###############################################################################
# Register.pm                                                                 #
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

$registerpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
if ( !$iamguest
    && ( !$admin && $action ne 'activate' && $action ne 'admin_descision' ) )
{
    fatal_error('no_registration_logged_in');
}

require Sources::Mailer;
LoadLanguage('Register');
LoadCensorList();

get_template('Register');

if ( $OSNAME =~ /Win/sm ) {
    my $regstyle = q~ style="text-transform: lowercase"~;
}
else {
    my $regstyle = q{};
}

sub Register {
    if ( $regtype == 0 && $iamguest ) { fatal_error('registration_disabled'); }
    if ( $RegAgree == 1 && $FORM{'regnoagree'} ) {
        $yySetLocation = qq~$scripturl~;
        redirectexit();
    }
    if ( $RegAgree == 1 && !$FORM{'regagree'} ) {
        $yytitle      = qq~$register_txt{'97'}~;
        $yynavigation = qq~&rsaquo; $register_txt{'97'}~;
        if ($language) {
            fopen( AGREE, "$langdir/$language/agreement.txt" );
        }
        else {
            fopen( AGREE, "$langdir/$lang/agreement.txt" );
        }
        @agreement = <AGREE>;
        fclose(AGREE);
        $fullagree = join q{}, @agreement;
        $fullagree =~ s/\n/<br \/>/gsm;
        $yymain .= $myregister_fullagree;
        $yymain =~ s/{yabb fullagree}/$fullagree/sm;
        template();
        exit;
    }
    my (
        $tmpregname,     $tmprealname, $tmpregemail,    $tmpregpasswrd1,
        $tmpregpasswrd2, $hidechecked, $reg_start_time, @birthdate
    );
    $yytitle      = $register_txt{'97'};
    $yynavigation = qq~&rsaquo; $register_txt{'97'}~;
    if ( $FORM{'reglanguage'} ) {
        $language = $FORM{'reglanguage'};
        LoadLanguage('Register');
    }
    if ( $FORM{'regusername'} ) { $tmpregname  = $FORM{'regusername'}; }
    if ( $FORM{'regrealname'} ) { $tmprealname = $FORM{'regrealname'}; }
    if ( $FORM{'email'} )       { $tmpregemail = $FORM{'email'}; }
    if ( $FORM{'hideemail'} || !exists $FORM{'hideemail'} ) {
        $hidechecked = q~ checked="checked"~;
    }
    if ( $FORM{'add_field0'} )  { $newfield       = $FORM{'add_field0'}; }
    if ( $FORM{'passwrd1'} )    { $tmpregpasswrd1 = $FORM{'passwrd1'}; }
    if ( $FORM{'passwrd2'} )    { $tmpregpasswrd2 = $FORM{'passwrd2'}; }
    if ( $FORM{'reason'} )      { $reason         = $FORM{'reason'}; }
    if ( $FORM{'birth_day'} )   { $birthdate[0]   = $FORM{'birth_day'}; }
    if ( $FORM{'birth_month'} ) { $birthdate[1]   = $FORM{'birth_month'}; }
    if ( $FORM{'birth_year'} )  { $birthdate[2]   = $FORM{'birth_year'}; }

    $min_reg_time ||= 0;
    if ( $min_reg_time > 0 ) {
        $reg_start_time =
          qq~<input type="hidden" name="reg_start_time" value="$date" />~;
    }

    if ( !$langopt ) { guestLangSel(); }

    if ( -e "$vardir/email_domain_filter.txt" ) {
        require "$vardir/email_domain_filter.txt";
    }
    if ($adomains) {
        @domains = split /\,/xsm, $adomains;
        $aedomains = $myaedomains_a;
        $aedomains =~ s/{yabb tmpregemail}/$tmpregemail/sm;
        foreach (@domains) {
            $aedomains .=
              ( $_ =~ m/\@/xsm )
              ? qq~<option value="$_">$_</option>~
              : qq~<option value="\@$_">&#64;$_</option>~;
        }
        $aedomains .= $myaedomains_b;
    }
    else {
        $aedomains .=
qq~<input type="text" maxlength="100" onchange="checkAvail('$scripturl',this.value,'email')" name="email" id="email" value="$tmpregemail" size="45" />~;
    }

    $yymain .= qq~
<script type="text/javascript" src="$yyhtml_root/ajax.js"></script>
<form action="$scripturl?action=register2" method="post" name="creator" onsubmit="return CheckRegFields();" accept-charset="$yymycharset">
    $reg_start_time~;
    if ( $RegAgree == 1 && $FORM{'regagree'} ) {
        $yymain .= q~
<input type="hidden" name="regagree" value="yes" />~;
    }
    $yymain .= $myregister_regfill_a;

    if ( $morelang > 1 ) {
        $yymain .= $myregister_morelang;
        $yymain =~ s/{yabb langopt}/$langopt/sm;
    }
    $newfield = q{};
## user name section
    $yymain .= $myregister_regfill_b;
    $yymain =~ s/{yabb tmpregname}/$tmpregname/sm;
    $yymain =~ s/{yabb regstyle}/$regstyle/sm;
    $yymain =~ s/{yabb language}/$language/sm;

    if ($name_cannot_be_userid) {
        $yymain .= qq~
            <br /><span class="small">$register_txt{'521'}</span>~;
    }

    $email2 = q{};
    if ( $imp_email_check == 1 ) {
        eval {
            require Net::DNS;
        };
        if (!$EVAL_ERROR ) {
            $email2 = $myregister_email2;
            $email2 =~ s/{yabb email2}/$register_txt{'70'}/sm;
        }
    }

    $yymain .= $myregister_avail;
    $yymain =~ s/{yabb tmprealname}/$tmprealname/sm;
    $yymain =~ s/{yabb aedomains}/$aedomains/sm;

    if ( $allow_hide_email == 1 ) {
        $yymain .= qq~
            <br /><input type="checkbox" name="hideemail" id="hideemail" value="1"$hidechecked /> <label for="hideemail">$register_txt{'721'}</label>
        ~;
    }
    $yymain .= $myregister_endrow;
    $yymain .= $email2;

    if ($birthday_on_reg) {
        my $editAgeTxt;
        if ( $editAgeLimit == 1 ) {
            $editAgeTxt =
              qq~<br /><span class="small">$register_txt{'birthday_c'}</span>~;
        }
        timetostring($date);
        if ( $timeselected =~ /[145]/xsm ) {
            $yymain .=
                $myregister_bdonreg
              . ( $birthday_on_reg == 2 ? $myreg_req : q{} )
              . qq~ <span class="small">$register_txt{'birthday_a'}</span>~;
        }
        else {
            $yymain .=
                $myregister_bdonreg_2
              . ( $birthday_on_reg == 2 ? $myreg_req : q{} )
              . qq~ <span class="small">$register_txt{'birthday_b'}</span>~;
        }
        $yymain =~ s/{yabb editAgeTxt}/$editAgeTxt/sm;
        $yymain =~ s/{yabb birthdate0}/$birthdate[0]/sm;
        $yymain =~ s/{yabb birthdate1}/$birthdate[1]/sm;
        $yymain =~ s/{yabb birthdate2}/$birthdate[2]/sm;

        $yymain .= $myregister_endrow;
    }

    if ($gender_on_reg == 1 ) {
        my $editGenderTxt;
        my $nongen_opt = q{};
        if ( $editGenderLimit == 1 ) {
            $editGenderTxt =
              qq~<br /><span class="small">$register_txt{'gender_edit'}</span>~;
        }
        if ( $gender_on_reg == 2 ) {
            $nongen_opt = $myreg_req;
        }

        $yymain .= $myregister_gender;
        $yymain =~ s/{yabb editGenderTxt}/$editGenderTxt/sm;
        $yymain =~ s/{yabb nongen_opt}/$nongen_opt/sm;
    }
    if ( !$emailpassword ) {
        $yymain .= password_check();
    }

    if ( $addmemgroup_enabled == 1 || $addmemgroup_enabled == 3 ) {
        my ( $addmemgroup, $selsize );
        foreach (@nopostorder) {
            my (
                $title, undef, undef, undef, undef, undef,
                undef,  undef, undef, undef, $additional
            ) = split /\|/xsm, $NoPost{$_};
            if ($additional) {
                $addmemgroup .= qq~<option value="$_">$title</option>~;
                $selsize++;
            }
        }
        $selsize = $selsize > 6 ? 6 : $selsize;
        my $additional_explain =
            $addmemgroup_enabled == 1
          ? $register_txt{'766'}
          : $register_txt{'767'};
        if ( $selsize > 1 ) { $additional_explain .= $register_txt{'767a'}; }

        if ($addmemgroup) {
            $yymain .= $myregister_addmem;
            $yymain =~ s/{yabb additional_explain}/$additional_explain/sm;
            $yymain =~ s/{yabb selsize}/$selsize/sm;
            $yymain =~ s/{yabb addmemgroup}/$addmemgroup/sm;
        }
    }

    if ( $regtype == 1 ) {
        $yymain .=
            $myregister_regreason_a
          . qq~            <textarea cols="60" rows="7" name="reason" id="reason">$reason</textarea>~
          . $myregister_regreason_c
          . length($RegReasonSymbols)
          . $myregister_regreason_b;
        $yymain =~ s/{yabb reason}/$reason/sm;
        $yymain =~ s/{yabb RegReasonSymbols}/$RegReasonSymbols/gsm;
    }

    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        my $reg_ext_prof = ext_register();
        $yymain .= $reg_ext_prof;
    }

    if ($regcheck) {
        require Sources::Decoder;
        validation_code();
        $yymain .= $myregister_regcheck;
        $yymain =~ s/{yabb flood_text}/$flood_text/sm;
        $yymain =~ s/{yabb showcheck}/$showcheck/sm;
    }
    if ( $en_spam_questions && -e "$langdir/$language/spam.questions" ) {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$register_txt{'verification_question_case'}~;
        }
        $yymain .= $myregister_spamquest;

        $yymain =~ s/{yabb spam_question}/$spam_question/sm;
        $yymain =~
          s/{yabb verification_question_desc}/$verification_question_desc/sm;
        $yymain =~ s/{yabb spam_question_id}/$spam_question_id/sm;
        $yymain =~ s/{yabb spam_question_image}/$spam_image/sm;
    }
    if ( $honeypot == 1 ) {
        fopen( HONEY, "<$langdir/$language/honey.txt" )
          or fatal_error( 'cannot_open', "$langdir/$language/honey.txt", 1 );
        @honey = <HONEY>;
        fclose(HONEY);
        chomp @honey;
        $hony      = int rand $#honey;
        $newfieldb = $honey[$hony];

        $yymain .= $myregister_honey;
        $yymain =~ s/{yabb newfieldb}/$newfieldb/sm;
        $yymain =~ s/{yabb newfield}/$newfield/sm;
    }

    # SpamFruits courtesy of Carsten Dalgaard #
    if ( $spamfruits == 1 ) {
        my @fruits =
          ( $fruittxt{'2'}, $fruittxt{'3'}, $fruittxt{'4'}, $fruittxt{'5'} );
        my $rdn = int rand 4;
        $fruit = $fruits[$rdn];
        $yymain .= $myregister_fruits;
        $yymain =~ s/{yabb fruit}/$fruit/gsm;
        $yymain .= qq~
                <script type="text/javascript">
                    function ShowFruits() {
                        var visfruits = "<html><head><link rel='stylesheet' href='$extpagstyle' type='text/css' /></head><body class='windowbg2'> ";
                        visfruits += "<img src='$defaultimagesdir/fruits.png' width='290' height='75' name='fruitsview' id='fruitsview' style='position: absolute; top: 0px; left: 0px; cursor: pointer;' alt='' onclick='FruitClick(event)' /> ";
                        visfruits += "<img src='$defaultimagesdir/fruitcheck.png' id='frmarker' style='z-index: 2; display: none;'> ";
                        visfruits += "<script type='text/javascript'> "
                        visfruits += "var xcor = 0; "
                        visfruits += "var ycor = 0; "
                        visfruits += "var mrkpos = 30; "
                        visfruits += "function FruitClick(event) \{ "
                        visfruits += "xcor = (event.clientX); "
                        visfruits += "ycor = (event.clientY); "
                        visfruits += "if(xcor > 0) mrkpos = 30; "
                        visfruits += "if(xcor > 75) mrkpos = 100; "
                        visfruits += "if(xcor > 145) mrkpos = 170; "
                        visfruits += "if(xcor > 215) mrkpos = 240; "
                        visfruits += "document.getElementById('frmarker').style.display = 'block'; "
                        visfruits += "document.getElementById('frmarker').style.position = 'absolute'; "
                        visfruits += "document.getElementById('frmarker').style.left = mrkpos + 'px'; "
                        visfruits += "document.getElementById('frmarker').style.top = '67px'; "
                        visfruits += "parent.document.creator.ycord.value = ycor; "
                        visfruits += "parent.document.creator.xcord.value = xcor; "
                        visfruits += "\} "
                        visfruits += "<\\/script> <\\/body> <\\/html>";
                        fruits.document.open("text/html");
                        fruits.document.write(visfruits);
                        fruits.document.close();
                    }
                    ShowFruits()
                </script>~;
        $yymain .= $myregister_endrow;
    }

    if ( $RegAgree == 2 ) {
        if ($language) {
            fopen( AGREE, "$langdir/$language/agreement.txt" );
        }
        else {
            fopen( AGREE, "$langdir/$lang/agreement.txt" );
        }
        @agreement = <AGREE>;
        fclose(AGREE);
        $fullagree = join q{}, @agreement;
        $fullagree =~ s/\n/<br \/>/gsm;
        $yymain .= $myregister_regagree;
        $yymain =~ s/{yabb fullagree}/$fullagree/gsm;

    }
    $yymain .= $myregister_endform;
    $yymain .= qq~
