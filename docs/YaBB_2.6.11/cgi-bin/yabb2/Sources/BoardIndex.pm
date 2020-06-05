###############################################################################
# BoardIndex.pm                                                               #
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
use English '-no_match_vars';
our $VERSION = '2.6.11';

$boardindexpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('BoardIndex');
get_micon();

sub BoardIndex {
    my (
        $users,   $lspostid,   $lspostbd,   $lssub,      $lsposter,
        $lsreply, $lsdatetime, @goodboards, @loadboards, $guestlist
    );
    get_forum_master();
    my @brd_img_id = sort ( keys %board);
    my %brd_img_id = ();
    my $brdimgcnt = 0;
    for ( @brd_img_id ) {
        $brd_img_id{$_} = $brdimgcnt;
        $brdimgcnt++;
    }

    my ( $memcount, $latestmember ) = MembershipGet();
    chomp $latestmember;
    $totalm       = 0;
    $totalt       = 0;
    $lastposttime = 0;
    my $lastthreadtime = 0;

    if ( $INFO{'boardselect'} ) { $subboard_sel = $INFO{'boardselect'}; }

    # if sub board is selected but none exists with that name, show everything
    if ( $subboard_sel && !$subboard{$subboard_sel} ) {
        $subboard_sel = 0;
    }

    get_template('BoardIndex');

    my ( $numusers, $guests, $numbots, $user_in_log, $guest_in_log ) =
      ( 0, 0, 0, 0, 0 );
    my %bvusers = ();

    # do not do this stuff when we're calling for sub board display
    if ( !$subboard_sel ) {
        GetBotlist();

        my $lastonline = $date - ( $OnlineLogTime * 60 );
        foreach (@logentries) {
            ( $name, $date1, $last_ip, $last_host, undef, $boardv, undef ) =
              split /\|/xsm, $_, 7;
            if ( !$last_ip ) {
                $last_ip =
qq~</i></span><span class="error">$boardindex_txt{'no_ip'}</span><span class="small"><i>~;
            }
            my $lookupIP =
              ( $ipLookup && $last_ip )
              ? qq~<a href="$scripturl?action=iplookup;ip=$last_ip">$last_ip</a>~
              : qq~$last_ip~;

            my $is_a_bot = Is_Bot($last_host);
            if ($is_a_bot) {
                $numbots++;
                $bot_count{$is_a_bot}++;
            }
            elsif ($name) {
                if ( LoadUser($name) ) {
                    if ( $name eq $username ) { $user_in_log = 1; }
                    elsif ( ${ $uid . $name }{'lastonline'} < $lastonline ) {
                        next;
                    }
                    if ( $iamadmin || $iamgmod || $iamfmod ) {
                        $numusers++;
                        $bvusers{$boardv}++;
                        $users .= QuickLinks($name);
                        $users .= ( ${ $uid . $name }{'stealth'} ? q{*} : q{} )
                          . (
                            (
                                     ( $iamadmin && $show_online_ip_admin )
                                  || ( $iamgmod && $show_online_ip_gmod )
                                  || ( $iamfmod && $show_online_ip_fmod )
                            ) ? qq~&nbsp;<i>($lookupIP)</i>, ~ : q{, }
                          );

                    }
                    elsif ( !${ $uid . $name }{'stealth'} ) {
                        $numusers++;
                        $users .= QuickLinks($name) . q{, };
                    }
                }
                else {
                    if ( $name eq $user_ip ) { $guest_in_log = 1; }
                    $guests++;
                    $bvusers{$boardv}++;
                    if (   ( $iamadmin && $show_online_ip_admin )
                        || ( $iamgmod && $show_online_ip_gmod )
                        || ( $iamfmod && $show_online_ip_fmod ) )
                    {
                        $guestlist .= qq~<i>$lookupIP</i>, ~;
                    }
                }
            }
        }
        if ( !$iamguest && !$user_in_log ) {
            if ($guests) { $guests--; }
            $numusers++;
            $bvusers{$boardv}++;
            $users .= QuickLinks($username);
            if ( $iamadmin || $iamgmod || $iamfmod ) {
                $users .= ${ $uid . $username }{'stealth'} ? q{*} : q{};
                if (   ( $iamadmin && $show_online_ip_admin )
                    || ( $iamgmod && $show_online_ip_gmod )
                    || ( $iamfmod && $show_online_ip_fmod ) )
                {
                    $users .= "&nbsp;<i>($user_ip)</i>";
                    $guestlist =~ s/<i>$lookupIP<\/i>, //osm;
                }
            }
        }
        elsif ( $iamguest && !$iambot && !$guest_in_log ) {
            $guests++;
            $bvusers{$boardv}++;
        }

        if ($numusers) {
            $users =~ s/, \Z//sm;
            $users .= q~<br />~;
        }
        if ($guestlist) {    # build the guest list
            $guestlist =~ s/, $//sm;
            $guestlist = qq~<span class="small">$guestlist</span><br />~;
        }
        if ($numbots) {      # build the bot list
            foreach ( sort keys %bot_count ) {
                $botlist .= qq~$_&nbsp;($bot_count{$_}), ~;
            }
            $botlist =~ s/, $//sm;
            $botlist = qq~<span class="small">$botlist</span>~;
        }

        if ( !$INFO{'catselect'} ) {
            $yytitle = $boardindex_txt{'18'};
        }
        else {
            ( $tmpcat, $tmpmod, $tmpcol ) =
              split /\|/xsm, $catinfo{ $INFO{'catselect'} };
            ToChars($tmpcat);
            $yytitle      = qq~$tmpcat~;
            $yynavigation = qq~&rsaquo; $tmpcat~;
        }

        if ( !$iamguest ) { Collapse_Load(); }
    }

    else {
        foreach (@logentries) {
            ( $name, $date1, $last_ip, $last_host, undef, $boardv, undef ) =
              split /\|/xsm, $_, 7;
            if ($name) {
                if ( LoadUser($name) ) {
                    if ( $iamadmin || $iamgmod || $iamfmod ) {
                        $numusers++;
                        $bvusers{$boardv}++;
                    }
                }
                else {
                    if ( $name eq $user_ip ) { $guest_in_log = 1; }
                    $guests++;
                    $bvusers{$boardv}++;
                }
            }
        }
    }

    my @tmplist;
    if ($subboard_sel) {
        push @tmplist, $subboard_sel;
    }
    else {
        push @tmplist, @categoryorder;
    }

# first get all the boards based on the categories found in forum.master or the provided sub board
    foreach my $catid (@tmplist) {
        if (   $INFO{'catselect'} ne $catid
            && $INFO{'catselect'}
            && !$subboard_sel )
        {
            next;
        }

        # get boards in category if we're not looking for subboards
        if ( !$subboard_sel ) {
            (@bdlist) = split /\,/xsm, $cat{$catid};
            my ( $catname, $catperms, $catallowcol ) =
              split /\|/xsm, $catinfo{$catid};

            # Category Permissions Check
            my $access = CatAccess($catperms);
            if ( !$access ) { next; }
            $cat_boardcnt{$catid} = 0;
        }
        else {
            (@bdlist) = split /\|/xsm, $subboard{$catid};
        }

        foreach my $curboard (@bdlist) {
            if ( !exists $board{$curboard} ) {
                gostRemove( $catid, $curboard );
                next;
            }

# hide the actual global announcement board for all normal users but admins and gmods
            if (   $annboard eq $curboard
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
            {
                next;
            }
            my ( $boardname, $boardperms, $boardview ) =
              split /\|/xsm, $board{$curboard};
            my $access = AccessCheck( $curboard, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' && $boardview != 1 ) {
                next;
            }

     # Now check subboards that won't be displayed but we need their latest info
            if ( $subboard{$curboard} ) {

         # recursively check access to all sub boards then add them to load list
                *recursive_boards = sub {
                    foreach my $childbd (@_) {

               # now fill all the necessary hashes to show all board index stuff
                        if ( !exists $board{$childbd} ) {
                            gostRemove( $catid, $childbd );
                            next;
                        }

# hide the actual global announcement board for all normal users but admins and gmods
                        if (   $annboard eq $childbd
                            && !$iamadmin
                            && !$iamgmod
                            && !$iamfmod )
                        {
                            next;
                        }
                        ( $boardname, $boardperms, $boardview ) =
                          split /\|/xsm, $board{$childbd};
                        $access = AccessCheck( $childbd, q{}, $boardperms );
                        if (  !$iamadmin
                            && $access ne 'granted'
                            && $boardview != 1 )
                        {
                            next;
                        }

                        # add it to list of boards to load data
                        push @loadboards, $childbd;

                        # make recursive call if this board has more children
                        if ( $subboard{$childbd} ) {
                            recursive_boards( split /\|/xsm,
                                $subboard{$childbd} );
                        }
                    }
                };
                recursive_boards( split /\|/xsm, $subboard{$curboard} );
            }

            # if it's a sub board don't add to category count
            if ( !${ $uid . $curboard }{'parent'} ) {
                $cat_boardcnt{$catid}++;
            }

            push @goodboards, "$catid|$curboard";
            push @loadboards, $curboard;
        }
    }

    BoardTotals( 'load', @loadboards );
    getlog();
    my $dmax = $date - ( $max_log_days_old * 86400 );

# if loading subboard list by ajax we don't need this (Ajax showcasepoll load does not work, assume this is mistake. DAR)

    my $polltemp;
    if ( -e "$datadir/showcase.poll" ) {
        fopen( SCPOLLFILE, "$datadir/showcase.poll" );
        my $scthreadnum = <SCPOLLFILE>;
        fclose(SCPOLLFILE);

        # Look for a valid poll file.
        my $pollthread;
        if ( -e "$datadir/$scthreadnum.poll" ) {
            MessageTotals( 'load', $scthreadnum );
            if ( $iamadmin || $iamgmod || $iamfmod ) {
                $pollthread = 1;
            }
            else {
                my $curcat = ${ $uid . ${$scthreadnum}{'board'} }{'cat'};
                my $catperms = ( split /\|/xsm, $catinfo{$curcat} )[1];
                if ( CatAccess($catperms) ) { $pollthread = 1; }
                my $boardperms =
                  ( split /\|/xsm, $board{ ${$scthreadnum}{'board'} } )[1];
                $pollthread =
                  AccessCheck( ${$scthreadnum}{'board'}, q{}, $boardperms ) eq
                  'granted' ? $pollthread : 0;
            }
            if ( ${ $uid . $scboard }{'brdpasswr'} && !$iamadmin && !$iamgmod )
            {
                my $pswiammod = 0;
                my $bdmods    = ${ $uid . $curboard }{'mods'};
                $bdmods =~ s/\, /\,/gsm;
                $bdmods =~ s/\ /\,/gsm;
                foreach my $curuser ( split /\,/xsm, $bdmods ) {
                    if ( $username eq $curuser ) { $pswiammod = 1; last; }
                }
                my $bdmodgroups = ${ $uid . $scboard }{'modgroups'};
                $bdmodgroups =~ s/\, /\,/gsm;
                foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                    if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                        $pswiammod = 1;
                        last;
                    }
                    foreach my $memberaddgroups ( split /\, /xsm,
                        ${ $uid . $username }{'addgroups'} )
                    {
                        chomp $memberaddgroups;
                        if ( $memberaddgroups eq $curgroup ) {
                            $pswiammod = 1;
                            last;
                        }
                    }
                }
                my $bpasscookie =
                  "$cookiepassword$scboard$username$cookieother_name";
                my $crypass = ${ $uid . $scboard }{'brdpassw'};
                if ( !$pswiammod && $yyCookies{$bpasscookie} ne $crypass ) {
                    $pollthread = 0;
                }
            }
        }

        if ($pollthread) {
            my $tempcurrentboard = $currentboard;
            $currentboard = ${$scthreadnum}{'board'};
            my $tempstaff = $staff;
            if ( !$iamadmin && !$iamgmod && !$iamfmod ) { $staff = 0; }
            require Sources::Poll;
            display_poll( $scthreadnum, 1 );
            $staff        = $tempstaff;
            $polltemp     = $pollmain . '<br />';
            $currentboard = $tempcurrentboard;
        }
    }

    # showcase poll end

    foreach my $curboard (@loadboards) {
        chomp $curboard;

        my $iammodhere = q{};
        foreach my $curuser ( split /, ?/sm, ${ $uid . $curboard }{'mods'} ) {
            if ( $username eq $curuser ) { $iammodhere = 1; }
        }
        foreach
          my $curgroup ( split /, /sm, ${ $uid . $curboard }{'modgroups'} )
        {
            if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                $iammodhere = 1;
            }
            foreach ( split /,/xsm, ${ $uid . $username }{'addgroups'} ) {
                if ( $_ eq $curgroup ) { $iammodhere = 1; last; }
            }
        }

