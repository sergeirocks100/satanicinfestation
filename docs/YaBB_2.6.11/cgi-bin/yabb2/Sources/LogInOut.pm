###############################################################################
# LogInOut.pm                                                                 #
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

$loginoutpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

if ($regcheck) { require Sources::Decoder; }
LoadLanguage('LogInOut');

$regstyle = q{};

sub Login {
    if ( !$iamguest && $sessionvalid == 1 ) {
        fatal_error( 'logged_in_already', $username );
    }
    $sharedLogin_title = $loginout_txt{'34'};
    $yymain .= sharedLogin() . q~<script type="text/javascript">
    document.loginform.username.focus();
</script>~;
    $yytitle = $loginout_txt{'34'};
    template();
    return;
}

sub Login2 {
    if ( !$iamguest && $sessionvalid == 1 ) {
        fatal_error( 'logged_in_already', $username );
    }
    if ( $FORM{'username'} eq q{} ) { fatal_error('no_username'); }
    if ( $FORM{'passwrd'}  eq q{} ) { fatal_error('no_password'); }
    $username = $FORM{'username'};
    $username =~ s/\s/_/gxsm;
    if ( $username =~ /[^ \w\x80-\xFF\[\]\(\)#\%\+,\-\|\.:=\?\@\^]/sm ) {
        $error_txt = isempty($loginout_txt{'35a'}, "$loginout_txt{'35'} $loginout_txt{'241'}");
        fatal_error( 'invalid_character',
            "$error_txt" );
    }

    ## Check if login ID is not an email address ##
    if ( !-e "$memberdir/$username.vars" ) {
        $test_id = MemberIndex( 'who_is', "$FORM{'username'}" );
        if ( $test_id ) { $username = $test_id; }
    }

    if ( -e "$memberdir/$username.pre" && ( $regtype == 1 || $regtype == 2 ) ) {
        fatal_error('not_activated');
    }
    elsif ( -e "$memberdir/$username.wait" && $regtype == 1 ) {
        fatal_error('prereg_wait');
    }
    elsif ( !-e "$memberdir/$username.vars" ) { fatal_error('bad_credentials'); }

    if ( -e "$memberdir/$username.pre" && -e "$memberdir/$username.vars" ) {
        unlink "$memberdir/$username.pre";
    }

    # Need to do this to get correct case of user ID,
    # for case insensitive systems. Can cause weird issues otherwise
    $caseright = 0;
    ManageMemberlist('load');
    while ( ( $curmemb, $value ) = each %memberlist ) {
        if ( $username eq $curmemb ) { $caseright = 1; last; }
    }
    undef %memberlist;

    if ( !$caseright ) {
        $username = 'Guest';
        fatal_error('bad_credentials');
    }

    if ( -e "$memberdir/$username.vars" ) {
        LoadUser($username);
        my $spass     = ${ $uid . $username }{'password'};
        my $cryptpass = encode_password("$FORM{'passwrd'}");

        # convert non encrypted password to MD5 encrypted one
        if ( $spass eq $FORM{'passwrd'} && $spass ne $cryptpass ) {

            # only encrypt the password if it's not already MD5 encrypted
            # MD5 hashes in YaBB are always 22 chars long (base64)
            if ( length( ${ $uid . $username }{'password'} ) != 22 ) {
                ${ $uid . $username }{'password'} = $cryptpass;
                UserAccount($username);
                $spass = $cryptpass;
            }
        }
        if ( $spass ne $cryptpass ) {
            $username = 'Guest';
            fatal_error('bad_credentials');
        }
    }
    else {
        $username = 'Guest';
        fatal_error('bad_credentials');
    }

    $iamadmin = ${ $uid . $username }{'position'} eq 'Administrator'    ? 1 : 0;
    $iamgmod  = ${ $uid . $username }{'position'} eq 'Global Moderator' ? 1 : 0;
    $sessionvalid = 1;
    $iamguest     = 0;

    if ( $maintenance && !$iamadmin ) {
        $username = 'Guest';
        fatal_error('admin_login_only');
    }
    banning();

    if ( $FORM{'cookielength'} == 1 ) {
        $ck{'len'} = 'Sunday, 17-Jan-2038 00:00:00 GMT';
    }
    else { $ck{'len'} = q{}; }

    ${ $uid . $username }{'session'} = encode_password($user_ip);
    UpdateCookie(
        'write', $username,
        encode_password( $FORM{'passwrd'} ),
        ${ $uid . $username }{'session'},
        q{/}, $ck{'len'}
    );

    UserAccount( $username, 'update', q{-} );

    # "-" to not update 'lastonline' here
    buildIMS( $username, 'load' );    # isn't loaded because was Guest before
    buildIMS( $username, q{} );

    # rebuild the Members/$username.ims file on login
    WriteLog();

    if ( $FORM{'sredir'} ) {
        $FORM{'sredir'} =~ s/\~/\=/gxsm;
        $FORM{'sredir'} =~ s/x3B/;/gsm;
        $FORM{'sredir'} =~ s/search2/search/gsm;
        $FORM{'sredir'} = qq~?$FORM{'sredir'}~;
        if ( $FORM{'sredir'} =~
            /action=(register|login2|reminder|reminder2)/xsm )
        {
            $FORM{'sredir'} = q{};
        }
    }
    $yySetLocation = qq~$scripturl$FORM{'sredir'}~;
    redirectexit();
    return;
}

sub Logout {
    if ( $username ne 'Guest' ) {
        RemoveUserOnline($username);    # Remove user from online log
        UserAccount( $username, 'update', 'lastonline' );
    }

    UpdateCookie('delete');
    $yySetLocation = $guestaccess ? $scripturl : qq~$scripturl?action=login~;
    $username = 'Guest';
    redirectexit();
    return;
}

sub sharedLogin {
    get_template('Loginout');
    if ( $action eq 'login' || $maintenance ) {
        $yynavigation = qq~&rsaquo; $loginout_txt{'34'}~;
    }

    #cookie length is now all or nothing.
    if ( $sharedLogin_title ne q{} ) {
        $sharedlog = $mysharedloga;
        $sharedlog =~ s/{yabb sharedLogin_title}/$sharedLogin_title/sm;
        if ( $sharedLogin_text ne q{} ) {
            $sharedlog .= $mysharedlogb;
            $sharedlog =~ s/{yabb sharedLogin_text}/$sharedLogin_text/sm;
        }
        $sharedlog .= $mysharedlogc;
        $sharedbot = $myborder_bottom;
    }
    else {
        $sharedlog = $mysharedlog_top;
        $sharedbot = $mysharedbot;
    }
    if ($maintenance) { $hide_passlink = ' style="visibility: hidden;"' }
    if ( $maintenance || !$regtype ) {
        $hide_reglink = ' style="visibility: hidden;"';;
    }
    $sharedlog .= qq~
            <form id="loginform" name="loginform" action="$scripturl?action=login2" method="post" accept-charset="$yymycharset">
                <input type="hidden" name="sredir" value="$INFO{'sesredir'}" />
    $mysharedlog_bodya
    $sharedbot~;
    $sharedlog =~ s/{yabb regstyle}/$regstyle/sm;
    $sharedlog =~ s/{yabb hide_reglink}/$hide_reglink/gsm;
    $sharedlog =~ s/{yabb hide_passlink}/$hide_passlink/gsm;
    my $cookielength_sel = q{};
    if ( $Cookie_Length  ) { $cookielength_sel = ' checked="checked"'}
    $sharedlog =~ s/{yabb cookielength_sel}/$cookielength_sel/gsm;
    $loginform         = 1;
    $sharedLogin_title = q{};
    $sharedLogin_text  = q{};
    return $sharedlog;
}

sub Reminder {
    if ( !$iamguest && $sessionvalid == 1 ) {
        fatal_error( 'logged_in_already', $username );
    }
    get_template('Loginout');

    $yymain .= qq~<br /><br />
<form action="$scripturl?action=reminder2" method="post" name="reminder" onsubmit="return CheckReminderField();" accept-charset="$yymycharset">
$myremindera~;
    $yymain =~ s/{yabb mbname}/$mbname/sm;
    $yymain =~ s/{yabb regstyle}/$regstyle/sm;

    if ($regcheck) {
        validation_code();
        $yymain .= $myreminder_regcheck;
        $yymain =~ s/{yabb flood_text}/$flood_text/sm;
        $yymain =~ s/{yabb showcheck}/$showcheck/sm;
    }
    if ( $spam_questions_send && -e "$langdir/$language/spam.questions" ) {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$loginout_txt{'verification_question_case'}~;
        }
        $yymain .= $myreminder_vericheck;
        $yymain =~ s/{yabb spam_question}/$spam_question/sm;
        $yymain =~ s/{yabb spam_question_id}/$spam_question_id/sm;
        $yymain =~ s/{yabb spam_question_image}/$spam_image/sm;
        $yymain =~
          s/{yabb verification_question_desc}/$verification_question_desc/sm;
    }

    $yymain .= $myreminder_endform;
    $yymain .= qq~
<script type="text/javascript">
    document.reminder.user.focus();

    function CheckReminderField() {
        if (document.reminder.user.value == '') {
            alert("$loginout_txt{'error_user_info'}");
            document.reminder.user.focus();
            return false;
        }~ .

      (
        $regcheck
        ? qq~
        if (document.reminder.verification.value == '') {
            alert("$loginout_txt{'error_verification'}");
            document.reminder.verification.focus();
            return false;
        }~
        : q{}
      )
      .

      (
        $spam_questions_send && -e "$langdir/$language/spam.questions"
        ? qq~
        if (document.reminder.verification_question.value == '') {
            alert("$loginout_txt{'error_verification_question'}");
            document.reminder.verification_question.focus();
            return false;
        }~
        : q{}
      )

      . q~
        return true;
    }
</script>
<br /><br />
~;

    $yytitle      = $loginout_txt{'669'};
    $yynavigation = qq~&rsaquo; $loginout_txt{'669'}~;
    template();
    return;
}

