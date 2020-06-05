###############################################################################
# Poll.pm                                                                     #
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

$pollpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ($action eq 'detailedversion') { return 1; }

LoadLanguage('Poll');
get_micon();
get_template('Poll');

sub DoVote {
    $pollnum = $INFO{'num'};
    $start   = $INFO{'start'};
    if ( !-e "$datadir/$pollnum.poll" ) {
        fatal_error( 'poll_not_found', $pollnum );
    }

    $novote = 0;
    $vote   = q{};
    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_question = <FILE>;
    @poll_data     = <FILE>;
    fclose(FILE);
    chomp $poll_question;
    (
        undef, $poll_locked, undef,       undef,       undef,
        undef, $guest_vote,  undef,       $multi_vote, undef,
        undef, undef,        $vote_limit, undef
    ) = split /\|/xsm, $poll_question, 14;

    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        chomp $poll_data[$i];
        ( $votes[$i], $options[$i], $slicecols[$i], $split[$i] ) =
          split /\|/xsm, $poll_data[$i];
        $tmp_vote = qq~$FORM{"option$i"}~;
        if ( $multi_vote && $tmp_vote ne q{} ) {
            $votes[$i]++;
            $novote = 1;
            if ( $vote ne q{} ) { $vote .= q{,}; }
            $vote .= $tmp_vote;
        }
    }
    $tmp_vote = $FORM{'option'};
    if ( !$multi_vote && $tmp_vote ne q{} ) {
        $vote = $tmp_vote;
        $votes[$tmp_vote]++;
        $novote = 1;
    }

    if ( $novote == 0 || $vote eq q{} ) { fatal_error('no_vote_option'); }
    if ( $iamguest && !$guest_vote ) { fatal_error('members_only'); }
    if ($poll_locked) { fatal_error('locked_poll_no_count'); }

    fopen(FILE, "$datadir/$pollnum.polled");
    @polled = <FILE>;
    fclose(FILE);

    for my $i ( 0 .. ( @polled - 1 ) ) {
        ( $voters_ip, $voters_name, $voters_vote, $vote_time ) = split /\|/xsm,
          $polled[$i];
        chomp $voters_vote;
        if (   $iamguest
            && $voters_name  eq 'Guest'
            && lc $voters_ip eq lc $user_ip )
        {
            fatal_error('ip_guest_used');
        }
        elsif ($iamguest
            && $voters_name ne 'Guest'
            && lc $voters_ip eq lc $user_ip )
        {
            fatal_error('ip_member_used');
        }
        elsif ( !$iamguest
            && $voters_name ne 'Guest'
            && lc $username eq lc $voters_name )
        {
            fatal_error('voted_already');
        }
        elsif ( !$iamguest
            && $voters_name  eq 'Guest'
            && lc $voters_ip eq lc $user_ip )
        {
            foreach my $oldvote ( split /\,/xsm, $voters_vote ) {
                $votes[$oldvote]--;
            }
            $polled[$i] = q{};
            last;
        }
    }

    fopen(FILE, ">$datadir/$pollnum.poll");
    print {FILE} "$poll_question\n" or croak "$croak{'print'} POLL FILE";
    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        print {FILE} "$votes[$i]|$options[$i]|$slicecols[$i]|$split[$i]\n"
          or croak "$croak{'print'} POLL FILE";
    }
    fclose(FILE);

    fopen(FILE, ">$datadir/$pollnum.polled");
    print {FILE} "$user_ip|$username|$vote|$date\n"
      or croak "$croak{'print'} POLL FILE";
    print {FILE} @polled or croak "$croak{'print'} POLL FILE";
    fclose(FILE);

    if ($start) { $start = "/$start"; }
    if ($INFO{'scp'}) {
        $yySetLocation = qq~$scripturl~;
    }
    else {
        $yySetLocation = qq~$scripturl?num=$pollnum$start~;
    }
    redirectexit();
    return;
}

