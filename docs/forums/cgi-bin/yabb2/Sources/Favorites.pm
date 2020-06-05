###############################################################################
# Favorites.pm                                                                #
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
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$favoritespmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub Favorites {
    LoadLanguage('MessageIndex');
    get_micon();
    get_template('MyPosts');

    my $start = int( $INFO{'start'} ) || 0;
    my (
        @threads, $counter, $pages, $mnum,     $msub,
        $mname,   $memail,  $mdate, $mreplies, $musername,
        $micon,   $mstate,  $dlp
    );
    my $treplies = 0;

# grab all relevant info on the favorite thread for this user and check access to them
    if ( !$maxfavs ) { $maxfavs = 10; }
    my @favboards;
    eval { require Variables::Movedthreads };
        foreach my $myfav ( split /,/xsm, ${ $uid . $username }{'favorites'} ) {

            # see if thread exists and search for it if moved
            if ( exists $moved_file{$myfav} ) {
                my @moved = ($myfav);
                while ( exists $moved_file{$myfav} ) {
                    $myfav = $moved_file{$myfav};
                    unshift @moved, $myfav;
                }
                foreach (@moved) {
                    $myfav = $_;
                    if ( $myfav ne $moved[-1] ) {
                        if ( -e "$datadir/$myfav.ctb" ) {
                            RemFav( $moved[-1], 'nonexist' );
                            AddFav( $myfav, 0, 1 );
                            last;
                        }
                    }
                    elsif ( !-e "$datadir/$myfav.ctb" ) {
                        RemFav( $myfav, 'nonexist' );
                        $myfav = 0;
                    }
                }
                next if !$myfav;
            }
            elsif ( !-e "$datadir/$myfav.ctb" ) {
                RemFav( $myfav, 'nonexist' );
                next;
            }
            MessageTotals( 'load', $myfav );
            $favoboard = ${$myfav}{'board'};
            push @favboards, "$favoboard|$myfav";
        }

    foreach ( sort @favboards ) {
        ( $loadboard, $loadfav ) = split /\|/xsm, $_;
        if ( !${ $uid . $loadboard }{'board'} ) {
            BoardTotals( 'load', $loadboard );
        }

        next
          if !$iamadmin
              && AccessCheck( $loadboard, q{},
                  ( split /\|/xsm, $board{$loadboard} )[1] ) ne 'granted';

        next
          if !$iamadmin
              && !CatAccess(
                  ( split /\|/xsm, $catinfo{"${$uid.$loadboard}{'cat'}"} )[1]
              );

        fopen( BRDTXT, "$boardsdir/$loadboard.txt" )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        while ( my $brd = <BRDTXT> ) {
            if ( ( split /\|/xsm, $brd, 2 )[0] eq $loadfav ) {
                push @threads, $brd;
            }
        }
        fclose(BRDTXT);
    }

    my $curfav = @threads;

    LoadCensorList();

    my %attachments;
    my $att_length = -s "$vardir/attachments.txt";
    if ( ( -s "$vardir/attachments.txt" ) > 5 ) {
        fopen( ATM, "$vardir/attachments.txt" );
        while (<ATM>) {
            $attachments{ ( split /\|/xsm, $_, 2 )[0] }++;
        }
        fclose(ATM);
    }

    # Print the header and board info.
    my $colspan = 7;

    # Begin printing the message index for current board.
    $counter = $start;
    getlog();
    my $dmax = $date - ( $max_log_days_old * 86400 );
    foreach (@threads) {
        (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate
        ) = split /\|/xsm, $_;

        # Set thread class depending on locked status and number of replies.
        if ( $mnum eq q{} ) { next; }

        MessageTotals( 'load', $mnum );

        $permlinkboard =
          ${$mnum}{'board'} eq $annboard ? $annboard : $currentboard;
        my $permdate = permtimer($mnum);
        my $message_permalink =
qq~<a href="http://$perm_domain/$symlink$permdate/$permlinkboard/$mnum">$messageindex_txt{'10'}</a>~;

        $threadclass = 'thread';
        if    ( $mstate =~ /h/ism ) { $threadclass = 'hide'; }
        elsif ( $mstate =~ /l/ism ) { $threadclass = 'locked'; }
        elsif ( $mreplies >= $VeryHotTopic ) { $threadclass = 'veryhotthread'; }
        elsif ( $mreplies >= $HotTopic )     { $threadclass = 'hotthread'; }
        elsif ( $mstate eq q{} ) { $threadclass = 'thread'; }
        if ( $threadclass eq 'hide' && $mstate =~ /s/ism && $mstate !~ /l/ism )
        {
            $threadclass = 'hidesticky';
        }
        elsif ($threadclass eq 'hide'
            && $mstate =~ /l/ism
            && $mstate !~ /s/ism )
        {
            $threadclass = 'hidelock';
        }
        elsif ($threadclass eq 'hide'
            && $mstate =~ /s/ism
            && $mstate =~ /l/ism )
        {
            $threadclass = 'hidestickylock';
        }
        elsif ($threadclass eq 'locked'
            && $mstate =~ /s/ism
            && $mstate !~ /h/ism )
        {
            $threadclass = 'stickylock';
        }
        elsif ( $mstate =~ /s/ism && $mstate !~ /h/ism ) {
            $threadclass = 'sticky';
        }
        elsif ( ${$mnum}{'board'} eq $annboard && $mstate !~ /h/ism ) {
            $threadclass =
              $threadclass eq 'locked' ? 'announcementlock' : 'announcement';
        }

        my $movedFlag;
        ( undef, $movedFlag ) = Split_Splice_Move( $msub, $mnum );

        if ( !$iamguest && $max_log_days_old ) {

            # Decide if thread should have the "NEW" indicator next to it.
            # Do this by reading the user's log for last read time on thread,
            # and compare to the last post time on the thread.
            $dlp =
              int( $yyuserlog{$mnum} ) >
              int( $yyuserlog{"$currentboard--mark"} )
              ? int( $yyuserlog{$mnum} )
              : int $yyuserlog{"$currentboard--mark"};
            if (   $yyuserlog{"$mnum--unread"}
                || ( !$dlp && $mdate > $dmax )
                || ( $dlp > $dmax && $dlp < $mdate ) )
            {
                if ( ${$mnum}{'board'} eq $annboard ) {
                    $new =
qq~<a href="$scripturl?virboard=$currentboard;num=$mnum/new">$micon{'new'}</a>~;
                }
                else {
                    $new =
                      qq~<a href="$scripturl?num=$mnum/new">$micon{'new'}</a>~;
                }
            }
            else {
                $new = q{};
            }
        }
        if ($movedFlag) { $new = q{}; }

        $micon = $micon{$micon};
        $mpoll = q{};
        if ( -e "$datadir/$mnum.poll" ) {
            $mpoll = qq~<b>$messageindex_txt{'15'}: </b>~;
            fopen( POLL, "$datadir/$mnum.poll" );
            my @poll = <POLL>;
            fclose(POLL);
            my (
                $poll_question, $poll_locked, $poll_uname,   $poll_name,
                $poll_email,    $poll_date,   $guest_vote,   $hide_results,
                $multi_vote,    $poll_mod,    $poll_modname, $poll_comment,
                $vote_limit,    $pie_radius,  $pie_legends,  $poll_end
            ) = split /\|/xsm, $poll[0];
            chomp $poll_end;
            if ( $poll_end && !$poll_locked && $poll_end < $date ) {
                $poll_locked = 1;
                $poll_end    = q{};
                $poll[0] =
"$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_vote|$poll_mod|$poll_modname|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n";
                fopen( POLL, ">$datadir/$mnum.poll" );
                print {POLL} @poll or croak "$croak{'print'} POLL";
                fclose(POLL);
            }
            $micon = qq~$img{'pollicon'}~;
            if ($poll_locked) { $micon = $img{'polliconclosed'}; }
            elsif ( $max_log_days_old && $mdate > $dmax ) {
                if ( $dlp < $createpoll_date ) {
                    $micon = qq~$img{'polliconnew'}~;
                }
                else {
                    fopen( POLLED, "$datadir/$mnum.polled" );
                    my $polled = <POLLED>;
                    fclose(POLLED);
                    if ( $dlp < ( split /\|/xsm, $polled )[3] ) {
                        $micon = qq~$img{'polliconnew'}~;
                    }
                }
            }
        }

        # Load the current nickname of the account name of the thread starter.
        if ( $musername ne 'Guest' ) {
            LoadUser($musername);
            if ( ${ $uid . $musername }{'realname'} ) {
                $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">$format_unbold{$musername}</a>~;
            }
            else {
                $mname .= qq~ ($messageindex_txt{'470a'})~;
            }
        }

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );

        # Censor the subject of the thread.
        $msub = Censor($msub);
        ToChars($msub);

        # Build the page links list.
        $pages = q{};
        $pagesall;
        if ($showpageall) {
            $pagesall =
              qq~<a href="$scripturl?num=$mnum/all-0">$pidtxt{'01'}</a>~;
        }
        $maxmessagedisplay ||= 10;
        if ( int( ( $mreplies + 1 ) / $maxmessagedisplay ) > 6 ) {
            $pages =
                qq~ <a href="$scripturl?num=$mnum/~
              . ( !$ttsreverse ? '0#0' : "$mreplies#$mreplies" )
              . q~">1</a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$maxmessagedisplay#$maxmessagedisplay"
                : ( $mreplies - $maxmessagedisplay ) . q{#}
                  . ( $mreplies - $maxmessagedisplay )
              ) . q~">2</a>~;
            $endpage = int( $mreplies / $maxmessagedisplay ) + 1;
            $i       = ( $endpage - 1 ) * $maxmessagedisplay;
            $j       = $i - $maxmessagedisplay;
            $k       = $endpage - 1;
            $tmpa    = $endpage - 2;
            $tmpb    = $j - $maxmessagedisplay;
            $pages .=
qq~ <a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$tmpb#$tmpb"
                : ( $mreplies - $tmpb ) . q{#} . ( $mreplies - $tmpb )
              ) . qq~">$tmpa</a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$j#$j"
                : ( $mreplies - $j ) . q{#} . ( $mreplies - $j )
              ) . qq~">$k</a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$i#$i"
                : ( $mreplies - $i ) . q{#} . ( $mreplies - $i )
              ) . qq~">$endpage</a>~;
            $pages =
qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages $pagesall &#187;</span>~;

        }
        elsif ( $mreplies + 1 > $maxmessagedisplay ) {
            $tmpa = 1;
            for my $tmpb ( 0 .. $mreplies ) {
                if ( $tmpb % $maxmessagedisplay == 0 ) {
                    $pages .=
                        qq~<a href="$scripturl?num=$mnum/~
                      . ( !$ttsreverse ? "$tmpb#$tmpb" : ( $mreplies - $tmpb ) )
                      . qq~">$tmpa</a>\n~;
                    ++$tmpa;
                }
            }
            $pages =~ s/\n\Z//xsm;
            $pages =
qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages &#187;</span>~;
        }

        $views      = ${$mnum}{'views'};
        $lastposter = ${$mnum}{'lastposter'};
        if ( $lastposter =~ m{\AGuest-(.*)}xsm ) {
            $lastposter = $1;
        }
        elsif ( $lastposter !~ m{Guest}xsm
            && !( -e "$memberdir/$lastposter.vars" ) )
        {
            $lastposter = $messageindex_txt{'470a'};
        }
        else {
            if (
                (
                       $lastposter ne $messageindex_txt{'470'}
                    && $lastposter ne $messageindex_txt{'470a'}
                )
                || !-e "$memberdir/$lastposter.vars"
              )
            {
                LoadUser($lastposter);
                if ( ${ $uid . $lastposter }{'realname'} ) {
                    $lastposter =
qq~<a href="$scripturl?action=viewprofile;username=$lastposter">$format_unbold{$lastposter}</a>~;
                }
            }
        }
        $lastpostername = $lastposter || $messageindex_txt{'470'};
        $views = $views ? $views - 1 : 0;

# Check if the thread contains attachments and create a paper-clip icon if it does
        $temp_attachment =
          $attachments{$mnum}
          ? qq~<a href="javascript:void(window.open('$scripturl?action=viewdownloads;thread=$mnum','_blank','width=800,height=650,scrollbars=yes'))"><img src="$micon_bg{'paperclip'}" alt="$messageindex_txt{'3'} $attachments{$mnum} ~
          . (
              $attachments{$mnum} == 1
            ? $messageindex_txt{'5'}
            : $messageindex_txt{'4'}
          )
          . qq~" title="$messageindex_txt{'3'} $attachments{$mnum} ~
          . (
              $attachments{$mnum} == 1
            ? $messageindex_txt{'5'}
            : $messageindex_txt{'4'}
          )
          . q~" /></a>~
          : q{};

        $mydate = timeformat($mdate);

        my $threadpic = $micon{$threadclass};
        my $msublink  = qq~<a href="$scripturl?num=$mnum">$msub</a>~;
        if ( !$movedFlag && ${$mnum}{'board'} eq $annboard ) {
            $msublink =
qq~<a href="$scripturl?virboard=$currentboard;num=$mnum">$msub</a>~;
        }
        my $lastpostlink =
qq~<a href="$scripturl?num=$mnum/$mreplies#$mreplies">$img{'lastpost'}$mydate</a>~;
        my $fmreplies = NumberFormat($mreplies);
        $views = NumberFormat($views);
        my $tempbar = $threadbar;
        if ($movedFlag) { $tempbar = $threadbarMoved; }

        $adminbar =
qq~<input type="checkbox" name="admin$mcount" class="windowbg" value="$mnum" />~;
        $admincol = $admincolumn;
        $admincol =~ s/{yabb admin}/$adminbar/gsm;

        $tempbar =~ s/{yabb admin column}/$admincol/gsm;
        $tempbar =~ s/{yabb threadpic}/$threadpic/gsm;
        $tempbar =~ s/{yabb icon}/$micon/gsm;
        $tempbar =~ s/{yabb new}/$new/gsm;
        $tempbar =~ s/{yabb poll}/$mpoll/gsm;
        $tempbar =~ s/{yabb favorite}/$favicon{$mnum}/gsm;
        $tempbar =~ s/{yabb subjectlink}/$msublink/gsm;
        $tempbar =~ s/{yabb attachmenticon}/$temp_attachment/gsm;
        $tempbar =~ s/{yabb pages}/$pages/gsm;
        $tempbar =~ s/{yabb starter}/$mname/gsm;
        $tempbar =~ s/{yabb replies}/$fmreplies/gsm;
        $tempbar =~ s/{yabb views}/$views/gsm;
        $tempbar =~ s/{yabb lastpostlink}/$lastpostlink/gsm;
        $tempbar =~ s/{yabb lastposter}/$lastpostername/gsm;
        if ( $accept_permalink == 1 ) {
            $tempbar =~ s/{yabb permalink}/$message_permalink/gsm;
        }
        else {
            $tempbar =~ s/{yabb permalink}//gsm;
        }
        $tmptempbar .= $tempbar;
        $counter++;
        $mcount++;
        $treplies += $mreplies + 1;
    }

    # Put a "no messages" message if no threads exisit:
    if ( !$tmptempbar ) {
        $tmptempbar = $no_favs;
    }

    $yabbicons = qq~$micon{'thread'} $messageindex_txt{'457'}
    <br />$micon{'sticky'} $messageindex_txt{'779'}
    <br />$micon{'locked'} $messageindex_txt{'456'}
    <br />$micon{'stickylock'}$messageindex_txt{'780'}<br />~;

    if ( $staff && $sessionvalid == 1 ) {
        $yabbadminicons = qq~$micon{'hide'} $messageindex_txt{'458'}
        <br />$micon{'hidesticky'} $messageindex_txt{'459'}
        <br />$micon{'hidelock'} $messageindex_txt{'460'}
        <br />$micon{'hidestickylock'} $messageindex_txt{'461'}<br />~;
    }

    $yabbadminicons .= qq~$micon{'announcement'} $messageindex_txt{'779a'}
    <br />$micon{'announcementlock'} $messageindex_txt{'779b'}
    <br />$micon{'hotthread'} $messageindex_txt{'454'} $HotTopic $messageindex_txt{'454a'}
    <br />$micon{'veryhotthread'} $messageindex_txt{'455'} $VeryHotTopic $messageindex_txt{'454a'}<br />
    ~;

    $formstart =
