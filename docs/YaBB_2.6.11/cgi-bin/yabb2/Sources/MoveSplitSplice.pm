###############################################################################
# MoveSplitSplice.pm                                                          #
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

$movesplitsplicepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('MoveSplitSplice');

get_template('Display');

sub Split_Splice {
    if ( !$staff ) { fatal_error('split_splice_not_allowed'); }
    if ( $FORM{'ss_submit'} || $INFO{'ss_submit'} ) { Split_Splice_2(); }

    my $curboard  = $INFO{'board'};
    my $curthread = $INFO{'thread'};
    if ( !exists $FORM{'oldposts'} ) { $FORM{'oldposts'} = $INFO{'oldposts'}; }
    if ( !exists $FORM{'leave'} )    { $FORM{'leave'}    = $INFO{'leave'}; }
    if ( exists $INFO{'newinfo'} )   { $FORM{'newinfo'}  = $INFO{'newinfo'}; }
    my $newcat   = $FORM{'newcat'}   || $INFO{'newcat'};
    my $newboard = $FORM{'newboard'} || $INFO{'newboard'};
    if ( !exists $FORM{'newthread'} ) {
        $FORM{'newthread'} = $INFO{'newthread'};
    }
    my $newthread = $FORM{'newthread'} || 'new';
    if ( !exists $FORM{'newthread_subject'} ) {
        $FORM{'newthread_subject'} = $INFO{'newthread_subject'};
    }
    if ( !exists $FORM{'position'} ) { $FORM{'position'} = $INFO{'position'}; }

    require Sources::YaBBC;
    LoadCensorList();

    # Get posts of current thread
    if ( !ref $thread_arrayref{$curthread} ) {
        fopen( FILE, "$datadir/$curthread.txt" );
        @{ $thread_arrayref{$curthread} } = <FILE>;
        fclose(FILE);
    }
    my @messages = @{ $thread_arrayref{$curthread} };

    my ( $counter, $size1 );
    for my $counter ( 0 .. ( @messages - 1 ) ) {
        $message = ( split /\|/xsm, $messages[$counter], 10 )[8];
        ( $message, undef ) = Split_Splice_Move( $message, 1 );
        DoUBBC();

        $convertstr = $message;
        $convertstr =~ s/<(p|br|div).*?>/ /gxsm;
        $convertstr =~ s/<.*?>//gxsm;              # remove HTML-tags
        $convertcut = 50;
        CountChars();
        $message = $convertstr;
        if ($cliped) { $message .= ' ...'; }

        ToChars($message);
        $message = Censor($message);

        $messages[$counter] = qq~<option value="$counter" ~
          . (
            $FORM{'oldposts'} =~ /\b$counter\b/xsm
            ? q~selected="selected"~
            : q{}
          )
          . q~>~
          . ( $counter ? "$sstxt{'40'} $counter" : $sstxt{'41'} )
          . qq~: $message</option>\n~;
    }
    if ( ( $ttsureverse && ${ $uid . $username }{'reversetopic'} )
        || $ttsreverse )
    {
        @messages = reverse @messages;
    }
    my $postlist = (
        $FORM{'oldposts'} eq 'all'
        ? qq~<option value="all" selected="selected">$sstxt{'26'}</option>\n~
        : qq~<option value="all">$sstxt{'26'}</option>\n~
    ) . join q{}, @messages;
    $size1 = @messages + 1;
    $size1 = $size1 > 10 ? 10 : $size1;    # maximum size of multiselect field

    # List of options of what, if anything, to leave in place of the posts moved
    my @leaveopts = ( $sstxt{'11'}, $sstxt{'12'}, $sstxt{'13'} );
    for my $counter ( 0 .. ( @leaveopts - 1 ) ) {
        $leavelist .=
            qq~<option value="$counter" ~
          . ( $FORM{'leave'} == $counter ? q~selected="selected"~ : q{} )
          . qq~>$leaveopts[$counter]</option>\n~;
    }

    # Get categories and make the current one the default selection
    my $catlist = qq~<option value="cats" >$sstxt{'28'}</option>\n~;
    foreach (@categoryorder) {
        my ( $catname, $catperms ) = split /\|/xsm, $catinfo{$_}, 3;
        next if !CatAccess($catperms);
        $catlist .=
            qq~<option value="$_" ~
          . ( $newcat eq $_ ? q~selected="selected"~ : q{} )
          . qq~>$catname</option>\n~;
    }

    # Get boards and make the current one the default selection
    $boardlist = qq~<option value="boards">$sstxt{'29'}</option>\n~;
    my $indent = -2;

    *get_subboards = sub {
        my @x = @_;
        $indent += 2;
        foreach my $childbd (@x) {
            my $dash;
            if ( $indent > 0 ) { $dash = q{-}; }
            my ( $boardname, $boardperms ) = split /\|/xsm, $board{$childbd}, 3;
            ToChars($boardname);
            my $access = AccessCheck( $_, q{}, $boardperms );
            next if !$iamadmin && $access ne 'granted' && $boardview != 1;

            my $bdnopost =
              ( ${ $uid . $childbd }{'canpost'} || !$subboard{$childbd} )
              ? q{}
              : q~ class="nopost"~;
            $boardlist .=
                qq~<option$bdnopost value="$childbd" ~
              . ( $newboard eq $childbd ? q~selected="selected"~ : q{} ) . q~>~
              . ( '&nbsp;' x $indent )
              . ( $dash x ( $indent / 2 ) )
              . qq~&nbsp;$boardname</option>\n~;

            if ( $subboard{$childbd} ) {
                get_subboards( split /\|/xsm, $subboard{$childbd} );
            }
        }
        $indent -= 2;
        return;
    };
    get_subboards( split /,/xsm, $cat{$newcat} );

    # Get threads and make the current one the default selection
    my ( $threadlist, $threadids, $positionlist );
    fopen( FILE, "$boardsdir/$newboard.txt" );
    my @threads = <FILE>;
    fclose(FILE);

    $threadlist = qq~<option value="new">$sstxt{'30'}</option>\n~;
    my $threadid;
    foreach (@threads) {
        ( $threadid, $message, undef ) = split /\|/xsm, $_, 3;
        next if $curthread eq $threadid;
        $threadids .= "$threadid,";

        ( $message, undef ) = Split_Splice_Move( $message, $threadid );
        DoUBBC();

        $convertstr = $message;
        $convertcut = 50;
        CountChars();
        $message = $convertstr;
        if ($cliped) { $message .= ' ...'; }

        ToChars($message);
        $message =~ s/<(p|br|div).*?>/ /gxsm;
        $message =~ s/<.*?>//gxsm;              # remove HTML-tags
        $message = Censor($message);

        $threadlist .=
            qq~<option value="$threadid" ~
          . ( $newthread eq $threadid ? q~selected="selected"~ : q{} )
          . qq~>$message</option>\n~;
    }

    # Get new thread posts to select splice site
    if ( $FORM{'newthread'} ne 'new' ) {
        if ( !ref $thread_arrayref{$newthread} ) {
            fopen( FILE, "$datadir/$newthread.txt" );
            @{ $thread_arrayref{$newthread} } = <FILE>;
            fclose(FILE);
        }
        @messages = @{ $thread_arrayref{$newthread} };

        for my $counter ( 0 .. ( @messages - 1 ) ) {
            $message = ( split /[\|]/xsm, $messages[$counter], 10 )[8];
            ( $message, undef ) = Split_Splice_Move( $message, 1 );
            DoUBBC();

            $convertstr = $message;
            $convertcut = 50;
            CountChars();
            $message = $convertstr;
            if ($cliped) { $message .= ' ...'; }

            ToChars($message);
            $message =~ s/<(p|br|div).*?>/ /gxsm;
            $message =~ s/<.*?>//gxsm;              # remove HTML-tags
            $message = Censor($message);

            $messages[$counter] =
                qq~<option value="$counter">~
              . ( $counter ? "$sstxt{'40'} $counter" : $sstxt{'41'} )
              . qq~: $message</option>\n~;
        }
        if ( ( $ttsureverse && ${ $uid . $username }{'reversetopic'} )
            || $ttsreverse )
        {
            @messages = reverse @messages;
        }
        $positionlist = qq~<option value="end">$sstxt{'31'}</option>\n~;
        $positionlist .=
          qq~<option value="begin">$sstxt{'32'}</option>\n~;
        $positionlist .= join q{}, @messages;
        if (   $FORM{'position'}
            && $newthread == $FORM{'old_position_thread'} )
        {
            $positionlist =~
              s/(value="$FORM{'position'}")/$1 selected="selected"/xsm;
        }
    }

    if (   $newthread eq 'new'
        || !$threadlist
        || $threadids !~ /\b$newthread\b/xsm )
    {
        $my_output = $mymove_output_a;
        $my_output =~ s/{yabb newthread_subject}/$FORM{'newthread_subject'}/sm;
        $my_output =~ s/{yabb position}/$FORM{'position'}/sm;
        $my_output =~
          s/{yabb old_position_thread}/$FORM{'old_position_thread'}/sm;
    }
    else {
        $my_output = $mymove_output_b;
        $my_output =~ s/{yabb positionlist}/$positionlist/sm;
        $my_output =~ s/{yabb newthread_subject}/$FORM{'newthread_subject'}/sm;
        $my_output =~ s/{yabb newthread}/$newthread/sm;
    }

    $my_checked = $FORM{'newinfo'} ? ' checked="checked"' : q{};

    $output = $mymove_top;
    $output =~ s/{yabb formsession}/$formsession/sm;
    $output =~ s/{yabb postlist}/$postlist/sm;
    $output =~ s/{yabb leavelist}/$leavelist/sm;
    $output =~ s/{yabb catlist}/$catlist/sm;
    $output =~ s/{yabb boardlist}/$boardlist/sm;
    $output =~ s/{yabb threadlist}/$threadlist/sm;
    $output =~ s/{yabb my_output}/$my_output/sm;
    $output =~ s/{yabb my_checked}/$my_checked/sm;
    $output =~ s/{yabb size1}/$size1/sm;

    print_output_header();
    print_HTML_output_and_finish();
    return;
}

