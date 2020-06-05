###############################################################################
# Notify.pm                                                                   #
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
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$notifypmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Notify');

sub ManageBoardNotify {
    my ( $todo, $theboard, $user, $userlang, $notetype, $noteview ) = @_;
    if (   $todo eq 'load'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        undef %theboard;
        ## open board mail file and build hash name / detail
        if ( -e "$boardsdir/$theboard.mail" ) {
            fopen( BOARDNOTE, "$boardsdir/$theboard.mail" );
            %theboard = map { /(.*)\t(.*)/xsm } <BOARDNOTE>;
            fclose(BOARDNOTE);
        }
    }
    if ( $todo eq 'add' ) {
        if ( !$maxtnote ) { $maxtnote = 10; }
        $theboard{$user} = "$userlang|$notetype|$noteview";
        LoadUser($user);
        my %bb;
        my @oldnote = split /,/xsm,
          ${ $uid . $username }{'board_notifications'};
        if ( @oldnote < ( $maxtnote || 10 ) ) {
            foreach ( split /,/xsm, ${ $uid . $user }{'board_notifications'} ) {
                $bb{$_} = 1;
           }
            $bb{$theboard} = 1;
            ${ $uid . $user }{'board_notifications'} = join q{,}, keys %bb;
            UserAccount($user);
        }
    }
    elsif ( $todo eq 'update' ) {
        if ( exists $theboard{$user} ) {
            my ( $memlang, $memtype, $memview ) =
              split /\|/xsm, $theboard{$user};
            if ($userlang) { $memlang = $userlang; }
            if ($notetype) { $memtype = $notetype; }
            if ($noteview) { $memview = $noteview; }
            $theboard{$user} = "$memlang|$memtype|$memview";
        }
    }
    elsif ( $todo eq 'delete' ) {
        my %bb;
        foreach my $u ( split /,/xsm, $user ) {
            delete $theboard{$u};
            LoadUser($u);
            foreach ( split /,/xsm, ${ $uid . $u }{'board_notifications'} ) {
                $bb{$_} = 1;
            }
            if ( delete $bb{$theboard} ) {
                ${ $uid . $u }{'board_notifications'} = join q{,}, keys %bb;
                UserAccount($u);
            }
            undef %bb;
        }
    }
    if (   $todo eq 'save'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        if (%theboard) {
            fopen( BOARDNOTE, ">$boardsdir/$theboard.mail" );
            print {BOARDNOTE} map { "$_\t$theboard{$_}\n" }
              sort { $theboard{$a} cmp $theboard{$b} } keys %theboard
              or croak "$croak{'print'} BOARDNOTE";
            fclose(BOARDNOTE);
            undef %theboard;
        }
        else {
            unlink "$boardsdir/$theboard.mail";
        }
    }
    return;
}

sub BoardNotify {
    if ( !$currentboard ) { fatal_error('no_access'); }
    if ($iamguest)        { fatal_error('members_only'); }
    $selected1 = q{};
    $selected2 = q{};
    $deloption = q{};
    my ( $boardname, undef ) = split /\|/xsm, $board{$currentboard}, 2;
    ToChars($boardname);
    ManageBoardNotify( 'load', $currentboard );

##  popup from MessageIndex

    LoadLanguage('Notify');
    get_template('MessageIndex');

    if ( exists $theboard{$username} ) {
        ( $memlang, $memtype, $memview ) = split /\|/xsm, $theboard{$username};
        ${ 'selected' . $memtype } = q~ selected="selected"~;
        $deloption = qq~<option value="3">$notify_txt{'134'}</option>~;
        $my_delopt = qq~$notify_txt{'137'} &nbsp;~;
    }
    else {
        $my_delopt = qq~$notify_txt{'126'} &nbsp;~;
    }

    $yymain .= $brd_notify;
    $yymain =~ s/{yabb boardname}/$boardname/gsm;
    $yymain =~ s/{yabb currentboard}/$currentboard/gsm;
    $yymain =~ s/{yabb currentboard}/$currentboard/gsm;
    $yymain =~ s/{yabb selected1}/$selected1/gsm;
    $yymain =~ s/{yabb selected2}/$selected2/gsm;
    $yymain =~ s/{yabb deloption}/$deloption/gsm;
    $yymain =~ s/{yabb my_delopt}/$my_delopt/gsm;

    undef %theboard;
    $yytitle = "$notify_txt{'125'}";
    template();
    return;
}