sub UndoVote {
    $pollnum = $INFO{'num'};
    if ( !-e "$datadir/$pollnum.poll" ) {
        fatal_error( 'poll_not_found', $pollnum );
    }

    check_deletepoll();
    if ( !$iamadmin && $poll_nodelete{$username} ) { fatal_error('no_access'); }

    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_question = <FILE>;
    @poll_data     = <FILE>;
    fclose(FILE);
    $poll_locked = ( split /\|/xsm, $poll_question, 2 )[1];
    my @options;
    my @votes;

    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        chomp $poll_data[$i];
        ( $votes[$i], $options[$i], $slicecols[$i], $split[$i] ) =
          split /\|/xsm, $poll_data[$i];
    }

    fopen(FILE, "$datadir/$pollnum.polled");
    @polled = <FILE>;
    fclose(FILE);

    if ( $FORM{'multidel'} == 1 ) {
        is_admin();
        for my $i ( 0 .. ( @polled - 1 ) ) {
            ( $voters_ip, $voters_name, $voters_vote, $vote_date ) =
              split /\|/xsm, $polled[$i];
            chomp $voters_vote;
            $id = $FORM{"$voters_ip-$voters_name"};
            if ( $id == 1 ) {
                foreach my $oldvote ( split /\,/xsm, $voters_vote ) {
                    $votes[$oldvote]--;
                }
                $polled[$i] = q{};
            }
            }
        }
     else {
        if ($iamguest)  { fatal_error('not_allowed'); }
        if ($poll_lock) { fatal_error('locked_poll_no_delete'); }
        $found = 0;
        for my $i ( 0 .. ( @polled - 1 ) ) {
            ( $voters_ip, $voters_name, $voters_vote, $vote_date ) =
              split /\|/xsm, $polled[$i];
            chomp $voters_vote;
            if ($voters_name eq $username) {
                $found = 1;
                for my $oldvote ( split /\,/xsm, $voters_vote ) {
                    $votes[$oldvote]--;
                }
                $polled[$i] = q{};
                last;
            }
        }
        if ( !$found ) { fatal_error('not_completed'); }
    }

    fopen(FILE, ">$datadir/$pollnum.poll");
    print {FILE} $poll_question or croak "$croak{'print'} POLL FILE";
    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        print {FILE} "$votes[$i]|$options[$i]|$slicecols[$i]|$split[$i]\n"
          or croak "$croak{'print'} POLL FILE";
    }
    fclose(FILE);

    fopen(FILE, ">$datadir/$pollnum.polled");
    print {FILE} @polled or croak "$croak{'print'} POLL FILE";
    fclose(FILE);

    if ($start) { $start = "/$start"; }
    if ($INFO{'scp'}) {
        $yySetLocation = qq~$scripturl~;
    }
    else {
        $yySetLocation = qq~$scripturl?num=$pollnum$start~;
    }
    redirectexit();
    return;
}

sub LockPoll {
    $pollnum = $INFO{'num'};
    if ( !-e "$datadir/$pollnum.poll" ) {
        fatal_error( 'poll_not_found', $pollnum );
    }

    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_question = <FILE>;
    @poll_data     = <FILE>;
    fclose(FILE);
    chomp $poll_question;
    ( $poll_question, $poll_locked, $poll_uname, $poll_stuff ) = split /\|/xsm,
      $poll_question, 4;
    if ( $username ne $poll_uname && !$staff ) { fatal_error('not_allowed'); }

    if ($poll_locked) { $poll_locked = 0; }
    else { $poll_locked = 1; }

    fopen(FILE, ">$datadir/$pollnum.poll");
    print {FILE} "$poll_question|$poll_locked|$poll_uname|$poll_stuff\n"
      or croak "$croak{'print'} POLL FILE";
    print {FILE} @poll_data or croak "$croak{'print'} POLL FILE";
    fclose(FILE);

    if ($start) { $start = "/$start"; }
    if ($INFO{'scp'}){
        $yySetLocation = qq~$scripturl~;
    }
    else {
        $yySetLocation = qq~$scripturl?num=$pollnum$start~;
    }
    redirectexit();
    return;
}

