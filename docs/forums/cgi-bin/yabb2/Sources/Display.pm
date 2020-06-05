###############################################################################
# Display.pm                                                                  #
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

$displaypmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Display');
LoadLanguage('FA');
get_micon();
get_template('Display');
get_gmod();

sub Display {

    # Check if board was 'shown to all' - and whether they can view the topic
    if ( AccessCheck( $currentboard, q{}, $boardperms ) ne 'granted' ) {
        fatal_error('no_access');
    }

    if ( $enable_guest_view_limit && $guestaccess ) {
        my $iambot = 0;
        my $user_host =
          ( gethostbyaddr pack( 'C4', split /\./xsm, $user_ip ), 2 )[0];
        if ( -e "$vardir/bots.hosts" ) {
            fopen( BOTS, "$vardir/bots.hosts" )
              or fatal_error( 'cannot_open', "$vardir/bots.hosts", 1 );
            my @botlist = <BOTS>;
            fclose(BOTS);
            chomp @botlist;
            foreach (@botlist) {
                if ( $_         =~ /(.*?)\|(.*)/xsm ) { $bot_name = $1; }
                if ( $user_host =~ /$bot_name/ixsm )  { $iambot   = 1; }
            }
        }
        if (   $iamguest
            && !$iambot
            && $yyCookies{$cookieview} < $guest_view_limit )
        {
            if ( $yyCookies{$cookieview} ) {
                $gtvlcount = $yyCookies{$cookieview};
                $gtvlcount =~ s/\D//gsm;
                $gtvlcount++;
            }
            else {
                $gtvlcount = 1;
            }
            my $guest_view_limit_clength = q{+} . $cookieviewtime . 'm';
            $yySetCookies1 = write_cookie(
                -path    => q{/},
                -name    => $cookieview,
                -value   => $gtvlcount,
                -expires => $guest_view_limit_clength
            );
        }
        elsif ($iamguest
            && !$iambot
            && $yyCookies{$cookieview} >= $guest_view_limit )
        {
            if ($guest_view_limit_block) {
                $guest_view_limit_warn = q{};
                $yytitle               = $display_txt{'guest_message'};
                $yynavigation = qq~&rsaquo; $display_txt{'guest_message'}~;
                $yymain .= $my_guest_limit;
                template();
                exit;
            }
            else {
                $guest_view_limit_warn = $guest_view_limit_w;
            }
        }
    }

    # Get the "NEW"est Post for this user.
    my $newestpost;
    if ( !$iamguest && $max_log_days_old && $INFO{'start'} eq 'new' ) {

        # This decides which messages were already read in the thread to
        # determining where the redirect should go. It is done by
        # comparing times in the username.log and the boardnumber.txt files.
        getlog();
        my $mnum = $INFO{'num'};
        my $dlp =
            int( $yyuserlog{$mnum} ) > int( $yyuserlog{"$currentboard--mark"} )
          ? int( $yyuserlog{$mnum} )
          : int $yyuserlog{"$currentboard--mark"};
        $dlp =
            $dlp > $date - ( $max_log_days_old * 86400 )
          ? $dlp
          : $date - ( $max_log_days_old * 86400 );

        if ( !ref $thread_arrayref{$mnum} ) {
            fopen( MNUM, "$datadir/$mnum.txt" );
            @{ $thread_arrayref{$mnum} } = <MNUM>;
            fclose(MNUM);
        }
        my $i = -1;
        foreach ( @{ $thread_arrayref{$mnum} } ) {
            $i++;
            last if ( split /\|/xsm, $_ )[3] > $dlp;
        }

        $newestpost = $INFO{'start'} = $i;
    }

    # Post and Thread Tools
    if ($useThreadtools) {
        LoadTools(
            2,           'addfav',     'remfav',     'addpoll',
            'reply',     'add_notify', 'del_notify', 'print',
            'sendtopic', 'markunread'
        );
    }
    if ($usePosttools) {
        LoadTools( 1, 'delete', 'admin_split', 'mquote', 'quote', 'modify',
            'printp', 'alertmod' );
    }

    if ($buddyListEnabled) { loadMyBuddy(); }
    my $viewnum = $INFO{'num'};

    # strip off any non numeric values to avoid exploitation
    $maxmessagedisplay ||= 10;
    my (
        $msubthread, $mnum,   $mstate,   $mdate,     $msub,
        $mname,      $memail, $mreplies, $musername, $micon,
        $mip,        $mlm,    $mlmb
    );
    my (
        $counter,           $counterwords,     $threadclass,
        $notify,            $max,              $start,
        $mattach,           $template_viewers, $template_favorite,
        $template_pollmain, $navback,          $mark_unread,
        $pollbutton,        $icanbypass,       $replybutton,
        $bypassReplyButton
    );

    LoadCensorList();

    # Determine category
    $curcat = ${ $uid . $currentboard }{'cat'};

    # Figure out the name of the category
    get_forum_master();

    if ( $currentboard eq $annboard ) {
        $vircurrentboard = $INFO{'virboard'};
        $vircurcat       = ${ $uid . $vircurrentboard }{'cat'};
        ( $vircat, undef ) = split /\|/xsm, $catinfo{$vircurcat};
        ToChars($vircat);
        ( $virboardname, undef ) = split /\|/xsm, $board{$vircurrentboard}, 2;
        ToChars($virboardname);
    }

    ( $cat, $catperms ) = split /\|/xsm, $catinfo{"$curcat"};
    ToChars($cat);

    ( $boardname, $boardperms, $boardview ) =
      split /\|/xsm, $board{$currentboard};

    ToChars($boardname);

    # Check to make sure this thread isn't locked.
    (
        $mnum,     $msubthread, $mname, $memail, $mdate,
        $mreplies, $musername,  $micon, $mstate
    ) = split /\|/xsm, $yyThreadLine;

    if ( $mstate =~ /m/sm ) {
        if ( $msubthread =~ / dest=(\d+)\]/sm ) {
            my $newnum = $1;
        }
        if ( -e "$datadir/$newnum.txt" ) {
            $yySetLocation = "$scripturl?num=$newnum";
            redirectexit();
        }
        if ( eval { require Variables::Movedthreads; 1 } ) {
            while ( exists $moved_file{$newnum} ) {
                $newnum = $moved_file{$newnum};
                next if exists $moved_file{$newnum};
                if ( -e "$datadir/$newnum.txt" ) {
                    $yySetLocation = "$scripturl?num=$newnum";
                    redirectexit();
                }
            }
        }
    }

    ( $msubthread, undef ) = Split_Splice_Move( $msubthread, 0 );
    ToChars($msubthread);
    $msubthread = Censor($msubthread);

    # Build a list of this board's moderators.
    if ( keys %moderators > 0 ) {
        if ( keys %moderators == 1 ) { $showmods = qq~($display_txt{'298'}: ~; }
        else                         { $showmods = qq~($display_txt{'63'}: ~; }

        while ( $_ = each %moderators ) {
            FormatUserName($_);
            $showmods .= QuickLinks( $_, 1 ) . q{, };
        }
        $showmods =~ s/, \Z/)/sm;
    }
    if ( keys %moderatorgroups > 0 ) {
        if ( keys %moderatorgroups == 1 ) {
            $showmodgroups = qq~($display_txt{'298a'}: ~;
        }
        else { $showmodgroups = qq~($display_txt{'63a'}: ~; }

        my ( $tmpmodgrp, $thismodgrp );
        while ( $_ = each %moderatorgroups ) {
            $tmpmodgrp = $moderatorgroups{$_};
            ( $thismodgrp, undef ) = split /\|/xsm, $NoPost{$tmpmodgrp}, 2;
            $showmodgroups .= qq~$thismodgrp, ~;
        }
        $showmodgroups =~ s/, \Z/)/sm;
    }

    ## now we have established credentials,
    ## can this user bypass locks?
    ## work out who can bypass locked thread post only if bypass switched on
    if ( $mstate =~ /l/ism ) {
        if ($bypass_lock_perm) { $icanbypass = checkUserLockBypass(); }
        $enable_quickreply = 0;
    }

    my $permdate = permtimer($mnum);
    my $display_permalink =
qq~<a href="http://$perm_domain/$symlink$permdate/$currentboard/$mnum">$display_txt{'10'}</a>~;

    # Look for a poll file for this thread.
    if ( AccessCheck( $currentboard, 3 ) eq 'granted' ) {
        $pollbutton =
qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;title=AddPoll">$img{'addpoll'}</a>~;
    }
    if ( -e "$datadir/$viewnum.poll" ) {
        $has_poll   = 1;
        $pollbutton = q{};
    }
    else {
        $has_poll = 0;
        if ( $useraddpoll == 0 ) { $pollbutton = q{}; }
    }

    # Get the class of this thread, based on lock status and number of replies.
    if ( ( !$iamguest || $enable_guestposting )
        && AccessCheck( $currentboard, 2 ) eq 'granted' )
    {
        $replybutton = q~<a href="~
          . (
            $enable_quickreply && $enable_quickjump
            ? 'javascript:document.postmodify.message.focus();'
            : qq~$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;title=PostReply~
          );
        $bypassReplyButton = $replybutton
          . qq~" onclick="return confirm('$display_txt{'posttolocked'}');">$img{'reply'}</a>~;
        $replybutton .= qq~">$img{'reply'}</a>~;   #" make my text-editor happy;
    }

    $threadclass = 'thread';
    ## hidden threads
    if ( $mstate =~ /h/ism ) {
        $threadclass = 'hide';
        if ( !$staff ) { fatal_error('no_access'); }
    }
    ## locked thread
    elsif ( $mstate =~ /l/ism ) {
        $threadclass = 'locked';                   ## same icon regardless
        $pollbutton  = q{};
        if   ($icanbypass) { $replybutton = $bypassReplyButton; }
        else               { $replybutton = q{}; }
    }
    elsif ( $mreplies >= $VeryHotTopic ) { $threadclass = 'veryhotthread'; }
    elsif ( $mreplies >= $HotTopic )     { $threadclass = 'hotthread'; }
    elsif ( $mstate eq q{} ) { $threadclass = 'thread'; }

    ## stickies
    if ( $mstate =~ /s/ism ) {
        if ( $threadclass eq 'hide' ) {
            if ( $mstate =~ /l/ism ) {
                $threadclass = 'hidestickylock';
                $pollbutton  = q{};
                if   ($icanbypass) { $replybutton = $bypassReplyButton; }
                else               { $replybutton = q{}; }
            }
            else {
                $threadclass = 'hidesticky';
            }
        }
        elsif ( $threadclass eq 'thread' ) { $threadclass = 'sticky'; }
        elsif ( $threadclass eq 'locked' ) {
            $threadclass = 'stickylock';
            if   ($icanbypass) { $replybutton = $bypassReplyButton; }
            else               { $replybutton = q{}; }
        }
    }
    elsif ( $threadclass eq 'hide' && $mstate =~ /l/ism ) {
        $threadclass = 'hidelock';
        $pollbutton  = q{};
        if   ($icanbypass) { $replybutton = $bypassReplyButton; }
        else               { $replybutton = q{}; }
    }
    elsif ( ${$mnum}{'board'} eq $annboard ) {
        $threadclass =
          $threadclass eq 'locked' ? 'announcementlock' : 'announcement';
    }

    if ( -e "$datadir/$mnum.mail" && !$iamguest ) {
        require Sources::Notify;
        ManageThreadNotify( 'update', $mnum, $username, q{}, q{}, '1' );
    }

    if ( $showmodgroups ne q{} && $showmods ne q{} ) { $showmods .= q~ - ~; }

    # Build the page links list.
    if ( !$iamguest ) {
        ( undef, $userthreadpage, undef, undef ) =
          split /\|/xsm, ${ $uid . $username }{'pageindex'};
    }
    my ( $pagetxtindex, $pagedropindex1, $pagedropindex2, $all, $allselected );
    $postdisplaynum = 3;               # max number of pages to display
    $dropdisplaynum = 10;
    $startpage      = 0;
    $max            = $mreplies + 1;
    if ( substr( $INFO{'start'}, 0, 3 ) eq 'all' && $showpageall != 0 ) {
        $maxmessagedisplay = $max;
        $all               = 1;
        $allselected       = q~ selected="selected"~;
        $start             = !$ttsreverse ? 0 : $mreplies;
    }
    else {
        $start =
          $INFO{'start'} !~ /\d/xsm
          ? ( !$ttsreverse ? 0 : $mreplies )
          : $INFO{'start'};
    }
    $start = $start > $mreplies ? $mreplies : $start;
    $start =
      !$ttsreverse
      ? ( int( $start / $maxmessagedisplay ) * $maxmessagedisplay )
      : (
        int( ( $mreplies - $start ) / $maxmessagedisplay ) *
          $maxmessagedisplay );
    $tmpa = 1;
    $pagenumb = int( ( $max - 1 ) / $maxmessagedisplay ) + 1;

    if ( $start >= ( ( $postdisplaynum - 1 ) * $maxmessagedisplay ) ) {
        $startpage = $start - ( ( $postdisplaynum - 1 ) * $maxmessagedisplay );
        $tmpa = int( $startpage / $maxmessagedisplay ) + 1;
    }
    if ( $max >= $start + ( $postdisplaynum * $maxmessagedisplay ) ) {
        $endpage = $start + ( $postdisplaynum * $maxmessagedisplay );
    }
    else { $endpage = $max; }
    $lastpn  = int( $mreplies / $maxmessagedisplay ) + 1;
    $lastptn = ( $lastpn - 1 ) * $maxmessagedisplay;
    $pageindex1 =
qq~<span class="small pgindex"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /> $display_txt{'139'}: $pagenumb</span>~;
    $pageindex2 = $pageindex1;
    if ( $pagenumb > 1 || $all ) {
        if ( $userthreadpage == 1 || $iamguest ) {
            $pagetxtindexst = q~<span class="small pgindex">~;
            if ( !$iamguest ) {
                $pagetxtindexst .=
                    qq~<a href="$scripturl?num=$viewnum;start=~
                  . ( !$ttsreverse ? $start : $mreplies - $start )
                  . qq~;action=threadpagedrop"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /></a> $display_txt{'139'}: ~;
            }
            else {
                $pagetxtindexst .=
qq~<img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /> $display_txt{'139'}: ~;
            }
            if ( $startpage > 0 ) {
                $pagetxtindex =
                    qq~<a href="$scripturl?num=$viewnum/~
                  . ( !$ttsreverse ? 0 : $mreplies )
                  . qq~"><span class="small">1</span></a>&nbsp;<a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>&nbsp;~;
            }
            if ( $startpage == $maxmessagedisplay ) {
                $pagetxtindex =
                    qq~<a href="$scripturl?num=$viewnum/~
                  . ( !$ttsreverse ? 0 : $mreplies )
                  . q~"><span class="small">1</span></a>&nbsp;~;
            }
            foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
                if ( $counter % $maxmessagedisplay == 0 ) {
                    $pagetxtindex .=
                      $start == $counter
                      ? qq~<b>[$tmpa]</b>&nbsp;~
                      : qq~<a href="$scripturl?num=$viewnum/~
                      . ( !$ttsreverse ? $counter : ( $mreplies - $counter ) )
                      . qq~"><span class="small">$tmpa</span></a>&nbsp;~;
                    $tmpa++;
                }
            }
            if ( $endpage < $max - ($maxmessagedisplay) ) {
                $pageindexadd =
qq~<a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>&nbsp;~;
            }
            if ( $endpage != $max ) {
                $pageindexadd .=
                    qq~<a href="$scripturl?num=$viewnum/~
                  . ( !$ttsreverse ? $lastptn : $mreplies - $lastptn )
                  . qq~"><span class="small">$lastpn</span></a>~;
            }
            $pagetxtindex .= qq~$pageindexadd~;
            $pageindex1 = qq~$pagetxtindexst$pagetxtindex</span>~;
            $pageindex2 = $pageindex1;

        }
        else {
            $pagedropindex1 = q~<span class="pagedropindex">~;
            $pagedropindex1 .=
qq~<span class="pagedropindex_inner"><a href="$scripturl?num=$viewnum;start=~
              . ( !$ttsreverse ? $start : $mreplies - $start )
              . qq~;action=threadpagetext"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /></a></span>~;
            $pagedropindex2 = $pagedropindex1;
            $tstart         = $start;

            $d_indexpages = $pagenumb / $dropdisplaynum;
            $i_indexpages = int( $pagenumb / $dropdisplaynum );
            if ( $d_indexpages > $i_indexpages ) {
                $indexpages = int( $pagenumb / $dropdisplaynum ) + 1;
            }
            else { $indexpages = int( $pagenumb / $dropdisplaynum ) }
            $selectedindex =
              int( ( $start / $maxmessagedisplay ) / $dropdisplaynum );

            if ( $pagenumb > $dropdisplaynum ) {
                $pagedropindex1 .=
qq~<span class="decselector"><select size="1" name="decselector1" id="decselector1" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
                $pagedropindex2 .=
qq~<span class="decselector"><select size="1" name="decselector2" id="decselector2" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
            }

            for my $i ( 0 .. ( $indexpages - 1 ) ) {
                $indexpage =
                  !$ttsreverse
                  ? ( $i * $dropdisplaynum * $maxmessagedisplay )
                  : (
                    $mreplies - ( $i * $dropdisplaynum * $maxmessagedisplay ) );
                $indexstart = ( $i * $dropdisplaynum ) + 1;
                $indexend = $indexstart + ( $dropdisplaynum - 1 );
                if ( $indexend > $pagenumb ) { $indexend = $pagenumb; }
                if ( $indexstart == $indexend ) {
                    $indxoption = qq~$indexstart~;
                }
                else { $indxoption = qq~$indexstart-$indexend~; }
                $selected = q{};
                if ( $i == $selectedindex ) {
                    $selected = q~ selected="selected"~;
                    $pagejsindex =
                      qq~$indexstart|$indexend|$maxmessagedisplay|$indexpage~;
                }
                if ( $pagenumb > $dropdisplaynum ) {
                    $pagedropindex1 .=
qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
                    $pagedropindex2 .=
qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
                }
            }

            if ( $pagenumb > $dropdisplaynum ) {
                $pagedropindex1 .= qq~</select>\n</span>~;
                $pagedropindex2 .= qq~</select>\n</span>~;
            }
            $pagedropindex1 .=
q~<span id="ViewIndex1" class="droppageindex viewindex_hid">&nbsp;</span>~;
            $pagedropindex2 .=
q~<span id="ViewIndex2" class="droppageindex viewindex_hid">&nbsp;</span>~;
            $tmpmaxmessagedisplay = $maxmessagedisplay;
            $prevpage =
               !$ttsreverse
              ? $start - $tmpmaxmessagedisplay
              : $mreplies - $start + $tmpmaxmessagedisplay;
            $nextpage =
               !$ttsreverse
              ? $start + $maxmessagedisplay
              : $mreplies - $start - $maxmessagedisplay;
            $pagedropindexpvbl =
qq~<img src="$index_togl{'index_left0'}" height="14" width="13" alt="" />~;
            $pagedropindexnxbl =
qq~<img src="$index_togl{'index_right0'}" height="14" width="13" alt="" />~;

            if (   ( !$ttsreverse && $start < $maxmessagedisplay )
                or ( $ttsreverse && $prevpage > $mreplies ) )
            {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left0'}" height="14" width="13" alt="" />~;
            }
            else {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left'}" height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" class="cursor" onclick="location.href=\\'$scripturl?num=$viewnum/$prevpage\\'" ondblclick="location.href=\\'$scripturl?num=$viewnum/~
                  . ( !$ttsreverse ? 0 : $mreplies )
                  . q~\\'" />~;
            }
            if (   ( !$ttsreverse && $nextpage > $lastptn )
                or ( $ttsreverse && $nextpage < $mreplies - $lastptn ) )
            {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right0'}" height="14" width="13" alt="" />~;
            }
            else {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right'}" height="14" width="13" alt="$pidtxt{'03'}" title="$pidtxt{'03'}" class="cursor" onclick="location.href=\\'$scripturl?num=$viewnum/$nextpage\\'" ondblclick="location.href=\\'$scripturl?num=$viewnum/~
                  . ( !$ttsreverse ? $lastptn : $mreplies - $lastptn )
                  . q~\\'" />~;
            }
            $pageindex1 = qq~$pagedropindex1</span>~;
            $pageindex2 = qq~$pagedropindex2</span>~;

            $pageindexjs = qq~
    function SelDec(decparam, visel) {
        splitparam = decparam.split("|");
        var vistart = parseInt(splitparam[0]);
        var viend = parseInt(splitparam[1]);
        var maxpag = parseInt(splitparam[2]);
        var pagstart = parseInt(splitparam[3]);
        //var allpagstart = parseInt(splitparam[3]);
        if(visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
        var pagedropindex = '$visel_0';
        for(i=vistart; i<=viend; i++) {
            if(visel == pagstart) pagedropindex += '$visel_1a<b>' + i + '</b>$visel_1b';
            else pagedropindex += '$visel_2a<a href="$scripturl?num=$viewnum/' + pagstart + '">' + i + '</a>$visel_1b';
            pagstart ~ . ( !$ttsreverse ? q{+} : q{-} ) . q~= maxpag;
        }
        ~;
            if ($showpageall) {
                $pageindexjs .= qq~
            if (vistart != viend) {
                if(visel == 'all') pagedropindex += '$visel_1a<b>$pidtxt{'01'}</b>$visel_1b';
                else pagedropindex += '$visel_2a<a href="$scripturl?num=$viewnum/all">$pidtxt{'01'}</a>$visel_1b';
            }
            ~;
            }
            $pageindexjs .= qq~
        if(visel != 'xx') pagedropindex += '$visel_3a$pagedropindexpv$pagedropindexnx$visel_1b';
        else pagedropindex += '$visel_3a$pagedropindexpvbl$pagedropindexnxbl$visel_1b';
        pagedropindex += '$visel_4';
        document.getElementById("ViewIndex1").innerHTML=pagedropindex;
        document.getElementById("ViewIndex1").style.visibility = "visible";
        document.getElementById("ViewIndex2").innerHTML=pagedropindex;
        document.getElementById("ViewIndex2").style.visibility = "visible";
        ~;
            if ( $pagenumb > $dropdisplaynum ) {
                $pageindexjs .= q~
        document.getElementById("decselector1").value = decparam;
        document.getElementById("decselector2").value = decparam;
        ~;
            }
            $pageindexjs .= qq~
    }
    SelDec('$pagejsindex', '~
              . ( !$ttsreverse ? $tstart : ( $mreplies - $tstart ) ) . q~');
~;
        }
    }

    if ( !$iamguest ) {
        my $addnotlink = $img{'add_notify'};
        my $remnotlink = $img{'del_notify'};
        if ($useThreadtools) {
            $addnotlink =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
            $remnotlink =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
        }
        $yyjavascript .= qq~
        var addnotlink = '$addnotlink';
        var remnotlink = '$remnotlink';
        ~;

        if (
            ${ $uid . $username }{'thread_notifications'} =~ /\b$viewnum\b/xsm )
        {
            $notify =
qq~$menusep<a href="javascript:Notify('$scripturl?action=notify3;num=$viewnum/~
              . ( !$ttsreverse ? $start : $mreplies - $start )
              . qq~','$imagesdir')" id="notifylink">$img{'del_notify'}</a>~;
            $notify2 =
qq~$menusep<a href="javascript:Notify('$scripturl?action=notify3;num=$viewnum/~
              . ( !$ttsreverse ? $start : $mreplies - $start )
              . qq~','$imagesdir')" id="notifylink2">$img{'del_notify'}</a>~;
        }
        else {
            $notify =
qq~$menusep<a href="javascript:Notify('$scripturl?action=notify2;num=$viewnum/~
              . ( !$ttsreverse ? $start : $mreplies - $start )
              . qq~','$imagesdir')" id="notifylink">$img{'add_notify'}</a>~;
            $notify2 =
qq~$menusep<a href="javascript:Notify('$scripturl?action=notify2;num=$viewnum/~
              . ( !$ttsreverse ? $start : $mreplies - $start )
              . qq~','$imagesdir')" id="notifylink2">$img{'add_notify'}</a>~;

        }
    }


    # update the .ctb file START
    MessageTotals( 'load', $viewnum );
    if ( $username ne 'Guest' ) {
        my ( %viewer, @tmprepliers, $isrep );
        foreach (@logentries)
        {    # @logentries already loaded in YaBB.pl => &WriteLog;
            $viewer{ ( split /\|/xsm, $_, 2 )[0] } = 1;
        }

        my $j = 0;
        foreach (@repliers) {
            my ( $reptime, $repuser, $isreplying ) = split /\|/xsm, $_;
            next if $date - $reptime > 600 || !exists $viewer{$repuser};
            if ( $repuser eq $username ) {
                $tmprepliers[$j] = qq~$date|$repuser|0~;
                $isrep = 1;
            }
            else { $tmprepliers[$j] = qq~$reptime|$repuser|$isreplying~; }
            $j++;
        }
        if ( !$isrep ) { push @tmprepliers, qq~$date|$username|0~; }
        @repliers = @tmprepliers;

        ${$viewnum}{'views'}++;   # Add 1 to the number of views of this thread.
        MessageTotals( 'update', $viewnum );
    }
    else {
        MessageTotals( 'incview', $viewnum );

        # Add 1 to the number of views of this thread.
    }

    # update the .ctb file END

    # Mark current board as read if no other new threads are in
    getlog();

# &NextPrev => Insert Navigation Bit and get info about number of threads newer than last visit
    if ( NextPrev( $viewnum, $yyuserlog{$currentboard} ) < 2 ) {
        $yyuserlog{$currentboard} = $date;
    }

    # Mark current thread as read. Save thread and board Mark.
    delete $yyuserlog{"$mnum--unread"};
    dumplog($mnum);

    $template_home = qq~<a href="$scripturl" class="nav">$mbname</a>~;
    $topviewers    = 0;
    if ( ${ $uid . $currentboard }{'ann'} == 1 ) {
        if ($vircurrentboard) {
            $template_cat =
              qq~<a href="$scripturl?catselect=$vircurcat">$vircat</a>~;
            $template_board =
              qq~<a href="$scripturl?board=$vircurrentboard">$virboardname</a>~;
            $navback =
qq~<a href="$scripturl?board=$vircurrentboard">&lsaquo; $maintxt{'board'}</a>~;
            $template_mods = qq~$showmods$showmodgroups~;
        }
        elsif ( $iamadmin || $iamgmod || $iamfmod ) {
            $template_cat = qq~<a href="$scripturl?catselect=$curcat">$cat</a>~;
            $template_board =
              qq~<a href="$scripturl?board=$currentboard">$boardname</a>~;
            $navback =
qq~<a href="$scripturl?board=$currentboard">&lsaquo; $maintxt{'board'}</a>~;
            $template_mods = qq~$showmods$showmodgroups~;
        }
        else {
            $template_cat   = $maintxt{'418'};
            $template_board = $display_txt{'999'};
            $template_mods  = q{};
        }
    }
    else {
        $template_cat = qq~<a href="$scripturl?catselect=$curcat">$cat</a>~;
        $template_board =
          qq~<a href="$scripturl?board=$currentboard">$boardname</a>~;
        $navback =
qq~<a href="$scripturl?board=$currentboard">&lsaquo; $maintxt{'board'}</a>~;
        $template_mods = qq~$showmods$showmodgroups~;
    }
    if (   $showtopicviewers
        && ($staff)
        && $sessionvalid == 1 )
    {
        foreach (@repliers) {
            my ( undef, $mrepuser, $misreplying ) = split /\|/xsm, $_;
            LoadUser($mrepuser);
            my $replying =
              $misreplying
              ? qq~ <span class="small">($display_txt{'645'})</span>~
              : q{};
            $template_viewers .= qq~$link{$mrepuser}$replying, ~;
            $topviewers++;
        }
        $template_viewers =~ s/\, \Z/\./sm;
    }

    $yyjavascript .= qq~
        var addfavlang = '$display_txt{'526'}';
        var remfavlang = '$display_txt{'527'}';
        var remnotelang = '$display_txt{'530'}';
        var addnotelang = '$display_txt{'529'}';
        var markfinishedlang = '$display_txt{'528'}';~;

    if ( !$iamguest && $currentboard ne $annboard ) {
        require Sources::Favorites;
        $template_favorite =
          IsFav( $viewnum, ( !$ttsreverse ? $start : $mreplies - $start ) );
        $template_favorite2 =
          IsFav1( $viewnum, ( !$ttsreverse ? $start : $mreplies - $start ) );
    }
    $template_threadimage = qq~$micon{$threadclass}~;
    $template_sendtopic =
      $sendtopicmail
      ? qq~$menusep<a href="javascript:sendtopicmail($sendtopicmail);">$img{'sendtopic'}</a>~
      : q{};
    $template_print =
qq~$menusep<a href="javascript:void(window.open('$scripturl?action=print;num=$viewnum','printwindow'))">$img{'print'}</a>~;
    if ($has_poll) {
        require Sources::Poll;
        display_poll($viewnum);
        $template_pollmain = $pollmain;
    }

    # Load background color list.
    @cssvalues = qw( windowbg windowbg2 );
    $cssnum    = @cssvalues;

    if ( !$UseMenuType ) { $sm = 1; }

    if ( !ref $thread_arrayref{$viewnum} ) {
        fopen( MSGTXT, "$datadir/$viewnum.txt" )
          or fatal_error( 'cannot_open', "$datadir/$viewnum.txt", 1 );
        @{ $thread_arrayref{$viewnum} } = <MSGTXT>;
        fclose(MSGTXT);
    }
    $counter = 0;
    my @messages;

    # Skip the posts in this thread until we reach $start.
    if ( !$ttsreverse ) {
        foreach ( @{ $thread_arrayref{$viewnum} } ) {
            if (    $counter >= $start
                and $counter < ( $start + $maxmessagedisplay ) )
            {
                push @messages, $_;
            }
            $counter++;
        }
        $counter = $start;

    }
    else {
        foreach ( @{ $thread_arrayref{$viewnum} } ) {
            if (    $counter > ( $mreplies - $start - $maxmessagedisplay )
                and $counter <= ( $mreplies - $start ) )
            {
                push @messages, $_;
            }
            $counter++;
        }
        $counter  = $mreplies - $start;
        @messages = reverse @messages;
    }

    if (   !$allowpics
        || !$showuserpic
        || ( ${ $uid . $username }{'hide_avatars'} && $user_hide_avatars ) )
    {
        $hideavatar = 1;
    }
    if ( !$showusertext
        || ( ${ $uid . $username }{'hide_user_text'} && $user_hide_user_text ) )
    {
        $hideusertext = 1;
    }
    if ( ${ $uid . $username }{'hide_attach_img'} && $user_hide_attach_img ) {
        $hideattachimg = 1;
    }
    if (   ( ${ $uid . $username }{'hide_signat'} && $user_hide_signat )
        || ( $hide_signat_for_guests && $iamguest ) )
    {
        $hidesignat = 1;
    }

    # For each post in this thread:
    my ( %attach_gif, %attach_count );
    my $movedflag = q{};
    foreach (@messages) {
        my (
            $userlocation,      $aimad,             $yimad,
            $gtalkad,           $skypead,           $myspacead,
            $facebookad,        $twitterad,         $youtubead,
            $icqad,             $buddyad,           $addbuddy,
            $isbuddy,           $addbuddylink,      $userOnline,
            $signature_hr,      $lastmodified,      $memberinfo,
            $template_postinfo, $template_ext_prof, $template_profile,
            $template_quote,    $template_email,    $template_www,
            $template_pm,       $template_age,      $template_regdate
        );

        $css = $cssvalues[ ( $counter % $cssnum ) ];
        (
            $msub,  $mname,   $memail, $mdate,       $musername,
            $micon, $mattach, $mip,    $postmessage, $ns,
            $mlm,   $mlmb,    $mfn
        ) = split /[\|]/xsm, $_;

        # If the user isn't a guest, load their info.
        if (   $musername ne 'Guest'
            && !$yyUDLoaded{$musername}
            && -e ("$memberdir/$musername.vars") )
        {
            my $tmpns = $ns;
            $ns = q{};
            LoadUserDisplay($musername);
            $ns = $tmpns;
        }
        $messagedate = $mdate;
        if ( ${ $uid . $musername }{'regtime'} ) {
            $registrationdate = ${ $uid . $musername }{'regtime'};
        }
        else {
            $registrationdate = $date;
        }

        # Do we have an attachment file?
        chomp $mfn;
        $attachment   = q{};
        $showattach   = q{};
        $showattachhr = q{};
        if ( $mfn ne q{} ) {

            # store all downloadcounts in variable
            if ( !%attach_count ) {
                fopen( ATM, "$vardir/attachments.txt" );
                while (<ATM>) {
                    chomp $_;
                    my (
                        undef, undef, undef,   undef, undef,
                        undef, undef, $atfile, $atcount
                    ) = split /\|/xsm, $_;
                    $attach_count{$atfile} = $atcount;
                }
                fclose(ATM);
                if ( !%attach_count ) { $attach_count{'no_attachments'} = 1; }
            }

            foreach ( split /,/xsm, $mfn ) {
                if ( $_ =~ /\.(.+?)$/xsm ) {
                    $ext = lc $1;
                }
                if ( !exists $attach_gif{$ext} ) {
                    $attach_gif{$ext} =
                      ( $att_img{$ext}
                          && -e "$htmldir/Templates/Forum/$useimages/$att_img{$ext}"
                      )
                      ? "$imagesdir/$att_img{$ext}"
                      : "$micon_bg{'paperclip'}";
                }
                my $filesize = -s "$uploaddir/$_";
                $urlname = $_;
                $urlname =~ s/([^A-Za-z0-9])/sprintf('%%%02X', ord($1))/egxsm;
                $download_txt = ( $attach_count{$_} == 1 ) ? $fatxt{'41b'} : isempty( $fatxt{'41c'}, $fatxt{'41a'} );
                if ($filesize) {
                    if (   $_ =~ /\.(bmp|jpe|jpg|jpeg|gif|png)$/ixsm
                        && $amdisplaypics == 1 )
                    {
                        $showattach .=
qq~<div class="small attbox"><a href="$scripturl?action=downloadfile;file=$urlname" target="_blank"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $_</a> ( ~
                          . int( $filesize / 1024 )
                          . qq~ KB | $attach_count{$_} $download_txt )<br />~
                          . (
                            $img_greybox
                            ? (
                                $img_greybox == 2
                                ? qq~<a href="$scripturl?action=downloadfile;file=$urlname" data-rel="gb_imageset[nice_pics]" title="$_">~
                                : qq~<a href="$scripturl?action=downloadfile;file=$urlname" data-rel="gb_image[nice_pics]" title="$_">~
                              )
                            : qq~<a href="$scripturl?action=downloadfile;file=$urlname" target="_blank">~
                          )
                          . qq~<img src="$uploadurl/$_" name="attach_img_resize" alt="$_" title="$_" style="display:none" /></a></div>\n~;
                    }
                    else {
                        $attachment .=
qq~<div class="small"><a href="$scripturl?action=downloadfile;file=$urlname"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $_</a> ( ~
                          . int( $filesize / 1024 )
                          . qq~ KB | $attach_count{$_} $download_txt )</div>~;
                    }
                }
                else {
                    $attachment .=
qq~<div class="small"><img src="$attach_gif{$ext}" class="bottom" alt="" />  $_ ($fatxt{'1'}~
                      . (
                        exists $attach_count{$_}
                        ? qq~ | $attach_count{$_} $download_txt ~
                        : q{}
                      ) . q~)</div>~;
                }
            }
            $showattachhr = q~<hr class="hr att_hr" />~;
            if ( $showattach && $attachment ) {
                $attachment =~
s/<div class="small">/<div class="small attbox_b">/gsm;
            }
        }

        # Should we show "last modified by?"
        if (
               $showmodify
            && $mlm  ne q{}
            && $mlmb ne q{}
            && ( !$tllastmodflag
                || ( $mdate + ( $tllastmodtime * 60 ) ) < $mlm )
          )
        {
            if ($mlmb) {
                LoadUser($mlmb);
                if ( $iamguest ) {
                    $mlmb = qq~$format_unbold{$mlmb}~;
                }
                else {
                    $mlmb =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$mlmb}">$format_unbold{$mlmb}</a>~;
                }
            }
            else {
                $mlmb = $display_txt{'470'};
            }
            $lastmodified =
                qq~&#171; <i>$display_txt{'211'}: ~
              . timeformat($mlm,0,0,0,1)
              . qq~ $display_txt{'525'} $mlmb</i> &#187;~;
        }

        if ($ipLookup) {
            ( $mip_one, $mip_two, $mip_three ) = split / /sm, $mip;
            if ($mip_one) {
                $lookupIP =
qq~<a href="$scripturl?action=iplookup;ip=$mip_one"><span class="small">$mip_one</span></a>~;
            }
            if ($mip_two) {
                $lookupIP .=
qq~ <a href="$scripturl?action=iplookup;ip=$mip_two"><span class="small">$mip_two</span></a>~;
            }
            if ($mip_three) {
                $lookupIP .=
qq~ <a href="$scripturl?action=iplookup;ip=$mip_three"><span class="small">$mip_three</span></a>~;
            }
        }
        else {
            $lookupIP = $mip;
        }
        if (   $iamadmin
            || $iamfmod
            || $iamgmod && $gmod_access2{'ipban2'} eq 'on' )
        {
            $mip = $lookupIP;
        }
        else { $mip = $display_txt{'511'}; }

        ## moderator alert button!
        if (   $PMenableAlertButton
            && $PM_level
            && !$staff
            && ( !$iamguest || ( $iamguest && $PMAlertButtonGuests ) ) )
        {
            $PMAlertButton =
qq~                 $menusep<a href="$scripturl?action=modalert;num=$viewnum;title=PostReply;quote=$counter" onclick="return confirm('$display_txt{'alertmod_confirm'}');">$img{'alertmod'}</a>~;
        }

        ## is member a buddy of mine?
        if ( $buddyListEnabled && !$iamguest && $musername ne $username ) {
            $isbuddy =
qq~<br /><img src="$micon_bg{'buddylist'}" alt="$display_txt{'isbuddy'}" title="$display_txt{'isbuddy'}" /> <br />$display_txt{'isbuddy'}~;
            $addbuddylink =
qq~$menusep<a href="$scripturl?num=$viewnum;action=addbuddy;name=$useraccount{$musername};vpost=$counter">$img{'addbuddy'}</a>~;
        }

        # user is current / admin / gmod
        if (
            (
                ${ $uid . $musername }{'regdate'}
                && $messagedate > $registrationdate
            )
            || ${ $uid . $musername }{'position'} eq 'Administrator'
            || ${ $uid . $musername }{'position'} eq 'Global Moderator'
          )
        {
            if ( !$iamguest && $musername ne $username ) {
                ## check whether user is a buddy
                if   ( $mybuddie{$musername} ) { $buddyad  = $isbuddy; }
                else                           { $addbuddy = $addbuddylink; }

                # Allow instant message sending if current user is a member.
                CheckUserPM_Level($musername);
                if (
                    $PM_level == 1
                    || (   $PM_level == 2
                        && $UserPM_Level{$musername} > 1
                        && $staff )
                    || (   $PM_level == 3
                        && $UserPM_Level{$musername} == 3
                        && ( $iamadmin || $iamgmod ) )
                    || (   $PM_level == 3
                        && $UserPM_Level{$musername} == 4
                        && ( $iamadmin || $iamgmod || $iamfmod ) )
                  )
                {
                    $template_pm =
qq~$menusep<a href="$scripturl?action=imsend;to=$useraccount{$musername}">$img{'message_sm'}</a>~;
                }
            }

            $tmppostcount = NumberFormat( ${ $uid . $musername }{'postcount'} );
            if ($iamguest) {
                $template_postinfo =
                  qq~$display_txt{'21'}: $tmppostcount<br />~;
            }
            else {
                my $lastPostsTxt;
                if ( $username eq $musername ) {
                    $lastPostsTxt = $display_txt{'mylastposts'};
                }
                else {
                    $lastPostsTxt =
                      $display_txt{'lastposts'}
                      . ${ $uid . $musername }{'realname'};
                }
                $template_postinfo =
qq~$display_txt{'21'}: <a href="$scripturl?action=usersrecentposts;username=$useraccount{$musername}" title="$lastPostsTxt"><span class="small">$tmppostcount</span></a><br />~;
            }
            if (   ${ $uid . $musername }{'bday'}
                && $showuserage
                && ( !$showage || !${ $uid . $musername }{'hideage'} ) )
            {
                CalcAge( $musername, 'calc' );
                $template_age = qq~$display_txt{'age'}: $age<br />~;
            }
            if ( $showregdate && ${ $uid . $musername }{'regtime'} ) {
                $dr_regdate = timeformat( ${ $uid . $musername }{'regtime'},0,0,0,1 );
                $dr_regdate = dtonly($dr_regdate);
                $dr_regdate =~ s/(.*)(, 1?[0-9]):[0-9][0-9].*/$1/xsm;
                $template_regdate =
                  qq~$display_txt{'regdate'} $dr_regdate<br />~;
            }
            $template_profile =
              ( $profilebutton && !$iamguest )
              ? qq~$menusep<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">$img{'viewprofile_sm'}</a>~
              : q{};
            $template_www =
              ${ $uid . $musername }{'weburl'}
              ? qq~$menusep${$uid.$musername}{'weburl'}~
              : q{};

            $userOnline  = userOnLineStatus($musername) . q~<br />~;
            $displayname = ${ $uid . $musername }{'realname'};
            if ( ${ $uid . $musername }{'location'} ) {
                $userlocation =
                    qq~$display_txt{'location'}: ~
                  . ${ $uid . $musername }{'location'}
                  . q~<br />~;
            }
            if ( ${ $uid . $musername }{'signature'} ) {
                $signature_hr = q~<hr class="hr att_hr" />~;
            }
            $memberinfo = "$memberinfo{$musername}$addmembergroup{$musername}";

            $aimad =
              ${ $uid . $musername }{'aim'}
              ? qq~$menusep${$uid.$musername}{'aim'}~
              : q{};
            $memailad =
              ${ $uid . $musername }{'email'}
              ? qq~${$uid.$musername}{'email'}~
              : q{};
            $icqad =
              ${ $uid . $musername }{'icq'}
              ? qq~$menusep${$uid.$musername}{'icq'}~
              : q{};
            $yimad =
              ${ $uid . $musername }{'yim'}
              ? qq~$menusep${$uid.$musername}{'yim'}~
              : q{};
            $gtalkad =
              ${ $uid . $musername }{'gtalk'}
              ? qq~$menusep${$uid.$musername}{'gtalk'}~
              : q{};
            $skypead =
              ${ $uid . $musername }{'skype'}
              ? qq~$menusep${$uid.$musername}{'skype'}~
              : q{};
            $myspacead =
              ${ $uid . $musername }{'myspace'}
              ? qq~$menusep${$uid.$musername}{'myspace'}~
              : q{};
            $facebookad =
              ${ $uid . $musername }{'facebook'}
              ? qq~$menusep${$uid.$musername}{'facebook'}~
              : q{};
            $twitterad =
              ${ $uid . $musername }{'twitter'}
              ? qq~$menusep${$uid.$musername}{'twitter'}~
              : q{};
            $youtubead =
              ${ $uid . $musername }{'youtube'}
              ? qq~$menusep${$uid.$musername}{'youtube'}~
              : q{};

            $usernamelink = QuickLinks($musername);
            if ($extendedprofiles) {
                require Sources::ExtendedProfiles;
                $usernamelink =
                  ext_viewinposts_popup( $musername, $usernamelink );
            }
        }
        elsif ( $musername !~ m/Guest/sm && $messagedate < $registrationdate ) {
            $exmem        = 1;
            $memberinfo   = $display_txt{'470a'};
            $usernamelink = qq~<b>$mname</b>~;
            $displayname  = $display_txt{'470a'};
        }
        else {
            require Sources::Decoder;
            $musername    = 'Guest';
            $memberinfo   = $display_txt{'28'};
            $usernamelink = qq~<b>$mname</b>~;
            $displayname  = $mname;
            $cryptmail    = scramble( $memail, $musername );
        }
        $usernames_life_quote{ $useraccount{$musername} } =
          $displayname;    # for display names in Quotes in LivePreview

        # Insert 2
        if (
            (
                   !${ $uid . $musername }{'hidemail'}
                || $iamadmin
                || $allow_hide_email != 1
                || $musername eq 'Guest'
            )
            && !$exmem
          )
        {
            if ($iamguest) { $template_email = q{}; }
            if ( $musername ne 'Guest' ) {
                $template_email =
                  $menusep . enc_eMail( $img{'email_sm'}, $memailad, q{}, q{} );
            }
            else {
                $template_email =
                  $menusep . enc_eMail( $img{'email_sm'}, $memail, q{}, q{} );
            }
            if ($iamadmin) {
                if ( $musername ne 'Guest' ) {
                    $template_email =~
                      s/title=\\"$img_txt{'69'}\\"/title=\\"$memailad\\"/xsm;
                }
                else {
                    $template_email =~
                      s/title=\\"$img_txt{'69'}\\"/title=\\"$memail\\"/xsm;
                }
            }
        }
        if ($iamguest) { $template_email = q{}; }

        $counterwords =
          $counter != 0 ? "$display_txt{'146'} #$counter - " : q{};

        $messdate = timeformat($mdate);
        if ( $counterwords ) {
            $messdate = timeformat($mdate,0,0,0,1);
        }

        # Print the post and user info for the poster.
        my $outblock        = $messageblock;
        my $posthandelblock = $posthandellist;
        my $contactblock    = $contactlist;

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        $msub = isempty( $msub, $display_txt{'24'} );
        ToChars($msub);
        my $reason;
        if (   $lastmodified
            && ( $staff_reason || $user_reason )
            && $postmessage =~ s/\[reason\](.+?)\[\/reason\]//isgm )
        {
            $reason = qq~<br /><i><b>$display_txt{'211a'}:</b> $1</i>~;
            $reason = Censor($reason);
            ToChars($reason);
        }
        $msub = Censor($msub);

        $message = Censor($postmessage);
        wrap();
        ( $message, $movedflag ) = Split_Splice_Move( $message, $viewnum );
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        wrap2();
        ToChars($message);

        if ($icanbypass) {
            $template_modify =
qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=$counter;thread=$viewnum" onclick="return confirm('$display_txt{'modifyinlocked'}');">$img{'modify'}</a>~;
        }

        if ( $mstate !~ /l/ism ) {
            if ($replybutton) {
                my $quote_mname = $displayname;
                $quote_mname =~ s/'/\\'/gxsm;
                if (   $enable_quickreply
                    && $enable_quoteuser
                    && ( !$iamguest || $enable_guestposting ) )
                {
                    $usernamelink =
qq~<a href="javascript:void(AddText('[color=$quoteuser_color]@[/color] [b]$quote_mname\[/b]\\r\\n\\r\\n'))"><img src="$imagesdir/$disp_qquname" alt="$display_txt{'146n'}" title="$display_txt{'146n'}" /></a> $usernamelink~;
                }

                if (  !$movedflag
                    || $staff )
                {
                    if ($enable_quickreply) {
                        $quote_mname = $useraccount{$musername};
                        $quote_mname =~ s/'/\\'/gxsm;
                        if ($enable_markquote) {
                            my $quoteinfo;
                            my $quotesmess = $postmessage;
                            while ( $quotesmess =~ s/\[quote (.*?)\]//sm ) {
                                my ( $tmpqauth, $tmpqlink, $tmpqdate ) =
                                  split / /sm, $1;
                                my ( undef, $tmpqau ) = split /=/xsm, $tmpqauth;
                                my ( undef, $tmpqli ) = split /=/xsm, $tmpqlink;
                                my ( undef, $tmpqda ) = split /=/xsm, $tmpqdate;

                                $quoteinfo .= qq~$tmpqau-$tmpqli-$tmpqda|~;
                            }
                            $outblock =~ s/(<div)( class="$messageclass" style="float: left; width: 99%; overflow: auto;">)/$1 id="mq$counter" onmouseup="get_selection($counter, '$quoteinfo');"$2/i;

                            $template_quote =
qq~$menusep<a href="javascript:void(quoteSelection('$quote_mname',$viewnum,$counter,$mdate,''))">$img{'mquote'}</a>~;
                        }
                        else {
                            $template_quote = q{};
                        }
                        if ($enable_quickjump) {
                            if ( length($postmessage) <= $quick_quotelength ) {
                                my $quickmessage = $postmessage;
                                if ( !$nestedquotes ) {
                                    $quickmessage =~
s/(<(br|p).*?>){0,1}\[quote([^\]]*)\](.*?)\[\/quote([^\]]*)\](<(br|p).*?>){0,1}/<br \/>/igsm;
                                }
                                $quickmessage =~ s/<(br|p).*?>/\\r\\n/igxsm;
                                $quickmessage =~ s/'/\\'/gxsm;
                                $template_quote .=
qq~$menusep<a href="javascript:void(quoteSelection('$quote_mname',$viewnum,$counter,$mdate,'$quickmessage'))">$img{'quote'}</a>~;
                            }
                            else {
                                $template_quote .=
qq~$menusep<a href="javascript:void(quick_quote_confirm('$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply'))">$img{'quote'}</a>~;
                            }
                        }
                        else {
                            $template_quote .=
qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply">$img{'quote'}</a>~;
                        }
                    }
                    else {
                        $template_quote =
qq~$menusep<a href="$scripturl?action=post;num=$viewnum;virboard=$vircurrentboard;quote=$counter;title=PostReply">$img{'quote'}</a>~;
                    }
                }
            }
            if (
                $sessionvalid == 1
                && (
                    $staff
                    || (
                        $username eq $musername
                        && (  !$tlnomodflag
                            || $date < $mdate + ( $tlnomodtime * 3600 * 24 ) )
                    )
                )
              )
            {
                $template_modify =
qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=$counter;thread=$viewnum">$img{'modify'}</a>~;
            }
            else {
                $template_modify = q{};
            }
            $postnum = $counter + 1;
                $template_print_post =
qq~$menusep<a href="javascript:void(window.open('$scripturl?action=print;num=$viewnum;post=$postnum','printwindow'))">$img{'printp'}</a>~;

            if (   $counter > 0
                && ($staff)
                && $sessionvalid == 1 )
            {
                $template_split =
qq~$menusep<a href="$scripturl?action=split_splice;board=$currentboard;thread=$viewnum;oldposts=~
                  . join( ',%20', ( $counter .. $mreplies ) )
                  . qq~;leave=0;newcat=$curcat;newboard=$currentboard;newthread=new;ss_submit=1" onclick="return confirm('$display_txt{'split_confirm'}');">$img{'admin_split'}</a>~;
            }
            if (
                $sessionvalid == 1
                && (
                    $staff
                    || (
                        $username eq $musername
                        && (  !$tlnodelflag
                            || $date < $mdate + ( $tlnodeltime * 3600 * 24 ) )
                    )
                )
              )
            {
                $template_delete =
qq~$menusep<a class="cursor" onclick="if(confirm('$display_txt{'rempost'}')) {uncheckAllBut($counter);}">$img{'delete'}</a>~;
                if (
                    (
                           ( $iammod && $mdmod == 1 )
                        || ( $iamadmin && $mdadmin == 1 )
                        || ( $iamfmod  && $mdfmod == 1 )
                        || ( $iamgmod  && $mdglobal == 1 )
                    )
                    && $sessionvalid == 1
                  )
                {
                    $template_admin =
qq~<input type="checkbox" class="$css" name="del$counter" value="$counter" title="$display_txt{'739a'}" />~;
                }
                else {

# need to set visibility to hidden - used for regular users to delete their posts too,
                    $template_admin =
qq~<input type="checkbox" class="$css" style="border: 0px; visibility: hidden; display: none;" name="del$counter" value="$counter" title="$display_txt{'739a'}" />~;
                }
            }
            else {
                $template_delete = q{};
                $template_admin =
qq~<input type="checkbox" class="$css" style="border: 0px; visibility: hidden; display: none;" name="del$counter" value="$counter" title="$display_txt{'739a'}" />~;
            }
        }

        $msgimg =
qq~<a href="$scripturl?num=$viewnum/$counter#$counter">$micon{$micon}</a>~;
        $ipimg = qq~<img src="$micon_bg{'ip'}" alt="" />~;

        if ($extendedprofiles) {
            require Sources::ExtendedProfiles;
            $template_ext_prof = ext_viewinposts($musername);
        }

        # Jump to the "NEW" Post.
        if ( $newestpost && $newestpost == $counter ) {
            $usernamelink = qq~<a id="new"></a>$usernamelink~;
        }

        $tool_sep = $usePosttools ? '|||' : q{};

        $posthandelblock =~ s/{yabb markquote}/$template_markquote$tool_sep/gsm;
        $posthandelblock =~ s/{yabb quote}/$template_quote$tool_sep/gsm;
        $posthandelblock =~ s/{yabb modify}/$template_modify$tool_sep/gsm;
        $posthandelblock =~ s/{yabb split}/$template_split$tool_sep/gsm;
        $posthandelblock =~ s/{yabb delete}/$template_delete$tool_sep/gsm;
        $posthandelblock =~ s/{yabb modalert}/$PMAlertButton$tool_sep/gsm;
        $posthandelblock =~ s/{yabb print_post}/$template_print_post$tool_sep/gsm;
        $posthandelblock =~ s/{yabb admin}/$template_admin/gsm;
        $posthandelblock =~ s/\Q$menusep//ism;

        @psetmenusep = ( "$template_markquote","$template_quote","$template_modify","$template_split","$template_delete","$PMAlertButton","$template_print_post",);
        @postout = ();
        my $psepcn = 0;
        for (@psetmenusep) {
            if ($_ ) {
               if ( !$usePosttools ) { $postout[$psepcn] = "$_$my_ttsep";}
               else  { $postout[$psepcn] = "$my_ttsep$_"; }
            }
            else  { $postout[$psepcn] = q{} }
            $psepcn++;
        }
        my $outside_posttools_tmp = $outside_posttools;
        $outside_posttools_tmp =~ s/{yabb markquote}/$postout[0]/gsm;
        $outside_posttools_tmp =~ s/{yabb quote}/$postout[1]/gsm;
        $outside_posttools_tmp =~ s/{yabb modify}/$postout[2]/gsm;
        $outside_posttools_tmp =~ s/{yabb split}/$postout[3]/gsm;
        $outside_posttools_tmp =~ s/{yabb delete}/$postout[4]/gsm;
        $outside_posttools_tmp =~ s/{yabb modalert}/$postout[5]/gsm;
        $outside_posttools_tmp =~ s/{yabb print_post}/$postout[6]/gsm;
        $outside_posttools_tmp =~ s/\Q$my_ttsep//ixsm;

        if ( !$usePosttools ) {
            $posthandelblock       = $outside_posttools_tmp . $posthandelblock;
            $outside_posttools_tmp = q{};
        }
        else {
            $outside_posttools_tmp =~ s/\Q$menusep//ixsm;
            $outside_posttools_tmp =~
              s/\[tool=(.+?)\](.+?)\[\/tool\]/$tmpimg{$1}/gxsm;
            $posthandelblock =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gxsm;
        }

        # Post and Thread Tools
        if ($usePosttools) {
            $posthandelblock =
              MakeTools( $counter, $maintxt{'63'}, $posthandelblock );
        }
        $contactblock =~ s/{yabb email}/$template_email/gsm;
        $contactblock =~ s/{yabb profile}/$template_profile/gsm;
        $contactblock =~ s/{yabb pm}/$template_pm/gsm;
        $contactblock =~ s/{yabb www}/$template_www/gsm;
        $contactblock =~ s/{yabb aim}/$aimad/gsm;
        $contactblock =~ s/{yabb yim}/$yimad/gsm;
        $contactblock =~ s/{yabb icq}/$icqad/gsm;
        $contactblock =~ s/{yabb gtalk}/$gtalkad/gsm;
        $contactblock =~ s/{yabb skype}/$skypead/gsm;
        $contactblock =~ s/{yabb myspace}/$myspacead/gsm;
        $contactblock =~ s/{yabb facebook}/$facebookad/gsm;
        $contactblock =~ s/{yabb twitter}/$twitterad/gsm;
        $contactblock =~ s/{yabb youtube}/$youtubead/gsm;
        $contactblock =~ s/{yabb addbuddy}/$addbuddy/gsm;
## Mod Hook Contactblock ##
        $contactblock =~ s/\Q$menusep//ixsm;

        $outblock =~ s/{yabb images}/$imagesdir/gsm;
        $outblock =~ s/{yabb messageoptions}/$msgcontrol/gsm;
        $outblock =~ s/{yabb memberinfo}/$memberinfo/gsm;
        $outblock =~ s/{yabb userlink}/$usernamelink/gsm;
        $outblock =~ s/{yabb location}/$userlocation/gsm;
        $outblock =~ s/{yabb stars}/$memberstar{$musername}/gsm;
        $outblock =~ s/{yabb subject}/$msub/gsm;
        $outblock =~ s/{yabb msgimg}/$msgimg/gsm;
        $outblock =~ s/{yabb msgdate}/$messdate/gsm;
        $outblock =~ s/{yabb replycount}/$counterwords/gsm;
        $outblock =~ s/{yabb count}/$counter/gsm;
        if ( $showattach || $attachment ) {
            $outblock =~ s/{yabb showatthr}/$showattachhr/gsm;
            $outblock =~ s/{yabb att}/$attachment/gsm;
            $outblock =~ s/{yabb showatt}/$showattach/gsm;
        }
        else {
            $outblock =~ s/{yabb hideatt}/ display: none;/gsm;
        }
        $outblock =~ s/{yabb css}/$css/gsm;
        $outblock =~ s/{yabb gender}/${$uid.$musername}{'gender'}/gsm;
        $outblock =~ s/{yabb zodiac}/${$uid.$musername}{'zodiac'}/gsm;
        $outblock =~ s/{yabb age}/$template_age/gsm;
        $outblock =~ s/{yabb regdate}/$template_regdate/gsm;
        $outblock =~ s/{yabb ext_prof}/$template_ext_prof/gsm;
        $outblock =~ s/{yabb postinfo}/$template_postinfo/gsm;
## Mod Hook Outbox ##
        if ( !$hideusertext ) {
            $outblock =~
              s/{yabb usertext}/${$uid.$musername}{'usertext'}/gsm;
        }
        if ( !$hideavatar ) {
            $outblock =~
              s/{yabb userpic}/${$uid.$musername}{'userpic'}/gsm;
        }
        $outblock =~ s/{yabb message}/$message/gsm;
        $outblock =~ s/{yabb modified}/$lastmodified/gsm;
        $outblock =~ s/{yabb reason}/$reason/gsm;
        if ( !$hidesignat && ${ $uid . $musername }{'signature'} ) {
            $outblock =~
              s/{yabb signature}/${$uid.$musername}{'signature'}/gsm;
            $outblock =~ s/{yabb signaturehr}/$signature_hr/gsm;
        }
        else {
            $outblock =~ s/{yabb hidesignat}/ display: none;/gsm;
        }
        $outblock =~ s/{yabb ipimg}/$ipimg/gsm;
        $outblock =~ s/{yabb ip}/$mip/gsm;
        $outblock =~
          s/{yabb outsideposttools}/$outside_posttools_tmp/gsm;
        $outblock =~ s/{yabb posthandellist}/$posthandelblock/gsm;
        $outblock =~ s/{yabb admin}/$template_admin/gsm;
        $outblock =~ s/{yabb contactlist}/$contactblock/gsm;

        if ( $accept_permalink == 1 ) {
            $outblock =~ s/{yabb permalink}/$display_permalink/gsm;
        }
        else {
            $outblock =~ s/{yabb permalink}//gsm;
        }
        $outblock =~ s/{yabb useronline}/$userOnline/gsm;
        $outblock =~ s/{yabb isbuddy}/$buddyad/gsm;

        $tmpoutblock .= $outblock;

        $counter += !$ttsreverse ? 1 : -1;
    }
    undef %UserPM_Level;

    # Insert 4

    # Insert 5
    my (
        $template_remove, $template_splice, $template_lock,
        $template_hide,   $template_sticky, $template_multidelete
    );
    if ( ($staff)
        && $sessionvalid == 1 )
    {
        $template_remove =
qq~$menusep<a href="javascript:document.removethread.submit();" onclick="return confirm('$display_txt{'162'}')">$img{'admin_rem'}</a>~;

        $template_splice =
qq~$menusep<a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$viewnum;oldposts=all;leave=0;newcat=$curcat;newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))">$img{'admin_move_split_splice'}</a>~;

        $template_lock =