# if this is a parent board and it can't be posted in, set lastposttime to 0 so subboards will show latest data
        if ( $subboard{$curboard} && !${ $uid . $curboard }{'canpost'} ) {
            ${ $uid . $curboard }{'lastposttime'} = 0;
        }

        $lastposttime = ${ $uid . $curboard }{'lastposttime'};

      # hide hidden threads for ordinary members and guests in all loaded boards
        if (   !$iammodhere
            && !$iamadmin
            && !$iamgmod
            && !$iamfmod
            && ${ $uid . $curboard }{'lasttopicstate'} =~ /h/ism )
        {
            ${ $uid . $curboard }{'lastpostid'}   = q{};
            ${ $uid . $curboard }{'lastsubject'}  = q{};
            ${ $uid . $curboard }{'lastreply'}    = q{};
            ${ $uid . $curboard }{'lastposter'}   = $boardindex_txt{'470'};
            ${ $uid . $curboard }{'lastposttime'} = q{};
            $lastposttime{$curboard} = $boardindex_txt{'470'};
            my ( $messageid, $messagestate );
            fopen( MNUM, "$boardsdir/$curboard.txt" );
            my @threadlist = <MNUM>;
            fclose(MNUM);

            foreach (@threadlist) {
                (
                    $messageid, undef, undef, undef, undef,
                    undef,      undef, undef, $messagestate
                ) = split /\|/xsm, $_;
                if ( $messagestate !~ /h/ism ) {
                    fopen( FILE, "$datadir/$messageid.txt" ) || next;
                    my @lastthreadmessages = <FILE>;
                    fclose(FILE);
                    my @lastmessage = split /\|/xsm, $lastthreadmessages[-1], 6;
                    ${ $uid . $curboard }{'lastpostid'}  = $messageid;
                    ${ $uid . $curboard }{'lastsubject'} = $lastmessage[0];
                    ${ $uid . $curboard }{'lastreply'}   = $#lastthreadmessages;
                    ${ $uid . $curboard }{'lastposter'} =
                      $lastmessage[4] eq 'Guest'
                      ? qq~Guest-$lastmessage[1]~
                      : $lastmessage[4];
                    ${ $uid . $curboard }{'lastposttime'} = $lastmessage[3];
                    $lastposttime{$curboard} = timeformat( $lastmessage[3] );
                    $lastposttime{$curboard2} = timeformat( $lastmessage[3],0,0,0,1 );
                    last;
                }
            }
        }

        ${ $uid . $curboard }{'lastposttime'} =
          ( ${ $uid . $curboard }{'lastposttime'} eq 'N/A'
              || !${ $uid . $curboard }{'lastposttime'} )
          ? $boardindex_txt{'470'}
          : ${ $uid . $curboard }{'lastposttime'};
        if (   ${ $uid . $curboard }{'lastposttime'} ne 'N/A'
            && ${ $uid . $curboard }{'lastposttime'} > 0 )
        {
            $lastposttime{$curboard} =
              timeformat( ${ $uid . $curboard }{'lastposttime'} );
            $lastposttime{$curboard2} =
              timeformat( ${ $uid . $curboard }{'lastposttime'},0,0,0,1 );
        }
        else { $lastposttime{$curboard} = $boardindex_txt{'470'}; }

        $lastpostrealtime{$curboard} =
          ( ${ $uid . $curboard }{'lastposttime'} eq 'N/A'
              || !${ $uid . $curboard }{'lastposttime'} )
          ? 0
          : ${ $uid . $curboard }{'lastposttime'};

        $lsreply{$curboard} = ${ $uid . $curboard }{'lastreply'} + 1;
        if ( ${ $uid . $curboard }{'lastposter'} =~ m{\AGuest-(.*)}xsm ) {
            ${ $uid . $curboard }{'lastposter'} = $1 . " ($maintxt{'28'})";
            $lastposterguest{$curboard} = 1;
        }

        ${ $uid . $curboard }{'lastposter'} =
          ${ $uid . $curboard }{'lastposter'} eq 'N/A'
          || !${ $uid . $curboard }{'lastposter'}
          ? $boardindex_txt{'470'}
          : ${ $uid . $curboard }{'lastposter'};

        ${ $uid . $curboard }{'messagecount'} =
          ${ $uid . $curboard }{'messagecount'} || 0;

        ${ $uid . $curboard }{'threadcount'} =
          ${ $uid . $curboard }{'threadcount'} || 0;

        $totalm += ${ $uid . $curboard }{'messagecount'};
        $totalt += ${ $uid . $curboard }{'threadcount'};

        if (
              !$iamguest
            && $max_log_days_old
            && $lastpostrealtime{$curboard}
            && (
                (
                      !$yyuserlog{$curboard}
                    && $lastpostrealtime{$curboard} > $dmax
                )
                || (   $yyuserlog{$curboard} > $dmax
                    && $yyuserlog{$curboard} < $lastpostrealtime{$curboard} )
            )
          )
        {
            $new_boards{$curboard} = 1;
        }

        # determine the true last post on all the boards a user has access to
        if ( ${ $uid . $curboard }{'lastposttime'} > $lastthreadtime
            && $lastposttime{$curboard} ne $boardindex_txt{'470'} )
        {
            my $cookiename = "$cookiepassword$curboard$username";
            my $crypass    = ${ $uid . $curboard }{'brdpassw'};
            if ( !${ $uid . $curboard }{'brdpasswr'} ) {
                $lsdatetime     = $lastposttime{$curboard2};
                $lsposter       = ${ $uid . $curboard }{'lastposter'};
                $lssub          = ${ $uid . $curboard }{'lastsubject'};
                $lspostid       = ${ $uid . $curboard }{'lastpostid'};
                $lsreply        = ${ $uid . $curboard }{'lastreply'};
                $lastthreadtime = ${ $uid . $curboard }{'lastposttime'};
                $lspostbd       = $curboard;
            }
            elsif ( $yyCookies{$cookiename} eq $crypass || $staff ) {
                $lsdatetime     = $lastposttime{$curboard2};
                $lsposter       = ${ $uid . $curboard }{'lastposter'};
                $lssub          = ${ $uid . $curboard }{'lastsubject'};
                $lspostid       = ${ $uid . $curboard }{'lastpostid'};
                $lsreply        = ${ $uid . $curboard }{'lastreply'};
                $lastthreadtime = ${ $uid . $curboard }{'lastposttime'};
                $lspostbd       = $curboard;
            }
        }
    }