qq~<form name="multiremfav" action="$scripturl?board=$currentboard;action=multiremfav" method="post" style="display: inline">~;
    $formend =
      qq~<input type="hidden" name="allpost" value="$INFO{'start'}" /></form>~;

    LoadAccess();

    $adminselector = qq~
    <input type="submit" value="$messageindex_txt{'842'}" class="button small" />
    ~;

    $admincheckboxes = q~
    <input type="checkbox" name="checkall" id="checkall" value="" class="titlebg" onclick="if (this.checked) checkAll(0); else uncheckAll(0);" />
    ~;
    $subfooterbar =~ s/{yabb admin selector}/$adminselector/gsm;
    $subfooterbar =~ s/{yabb admin checkboxes}/$admincheckboxes/gsm;

    # Template it
    $adminheader =~ s/{yabb admin}/$messageindex_txt{'2'}/gsm;

    $favorites_template =~ s/{yabb home}//gsm;
    $favorites_template =~ s/{yabb category}//gsm;

    $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $img_txt{'70'}~;

    $favboard = qq~<span class="nav">$img_txt{'70'}</span>~;
    $favorites_template =~ s/{yabb board}/$favboard/gsm;
    $bdescrip =
qq~$messageindex_txt{'75'}<br />$messageindex_txt{'76'} $curfav $messageindex_txt{'77'} $maxfavs $messageindex_txt{'78'}~;
    $curfav   = NumberFormat($curfav);
    $treplies = NumberFormat($treplies);
    $bdpicExt ||= 'gif';

    ToChars($bdescrip);
    $boarddescription   =~ s/{yabb boarddescription}/$bdescrip/gsm;
    $favorites_template =~ s/{yabb description}/$boarddescription/gsm;
    $bdpic =