sub BoardNotify2 {
    if ($iamguest) { fatal_error('members_only'); }
    foreach my $variable ( keys %FORM ) {
        if ( $variable eq 'formsession' ) { next; }
        $notify_type = $FORM{$variable};
        if ( $notify_type == 1 || $notify_type == 2 ) {
            ManageBoardNotify( 'add', $variable, $username,
                ${ $uid . $username }{'language'},
                $notify_type, '1' );
        }
        elsif ( $notify_type == 3 ) {
            ManageBoardNotify( 'delete', $variable, $username );
        }
    }
    if ( $action eq 'boardnotify3' ) {
        $yySetLocation = qq~$scripturl?board=$INFO{'board'}~;
    }
    else {
        $yySetLocation = qq~$scripturl?action=shownotify~;
    }
    redirectexit();
    return;
}

sub ManageThreadNotify {
    my ( $todo, $thethread, $user, $userlang, $notetype, $noteview ) = @_;
    if (   $todo eq 'load'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        undef %thethread;
        ##  open mail file and build hash
        if ( -e "$datadir/$thethread.mail" ) {
            fopen( THREADNOTE, "$datadir/$thethread.mail" );
            %thethread = map /(.*)\t(.*)/, <THREADNOTE>;
            fclose(THREADNOTE);
        }
    }
    if ( $todo eq 'add' ) {
        $thethread{$user} = "$userlang|$notetype|$noteview";
        LoadUser($user);
        my %t;
        foreach ( split /,/xsm, ${ $uid . $user }{'thread_notifications'} ) {
            $t{$_} = 1;
        }
        $t{$thethread} = 1;
        ${ $uid . $user }{'thread_notifications'} = join q{,}, keys %t;
        UserAccount($user);
    }
    elsif ( $todo eq 'update' ) {
        if ( exists $thethread{$user} ) {
            ( $memlang, $memtype, $memview ) = split /\|/xsm, $thethread{$user};
            if ($userlang) { $memlang = $userlang; }
            if ($notetype) { $memtype = $notetype; }
            if ($noteview) { $memview = $noteview; }
            $thethread{$user} = "$memlang|$memtype|$memview";
        }
    }
    elsif ( $todo eq 'delete' ) {
        my %t;
        foreach my $u ( split /,/xsm, $user ) {
            delete $thethread{$u};
            LoadUser($u);
            foreach ( split /,/xsm, ${ $uid . $u }{'thread_notifications'} ) {
                $t{$_} = 1;
            }
            if ( delete $t{$thethread} ) {
                ${ $uid . $u }{'thread_notifications'} = join q{,}, keys %t;
                UserAccount($u);
            }
            undef %t;
        }
    }
    if (   $todo eq 'save'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        if (%thethread) {
            fopen( THREADNOTE, ">$datadir/$thethread.mail" );
            print {THREADNOTE} map { "$_\t$thethread{$_}\n" }
              sort { $thethread{$a} cmp $thethread{$b} } keys %thethread
              or croak "$croak{'print'} THREADNOTE";
            fclose(THREADNOTE);
            undef %thethread;
        }
        else {
            unlink "$datadir/$thethread.mail";
        }
    }
    return;
}

# sub Notify { deleted because not needed since YaBB 2.3 (deti)

