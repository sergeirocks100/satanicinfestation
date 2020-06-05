###############################################################################
# Recent.pm                                                                   #
# $Date: 12.02.14 $                                                           #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Open-Source Community Software for Webmasters                               #
# Version:        YaBB 2.6.11                                                 #
# Packaged:       December 2, 2014                                            #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2014 YaBB (www.yabbforum.com) - All Rights Reserved.     #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
###############################################################################
# use strict;
# use warnings;
# no warnings qw(uninitialized once);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

# from YaBB3.0 build 100 #
$recentpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

# Sub RecentTopics shows all the most recently posted topics
# Meaning each thread will show up ONCE in the list.

# Sub RecentPosts will show the X last POSTS
# Even if they are all from the same thread
get_template('Display');

sub RecentPosts {
    spam_protection();

    my $display = isempty( $FORM{'display'}, 10 );
    if ( $display < 0 ) { $display = 5; }
    elsif ( $display > $maxrecentdisplay ) { $display = $maxrecentdisplay; }

    $numfound = 0;

    get_forum_master();

    *recursive_check2 = sub {
        foreach my $curboard (@_) {
            ( $boardname{$curboard}, $boardperms, $boardview ) =
              split /\|/xsm, $board{$curboard};

            my $access = AccessCheck( $curboard, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' ) { next; }

            if ( ${ $uid . $curboard }{'brdpasswr'} ) {
                my $bdmods = ${ $uid . $curboard }{'mods'};
                $bdmods =~ s/\, /\,/gsm;
                $bdmods =~ s/\ /\,/gsm;
                my %moderators = ();
                my $pswiammod  = 0;
                foreach my $curuser ( split /\,/xsm, $bdmods ) {
                    if ( $username eq $curuser ) { $pswiammod = 1; }
                }
                my $bdmodgroups = ${ $uid . $curboard }{'modgroups'};
                $bdmodgroups =~ s/\, /\,/gsm;
                my %moderatorgroups = ();
                foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                    if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                        $pswiammod = 1;
                    }
                    foreach my $memberaddgroups ( split /\, /sm,
                        ${ $uid . $username }{'addgroups'} )
                    {
                        chomp $memberaddgroups;
                        if ( $memberaddgroups eq $curgroup ) {
                            $pswiammod = 1;
                            last;
                        }
                    }
                }
                my $cookiename = "$cookiepassword$curboard$username";
                my $crypass    = ${ $uid . $curboard }{'brdpassw'};
                if (   !$iamadmin
                    && !$iamgmod
                    && !$pswiammod
                    && $yyCookies{$cookiename} ne $crypass )
                {
                    next;
                }
            }

            $catid{$curboard}   = $catid;
            $catname{$curboard} = $catname;

            fopen( REC_BDTXT, "$boardsdir/$curboard.txt" );
            @buffer = <REC_BDTXT>;
            for my $i ( 0 .. ( $display - 1 ) ) {
                if ( $buffer[$i] ) {
                    (
                        $tnum,      $tsub,  $tname,
                        $temail,    $tdate, $treplies,
                        $tusername, $ticon, $tstate
                    ) = split /\|/xsm, $buffer[$i];
                    chomp $tstate;
                    if ( $tstate !~ /h/sm || $iamadmin || $iamgmod ) {
                        $mtime = $tdate;
                        $data[$numfound] =
"$mtime|$curboard|$tnum|$treplies|$tusername|$tname|$tstate";
                        $numfound++;
                    }
                }
            }
            fclose(REC_BDTXT);

            if ( $subboard{$curboard} ) {
                recursive_check2( split /\|/xsm, $subboard{$curboard} );
            }
        }
    };

    foreach my $catid (@categoryorder) {

        (@bdlist) = split /\,/xsm, $cat{$catid};

        ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};
        $cataccess = CatAccess($catperms);
        if ( !$cataccess ) { next; }

        recursive_check2(@bdlist);
    }
    @data = reverse sort { $a cmp $b } @data;

    $numfound = 0;
    $threadfound = @data > $display ? $display : @data;

    for my $i ( 0 .. ( $threadfound - 1 ) ) {
        ( $mtime, $curboard, $tnum, $treplies, $tusername, $tname, $tstate ) =
          split /\|/xsm, $data[$i];

        # No need to check for hidden topics here, it was done above
        $tstart = $mtime;
        fopen( REC_THRETXT, "$datadir/$tnum.txt" ) || next;
        @mess = <REC_THRETXT>;
        fclose(REC_THRETXT);

        $threadfrom = @mess > $display ? @mess - $display : 0;
        for my $c ( $threadfrom .. @mess ) {
            if ( $mess[$c] ) {
                (
                    $msub,  $mname,   $memail, $mdate,   $musername,
                    $micon, $mattach, $mip,    $message, $mns
                ) = split /\|/xsm, $mess[$c];
                $mtime = $mdate;
                $messages[$numfound] =
"$mtime|$curboard|$tnum|$c|$tusername|$tname|$msub|$mname|$memail|$mdate|$musername|$micon|$mattach|$mip|$message|$mns|$tstate|$tstart";
                $numfound++;
            }
        }
    }

    @messages = reverse sort { $a cmp $b } @messages;

    if ( $numfound > 0 ) {
        if ( $numfound > $display ) { $numfound = $display; }
        LoadCensorList();
    }
    else {
        $yymain .= qq~<hr class="hr"><b>$maintxt{'170'}</b><hr />~;
    }

    for my $i ( 0 .. ( $numfound - 1 ) ) {
        (
            $dummy,   $board, $tnum,    $c,     $tusername, $tname,
            $msub,    $mname, $memail,  $mdate, $musername, $micon,
            $mattach, $mip,   $message, $mns,   $tstate,    $trstart
        ) = split /\|/xsm, $messages[$i];
        $displayname = $mname;

        if ( $tusername ne 'Guest' && -e ("$memberdir/$tusername.vars") ) {
            LoadUser($tusername);
        }
        if ( ${ $uid . $tusername }{'regtime'} ) {
            $registrationdate = ${ $uid . $tusername }{'regtime'};
        }
        else {
            $registrationdate = $date;
        }

        if ( ${ $uid . $tusername }{'regdate'} && $trstart > $registrationdate )
        {
            if ( $iamguest ) {
                $tname = qq~$format_unbold{$tusername}~;
            }
            else {
                $tname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tusername}" rel="nofollow">$format_unbold{$tusername}</a>~;
            }
        }
        elsif ( $tusername !~ m{Guest}sm && $trstart < $registrationdate ) {
            $tname = qq~$tname - $maintxt{'470a'}~;
        }
        else {
            $tname = "$tname ($maintxt{'28'})";
        }

        if ( $musername ne 'Guest' && -e ("$memberdir/$musername.vars") ) {
            LoadUser($musername);
        }
        if ( ${ $uid . $musername }{'regtime'} ) {
            $registrationdate = ${ $uid . $musername }{'regtime'};
        }
        else {
            $registrationdate = $date;
        }

        if ( ${ $uid . $musername }{'regdate'} && $mdate > $registrationdate ) {
            if ( $iamguest ) {
                $mname = qq~$format_unbold{$musername}~;
            }
            else {
                $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}" rel="nofollow">$format_unbold{$musername}</a>~;
            }
        }
        elsif ( $musername !~ m{Guest}sm && $mdate < $registrationdate ) {
            $mname = qq~$mname - $maintxt{'470a'}~;
        }
        else {
            $mname = "$mname ($maintxt{'28'})";
        }

        wrap();
        $movedflag = q{};
        ( $message, $movedflag ) = Split_Splice_Move( $message, $tnum );
        if ($enable_ubbc) {
            $ns = $mns;
            enable_yabbc();
            DoUBBC();
        }
        wrap2();
        ToChars($message);
        $message = Censor($message);

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        ToChars($msub);
        $msub = Censor($msub);

        if ($iamguest) {
            $notify = q{};
        }
        else {
            if ( ${ $uid . $username }{'thread_notifications'} =~
                /\b$tnum\b/xsm )
            {
                $notify =
qq~$menusep<a href="$scripturl?action=notify3;num=$tnum/$c;oldnotify=1">$img{'del_notify'}</a>~;
            }
            else {
                $notify =
qq~$menusep<a href="$scripturl?action=notify2;num=$tnum/$c;oldnotify=1">$img{'add_notify'}</a>~;
            }
        }
        $mdate = timeformat($mdate);

        # generate a sub board tree
        my $boardtree   = q{};
        my $parentboard = $board;
        while ($parentboard) {
            my ( $pboardname, undef, undef ) =
              split /\|/xsm, $board{$parentboard};
            if ( ${ $uid . $parentboard }{'canpost'}
                || !$subboard{$parentboard} )
            {
                $pboardname =
qq~<a href="$scripturl?board=$parentboard"><span class="under">$pboardname</span></a>~;
            }
            else {
                $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard;subboards=1"><span class="under">$pboardname</span></a>~;
            }
            $boardtree   = qq~ / $pboardname$boardtree~;
            $my_cat      = ${ $uid . $parentboard }{'cat'};
            $parentboard = ${ $uid . $parentboard }{'parent'};
        }
        $counter = $i + 1;

        if ( $tstate != 1 && ( !$iamguest || $enable_guestposting ) ) {
            $my_tstate = $myrecent_mess;
            $my_tstate =~ s/{yabb tnum}/$tnum/gsm;
            $my_tstate =~ s/{yabb c}/$c/gsm;
        }

        $yymain .= $myrecent;
        $yymain =~ s/{yabb counter}/$counter/sm;
        $yymain =~ s/{yabb catbrd}/$my_cat/sm;
        $yymain =~ s/{yabb catname}/$catname{$board}/sm;
        $yymain =~ s/{yabb boardtree}/$boardtree/sm;
        $yymain =~ s/{yabb tnum}/$tnum\/$c#$c/sm;
        $yymain =~ s/{yabb msub}/$msub/sm;
        $yymain =~ s/{yabb mdate}/$mdate/sm;
        $yymain =~ s/{yabb tname}/$tname/sm;
        $yymain =~ s/{yabb mname}/$mname/sm;
        $yymain =~ s/{yabb my_tstate}/$my_tstate/sm;
        $yymain =~ s/{yabb message}/$message/sm;
    }

    $yynavigation = qq~&rsaquo; $maintxt{'214'}~;
    $yytitle      = $maintxt{'214'};
    template();
    return;
}