# make a copy of new boards has to update the tree if a sub board has a new post, but keep original so we know which individual boards are new
    my %new_icon = %new_boards;

    # count boards to see if we print anything when we're looking for subboards
    my $brd_count;
    LoadCensorList();
    foreach my $catid (@tmplist) {
        if (   $INFO{'catselect'} ne $catid
            && $INFO{'catselect'}
            && !$subboard_sel )
        {
            next;
        }

        my ( $catname, $catperms, $catallowcol, $catimage, $catrss );

        # get boards in category if we're not looking for subboards
        if ( !$subboard_sel ) {
            (@bdlist) = split /\,/xsm, $cat{$catid};
            ( $catname, $catperms, $catallowcol, $catimage, $catrss ) =
              split /\|/xsm, $catinfo{$catid};
            ToChars($catname);

            # Category Permissions Check
            $cataccess = CatAccess($catperms);
            if ( !$cataccess ) { next; }
        }
        else {
            (@bdlist) = split /\|/xsm, $subboard{$catid};
            my ( $boardname, $boardperms, $boardview ) =
              split /\|/xsm, $board{$catid};
            ToChars($boardname);
            ( $catname, $catperms, $catallowcol, $catimage ) =
              ( qq~$boardindex_txt{'65'} '$boardname'~, 0, 0, q{} );
        }

        # Skip any empty categories.
        if ( $cat_boardcnt{$catid} == 0 && !$subboard_sel ) { next; }

        if ( !$iamguest ) {
            my $newmsg = 0;
            $newms{$catname}       = q{};
            $newrowicon{$catname}  = q{};
            $newrowstart{$catname} = q{};
            $newrowend{$catname}   = q{};
            $collapse_link         = q{};
            $mnew                  = q{};

            if ($catallowcol) {
                $collapse_link =
qq~<a href="javascript:SendRequest('$scripturl?action=collapse_cat;cat=$catid','$catid','$imagesdir','$boardindex_exptxt{'2'}','$boardindex_exptxt{'1'}')">~;
            }

# loop through any collapsed boards to find new posts in it and change the image to match
# Now shows this whether minimized or not, for Javascript hiding/showing. (Unilat)
            if ( $INFO{'catselect'} eq q{} ) {
                foreach my $boardinfo (@goodboards) {
                    my $testcat;
                    ( $testcat, $curboard ) = split /\|/xsm, $boardinfo;
                    if ( $testcat ne $catid ) { next; }

# as we fill the vars based on all boards we need to skip any cat already shown before
                    if ( $new_icon{$curboard} ) {
                        my ( undef, $boardperms, $boardview ) =
                          split /\|/xsm, $board{$curboard};
                        if ( AccessCheck( $curboard, q{}, $boardperms ) eq
                            'granted' )
                        {
                            $newmsg = 1;
                        }
                    }
                }

                if ($catallowcol) {
                    $template_catnames .= qq~"$catid",~;
                    $newrowend{$catname} = $brd_newrowend;
                    if ( $catcol{$catid} ) {
                        $my_brdrow = $brd_newrow;
                        $my_brdrow =~ s/{yabb new_msg_bg}/$new_msg_bg/sm;
                        $my_brdrow =~ s/{yabb new_msg_class}/$new_msg_class/sm;
                        $newrowstart{$catname} = $my_brdrow;
                        $template_boardtable = qq~id="$catid"~;
                        $template_colboardtable =
                          qq~id="col$catid" style="display:none"~;
                    }
                    else {
                        $my_brdrow = $brd_newrow;
                        $my_brdrow =~ s/{yabb new_msg_bg}/$new_msg_bg/sm;
                        $my_brdrow =~ s/{yabb new_msg_class}/$new_msg_class/sm;
                        $newrowstart{$catname} = $my_brdrow;
                        $template_boardtable =
                          qq~id="$catid" style="display:none;"~;
                        $template_colboardtable = qq~id="col$catid"~;
                    }
                    if ($newmsg) {
                        $mnew = q{new_} . $curboard;
                        $newrowicon{$catname} =
qq~<img src="$imagesdir/$newload{'brd_new'}" alt="$boardindex_txt{'333'}" title="$boardindex_txt{'333'}" class="ongif" id="$mnew" />~;
                        $newms{$catname} = $boardindex_exptxt{'5'};
                    }
                    else {
                        $newrowicon{$catname} =
qq~<img src="$imagesdir/$newload{'brd_old'}" alt="$boardindex_txt{'334'}" title="$boardindex_txt{'334'}" class="ongif" />~;
                        $newms{$catname} = $boardindex_exptxt{'6'};
                    }
                    if ( $catcol{$catid} ) {
                        $hash{$catname} =
qq~<img src="$imagesdir/$newload{'brd_col'}" id="img$catid" alt="$boardindex_exptxt{'2'}" title="$boardindex_exptxt{'2'}" /></a>~;
                    }
                    else {
                        $hash{$catname} =
qq~<img src="$imagesdir/$newload{'brd_exp'}" id="img$catid" alt="$boardindex_exptxt{'1'}" title="$boardindex_exptxt{'1'}" /></a>~;
                    }
                }
                else {
                    $template_boardtable = qq~id="$catid"~;
                    $template_colboardtable =
                      qq~id="col$catid" style="display:none;"~;
                }
            }
            else {
                $collapse_link       = q{};
                $hash{$catname}      = q{};
                $template_boardtable = qq~id="$catid"~;
                $template_colboardtable =
                  qq~id="col$catid" style="display:none;"~;
            }

            if ( $cat{$catid} && !$INFO{'board'} ) { $my_cat = 'catselect'; }
            else                                   { $my_cat = 'boardselect'; }
            $catlink =
qq~$collapse_link $hash{$catname} <a href="$scripturl?$my_cat=$catid" title="$boardindex_txt{'797'} $catname">$catname</a>~;
        }
        else {
            if ( $cat{$catid} && !$INFO{'board'} ) { $my_cat = 'catselect'; }
            else                                   { $my_cat = 'boardselect'; }
            $template_boardtable    = qq~id="$catid"~;
            $template_colboardtable = qq~id="col$catid" style="display:none;"~;
            $catlink = qq~<a href="$scripturl?$my_cat=$catid">$catname</a>~;
        }

        # Don't need the category headers if we're loading ajax subboards
        if ( !$INFO{'a'} ) {
            if ( !$rss_disabled && $catrss ) {
                $rss_catlink =
qq~<a href="$scripturl?action=RSSrecent;catselect=$catid" target="_blank"><img src="$micon_bg{'boardrss'}" alt="$maintxt{'rssfeed'} - $catname" title="$maintxt{'rssfeed'} - $catname" /></a>~;
            }
            else {
                $rss_catlink = q{};
            }
            $templatecat = $catheader;
            $tmpcatimg   = q{};
            $imgid = $brd_img_id{$catid};
            if ( $catimage ne q{} ) {
                if ( $catimage =~ /\//ism ) {
                    $catimage = qq~<img src="$catimage" alt="" id="brd_id_$imgid" onload="resize_brd_images(this);" />~;
                }
                elsif ($catimage) {
                    $catimage = qq~<img src="$imagesdir/$catimage" alt="" id="brd_id_$imgid" onload="resize_brd_images(this);" />~;
                }
                $tmpcatimg = qq~$catimage~;
            }
            $templatecat =~ s/{yabb catimage}/$tmpcatimg/gsm;
            $templatecat =~ s/{yabb catrss}/$rss_catlink/gsm;
            $templatecat =~ s/{yabb catlink}/$catlink/gsm;
            $templatecat =~ s/{yabb newmsg start}/$newrowstart{$catname}/gsm;
            $templatecat =~ s/{yabb newmsg icon}/$newrowicon{$catname}/gsm;
            $templatecat =~ s/{yabb newmsg}/$newms{$catname}/gsm;
            $templatecat =~ s/{yabb newmsg end}/$newrowend{$catname}/gsm;
            $templatecat =~ s/{yabb boardtable}/$template_boardtable/gsm;
            $templatecat =~ s/{yabb colboardtable}/$template_colboardtable/gsm;
            $tmptemplateblock .= $templatecat;
        }

        my $alternateboardcolor = 0;

        # Moved this out of for loop. Gets the latest data for sub boards
        *find_latest_data = sub {
            my ( $parentbd, @children ) = @_;
            $childcnt{$parentbd}    = 0;
            $sub_new_cnt{$parentbd} = 0;
            foreach my $childbd (@children) {

# make recursive call first so we can get latest post data working from bottom up.
                if ( $subboard{$childbd} ) {
                    find_latest_data( $childbd, split /\|/xsm,
                        $subboard{$childbd} );
                }

                # don't check sub board if its lastposttime is N/A
                if ( ${ $uid . $childbd }{'lastposttime'} ne
                    $boardindex_txt{'470'} )
                {

                  # update parent board last data if this child's is more recent
                    if ( $lastpostrealtime{$childbd} >
                        $lastpostrealtime{$parentbd} )
                    {
                        $lastposttime{$parentbd} = $lastposttime{$childbd};
                        $lastpostrealtime{$parentbd} =
                          $lastpostrealtime{$childbd};
                        ${ $uid . $parentbd }{'lastposttime'} =
                          ${ $uid . $childbd }{'lastposttime'};
                        ${ $uid . $parentbd }{'lastposter'} =
                          ${ $uid . $childbd }{'lastposter'};
                        ${ $uid . $parentbd }{'lastpostid'} =
                          ${ $uid . $childbd }{'lastpostid'};
                        ${ $uid . $parentbd }{'lastreply'} =
                          ${ $uid . $childbd }{'lastreply'};
                        ${ $uid . $parentbd }{'lastsubject'} =
                          ${ $uid . $childbd }{'lastsubject'};
                        ${ $uid . $parentbd }{'lasticon'} =
                          ${ $uid . $childbd }{'lasticon'};
                        ${ $uid . $parentbd }{'lasttopicstate'} =
                          ${ $uid . $childbd }{'lasttopicstate'};
                    }
                }

                # Add to totals
                ${ $uid . $parentbd }{'threadcount'} +=
                  ${ $uid . $childbd }{'threadcount'};
                ${ $uid . $parentbd }{'messagecount'} +=
                  ${ $uid . $childbd }{'messagecount'};

      # but if it's a parent board that can't be posted in, don't add to totals.
                if ( $subboard{$childbd} && !${ $uid . $childbd }{'canpost'} ) {
                    ${ $uid . $parentbd }{'threadcount'} -=
                      ${ $uid . $childbd }{'threadcount'};
                    ${ $uid . $parentbd }{'messagecount'} -=
                      ${ $uid . $childbd }{'messagecount'};
                }
                if ( $new_icon{$childbd} ) {

                    # parent board gets new status if child has something new
                    $new_icon{$parentbd} = $new_icon{$childbd};

                    # count sub boards with new posts
                    $sub_new_cnt{$parentbd}++;
                }

                $childcnt{$parentbd}++;
            }
        };
        if (  !$INFO{'oldcollapse'}
            || $catcol{$catid}
            || $INFO{'catselect'} ne q{}
            || $iamguest )
        {    # deti
            foreach my $boardinfo (@goodboards) {
                my $testcat;
                ( $testcat, $curboard ) = split /\|/xsm, $boardinfo;
                if ( $testcat ne $catid ) { next; }

                $brd_count++;

                # let's add this to javascript array of good boards.
                $template_boardnames .= qq~"$curboard",~;

# first off, lets find the most recent post data and total sub board posts/threads
                if ( $subboard{$curboard} ) {

# if its a parent board that cant be posted in, don't count its threads/posts towards total
                    if ( !${ $uid . $curboard }{'canpost'} ) {
                        ${ $uid . $curboard }{'threadcount'}  = 0;
                        ${ $uid . $curboard }{'messagecount'} = 0;
                    }

                    find_latest_data( $curboard, split /\|/xsm,
                        $subboard{$curboard} );
                }

                ( $boardname, $boardperms, $boardview ) =
                  split /\|/xsm, $board{$curboard};
                ToChars($boardname);
                $INFO{'zeropost'} = 0;
                $zero             = q{};
                $bdpic = qq~$imagesdir/boards.$bdpicExt~;
                fopen( BRDPIC, "<$boardsdir/brdpics.db" );
                my @brdpics = <BRDPIC>;
                fclose( BRDPIC);
                chomp @brdpics;
                for (@brdpics) {
                    my ( $brdnm, $style, $brdpic ) = split /[|]/xsm, $_;
                    if ( $brdnm eq $curboard && $usestyle eq $style ) {
                        if ( $brdpic =~ /\//ism ) {
                            $bdpic = $brdpic;
                            last;
                        }
                        else {
                            if ( -e "$htmldir/Templates/Forum/$useimages/Boards/$brdpic" ) {
                                $bdpic = qq~$imagesdir/Boards/$brdpic~;
                            }
                            else { $bdpic = qq~$imagesdir/boards.$bdpicExt~; }
                            last;
                        }
                    }
                    else {
                        if ( $boardname =~ m/[ht|f]tp[s]{0,1}:\/\//sm  ) {
                            $bdpic = qq~$imagesdir/$extern~;
                        }
                        else {$bdpic = qq~$imagesdir/boards.$bdpicExt~; }
                    }
                }

                if ( ${ $uid . $curboard }{'ann'} == 1 ) {
                    $bdpic = qq~$imagesdir/ann.$bdpicExt~;
                }
                if ( ${ $uid . $curboard }{'rbin'} == 1 ) {
                    $bdpic = qq~$imagesdir/recycle.$bdpicExt~;
                }
                $bddescr          = ${ $uid . $curboard }{'description'};
                ToChars($bddescr);
                $iammod     = q{};
                %moderators = ();
                my $curmods = ${ $uid . $curboard }{'mods'};

                foreach my $curuser ( split /, ?/sm, $curmods ) {
                    if ( $username eq $curuser ) { $iammod = 1; }
                    LoadUser($curuser);
                    $moderators{$curuser} = ${ $uid . $curuser }{'realname'};
                }
                $showmods = q{};
                if ( keys %moderators == 1 ) {
                    $showmods = qq~$boardindex_txt{'298'}: ~;
                }
                elsif ( keys %moderators != 0 ) {
                    $showmods = qq~$boardindex_txt{'63'}: ~;
                }
                while ( $tmpa = each %moderators ) {
                    FormatUserName($tmpa);
                    $showmods .= QuickLinks( $tmpa, 1 ) . q{, };
                }
                $showmods =~ s/, \Z//sm;

                LoadUser($username);
                %moderatorgroups = ();
                foreach my $curgroup ( split /, /sm,
                    ${ $uid . $curboard }{'modgroups'} )
                {
                    if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                        $iammod = 1;
                    }
                    foreach ( split /,/xsm, ${ $uid . $username }{'addgroups'} )
                    {
                        if ( $_ eq $curgroup ) { $iammod = 1; last; }
                    }
                    ( $thismodgrp, undef ) =
                      split /\|/xsm, $NoPost{$curgroup}, 2;
                    $moderatorgroups{$curgroup} = $thismodgrp;
                }

                $showmodgroups = q{};
                if ( scalar keys %moderatorgroups == 1 ) {
                    $showmodgroups = qq~$boardindex_txt{'298a'}: ~;
                }
                elsif ( scalar keys %moderatorgroups != 0 ) {
                    $showmodgroups = qq~$boardindex_txt{'63a'}: ~;
                }
                while ( $tmpa = each %moderatorgroups ) {
                    $showmodgroups .= qq~$moderatorgroups{$tmpa}, ~;
                }
                $showmodgroups =~ s/, \Z//sm;
                if ( $showmodgroups eq q{} && $showmods eq q{} ) {
                    $showmodgroups = q~<br />~;
                }
                if ( $showmodgroups ne q{} && $showmods ne q{} ) {
                    $showmods .= q~<br />~;
                }

                if ($iamguest) {
                    $new  = q{};
                    $new2 = q{};
                }
                elsif ( $new_icon{$curboard} ) {
                    my ( undef, $boardperms, $boardview ) =
                      split /\|/xsm, $board{"$curboard"};
                    if ( AccessCheck( $curboard, q{}, $boardperms ) eq
                        'granted' )
                    {
                        $mnew = q{new_} . $curboard;
                        $new =
qq~<img src="$imagesdir/$newload{'brd_new'}" alt="$boardindex_txt{'333'}" title="$boardindex_txt{'333'}" class="img_new" id="$mnew" />~;
                        $new2 =
qq~<img src="$imagesdir/$newload{'sub_brd_new'}" alt="$boardindex_txt{'333'}" title="$boardindex_txt{'333'}" class="img_new" id="$mnew" />~;

                    }
                    else {
                        $new =
qq~<img src="$imagesdir/$newload{'brd_old'}" alt="$boardindex_txt{'334'}" title="$boardindex_txt{'334'}" class="img_new" />~;
                    }
                }
                else {
                    $new =
qq~<img src="$imagesdir/$newload{'brd_old'}" alt="$boardindex_txt{'334'}" title="$boardindex_txt{'334'}" />~;
                }
                $lastposter = ${ $uid . $curboard }{'lastposter'};
                $lastposter =~ s/\AGuest-(.*)/$1 ($maintxt{'28'})/ism;

                if ( !$lastposterguest{$curboard}
                    && ${ $uid . $curboard }{'lastposter'} ne
                    $boardindex_txt{'470'} )
                {
                    LoadUser($lastposter);
                    if (
                        (
                               ${ $uid . $lastposter }{'regdate'}
                            && ${ $uid . $curboard }{'lastposttime'} >
                            ${ $uid . $lastposter }{'regtime'}
                        )
                        || ${ $uid . $lastposter }{'position'} eq
                        'Administrator'
                        || ${ $uid . $lastposter }{'position'} eq
                        'Global Moderator'
                      )
                    {
                        if ( $iamguest ) {
                            $lastposter = qq~$format_unbold{$lastposter}~;
                        }
                        else {
                            $lastposter =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$lastposter}" rel="nofollow">$format_unbold{$lastposter}</a>~;
                        }
                    }
                    else {

            # Need to load thread to see lastposters DISPLAYname if is Ex-Member
                        fopen( EXMEMBERTHREAD,
                            "$datadir/${$uid.$curboard}{'lastpostid'}.txt" )
                          or fatal_error( 'cannot_open',
                            "$datadir/${$uid.$curboard}{'lastpostid'}.txt", 1 );
                        my @x = <EXMEMBERTHREAD>;
                        fclose(EXMEMBERTHREAD);
                        @lstp = split /\|/xsm, $x[-1];
                        if ( $lstp[4] eq 'Guest') {
                            $lastposter = qq~$lstp[1] ($maintxt{'28'})~;
                        }
                        else { $lastposter = qq~$lstp[1] - $boardindex_txt{'470a'}~; }
                    }
                }
                ${ $uid . $curboard }{'lastposter'} = isempty( ${ $uid . $curboard }{'lastposter'}, $boardindex_txt{'470'} );
                ${ $uid . $curboard }{'lastposttime'} = isempty( ${ $uid . $curboard }{'lastposttime'}, $boardindex_txt{'470'} );

                my $templateblock = $boardblock;

                # if we can't post in this parent board, change the layout
                if ( $subboard{$curboard} && !${ $uid . $curboard }{'canpost'} )
                {
                    $templateblock = $nopost_boardblock;
                }

                my $lasttopictxt = ${ $uid . $curboard }{'lastsubject'};
                ( $lasttopictxt, undef ) =
                  Split_Splice_Move( $lasttopictxt, 0 );
                my $fulltopictext = $lasttopictxt;

                $convertstr = $lasttopictxt;
                $convertcut = $topiccut ? $topiccut : 15;
                CountChars();
                $lasttopictxt = $convertstr;
                if ($cliped) { $lasttopictxt .= q{...}; }

                ToChars($lasttopictxt);
                $lasttopictxt = Censor($lasttopictxt);

                ToChars($fulltopictext);
                $fulltopictext = Censor($fulltopictext);

                if ( ${ $uid . $curboard }{'lastreply'} ne q{} ) {
                    $lastpostlink =
qq~<a href="$scripturl?num=${$uid.$curboard}{'lastpostid'}/${$uid.$curboard}{'lastreply'}#${$uid.$curboard}{'lastreply'}" title="$boardindex_txt{'22'}">$img{'lastpost'}</a> $lastposttime{$curboard}~;
                }
                else {
                    $lastpostlink = qq~$img{'lastpost'} $boardindex_txt{'470'}~;
                }

                if ( !$rss_disabled ) {
                    my ( undef, $boardperms, $boardview ) = split /\|/xsm,
                      $board{"$curboard"};
                    if ( AccessCheck( $curboard, q{}, $boardperms ) eq 'granted'
                        && ${ $uid . $curboard }{'brdrss'} == 1 )
                    {
                        $rss_boardlink =
qq~<a href="$scripturl?action=RSSboard;board=$curboard" target="_blank"><img src="$micon_bg{'boardrss'}" alt="$maintxt{'rssfeed'} - $boardname" title="$maintxt{'rssfeed'} - $boardname" /></a>~;
                    }
                    else {
                        $rss_boardlink = q{};
                    }
                }

    # if we have subboards, check to see if there's something new and print name
                my $template_subboards;
                my $tmp_sublist = q{};
                my $sub_count;
                if ( $subboard{$curboard} ) {
                    my @childboards = split /\|/xsm, $subboard{$curboard};
                    $tmp_sublist = $subboard_list;
                    foreach my $childbd (@childboards) {
                        my $tmp_sublinks = $subboard_links_ext;
                        my ( $chldboardname, $chldboardperms, $chldboardview ) =
                          split /\|/xsm, $board{$childbd};
                        my $access =
                          AccessCheck( $childbd, q{}, $chldboardperms );
                        if (  !$iamadmin
                            && $access ne 'granted'
                            && $chldboardview != 1 )
                        {
                            next;
                        }
                        ToChars($chldboardname);
                        $sub_count++;

                        $cookiename = "$cookiepassword$childbd$username";
                        $crypass    = ${ $uid . $childbd }{'brdpassw'};
                        $sub_lock   = q{};
                        if ($crypass) {
                            if ( $staff || $yyCookies{$cookiename} eq $crypass )
                            {
                                $sub_lock = qq~ $micon{'lockopen_sub'}~;
                            }
                            else {
                                $sub_lock = qq~ $micon{'lockimg_sub'}~;
                            }
                        }

                        # get new icon
                        if ($iamguest) {
                            $sub_new = q{};
                        }
                        elsif ( $new_icon{$childbd} ) {
                            $mnew = q{new_} . $childbd . q{_sub};
                            $sub_new =
qq~<img src="$imagesdir/$newload{'sub_brd_new'}" alt="$boardindex_txt{'333'}" title="$boardindex_txt{'333'}" id="$mnew" />~;
                        }
                        else {
                            $sub_new =
qq~<img src="$imagesdir/$newload{'sub_brd_old'}" alt="$boardindex_txt{'334'}" title="$boardindex_txt{'334'}" />~;
                        }

                        my $boardinfotxt =
                            $new_boards{$childbd}
                          ? $boardindex_txt{'67'}
                          : $boardindex_txt{'68'};
                        if ( $subboard{$childbd} ) {
                            if ( $childcnt{$childbd} > 1 ) {
                                $boardinfotxt .=
qq~ $sub_new_cnt{$childbd} $boardindex_txt{'69'} $childcnt{$childbd} $boardindex_txt{'70'}~;
                            }
                            else {
                                if ( $sub_new_cnt{$childbd} ) {
                                    $boardinfotxt .=
qq~ $childcnt{$childbd} $boardindex_txt{'71'}~;
                                }
                                else {
                                    $boardinfotxt .=
qq~ $childcnt{$childbd} $boardindex_txt{'72'}~;
                                }
                            }
                        }

                        if ( $chldboardname =~ m/[ht|f]tp[s]{0,1}:\/\//sm ) {
                            $tmp_sublinks = $subboard_links_ext;
                            $bdd          = q{};
                            $my_bddescr   = ${ $uid . $childbd }{'description'};
                            my @bname = split /<br \/>/sm, $my_bddescr;
                            $boardname = qq~$scripturl\?action\=showexternal;exboard\=$childbd~;
                            $tmp_sublinks =~ s/{yabb boardurl}/$boardname/gsm;
                            $tmp_sublinks =~ s/{yabb new}/$new/gsm;
                            $tmp_sublinks =~ s/{yabb boardname}/$bname[0]/gsm;
                            $tmp_sublinks =~ s/{yabb sub_lock}/$sub_lock/gsm;
                        }
                        else {
                            $tmp_sublinks = $subboard_links;
                            $tmp_sublinks =~ s/{yabb boardname}/$chldboardname/gsm;
                            $tmp_sublinks =~ s/{yabb boardurl}/$scripturl\?board\=$childbd/gsm;
                            $tmp_sublinks =~ s/{yabb new}/$sub_new/gsm;
                            $tmp_sublinks =~ s/{yabb sub_lock}/$sub_lock/gsm;
                            $tmp_sublinks =~ s/{yabb boardinfo}/$boardinfotxt/gsm;
                        }
                        $template_subboards .= qq~$tmp_sublinks, ~;
                    }
                    $template_subboards =~ s/, $//gsm;

                    my $sub_txt = $boardindex_txt{'64'};

                    if ( $sub_count == 1 ) { $sub_txt = $boardindex_txt{'66'}; }
                    elsif ( $sub_count == 0 ) {
                        $sub_txt     = q{};
                        $tmp_sublist = q{};
                    }

# drop down arrow for expanding sub boards
# only do this if 1 or more sub boards and if this is an ajax call we do not want infinite levels of subboards
                    my $subdropdown;
                    if ( $sub_count > 0 ) {

                     # do not make an ajax dropdown if we are calling from ajax.
                        if ( $INFO{'a'} ) {
                            $subdropdown = qq~$sub_txt~;
                        }
                        else {
                            $subdropdown =
qq~<a href="javascript:void(0)" id="subdropa_$curboard" style="font-weight:bold" onclick="SubBoardList('$scripturl?board=$curboard','$curboard','$catid',$sub_count,$alternateboardcolor)"><img src="$imagesdir/$sub_arrow_dn" id="subdropbutton_$curboard" class="sub_drop" alt="" />&nbsp;$sub_txt</a>~;
                        }
                    }
                    $tmp_sublist =~
                      s/{yabb subboardlinks}/$template_subboards/gsm;
                    $tmp_sublist =~ s/{yabb subdropdown}/$subdropdown/gsm;
                }

                my $altbrdcolor =
                  ( ( $alternateboardcolor % 2 ) == 1 )
                  ? 'windowbg'
                  : 'windowbg2';
                my $boardanchor = $curboard;
                if ( $boardanchor =~ m{\A[^az]}ism ) {
                    $boardanchor =~ s/(.*?)/b$1/xsm;
                }
                my $lasttopiclink =
qq~<a href="$scripturl?num=${$uid.$curboard}{'lastpostid'}/${$uid.$curboard}{'lastreply'}#${$uid.$curboard}{'lastreply'}" title="$fulltopictext">$lasttopictxt</a>~;
                my $boardpwpic = q{};
                my $crypass;
                if ( ${ $uid . $curboard }{'brdpasswr'} ) {
                    my $cookiename = "$cookiepassword$curboard$username";
                    $crypass = ${ $uid . $curboard }{'brdpassw'};
                    if (  !$staff
                        && $yyCookies{$cookiename} ne $crypass )
                    {
                        $boardpwpic    = qq~$micon{'lockimg'}~;
                        $lastpostlink  = qq~$maintxt{'900pr'}~;
                        $lasttopiclink = q~~;
                        $lastposter    = q~~;
                        $templateblock = $boardblockpw;
                    }
                    else {
                        $boardpwpic = qq~$micon{'lockopen'}~;
                    }
                }
                if ( ${ $uid . $curboard }{'threadcount'} < 0 ) {
                    ${ $uid . $curboard }{'threadcount'} = 0;
                }
                if ( ${ $uid . $curboard }{'messagecount'} < 0 ) {
                    ${ $uid . $curboard }{'messagecount'} = 0;
                }
                ${ $uid . $curboard }{'threadcount'} =
                  NumberFormat( ${ $uid . $curboard }{'threadcount'} );
                ${ $uid . $curboard }{'messagecount'} =
                  NumberFormat( ${ $uid . $curboard }{'messagecount'} );

# if it's a parent board that cannot be posted in, just show sub board list when clicked vs. message index
                if ( $subboard{$curboard} && !${ $uid . $curboard }{'canpost'} )
                {
                    $templateblock =~ s/{yabb boardurl}/$scripturl\?boardselect\=$curboard/gsm;
                }
                else {
                    $templateblock =~ s/{yabb boardurl}/$scripturl\?board\=$curboard/gsm;
                }

                # Make hidden table rows for drop down message list
                $expandmessages = $brd_expandmessages;
                $expandmessages =~ s/{yabb curboard}/$curboard/gsm;
                $messagedropdown;
                ( $boardname, $boardperms, $boardview ) =
                  split /\|/xsm, $board{$curboard};
                $access = AccessCheck( $curboard, q{}, $boardperms );
                if (   ( $boardperms eq q{} && !$crypass )
                    || ( !$iamguest && $access eq 'granted' ) )
                {
                    $messagedropdown =
qq~    <img src="$imagesdir/$brd_dropdown" onclick="MessageList('$scripturl\?board\=$curboard;messagelist=1','$yyhtml_root','$curboard', 0)" id="dropbutton_$curboard" class="cursor" alt="" />~;
                }
                else { $messagedropdown = q{}; }

                $imgid = $brd_img_id{$curboard};
                $bdpic =
qq~ <img src="$bdpic" alt="$boardname" title="$boardname" id="brd_id_$imgid" onload="resize_brd_images(this);" /> ~;

                if ( $boardname !~ m/[ht|f]tp[s]{0,1}:\/\//sm ) {
                    $templateblock =~ s/{yabb expandmessages}/$expandmessages/gsm;
                    $templateblock =~ s/{yabb messagedropdown}/$messagedropdown/gsm;

                    $templateblock =~ s/{yabb boardanchor}/$boardanchor/gsm;
                    $templateblock =~ s/{yabb new}/$new/gsm;
                    $templateblock =~ s/{yabb boardrss}/$rss_boardlink/gsm;
                    $templateblock =~ s/{yabb newsm}/$new2/gsm;
                    $templateblock =~ s/{yabb boardpic}/$bdpic/gsm;
                    $templateblock =~ s/{yabb boardname}/$boardname $boardpwpic/gsm;
                    $templateblock =~ s/{yabb boarddesc}/$bddescr/gsm;
                    my $boardviewers;

                    if ( $bvusers{$curboard} ) {
                        $tmpboardviewers = NumberFormat($bvusers{$curboard});
                        $boardviewers = qq~&nbsp;($tmpboardviewers&nbsp;$boardindex_txt{'bviews'})~;
                    }
                    $templateblock =~ s/{yabb boardviewers}/$boardviewers/gsm;
                    $templateblock =~ s/{yabb moderators}/$showmods$showmodgroups/gsm;
                    $templateblock =~ s/{yabb threadcount}/${$uid.$curboard}{'threadcount'}/gsm;
                    $templateblock =~ s/{yabb messagecount}/${$uid.$curboard}{'messagecount'}/gsm;
                    $templateblock =~ s/{yabb lastpostlink}/$lastpostlink/gsm;
                    $templateblock =~ s/{yabb lastposter}/$lastposter/gsm;
                    $templateblock =~ s/{yabb lasttopiclink}/$lasttopiclink/gsm;
                    $templateblock =~ s/{yabb altbrdcolor}/$altbrdcolor/gsm;
                    $templateblock =~ s/{yabb subboardlist}/$tmp_sublist/gsm;
                }
                else {
                    $templateblock = $boardblockext;
                    $bdd           = q{};
                    my @bname = split /<br \/>/sm, $bddescr;
                    my $dcnt = @bname;
                    for my $i ( 1 .. ( $dcnt - 1 ) ) {
                        $bdd .= $bname[$i] . '<br />';
                    }
                    $boardname =
                      qq~$scripturl\?action\=showexternal;exboard\=$curboard~;
                    $my_blankext = q{--};
                    $templateblock =~ s/{yabb boardurl}/$boardname/gsm;
                    $templateblock =~ s/{yabb boardpic}/$bdpic/gsm;
                    $templateblock =~ s/{yabb boardname}/$bname[0]/gsm;
                    $templateblock =~ s/{yabb boarddesc}/$bdd/gsm;
                    $templateblock =~ s/{yabb threadcount}/$my_blankext/gsm;
                    $templateblock =~ s/{yabb messagecount}/$my_blankext/gsm;
                    $lastpostlink = RedirectExternalShow() || 0;
                    $templateblock =~ s/{yabb lastpostlink}/$lastpostlink/gsm;
                    $templateblock =~ s/{yabb altbrdcolor}/$altbrdcolor/gsm;
                    $templateblock =~ s/{yabb subboardlist}/$tmp_sublist/gsm;
                    $templateblock =~ s/{yabb boardanchor}/$curboard/gsm;
                }

                $tmptemplateblock .= $templateblock;

                $alternateboardcolor++;
            }
        }
        $tmptemplateblock .= $INFO{'a'} ? q{} : $catfooter;
        ++$catcount;
    }

    if ( !$iamguest && !$subboard_sel ) {
        if ( ${ $uid . $username }{'im_imspop'} ) {
            $yymain .= qq~\n\n<script type="text/javascript">
    function viewIM() { window.open("$scripturl?action=im"); }
    function viewIMOUT() { window.open("$scripturl?action=imoutbox"); }
    function viewIMSTORE() { window.open("$scripturl?action=imstorage"); }
</script>~;
        }
        else {
            $yymain .= qq~\n\n<script type="text/javascript">
    function viewIM() { location.href = ("$scripturl?action=im"); }
    function viewIMOUT() { location.href = ("$scripturl?action=imoutbox"); }
    function viewIMSTORE() { location.href = ("$scripturl?action=imstorage"); }
</script>~;
        }
        my $imsweredeleted = 0;
        if ( ${$username}{'PMmnum'} > $numibox && $numibox && $enable_imlimit )
        {
            Del_Max_IM( 'msg', $numibox );
            $imsweredeleted = ${$username}{'PMmnum'} - $numibox;
            $yymain .= qq~\n<script type="text/javascript">
    if (confirm('$boardindex_imtxt{'11'} ${$username}{'PMmnum'} $boardindex_imtxt{'12'} $boardindex_txt{'316'}, $boardindex_imtxt{'16'} $numibox $boardindex_imtxt{'18'}. $boardindex_imtxt{'19'} $imsweredeleted $boardindex_imtxt{'20'} $boardindex_txt{'316'} $boardindex_imtxt{'21'}')) viewIM();
</script>~;
            ${$username}{'PMmnum'} = $numibox;
        }
        if (   ${$username}{'PMmoutnum'} > $numobox
            && $numobox
            && $enable_imlimit )
        {
            Del_Max_IM( 'outbox', $numobox );
            $imsweredeleted = ${$username}{'PMmoutnum'} - $numobox;
            $yymain .= qq~\n<script type="text/javascript">
    if (confirm('$boardindex_imtxt{'11'} ${$username}{'PMmoutnum'} $boardindex_imtxt{'12'} $boardindex_txt{'320'}, $boardindex_imtxt{'16'} $numobox $boardindex_imtxt{'18'}. $boardindex_imtxt{'19'} $imsweredeleted $boardindex_imtxt{'20'} $boardindex_txt{'320'} $boardindex_imtxt{'21'}')) viewIMOUT();
</script>~;
            ${$username}{'PMmoutnum'} = $numobox;
        }
        if (   ${$username}{'PMstorenum'} > $numstore
            && $numstore
            && $enable_imlimit )
        {
            Del_Max_IM( 'imstore', $numstore );
            $imsweredeleted = ${$username}{'PMstorenum'} - $numstore;
            $yymain .= qq~\n<script type="text/javascript">
if (confirm('$boardindex_imtxt{'11'} ${$username}{'PMstorenum'} $boardindex_imtxt{'12'} $boardindex_imtxt{'46'}, $boardindex_imtxt{'16'} $numstore $boardindex_imtxt{'18'}. $boardindex_imtxt{'19'} $imsweredeleted $boardindex_imtxt{'20'} $boardindex_imtxt{'46'} $boardindex_imtxt{'21'}')) viewIMSTORE();
</script>~;
            ${$username}{'PMstorenum'} = $numstore;
        }
        if ($imsweredeleted) {
            buildIMS( $username, 'update' );
            LoadIMs();
        }

        $ims    = q{};
        $pm_lev = PMlev();
        if ( $pm_lev == 1 ) {
            $ims =
qq~$boardindex_txt{'795'} <a href="$scripturl?action=im"><b>${$username}{'PMmnum'}</b></a> $boardindex_txt{'796'}~;
            if ( ${$username}{'PMmnum'} > 0 ) {
                if ( ${$username}{'PMimnewcount'} == 1 ) {
                    $ims .=
qq~ <span class="newPM">$boardindex_imtxt{'24'} <a href="$scripturl?action=im"><b>${$username}{'PMimnewcount'}</b></a> $boardindex_imtxt{'25'}.</span>~;
                }
                else {
                    $ims .=
qq~ <span class="newPM">$boardindex_imtxt{'24'} <a href="$scripturl?action=im"><b>${$username}{'PMimnewcount'}</b></a> $boardindex_imtxt{'26'}.</span>~;
                }
            }
            else {
                $ims .= q~.~;
            }
        }

        if ( $INFO{'catselect'} eq q{} ) {
            if   ($colbutton) { $col_vis = q{}; }
            else              { $col_vis = q{ style="display:none;"}; }
            if ( ${ $uid . $username }{'cathide'} ) { $exp_vis = q{}; }
            else { $exp_vis = q{ style="display:none;"}; }

            $expandlink =
qq~<span id="expandall" $exp_vis><a href="javascript:Collapse_All('$scripturl?action=collapse_all;status=1',1,'$imagesdir','$boardindex_exptxt{'2'}')">$img{'expand'}</a>$menusep</span>~;
            $collapselink =
qq~<span id="collapseall" $col_vis><a href="javascript:Collapse_All('$scripturl?action=collapse_all;status=0',0,'$imagesdir','$boardindex_exptxt{'1'}')">$img{'collapse'}</a>$menusep</span>~;
            $markalllink =
qq~<a href="javascript:MarkAllAsRead('$scripturl?action=markallasread','$imagesdir','0','1')">$img{'markallread'}</a>~;
        }
        else {
            $markalllink =
qq~<a href="javascript:MarkAllAsRead('$scripturl?action=markallasread;cat=$INFO{'catselect'}','$imagesdir')">$img{'markallread'}</a>~;
            $collapselink = q{};
            $expandlink   = q{};
        }
    }

    if ( $totalt < 0 ) { $totalt = 0; }
    if ( $totalm < 0 ) { $totalm = 0; }
    $totalt = NumberFormat($totalt);
    $totalm = NumberFormat($totalm);

    # Template some stuff for sub boards before the rest
    $boardindex_template =~ s/{yabb catsblock}/$tmptemplateblock/gsm;