qq~ <img src="$imagesdir/$my_favbrds" alt="$img_txt{'70'}" title="$img_txt{'70'}" /> ~;
    $favorites_template =~ s/{yabb bdpicture}/$bdpic/gsm;
    $favorites_template =~ s/{yabb threadcount}/$curfav/gsm;
    $favorites_template =~ s/{yabb messagecount}/$treplies/gsm;

    $favorites_template =~ s/{yabb colspan}/$colspan/gsm;

    $favorites_template =~ s/{yabb admin column}/$adminheader/gsm;
    $favorites_template =~ s/{yabb modupdate}/$formstart/gsm;
    $favorites_template =~ s/{yabb modupdateend}/$formend/gsm;

    $favorites_template =~ s/{yabb threadblock}/$tmptempbar/gsm;
    $favorites_template =~ s/{yabb adminfooter}/$subfooterbar/gsm;
    $favorites_template =~ s/{yabb icons}/$yabbicons/gsm;
    $favorites_template =~ s/{yabb admin icons}/$yabbadminicons/gsm;
    $showFavorites .= qq~$favorites_template~;

    $showFavorites .= qq~
<script type="text/javascript">
        function checkAll(j) {
            for (var i = 0; i < document.multiremfav.elements.length; i++) {
                if (j == 0 ) {document.multiremfav.elements[i].checked = true;}
            }
        }
        function uncheckAll(j) {
            for (var i = 0; i < document.multiremfav.elements.length; i++) {
                if (j == 0 ) {document.multiremfav.elements[i].checked = false;}
            }
        }
        function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