<script type="text/javascript">
    document.creator.regusername.focus();

    function CheckRegFields() {
        if (document.creator.regusername.value === '') {
            alert("$register_txt{'error_username'}");
            document.creator.regusername.focus();
            return false;
        }~;
        if ( !$emailpassword ) {
            $yymain .= qq~
        if (document.creator.regusername.value == document.creator.passwrd1.value || document.creator.regrealname.value == document.creator.passwrd1.value) {
            alert("$register_txt{'error_usernameispass'}");
            document.creator.regusername.focus();
            return false;
        }~;
        }
    $yymain .= qq~
        if (document.creator.regrealname.value === '') {
            alert("$register_txt{'error_realname'}");
            document.creator.regrealname.focus();
            return false;
        }~ .

      (
        $name_cannot_be_userid
        ? qq~
        if (document.creator.regusername.value == document.creator.regrealname.value) {
            alert("$register_txt{'error_name_cannot_be_userid'}");
            document.creator.regrealname.focus();
            return false;
        }~
        : q{}
      )

      . qq~
        if (document.creator.email.value === '') {
            alert("$register_txt{'error_email'}");
            document.creator.email.focus();
            return false;
        }~ .

      (
          $imp_email_check ? qq~
        if (document.creator.email2.value === '') {
            alert("$register_txt{'error_email2'}");
            document.creator.email2.focus();
            return false;
        }
        if (document.creator.email.value != document.creator.email2.value) {
            alert("$register_txt{'error_email3'}");
            document.creator.email.focus();
            return false;
        }~ : q{}
      ) .

      (
        $birthday_on_reg
        ? q~
        if (~
          . (
            $birthday_on_reg == 1
            ? 'document.creator.birth_day.value.length && '
            : q{}
          )
          . qq~(document.creator.birth_day.value.length < 2 || document.creator.birth_day.value < 1 || document.creator.birth_day.value > 31 || (/\\D/.test)(document.creator.birth_day.value))) {
            alert("$register_txt{'error_birth_day'}");
            document.creator.birth_day.focus();
            return false;
        }
        if (~
          . (
            $birthday_on_reg == 1
            ? 'document.creator.birth_month.value.length && '
            : q{}
          )
          . qq~(document.creator.birth_month.value.length < 2 || document.creator.birth_month.value < 1 || document.creator.birth_month.value > 12 || (/\\D/.test)(document.creator.birth_month.value))) {
            alert("$register_txt{'error_birth_month'}");
            document.creator.birth_month.focus();
            return false;
        }
        if (~
          . (
            $birthday_on_reg == 1
            ? 'document.creator.birth_year.value.length && '
            : q{}
          )
          . qq~(document.creator.birth_year.value.length < 4 || (/\\D/.test)(document.creator.birth_year.value))) {
            alert("$register_txt{'error_birth_year'}");
            document.creator.birth_year.focus();
            return false;
        }
        if (~
          . (
            $birthday_on_reg == 1
            ? 'document.creator.birth_year.value.length && '
            : q{}
          )
          . qq~(document.creator.birth_year.value < ($year - 120) || document.creator.birth_year.value > $year)) {
            alert("$register_txt{'error_birth_year_real'}");
            document.creator.birth_year.focus();
            return false;
        }~
        : q{}
      )

      . qq~
        var emailpassword = $emailpassword;
        if (emailpassword === 0) {
            if (document.creator.passwrd1.value === '' || document.creator.passwrd2.value === '') {
                alert("$register_txt{'error_pass1'}");
                document.creator.passwrd1.focus();
                return false;
            }
            if (document.creator.passwrd1.value != document.creator.passwrd2.value) {
                alert("$register_txt{'error_pass2'}");
                document.creator.passwrd1.focus();
                return false;
            }
        }
		var regcheck = $regcheck;
        if (regcheck > 0 && document.creator.verification.value === '') {
            alert("$register_txt{'error_verification'}");
            document.creator.verification.focus();
            return false;
        }~ .

      (
        $en_spam_questions && -e "$langdir/$language/spam.questions"
        ? qq~
        if (document.creator.verification_question.value === '') {
            alert("$register_txt{'error_verification_question'}");
            document.creator.verification_question.focus();
            return false;
        }~
        : q{}
      )

      . qq~
        var regtype = $regtype;
        var RegAgree = $RegAgree;
        var gender_on_reg = $gender_on_reg;
        if (regtype == 1 && document.creator.reason.value === '') {
            alert("$register_txt{'error_reason'}");
            document.creator.reason.focus();
            return false;
        }
        if (RegAgree == 2 && document.creator.regagree[0].checked !== true) {
            alert("$register_txt{'error_agree'}");
            return false;
        }

        if (gender_on_reg > 1 && !document.creator.gender.value) {
            alert("$register_txt{'error_gender'}");
            document.creator.gender.focus();
            return false;
        }
        return true;
    }

    function jumpatnext(from,to,length) {
        window.setTimeout('if (' + from + '.value.length == ' + length + ') ' + to + '.focus();', 1);
    }
