###############################################################################
# Sessions.pm                                                                 #
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

$sessionspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Sessions');
get_micon();
get_template('Other');

sub SessionReval {
    if (   ${ $uid . $username }{'sesquest'} eq q{}
        || ${ $uid . $username }{'sesquest'} eq 'password' )
    {
        $sesremark =
          qq~<br /><br /><fieldset><i>$session_txt{'10'}</i></fieldset>~;
        $sesquestion = 'password';
        $sestype     = 'password';
    }
    else {
        $sesremark   = q{};
        $sesquestion = "${$uid.$username}{'sesquest'}";
        $sestype     = 'text';
    }

    $yymain .= $my_sessions;
    $yymain =~ s/{yabb sesremark}/$sesremark/sm;
    $yymain =~ s/{yabb sestype}/$sestype/sm;
    $yymain =~ s/{yabb sesstext3}/$session_txt{'3'}/sm;
    $yymain =~ s/{yabb sesstext4}/$session_txt{'4'}/sm;
    $yymain =~ s/{yabb sesquestion}/$sesquest_txt{$sesquestion}/sm;
    $yymain =~ s/{yabb sesredir}/$INFO{'sesredir'}/sm;
    $yytitle   = "$img_txt{'34a'}";
    template();
    return;
}

sub SessionReval2 {
#    require Sources::Decoder;
    $FORM{'cookielength'}   = 360;
    $FORM{'cookieneverexp'} = 1;
    if ( $FORM{'sesanswer'} eq q{} ) { fatal_error('no_secret_answer'); }
    if (   ${ $uid . $username }{'sesquest'} eq q{}
        || ${ $uid . $username }{'sesquest'} eq 'password' )
    {
        $question = ${ $uid . $username }{'password'};
        $answer   = encode_password("$FORM{'sesanswer'}");
        chomp $answer;
    }
    else {
        $question = encode_password( ${ $uid . $username }{'sesanswer'} );
        $answer =   encode_password( $FORM{'sesanswer'} );

        #       bug fix courtesy Derek Barnstorm;
        chomp $answer;
    }
    if ( $answer ne $question ) {
        UpdateCookie('delete');

        $username = 'Guest';
        $iamguest = '1';
        $iamadmin = q{};
        $iamgmod  = q{};
        $password = q{};
        $yyim     = q{};
        local $ENV{'HTTP_COOKIE'} = q{};
        $yyuname     = q{};
        $formsession = cloak("$mbname$username");

        require Sources::LogInOut;
        $sharedLogin_text = $session_txt{'6'};
        $action           = 'login';
        Login();
    }
    else {
        $iamadmin =
          ${ $uid . $username }{'position'} eq 'Administrator' ? 1 : 0;
        $iamgmod =
          ${ $uid . $username }{'position'} eq 'Global Moderator' ? 1 : 0;
        $sessionvalid = 1;
    }
    if ( $FORM{'cookielength'} < 1 || $FORM{'cookielength'} > 9999 ) {
        $FORM{'cookielength'} = $Cookie_Length;
    }
    if ( !$FORM{'cookieneverexp'} ) { $ck{'len'} = "\+$FORM{'cookielength'}m"; }
    else { $ck{'len'} = 'Sunday, 17-Jan-2038 00:00:00 GMT'; }
    ${ $uid . $username }{'session'} = encode_password($user_ip);
    chomp ${ $uid . $username }{'session'};
    UserAccount( $username, 'update' );
    UpdateCookie(
        'write', $username,
        ${ $uid . $username }{'password'},
        ${ $uid . $username }{'session'},
        q{/}, $ck{'len'}
    );

    $redir = q{};
    if ( $FORM{'sredir'} ) {
        my $tmpredir = $FORM{'sredir'};
        $tmpredir =~ s/\~/\=/gxsm;
        $tmpredir =~ s/x3B/;/gxsm;
        $tmpredir =~ s/search2/search/gxsm;
        $redir = qq~?$tmpredir~;
    }
    $yySetLocation = qq~$scripturl$redir~;
    redirectexit();
    return;
}

1;