qq~$menusep<a href="$scripturl?action=lock;thread=$viewnum">$img{'admin_lock'}</a>~;
        $template_hide =
qq~$menusep<a href="$scripturl?action=hide;thread=$viewnum">$img{'hide'}</a>~;
        $template_sticky =
qq~$menusep<a href="$scripturl?action=sticky;thread=$viewnum">$img{'admin_sticky'}</a>~;
        if ( ${$mnum}{'board'} eq $annboard ) { $template_sticky = q{}; }
    }
    if (
        (
               ( $iammod && $mdmod == 1 )
            || ( $iamadmin && $mdadmin == 1 )
            || ( $iamfmod  && $mdfmod == 1 )
            || ( $iamgmod  && $mdglobal == 1 )
        )
        && $sessionvalid == 1
      )
    {
        if ( $mstate !~ /l/ism ) {
            $template_multidelete =
qq~$menusep<a href="javascript:document.multidel.submit();" onclick="return confirm('$display_txt{'739'}')">$img{'admin_del'}</a>~;
        }
    }

    if ($template_viewers) {
        $topic_viewers = $mydisp_topicview;
        $topic_viewers =~ s/{yabb topviewers}/$topviewers/sm;
        $topic_viewers =~ s/{yabb template_viewers}/$template_viewers/sm;
    }

    # Social Bookmarks Start
    if ( $en_bookmarks && $bm_boards ) {
        $board_bookmarks = 0;
        foreach ( split /\, /sm, $bm_boards ) {
            if ( $_ eq $currentboard ) { $board_bookmarks = 1; }
        }
    }
    else {
        $board_bookmarks = 1;
    }
    if ( $en_bookmarks && $board_bookmarks ) {
        fopen( BMARKS, "<$vardir/Bookmarks.txt" )
          or fatal_error( 'cannot_open', "$vardir/Bookmarks.txt", 1 );
        @bookmarks = <BMARKS>;
        fclose(BMARKS);
        foreach my $bookmark ( sort { $a <=> $b } @bookmarks ) {
            chomp $bookmark;
            ( undef, $bm_title, $bm_image, $bm_url, undef ) = split /\|/xsm,
              $bookmark;
            $bm_subject = $msubthread;
            $convertstr = $bm_subject;
            $convertcut = $bm_subcut;
            CountChars();
            $bm_subject = $convertstr;
            if ($cliped) { $bm_subject .= '...'; }
            $bm_subject =~ s/([^A-Za-z0-9])/sprintf('%%%02X', ord($1))/segm;
            $bm_url =~ s/{url}/$scripturl?num=$mnum/gxsm;
            $bm_url =~ s/{title}/$bm_subject/gxsm;
            $show_bookmarks .=
qq~<a href="$bm_url" rel="nofollow" target="_blank"><img src="$yyhtml_root/Bookmarks/$bm_image" alt="$bm_title" title="$bm_title" /></a>\n~;
        }
        $bookmarks = $my_bookmarks;
        $bookmarks =~  s/{yabb bookmarks}/$show_bookmarks/sm;
    }

    # Social Bookmarks End

    # Mark as read button has no use in global announcements or for guests
    if ( $currentboard ne $annboard && !$iamguest ) {
        $mark_unread =
qq~$menusep<a href="$scripturl?action=markunread;thread=$viewnum;board=$currentboard">$img{'markunread'}</a>~;
    }

    # Template it

    $yynavback =