sub RecentTopics {
    spam_protection();

    $recent_topics = $action eq 'recenttopics' ? 1 : 0;

    $display = $FORM{'display'} || $INFO{'display'} || 10;
    if ( $display < 0 ) { $display = 5; }
    elsif ( $display > $maxrecentdisplay ) { $display = $maxrecentdisplay; }

    $numfound = 0;
    get_forum_master();
    foreach my $catid (@categoryorder) {
        my ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};
        if ( !CatAccess($catperms) ) { next; }
        (@bdlist) = split /\,/xsm, $cat{$catid};
        recursive_check(@bdlist);
    }

    @data = reverse sort { $a cmp $b } @data;

    $numfound = 0;
    $notify =
      $recent_topics
      ? scalar @data
      : ( @data > $display ? $display : scalar @data );
    for my $i ( 0 .. ( $notify - 1 ) ) {
        ( $mtime, $curboard, $tnum, $treplies, $tusername, $tname, $tstate ) =
          split /\|/xsm, $data[$i];

        fopen( REC_THRETXT, "$datadir/$tnum.txt" ) || next;
        @mess = <REC_THRETXT>;
        fclose(REC_THRETXT);

        for my $c ( $#mess .. @mess ) {
            chomp $mess[$c];
            if ( $mess[$c] ) {
                (
                    $msub,  $mname,    $memail, $mdate,   $musername,
                    $micon, $mreplyno, $mip,    $message, $mns
                ) = split /\|/xsm, $mess[$c];
                $messages[$numfound] =
"$mdate|$curboard|$tnum|$c|$tusername|$tname|$msub|$mname|$memail|$mdate|$musername|$micon|$mreplyno|$mip|$message|$mns|$tstate|$mtime";
                $numfound++;
            }
        }
        if ( $recent_topics && $numfound == $display ) { last; }
    }

    @messages = reverse sort { $a cmp $b } @messages;

    if ( $numfound > 0 ) {
        if ( $numfound > $display ) { $numfound = $display; }
        LoadCensorList();
        $icanbypass = checkUserLockBypass();
    }
    else {
        $yymain .= qq~<hr class="hr" /><b>$maintxt{'170'}</b><hr />~;
    }

    for my $i ( 0 .. ( $numfound - 1 ) ) {
        (
            $dummy,   $board, $tnum,    $c,     $tusername, $tname,
            $msub,    $mname, $memail,  $mdate, $musername, $micon,
            $mattach, $mip,   $message, $mns,   $tstate,    $trstart
        ) = split /\|/xsm, $messages[$i];
        $displayname = $mname;

        if ( $tusername ne 'Guest' && -e ("$memberdir/$tusername.vars") ) {
            LoadUser($tusername);
        }
        if ( ${ $uid . $tusername }{'regtime'} ) {
            $registrationdate = ${ $uid . $tusername }{'regtime'};
        }
        else {
            $registrationdate = $date;
        }

        if ( ${ $uid . $tusername }{'regdate'} && $trstart > $registrationdate )
        {
            if ( $iamguest ) {
                $tname = qq~$format_unbold{$tusername}~;
            }
            else {
                $tname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tusername}" rel="nofollow">$format_unbold{$tusername}</a>~;
            }
        }
        elsif ( $tusername !~ m{Guest}sm && $trstart < $registrationdate ) {
            $tname = qq~$tname - $maintxt{'470a'}~;
        }
        else {
            $tname = "$tname ($maintxt{'28'})";
        }

        if ( $musername ne 'Guest' && -e ("$memberdir/$musername.vars") ) {
            LoadUser($musername);
        }
        if ( ${ $uid . $musername }{'regtime'} ) {
            $registrationdate = ${ $uid . $musername }{'regtime'};
        }
        else {
            $registrationdate = $date;
        }

        if ( ${ $uid . $musername }{'regdate'} && $mdate > $registrationdate ) {
            if ( $iamguest ) {
                $mname = qq~$format_unbold{$tusername}~;
            }
            else {
                $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}" rel="nofollow">$format_unbold{$musername}</a>~;
            }
        }
        elsif ( $musername !~ m{Guest}sm && $mdate < $registrationdate ) {
            $mname = qq~$mname - $maintxt{'470a'}~;
        }
        else {
            $mname = "$mname ($maintxt{'28'})";
        }

        wrap();
        $movedflag = q{};
        ( $message, $movedflag ) = Split_Splice_Move( $message, $tnum );
        if ($enable_ubbc) {
            $ns = $mns;
            enable_yabbc();
            DoUBBC();
        }
        wrap2();
        ToChars($message);
        $message = Censor($message);

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        ToChars($msub);
        $msub = Censor($msub);

        if ($iamguest) {
            $notify = q{};
        }
        else {
            if ( ${ $uid . $username }{'thread_notifications'} =~
                /\b$tnum\b/xsm )
            {
                $notify =
qq~$menusep<a href="$scripturl?action=notify3;num=$tnum/$c;oldnotify=1">$img{'del_notify'}</a>~;
            }
            else {
                $notify =
qq~$menusep<a href="$scripturl?action=notify2;num=$tnum/$c;oldnotify=1">$img{'add_notify'}</a>~;
            }
        }
        $mdate = timeformat($mdate);

        # generate a sub board tree
        my $boardtree   = q{};
        my $parentboard = $board;
        while ($parentboard) {
            my ( $pboardname, undef, undef ) =
              split /\|/xsm, $board{"$parentboard"};
            if ( ${ $uid . $parentboard }{'canpost'}
                || !$subboard{$parentboard} )
            {
                $pboardname =
qq~<a href="$scripturl?board=$parentboard"><span class="under">$pboardname</span></a>~;
            }
            else {
                $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard&subboards=1"><span class="under">$pboardname</span></a>~;
            }
            $boardtree = qq~ / $pboardname$boardtree~;
            $my_cat    = ${ $uid . $parentboard }{'cat'};
            ( $my_catname, undef ) = split /\|/xsm, $catinfo{$my_cat};
            $parentboard = ${ $uid . $parentboard }{'parent'};
        }
        $counter = $i + 1;

        if ( $tstate != 1 && ( !$iamguest || $enable_guestposting ) ) {
            $my_tstate = $myrecent_mess;
            $my_tstate =~ s/{yabb tnum}/$tnum/gsm;
            $my_tstate =~ s/{yabb c}/$c/gsm;
        }

        $yymain .= $myrecent;
        $yymain =~ s/{yabb counter}/$counter/sm;
        $yymain =~ s/{yabb catbrd}/$my_cat/sm;
        $yymain =~ s/{yabb catname}/$my_catname/sm;
        $yymain =~ s/{yabb boardtree}/$boardtree/sm;
        $yymain =~ s/{yabb tnum}/$tnum\/$c#$c/sm;
        $yymain =~ s/{yabb msub}/$msub/sm;
        $yymain =~ s/{yabb mdate}/$mdate/sm;
        $yymain =~ s/{yabb tname}/$tname/sm;
        $yymain =~ s/{yabb mname}/$mname/sm;
        $yymain =~ s/{yabb my_tstate}/$my_tstate/sm;
        $yymain =~ s/{yabb message}/$message/sm;
    }

    $yynavigation = qq~&rsaquo; $maintxt{'214b'}~;
    $yytitle      = $maintxt{'214b'};
    template();
    return;
}