# no matter if this is ajax subboards, subboards at top of messageindex, or regular boardindex we need these vars now
    $brd_img_idw       = isempty( $max_brd_img_width, 50 );
    $brd_img_idh       = isempty( $max_brd_img_height, 50 );
    $fix_brd_img_size  = isempty( $fix_brd_img_size, 0 );
    $template_catnames =~ s/,\Z//xsm;
    $template_boardnames =~ s/,\Z//xsm;
    $yymain .= qq~
<script type="text/javascript">
    var catNames = [$template_catnames];
    var boardNames = [$template_boardnames];
    var boardOpen = "";
    var subboardOpen = "";
    var arrowup = '<img src="$imagesdir/$brd_arrowup" class="brd_arrow" alt="$boardindex_txt{'643'}" />';
    var openbutton = "$imagesdir/$brd_dropdown";
    var closebutton = "$imagesdir/$brd_dropup";
    var opensubbutton = "$imagesdir/$sub_arrow_dn";
    var closesubbutton = "$imagesdir/$sub_arrow_up";
    var loadimg = "$imagesdir/$brd_loadbar";
    var cachedBoards = new Object();
    var cachedSubBoards = new Object();
    var curboard = "";
    var insertindex;
    var insertcat;
    var prev_subcount;
    var markallreadlang = '$boardindex_txt{'500'}';
    var markfinishedlang = '$boardindex_txt{'500a'}';
    var markthreadslang = '$boardindex_txt{'500b'}';
    var brd_img_idw = $brd_img_idw;
    var brd_img_idh = $brd_img_idh;
    var fix_brd_size = $fix_brd_img_size;