</script>
    ~;

    $yytitle = $img_txt{'70'};
    return;
}

sub AddFav {
    my @x      = @_;
    my $favo   = $INFO{'fav'} || $x[0];
    my $goto   = $INFO{'start'} || $x[1] || 0;
    my $return = $x[2];

    if ( $favo =~ /\D/xsm ) { fatal_error( 'error_occurred', q{}, 1 ); }

    my @oldfav = split /,/xsm, ${ $uid . $username }{'favorites'};
    if ( @oldfav < ( $maxfavs || 10 ) ) {
        push @oldfav, $favo;
        ${ $uid . $username }{'favorites'} = join q{,}, undupe(@oldfav);
        UserAccount( $username, 'update' );
    }
    if ( !$return ) {
        if ( $INFO{'oldaddfav'} ) {
            $yySetLocation = qq~$scripturl?num=$favo/$goto~;
            redirectexit();
        }
        $elenable = 0;
        croak q{};    # This is here only to avoid server error log entries!
    }
    return;
}

sub MultiRemFav {
    while ( $maxfavs >= $count ) {
        RemFav( $FORM{"admin$count"} );
        $count++;
    }
    $yySetLocation = qq~$scripturl?action=favorites~;
    redirectexit();
    return;
}

sub RemFav {
    my @x    = @_;
    my $favo = $INFO{'fav'} || $x[0];
    my $goto = $INFO{'start'} || $x[1];
    if ( !$goto ) { $goto = 0; }

    my @newfav;
    foreach ( split /,/xsm, ${ $uid . $username }{'favorites'} ) {
        if ( $favo ne $_ ) { push @newfav, $_; }
    }

    ${ $uid . $username }{'favorites'} = join q{,}, undupe(@newfav);
    UserAccount( $username, 'update' );

    return if $x[1] eq 'nonexist';
    if (   $INFO{'ref'} ne 'delete'
        && $action ne 'multiremfav'
        && $INFO{'oldaddfav'} )
    {
        $yySetLocation = qq~$scripturl?num=$favo/$goto~;
        redirectexit();
    }
    if ( $action eq 'remfav' ) {
        $elenable = 0;
        croak q{};    # This is here only to avoid server error log entries!
    }
    return;
}