sub votedetails {
    is_admin();

    $pollnum = $INFO{'num'};
    if ( !-e "$datadir/$pollnum.poll" ) {
        fatal_error( 'poll_not_found', $pollnum );
    }
    if ($start) { $start = "/$start"; }

    LoadCensorList();

    # Figure out the name of the category
    get_forum_master();
    ( $curcat, $catperms ) = split /\|/xsm, $catinfo{"$cat"};

    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_question = <FILE>;
    @poll_data     = <FILE>;
    fclose(FILE);
    chomp $poll_question;
    (
        $poll_question, $poll_locked, $poll_uname, $poll_name,
        $poll_email, $poll_date, $guest_vote, $hide_results,
        $multi_vote, $poll_mod, $poll_modname, $poll_comment,
        undef
    ) = split /\|/xsm, $poll_question, 13;

    if ( !ref $thread_arrayref{$pollnum} ) {
        fopen(POLLTP, "$datadir/$pollnum.txt");
        @{$thread_arrayref{$pollnum}} = <POLLTP>;
        fclose(POLLTP);
    }
    $psub = ( split /\|/xsm, ${ $thread_arrayref{$pollnum} }[0], 2 )[0];
    ToChars($psub);

    # Censor the options.
    $poll_question = Censor($poll_question);
    if ($ubbcpolls) {
        enable_yabbc();
        $message = $poll_question;
        DoUBBC();
        $poll_question = $message;
    }
    ToChars($poll_question);

    my @options;
    my @votes;
    my $totalvotes = 0;
    my $maxvote    = 0;
    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        chomp $poll_data[$i];
        ( $votes[$i], $options[$i] ) = split /\|/xsm, $poll_data[$i];
        $totalvotes += int $votes[$i];
        if ( int( $votes[$i] ) >= $maxvote ) { $maxvote = int $votes[$i]; }
        $options[$i] = Censor( $options[$i] );
        if ($ubbcpolls) {
            $message = $options[$i];
            DoUBBC();
            $options[$i] = $message;
        }
        ToChars( $options[$i] );
    }

    fopen(FILE, "$datadir/$pollnum.polled");
    @polled = <FILE>;
    fclose(FILE);

    if ( $poll_modname ne q{} && $poll_mod ne q{} ) {
        $poll_mod = timeformat($poll_mod);
        LoadUser($poll_modname);
        if ( $iamguest ) {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45a'}: $format_unbold{$poll_modname} $polltxt{'46'}: $poll_mod &#187;</span>~;
        }
        else {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45a'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_modname}">$format_unbold{$poll_modname}</a> $polltxt{'46'}: $poll_mod &#187;</span>~;
        }
    }
    if ( $poll_uname ne q{} && $poll_date ne q{} ) {
        $poll_date = timeformat($poll_date);
        if ($poll_uname ne 'Guest' && -e "$memberdir/$poll_uname.vars") {
            LoadUser($poll_uname);
            if ( $iamguest ) {
                $displaydate =
qq~<span class="small">&#171; $polltxt{'45a'}: $format_unbold{$poll_uname} $polltxt{'46'}: $poll_mod &#187;</span>~;
            }
            else {
                $displaydate =
qq~<span class="small">&#171; $polltxt{'45'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_uname}">$format_unbold{$poll_uname}</a> $polltxt{'46'}: $poll_date &#187;</span>~;
            }
        }
        else {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45'}: $poll_name $polltxt{'46'}: $poll_date &#187;</span>~;
        }
    }
    ToChars($boardname);
    $yytitle = $polltxt{'42'};

    $template_home = qq~<a href="$scripturl" class="nav">$mbname</a>~;
    $template_cat =
      qq~<a href="$scripturl?catselect=$curcat" class="nav">$cat</a>~;
    $template_board =
      qq~<a href="$scripturl?board=$currentboard" class="nav">$boardname</a>~;
    $curthreadurl =
qq~<a href="$scripturl?num=$pollnum" class="nav">$psub</a> &rsaquo; $polltxt{'42'}~;

    $yynavigation =
qq~&rsaquo; $template_cat &rsaquo; $template_board &rsaquo; $curthreadurl~;

    foreach my $entry (@polled) {
        chomp $entry;
        $voted = q{};
        ( $voters_ip, $voters_name, $voters_vote, $vote_date ) = split /\|/xsm,
          $entry;
        $id = qq~$voters_ip-$voters_name~;
        if ($voters_name ne 'Guest' && -e "$memberdir/$voters_name.vars") {
            LoadUser($voters_name);
            if ( $iamguest ) {
                $voters_name = qq~$format_unbold{$voters_name}~;
            }
            else {
                $voters_name =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$voters_name}">$format_unbold{$voters_name}</a>~;
            }
        }
        foreach my $oldvote ( split /\,/xsm, $voters_vote ) {
            if ($ubbcpolls) {
                $message = $options[$oldvote];
                DoUBBC();
                $options[$oldvote] = $message;
            }
            ToChars( $options[$oldvote] );
            $voted .= qq~$options[$oldvote]<br />~;
        }

        my $lookupIP =
          ($ipLookup)
          ? qq~<a href="$scripturl?action=iplookup;ip=$voters_ip">$voters_ip</a>~
          : qq~$voters_ip~;
        $vote_date = timeformat($vote_date);
        $my_IP .= $mypoll_IP;
        $my_IP =~ s/{yabb id}/$id/sm;
        $my_IP =~ s/{yabb voters_name}/$voters_name/sm;
        $my_IP =~ s/{yabb lookupIP}/$lookupIP/sm;
        $my_IP =~ s/{yabb vote_date}/$vote_date/sm;
        $my_IP =~ s/{yabb voted}/$voted/sm;
    }

    $yymain .= $mypoll_details;
    $yymain =~ s/{yabb pollnum}/$pollnum/sm;
    $yymain =~ s/{yabb start}/$start/sm;
    $yymain =~ s/{yabb poll_question}/$poll_question/sm;
    $yymain =~ s/{yabb my_IP}/$my_IP/sm;

    $display_template =~ s/{yabb home}/$template_home/gsm;
    $display_template =~ s/{yabb category}/$template_cat/gsm;
    $display_template =~ s/{yabb board}/$template_board/gsm;
    $display_template =~ s/{yabb threadurl}/$curthreadurl/gsm;

    template();
    return;
}