</script>~;

    # don't show info center, login, etc. if we're calling from sub boards
    if ( !$subboard_sel ) {
        $guestson =
          qq~<span class="small">$boardindex_txt{'141'}: <b>$guests</b></span>~;
        $userson =
qq~<span class="small">$boardindex_txt{'142'}: <b>$numusers</b></span>~;
        $botson =
qq~<span class="small">$boardindex_txt{'143'}: <b>$numbots</b></span>~;

        $totalusers = $numusers + $guests;

        if ( !-e ("$vardir/mostlog.txt") ) {
            fopen( MOSTUSERS, ">$vardir/mostlog.txt" );
            print {MOSTUSERS} "$numusers|$date\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$guests|$date\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$totalusers|$date\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$numbots|$date\n"
              or croak "$croak{'print'} MOSTUSERS";
            fclose(MOSTUSERS);
        }
        fopen( MOSTUSERS, "$vardir/mostlog.txt" );
        @mostentries = <MOSTUSERS>;
        fclose(MOSTUSERS);
        ( $mostmemb,  $datememb )  = split /\|/xsm, $mostentries[0];
        ( $mostguest, $dateguest ) = split /\|/xsm, $mostentries[1];
        ( $mostusers, $dateusers ) = split /\|/xsm, $mostentries[2];
        ( $mostbots,  $datebots )  = split /\|/xsm, $mostentries[3];
        $mostmemb  = ( $mostmemb  || 0 );
        $datememb  = ( $datememb  || 0 );
        $mostguest = ( $mostguest || 0 );
        $dateguest = ( $dateguest || 0 );
        $mostusers = ( $mostusers || 0 );
        $dateusers = ( $dateusers || 0 );
        $mostbots  = ( $mostbots  || 0 );
        $datebots  = ( $datebots  || 0 );

        chomp $datememb;
        chomp $dateguest;
        chomp $dateusers;
        chomp $datebots;

        if (   $numusers > $mostmemb
            || $guests > $mostguest
            || $numbots > $mostbots
            || $totalusers > $mostusers )
        {
            fopen( MOSTUSERS, ">$vardir/mostlog.txt" );
            if ( $numusers > $mostmemb ) {
                $mostmemb = $numusers;
                $datememb = $date;
            }
            if ( $guests > $mostguest ) {
                $mostguest = $guests;
                $dateguest = $date;
            }
            if ( $totalusers > $mostusers ) {
                $mostusers = $totalusers;
                $dateusers = $date;
            }
            if ( $numbots > $mostbots ) {
                $mostbots = $numbots;
                $datebots = $date;
            }
            print {MOSTUSERS} "$mostmemb|$datememb\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$mostguest|$dateguest\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$mostusers|$dateusers\n"
              or croak "$croak{'print'} MOSTUSERS";
            print {MOSTUSERS} "$mostbots|$datebots\n"
              or croak "$croak{'print'} MOSTUSERS";
            fclose(MOSTUSERS);
        }
        $themostmembdate  = timeformat($datememb,0,0,0,1);
        $themostguestdate = timeformat($dateguest,0,0,0,1);
        $themostuserdate  = timeformat($dateusers,0,0,0,1);
        $themostbotsdate  = timeformat($datebots,0,0,0,1);
        $mostmemb         = NumberFormat($mostmemb);
        $mostguest        = NumberFormat($mostguest);
        $mostusers        = NumberFormat($mostusers);
        $mostbots         = NumberFormat($mostbots);

        my $shared_login;
        if ($iamguest) {
            require Sources::LogInOut;
            $sharedLogin_title = q{};
            $shared_login      = sharedLogin();
        }

        my %tmpcolors;
        $tmpcnt    = 0;
        $grpcolors = q{};

        foreach my $stafgrp ( sort keys %Group ) {
            ( $title, undef, undef, $color, $noshow, undef ) =
              split /\|/xsm, $Group{$stafgrp}, 6;
            if ( $color && $noshow != 1 ) {
                $tmpcnt++;
                $tmpcolors{$tmpcnt} =
qq~<div class="grpcolors"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
            }
        }
        foreach (@nopostorder) {
            ( $title, undef, undef, $color, $noshow, undef ) =
              split /\|/xsm, $NoPost{$_}, 6;
            if ( $color && $noshow != 1 ) {
                $tmpcnt++;
                $tmpcolors{$tmpcnt} =
qq~<div class="grpcolors"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
            }
        }
        foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
            ( $title, undef, undef, $color, $noshow, undef ) =
              split /\|/xsm, $Post{$postamount}, 6;
            if ( $color && $noshow != 1 ) {
                $tmpcnt++;
                $tmpcolors{$tmpcnt} =
qq~<div class="grpcolors"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
            }
        }
        $rows = int( ( $tmpcnt / 2 ) + 0.5 );
        $col1 = 1;
        for ( 1 .. $rows ) {
            $col2 = $rows + $col1;
            if ( $tmpcolors{$col1} ) { $grpcolors .= qq~$tmpcolors{$col1}~; }
            if ( $tmpcolors{$col2} ) { $grpcolors .= qq~$tmpcolors{$col2}~; }
            $col1++;
        }
        undef %tmpcolors;

        # Template it
        my ( $rss_link, $rss_text );
        if ( !$rss_disabled ) {
            $rss_link =
qq~<a href="$scripturl?action=RSSrecent" target="_blank"><img src="$micon_bg{'rss'}" alt="$maintxt{'rssfeed'}" title="$maintxt{'rssfeed'}" /></a>~;
            if ( $INFO{'catselect'} ) {
                $rss_link =
qq~<a href="$scripturl?action=RSSrecent;catselect=$INFO{'catselect'}" target="_blank"><img src="$micon_bg{'rss'}" alt="$maintxt{'rssfeed'}" title="$maintxt{'rssfeed'}" /></a>~;
            }
            $rss_text =
qq~<a href="$scripturl?action=RSSrecent" target="_blank">$boardindex_txt{'792'}</a>~;
            if ( $INFO{'catselect'} ) {
                $rss_text =
qq~<a href="$scripturl?action=RSSrecent;catselect=$INFO{'catselect'}" target="_blank">$boardindex_txt{'792'}</a>~;
            }
        }
        $yyrssfeed = $rss_text;
        $yyrss     = $rss_link;
        $boardindex_template =~ s/{yabb rssfeed}/$rss_text/gsm;
        $boardindex_template =~ s/{yabb rss}/$rss_link/gsm;

        $boardindex_template =~ s/{yabb navigation}/&nbsp;/gsm;
        $boardindex_template =~ s/{yabb pollshowcase}/$polltemp/gsm;
        $boardindex_template =~ s/{yabb selecthtml}//gsm;

        $boardhandellist =~ s/{yabb collapse}/$collapselink/gsm;
        $boardhandellist =~ s/{yabb expand}/$expandlink/gsm;
        $boardhandellist =~ s/{yabb markallread}/$markalllink/gsm;

        $boardindex_template =~ s/{yabb boardhandellist}/$boardhandellist/gsm;
        $boardindex_template =~ s/{yabb totaltopics}/$totalt/gsm;
        $boardindex_template =~ s/{yabb totalmessages}/$totalm/gsm;