qq~$tabsep <a href="$scripturl">&#171; $img_txt{'103'}</a> $tabsep $navback $tabsep~;

    $boardtree   = q{};
    $parentboard = $currentboard;
    while ($parentboard) {
        my ( $pboardname, undef, undef ) = split /\|/xsm,
          $board{"$parentboard"};
        ToChars($pboardname);
        if ( ${ $uid . $parentboard }{'canpost'} || !$subboard{$parentboard} ) {
            $pboardname =
qq~<a href="$scripturl?board=$parentboard" class="a"><b>$pboardname</b></a>~;
        }
        else {
            $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard;subboards=1" class="a"><b>$pboardname</b></a>~;
        }
        $boardtree   = qq~ &rsaquo; $pboardname$boardtree~;
        $parentboard = ${ $uid . $parentboard }{'parent'};
    }

    $yynavigation = qq~&rsaquo; $template_cat$boardtree &rsaquo; $msubthread~;

    # Create link to modify displayed post order if allowed
    my $curthreadurl =
      ( !$iamguest && $ttsureverse )
      ? qq~<a title="$display_txt{'reverse'}" href="$scripturl?num=$viewnum;start=~
      . ( !$ttsreverse ? $mreplies : 0 )
      . q~;action=~
      . ( $userthreadpage == 1 ? 'threadpagetext' : 'threadpagedrop' )
      . qq~;reversetopic=$ttsreverse"><img src="$imagesdir/~
      . ( $ttsreverse ? "$disp_arrow_up" : "$disp_arrow_dn" )
      . qq~" alt="" /> $msubthread</a>~
      : $msubthread;

    $tool_sep = $useThreadtools ? '|||' : q{};

    $threadhandellist =~ s/{yabb markunread}/$mark_unread$tool_sep/gsm;
    $threadhandellist =~ s/{yabb reply}/$replybutton$tool_sep/gsm;
    $threadhandellist =~ s/{yabb poll}/$pollbutton$tool_sep/gsm;
    $threadhandellist =~ s/{yabb notify}/$notify$tool_sep/gsm;
    $threadhandellist =~
      s/{yabb favorite}/$template_favorite$tool_sep/gsm;
    $threadhandellist =~
      s/{yabb sendtopic}/$template_sendtopic$tool_sep/gsm;
    $threadhandellist =~ s/{yabb print}/$template_print$tool_sep/gsm;
    $threadhandellist =~ s/\Q$menusep//ixsm;

    $threadhandellist2 =~ s/{yabb markunread}/$mark_unread$tool_sep/gsm;
    $threadhandellist2 =~ s/{yabb reply}/$replybutton$tool_sep/gsm;
    $threadhandellist2 =~ s/{yabb poll}/$pollbutton$tool_sep/gsm;
    $threadhandellist2 =~ s/{yabb notify2}/$notify2$tool_sep/gsm;
    $threadhandellist2 =~
      s/{yabb favorite2}/$template_favorite2$tool_sep/gsm;
    $threadhandellist2 =~
      s/{yabb sendtopic}/$template_sendtopic$tool_sep/gsm;
    $threadhandellist2 =~ s/{yabb print}/$template_print$tool_sep/gsm;
    $threadhandellist2 =~ s/\Q$menusep//ixsm;

    @threadin = ( "$mark_unread","$replybutton","$pollbutton","$notify","$template_favorite","$template_sendtopic","$template_print",);
    @threadout = ();
    my $sepcn = 0;
    for (@threadin) {
        if ($_ ) {
           if ( !$useThreadtools ) { $threadout[$sepcn] = "$_$menusep";}
           else  { $threadout[$sepcn] = "$menusep$_"; }
        }
        else  { $threadout[$sepcn] = q{}; }
        $sepcn++;
    }

    $outside_threadtools =~ s/{yabb markunread}/$threadout[0]/gsm;
    $outside_threadtools =~ s/{yabb reply}/$threadout[1]/gsm;
    $outside_threadtools =~ s/{yabb poll}/$threadout[2]/gsm;
    $outside_threadtools =~ s/{yabb notify}/$threadout[3]/gsm;
    $outside_threadtools =~ s/{yabb favorite}/$threadout[4]/gsm;
    $outside_threadtools =~ s/{yabb sendtopic}/$threadout[5]/gsm;
    $outside_threadtools =~ s/{yabb print}/$threadout[6]/gsm;
    if ( $menusep ne q{ } ) {
        $outside_threadtools =~ s/\Q$menusep//ixsm;
    }

    if ( !$useThreadtools ) {
        $threadhandellist    = $outside_threadtools . $threadhandellist;
        $threadhandellist2   = $outside_threadtools . $threadhandellist2;
        $outside_threadtools = q{};
    }
    else {
        $outside_threadtools =~
          s/\[tool=(.+?)\](.+?)\[\/tool\]/$tmpimg{$1}/gxsm;
        $threadhandellist  =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gxsm;
        $threadhandellist2 =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
    }

    # Thread Tools #
    if ($useThreadtools) {
        $threadhandellist2 =
          MakeTools( 'bottom', $maintxt{'62'}, $threadhandellist2 );
        $threadhandellist =
          MakeTools( 'top', $maintxt{'62'}, $threadhandellist );
    }

    $adminhandellist =~ s/{yabb remove}/$template_remove/gsm;
    $adminhandellist =~ s/{yabb splice}/$template_splice/gsm;
    $adminhandellist =~ s/{yabb lock}/$template_lock/gsm;
    $adminhandellist =~ s/{yabb hide}/$template_hide/gsm;
    $adminhandellist =~ s/{yabb sticky}/$template_sticky/gsm;
    $adminhandellist =~ s/{yabb multidelete}/$template_multidelete/gsm;
    $adminhandellist =~ s/\Q$menusep//ixsm;

    $display_template =~ s/{yabb guestview}/$guest_view_limit_warn/gsm;
    $display_template =~ s/{yabb home}/$template_home/gsm;
    $display_template =~ s/{yabb category}/$template_cat/gsm;
    $display_template =~ s/{yabb board}/$template_board/gsm;
    $display_template =~ s/{yabb moderators}/$template_mods/gsm;
    $display_template =~ s/{yabb topicviewers}/$topic_viewers/gsm;
    $display_template =~ s/{yabb prev}/$prevlink/gsm;
    $display_template =~ s/{yabb next}/$nextlink/gsm;
    $display_template =~ s/{yabb pageindex top}/$pageindex1/gsm;
    $display_template =~ s/{yabb pageindex bottom}/$pageindex2/gsm;
    $display_template =~
      s/{yabb bookmarks}/$bookmarks/gsm;    # Social Bookmarks

    $display_template =~
      s/{yabb outsidethreadtools}/$outside_threadtools/gsm;
    $display_template =~
      s/{yabb threadhandellist}/$threadhandellist/gsm;
    $display_template =~
      s/{yabb threadhandellist2}/$threadhandellist2/gsm;
    $display_template =~
      s/{yabb threadhandellist1}/$threadhandellist1/gsm;
    $display_template =~ s/{yabb threadimage}/$template_threadimage/gsm;
    $display_template =~ s/{yabb threadurl}/$curthreadurl/gsm;
    $tmpviews = ${$viewnum}{'views'} - 1;
    $tmpviews = NumberFormat($tmpviews);
    $display_template =~ s/{yabb views}/ $tmpviews /egsm;

    if ( ($staff)
        && $sessionvalid == 1 )
    {

        # Board=$currentboard is necessary for multidel - DO NOT REMOVE!!
        # This form is necessary to allow thread deletion in locked topics.
        $formstart = qq~
    <form name="removethread" action="$scripturl?action=removethread" method="post" style="display: inline">
        <input type="hidden" name="thread" value="$viewnum" />
        </form>~;
    }
    $formstart .=