sub IsFav {
    my @x         = @_;
    my $favo      = $x[0];
    my $goto      = $x[1] || 0;
    my $postcheck = $x[2];

    my $addfav = $img{'addfav'};
    my $remfav = $img{'remfav'};
    if ($useThreadtools) {
        $addfav =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
        $remfav =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
    }
    if ( !$postcheck ) {
        $yyjavascript .= qq~\n
        var addlink = '$addfav';
        var remlink = '$remfav';\n~;
    }

    my @oldfav = split /,/xsm, ${ $uid . $username }{'favorites'};
    my ( $button, $nofav );
    if ( @oldfav < ( $maxfavs || 10 ) ) {
        $button =
qq~$menusep<a href="javascript:AddRemFav('$scripturl?action=addfav;fav=$favo;start=$goto','$imagesdir')" id="favlink">$img{'addfav'}</a>~;
        $nofav = 1;
    }
    else { $nofav = 2; }

    foreach (@oldfav) {
        if ( $favo eq $_ ) {
            $button =
qq~$menusep<a href="javascript:AddRemFav('$scripturl?action=remfav;fav=$favo;start=$goto','$imagesdir')" id="favlink">$img{'remfav'}</a>~;
            $nofav = 0;
        }
    }
    return ( !$postcheck ? $button : $nofav );
}