### recent/recentopics?##
        if ($Show_RecentBar) {
            ( $lssub, undef ) = Split_Splice_Move( $lssub, 0 );
            ToChars($lssub);
            $lssub        = Censor($lssub);
            $tmlsdatetime = qq~($lsdatetime).<br />~;
            $lastpostlink =
qq~$boardindex_txt{'236'} <b><a href="$scripturl?num=$lspostid/$lsreply#$lsreply"><b>$lssub</b></a></b>~;
            if ( $Show_RecentBar == 1 || $Show_RecentBar == 3 ) {
                $recentl   = 'recent';
                $recenttxt = "$boardindex_txt{'792'}";
                if ( $maxrecentdisplay > 0 ) {
                    $recentpostslink =
qq~$boardindex_txt{'791'} <form method="post" action="$scripturl?action=$recentl" name="$recentl" style="display: inline"><select size="1" name="display" onchange="submit()"><option value="">&nbsp;</option>~;
                    my ( $x, $y ) = ( int( $maxrecentdisplay / 5 ), 0 );
                    if ($x) {
                        foreach my $i ( 1 .. 5 ) {
                            $y = $i * $x;
                            $recentpostslink .=
                              qq~<option value="$y">$y</option>~;
                        }
                    }
                    if ( $maxrecentdisplay > $y ) {
                        $recentpostslink .=
qq~<option value="$maxrecentdisplay">$maxrecentdisplay</option>~;
                    }
                    $recentpostslink .=
qq~</select> <input type="submit" style="display:none" /></form> $recenttxt $boardindex_txt{'793'}~;
                }
            }
            if ( $Show_RecentBar == 2 || $Show_RecentBar == 3 ) {
                $recentl_t   = 'recenttopics';
                $recenttxt_t = "$boardindex_txt{'792a'}";
                if ( $maxrecentdisplay_t > 0 ) {
                    $recenttopicslink =
qq~$boardindex_txt{'791'} <form method="post" action="$scripturl?action=$recentl_t" name="$recentl_t" style="display: inline"><select size="1" name="display" onchange="submit()"><option value="">&nbsp;</option>~;
                    my ( $x, $y ) = ( int( $maxrecentdisplay_t / 5 ), 0 );
                    if ($x) {
                        foreach my $i ( 1 .. 5 ) {
                            $y = $i * $x;
                            $recenttopicslink .=
                              qq~<option value="$y">$y</option>~;
                        }
                    }
                    if ( $maxrecentdisplay > $y ) {
qq~<option value="$maxrecentdisplay_t">$maxrecentdisplay_t</option>~;
                    }
                    $recenttopicslink .=
qq~</select> <input type="submit" style="display:none" /></form> $recenttxt_t $boardindex_txt{'793'}~;
                }
            }
            if ( $Show_RecentBar == 3 && $maxrecentdisplay_t > 0 ) {
                $spc = q~<br />~;
            }
            $boardindex_template =~ s/{yabb lastpostlink}/$lastpostlink/gsm;
            $boardindex_template =~ s/{yabb recentposts}/$recentpostslink/gsm;
            $boardindex_template =~ s/{yabb spc}/$spc/sm;
            $boardindex_template =~ s/{yabb recenttopics}/$recenttopicslink/gsm;
            $boardindex_template =~ s/{yabb lastpostdate}/$tmlsdatetime/gsm;
        }
        else {
            $boardindex_template =~ s/{yabb lastpostlink}//gsm;
            $boardindex_template =~ s/{yabb recentposts}//gsm;
            $boardindex_template =~ s/{yabb recenttopics}//gsm;
            $boardindex_template =~ s/{yabb lastpostdate}//gsm;
        }
        $memcount = NumberFormat($memcount);
        $membercountlink =
          qq~<a href="$scripturl?action=ml"><b>$memcount</b></a>~;
        if ( $iamguest && $ML_Allowed ) {
            $membercountlink = qq~<b>$memcount</b>~;
        }
        $boardindex_template =~ s/{yabb membercount}/$membercountlink/gsm;
        if ($showlatestmember) {
            LoadUser($latestmember);
            $latestmemberlink =
                qq~$boardindex_txt{'201'} ~
              . QuickLinks($latestmember)
              . q~.<br />~;
            $boardindex_template =~ s/{yabb latestmember}/$latestmemberlink/gsm;
        }
        else {
            $boardindex_template =~ s/{yabb latestmember}//gsm;
        }
        $boardindex_template =~ s/{yabb ims}/$ims/gsm;
        $boardindex_template =~ s/{yabb guests}/$guestson/gsm;
        $boardindex_template =~ s/{yabb users}/$userson/gsm;
        $boardindex_template =~ s/{yabb bots}/$botson/gsm;
        $boardindex_template =~ s/{yabb onlineusers}/$users/gsm;
        $boardindex_template =~ s/{yabb onlineguests}/$guestlist/gsm;
        $boardindex_template =~ s/{yabb onlinebots}/$botlist/gsm;
        $boardindex_template =~ s/{yabb mostmembers}/$mostmemb/gsm;
        $boardindex_template =~ s/{yabb mostguests}/$mostguest/gsm;
        $boardindex_template =~ s/{yabb mostbots}/$mostbots/gsm;
        $boardindex_template =~ s/{yabb mostusers}/$mostusers/gsm;
        $boardindex_template =~ s/{yabb mostmembersdate}/$themostmembdate/gsm;
        $boardindex_template =~ s/{yabb mostguestsdate}/$themostguestdate/gsm;
        $boardindex_template =~ s/{yabb mostbotsdate}/$themostbotsdate/gsm;
        $boardindex_template =~ s/{yabb mostusersdate}/$themostuserdate/gsm;
        $boardindex_template =~ s/{yabb groupcolors}/$grpcolors/gsm;
        $boardindex_template =~ s/{yabb sharedlogin}/$shared_login/gsm;
        $boardindex_template =~ s/{yabb new_load}/$newload/gsm;

        # EventCal START
        my $cal_display;
        if ( $Show_EventCal == 2 || ( !$iamguest && $Show_EventCal == 1 ) ) {
            require Sources::EventCal;
            $cal_display = eventcal();
        }
        $boardindex_template =~ s/{yabb caldisplay}/$cal_display/gsm;

        # EventCal END

        chop $template_catnames;
        chop $template_boardnames;
        $yymain .= qq~$boardindex_template~;

        $yymain .= qq~