sub Notify2 {
    if ($iamguest) { fatal_error('members_only'); }

    ManageThreadNotify( 'add', $INFO{'num'}, $username,
        ${ $uid . $username }{'language'},
        1, 1 );

    if ( $INFO{'oldnotify'} ) {
        redirectinternal();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub Notify3 {
    if ($iamguest) { fatal_error('members_only'); }

    ManageThreadNotify( 'delete', $INFO{'num'}, $username );

    if ( $INFO{'oldnotify'} ) {
        redirectinternal();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub Notify4 {
    if ($iamguest) { fatal_error('members_only'); }
    foreach my $variable ( keys %FORM ) {
        my ( $notype, $threadno ) = split /-/xsm, $variable;
        if ( $notype eq 'thread' ) {
            ManageThreadNotify( 'delete', $threadno, $username );
        }
    }
    $action = 'shownotify';
    ShowNotifications();
    return;
}

sub updateLanguage {
    my ( $user, $newlang ) = @_;
    getMailFiles();
    foreach (@bmaildir) {
        ManageBoardNotify( 'update', $_, $user, $newlang, q{}, q{} );
    }
    foreach (@tmaildir) {
        ManageThreadNotify( 'update', $_, $user, $newlang, q{}, q{} );
    }
    return;
}

sub removeNotifications {
    my $user_s = shift;
    getMailFiles();
    foreach (@bmaildir) {
        ManageBoardNotify( 'delete', $_, $user_s );
    }
    foreach (@tmaildir) {
        ManageThreadNotify( 'delete', $_, $user_s );
    }
    return;
}

sub getMailFiles {
    opendir BOARDNOT, "$boardsdir";
    @bmaildir =
      map { ( split /\./xsm, $_ )[0] } grep { /\.mail$/xsm } readdir BOARDNOT;
    closedir BOARDNOT;
    opendir THREADNOT, "$datadir";
    @tmaildir =
      map { ( split /\./xsm, $_ )[0] } grep { /\.mail$/xsm } readdir THREADNOT;
    closedir THREADNOT;
    return;
}

sub ShowNotifications {
    ## bye bye guest....
    if ($iamguest) { fatal_error('members_only'); }

    $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $img_txt{'418'}~;

    LoadLanguage('Notify');
    get_template('MyPosts');

    my @oldnote = split /,/xsm, ${ $uid . $username }{'board_notifications'};
    $curbrd = @oldnote;
 #   if ( !$maxtnote ) { $maxtnote = 10; }

 #   $note_brd = qq~<br />$notify_txt{'75'}<br />$notify_txt{'76'} $curbrd $notify_txt{'77'} $maxtnote $notify_txt{'78'}~;
    $curbrd = NumberFormat($curbrd);

    # Show Javascript for 'check all' notifications

    ( $board_notify, $thread_notify ) = NotificationAlert();
    my ( $num, $new );

    # Board notifications
    foreach ( keys %{$board_notify} ) {    # boardname, boardnotifytype , new
        $num++;

        my ( $selected1, $selected2 );
        if ( ${ $$board_notify{$_} }[1] == 1 ) {    # new topics
            $selected1 = q~ selected="selected"~;
        }
        else {                                      # all new posts
            $selected2 = q~ selected="selected"~;
        }

        if ( ${ $$board_notify{$_} }[2] ) {
            $new =
qq~<img src="$imagesdir/$brdimg_new" alt="$notify_txt{'333'}" title="$notify_txt{'333'}" />~;
        }
        else {
            $new =
qq~<img src="$imagesdir/$brdimg_old" alt="$notify_txt{'334'}" title="$notify_txt{'334'}" />~;
        }

        ## output notify detail - option 3 = remove notify
        $boardblock .= $my_boardblock;
        $boardblock =~ s/{yabb brd}/$_/gsm;
        $boardblock =~ s/{yabb new}/$new/gsm;
        $boardblock =~ s/{yabb brdnote0}/${$$board_notify{$_}}[0]/gsm;
        $boardblock =~ s/{yabb selected1}/$selected1/gsm;
        $boardblock =~ s/{yabb selected2}/$selected2/gsm;
    }

    if ( !$num ) {    # no board notifies up
        $my_showNotifications_b = $my_nonotes;
    }
    else {            # list boards
        $my_showNotifications_b = $my_notebrdlist;
        $my_showNotifications_b =~ s/{yabb boardblock}/$boardblock/gsm;
    }

    $num = 0;
    foreach ( keys %{$thread_notify} )
    { # mythread, msub, new, username_link, catname_link, boardname_link, lastpostdate
        $num++;

        ## build block for display
        $threadblock .= $my_threadblock;
        $threadblock =~ s/{yabb tnote0}/${$$thread_notify{$_}}[0]/gsm;
        $threadblock =~ s/{yabb tnote1}/${$$thread_notify{$_}}[1]/gsm;
        $threadblock =~ s/{yabb tnote2}/${$$thread_notify{$_}}[2]/gsm;
        $threadblock =~ s/{yabb tnote3}/${$$thread_notify{$_}}[3]/gsm;
        $threadblock =~ s/{yabb tnote4}/${$$thread_notify{$_}}[4]/gsm;
        $threadblock =~ s/{yabb tnote5}/${$$thread_notify{$_}}[5]/gsm;
        $threadblock =~ s/{yabb tnote6}/${$$thread_notify{$_}}[6]/gsm;
    }

    if ( !$num ) {    ## no threads listed
        $my_showNotifications_t = $my_nothreads;
    }
    else {            ## output details
        $my_showNotifications_t = $my_threadnote_b;
        $my_showNotifications_t =~ s/{yabb threadblock}/$threadblock/gsm;
    }
    $showNotifications = $my_boardnote;

    #    $showNotifications =~ s/{yabb note_brd}/$note_brd/sm;
    $showNotifications =~ s/{yabb note_brd}//sm;
    $showNotifications =~
      s/{yabb my_showNotifications_b}/$my_showNotifications_b/sm;
    $showNotifications =~
      s/{yabb my_showNotifications_t}/$my_showNotifications_t/sm;
    $showNotifications .= $my_threadnote_end;

    $yytitle = "$notify_txt{'124'}";

    ## and finally, add jump menu for a route back.
    if ( !$view ) {
        jumpto();
        $yymain .= qq~$showNotifications$selecthtml~;
        template();
    }
    return;
}

sub NotificationAlert {
    my ( $myboard, %board_notify, $mythread, %thread_notify );

    @bmaildir = split /,/xsm, ${ $uid . $username }{'board_notifications'};
    @tmaildir = split /,/xsm, ${ $uid . $username }{'thread_notifications'};

    # needed for $new - icon (on/off/new)
    my @noloadboard =
      grep { !exists ${ $uid . $_ }{'lastposttime'} } @allboards;
    if (@noloadboard) { BoardTotals( 'load', @noloadboard ); }

    # to get ${$uid.$myboard}{'lastposttime'}
    getlog();    # sub in Subs.pm, for $yyuserlog{$myboard}
    my $dmax = $date - ( $max_log_days_old * 86400 );

    ## run through boards list
    foreach my $myboard (@bmaildir) {    # board name from file name
        if ( !-e "$boardsdir/$myboard.txt" )
        {                             # remove from user board_notifications
            ManageBoardNotify( 'delete', $myboard, $username );
            next;
        }

        ## load in hash of name / detail for board
        ManageBoardNotify( 'load', $myboard );

        if ( exists $theboard{$username} ) {
            ## grab board name
            my $boardname = ( split /\|/xsm, $board{$myboard} )[0];

            $board_notify{$myboard} = [
                $boardname,
                ( split /\|/xsm, $theboard{$username} )[1],    # boardnotifytype
                (
                    (
                             $max_log_days_old
                          && int( ${ $uid . $myboard }{'lastposttime'} )
                          && (
                            (
                                !$yyuserlog{$myboard}
                                && ${ $uid . $myboard }{'lastposttime'} > $dmax
                            )
                            || (   $yyuserlog{$myboard} > $dmax
                                && $yyuserlog{$myboard} <
                                ${ $uid . $myboard }{'lastposttime'} )
                          )
                    ) ? 1 : 0
                ),    # new == 1
            ];

            undef %theboard;
        }
    }

    if ( $action eq 'shownotify' ) { LoadCensorList(); }

    ## load board names
    get_forum_master();    # for $board{...}

    foreach my $mythread (@tmaildir) {    # number of next thread
            # see if thread exists and search for it if moved
        if ( !-e "$datadir/$mythread.txt" ) {
            ManageThreadNotify( 'delete', $mythread, $username );
            if ( eval { require Variables::Movedthreads; 1 } ) {
                next
                  if !exists $moved_file{$mythread} || !$moved_file{$mythread};
            my $newthread;
            while ( exists $moved_file{$mythread} ) {
                $mythread  = $moved_file{$mythread};
                    if ( !exists $moved_file{$mythread}
                        && -e "$datadir/$mythread.txt" )
                    {
                        $newthread = $mythread;
                    }
            }
            next if !$newthread;
                ManageThreadNotify( 'add', $newthread, $username,
                ${ $uid . $username }{'language'},
                1, 1 );
        }
        }

        ## load threads hash
        ManageThreadNotify( 'load', $mythread );

        if ( exists $thethread{$username} ) {
            ## load ctb file for board data
            MessageTotals( 'load', $mythread );

            ## pull out board and last post
            my $boardid = ${$mythread}{'board'};
            my ( $msub, $mname, $musername, $new, $username_link, $catname_link,
                $boardname_link, $lastpostdate );
            if ( $action eq 'shownotify' ) {
                if ( !${ ${ 'notify' . $boardid . $mythread } }[0] ) {
                    my ( $messageid, $messagesubject );
                    fopen( BOARDTXT, "$boardsdir/$boardid.txt" )
                      or fatal_error( 'cannot_open', "$boardsdir/$boardid.txt",
                        1 );
                    while ( my $brd = <BOARDTXT> ) {
                        (
                            $messageid, $messagesubject, $mname, undef, undef,
                            undef, $musername, undef
                        ) = split /\|/xsm, $brd, 8;
                        ${ 'notify' . $boardid . $messageid } =
                          [ $messagesubject, $mname, $musername ];
                    }
                    fclose(BOARDTXT);
                }
                $msub      = ${ ${ 'notify' . $boardid . $mythread } }[0];
                $mname     = ${ ${ 'notify' . $boardid . $mythread } }[1];
                $musername = ${ ${ 'notify' . $boardid . $mythread } }[2];

                ToChars($msub);
                ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
                $msub = Censor($msub);    # censor subject text !

                ## run through the categories until we hit the match for category name
                my ( $catname, $thiscatid, $catid );
                my $boardname = ( split /\|/xsm, $board{$boardid} )[0];

                # grab boardname from list
              CHECKBOARDNAME: foreach my $catid (@categoryorder) {
                    foreach ( split /\,/xsm, $cat{$catid} ) {
                        ## find the match, grab data and jump out
                        if ( $_ eq $boardid ) {
                            $catname = ( split /\|/xsm, $catinfo{$catid} )[0];
                            $thiscatid = $catid;
                            last CHECKBOARDNAME;
                        }
                    }
                }
                $catname_link =
                  qq~<a href="$scripturl?catselect=$thiscatid">$catname</a>~;
                $boardname_link =
                  qq~<a href="$scripturl?board=$boardid">$boardname</a>~;

                ## build view profile link, if real name exists
                LoadUser($musername);    # load poster
                if ( ${ $uid . $musername }{'realname'} ) {
                    $username_link =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">$format_unbold{$musername}</a>~;
                }
                elsif ($mname) {
                    $username_link = $mname;
                }
                else {
                    $username_link = $musername;
                }

                ## format last post for output
                $lastpostdate = timeformat( ${$mythread}{'lastpostdate'} );
            }

            if ($max_log_days_old) {

               # Decide if thread should have the "NEW" indicator next to it.
               # Do this by reading the user's log for last read time on thread,
               # and compare to the last post time on the thread.
                my $dlp  = int $yyuserlog{$mythread};
                my $dlpb = int $yyuserlog{"$boardid--mark"};
                $dlp = $dlp > $dlpb ? $dlp : $dlpb;
                if (   $yyuserlog{"$mythread--unread"}
                    || ( !$dlp && ${$mythread}{'lastpostdate'} > $dmax )
                    || ( $dlp > $dmax && $dlp < ${$mythread}{'lastpostdate'} ) )
                {
                    $new =
qq~<img src="$imagesdir/$brdimg_new" alt="$notify_txt{'335'}" title="$notify_txt{'335'}"/>~;
                }
            }

            $thread_notify{$mythread} = [
                $mythread,      $msub,         $new,
                $username_link, $catname_link, $boardname_link,
                $lastpostdate
            ];
        }
    }

    return ( \%board_notify, \%thread_notify );
}

1;