</script>
    ~;
    template();
    return;
}

sub Register2 {
    if ( !$regtype ) { fatal_error('registration_disabled'); }
    if ( $RegAgree > 0 && $FORM{'regagree'} ne 'yes' ) {
        fatal_error('no_regagree');
    }
    my %member;
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        if ( $key ne 'reason' ) { $value =~ s/[\n\r]//gxsm; }
        $member{$key} = $value;
    }
    if ( $member{'domain'} ) { $member{'email'} .= $member{'domain'}; }
#    $member{'regusername'} =~ s/\s/_/gxsm;
    $member{'regrealname'} =~ s/\t+/\ /gsm;

    # If enabled check if user has a valid e-mail address (needs Net::DNS to be installed)
    if ( $imp_email_check == 1 ) {
        eval {
            require Net::DNS;
        };
        if ( !$EVAL_ERROR ) {
            my $helo;
            require Mail::CheckUser;
            Mail::CheckUser->import(qw(check_email last_check));
            $Mail::CheckUser::Sender_Addr = $webmaster_email;
            if ($boardurl =~ /http\:\/\/(.*?)\//){ $Mail::CheckUser::Helo_Domain = $1; }
            if (check_email($member{'email'})) {
                my $email_ok = 1;
            }
            else {
                my $failure = last_check()->{code};
                fatal_error(q{}, "$mail_check{'address'} $member{'email'} $mail_check{'invalid'} $mail_check{'reason'} $mail_check{$failure}");
            }
        }
    }

    # Make sure users can't register with banned details
    email_domain_check( $member{'email'} );
    banning( $member{'regusername'}, $member{'email'} );

# check if there is a system hash named like this by checking existence through size
    if ( keys( %{ $member{'regusername'} } ) > 0 ) {
        fatal_error( 'system_prohibited_id', "($member{'regusername'})" );
    }
    if ( length( $member{'regusername'} ) > 25 ) {
        fatal_error( 'id_to_long', "($member{'regusername'})" );
    }
    if ( $member{'email'} ne $member{'email2'} && $imp_email_check ) {
        fatal_error( 'email_mismatch' );
    }
    if ( length( $member{'email'} ) > 100 ) {
        fatal_error( 'email_to_long', "($member{'email'})" );
    }
    if ( $member{'regusername'} eq q{} ) {
        fatal_error( 'no_username', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} eq q{_} ) {
        fatal_error( 'id_alfa_only', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} =~ /guest/ixsm ) {
        fatal_error( 'id_reserved', "$member{'regusername'}" );
    }
    if ( $member{'regusername'} =~ /[^\w\+\-\_\@\.]/sm ) {
        fatal_error( 'invalid_character',
            "$register_txt{'35'} $register_txt{'241e'}" );
    }
    if ( $member{'regusername'} =~ /^[0-9]+$/sm ) {
        fatal_error( 'all_numbers',
            "$register_txt{'35'} $register_txt{'241n'}" );
    }
    if ( $member{'email'} eq q{} ) {
        fatal_error( 'no_email', "($member{'regusername'})" );
    }
    if ( -e ("$memberdir/$member{'regusername'}.vars") ) {
        fatal_error( 'id_taken', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} eq $member{'passwrd1'} ) {
        fatal_error('password_is_userid');
    }
    if ( $member{'reason'} eq q{} && $regtype == 1 ) {
        fatal_error('no_reg_reason');
    }

    if ( $spamfruits == 1 ) {
        if ( $member{'ycord'} < 5 || $member{'ycord'} > 70 ) {
            fatal_error( q{}, "$fruittxt{'6'}" );
        }
        if ( $member{'thefruit'} eq $fruittxt{'2'}
            && ( $member{'xcord'} < 5 || $member{'xcord'} > 75 ) )
        {
            fatal_error( q{}, "$fruittxt{'6'}" );
        }
        if ( $member{'thefruit'} eq $fruittxt{'3'}
            && ( $member{'xcord'} < 75 || $member{'xcord'} > 145 ) )
        {
            fatal_error( q{}, "$fruittxt{'6'}" );
        }
        if ( $member{'thefruit'} eq $fruittxt{'4'}
            && ( $member{'xcord'} < 145 || $member{'xcord'} > 215 ) )
        {
            fatal_error( q{}, "$fruittxt{'6'}" );
        }
        if ( $member{'thefruit'} eq $fruittxt{'5'}
            && ( $member{'xcord'} < 215 || $member{'xcord'} > 285 ) )
        {
            fatal_error( q{}, "$fruittxt{'6'}" );
        }
    }

    FromChars( $member{'regrealname'} );
    $convertstr = $member{'regrealname'};
    $convertcut = 30;
    CountChars();
    $member{'regrealname'} = $convertstr;
    if ($cliped) {
        fatal_error( 'realname_to_long',
            "($member{'regrealname'} => $convertstr)" );
    }
    if ( $member{'regrealname'} =~
        /[^ \w\x80-\xFF\[\]\(\)#\%\+,\-\|\.:=\?\@\^]/sm )
    {
        fatal_error( 'invalid_character',
            "$register_txt{'38'} $register_txt{'241re'}" );
    }

    if ( $name_cannot_be_userid
        && lc $member{'regusername'} eq lc $member{'regrealname'} )
    {
        fatal_error('name_is_userid');
    }

    if (
        lc $member{'regusername'} eq
        lc MemberIndex( 'check_exist', $member{'regusername'}, 0 ) )
    {
        fatal_error( 'id_taken', "($member{'regusername'})" );
    }
    if (
        lc $member{'email'} eq lc MemberIndex( 'check_exist', $member{'email'}, 2 )
      )
    {
        fatal_error( 'email_taken', "($member{'email'})" );
    }
    if (
        lc $member{'regrealname'} eq
        lc MemberIndex( 'check_exist', $member{'regrealname'}, 1 ) )
    {
        fatal_error('name_taken');
    }
    if ( Censor( $member{'regusername'} ) ne $member{'regusername'} ) {
        fatal_error( 'censor1', CheckCensor( $member{'regusername'} ) );
    }
    if ( Censor( $member{'email'} ) ne $member{'email'} ) {
        fatal_error( 'censor2', CheckCensor( $member{'email'} ) );
    }
    if ( Censor( $member{'regrealname'} ) ne $member{'regrealname'} ) {
        fatal_error( 'censor3', CheckCensor( $member{'regrealname'} ) );
    }
    if ( $honeypot == 1 && $member{'add_field0'} ne q{} ) {
        fatal_error('bad_bot');
    }

    if ( $regtype == 1 ) {
        $convertstr = $member{'reason'};
        $convertcut = $RegReasonSymbols;
        CountChars();
        $member{'reason'} = $convertstr;

        FromChars( $member{'reason'} );
        ToHTML( $member{'reason'} );
        ToChars( $member{'reason'} );
        $member{'reason'} =~ s/[\n\r]{1,2}/<br \/>/igsm;
    }

    if ($regcheck) {
        require Sources::Decoder;
        validation_check( $member{'verification'} );
    }
    $min_reg_time ||= 0;
    if ( $min_reg_time > 0 ) {
        $reg_finish_time = $date - $member{'reg_start_time'};
        if ( $reg_finish_time < $min_reg_time || !$member{'reg_start_time'} ) {
            fatal_error( q{}, "$register_txt{'error_min_reg_time'}" );
        }
    }

    if ( $en_spam_questions && -e "$langdir/$language/spam.questions" ) {
        SpamQuestionCheck(
            $member{'verification_question'},
            $member{'verification_question_id'}
        );
    }

    if ($emailpassword) {
        srand;
        $member{'passwrd1'} = int rand 100;
        $member{'passwrd1'} =~ tr/0123456789/ymifxupbck/;
        $_ = int rand 77;
        $_ =~ tr/0123456789/q8dv7w4jm3/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 89;
        $_ =~ tr/0123456789/y6uivpkcxw/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 188;
        $_ =~ tr/0123456789/poiuytrewq/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 65;
        $_ =~ tr/0123456789/lkjhgfdaut/;
        $member{'passwrd1'} .= $_;
    }
    else {
        if ( $member{'passwrd1'} ne $member{'passwrd2'} ) {
            fatal_error( 'password_mismatch', "($member{'regusername'})" );
        }
        if ( $member{'passwrd1'} eq q{} ) {
            fatal_error( 'no_password', "($member{'regusername'})" );
        }
        if ( $member{'passwrd1'} =~
            /[^\s\w!\@#\$\%\^&\*\(\)\+\|`~\-=\\:;'",\.\/\?\[\]\{\}]/xsm )
        {
            fatal_error( 'invalid_character',
                "$register_txt{'36'} $register_txt{'241'}" );
        }
    }
    if ( $member{'email'} !~ /^[\w\-\.\+]+\@[\w\-\.\+]+\.\w{2,4}$/xsm ) {
        fatal_error( 'invalid_character',
            "$register_txt{'69'} $register_txt{'241e'}" );
    }
    if (   $member{'email'} =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/xsm
        || $member{'email'} !~
        /\A.+@\[?(\w|[-.])+\.[a-zA-Z]{2,4}|[0-9]{1,4}\]?\Z/xsm )
    {
        fatal_error('invalid_email');
    }

    fopen( RESERVE, "$vardir/reserve.txt" )
      or fatal_error( 'cannot_open', "$vardir/reserve.txt", 1 );
    @reserve = <RESERVE>;
    fclose(RESERVE);
    fopen( RESERVECFG, "$vardir/reservecfg.txt" )
      or fatal_error( 'cannot_open', "$vardir/reservecfg.txt", 1 );
    @reservecfg = <RESERVECFG>;
    fclose(RESERVECFG);

    for my $aa ( 0 .. ( @reservecfg - 1 ) ) {
        chomp $reservecfg[$aa];
    }
    $matchword = $reservecfg[0] eq 'checked';
    $matchcase = $reservecfg[1] eq 'checked';
    $matchuser = $reservecfg[2] eq 'checked';
    $matchname = $reservecfg[3] eq 'checked';
    $namecheck =
        $matchcase eq 'checked'
      ? $member{'regusername'}
      : lc $member{'regusername'};
    $realnamecheck =
        $matchcase eq 'checked'
      ? $member{'regrealname'}
      : lc $member{'regrealname'};

    foreach my $reserved (@reserve) {
        chomp $reserved;
        $reservecheck = $matchcase ? $reserved : lc $reserved;
        if ($matchuser) {
            if ($matchword) {
                if ( $namecheck eq $reservecheck ) {
                    fatal_error( 'id_reserved', "$reserved" );
                }
            }
            else {
                if ( $namecheck =~ $reservecheck ) {
                    fatal_error( 'id_reserved', "$reserved" );
                }
            }
        }
        if ($matchname) {
            if ($matchword) {
                if ( $realnamecheck eq $reservecheck ) {
                    fatal_error( 'name_reserved', "$reserved" );
                }
            }
            else {
                if ( $realnamecheck =~ $reservecheck ) {
                    fatal_error( 'name_reserved', "$reserved" );
                }
            }
        }
    }

    if   ($default_template) { $new_template = $default_template; }
    else                     { $new_template = q~Forum default~; }

    # check if user isn't already registered
    if ( -e ("$memberdir/$member{'regusername'}.vars") ) {
        fatal_error('id_taken');
    }

    # check if user isn't already in pre-registration
    if ( -e ("$memberdir/$member{'regusername'}.pre") ) {
        fatal_error('already_preregged');
    }
    if ( -e ("$memberdir/$member{'regusername'}.wait") ) {
        fatal_error('already_preregged');
    }

    if ( $new_template !~ m{\A[0-9a-zA-Z\_\(\)\ \#\%\-\:\+\?\$\&\~\.\,\@]+\Z}xsm
        && $new_template ne q{} )
    {
        fatal_error('invalid_template');
    }
    if ( $member{'language'} !~
        m{\A[0-9a-zA-Z\_\(\)\ \#\%\-\:\+\?\$\&\~\.\,\@]+\Z}xsm
        && $member{'language'} ne q{} )
    {
        fatal_error('invalid_language');
    }

    ToHTML( $member{'language'} );

    $reguser      = $member{'regusername'};
    $registerdate = timetostring($date);
    $language     = $member{'language'};

    ToHTML( $member{'regrealname'} );

    if ($birthday_on_reg) {
        $member{'birth_month'} =~ s/\D//gxsm;
        $member{'birth_day'}   =~ s/\D//gxsm;
        $member{'birth_year'}  =~ s/\D//gxsm;
        if ( $birthday_on_reg == 1 ) {
            if (   length( $member{'birth_month'} ) < 2
                || $member{'birth_month'} < 1
                || $member{'birth_month'} > 12 )
            {
                $member{'birth_month'} = q{};
            }
            if (   length( $member{'birth_day'} ) < 2
                || $member{'birth_day'} < 1
                || $member{'birth_day'} > 31 )
            {
                $member{'birth_day'} = q{};
            }
            if (   length( $member{'birth_year'} ) < 4
                || $member{'birth_year'} < ( $year - 120 )
                || $member{'birth_year'} > $year )
            {
                $member{'birth_year'} = q{};
            }
            if (   $member{'birth_day'}
                && $member{'birth_month'}
                && $member{'birth_year'} )
            {
                ${ $uid . $reguser }{'bday'} =
"$member{'birth_month'}/$member{'birth_day'}/$member{'birth_year'}";
            }
        }
        elsif ( $birthday_on_reg == 2 ) {
            if (   length( $member{'birth_month'} ) < 2
                || $member{'birth_month'} < 1
                || $member{'birth_month'} > 12 )
            {
                fatal_error( q{}, $register_txt{'error_birth_month'} );
            }
            if (   length( $member{'birth_day'} ) < 2
                || $member{'birth_day'} < 1
                || $member{'birth_day'} > 31 )
            {
                fatal_error( q{}, $register_txt{'error_birth_day'} );
            }
            if ( length( $member{'birth_year'} ) < 4 ) {
                fatal_error( q{}, $register_txt{'error_birth_year'} );
            }
            if (   $member{'birth_year'} < ( $year - 120 )
                || $member{'birth_year'} > $year )
            {
                fatal_error( q{}, $register_txt{'error_birth_year_real'} );
            }
            ${ $uid . $reguser }{'bday'} =
"$member{'birth_month'}/$member{'birth_day'}/$member{'birth_year'}";
        }
    }
    if ($gender_on_reg) {
        ${ $uid . $reguser }{'gender'} = $member{'gender'};
        if ( $editGenderLimit && ${ $uid . $reguser }{'gender'} ne q{} ) {
            ${ $uid . $reguser }{'disablegender'} = 1;
        }
    }
    if (   $birthday_on_reg
        && $editAgeLimit
        && ${ $uid . $reguser }{'bday'} ne q{} )
    {
        ${ $uid . $reguser }{'disableage'} = 1;
    }

    ${ $uid . $reguser }{'password'}   = encode_password( $member{'passwrd1'} );
    ${ $uid . $reguser }{'realname'}   = $member{'regrealname'};
    ${ $uid . $reguser }{'email'}      = lc $member{'email'};
    ${ $uid . $reguser }{'postcount'}  = 0;
    ${ $uid . $reguser }{'regreason'}  = $member{'reason'};
    ${ $uid . $reguser }{'usertext'}   = $defaultusertxt;
    ${ $uid . $reguser }{'userpic'}    = $my_blank_avatar;
    ${ $uid . $reguser }{'regdate'}    = $registerdate;
    ${ $uid . $reguser }{'regtime'}    = $date;
    ${ $uid . $reguser }{'timeselect'} = $timeselected;
    ${ $uid . $reguser }{'lastips'}    = $user_ip;
    ${ $uid . $reguser }{'hidemail'}   = $member{'hideemail'} ? 1 : 0;
    ${ $uid . $reguser }{'timeformat'} = q~MM D+ YYYY @ HH:mm:ss*~;
    ${ $uid . $reguser }{'template'}   = $new_template;
    ${ $uid . $reguser }{'language'}   = $language;
    ${ $uid . $reguser }{'pageindex'}  = q~1|1|1|1~;

    if ( ( $addmemgroup_enabled == 1 || $addmemgroup_enabled == 3 )
        && $member{'joinmemgroup'} ne q{} )
    {
        my @newmemgr;
        foreach ( split /, /sm, $member{'joinmemgroup'} ) {
            if ( $NoPost{$_} && ( split /\|/xsm, $NoPost{$_} )[10] == 1 ) {
                push @newmemgr, $_;
            }
        }
        ${ $uid . $reguser }{'addgroups'} = join q{,}, @newmemgr;
    }

    if ( $regtype == 1 || $regtype == 2 ) {
        my ( @reglist, @x );

        # If a pre-registration list exists load it
        if ( -e "$memberdir/memberlist.inactive" ) {
            fopen( INACT, "$memberdir/memberlist.inactive" );
            @reglist = <INACT>;
            fclose(INACT);
        }

        # If a approve-registration list exists load it too
        if ( -e "$memberdir/memberlist.approve" ) {
            fopen( APPROVE, "$memberdir/memberlist.approve" );
            push @reglist, <APPROVE>;
            fclose(APPROVE);
        }
        foreach (@reglist) {
            @x = split /\|/xsm, $_;
            if ( $reguser eq $x[2] ) { fatal_error('already_preregged'); }
            if ( lc $member{'email'} eq lc $x[4] ) {
                fatal_error('email_already_preregged');
            }
        }

        # create pre-registration .pre file and write log and inactive list
        require Sources::Decoder;
        validation_code();
        $activationcode = substr $sessionid, 0, 20;

        if ($extendedprofiles) {
            require Sources::ExtendedProfiles;
            my $error = ext_validate_submition( $reguser, $reguser );
            if ( $error ne q{} ) {
                fatal_error( 'extended_profiles_validation', $error );
            }
            ext_saveprofile($reguser);
        }

        UserAccount( $reguser, 'preregister' );
        if   ($do_scramble_id) { $cryptuser = cloak($reguser); }
        else                   { $cryptuser = $reguser; }

        if ($emailpassword) { $regpass = $member{'passwrd1'}; }
        else { $regpass = encode_password( $member{'passwrd1'} ); }
        fopen( INACT, ">>$memberdir/memberlist.inactive", 1 );
        print {INACT}
          "$date|$activationcode|$reguser|$regpass|$member{'email'}|$user_ip\n"
          or croak "$croak{'print'} INACT";
        fclose(INACT);
        fopen( REGLOG, ">>$vardir/registration.log", 1 );
        print {REGLOG} "$date|N|$member{'regusername'}||$user_ip\n"
          or croak "$croak{'print'} REGLOG";
        fclose(REGLOG);

        ## send an e-mail to the user that registration is pending e-mail validation within the given timespan. ##
        my $templanguage = $language;
        $language = $member{'language'};
        LoadLanguage('Email');
        sendmail(
            ${ $uid . $reguser }{'email'},
            "$mailreg_txt{'apr_result_activate'} $mbname",
            template_email(
                $preregemail,
                {
                    'displayname'    => $member{'regrealname'},
                    'username'       => $reguser,
                    'cryptusername'  => $cryptuser,
                    'password'       => $member{'passwrd1'},
                    'activationcode' => $activationcode,
                    'preregspan'     => $preregspan
                }
            ),
            q{},
            $emailcharset
        );
        $language = $templanguage;
        $yymain .= $myregister_pending;
        $yytitle = "$prereg_txt{'1a'}";

    }
    else {
        if ($extendedprofiles) {
            require Sources::ExtendedProfiles;
            my $error = ext_validate_submition( $reguser, $reguser );
            if ( $error ne q{} ) {
                fatal_error( 'extended_profiles_validation', $error );
            }
            ext_saveprofile($reguser);
        }
        UserAccount( $reguser, 'register' );
        MemberIndex( 'add', $reguser );
        FormatUserName($reguser);

        if ( $send_welcomeim == 1 ) {

# new format msg file:
# messageid|(from)user|(touser(s))|(ccuser(s))|(bccuser(s))|subject|date|message|(parentmid)|reply#|ip|messagestatus|flags|storefolder|attachment
            $messageid = $BASETIME . $PROCESS_ID;
            fopen( IM, ">$memberdir/$member{'regusername'}.msg", 1 );
            print {IM}
"$messageid|$sendname|$member{'regusername'}|||$imsubject|$date|$imtext|$messageid|0|$ENV{'REMOTE_ADDR'}|s|u||\n"
              or croak "$croak{'print'} IM";
            fclose(IM);
        }
        if ($new_member_notification) {
            my $templanguage = $language;
            $language = $lang;
            LoadLanguage('Email');
            sendmail(
                $new_member_notification_mail,
                $mailreg_txt{'new_member_info'},
                template_email(
                    $newmemberemail,
                    {
                        'displayname' => $member{'regrealname'},
                        'username'    => $reguser,
                        'userip'      => $user_ip,
                        'useremail'   => ${ $uid . $reguser }{'email'}
                    }
                ),
                q{},
                $emailcharset
            );
            $language = $templanguage;
        }

        if ($emailpassword) {
            my $templanguage = $language;
            $language = $member{'language'};
            LoadLanguage('Email');
            sendmail(
                ${ $uid . $reguser }{'email'},
                "$mailreg_txt{'apr_result_info'} $mbname",
                template_email(
                    $passwordregemail,
                    {
                        'displayname' => $member{'regrealname'},
                        'username'    => $reguser,
                        'password'    => $member{'passwrd1'}
                    }
                ),
                q{},
                $emailcharset
            );
            $language = $templanguage;
            $yymain .= $myregister_password;
        }
        else {
            if ($emailwelcome) {
                my $templanguage = $language;
                $language = $member{'language'};
                LoadLanguage('Email');
                sendmail(
                    ${ $uid . $reguser }{'email'},
                    "$mailreg_txt{'apr_result_info'} $mbname",
                    template_email(
                        $welcomeregemail,
                        {
                            'displayname' => $member{'regrealname'},
                            'username'    => $reguser,
                            'password'    => $member{'passwrd1'}
                        }
                    ),
                    q{},
                    $emailcharset
                );
                $language = $templanguage;
            }
            $yymain .= $myregister_welcome;
            $yymain =~ s/{yabb regusername}/$member{'regusername'}/sm;
            $yymain =~ s/{yabb passwrd1}/$member{'passwrd1'}/sm;
            $yymain =~ s/{yabb Cookie_Length}/$Cookie_Length/sm;
        }
        $yytitle = "$register_txt{'245'}";
    }
    template();
    return;
}

sub user_activation {
    my ( $reguse, $active ) = @_;
    $changed       = 0;
    $reguser       = $reguse || $INFO{'username'};
    $activationkey = $active || $INFO{'activationkey'};
    if ( !$reguser ) { fatal_error('wrong_id'); }
    if ($do_scramble_id) { $reguser = decloak($reguser); }
    if ( !-e "$memberdir/$reguser.pre" && -e "$memberdir/$reguser.vars" ) {
        fatal_error('already_activated');
    }
    if ( ( $regtype != 1 && !-e "$memberdir/$reguser.pre" ) || ( $regtype == 1 && !-e "$memberdir/$reguser.pre" && !-e "$memberdir/$reguser.wait" ) ) { fatal_error('prereg_expired'); }
    elsif ( $regtype == 1 && -e "$memberdir/$reguser.wait" ) { fatal_error('prereg_wait'); }
    # If a pre-registration list exists load it
    if ( -e "$memberdir/memberlist.inactive" ) {
        fopen( INACT, "$memberdir/memberlist.inactive" );
        @reglist = <INACT>;
        fclose(INACT);
    }
    else {

        # add entry to registration log
        fopen( REGLOG, ">>$vardir/registration.log", 1 );
        print {REGLOG} "$date|E|$reguser||$user_ip\n"
          or croak "$croak{'print'} REGLOG";
        fclose(REGLOG);
        fatal_error('prereg_expired');
    }
    if ( $regtype == 1 && -e "$memberdir/memberlist.approve" ) {
        fopen( APR, "$memberdir/memberlist.approve" );
        @aprlist = <APR>;
        fclose(APR);
    }

    # check if user is in pre-registration and check activation key
    foreach (@reglist) {
        ( $regtime, $testkey, $regmember, $regpassword, undef ) =
          split /\|/xsm, $_, 5;

        if ( $regmember ne $reguser ) {
            push @chnglist, $_;    # update non activate user list
        }
        else {
            my $templanguage = $language;
            if ( $activationkey ne $testkey ) {
                fopen( REGLOG, ">>$vardir/registration.log", 1 );
                print {REGLOG} "$date|E|$reguser||$user_ip\n"
                  or croak "$croak{'print'} REGLOG";

                # add entry to registration log
                fclose(REGLOG);
                fatal_error('wrong_code');

            }
            elsif ( $regtype == 1 ) {

        # user is in list and the keys match, so move him/her for admin approval
                unshift @aprlist, $_;

                rename "$memberdir/$reguser.pre", "$memberdir/$reguser.wait";

                # add entry to registration log
                if   ( $iamadmin || $iamgmod ) { $actuser = $username; }
                else                           { $actuser = $reguser; }
                fopen( REGLOG, ">>$vardir/registration.log", 1 );
                print {REGLOG} "$date|W|$reguser|$actuser|$user_ip\n"
                  or croak "$croak{'print'} REGLOG";
                fclose(REGLOG);

                LoadUser($reguser);
                $language = ${ $uid . $reguser }{'language'};
                LoadLanguage('Email');
                sendmail(
                    ${ $uid . $reguser }{'email'},
                    "$mailreg_txt{'apr_result_wait'} $mbname",
                    template_email(
                        $approveregemail,
                        {
                            'username'    => $reguser,
                            'displayname' => ${ $uid . $reguser }{'realname'}
                        }
                    ),
                    q{},
                    $emailcharset
                );

            }
            elsif ( $regtype == 2 ) {
                LoadUser($reguser);

                # check if email is already in active use
                if (
                    lc ${ $uid . $reguser }{'email'} eq
                    lc MemberIndex( 'check_exist',
                        ${ $uid . $reguser }{'email'}, 2 ) )
                {
                    fatal_error( 'email_taken', "(${$uid.$reguser}{'email'})" );
                }

                # user is in list and the keys match, so let him/her in
                rename "$memberdir/$reguser.pre", "$memberdir/$reguser.vars";
                MemberIndex( 'add', $reguser );

                if   ( $iamadmin || $iamgmod ) { $actuser = $username; }
                else                           { $actuser = $reguser; }

                # add entry to registration log
                fopen( REGLOG, ">>$vardir/registration.log", 1 );
                print {REGLOG} "$date|A|$reguser|$actuser|$user_ip\n"
                  or croak "$croak{'print'} REGLOG";
                fclose(REGLOG);

                if ($emailpassword) {
                    chomp $regpassword;
                    $language = ${ $uid . $reguser }{'language'};
                    LoadLanguage('Email');
                    sendmail(
                        ${ $uid . $reguser }{'email'},
                        "$mailreg_txt{'apr_result_validate'} $mbname",
                        template_email(
                            $activatedpassregemail,
                            {
                                'displayname' =>
                                  ${ $uid . $reguser }{'realname'},
                                'username' => $reguser,
                                'password' => $regpassword
                            }
                        ),
                        q{},
                        $emailcharset
                    );
                    $yymain .= $myregister_table_a;
                    $sharedLogin_title = $register_txt{'97'};
                    $sharedLogin_text  = $register_txt{'703'};
                    $yymain .= $myregister_table_b;

                }
                elsif ($emailwelcome) {
                    chomp $regpassword;
                    $language = ${ $uid . $reguser }{'language'};
                    LoadLanguage('Email');
                    sendmail(
                        ${ $uid . $reguser }{'email'},
                        "$mailreg_txt{'apr_result_validate'} $mbname",
                        template_email(
                            $activatedwelcomeregemail,
                            {
                                'displayname' =>
                                  ${ $uid . $reguser }{'realname'},
                                'username' => $reguser,
                                'password' => $regpassword
                            }
                        ),
                        q{},
                        $emailcharset
                    );
                }
            }

            if ( $send_welcomeim == 1 ) {

# new format msg file:
# messageid|(from)user|(touser(s))|(ccuser(s))|(bccuser(s))|subject|date|message|(parentmid)|reply#|ip|messagestatus|flags|storefolder|attachment
                $messageid = $BASETIME . $PROCESS_ID;
                fopen( INBOX, ">$memberdir/$reguser.msg" );
                print {INBOX}
"$messageid|$sendname|$reguser|||$imsubject|$date|$imtext|$messageid|0|$ENV{'REMOTE_ADDR'}|s|u||\n"
                  or croak "$croak{'print'} INBOX";
                fclose(INBOX);
            }
            if ($new_member_notification) {
                $language = $lang;
                LoadLanguage('Email');
                sendmail(
                    $new_member_notification_mail,
                    $mailreg_txt{'new_member_info'},
                    template_email(
                        $newmemberemail,
                        {
                            'displayname' => ${ $uid . $reguser }{'realname'},
                            'username'    => $reguser,
                            'userip'      => $user_ip,
                            'useremail'   => ${ $uid . $reguser }{'email'}
                        }
                    ),
                    q{},
                    $emailcharset
                );
            }
            $language = $templanguage;
            $changed  = 1;
        }
    }

    if ($changed) {

        # if changed write new inactive list
        fopen( INACT, ">$memberdir/memberlist.inactive" );
        print {INACT} @chnglist or croak "$croak{'print'} INACT";
        fclose(INACT);

        # update approval user list
        if ( $regtype == 1 ) {
            fopen( APR, ">$memberdir/memberlist.approve" );
            print {APR} @aprlist or croak "$croak{'print'} APR";
            fclose(APR);
        }
    }
    else {

        # add entry to registration log
        fopen( REGLOG, ">>$vardir/registration.log", 1 );
        print {REGLOG} "$date|E|$reguser|$user_ip\n"
          or croak "$croak{'print'} REGLOG";
        fclose(REGLOG);
        fatal_error('wrong_id');
    }

    if ( $regtype == 1 ) {
        $yymain .= $myregister_prereg1;
        $yytitle = "$prereg_txt{'1b'}";

    }
    elsif ( $regtype == 2 ) {
        $yymain .= $myregister_prereg2;
        if ( !$emailpassword ) { $yymain .= $prereg_txt{'5a'}; }
        $yymain .= qq~$prereg_txt{'5b'}<br /><br />~;
        if ($emailpassword) {
            $yymain .= qq~$register_txt{'703'}<br /> <br />~;
        }
        $yymain .= $myregister_enddiv;

        if ( !$iamadmin && !$iamgmod ) {
            if ( !$emailpassword ) {
                $yymain .= $myregister_div_a;
                require Sources::LogInOut;
                $yymain .= sharedLogin();
                $yymain .= $myregister_div_b;
            }
            else {
                $yymain .= q~<br /><br />~;
            }
        }
        $yytitle = "$prereg_txt{'5'}";
    }

    if ( $iamadmin || $iamgmod ) {
        $yySetLocation = qq~$adminurl?action=view_reglog~;
        redirectexit();
    }
    else {
        template();
    }
    return;
}

1;