<script type="text/javascript">
    function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
    function ListPages2(bid,cid) { window.open('$scripturl?action=pages;board='+bid+';count='+cid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
            </script>
        ~;

        if ( ${$username}{'PMimnewcount'} > 0 ) {
            if ( ${$username}{'PMimnewcount'} > 1 ) {
                $en  = 's';
                $en2 = $boardindex_imtxt{'47'};
            }
            else { $en = q{}; $en2 = $boardindex_imtxt{'48'}; }

            if ( ${ $uid . $username }{'im_popup'} ) {
                if ( ${ $uid . $username }{'im_imspop'} ) {
                    $yymain .= qq~
<script type="text/javascript">
    if (confirm("$boardindex_imtxt{'14'} ${$username}{'PMimnewcount'}$boardindex_imtxt{'15'}?")) window.open("$scripturl?action=im","_blank");
</script>~;
                }
                else {
                    $yymain .= qq~
<script type="text/javascript">
    if (confirm("$boardindex_imtxt{'14'} ${$username}{'PMimnewcount'}$boardindex_imtxt{'15'}?")) location.href = ("$scripturl?action=im");
</script>~;
                }
            }
        }

        LoadBroadcastMessages($username);

        # look for new BM
        if ($BCnewMessage) {
            if ( ${ $uid . $username }{'im_imspop'} ) {
                $yymain .= qq~
<script type="text/javascript">
    if (confirm("$boardindex_imtxt{'50'}$boardindex_imtxt{'51'}?")) window.open("$scripturl?action=im;focus=bmess","_blank");
</script>~;
            }
            else {
                $yymain .= qq~
<script type="text/javascript">
    if (confirm("$boardindex_imtxt{'50'}$boardindex_imtxt{'51'}?")) location.href = ("$scripturl?action=im;focus=bmess");
</script>~;
            }
        }

        # Make browsers aware of our RSS
        if ( !$rss_disabled ) {
            if ( $INFO{'catselect'} ) {    # Handle categories properly
                $yyinlinestyle .=
qq~    <link rel="alternate" type="application/rss+xml" title="$boardindex_txt{'792'}" href="$scripturl?action=RSSrecent;catselect=$INFO{'catselect'}" />~;
            }
            else {
                $yyinlinestyle .=
qq~    <link rel="alternate" type="application/rss+xml" title="$boardindex_txt{'792'}" href="$scripturl?action=RSSrecent" />~;
            }
        }
        template();
    }

    # end info center, login, etc.

    if ( !$INFO{'a'} ) {
        if ( $INFO{'boardselect'} ) {
            $yymain .= $boardindex_template;

            my $boardtree = q{};
            $mycat = ${ $uid . $subboard_sel }{'cat'};
            ( $mynamecat, undef ) = split /\|/xsm, $catinfo{$mycat};
            ToChars($mynamecat);
            my $catlinkb =
              qq~<a href="$scripturl?catselect=$mycat">$mynamecat</a>~;
            my $parentboard = $subboard_sel;

            while ($parentboard) {
                my ( $pboardname, undef, undef ) =
                  split /\|/xsm, $board{$parentboard};
                ToChars($pboardname);
                $yytitle = $pboardname;
                if ( ${ $uid . $parentboard }{'canpost'}
                    || !$subboard{$parentboard} )
                {
                    $pboardname =
qq~<a href="$scripturl?board=$parentboard" class="a"><b>$pboardname</b></a>~;
                }
                else {
                    $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard;subboards=1" class="a"><b>$pboardname</b></a>~;
                }
                $boardtree =
                  qq~ &rsaquo; $catlinkb &rsaquo; $pboardname$boardtree~;
                $parentboard = ${ $uid . $parentboard }{'parent'};
            }

            $yynavigation .= qq~$boardtree~;
            template();
        }
        elsif ($subboard_sel) {
            if ($brd_count) {
                $boardindex_template = qq~
                        <script type="text/javascript">
                        var catNames = [$template_catnames];
                        var boardNames = [$template_boardnames];
                        var boardOpen = "";
                        var subboardOpen = "";
                        var arrowup = '<img src="$imagesdir/$brd_arrowup" class="brd_arrow" alt="$boardindex_txt{'643'}" />';
                        var openbutton = "$imagesdir/$brd_dropdown";
                        var closebutton = "$imagesdir/$brd_dropup";
                        var loadimg = "$imagesdir/$brd_loadbar";
                        var cachedBoards = new Object();
                        var cachedSubBoards = new Object();
                        var curboard = "";
                        var insertindex;
                        var insertcat;
                        var prev_subcount;
                        </script>
                        $boardindex_template
~;
            }
        }
    }
    else {
        print "Content-type: text/html; charset=$yymycharset\n\n"
          or croak "$croak{'print'} charset";
        print qq~
            <table id="subloaded_$INFO{'board'}" style="display:none">
            $boardindex_template
            </table>
        ~ or croak "$croak{'print'} table";
        CORE::exit;    # This is here only to avoid server error log entries!
    }

    # cannot have return here - breaks subboard display;
}