sub Split_Splice_2 {
    if ( !$staff && $INFO{'newboard'} ne $binboard ) {
        fatal_error('split_splice_not_allowed');
    }

    my $curboard    = $INFO{'board'};
    my $curthreadid = $INFO{'thread'};
    my $movingposts =
      exists $INFO{'oldposts'} ? $INFO{'oldposts'} : $FORM{'oldposts'};
    $FORM{'oldposts'} = $movingposts;
    my $leavemess = exists $INFO{'leave'} ? $INFO{'leave'} : $FORM{'leave'};
    my $forcenewinfo =
      exists $INFO{'newinfo'} ? $INFO{'newinfo'} : $FORM{'newinfo'};
    my $newcat = exists $INFO{'newcat'} ? $INFO{'newcat'} : $FORM{'newcat'};
    my $newboard =
      exists $INFO{'newboard'} ? $INFO{'newboard'} : $FORM{'newboard'};
    my $newthreadid =
      exists $INFO{'newthread'} ? $INFO{'newthread'} : $FORM{'newthread'};
    $FORM{'newthread'} = $newthreadid;
    my $newthreadsub =
      exists $INFO{'newthread_subject'}
      ? $INFO{'newthread_subject'}
      : $FORM{'newthread_subject'};
    my $newposition =
      exists $INFO{'position'} ? $INFO{'position'} : $FORM{'position'};
    $FORM{'position'} = $newposition;

    # Error messages if something is not filled out right
    if ( $movingposts eq q{} ) {
        fatal_error( q{}, "$sstxt{'22b'} $sstxt{'23'} $sstxt{'50'}" );
    }
    if ( $newcat   eq 'cats' )   { fatal_error( q{}, "$sstxt{'22'}" ); }
    if ( $newboard eq 'boards' ) { fatal_error( q{}, "$sstxt{'22a'}" ); }
    if ( -e "$datadir/$curthreadid.poll" && -e "$datadir/$newthreadid.poll" ) {
        fatal_error( q{}, "$sstxt{'51'} $sstxt{'50'}" );
    }

    my ( @postnum, @utdcurthread, @utdnewthread, $i );
    my $linkcount = 0;

    # Get current thread posts
    if ( !ref $thread_arrayref{$curthreadid} ) {
        fopen( FILE, "$datadir/$curthreadid.txt" );
        @{ $thread_arrayref{$curthreadid} } = <FILE>;
        fclose(FILE);
    }
    my @curthread = @{ $thread_arrayref{$curthreadid} };
    MessageTotals( 'load', $curthreadid );

    # Store post numbers to be moved in array
    if ( ( split /\, /sm, $movingposts, 2 )[0] eq 'all' ) {
        @postnum = ( 0 .. $#curthread );
    }
    else {
        @postnum = sort { $a <=> $b } split /\, /sm, $movingposts;
    }    # sort numerically ascending because may be reversed!

# Check to see if current thread was the latest post for the board and if the last post was selected to change
    BoardTotals( 'load', $curboard );
    if (
        ${$curthreadid}{'lastpostdate'} == ${ $uid . $curboard }{'lastposttime'}
        && $leavemess == 2
        && $postnum[-1] == $#curthread )
    {
        $newest_post = 1;
    }

    # Move selected posts to a brand new thread
    if ( $newthreadid eq 'new' ) {

        # Find a valid random ID for new thread.
        $newthreadid = ( split /\|/xsm, $curthread[ $postnum[0] ], 5 )[3] + 1;
        while ( -e "$datadir/$newthreadid.txt" ) { $newthreadid++; }

        foreach (@postnum) {
            if ( $newthreadsub || $leavemess == 1 )
            {    # insert new subject name || add 'no_postcount' into copies
                my @x = split /\|/xsm, $curthread[$_];
                if ($newthreadsub) {
                    $x[0] =
                        $_ == $postnum[0]
                      ? $newthreadsub
                      : qq~$sstxt{'21'} $newthreadsub~;
                }
                if ( $leavemess == 1 ) { $x[5] = 'no_postcount'; }
                push @utdnewthread, join q{|}, @x;
            }
            else {
                push @utdnewthread, $curthread[$_];
            }
        }

        # Place selected posts in existing thread at selected position
    }
    else {

        # Get existing thread posts
        if ( !ref $thread_arrayref{$newthreadid} ) {
            fopen( FILE, "$datadir/$newthreadid.txt" );
            @{ $thread_arrayref{$newthreadid} } = <FILE>;
            fclose(FILE);
        }
        my @newthread = @{ $thread_arrayref{$newthreadid} };
        MessageTotals( 'load', $newthreadid );

        if ( $newposition eq 'end' ) { $newposition = $#newthread; }
        elsif ( $newposition eq 'begin' ) {
            foreach (@postnum) {
                if ( $leavemess == 1 ) {    # add 'no_postcount' into copies
                    my @x = split /\|/xsm, $curthread[$_];
                    $x[5] = 'no_postcount';
                    push @utdnewthread, join q{|}, @x;
                }
                else {
                    push @utdnewthread, $curthread[$_];
                }
            }
            $newposition = -1;
        }
        for my $i ( 0 .. ( @newthread - 1 ) ) {
            push @utdnewthread, $newthread[$i];
            if ( $newposition == $i ) {
                foreach (@postnum) {
                    if ( $leavemess == 1 ) {    # add 'no_postcount' into copies
                        my @x = split /\|/xsm, $curthread[$_];
                        $x[5] = 'no_postcount';
                        push @utdnewthread, join q{|}, @x;
                    }
                    else {
                        push @utdnewthread, $curthread[$_];
                    }
                }
                $linkcount = $i + 1;
            }
        }
    }

    # Remove or copy selected posts from current thread
    if ( $#postnum == $#curthread && $leavemess != 1 ) {
        if ( $newboard ne $binboard ) {
            my ( $tmpsub, $tmpmessage );
            my $hidename = cloak($username);
            ( $tmpsub, undef ) = split /\|/xsm, $curthread[0], 2;
            if ( $curboard eq $newboard ) {
                $tmpmessage =
                  qq~[m by=$hidename dest=$newthreadid/$linkcount#$linkcount]~;
                $tmpsub = qq~[m by=$hidename dest=$newthreadid]: '$tmpsub'~;
            }
            else {
                $tmpmessage =
qq~[m by=$hidename destboard=$newboard dest=$newthreadid/$linkcount#$linkcount]~;
                $tmpsub =
qq~[m by=$hidename destboard=$newboard dest=$newthreadid]: '$tmpsub'~;
            }
            FromChars($tmpmessage);
            $utdcurthread[0] =
qq~$tmpsub|${$uid.$username}{'realname'}|${$uid.$username}{'email'}|$date|$username|no_postcount||$user_ip|$tmpmessage||||\n~;

            if ( eval { require Variables::Movedthreads; 1 } ) {
                $moved_file{$curthreadid} = $newthreadid;
                delete $moved_file{$newthreadid};
                save_moved_file();
                $leavemess = 0;
            }
        }
        else {
            $leavemess    = 2;
            $forcenewinfo = 1;
        }
    }
    elsif ( $leavemess != 1 ) {
        if ( $newboard eq $binboard ) { $leavemess = 2; }
        for my $i ( 0 .. ( @curthread - 1 ) ) {
            if ( $movingposts =~ /\b$i\b/xsm ) {
                if ( $leavemess == 0 && $i == $postnum[-1] ) {
                    my $tmpsub;
                    ( $tmpsub, undef ) = split /\|/xsm, $curthread[$i], 2;
                    push @utdcurthread,
qq~$tmpsub|${$uid.$username}{'realname'}|${$uid.$username}{'email'}|$date|$username|no_postcount||$user_ip|[split] [link=$scripturl?num=$newthreadid/$linkcount#$linkcount][splithere][/link][splithere_end]||||\n~;
                }
            }
            else {
                push @utdcurthread, $curthread[$i];
            }
        }

    }
    else { @utdcurthread = @curthread; }

    if ($forcenewinfo) {
        my ( $boardtitle, $tmpsub, $tmpmessage );
        ( $boardtitle, undef ) = split /\|/xsm, $board{$curboard}, 2;
        $tmpmessage = (
            $#postnum == $#utdnewthread
            ? '[b][movedhere]'
            : '[b][postsmovedhere1] ' . @postnum . ' [postsmovedhere2]'
          )
          . " [i]$boardtitle\[/i] [move by] [i]${$uid.$username}{'realname'}\[/i].[/b]";
        FromChars($tmpmessage);
        ( $tmpsub, undef, undef, undef, undef, undef, undef ) =
          split /\|/xsm, $utdnewthread[0], 7;
        splice @utdnewthread, ( $linkcount + @postnum ), 0,
qq~$sstxt{'21'} $tmpsub|${$uid.$username}{'realname'}|${$uid.$username}{'email'}|$date|$username|no_postcount||$user_ip|$tmpmessage||||\n~;
    }

    if (@utdcurthread) {
        for my $i ( 0 .. ( @utdcurthread - 1 ) ) {    # sort post numbers
            my @x = split /\|/xsm, $utdcurthread[$i];
            $x[6] = $i;
            $utdcurthread[$i] = join q{|}, @x;
        }

        # Update current thread
        fopen( FILE, ">$datadir/$curthreadid.txt" );
        print {FILE} @utdcurthread or croak "$croak{'print'} FILE";
        fclose(FILE);
    }
    else {
        require Sources::RemoveTopic;
        my $moveit = $INFO{'moveit'};
        $INFO{'moveit'} = 1;
        RemoveThread();
        $INFO{'moveit'} = $moveit;
    }

    for my $i ( 0 .. ( @utdnewthread - 1 ) ) {    # sort post numbers
        my @x = split /\|/xsm, $utdnewthread[$i];
        $x[6] = $i;
        $utdnewthread[$i] = join q{|}, @x;
    }

    # Update new thread
    fopen( FILE, ">$datadir/$newthreadid.txt" );
    print {FILE} @utdnewthread or croak "$croak{'print'} FILE";
    fclose(FILE);

    # Update the .rlog files of the users
    my (
        $reply,               $ms,                 $mn,
        $md,                  $mu,                 $mnp,
        $mi,                  %mu,                 %curthreadusersdate,
        %curthreaduserscount, %newthreadusersdate, %newthreaduserscount,
        %BoardTotals
    );
    $reply = 0;
    foreach (@utdcurthread)
    { # $subject|$name|$email|$date|$username|$icon|0|$user_ip|$message|$ns|||$fixfile
        ( $ms, $mn, undef, $md, $mu, $mnp, undef, $mi, undef ) =
          split /\|/xsm, $_, 9;
        if ( ${ $BoardTotals{$curthreadid} }[0] <= $md ) {
            $BoardTotals{$curthreadid} = [ $md, $mu, $reply, $ms, $mn, $mi ];
        }
        $reply++;
        next if $mnp eq 'no_postcount';
        if ( $curthreadusersdate{$mu} < $md ) {
            $curthreadusersdate{$mu} = $md;
        }
        $curthreaduserscount{$mu}++;
        $mu{$mu} = 1;
    }
    $reply = 0;
    foreach (@utdnewthread) {
        ( $ms, $mn, undef, $md, $mu, $mnp, undef, $mi, undef ) =
          split /\|/xsm, $_, 9;
        if ( ${ $BoardTotals{$newthreadid} }[0] <= $md ) {
            $BoardTotals{$newthreadid} = [ $md, $mu, $reply, $ms, $mn, $mi ];
        }
        $reply++;
        next if $mnp eq 'no_postcount';
        if ( $newthreadusersdate{$mu} < $md ) {
            $newthreadusersdate{$mu} = $md;
        }
        $newthreaduserscount{$mu}++;
        $mu{$mu} = 1;
    }
    foreach my $mu ( keys %mu ) {
        Recent_Load($mu);
        delete $recent{$curthreadid};
        delete $recent{$newthreadid};
        if ( $curthreaduserscount{$mu} ) {
            ${ $recent{$curthreadid} }[0] = $curthreaduserscount{$mu};
            ${ $recent{$curthreadid} }[1] = $curthreadusersdate{$mu};
        }
        if ( $newthreaduserscount{$mu} ) {
            ${ $recent{$newthreadid} }[0] = $newthreaduserscount{$mu};
            ${ $recent{$newthreadid} }[1] = $newthreadusersdate{$mu};
        }
        Recent_Save($mu);
    }

    # For: Mark threads/boards as read
    getlog();
    my $boardlog = 1;

    # Mark new thread as read because you will be directed there at the end
    delete $yyuserlog{"$newthreadid--unread"};
    $yyuserlog{$newthreadid} = $date;

# Update .ctb, tags=>(board replies views lastposter lastpostdate threadstatus repliers)
# curthread
    ${$curthreadid}{'replies'}      = $#utdcurthread;
    ${$curthreadid}{'lastpostdate'} = ${ $BoardTotals{$curthreadid} }[0];
    ${$curthreadid}{'lastposter'} =
      ${ $BoardTotals{$curthreadid} }[1] eq 'Guest'
      ? "Guest-${$BoardTotals{$curthreadid}}[4]"
      : ${ $BoardTotals{$curthreadid} }[1];

    # newthread
    ${$newthreadid}{'replies'}      = $#utdnewthread;
    ${$newthreadid}{'lastpostdate'} = ${ $BoardTotals{$newthreadid} }[0];
    ${$newthreadid}{'lastposter'} =
      ${ $BoardTotals{$newthreadid} }[1] eq 'Guest'
      ? "Guest-${$BoardTotals{$newthreadid}}[4]"
      : ${ $BoardTotals{$newthreadid} }[1];
    if ( $FORM{'newthread'} eq 'new' ) {
        ${$newthreadid}{'board'} = $newboard;
        ${$newthreadid}{'views'} =
          $#postnum == $#curthread
          ? ${$curthreadid}{'views'}
          : ( $INFO{'ss_submit'} ? 1 : 0 );
        ${$newthreadid}{'threadstatus'} = ${$curthreadid}{'threadstatus'};
        ${$curthreadid}{'views'}        = $#postnum == $#curthread
          && $leavemess != 1 ? 0 : ${$curthreadid}{'views'};
    }
    else {
        ${$newthreadid}{'views'} +=
          int( ${$curthreadid}{'views'} / @curthread * @postnum );
    }

    # Update current message index
    fopen( BOARD, "<$boardsdir/$curboard.txt", 1 );
    my @curmessindex = <BOARD>;
    fclose( BOARD );

    my $old_mstate;
    for my $i ( 0 .. ( @curmessindex - 1 ) ) {
        my (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate
        ) = split /\|/xsm, $curmessindex[$i];
        if ( $mdate > $yyuserlog{$curboard} ) {
            $boardlog = 0;
        }    # For: Mark boards as read
        if ( $mnum == $curthreadid ) {
            chomp $mstate;
            if ( $#postnum == $#curthread && $leavemess != 1 )
            {    # thread was moved
                my $hidename = cloak($username);
                if ( $curboard eq $newboard ) {
                    $msub = qq~[m by=$hidename dest=$newthreadid]: '$msub'~;
                }
                else {
                    $msub =
qq~[m by=$hidename destboard=$newboard dest=$newthreadid]: '$msub'~;
                }
                $mname     = ${ $uid . $username }{'realname'};
                $memail    = ${ $uid . $username }{'email'};
                $mreplies  = 0;
                $musername = $username;

                # alter message icon to 'exclamation' to match status 'lm'
                if ( $micon ne 'no_postcount' ) { $micon = 'exclamation'; }

      # thread status - (a)nnoumcement, (h)idden, (l)ocked, (m)oved and (s)ticky
                $old_mstate = $mstate;
                if ( $curboard eq $annboard && $mstate !~ /a/ism ) {
                    $mstate .= 'a';
                }
                if ( $mstate !~ /l/ism ) { $mstate .= 'l'; }
                if ( $mstate !~ /m/ism ) { $mstate .= 'm'; }
                ${$curthreadid}{'threadstatus'} = $mstate;
            }
            else {
                ( $msub, $mname, $memail, undef, $musername, $micon, undef ) =
                  split /\|/xsm, $utdcurthread[0], 7;
                $mreplies = ${$curthreadid}{'replies'};
            }
            $curmessindex[$i] =
qq~$mnum|$msub|$mname|$memail|${$curthreadid}{'lastpostdate'}|$mreplies|$musername|$micon|$mstate\n~;
            ${ $BoardTotals{$mnum} }[6] = $mstate;

        }
        elsif ( $mnum == $newthreadid ) {
            chomp $mstate;
            if ( $FORM{'position'} eq 'begin' ) {
                ( $msub, $mname, $memail, undef, $musername, $micon, undef ) =
                  split /\|/xsm, $utdnewthread[0], 7;
            }
            $yyThreadLine = $curmessindex[$i] =
qq~$mnum|$msub|$mname|$memail|${$newthreadid}{'lastpostdate'}|${$newthreadid}{'replies'}|$musername|$micon|$mstate\n~;
            ${ $BoardTotals{$mnum} }[6] = $mstate;
            if (
                ( $enable_notifications == 1 || $enable_notifications == 3 )
                && (   -e "$boardsdir/$curboard.mail"
                    || -e "$datadir/$newthreadid.mail" )
              )
            {
                require Sources::Post;
                $currentboard = $curboard;
                $msub         = Censor($msub);
                ReplyNotify( $newthreadid, $msub, ${$newthreadid}{'replies'} );
            }
        }
    }
    if ( $curboard eq $newboard && $FORM{'newthread'} eq 'new' ) {
        my ( $msub, $mname, $memail, $musername, $micon );
        ( $msub, $mname, $memail, undef, $musername, $micon, undef ) =
          split /\|/xsm, $utdnewthread[0], 7;
        if ( $old_mstate !~ /0/ism ) { $old_mstate .= '0'; }
        $yyThreadLine =
qq~$newthreadid|$msub|$mname|$memail|${$newthreadid}{'lastpostdate'}|${$newthreadid}{'replies'}|$musername|$micon|$old_mstate\n~;
        unshift @curmessindex, $yyThreadLine;
        ${ $BoardTotals{$newthreadid} }[6] = $old_mstate;
        if ( ( $enable_notifications == 1 || $enable_notifications == 3 )
            && -e "$boardsdir/$newboard.mail" )
        {
            require Sources::Post;
            $currentboard = $curboard;
            $msub         = Censor($msub);
            NewNotify( $newthreadid, $msub );
        }
    }
    fopen( BOARD, ">$boardsdir/$curboard.txt", 1 );
    print {BOARD} reverse
      sort { ( split /\|/xsm, $a, 6 )[4] <=> ( split /\|/xsm, $b, 6 )[4] }
      @curmessindex
      or croak "$croak{'print'} BOARD";
    fclose( BOARD );

    if ($boardlog) {
        $yyuserlog{$curboard} = $date;
    }    # For: Mark boards as read

    # Update new message index if needed
    if ( $curboard ne $newboard ) {
        $boardlog = 1;    # For: Mark boards as read

        fopen( BOARD, "+<$boardsdir/$newboard.txt", 1 );
        seek BOARD, 0, 0;
        my @newmessindex = <BOARD>;
        truncate BOARD, 0;
        seek BOARD, 0, 0;

        if ( $FORM{'newthread'} eq 'new' ) {

            # For: Mark boards as read
            foreach (@newmessindex) {
                if ( ( split /\|/xsm, $_, 6 )[4] > $yyuserlog{$newboard} ) {
                    $boardlog = 0;
                }
                last if !$boardlog;
            }

            my ( $msub, $mname, $memail, undef, $musername, $micon, undef ) =
              split /\|/xsm, $utdnewthread[0], 7;
            if ( $old_mstate =~ /a/ism ) {
                if ( $newboard ne $annboard ) { $old_mstate =~ s/a//gism; }
            }
            elsif ( $newboard eq $annboard ) {
                $old_mstate .= 'a';
            }
            if ( $old_mstate !~ /0/ism ) { $old_mstate .= '0'; }
            $yyThreadLine =
qq~$newthreadid|$msub|$mname|$memail|${$newthreadid}{'lastpostdate'}|${$newthreadid}{'replies'}|$musername|$micon|$old_mstate\n~;
            unshift @newmessindex, $yyThreadLine;
            ${ $BoardTotals{$newthreadid} }[6] = $old_mstate;
            if ( ( $enable_notifications == 1 || $enable_notifications == 3 )
                && -e "$boardsdir/$newboard.mail" )
            {
                require Sources::Post;
                $currentboard = $newboard;
                $msub         = Censor($msub);
                NewNotify( $newthreadid, $msub );
            }
        }
        else {
            for my $i ( 0 .. ( @newmessindex - 1 ) ) {
                my (
                    $mnum,     $msub,      $mname, $memail, $mdate,
                    $mreplies, $musername, $micon, $mstate
                ) = split /\|/xsm, $newmessindex[$i];
                if ( $mdate > $yyuserlog{$newboard} ) {
                    $boardlog = 0;
                }    # For: Mark boards as read
                if ( $mnum == $newthreadid ) {
                    chomp $mstate;
                    if ( $FORM{'position'} eq 'begin' ) {
                        (
                            $msub, $mname, $memail, undef, $musername, $micon,
                            undef
                        ) = split /\|/xsm, $utdnewthread[0], 7;
                    }
                    $yyThreadLine = $newmessindex[$i] =
qq~$mnum|$msub|$mname|$memail|${$newthreadid}{'lastpostdate'}|${$newthreadid}{'replies'}|$musername|$micon|$mstate\n~;
                    ${ $BoardTotals{$mnum} }[6] = $mstate;
                }
            }
            if (
                ( $enable_notifications == 1 || $enable_notifications == 3 )
                && (   -e "$boardsdir/$newboard.mail"
                    || -e "$datadir/$newthreadid.mail" )
              )
            {
                require Sources::Post;
                $currentboard = $newboard;
                $msub         = Censor($msub);
                ReplyNotify( $newthreadid, $msub, ${$newthreadid}{'replies'} );
            }
        }
        print {BOARD} reverse
          sort { ( split /\|/xsm, $a, 6 )[4] <=> ( split /\|/xsm, $b, 6 )[4] }
          @newmessindex
          or croak "$croak{'print'} BOARD";
        fclose(BOARD);

        if ($boardlog) {
            $yyuserlog{$newboard} = $date;
        }    # For: Mark boards as read
    }

    if (@utdcurthread) { MessageTotals( 'update', $curthreadid ); }
    MessageTotals( 'update', $newthreadid );

# update current board totals
# BoardTotals- tags => (board threadcount messagecount lastposttime lastposter lastpostid lastreply lastsubject lasticon lasttopicstate)
#&BoardTotals("load", $curboard); - Load this at top now to detect if newest board post is being moved - Unilat
    if ( ${ $BoardTotals{$curthreadid} }[6] =~ /m/sm ) {    # Moved-Info thread
        if ( $curboard ne $newboard ) {
            ${ $uid . $curboard }{'threadcount'}--;
            ${ $uid . $curboard }{'messagecount'} -= @postnum;
        }
        BoardSetLastInfo( $curboard, \@curmessindex );
    }
    else {
        if ( $FORM{'newthread'} eq 'new' && $curboard eq $newboard ) {
            ${ $uid . $curboard }{'threadcount'}++;
        }
        if ( $leavemess == 0 ) {
            if ( $curboard ne $newboard ) {
                ${ $uid . $curboard }{'messagecount'} -= $#postnum;
            }
            else {
                ${ $uid . $curboard }{'messagecount'} +=
                  ( $forcenewinfo ? 2 : 1 );
            }
        }
        elsif ( $leavemess == 1 && $curboard eq $newboard ) {
            ${ $uid . $curboard }{'messagecount'} +=
              $#postnum + ( $forcenewinfo ? 1 : 0 );
        }
        elsif ( $leavemess == 2 && $curboard ne $newboard && @utdcurthread ) {
            ${ $uid . $curboard }{'messagecount'} -= @postnum;
        }
        if (
            $newest_post
            || (
                (
                    (
                        ${ $uid . $curboard }{'threadcount'} == 1
                        && @utdcurthread
                    )
                    || ${ $BoardTotals{$curthreadid} }[0] >=
                    ${ $uid . $curboard }{'lastposttime'}
                )
                && ( $curboard ne $newboard
                    || ${ $BoardTotals{$curthreadid} }[0] >=
                    ${ $BoardTotals{$newthreadid} }[0] )
            )
          )
        {
            ${ $uid . $curboard }{'lastposttime'} =
              ${ $BoardTotals{$curthreadid} }[0];
            ${ $uid . $curboard }{'lastposter'} =
              ${ $BoardTotals{$curthreadid} }[1] eq 'Guest'
              ? "Guest-${$BoardTotals{$curthreadid}}[4]"
              : ${ $BoardTotals{$curthreadid} }[1];
            ${ $uid . $curboard }{'lastpostid'} = $curthreadid;
            ${ $uid . $curboard }{'lastreply'} =
              ${ $BoardTotals{$curthreadid} }[2]--;
            ${ $uid . $curboard }{'lastsubject'} =
              ${ $BoardTotals{$curthreadid} }[3];
            ${ $uid . $curboard }{'lasticon'} =
              ${ $BoardTotals{$curthreadid} }[5];
            ${ $uid . $curboard }{'lasttopicstate'} =
              ${ $BoardTotals{$curthreadid} }[6];
        }
        elsif ( ${ $BoardTotals{$newthreadid} }[0] >=
            ${ $uid . $curboard }{'lastposttime'}
            && $curboard eq $newboard )
        {
            ${ $uid . $curboard }{'lastposttime'} =
              ${ $BoardTotals{$newthreadid} }[0];
            ${ $uid . $curboard }{'lastposter'} =
              ${ $BoardTotals{$newthreadid} }[1] eq 'Guest'
              ? "Guest-${$BoardTotals{$newthreadid}}[4]"
              : ${ $BoardTotals{$newthreadid} }[1];
            ${ $uid . $curboard }{'lastpostid'} = $newthreadid;
            ${ $uid . $curboard }{'lastreply'} =
              ${ $BoardTotals{$newthreadid} }[2]--;
            ${ $uid . $curboard }{'lastsubject'} =
              ${ $BoardTotals{$newthreadid} }[3];
            ${ $uid . $curboard }{'lasticon'} =
              ${ $BoardTotals{$newthreadid} }[5];
            ${ $uid . $curboard }{'lasttopicstate'} =
              ${ $BoardTotals{$newthreadid} }[6];
        }
        BoardSetLastInfo( $curboard, \@curmessindex );
    }

    # update new board totals if needed
    if ( $curboard ne $newboard ) {
        BoardTotals( 'load', $newboard );
        if ( $FORM{'newthread'} eq 'new' ) {
            ${ $uid . $newboard }{'threadcount'}++;
        }
        ${ $uid . $newboard }{'messagecount'} +=
          @postnum + ( $forcenewinfo ? 1 : 0 );
        if (   ${ $uid . $newboard }{'threadcount'} == 1
            || ${ $BoardTotals{$newthreadid} }[0] >=
            ${ $uid . $newboard }{'lastposttime'} )
        {
            ${ $uid . $newboard }{'lastposttime'} =
              ${ $BoardTotals{$newthreadid} }[0];
            ${ $uid . $newboard }{'lastposter'} =
              ${ $BoardTotals{$newthreadid} }[1] eq 'Guest'
              ? "Guest-${$BoardTotals{$newthreadid}}[4]"
              : ${ $BoardTotals{$newthreadid} }[1];
            ${ $uid . $newboard }{'lastpostid'} = $newthreadid;
            ${ $uid . $newboard }{'lastreply'} =
              ${ $BoardTotals{$newthreadid} }[2]--;
            ${ $uid . $newboard }{'lastsubject'} =
              ${ $BoardTotals{$newthreadid} }[3];
            ${ $uid . $newboard }{'lasticon'} =
              ${ $BoardTotals{$newthreadid} }[5];
            ${ $uid . $newboard }{'lasttopicstate'} =
              ${ $BoardTotals{$newthreadid} }[6];
        }
        BoardTotals( 'update', $newboard );
    }

    # now fix all attachments.txt info
    my $attachments;
    for my $i ( $postnum[0] .. ( @curthread - 1 ) )
    {    # see if old thread had attachments
        $attachments = ( split /\|/xsm, $curthread[$i] )[12];
        chomp $attachments;
        if ($attachments) {
            $attachments = 1;
            last;
        }
    }
    if ( !$attachments ) {    # see if new thread has attachments
        for my $i ( $linkcount .. ( @utdnewthread - 1 ) ) {
            $attachments = ( split /\|/xsm, $utdnewthread[$i] )[12];
            chomp $attachments;
            if ($attachments) {
                $attachments = 2;
                last;
            }
        }
    }
    if ($attachments) {
        my ( @newattachments, %attachments );
        fopen( ATM, "<$vardir/attachments.txt", 1 )
          or fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
        my @attach = <ATM>;
        fclose(ATM);
        for (@attach) {
            my (
                $attid, undef, undef, undef, undef, undef, undef,
                $attachmentname, $downloadscount
            ) = split /\|/xsm, $_;
            if (   ( $attid != $curthreadid && $attid != $newthreadid )
                || ( $attid == $curthreadid && $attachments != 1 ) )
            {
                push @newattachments, $_;
            }
            chomp $downloadscount;
            $attachments{$attachmentname} = $downloadscount;
        }

        my $mreplies = 0;
        if ( $attachments == 1 ) {
            foreach (@utdcurthread) {    # fix new old thread attachments
                my (
                    $msub, $mname, undef, $mdate, undef, undef, undef,
                    undef, undef,  undef, undef,  undef, $mfn
                ) = split /\|/xsm, $_;
                chomp $mfn;
                foreach ( split /,/xsm, $mfn ) {
                    if ( -e "$uploaddir/$_" ) {
                        my $asize = int( ( -s "$uploaddir/$_" ) / 1024 )
                          || 1;
                        push @newattachments,
qq~$curthreadid|$mreplies|$msub|$mname|$curboard|$asize|$mdate|$_|~
                          . ( $attachments{$_} || 0 ) . qq~\n~;
                    }
                }
                $mreplies++;
            }
        }

        $mreplies = 0;
        foreach (@utdnewthread) {    # fix new thread attachments
            my (
                $msub, $mname, undef, $mdate, undef, undef, undef,
                undef, undef,  undef, undef,  undef, $mfn
            ) = split /\|/xsm, $_;
            chomp $mfn;
            foreach ( split /,/xsm, $mfn ) {
                if ( -e "$uploaddir/$_" ) {
                    my $asize = int( ( -s "$uploaddir/$_" ) / 1024 ) || 1;
                    push @newattachments,
qq~$newthreadid|$mreplies|$msub|$mname|$newboard|$asize|$mdate|$_|~
                      . ( $attachments{$_} || 0 ) . qq~\n~;
                }
            }
            $mreplies++;
        }
        fopen( FATM, ">$vardir/attachments.txt" )
          or fatal_error( 'cannot_open', "$vardir/attachments.txt" );
            print {FATM}
            sort { ( split /\|/xsm, $a, 8 )[6] <=> ( split /\|/xsm, $b, 8 )[6] }
            @newattachments or croak "$croak{'print'} ATM";
        fclose(FATM);
    }

    if ( $#postnum == $#curthread ) {
        if ( -e "$datadir/$curthreadid.poll" ) {
            rename
              "$datadir/$curthreadid.poll",
              "$datadir/$newthreadid.poll";
        }
        if ( -e "$datadir/$curthreadid.polled" ) {
            rename
              "$datadir/$curthreadid.polled",
              "$datadir/$newthreadid.polled";
        }
        if ( -e "$datadir/$curthreadid.mail" ) {
            rename
              "$datadir/$curthreadid.mail",
              "$datadir/$newthreadid.mail";
            require Sources::Notify;
            ManageThreadNotify( 'load', $newthreadid );
            my (%t);
            foreach my $u ( keys %thethread ) {
                LoadUser($u);
                foreach ( split /,/xsm, ${ $uid . $u }{'thread_notifications'} )
                {
                    $t{$_} = 1;
                }
                delete $t{$curthreadid};
                $t{$newthreadid} = 1;
                ${ $uid . $u }{'thread_notifications'} = join q{,}, keys %t;
                UserAccount($u);
                undef %t;
            }
        }
    }

    # Mark current thread as read
    delete $yyuserlog{"$curthreadid--unread"};
    dumplog($curthreadid);    # Save threads/boards as read

    chomp $yyThreadLine;

    if ( $INFO{'moveit'} == 1 ) {
        $currentboard = $curboard;
        return;
    }
    if ( $INFO{'ss_submit'} ) {
        $currentboard = $newboard;
        $INFO{'num'} = $INFO{'thread'} = $FORM{'threadid'} = $curnum =
          $newthreadid;
        redirectinternal();
    }
    if ( $debug == 1 or ( $debug == 2 && $iamadmin ) ) {
        require Sources::Debug;
        Debug();
        $yydebug =
qq~\n- $#utdnewthread<br />\n- @utdnewthread<br />\n- ${$newthreadid}{'lastpostdate'}<br />\n- ${$newthreadid}{'lastposter'}<br />\n- \$enable_notifications == $enable_notifications<br />\n- \$attachments = $attachments<br />\n<a href="javascript:load_thread($newthreadid,$linkcount);">continue</a>\n$yydebug~;
    }

    print_output_header();

    $output =
qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$abbr_lang" lang="$abbr_lang">
<head>
<title>$sstxt{'1'}</title>
<meta http-equiv="Content-Type" content="text/html; charset=$yymycharset" />
<script type="text/javascript">
    function load_thread(threadid,replies) {
        try{
            if (typeof(opener.document) == 'object') throw '1';
            else throw '0';
        } catch (e) {
            if (replies > 0 || ~
      . (
        (
            ( $ttsureverse && ${ $uid . $username }{'reversetopic'} )
              || $ttsreverse
        ) ? 1 : 0
      )
      . qq~ == 1) replies = '/' + replies + '#' + replies;
            else replies = '';
            if (e == 1) {
                opener.focus();
                opener.location.href='$scripturl?num=' + threadid + replies;
                self.close();
            } else {
                location.href='$scripturl?num=' + threadid + replies;
            }
        }
    }
</script>
</head>
<body onload="load_thread($newthreadid,$linkcount);">
&nbsp;$yydebug
</body>
</html>~;

    print_HTML_output_and_finish();
    return;
}

1;