qq~<form name="multidel" action="$scripturl?board=$currentboard;action=multidel;thread=$viewnum/~
      . ( !$ttsreverse ? $start : $mreplies - $start )
      . q~" method="post" style="display: inline">~;
    $formend = q~</form>~;

    $display_template =~ s/{yabb multistart}/$formstart/gsm;
    $display_template =~ s/{yabb multiend}/$formend/gsm;

    $display_template =~ s/{yabb pollmain}/$template_pollmain/gsm;
    $display_template =~ s/{yabb postsblock}/$tmpoutblock/gsm;
    $display_template =~ s/{yabb adminhandellist}/$adminhandellist/gsm;
    $display_template =~ s/{yabb forumselect}/$selecthtml/gsm;

    $yymain .= qq~
    $display_template
    <script type="text/javascript">
    function uncheckAllBut(counter) {
        for (var i = 0; i < document.forms["multidel"].length; ++i) {
            if (document.forms["multidel"].elements[i].type == "checkbox") document.forms["multidel"].elements[i].checked = false;
        }
        document.forms["multidel"].elements["del"+counter].checked = true;
        document.multidel.submit();
    }~;

    if ($sendtopicmail) {
        my ( $esubject, $emessage );
        if ( $sendtopicmail > 1 ) {
            LoadLanguage('SendTopic');
            LoadLanguage('Email');
            require Sources::Mailer;
            $esubject = uri_escape(
"$sendtopic_txt{'118'}: $msubthread ($sendtopic_txt{'318'} ${$uid.$username}{'realname'})"
            );
            $emessage = uri_escape(
                template_email(
                    $sendtopicemail,
                    {
                        'toname'      => '?????',
                        'subject'     => $msubthread,
                        'displayname' => ${ $uid . $username }{'realname'},
                        'num'         => $viewnum
                    }
                )
            );
        }
        $yymain .= qq~

    function sendtopicmail(action) {
        var x = "mailto:?subject=$esubject&body=$emessage";
        if (action == 3) {
            Check = confirm('$display_txt{'sendtopicemail'}');
            if (Check !== true) x = '';
        }
        if (action == 1 || x === '') x = "$scripturl?action=sendtopic;topic=$viewnum";
        window.location.href = x;
    }~;
    }

    $yymain .= qq~
    $pageindexjs
    function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
    </script>
    ~;