sub GetBotlist {
    if ( -e "$vardir/bots.hosts" ) {
        fopen( BOTS, "$vardir/bots.hosts" )
          or fatal_error( 'cannot_open', "$vardir/bots.hosts", 1 );
        my @botlist = <BOTS>;
        fclose(BOTS);
        chomp @botlist;
        foreach (@botlist) {
            if ( $_ =~ /(.*?)\|(.*)/xsm ) {
                push @all_bots, $1;
                $bot_name{$1} = $2;
            }
        }
    }
    return;
}

sub Is_Bot {
    my ($bothost) = @_;
    foreach (@all_bots) { return $bot_name{$_} if $bothost =~ /$_/ism; }
    return;
}

sub Collapse_Write {
    my @userhide;

    # rewrite the category hash for the user
    foreach my $key (@categoryorder) {
        my ( $catname, $catperms, $catallowcol ) =
          split /\|/xsm, $catinfo{$key};
        $access = CatAccess($catperms);
        if ( $catcol{$key} == 0 && $access ) { push @userhide, $key; }
    }
    ${ $uid . $username }{'cathide'} = join q{,}, @userhide;
    UserAccount( $username, 'update' );
    if ( -e "$memberdir/$username.cat" ) {
        unlink "$memberdir/$username.cat";
    }
    return;
}

sub Collapse_Cat {
    if ($iamguest) { fatal_error('collapse_no_member'); }
    my $changecat = $INFO{'cat'};
    if ( !$colloaded ) { Collapse_Load(); }

    if ( $catcol{$changecat} == 1 ) {
        $catcol{$changecat} = 0;
    }
    else {
        $catcol{$changecat} = 1;
    }
    Collapse_Write();
    if ( $INFO{'oldcollapse'} ) {
        $yySetLocation = $scripturl;
        redirectexit();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub Collapse_All {
    my $state = $INFO{'status'};

    if ($iamguest) { fatal_error('collapse_no_member'); }
    if ( $state != 1 && $state != 0 ) {
        fatal_error('collapse_invalid_state');
    }

    foreach my $key (@categoryorder) {
        my ( $catname, $catperms, $catallowcol ) =
          split /\|/xsm, $catinfo{$key};
        if ( $catallowcol eq '1' ) {
            $catcol{$key} = $state;
        }
        else {
            $catcol{$key} = 1;
        }
    }
    Collapse_Write();
    if ( $INFO{'oldcollapse'} ) {
        $yySetLocation = $scripturl;
        redirectexit();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub MarkAllRead {    # Mark all boards as read.
    get_forum_master();

    my @cats = ();
    if ( $INFO{'cat'} ) {
        @cats = ( $INFO{'cat'} );
        $INFO{'catselect'} = $INFO{'cat'};
    }
    else { @cats = @categoryorder; }

    # Load the whole log
    getlog();

    *recursive_mark = sub {
        my @x = @_;
        foreach my $board (@x) {

            # Security check
            if (
                AccessCheck(
                    $board, q{}, ( split /\|/xsm, $board{$board} )[1]
                ) ne 'granted'
              )
            {
                delete $yyuserlog{"$board--mark"};
                delete $yyuserlog{$board};
            }
            else {

                # Mark it
                $yyuserlog{"$board--mark"} = $date;
                $yyuserlog{$board} = $date;
            }

            # make recursive call if this board has more children
            if ( $subboard{$board} ) {
                recursive_mark( split /\|/xsm, $subboard{$board} );
            }
        }
    };

    foreach my $catid (@cats) {

        # Security check
        if ( !CatAccess( ( split /\|/xsm, $catinfo{$catid} )[1] ) ) {
            foreach my $board ( split /\,/xsm, $cat{$catid} ) {
                delete $yyuserlog{"$board--mark"};
                delete $yyuserlog{$board};
            }
            next;
        }

        recursive_mark( split /\,/xsm, $cat{$catid} );
    }

    # Write it out
    dumplog();

    if ( $INFO{'oldmarkread'} ) {
        redirectinternal();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub gostRemove {
    my ( $thecat, $gostboard ) = @_;
    get_forum_master();
    (@gbdlist) = split /\,/xsm, $cat{$thecat};
    $tmp_master = q{};
    foreach my $item (@gbdlist) {
        if ( $item ne $gostboard ) {
            $tmp_master .= qq~$item,~;
        }
    }
    $tmp_master =~ s/,\Z//xsm;
    $cat{$thecat} = $tmp_master;
    Write_ForumMaster();
    return;
}

sub Del_Max_IM {
    my ( $ext, $max ) = @_;
    fopen( DELMAXIM, "<$memberdir/$username.$ext" );
    my @IMmessages = <DELMAXIM>;
    fclose(DELMAXIM);
    splice @IMmessages, $max;

    fopen( DELMAXIM, ">$memberdir/$username.$ext" );
    print {DELMAXIM} @IMmessages or croak "$croak{'print'} DELMAXIM";
    fclose(DELMAXIM);
    return;
}

sub RedirectExternalShow {
    my $exboard = $INFO{'exboard'} || $curboard;
    fopen( COUNT, "$boardsdir/$exboard.exhits" );
    $excount = <COUNT>;
    chomp $excount;
    fclose(COUNT);

    if ( $INFO{'action'} eq 'showexternal' ) {
        my $link = ( split /\|/xsm, $board{$exboard} )[0];
        if   ($excount) { $excount++; }
        else            { $excount = 1; }
        fopen( COUNT, ">$boardsdir/$exboard.exhits" );
        seek COUNT, 0, 0;
        print {COUNT} "$excount" or croak "$croak{'print'} COUNT";
        fclose(COUNT);
        print "Content-type: text/html\n" or croak "$croak{'print'} top";
        print "Location: $link\n\n"       or croak "$croak{'print'} link";
        exit;
    }
    else {
        return $excount;
    }
}

1;
