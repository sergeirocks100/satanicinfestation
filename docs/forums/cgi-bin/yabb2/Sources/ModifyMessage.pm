###############################################################################
# ModifyMessage.pm                                                            #
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
our $VERSION = '2.6.11';
use CGI::Carp qw(fatalsToBrowser);

$modifymessagepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

if ( !$post_txt_loaded ) {
    LoadLanguage('Post');
    $post_txt_loaded = 1;
}
LoadLanguage('FA');
LoadLanguage('Display');

get_micon();
get_template('Post');

require Sources::SpamCheck;
if ( $iamadmin || $iamgmod ) { $MaxMessLen = $AdMaxMessLen; }
$set_subjectMaxLength ||= 50;

sub ModifyMessage {
    if ($iamguest) { fatal_error('members_only'); }
    if ( $currentboard eq q{} ) { fatal_error('no_access'); }

    my ( $mattach, $mip, $mmessage, $mns, $mlm, $mlmb );
    $threadid = $INFO{'thread'};
    $postid   = $INFO{'message'};

    my ( $filetype_info, $filesize_info, $extensions );
    $extensions = join q{ }, @ext;
    $filetype_info =
      $checkext == 1
      ? qq~$fatxt{'2'} $extensions~
      : qq~$fatxt{'2'} $fatxt{'4'}~;
    $limit ||= 0;
    $filesize_info =
      $limit != 0 ? qq~$fatxt{'3'} $limit KB~ : qq~$fatxt{'3'} $fatxt{'5'}~;

    my (
        $mnum,     $msub,      $mname, $memail, $mdate,
        $mreplies, $musername, $micon, $mstate
    ) = split /\|/xsm, $yyThreadLine;

    $postthread = 2;

    if ( $mstate =~ /l/ism ) {
        if ($bypass_lock_perm) { $icanbypass = checkUserLockBypass(); }
        if ( !$icanbypass ) { fatal_error('topic_locked'); }
    }
    elsif ( !$staff
        && $tlnomodflag
        && $date > $mdate + ( $tlnomodtime * 3600 * 24 ) )
    {
        fatal_error( 'time_locked', "$tlnomodtime$timelocktxt{'02'}" );
    }
    if ( $postid eq 'Poll' ) {
        if ( !-e "$datadir/$threadid.poll" ) { fatal_error('not_allowed'); }

        fopen( FILE, "$datadir/$threadid.poll" );
        my @poll_data = <FILE>;
        fclose(FILE);
        chomp @poll_data;
        (
            $poll_question, $poll_locked, $poll_uname,   $poll_name,
            $poll_email,    $poll_date,   $guest_vote,   $hide_results,
            $multi_choice,  $poll_mod,    $poll_modname, $poll_comment,
            $vote_limit,    $pie_radius,  $pie_legends,  $poll_end
        ) = split /\|/xsm, $poll_data[0];
        ToChars($poll_question);
        ToChars($poll_comment);

        for my $i ( 1 .. ( @poll_data - 1 ) ) {
            ( $votes[$i], $options[$i], $slicecolor[$i], $split[$i] ) =
              split /\|/xsm, $poll_data[$i];
            ToChars( $options[$i] );
        }

        if ( $poll_uname ne $username && !$staff ) {
            fatal_error('not_allowed');
        }

        $poll_comment =~ s/<br \/>/\n/gsm;
        $poll_comment =~ s/<br>/\n/gxsm;
        $pollthread = 2;
        $settofield = 'question';
        $icon       = 'poll_mod';

    }
    else {
        if ( !ref $thread_arrayref{$threadid} ) {
            fopen( FILE, "$datadir/$threadid.txt" )
              or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
            @{ $thread_arrayref{$threadid} } = <FILE>;
            fclose(FILE);
        }
        (
            $sub,   $mname,   $memail, $mdate,   $musername,
            $micon, $mattach, $mip,    $message, $mns,
            $mlm,   $mlmb,    $mfn
        ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[$postid];
        chomp $mfn;

        if (
            (
                ${ $uid . $username }{'regtime'} > $mdate
                || $musername ne $username
            )
            && !$staff
          )
        {
            fatal_error('change_not_allowed');
        }

        $lastmod_a = $mlm ? timeformat($mlm) : q{-};
        $nscheck   = $mns ? ' checked'       : q{};

        $lastmod = $mypost_lastmod;
        $lastmod =~ s/{yabb lastmod_a}/$lastmod_a/sm;

        $icon = $micon;
        $message =~ s/<br \/>/\n/igsm;
        $message =~ s/<br>/\n/igxsm;
        $message =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/igsm;
        $settofield = 'message';
        if ( $message =~ s/\[reason\](.+?)\[\/reason\]//isgm ) { $reason = $1; }
    }
    $submittxt   = $post_txt{'10'};
    $destination = 'modify2';
    $post        = 'postmodify';
    require Sources::Post;
    $yytitle       = $post_txt{'66'};
    $mename        = $mname;
    $thismusername = $musername;
    $tmpmdate      = $mdate;
    Postpage();
    template();
    return;
}

sub ModifyMessage2 {
    if ($iamguest) { fatal_error('members_only'); }

    if ( $FORM{'previewmodify'} ) {
        $mename        = qq~$FORM{'mename'}~;
        $tmpmdate      = qq~$FORM{'tmpmdate'}~;
        $thismusername = qq~$FORM{'thismusername'}~;
        require Sources::Post;
        Preview();
    }

    # the post is to be deleted...
    if ( $INFO{'d'} == 1 ) {
        $threadid = $FORM{'thread'};
        $postid   = $FORM{'id'};

        if ( $postid eq 'Poll' ) {

            # showcase poll start
            # Look for a showcase.poll file to unlink.
            if ( -e "$datadir/showcase.poll" ) {
                fopen( FILE, "$datadir/showcase.poll" );
                if ( $threadid == <FILE> ) {
                    fclose(FILE);
                    unlink "$datadir/showcase.poll";
                }
                else {
                    fclose(FILE);
                }
            }

            # showcase poll end
            unlink "$datadir/$threadid.poll";
            unlink "$datadir/$threadid.polled";
            $yySetLocation = qq~$scripturl?num=$threadid~;
            redirectexit();
        }
        else {
            if ( !ref $thread_arrayref{$threadid} ) {
                fopen( FILE, "$datadir/$threadid.txt" )
                  or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
                @{ $thread_arrayref{$threadid} } = <FILE>;
                fclose(FILE);
            }
            $msgcnt = @{ $thread_arrayref{$threadid} };

            # Make sure the user is allowed to edit this post.
            if ( $postid >= 0 && $postid < $msgcnt ) {
                (
                    $msub,  $mname,   $memail, $mdate,    $musername,
                    $micon, $mattach, $mip,    $mmessage, $mns,
                    $mlm,   $mlmb,    $mfn
                ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[$postid];
                chomp $mfn;
                if (
                    ${ $uid . $username }{'regdate'} > $mdate
                    || (  !$staff
                        && $musername ne $username )
                    || !$sessionvalid
                  )
                {
                    fatal_error('delete_not_allowed');
                }
                if (  !$staff
                    && $tlnodelflag
                    && $date > $mdate + ( $tlnodeltime * 3600 * 24 ) )
                {
                    fatal_error( 'time_locked',
                        "$tlnodeltime$timelocktxt{'02a'}" );
                }
            }
            else {
                fatal_error( 'bad_postnumber', $postid );
            }
            $iamposter = ( $musername eq $username && $msgcnt == 1 ) ? 1 : 0;
            $FORM{"del$postid"} = 1;
            MultiDel();
        }
    }

    my (
        $threadid,  $postid,   $msub,      $mname, $memail,   $mdate,
        $musername, $micon,    $mattach,   $mip,   $mmessage, $mns,
        $mlm,       $mlmb,     $tnum,      $tsub,  $tname,    $temail,
        $tdate,     $treplies, $tusername, $ticon, $tstate,   $name,
        $email,     $subject,  $message,   $ns,
    );

    $threadid   = $FORM{'threadid'};
    $postid     = $FORM{'postid'};
    $pollthread = $FORM{'pollthread'};

    if ($pollthread) {
        $maxpq          ||= 60;
        $maxpo          ||= 50;
        $maxpc          ||= 0;
        $numpolloptions ||= 8;
        $vote_limit     ||= 0;

        if ( !-e "$datadir/$threadid.poll" ) { fatal_error('not_allowed'); }

        fopen( FILE, "$datadir/$threadid.poll" );
        my @poll_data = <FILE>;
        fclose(FILE);
        chomp $poll_data;
        (
            $poll_question, $poll_locked, $poll_uname,   $poll_name,
            $poll_email,    $poll_date,   $guest_vote,   $hide_results,
            $multi_choice,  $poll_mod,    $poll_modname, $poll_comment,
            $vote_limit,    $pie_radius,  $pie_legends,  $poll_end
        ) = split /\|/xsm, $poll_data[0];

        if ( $poll_uname ne $username && !$staff ) {
            fatal_error('not_allowed');
        }

        my $numcount = 0;
        if ( !$FORM{'question'} ) { fatal_error('no_question'); }
        $FORM{'question'} =~ s/\&nbsp;/ /gxsm;
        my $testspaces = $FORM{'question'};
        $testspaces = regex_1($testspaces);
        if ( length($testspaces) == 0 && length( $FORM{'question'} ) > 0 ) {
            fatal_error( 'useless_post', "$testspaces" );
        }

        $poll_question = $FORM{'question'};
        FromChars($poll_question);
        $convertstr = $poll_question;
        $convertcut = $maxpq;
        CountChars();
        $poll_question = $convertstr;
        if ($cliped) {
            fatal_error( 'error_occurred',
"$post_polltxt{'40'} $post_polltxt{'34a'} $maxpq $post_polltxt{'34b'} $post_polltxt{'36'}"
            );
        }
        ToHTML($poll_question);

        $guest_vote   = $FORM{'guest_vote'}   || 0;
        $hide_results = $FORM{'hide_results'} || 0;
        $multi_choice = $FORM{'multi_choice'} || 0;
        $poll_comment = $FORM{'poll_comment'} || q{};
        $vote_limit   = $FORM{'vote_limit'}   || 0;
        $pie_legends  = $FORM{'pie_legends'}  || 0;
        $pie_radius   = $FORM{'pie_radius'}   || 100;
        $poll_end_days = $FORM{'poll_end_days'};
        $poll_end_min  = $FORM{'poll_end_min'};

        if ( $pie_radius =~ /\D/xsm ) { $pie_radius = 100; }
        if ( $pie_radius < 100 ) { $pie_radius = 100; }
        if ( $pie_radius > 200 ) { $pie_radius = 200; }

        if ( $vote_limit =~ /\D/xsm ) {
            $vote_limit = 0;
            fatal_error( 'only_numbers_allowed', "$post_polltxt{'62'}" );
        }

        FromChars($poll_comment);
        $convertstr = $poll_comment;
        $convertcut = $maxpc;
        CountChars();
        $poll_comment = $convertstr;
        if ($cliped) {
            fatal_error( 'error_occurred',
"$post_polltxt{'57'} $post_polltxt{'34a'} $maxpc $post_polltxt{'34b'} $post_polltxt{'36'}"
            );
        }
        ToHTML($poll_comment);
        $poll_comment =~ s/\n/<br \/>/gxsm;
        $poll_comment =~ s/\r//gxsm;

        if ( !$poll_end_days || $poll_end_days =~ /\D/xsm ) {
            $poll_end_days = q{};
        }
        if ( !$poll_end_min || $poll_end_min =~ /\D/xsm ) {
            $poll_end_min = q{};
        }
        my $poll_end = q{};
        if ($poll_end_days) { $poll_end = $poll_end_days * 86400; }
        if ($poll_end_min) { $poll_end += $poll_end_min * 60; }
        if ($poll_end)     { $poll_end += $date; }

        my @new_poll_data;
        push @new_poll_data,
qq~$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_choice|$date|$username|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n~;

        for my $i ( 1 .. $numpolloptions ) {
            ( $votes, undef ) = split /\|/xsm, $poll_data[$i], 2;
            if ( !$votes ) { $votes = 0; }
            if ( $FORM{"option$i"} ) {
                $FORM{"option$i"} =~ s/\&nbsp;/ /gxsm;
                $testspaces = $FORM{"option$i"};
                $testspaces = regex_1($testspaces);
                if ( !length $testspaces ) {
                    fatal_error( 'useless_post', "$testspaces" );
                }

                FromChars( $FORM{"option$i"} );
                $convertstr = $FORM{"option$i"};
                $convertcut = $maxpo;
                CountChars();
                $FORM{"option$i"} = $convertstr;
                if ($cliped) {
                    fatal_error( 'error_occurred',
"$post_polltxt{'7'} $i $post_polltxt{'34a'} $maxpo $post_polltxt{'34b'} $post_polltxt{'36'}"
                    );
                }

                ToHTML( $FORM{"option$i"} );
                $numcount++;
                push @new_poll_data,
qq~$votes|$FORM{"option$i"}|$FORM{"slicecol$i"}|$FORM{"split$i"}\n~;
            }
        }
        if ( $numcount < 2 ) { fatal_error('no_options'); }

        # showcase poll start
        if ( $iamadmin || $iamgmod || $iamfmod ) {
            my $scthreadid;
            if ( -e "$datadir/showcase.poll" ) {
                fopen( FILE, "$datadir/showcase.poll" );
                $scthreadid = <FILE>;
                fclose(FILE);
            }
            if ( $threadid == $scthreadid && !$FORM{'scpoll'} ) {
                unlink "$datadir/showcase.poll";
            }
            elsif ( $FORM{'scpoll'} ) {
                fopen( SCFILE, ">$datadir/showcase.poll" );
                print {SCFILE} $threadid or croak "$croak{'print'}SCFILE";
                fclose(SCFILE);
            }
        }

        # showcase poll end

        fopen( POLL, ">$datadir/$threadid.poll" );
        print {POLL} @new_poll_data or croak "$croak{'print'} POLL";
        fclose(POLL);

        $yySetLocation = qq~$scripturl?num=$threadid~;

        redirectexit();
    }

    if ( !ref $thread_arrayref{$threadid} ) {
        fopen( FILE, "$datadir/$threadid.txt" )
          or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
        @{ $thread_arrayref{$threadid} } = <FILE>;
        fclose(FILE);
    }

    # Make sure the user is allowed to edit this post.
    if ( $postid >= 0 && $postid < @{ $thread_arrayref{$threadid} } ) {
        (
            $msub,  $mname,   $memail, $mdate,    $musername,
            $micon, $mattach, $mip,    $mmessage, $mns,
            $mlm,   $mlmb,    $mfn
        ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[$postid];
        chomp $mfn;
        if (
            (
                ${ $uid . $username }{'regdate'} >= $mdate
                || $musername ne $username
            )
            && !$staff
          )
        {
            fatal_error('change_not_allowed');
        }
    }
    else {
        fatal_error( 'bad_postnumber', "$postid" );
    }

    (
        $tnum,     $tsub,      $tname, $temail, $tdate,
        $treplies, $tusername, $ticon, $tstate
    ) = split /\|/xsm, $yyThreadLine;

    if ($postid) { $postthread = 2; }

    # the post is to be modified...
    $name      = $FORM{'name'};
    $email     = $FORM{'email'};
    $subject   = $FORM{'subject'};
    $message   = $FORM{'message'};
    $icon      = $FORM{'icon'};
    $ns        = $FORM{'ns'};
    $notify    = $FORM{'notify'};
    $thestatus = $FORM{'topicstatus'};
    $thestatus =~ s/\, //gsm;
    CheckIcon();

    if ( $FORM{'reason'} ) {
        $reason  = $FORM{'reason'};
        $reason  = qq~\[reason\]$reason\[\/reason\]~;
        $message = qq~$message$reason~;
    }

    if ( !$message ) { fatal_error('no_message'); }

    $spamdetected = spamcheck("$subject $message");
    if ( !${ $uid . $FORM{$username} }{'spamcount'} ) {
        ${ $uid . $FORM{$username} }{'spamcount'} = 0;
    }
    $postspeed = $date - $posttime;
    if ( !$staff ) {
        if ( ( $speedpostdetection && $postspeed < $min_post_speed )
            || $spamdetected == 1 )
        {
            ${ $uid . $username }{'spamcount'}++;
            ${ $uid . $username }{'spamtime'} = $date;
            UserAccount( $username, 'update' );
            $spam_hits_left_count =
              $post_speed_count - ${ $uid . $username }{'spamcount'};
            if   ( $spamdetected == 1 ) { fatal_error('tsc_alert'); }
            else                        { fatal_error('speed_alert'); }
        }
    }

    my $mess_len = $message;
    $mess_len =~ s/[\r\n ]//igsm;
    $mess_len =~ s/&#\d{3,}?\;/X/igxsm;
    if ( length($mess_len) > $MaxMessLen ) {
        require Sources::Post;
        Preview($post_txt{'536'} . q{ }
              . ( length($mess_len) - $MaxMessLen ) . q{ }
              . $post_txt{'537'} );
    }
    undef $mess_len;

    FromChars($subject);
    $convertstr = $subject;
    $convertcut = $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $subject = $convertstr;
    ToHTML($subject);

    ToHTML($name);
    $email =~ s/\|//gxsm;
    ToHTML($email);
    if ( !$subject || $subject =~ m{\A[\s_.,]+\Z}xsm ) {
        fatal_error('no_subject');
    }
    my $testmessage = $message;
    ToChars($testmessage);
    $testmessage = regex_1($testmessage);

    if ( $testmessage eq q{} && $message ne q{} && $pollthread != 2 ) {
        fatal_error( 'useless_post', "$testmessage" );
    }

    if ( !$minlinkpost ) { $minlinkpost = 0; }
    if (   ${ $uid . $username }{'postcount'} < $minlinkpost
        && !$staff
        && !$iamguest )
    {
        if (   $message =~ m{http:\/\/}xsm
            || $message =~ m{https:\/\/}xsm
            || $message =~ m{ftp:\/\/}xsm
            || $message =~ m{www.}xsm
            || $message =~ m{ftp.}xsm =~ m{\[url}xsm
            || $message =~ m{\[link}xsm
            || $message =~ m{\[img}xsm
            || $message =~ m{\[ftp}xsm )
        {
            fatal_error('no_links_allowed');
        }
    }

    FromChars($message);
    $message = regex_2($message);
    ToHTML($message);
    $message = regex_3($message);
    if ( $postid == 0 ) {
        $tsub  = $subject;
        $ticon = $icon;
    }

    if ( $tstate =~ /l/ism ) {
        if ($bypass_lock_perm) { $icanbypass = checkUserLockBypass(); }
        if ( !$icanbypass ) { fatal_error('topic_locked'); }
    }
    if ($staff) {
        $thestatus =~ s/0//gxsm;
        $tstate = $tstate =~ /a/ism ? "0a$thestatus" : "0$thestatus";
        MessageTotals( 'load', $tnum );
        ${$tnum}{'threadstatus'} = $tstate;
        MessageTotals( 'update', $tnum );
    }

    $yyThreadLine =
      qq~$tnum|$tsub|$tname|$temail|$tdate|$treplies|$tusername|$ticon|$tstate~;

    if   ( $mip =~ /$user_ip/sm ) { $useredit_ip = $mip; }
    else                          { $useredit_ip = "$mip $user_ip"; }

    my ( @attachments, %post_attach, %del_filename );
    fopen( ATM, "+<$vardir/attachments.txt" );
    seek ATM, 0, 0;
    while (<ATM>) {
        if ( $_ =~ /^(\d+)\|(\d+)\|.+\|(.+)\|\d+\s+/sm ) {
            $del_filename{$3}++;
            if ( $threadid == $1 && $postid == $2 ) {
                $post_attach{$3} = $_;
            }
            else {
                push @attachments, $_;
            }
        }
    }

    my ( $file, $fixfile, @filelist, @newfilelist, $fixext );
    $allowattach ||= 0;
	if ( $allowattach > 0 ) {
    for my $y ( 1 .. $allowattach ) {
        if ($CGI_query) { $file = $CGI_query->upload("file$y"); }
        if ( $file
            && ( $FORM{"w_file$y"} eq 'attachnew' || !exists $FORM{"w_file$y"} )
          )
        {
            $fixfile = $file;
            $fixfile =~ s/.+\\([^\\]+)$|.+\/([^\/]+)$/$1/sm;
            $fixfile =~ s/[^0-9A-Za-z\+\-\.:_]/_/gsm;

            # replace all inappropriate with the "_" character.

            # replace . with _ in the filename except for the extension
            my $fixname = $fixfile;
            if ( $fixname =~ s/(.+)(\..+?)$/$1/sm ) {
                $fixext = $2;
            }

            my $spamdetected = spamcheck("$fixname");
            if ( !$staff ) {
                if ( $spamdetected == 1 ) {
                    ${ $uid . $username }{'spamcount'}++;
                    ${ $uid . $username }{'spamtime'} = $date;
                    UserAccount( $username, 'update' );
                    $spam_hits_left_count =
                      $post_speed_count - ${ $uid . $username }{'spamcount'};
                    foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                    fatal_error('tsc_alert');
                }
            }
            if ( $use_guardian && $string_on ) {
                @bannedstrings = split /\|/xsm, $banned_strings;
                foreach (@bannedstrings) {
                    chomp $_;
                    if ( $fixname =~ m/$_/ism ) {
                        fatal_error( 'attach_name_blocked', "($_)" );
                    }
                }
            }
            $fixext  =~ s/\.(pl|pm|cgi|php)/._$1/ism;
            $fixname =~ s/\./_/gxsm;
            $fixfile = qq~$fixname$fixext~;

            if ( $FORM{"w_filename$y"} ) {
                unlink qq~$uploaddir/$FORM{"w_filename$y"}~;
            }
            if ( !$overwrite ) {
                $fixfile = check_existence( $uploaddir, $fixfile );
            }
            elsif ( $overwrite == 2 && -e "$uploaddir/$fixfile" ) {
                foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                fatal_error(file_overwrite);
            }

            my $match = 0;
            if ( !$checkext ) { $match = 1; }
            else {
                foreach my $ext (@ext) {
                    if ( grep { /$ext$/ism } $fixfile ) {
                        $match = 1;
                        last;
                    }
                }
            }
            if ($match) {
                if (
                    $allowattach < 1
                    || ( ( $allowguestattach != 0 || $username eq 'Guest' )
                        && $allowguestattach != 1 )
                  )
                {
                    foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                    fatal_error('no_perm_att');
                }
            }
            else {
                foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                require Sources::Post;
                Preview("$fixfile $fatxt{'20'} @ext");
            }

            my ( $size, $buffer, $filesize, $file_buffer );
            while ( $size = read $file, $buffer, 512 ) {
                $filesize += $size;
                $file_buffer .= $buffer;
            }
            $limit ||= 0;
            if ( $limit > 0 && $filesize > ( 1024 * $limit ) ) {
                foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                require Sources::Post;
                Preview("$fatxt{'21'} $fixfile ("
                      . int( $filesize / 1024 )
                      . " KB) $fatxt{'21b'} "
                      . $limit );
            }
			$dirlimit ||= 0;
            if ($dirlimit > 0) {
                my $dirsize = dirsize($uploaddir);
                if ( $filesize > ( ( 1024 * $dirlimit ) - $dirsize ) ) {
                    foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                    require Sources::Post;
                    Preview(
                        "$fatxt{'22'} $fixfile ("
                          . (
                            int( $filesize / 1024 ) -
                              $dirlimit +
                              int( $dirsize / 1024 )
                          )
                          . " KB) $fatxt{'22b'}"
                    );
                }
            }

 # create a new file on the server using the formatted ( new instance ) filename
            if ( fopen( NEWFILE, ">$uploaddir/$fixfile" ) ) {
                binmode NEWFILE;

                # needed for operating systems (OS) Windows, ignored by Linux
                print {NEWFILE} $file_buffer
                  or croak "$croak{'print'} NEWFILE";    # write new file on HD
                fclose(NEWFILE);

            }
            else
            { # return the server's error message if the new file could not be created
                foreach (@newfilelist) { unlink "$uploaddir/$_"; }
                fatal_error( 'file_not_open', "$uploaddir" );
            }

     # check if file has actually been uploaded, by checking the file has a size
            my $filesizekb = -s "$uploaddir/$fixfile";
            if ( !$filesizekb ) {
                foreach (qw("@newfilelist" $fixfile)) {
                    unlink "$uploaddir/$_";
                }
                fatal_error( 'file_not_uploaded', $fixfile );
            }
            $filesizekb = int( $filesizekb / 1024 );

            if ( $fixfile =~ /\.(jpg|gif|png|jpeg)$/ixsm ) {
                my $okatt = 1;
                if ( $fixfile =~ /gif$/ism ) {
                    my $header;
                    fopen( ATTFILE, "$uploaddir/$fixfile" );
                    read ATTFILE, $header, 10;
                    my $giftest;
                    ( $giftest, undef, undef, undef, undef, undef ) =
                      unpack 'a3a3C4', $header;
                    fclose(ATTFILE);
                    if ( $giftest ne 'GIF' ) { $okatt = 0; }
                }
                fopen( ATTFILE, "$uploaddir/$fixfile" );
                while ( read ATTFILE, $buffer, 1024 ) {
                    if ( $buffer =~ /<(html|script|body)/igsm ) {
                        $okatt = 0;
                        last;
                    }
                }
                fclose(ATTFILE);
                if ( !$okatt ) {   # delete the file as it contains illegal code
                    foreach (qw("@newfilelist" $fixfile)) {
                        unlink "$uploaddir/$_";
                    }
                    fatal_error( 'file_not_uploaded',
                        "$fixfile <= illegal code inside image file!" );
                }
            }

            push @newfilelist, $fixfile;
            push @filelist,    $fixfile;
            push @attachments,
qq~$threadid|$postid|$subject|$mname|$currentboard|$filesizekb|$date|$fixfile|0\n~;

        }
        elsif ( $FORM{"w_filename$y"} ) {
            if ( $FORM{"w_file$y"} eq 'attachdel' ) {
                if ( $del_filename{ $FORM{"w_filename$y"} } == 1 ) {
                    unlink qq~$uploaddir/$FORM{"w_filename$y"}~;
                }
                $del_filename{ $FORM{"w_filename$y"} }--;
            }
            elsif ( $FORM{"w_file$y"} eq 'attachold' ) {
                push @filelist,    $FORM{"w_filename$y"};
                push @attachments, $post_attach{ $FORM{"w_filename$y"} };
            }
        }
    }

    # Print attachments.txt
    truncate ATM, 0;
    seek ATM, 0, 0;
    print {ATM} sort { ( split /\|/xsm, $a )[6] <=> ( split /\|/xsm, $b )[6] }
      @attachments
      or croak "$croak{'print'} ATM";
    fclose(ATM);

    # Create the list of files
    $fixfile = join q{,}, @filelist;

    ${ $thread_arrayref{$threadid} }[$postid] =
qq~$subject|$mname|$memail|$mdate|$musername|$icon|0|$useredit_ip|$message|$ns|$date|$username|$fixfile\n~;
    fopen( FILE, ">$datadir/$threadid.txt" )
      or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
    print {FILE} @{ $thread_arrayref{$threadid} }
      or croak "$croak{'print'} FILE";
    fclose(FILE);
	}

    if ( $postid == 0 || $staff ) {

# Save the current board. icon, status or subject may have changed -> update board info
        fopen( BOARD, "+<$boardsdir/$currentboard.txt" )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        my @board = <BOARD>;
        for my $c ( 0 .. ( @board - 1 ) ) {
            if ( $board[$c] =~ m{\A$threadid\|}osm ) {
                $board[$c] = "$yyThreadLine\n";
                last;
            }
        }
        truncate BOARD, 0;
        seek BOARD, 0, 0;
        print {BOARD} @board or croak "$croak{'print'} BOARD";
        fclose(BOARD);

        BoardSetLastInfo( $currentboard, \@board );

    }
    elsif ( $postid == $#{ $thread_arrayref{$threadid} } ) {

        # maybe last message changed subject and/or icon -> update board info
        fopen( BOARD, "$boardsdir/$currentboard.txt" )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        my @board = <BOARD>;
        fclose(BOARD);
        BoardSetLastInfo( $currentboard, \@board );
    }

    require Sources::Notify;
    if ($notify) {
        ManageThreadNotify( 'add', $threadid, $username,
            ${ $uid . $username }{'language'},
            1, 1 );
    }
    else {
        ManageThreadNotify( 'delete', $threadid, $username );
    }

    if ( ${ $uid . $username }{'postlayout'} ne
"$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}"
      )
    {
        ${ $uid . $username }{'postlayout'} =
"$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}";
        UserAccount( $username, 'update' );
    }

    $maxmessagedisplay ||= 10;
    my $start =
      !$ttsreverse
      ? ( int( $postid / $maxmessagedisplay ) * $maxmessagedisplay )
      : $treplies -
      (
        int( ( $treplies - $postid ) / $maxmessagedisplay ) *
          $maxmessagedisplay );
    my $rts = $FORM{'return_to'};
    if ( $rts == 3 ) {
        $yySetLocation = qq~$scripturl~;
    }
    elsif ( $rts == 2 ) {
        $yySetLocation = qq~$scripturl?board=$currentboard~;
    }
    else {
        $yySetLocation = qq~$scripturl?num=$threadid/$start#$postid~;
    }
    redirectexit();
    return;
}

sub MultiDel {    # deletes single- or multi-Posts
    $thread = $INFO{'thread'};

    if ( !ref $thread_arrayref{$thread} ) {
        fopen( FILE, "$datadir/$thread.txt" )
          or fatal_error( 'cannot_open', "$datadir/$thread.txt", 1 );
        @{ $thread_arrayref{$thread} } = <FILE>;
        fclose(FILE);
    }
    my @messages = @{ $thread_arrayref{$thread} };

    # check all checkboxes, delete posts if checkbox is ticked
    my $kill = 0;
    my $postid;
    foreach my $count ( reverse 0 .. $#messages ) {
        if ( $FORM{"del$count"} ne q{} ) {
            chomp $messages[$count];
            @message = split /\|/xsm, $messages[$count];
            $musername = $message[4];

            # Checks that the user is actually allowed to access multidel
            if (
                ${ $uid . $username }{'regdate'} > $message[3]
                || (  !$staff
                    && $musername ne $username )
                || !$sessionvalid
              )
            {
                fatal_error('delete_not_allowed');
            }
            if (  !$staff
                && $tlnodelflag
                && $date > $message[3] + ( $tlnodeltime * 3600 * 24 ) )
            {
                fatal_error( 'time_locked', "$tlnodeltime$timelocktxt{'02a'}" );
            }

            if ( $message[12] ) {    # delete post attachments
                require Admin::Attachments;
                my %remattach;
                $message[12] =~ s/,/|/gxsm;
                $remattach{$thread} = $message[12];
                RemoveAttachments( \%remattach );
            }

            splice @messages, $count, 1;
            $kill++;
            if ( $kill == 1 ) { $postid = $count; }

            # decrease members post count if not in a zero post count board
            if (   !${ $uid . $currentboard }{'zero'}
                && $musername  ne 'Guest'
                && $message[6] ne 'no_postcount' )
            {
                if ( !${ $uid . $musername }{'password'} ) {
                    LoadUser($musername);
                }
                if ( ${ $uid . $musername }{'postcount'} > 0 ) {
                    ${ $uid . $musername }{'postcount'}--;
                    UserAccount( $musername, 'update' );
                }
                if ( ${ $uid . $musername }{'position'} ) {
                    $grp_after = qq~${$uid.$musername}{'position'}~;
                }
                else {
                    foreach
                      my $postamount ( reverse sort { $a <=> $b } keys %Post )
                    {
                        if ( ${ $uid . $musername }{'postcount'} > $postamount )
                        {
                            ( $grp_after, undef ) =
                              split /\|/xsm, $Post{$postamount}, 2;
                            last;
                        }
                    }
                }
                ManageMemberinfo( 'update', $musername, q{}, q{}, $grp_after,
                    ${ $uid . $musername }{'postcount'} );

                my ( $md, $mu, $mdmu );
                foreach ( reverse @messages ) {
                    ( undef, undef, undef, $md, $mu, undef ) = split /\|/xsm,
                      $_, 6;
                    if ( $mu eq $musername ) { $mdmu = $md; last; }
                }
                Recent_Write( 'decr', $thread, $musername, $mdmu );
            }
        }
    }

    if ( !@messages ) {

        # all post was deleted, call removethread
        require Sources::Favorites;
        $INFO{'ref'} = 'delete';
        RemFav($thread);

        require Sources::RemoveTopic;
        $iamposter = ( $message[4] eq $username ) ? 1 : 0;
        DeleteThread($thread);
    }
    @{ $thread_arrayref{$thread} } = @messages;

# if thread has not been deleted: update thread, update message index details ...
    fopen( FILE, ">$datadir/$thread.txt" )
      or fatal_error( 'cannot_open', "$datadir/$thread.txt", 1 );
    print {FILE} @{ $thread_arrayref{$thread} } or croak "$croak{'print'} FILE";
    fclose(FILE);

    my @firstmessage = split /\|/xsm, ${ $thread_arrayref{$thread} }[0];
    my @lastmessage = split /\|/xsm,
      ${ $thread_arrayref{$thread} }[ $#{ $thread_arrayref{$thread} } ];

    # update the current thread
    MessageTotals( 'load', $thread );
    ${$thread}{'replies'} = $#{ $thread_arrayref{$thread} };
    ${$thread}{'lastposter'} =
      $lastmessage[4] eq 'Guest' ? qq~Guest-$lastmessage[1]~ : $lastmessage[4];
    MessageTotals( 'update', $thread );

    # update the current board.
    BoardTotals( 'load', $currentboard );
    ${ $uid . $currentboard }{'messagecount'} -= $kill;

    # &BoardTotals("update", ...) is done later in &BoardSetLastInfo

    my $threadline = q{};
    fopen( BOARDFILE, "+<$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    my @buffer = <BOARDFILE>;

    for my $c ( 0 .. ( @buffer - 1 ) ) {
        if ( $buffer[$c] =~ /^$thread\|/xsm ) {
            $threadline = $buffer[$c];
            splice @buffer, $c, 1;
            last;
        }
    }

    chomp $threadline;
    my @newthreadline = split /\|/xsm, $threadline;
    $newthreadline[1] = $firstmessage[0];         # subject of first message
    $newthreadline[7] = $firstmessage[5];         # icon of first message
    $newthreadline[4] = $lastmessage[3];          # date of last message
    $newthreadline[5] = ${$thread}{'replies'};    # replay number

    my $inserted = 0;
    for my $c ( 0 .. ( @buffer - 1 ) ) {
        if ( ( split /\|/xsm, $buffer[$a], 6 )[4] < $newthreadline[4] ) {
            splice @buffer, $c, 0, join( q{|}, @newthreadline ) . "\n";
            $inserted = 1;
            last;
        }
    }
    if ( !$inserted ) { push @buffer, join( q{|}, @newthreadline ) . "\n"; }

    truncate BOARDFILE, 0;
    seek BOARDFILE, 0, 0;
    print {BOARDFILE} @buffer or croak "$croak{'print'} BOARD";
    fclose(BOARDFILE);

    BoardSetLastInfo( $currentboard, \@buffer );

    $postid =
      $postid > ${$thread}{'replies'} ? ${$thread}{'replies'} : ( $postid - 1 );

    $maxmessagedisplay ||= 10;
    my $start =
      !$ttsreverse
      ? ( int( $postid / $maxmessagedisplay ) * $maxmessagedisplay )
      : ${$thread}{'replies'} -
      (
        int( ( ${$thread}{'replies'} - $postid ) / $maxmessagedisplay ) *
          $maxmessagedisplay );
    $yySetLocation = qq~$scripturl?num=$thread/$start#$postid~;

    redirectexit();
    return;
}

1;