sub IsFav1 {
    my @x         = @_;
    my $favo      = $x[0];
    my $goto      = $x[1] || 0;
    my $postcheck = $x[2];

    my $addfav = $img{'addfav'};
    my $remfav = $img{'remfav'};
    if ($useThreadtools) {
        $addfav =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
        $remfav =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
    }
    if ( !$postcheck ) {
        $yyjavascript .= qq~\n
        addlink = '$addfav';
        remlink = '$remfav';\n~;
    }

    my @oldfav = split /,/xsm, ${ $uid . $username }{'favorites'};
    my ( $button, $nofav );
    if ( @oldfav < ( $maxfavs || 10 ) ) {
        $button =
qq~$menusep<a href="javascript:AddRemFav('$scripturl?action=addfav;fav=$favo;start=$goto','$imagesdir')" id="favlink2">$img{'addfav'}</a>~;
        $nofav = 1;
    }
    else { $nofav = 2; }

    foreach (@oldfav) {
        if ( $favo eq $_ ) {
            $button =
qq~$menusep<a href="javascript:AddRemFav('$scripturl?action=remfav;fav=$favo;start=$goto','$imagesdir')" id="favlink2">$img{'remfav'}</a>~;
            $nofav = 0;
        }
    }
    return ( !$postcheck ? $button : $nofav );
}

1;