## gb_css spot

    $yytitle = $msubthread;
    if ( $replybutton and $enable_quickreply ) {
        $yymain =~
s/(<!-- Threads Admin Button Bar start -->.*?<\/td>)/$1<td class="right">{yabb forumjump}<\/td>/sm;
        require Sources::Post;
        $action        = 'post';
        $INFO{'title'} = 'PostReply';
        $Quick_Post    = 1;
        $message       = q{};
        Post();
    }
    template();
    return;
}

sub NextPrev {
    my ( $name, $lastvisit ) = @_;
    fopen( MSGTXT, "$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    my @threadlist = <MSGTXT>;
    fclose(MSGTXT);

    $thevirboard = q~num=~;
    if ($vircurrentboard) {
        fopen( MSGTXT, "$boardsdir/$vircurrentboard.txt" )
          or fatal_error( 'cannot_open', "$boardsdir/$vircurrentboard.txt", 1 );
        my @virthreadlist = <MSGTXT>;
        fclose(MSGTXT);
        push @threadlist, @virthreadlist;
        undef @virthreadlist;
        $thevirboard = qq~virboard=$vircurrentboard;num=~;
    }

    my ( $countsticky, $countnosticky ) = ( 0, 0 );
    my ( @stickythreadlist, @nostickythreadlist );
    for my $i ( 0 .. ( @threadlist - 1 ) ) {
        my $threadstatus = ( split /\|/xsm, $threadlist[$i] )[8];
        if ( $threadstatus =~ /h/ism
            && !$staff )
        {
            next;
        }
        if ( $threadstatus =~ /s/ism || $threadstatus =~ /a/ism ) {
            $stickythreadlist[$countsticky] = $threadlist[$i];
            $countsticky++;
        }
        else {
            $nostickythreadlist[$countnosticky] = $threadlist[$i];
            $countnosticky++;
        }
    }

    @threadlist = ();
    if ($countsticky)   { push @threadlist, @stickythreadlist; }
    if ($countnosticky) { push @threadlist, @nostickythreadlist; }

    my $is = 0;
    my ( $mnum, $mdate, $datecount );
    for my $i ( 0 .. ( @threadlist - 1 ) ) {
        ( $mnum, undef, undef, undef, $mdate, undef ) =
          split /\|/xsm, $threadlist[$i], 6;
        if ( $mnum == $name ) {
            if ( $i > 0 ) {
                ( $prev, undef ) = split /\|/xsm, $threadlist[ $i - 1 ], 2;
                $prevlink =
qq~<a href="$scripturl?$thevirboard$prev">$display_txt{'768'}</a>~;
            }
            else {
                $prevlink = $display_txt{'766'};
            }
            if ( $i < $#threadlist ) {
                ( $next, undef ) = split /\|/xsm, $threadlist[ $i + 1 ], 2;
                $nextlink =
qq~<a href="$scripturl?$thevirboard$next">$display_txt{'767'}</a>~;
            }
            else {
                $nextlink = $display_txt{'766'};
            }
            $is = 1;
        }
        if ( $mdate > $lastvisit ) { $datecount++; }
        last if $is && $datecount > 1;
    }

    if ( !$is ) { undef $INFO{'num'}; redirectinternal(); } # if topic not found
    return $datecount;
}

sub SetGtalk {
    my $gtalkname = $INFO{'gtalkname'};
    my $gtalkstyle = qq~<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />\n~;
    if ( !${ $uid . $gtalkname }{'password'} ) { LoadUser($gtalkname); }
    $gtalkuser = ${ $uid . $gtalkname }{'gtalk'};

    print qq~Content-type: text/html\n\n~
      or croak "$croak{'print'} page content";
    $setgtalk = $gtalk;
    $setgtalk =~ s/{yabb xml_lang}/$abbr_lang/sm;
    $setgtalk =~ s/{yabb mycharset}/$yymycharset/sm;
    $setgtalk =~ s/{yabb style}/$gtalkstyle/sm;
    $setgtalk =~ s/{yabb gname}/${ $uid . $gtalkname }{'realname'}/gsm;
    $setgtalk =~ s/{yabb gtalkuser}/$gtalkuser/gsm;

    print $setgtalk or croak "$croak{'print'} page";
    return;
}

sub ThreadPageindex {

    my ( $msindx, $trindx, $mbindx, $pmindx ) =
      split /\|/xsm, ${ $uid . $username }{'pageindex'};
    if ( $INFO{'action'} eq 'threadpagedrop' ) {
        ${ $uid . $username }{'pageindex'} = qq~$msindx|0|$mbindx|$pmindx~;
    }
    if ( $INFO{'action'} eq 'threadpagetext' ) {
        ${ $uid . $username }{'pageindex'} = qq~$msindx|1|$mbindx|$pmindx~;
    }
    if ( exists $INFO{'reversetopic'} ) {
        ${ $uid . $username }{'reversetopic'} = $INFO{'reversetopic'} ? 0 : 1;
    }
    UserAccount( $username, 'update' );
    $yySetLocation = qq~$scripturl?num=$INFO{'num'}/$INFO{'start'}~;
    redirectexit();
    return;
}

sub undumplog {    # Used to mark a thread as unread
                   # Load the log file
    getlog();

    if ( $yyuserlog{ $INFO{'thread'} } ) { dumplog("$INFO{'thread'}--unread"); }

    redirectinternal();
    return;
}

1;
