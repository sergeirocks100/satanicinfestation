###############################################################################
# Decoder.pm                                                                  #
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

$decoderpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub scramble {
    my ( $input, $user ) = @_;
    if ( $user eq q{} ) { return; }

    # creating a codekey based on userid
    my $carrier = q{};
    for my $n ( 0 .. length $user ) {
        my $ascii = substr $user, $n, 1;
        $ascii = ord $ascii;
        $carrier .= $ascii;
    }
    while ( length($carrier) < length $input ) { $carrier .= $carrier; }
    $carrier = substr $carrier, 0, length $input;
    my $scramble = encode_password( rand 100 );
    for my $n ( 0 .. 9 ) {
        $scramble .= encode_password($scramble);
    }
    $scramble =~ s/\//y/gxsm;
    $scramble =~ s/\+/x/gxsm;
    $scramble =~ s/\-/Z/gxsm;
    $scramble =~ s/\:/Q/gxsm;

    # making a mess of the input
    my $lastvalue = 3;
    for my $n ( 0 .. length $input ) {
        $value = ( substr $carrier, $n, 1 ) + $lastvalue + 1;
        $lastvalue = $value;
        substr( $scramble, $value, 1 ) = substr $input, $n, 1;
    }

    # adding code length to code
    my $len = length($input) + 65;
    $scramble .= chr $len;
    return $scramble;
}

sub descramble {
    my ( $input, $user ) = @_;
    if ( $user eq q{} ) { return; }

    # creating a codekey based on userid
    my $carrier = q{};
    for my $n ( 0 .. ( length($user) - 1 ) ) {
        my $ascii = substr $user, $n, 1;
        $ascii = ord $ascii;
        $carrier .= $ascii;
    }
    my $orgcode = substr $input, length($input) - 1, 1;
    my $orglength = ord $orgcode;

    while ( length($carrier) < ( $orglength - 65 ) ) { $carrier .= $carrier; }
    $carrier = substr $carrier, 0, length $input;

    my $lastvalue  = 3;
    my $descramble = q{};

    # getting code length from encrypted input
    for my $n ( 0 .. ( $orglength - 66 ) ) {
        my $value = ( substr $carrier, $n, 1 ) + $lastvalue + 1;
        $lastvalue = $value;
        $descramble .= substr $input, $value, 1;
    }
    return $descramble;
}

sub validation_check {
    my ($checkcode) = @_;
    if ( $checkcode eq q{} ) { fatal_error('no_verification_code'); }
    if ( $checkcode !~ /\A[0-9A-Za-z]+\Z/xsm ) {
        fatal_error('invalid_verification_code');
    }
    if ( testcaptcha( $FORM{'sessionid'} ) ne $checkcode ) {
        fatal_error('wrong_verification_code');
    }
    return;
}

sub validation_code {

    # set the max length of the shown verification code
    my ( $firstCharsLen, $lastCharsLen );
    if ($captchaStartChars) { $firstCharsLen = length $captchaStartChars; }
    if ($captchaEndChars)   { $lastCharsLen  = length $captchaEndChars; }
    if ( $captchaStartChars && $captchaEndChars ) {
        $flood_text =
qq~$floodtxt{'casewarning_1'}$floodtxt{'casewarning_2'} $firstCharsLen $floodtxt{'casewarning_4'} $lastCharsLen $floodtxt{'casewarning_5'}~;
    }
    elsif ($captchaStartChars) {
        $flood_text =
qq~$floodtxt{'casewarning_1'}$floodtxt{'casewarning_2'} $firstCharsLen $floodtxt{'casewarning_5'}~;
    }
    elsif ($captchaEndChars) {
        $flood_text =
qq~$floodtxt{'casewarning_1'}$floodtxt{'casewarning_3'} $lastCharsLen $floodtxt{'casewarning_5'}~;
    }
    else {
        $flood_text = qq~$floodtxt{'casewarning'}~;
    }
    if ( !$codemaxchars || $codemaxchars < 3 ) { $codemaxchars = 3; }
    $codemaxchars2 = $codemaxchars + int rand 2;
    ## Generate a random string
    $captcha = keygen( $codemaxchars2, $captchastyle );
    ## now we are going to spice the captcha with the formsession
    $sessionid = scramble( $captcha, $masterkey );
    chomp $sessionid;

    $showcheck .=
qq~<img src="$scripturl?action=$randaction;$randaction=$sessionid" alt="" /><input type="hidden" name="sessionid" value="$sessionid" />~;
    return $sessionid;
}

sub testcaptcha {
    my ($testcode) = @_;
    chomp $testcode;
    ## now it is time to decode the session and see if we have a valid code ##
    my $out = descramble( $testcode, $masterkey );
    chomp $out;
    return $out;
}

sub convert {
    require Sources::Captcha;
    my ( $startChars, $endChars );
    if ($captchaStartChars) { $startChars = $captchaStartChars; }
    if ($captchaEndChars)   { $endChars   = $captchaEndChars; }
    $captcha = testcaptcha( $INFO{$randaction} );
    captcha( $startChars . $captcha . $endChars );
    return;
}

1;