sub Reminder2 {
    if ( !$FORM{'user'} ) {
        fatal_error( q{}, "$loginout_txt{'error_user_info'}" );
    }

    if ( !$iamguest && $sessionvalid == 1 && !$iamadmin ) {
        fatal_error( 'logged_in_already', $username );
    }

    # generate random ID for password reset.
    my $randid = keygen( 8, 'A' );

    if ( $regcheck && !$iamadmin ) {
        validation_check( $FORM{'verification'} );
    }
    if ( $spam_questions_send && -e "$langdir/$language/spam.questions" ) {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    }

    my $user = $FORM{'user'};
    $user =~ s/\s/_/gxsm;

    if ( !-e "$memberdir/$user.vars" ) {
        $test_id = MemberIndex( 'who_is', $FORM{'user'} );
        if ($test_id) { $user = $test_id; }
        else { fatal_error( q{}, "$loginout_txt{'no_user_info_exists'}" ); }
    }

    # Fix to make it load in their own language
    LoadUser($user);
    if ( !${ $uid . $user }{'email'} ) { fatal_error('corrupt_member_file'); }

    $username = $user;
    WhatLanguage();
    LoadLanguage('LogInOut');
    LoadLanguage('Email');
    undef $username;

    $userfound = 0;

    if ( -e "$memberdir/forgotten.passes" ) {
        require "$memberdir/forgotten.passes";
    }
    if ( exists $pass{$user} ) { delete $pass{$user}; }
    $pass{"$user"} = $randid;

    fopen( FILE, ">$memberdir/forgotten.passes" )
      or fatal_error( 'cannot_open', "$memberdir/forgotten.passes", 1 );
    while ( ( $key, $value ) = each %pass ) {
        print {FILE} qq~\$pass{'$key'} = '$value';\n~
          or croak "$croak{'print'} forgotten.passes";
    }
    print {FILE} '1;' or croak "$croak{'print'} forgotten.passes";
    fclose(FILE);

    $subject = "$mbname $loginout_txt{'36b'}: ${$uid.$user}{'realname'}";
    if   ($do_scramble_id) { $cryptusername = cloak($user); }
    else                   { $cryptusername = $user; }
    require Sources::Mailer;
    LoadLanguage('Email');
    my $message = template_email(
        $passwordreminderemail,
        {
            'displayname'   => ${ $uid . $user }{'realname'},
            'cryptusername' => $cryptusername,
            'remindercode'  => $randid
        }
    );
    sendmail( ${ $uid . $user }{'email'}, $subject, $message );
    get_template('Loginout');

    $yymain .= $myreminder2;
    $yymain =~ s/{yabb mbname}/$mbname/sm;
    $yymain =~ s/{yabb forum_user}/$FORM{'user'}/sm;

    $yytitle = "$loginout_txt{'669'}";
    template();
    return;
}