sub recursive_check {
    my @x = @_;
    foreach my $curboard (@x) {
        ( $boardname{$curboard}, $boardperms, undef ) = split /\|/xsm,
          $board{$curboard};

        my $access = AccessCheck( $curboard, q{}, $boardperms );
        if ( !$iamadmin && $access ne 'granted' ) { next; }

        if ( ${ $uid . $curboard }{'brdpasswr'} ) {
            my $bdmods = ${ $uid . $curboard }{'mods'};
            $bdmods =~ s/\, /\,/gsm;
            $bdmods =~ s/\ /\,/gsm;
            my %moderators = ();
            my $pswiammod  = 0;
            foreach my $curuser ( split /\,/xsm, $bdmods ) {
                if ( $username eq $curuser ) { $pswiammod = 1; }
            }
            my $bdmodgroups = ${ $uid . $curboard }{'modgroups'};
            $bdmodgroups =~ s/\, /\,/gsm;
            my %moderatorgroups = ();
            foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                    $pswiammod = 1;
                }
                foreach my $memberaddgroups ( split /\, /sm,
                    ${ $uid . $username }{'addgroups'} )
                {
                    chomp $memberaddgroups;
                    if ( $memberaddgroups eq $curgroup ) {
                        $pswiammod = 1;
                        last;
                    }
                }
            }
            my $cookiename = "$cookiepassword$curboard$username";
            my $crypass    = ${ $uid . $curboard }{'brdpassw'};
            if (   !$iamadmin
                && !$iamgmod
                && !$pswiammod
                && $yyCookies{$cookiename} ne $crypass )
            {
                next;
            }
        }

        $catid{$curboard}   = $catid;
        $catname{$curboard} = $catname;

        fopen( REC_BDTXT, "$boardsdir/$curboard.txt" );
        @buffer = <REC_BDTXT>;
        if ( !$display ) {
            $display = scalar @buffer;
        }
        for my $i ( 0 .. ( $display - 1 ) ) {
            if ( $buffer[$i] ) {
                (
                    $tnum,     $tsub,      $tname, $temail, $tdate,
                    $treplies, $tusername, $ticon, $tstate
                ) = split /\|/xsm, $buffer[$i];
                chomp $tstate;
                if ( $tstate !~ /h/sm || $iamadmin || $iamgmod ) {
                    $mtime = $tdate;
                    $data[$numfound] =
"$mtime|$curboard|$tnum|$treplies|$tusername|$tname|$tstate";
                    $numfound++;
                }
            }
        }
        fclose(REC_BDTXT);
        if ( $subboard{$curboard} ) {
            recursive_check( split /\|/xsm, $subboard{$curboard} );
        }
    }
    return;
}

1;