sub display_poll {
    ( $pollnum, $brdpoll ) = @_;

    # showcase poll start
    $scp        = q{};
    $viewthread = q{};
    $boardpoll  = q{};
    if ($brdpoll) {
        $scp = q~;scp=1~;
        $viewthread =
qq~<a href="$scripturl?num=$pollnum" class="altlink">$img{'viewthread'}</a>~;
        if ( $iamadmin || $iamgmod ) {
            $boardpoll =
qq~&nbsp;/ <a href="$scripturl?action=scpolldel" class="altlink">$polltxt{'showcaserem'}</a>~;
        }
    }
    elsif ( -e "$datadir/showcase.poll" ) {
        fopen (FILE, "$datadir/showcase.poll");
        if ( $pollnum == <FILE> ) {
            $boardpoll = qq~&nbsp;/ $polltxt{'showcased'}~;
        }
        fclose (FILE);
        if ($iamadmin || $iamgmod) {
            $boardpoll =
              $boardpoll
              ? qq~&nbsp;/ <a href="$scripturl?action=scpolldel" class="altlink">$polltxt{'showcaserem'}</a>~
              : qq~&nbsp;/ <a href="javascript:Check=confirm('$polltxt{'confirm'}');if(Check==true){window.location.href='$scripturl?action=scpoll;num=$pollnum';}else{void Check;}" class="altlink">$polltxt{'setshowcased'}</a>~;
        }
    }
    else {
        if ( $iamadmin || $iamgmod ) {
            $boardpoll =
qq~&nbsp;/ <a href="$scripturl?action=scpoll;num=$pollnum" class="altlink">$polltxt{'setshowcased'}</a>~;
        }
    }

    # showcase poll end

    LoadCensorList();

    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_question = <FILE>;
    @poll_data = <FILE>;
    fclose(FILE);
    chomp $poll_question;
    (
        $poll_question, $poll_locked, $poll_uname,   $poll_name,
        $poll_email,    $poll_date,   $guest_vote,   $hide_results,
        $multi_vote,    $poll_mod,    $poll_modname, $poll_comment,
        $vote_limit,    $pie_radius,  $pie_legends,  $poll_end
    ) = split /\|/xsm, $poll_question;

    if ($poll_end && !$poll_locked && $poll_end < $date) {
        $poll_locked = 1;
        $poll_end    = q{};
        fopen(FILE, ">$datadir/$pollnum.poll");
        print {FILE}
"$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_vote|$poll_mod|$poll_modname|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n"
          or croak "$croak{'print'} POLL FILE";
        print {FILE} @poll_data or croak "$croak{'print'} POLL FILE";
        fclose(FILE);
    }

    $pie_radius ||= 100;
    $pie_legends ||= 0;

    $users_votetext = q{};
    $has_voted = 0;
    if (!$guest_vote && $iamguest) { $has_voted = 4; }
    else {
        fopen(FILE, "$datadir/$pollnum.polled");
        @polled = <FILE>;
        fclose(FILE);
        foreach my $tmpLine (@polled) {
            chomp $tmpline;
            ( $voters_ip, $voters_name, $voters_vote, $vote_date ) =
              split /\|/xsm, $tmpLine;
            if (   $iamguest
                && $voters_name  eq 'Guest'
                && lc $voters_ip eq lc $user_ip )
            {
                $has_voted = 1;
                last;
            }
            elsif ($iamguest
                && $voters_name ne 'Guest'
                && lc $voters_ip eq lc $user_ip )
            {
                $has_voted = 2;
                last;
            }
            elsif (!$iamguest && lc $username eq lc $voters_name) {
                $has_voted = 3;
                $users_votedate = timeformat($vote_date);
                @users_vote     = split /\,/xsm, $voters_vote;
                my $users_votecount = @users_vote;
                if ($users_votecount == 1) {
                    $users_votetext =
qq~<br /><span style="font-weight: bold;">$polltxt{'64'}:</span> $users_votedate<br /><span style="font-weight: bold;">$polltxt{'65'}:</span> ~;
                }
                else {
                    $users_votetext =
qq~<br /><span style="font-weight: bold;">$polltxt{'64'}:</span> $users_votedate<br /><span style="font-weight: bold;">$polltxt{'66'}:</span> ~;
                }
                last;
            }
        }
    }

    my @options;
    my @votes;
    my $totalvotes = 0;
    my $maxvote    = 0;
    $piearray = q~[~;
    for my $i ( 0 .. ( @poll_data - 1 ) ) {
        chomp $poll_data[$i];
        ( $votes[$i], $options[$i], $slicecolor[$i], $split[$i] ) =
          split /\|/xsm, $poll_data[$i];

        # Censor the options.
        $options[$i] = Censor( $options[$i] );
        $options[$i] =~ s/[\n\r]//gxsm;
        if ($ubbcpolls) {
            enable_yabbc();
            $message = $options[$i];
            DoUBBC();
            $options[$i] = $message;
        }
        ToChars( $options[$i] );
        $piearray .= qq~"$votes[$i]|$options[$i]|$slicecolor[$i]|$split[$i]", ~;
        $totalvotes += int $votes[$i];
        if ( int( $votes[$i] ) >= $maxvote ) { $maxvote = int $votes[$i]; }
    }
    $piearray =~ s/\, $//ism;
    $piearray .= q~]~;

    my ($endedtext, $displayvoters);
    if ( !$iamguest
        && ( $username eq $poll_uname || $staff ) )
    {
        if ($poll_locked) {
            $lockpoll =
qq~<a href="$scripturl?action=lockpoll;num=$pollnum$scp" class="altlink">$img{'openpoll'}</a>~;
        }
        else {
            $lockpoll =
qq~<a href="$scripturl?action=lockpoll;num=$pollnum$scp" class="altlink">$img{'closepoll'}</a>~;
        }
        $modifypoll =
qq~$menusep<a href="$scripturl?board=$currentboard;action=modify;message=Poll;thread=$pollnum" class="altlink">$img{'modifypoll'}</a>~;
        $deletepoll =
qq~$menusep<a href="javascript:document.removepoll.submit();" class="altlink" onclick="return confirm('$polltxt{'44'}')">$img{'deletepoll'}</a>~;
        if ($iamadmin) {
            if ($viewthread) { $displayvoters = $menusep; }
            $displayvoters .=
qq~<a href="$scripturl?action=showvoters;num=$pollnum">$img{'viewvotes'}</a>~;
        }
        if ($hide_results) {
            $endedtext    = $mypoll_ended;
            $hide_results = 0;
        }
    }

    if ( $poll_modname ne q{} && $poll_mod ne q{} && $showmodify ) {
        $poll_mod = timeformat($poll_mod);
        LoadUser($poll_modname);
        if ( $iamguest ) {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45a'}: $format_unbold{$poll_modname} $polltxt{'46'}: $poll_mod &#187;</span>~;
        }
        else {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45a'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_modname}">$format_unbold{$poll_modname}</a> $polltxt{'46'}: $poll_mod &#187;</span>~;
        }
    }
    elsif ( $poll_uname ne q{} && $poll_date ne q{} ) {
        $poll_date = timeformat($poll_date);
        if ($poll_uname ne 'Guest' && -e "$memberdir/$poll_uname.vars") {
            LoadUser($poll_uname);
            if ( $iamguest ) {
                $displaydate =
qq~<span class="small">&#171; $polltxt{'45'}: $format_unbold{$poll_uname} $polltxt{'46'}: $poll_date &#187;</span>~;
            }
            else {
                $displaydate =
qq~<span class="small">&#171; $polltxt{'45'}: <a href="$scripturl?action=viewprofile;username=$useraccount{$poll_uname}">$format_unbold{$poll_uname}</a> $polltxt{'46'}: $poll_date &#187;</span>~;
            }
        }
        elsif ( $poll_name ne q{} ) {
            $displaydate =
qq~<span class="small">&#171; $polltxt{'45'}: $poll_name $polltxt{'46'}: $poll_date &#187;</span>~;
        }
        else {
            $displaydate = q{};
        }
    }
    else {
        $displaydate = q{};
    }

    if ($poll_locked) {
        $endedtext = $mypoll_locked;
        $poll_icon = $img{'polliconclosed'};
        $has_voted = 5;
    }
    else {
        $poll_icon = $img{'pollicon'};
    }

    # Censor the question.
    $poll_question = Censor($poll_question);
    if ($ubbcpolls) {
        enable_yabbc();
        my $message = $poll_question;
        DoUBBC();
        $poll_question = $message;
    }
    ToChars($poll_question);

    $deletevote = q{};
    if ($has_voted) {
        if ($users_votetext) {
            if ( !$yyYaBBCloaded && $ubbcpolls ) {
                require Sources::YaBBC;
            }
            $footer = $users_votetext;
            for my $i ( 0 .. ( @users_vote - 1 ) ) {
                $optnum = $users_vote[$i];

                # Censor the user answer.
                $options[$optnum] = Censor( $options[$optnum] );
                if ($ubbcpolls) {
                    $message = $options[$optnum];
                    DoUBBC();
                    $options[$optnum] = $message;
                }
                ToChars( $options[$optnum] );
                $footer .= qq~$options[$optnum], ~;
            }
        }
        $footer =~ s/, \Z//sm;
        $footer .= qq~<br /><br /><b>$polltxt{'17'}: $totalvotes</b>~;
        $width = q{};
        if ($viewthread) { $deletevote .= $menusep; }
        $deletevote .=
qq~<a href="$scripturl?action=undovote;num=$pollnum$scp">$img{'deletevote'}</a>~;
        if ( !$viewthread && $displayvoters ) { $deletevote .= $menusep; }
    }
    else {
        $footer  =
          qq~<input type="submit" value="$polltxt{'18'}" class="button" />~;
        $width = q~ width="80%"~;
    }
    check_deletepoll();
    if ($iamguest || $poll_locked || $poll_nodelete{$username}) {
        $deletevote = q{};
    }

    if (!$yyUDLoaded{$username}) { LoadUser($username); }
    $scdivdisp = q~block~;
    $poll_coll = q{};
    if(!$INFO{'num'} && !$iamguest) {
        if(${$uid.$username}{'collapsescpoll'} == $pollnum) {
            $poll_coll .= qq~<img src="$imagesdir/$cat_exp" id="scpollcollapse" alt="$boardindex_exptxt{'1'}" title="$boardindex_exptxt{'1'}" class="cursor" onclick="collapseSCpoll('$pollnum');" />~;
            $scdivdisp = q~none~;
        }
        else {
            $poll_coll .= qq~<img src="$imagesdir/$cat_col" id="scpollcollapse" alt="$boardindex_exptxt{'2'}" title="$boardindex_exptxt{'2'}" class="cursor" onclick="collapseSCpoll('$pollnum');" />~;
        }
    }
    $pollmain = $mypoll_display;
    $pollmain =~ s/{yabb pollnum}/$pollnum/gsm;
    $pollmain =~ s/{yabb scp}/$scp/sm;
    $pollmain =~ s/{yabb poll_coll}/$poll_coll/gsm;
    $pollmain =~ s/{yabb scdivdisp}/$scdivdisp/gsm;
    $pollmain =~ s/{yabb poll_icon}/$poll_icon/gsm;
    $pollmain =~ s/{yabb boardpoll}/$boardpoll/gsm;
    $pollmain =~ s/{yabb lockpoll}/$lockpoll/gsm;
    $pollmain =~ s/{yabb modifypoll}/$modifypoll/gsm;
    $pollmain =~ s/{yabb deletepoll}/$deletepoll/gsm;
    $pollmain =~ s/{yabb poll_question}/$poll_question/gsm;

    if($has_voted) {
     if ( !$hide_results || $poll_locked ) {
        $poll_notlocked = qq~
           <div style="float: right; width: 55px; text-align: right; margin-right:4px">
                <a href="$scripturl?num=$viewnum">$poll_bar</a> &nbsp;
                <a href="$scripturl?num=$viewnum;view=pie">$poll_pie</a>
           </div>
    ~;
        }
    }

    if ($has_voted && $hide_results && !$poll_locked) {

        # Display Poll Hidden Message
        $poll_hidden .=
qq~$polltxt{'47'}<br /><span class="small">($polltxt{'48'})</span><br />~;
    }
    else {
        if($has_voted) {
            if ( $INFO{'view'} eq 'pie' ) {
                $poll_hasvoted = qq~
        <script src="$yyhtml_root/piechart.js" type="text/javascript"></script>
        <script type="text/javascript">
            if (document.getElementById('piestyle').currentStyle) {
                pie_colorstyle = document.getElementById('piestyle').currentStyle['color'];
            } else if (window.getComputedStyle) {
                var compStyle = window.getComputedStyle(document.getElementById('piestyle'), "");
                pie_colorstyle = compStyle.getPropertyValue('color');
            }
            else pie_colorstyle = "#000000";

            var pie = new pieChart();
            pie.pie_array = $piearray;
            pie.radius = $pie_radius;
            pie.use_legends = $pie_legends;
            pie.color_style = pie_colorstyle;
            pie.sliceAdd();
        </script>~;
            }
            else {
                for my $i ( 0 .. $#options ) {
                    if ( !$options[$i] ) { next; }

                    # Display Poll Results
                    $pollpercent = 0;
                    $pollbar     = 0;
                    if ($totalvotes > 0 && $maxvote > 0) {
                        $pollpercent = (100 * $votes[$i]) / $totalvotes;
                        $pollpercent = sprintf '%.1f', $pollpercent;
                        $pollbar = int(150 * $votes[$i] / $maxvote);
                    }
                    $poll_hasvoted .= $mypoll_hasvoted;
                    $poll_hasvoted =~ s/{yabb optionsi}/$options[$i]/gsm;
                    $poll_hasvoted =~ s/{yabb pollbar}/$pollbar/gsm;
                    $poll_hasvoted =~ s/{yabb slicecolori}/$slicecolor[$i]/gsm;
                    $poll_hasvoted =~ s/{yabb votesi}/$votes[$i]/gsm;
                    $poll_hasvoted =~ s/{yabb pollpercent}/$pollpercent/gsm;
                }
            }
        }
        else {
            for my $i ( 0 .. ( @options - 1 ) ) {
                if ( !$options[$i] ) { next; }

                # Display Poll Options
                if ($multi_vote) {
                    $input =
qq~<input type="checkbox" name="option$i" id="option$i" value="$i" style="margin: 0; padding: 0; vertical-align: middle;" />~;
                }
                else {
                    $input =
qq~<input type="radio" name="option" id="option$i" value="$i" style="margin: 0; padding: 0; vertical-align: middle;" />~;
                }
                $poll_hasvoted .= qq~
        <div class="clear">
        <div style="float: left; height: 22px; text-align: right;">$input <label for="option$i"><b>$options[$i]</b></label></div>
        </div>~;
            }
        }
    }

    if ($poll_comment ne q{}) {
        $poll_comment = Censor($poll_comment);
        $message = $poll_comment;
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        $poll_comment = $message;
        ToChars($poll_comment);
        $my_pollcomment = qq~
    <div style="width: 100%;"><br />$poll_comment</div>~;
    }
    if (!$poll_locked && $poll_end) {
        my $x = $poll_end - $date;
        my $days  = int( $x / 86400 );
        my $hours = int( ( $x - ( $days * 86400 ) ) / 3600 );
        my $min   = int( ( $x - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 );
        $poll_end = "$post_polltxt{'100'} ";
        if ($days) {
            $poll_end .= "$days $post_polltxt{'100a'}"
              . ( $hours ? q{, } : " $post_polltxt{'100c'} " );
        }
        if ($hours) {
            $poll_end .= "$hours $post_polltxt{'100b'} $post_polltxt{'100c'} ";
        }
        $poll_end .= "$min $post_polltxt{'100d'}<br />";
    }
    else {
        $poll_end = q{};
    }

    $pollmain =~ s/{yabb pollnum}/$pollnum/gsm;
    $pollmain =~ s/{yabb scp}/$scp/sm;
    $pollmain =~ s/{yabb poll_coll}/$poll_coll/gsm;
    $pollmain =~ s/{yabb scdivdisp}/$scdivdisp/gsm;
    $pollmain =~ s/{yabb poll_icon}/$poll_icon/sm;
    $pollmain =~ s/{yabb boardpoll}/$boardpoll/sm;
    $pollmain =~ s/{yabb lockpoll}/$lockpoll/sm;
    $pollmain =~ s/{yabb modifypoll}/$modifypoll/sm;
    $pollmain =~ s/{yabb deletepoll}/$deletepoll/sm;
    $pollmain =~ s/{yabb poll_question}/$poll_question/sm;
    $pollmain =~ s/{yabb poll_notlocked}/$poll_notlocked/gsm;
    $pollmain =~ s/{yabb endedtext}/$endedtext/sm;
    $pollmain =~ s/{yabb pollhidden}/$poll_hidden/sm;
    $pollmain =~ s/{yabb poll_hasvoted}/$poll_hasvoted/sm;
    $pollmain =~ s/{yabb footer}/$footer/sm;
    $pollmain =~ s/{yabb my_pollcomment}/$my_pollcomment/sm;
    $pollmain =~ s/{yabb poll_end}/$poll_end/sm;
    $pollmain =~ s/{yabb displaydate}/$displaydate/sm;
    $pollmain =~ s/{yabb viewthread}/$viewthread/sm;
    $pollmain =~ s/{yabb deletevote}/$deletevote/sm;
    $pollmain =~ s/{yabb displayvoters}/$displayvoters/sm;
    $pollmain .= qq~<script type="text/javascript">
function collapseSCpoll(pollnr) {
    if (document.getElementById("polldiv").style.display == 'none') linkpollnr = '0';
    else linkpollnr = pollnr;
    var doexpand = "$boardindex_exptxt{'1'}";
    var docollaps = "$boardindex_exptxt{'2'}";
    if (document.getElementById("polldiv").style.display == 'none') {
        document.getElementById("polldiv").style.display = 'block';
        document.getElementById('scpollcollapse').src = "$imagesdir/$cat_col";
        document.getElementById('scpollcollapse').alt = docollaps;
        document.getElementById('scpollcollapse').title = docollaps;
    }
    else {
        document.getElementById("polldiv").style.display = 'none';
        document.getElementById('scpollcollapse').src="$imagesdir/$cat_exp";
        document.getElementById('scpollcollapse').alt = doexpand;
        document.getElementById('scpollcollapse').title = doexpand;
    }
    var url = '$scripturl?action=scpollcoll&scpoll=' + linkpollnr;
    GetXmlHttpObject();
    if (xmlHttp === null) return;
    xmlHttp.open("GET",url,true);
    xmlHttp.send(null);
}
</script>
~;
    return $pollmain;
}

sub collapse_poll {
    ${$uid.$username}{'collapsescpoll'} = $INFO{'scpoll'};
    UserAccount($username, 'update');
    $elenable = 0;
    croak q{};
}

sub check_deletepoll {
    fopen(FILE, "$datadir/$pollnum.poll");
    $poll_chech = <FILE>;
    fclose(FILE);
    chomp $poll_chech;
    $vote_limit = ( split /\|/xsm, $poll_chech, 14 )[12];
    $poll_nodelete{$username} = 0;
    if (!$vote_limit) {
        $poll_nodelete{$username} = 1;
        return;
    }
    if (-e "$datadir/$pollnum.polled") {
        fopen(FILE, "$datadir/$pollnum.polled");
        @chpolled = <FILE>;
        fclose(FILE);
        foreach my $chvoter (@chpolled) {
            ( undef, $chvotersname, undef, $chvotedate ) = split /\|/xsm,
              $chvoter;
            if ($chvotersname eq $username) {
                $chdiff = $date - $chvotedate;
                if ($chdiff > ($vote_limit * 60)) {
                    $poll_nodelete{$username} = 1;
                    last;
                }
            }
        }
    }
    return;
}

sub ShowcasePoll {
    is_admin_or_gmod();
    my $thrdid = $INFO{'num'};
    fopen (SCFILE, ">$datadir/showcase.poll");
    print {SCFILE} $thrdid or croak "$croak{'print'} SCFILE";
    fclose (SCFILE);
    $yySetLocation = qq~$scripturl~;
    redirectexit();
    return;
}

sub DelShowcasePoll{
    is_admin_or_gmod();
    if ( -e "$datadir/showcase.poll" ) { unlink "$datadir/showcase.poll"; }
    $yySetLocation = qq~$scripturl~;
    redirectexit();
    return;
}

1;
