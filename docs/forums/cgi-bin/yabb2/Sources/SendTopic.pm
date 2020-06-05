###############################################################################
# SendTopic.pm                                                                #
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

$sendtopicpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

if ( !$sendtopicmail || $sendtopicmail == 2 ) { fatal_error('not_allowed'); }

if ($gpvalid_en && $iamguest) { require Sources::Decoder; }

LoadLanguage('SendTopic');
get_micon();
get_template('Display');

sub SendTopic {
    $topic = $INFO{'topic'};
    MessageTotals( 'load', $topic );
    $board = ${$topic}{'board'};
    if ( $board eq q{} || $board eq q{_} || $board eq q{ } ) {
        fatal_error('no_board_send');
    }
    if ( $topic eq q{} || $topic eq q{_} || $topic eq q{ } ) {
        fatal_error('no_topic_send');
    }
    if ($iamguest) { $focus_y_name = q~document.sendtopic.y_name.focus();~; }

    if ( !ref $thread_arrayref{$topic} ) {
        fopen( FILE, "$datadir/$topic.txt" )
          or fatal_error( 'cannot_open', "$datadir/$topic.txt", 1 );
        @{ $thread_arrayref{$topic} } = <FILE>;
        fclose(FILE);
    }
    $subject = ( split /\|/xsm, ${ $thread_arrayref{$topic} }[0], 2 )[0];

    if ($gpvalid_en && $iamguest) {
        validation_code();
        $my_valcode = $mysend_valcode;
        $my_valcode =~ s/{yabb showcheck}/$showcheck/sm;
        $my_valcode =~ s/{yabb flood_text}/$flood_text/sm;
    }
    if ( $spam_questions_gp && $iamguest && -e "$langdir/$language/spam.questions" ) {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$sendtopic_txt{'verification_question_case'}~;
        }
        $my_spam = $mysend_spam;
        $my_spam =~ s/{yabb spam_question}/$spam_question/sm;
        $my_spam =~
          s/{yabb verification_question_desc}/$verification_question_desc/sm;
        $my_spam =~ s/{yabb spam_question_id}/$spam_question_id/sm;
        $my_spam =~ s/{yabb spam_question_image}/$spam_image/sm;
    }

    $my_jschecks = qq~<script type="text/javascript">
    $focus_y_name

    function CheckSendTopicFields() {
        if (document.sendtopic.y_name.value == '') {
            alert("$sendtopic_txt{'error_sender_name'}");
            document.sendtopic.y_name.focus();
        return false;
        }
        if (document.sendtopic.y_email.value == '') {
            alert("$sendtopic_txt{'error_sender_email'}");
            document.sendtopic.y_email.focus();
        return false;
        }
        if (document.sendtopic.r_name.value == '') {
            alert("$sendtopic_txt{'error_recipient_name'}");
            document.sendtopic.r_name.focus();
        return false;
        }
        if (document.sendtopic.r_email.value == '') {
            alert("$sendtopic_txt{'error_recipient_email'}");
            document.sendtopic.r_email.focus();
        return false;
        }
        ~ . (
        $regcheck
        ? qq~
        if (document.sendtopic.verification.value == '') {
            alert("$sendtopic_txt{'error_verification'}");
            document.sendtopic.verification.focus();
            return false;
        }~
        : q{}
      )
      . (
        $spam_questions_send && -e "$langdir/$language/spam.questions"
        ? qq~
        if (document.sendtopic.verification_question.value == '') {
            alert("$sendtopic_txt{'error_verification_question'}");
            document.sendtopic.verification_question.focus();
            return false;
        }~
        : q{}
      )
      . q~
        return true;
    }
</script>~;

    $yymain .= $mysend_top;
    $yymain =~ s/{yabb subject}/$subject/sm;
    $yymain =~ s/{yabb realname}/${$uid.$username}{'realname'}/sm;
    $yymain =~ s/{yabb email}/${$uid.$username}{'email'}/sm;
    $yymain =~ s/{yabb my_valcode}/$my_valcode/sm;
    $yymain =~ s/{yabb my_spam}/$my_spam/sm;
    $yymain =~ s/{yabb my_jschecks}/$my_jschecks/sm;
    $yymain =~ s/{yabb board}/$board/sm;
    $yymain =~ s/{yabb topic}/$topic/sm;

    $yytitle =