sub Reminder3 {
    $id = $INFO{'ID'};
    if   ($do_scramble_id) { $user = decloak( $INFO{'user'} ); }
    else                   { $user = $INFO{'user'}; }

    if ( $id !~ /[a-zA-Z0-9]+/xsm ) {
        fatal_error( 'invalid_character', "ID $loginout_txt{'241'}" );
    }
    if ( $user =~ /[^\w#\%\+\-\.\@\^]/xsm ) {
        fatal_error( 'invalid_character', "User $loginout_txt{'241'}" );
    }

    # generate a new random password as the old one is one-way encrypted.
    @chararray =
      qw(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
    my $newpassword;
    for my $i ( 0 .. 7 ) {
        $newpassword .= $chararray[ int rand 61 ];
    }

    # load old userdata
    LoadUser($user);

    # update forgotten passwords database
    require "$memberdir/forgotten.passes";
    if ( $pass{$user} ne $id ) { fatal_error('wrong_id'); }
    delete $pass{$user};
    fopen( FORGOTTEN, ">$memberdir/forgotten.passes" )
      or fatal_error( 'cannot_open', "$memberdir/forgotten.passes", 1 );
    while ( ( $key, $value ) = each %pass ) {
        print {FORGOTTEN} qq~\$pass{'$key'} = '$value';\n~
          or croak "$croak{'print'} FORGOTTEN";
    }
    print {FORGOTTEN} "\n1;" or croak "$croak{'print'} FORGOTTEN";
    fclose(FORGOTTEN);

    # add newly generated password to user data
    ${ $uid . $user }{'password'} = encode_password($newpassword);
    UserAccount( $user, 'update' );

    $FORM{'username'}     = $user;
    $FORM{'passwrd'}      = $newpassword;
    $FORM{'cookielength'} = 10;
    $FORM{'sredir'} =
qq*action~profileCheck2;redir~myprofile;username~$INFO{'user'};passwrd~$newpassword;newpassword~1*;
    Login2();
    return;
}

sub InMaintenance {
    if ( $maintenancetext ne q{} ) { $maintxt{'157'} = $maintenancetext; }
    $sharedLogin_title = "$maintxt{'114'}";
    $sharedLogin_text  = "<b>$maintxt{'156'}</b><br />$maintxt{'157'}";
    $yymain .= sharedLogin();
    $yytitle = "$maintxt{'155'}";
    template();
    return;
}

1;