"$sendtopic_txt{'707'}&nbsp; &#171; $subject &#187; &nbsp;$sendtopic_txt{'708'}";
    $yynavigation = qq~&rsaquo; $sendtopic_txt{'707'}~;
    template();
    return;
}

sub SendTopic2 {
    $topic = $FORM{'topic'};
    $board = $FORM{'board'};
    if ( $board eq q{} || $board eq q{_} || $board eq q{ } ) {
        fatal_error('no_board_send');
    }
    if ( $topic eq q{} || $topic eq q{_} || $topic eq q{ } ) {
        fatal_error('no_topic_send');
    }

    $yname  = $FORM{'y_name'};
    $rname  = $FORM{'r_name'};
    $yemail = $FORM{'y_email'};
    $remail = $FORM{'r_email'};
    $yname  =~ s/\A\s+//xsm;
    $yname  =~ s/\s+\Z//xsm;
    $yemail =~ s/\A\s+//xsm;
    $yemail =~ s/\s+\Z//xsm;
    $rname  =~ s/\A\s+//xsm;
    $rname  =~ s/\s+\Z//xsm;
    $remail =~ s/\A\s+//xsm;
    $remail =~ s/\s+\Z//xsm;

    if ( $yname eq q{} || $yname eq q{_} || $yname eq q{ } ) {
        fatal_error( 'no_name', "$sendtopic_txt{'335'}" );
    }
    if ( length($yname) > 25 ) {
        fatal_error( 'sendname_too_long', "$sendtopic_txt{'335'}" );
    }
    if ( $yemail eq q{} ) {
        fatal_error( 'no_email', "$sendtopic_txt{'336'}" );
    }
    if ( $yemail !~ /[\w\-\.\+]+\@[\w\-\.\+]+\.(\w{2,4}$)/sm ) {
        fatal_error( 'invalid_character',
            "$sendtopic_txt{'336'} $sendtopic_txt{'241'}" );
    }
    if (   ( $yemail =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/sm )
        || ( $yemail !~ /^.+@\[?(\w|[-.])+\.[a-zA-Z]{2,4}|[0-9]{1,4}\]?$/sm ) )
    {
        fatal_error( 'invalid_email', "$sendtopic_txt{'336'}" );
    }
    if ( $rname eq q{} || $rname eq q{_} || $rname eq q{ } ) {
        fatal_error( 'no_name', "$sendtopic_txt{'717'}" );
    }
    if ( length($rname) > 25 ) {
        fatal_error( 'sendname_too_long', "$sendtopic_txt{'717'}" );
    }
    if ( $remail eq q{} ) {
        fatal_error( 'no_email', "$sendtopic_txt{'718'}" );
    }
    if ( $remail !~ /[\w\-\.\+]+\@[\w\-\.\+]+\.(\w{2,4}$)/sm ) {
        fatal_error( 'invalid_character',
            "$sendtopic_txt{'718'} $sendtopic_txt{'241'}" );
    }
    if (   ( $remail =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/sm )
        || ( $remail !~ /^.+@\[?(\w|[-.])+\.[a-zA-Z]{2,4}|[0-9]{1,4}\]?$/sm ) )
    {
        fatal_error( 'invalid_email', "$sendtopic_txt{'718'}" );
    }

    if ($gpvalid_en && $iamguest) {
        validation_check( $FORM{'verification'} );
    }
    if ( $spam_questions_gp && $iamguest && -e "$langdir/$language/spam.questions" ) {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    } 
    if ( !ref $thread_arrayref{$topic} ) {
        fopen( FILE, "$datadir/$topic.txt" )
          or fatal_error( 'cannot_open', "$datadir/$topic.txt", 1 );
        @{ $thread_arrayref{$topic} } = <FILE>;
        fclose(FILE);
    }
    $subject = ( split /\|/xsm, ${ $thread_arrayref{$topic} }[0], 2 )[0];
    FromHTML($subject);
    require Sources::Mailer;
    LoadLanguage('Email');
    my $message = template_email(
        $sendtopicemail,
        {
            'toname'      => $rname,
            'subject'     => $subject,
            'displayname' => $yname,
            'num'         => $topic
        }
    );
    sendmail( $remail,
        "$sendtopic_txt{'118'}: $subject ($sendtopic_txt{'318'} $yname)",
        $message, $yemail );

    $yySetLocation = qq~$scripturl?num=$topic~;
    redirectexit();
    return;
}

1;
