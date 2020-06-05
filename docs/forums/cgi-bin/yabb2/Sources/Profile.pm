###############################################################################
# Profile.pm                                                                  #
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
use English qw(-no_match_vars);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$profilepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Profile');
LoadLanguage('Register');
require Sources::AddModerators;
get_micon();
get_template('MyProfile');
get_gmod();

$pm_lev = PMlev();

# make sure this person has access to this profile
sub PrepareProfile {
    if ($iamguest) { fatal_error('no_access'); }

    # If someone registers with a '+' in their name It causes problems.
    # Get's turned into a <space> in the query string Change it back here.
    # Users who register with spaces get them replaced with _
    # So no problem there.
    $INFO{'username'} =~ tr/ /+/;

    $user = $INFO{'username'};
    if ($do_scramble_id)    { decloak($user); }
    if ( $user =~ m{/}sm )  { fatal_error('no_user_slash'); }
    if ( $user =~ m{\\}sm ) { fatal_error('no_user_backslash'); }

    if ( !LoadUser($user) ) { fatal_error('no_profile_exists'); }

    if (
        (
               $user ne $username
            && !$iamadmin
            && ( !$iamgmod || !$allow_gmod_profile )
        )
        || ( $user eq 'admin' && $username ne 'admin' )
        || ( $iamgmod && ${ $uid . $user }{'position'} eq 'Administrator' )
      )
    {
        fatal_error('not_allowed_profile_change');
    }

    @menucolors = qw(catbg catbg catbg catbg catbg catbg);
    return;
}

# Check that profile-editing session is still valid
sub SidCheck {
    my @x         = @_;
    my $cur_sid   = decloak( $INFO{'sid'} );
    my $sid_check = substr $date, 5, 5;
    if ( $sid_check <= 600 && $cur_sid >= 99_400 ) { $sid_check += 100_000; }

    $sid_expires = $cur_sid + 600 - $sid_check;

    if ( $sid_expires < 0 || $cur_sid > $sid_check ) { ProfileCheck( $x[0] ); }
    if ( $sid_expires < 60 ) {
        $expsectxt =
          ( $sid_expires == 1 )
          ? $profile_txt{'sid_expires_3'}
          : $profile_txt{'sid_expires_2'};
        $expiretxt = qq~$profile_txt{'sid_expires_1'} $sid_expires $expsectxt~;
    }
    else {
        $expiremin = int( $sid_expires / 60 );
        $expiresec = $sid_expires % 60;
        $expmintxt =
          ( $expiremin == 1 )
          ? $profile_txt{'sid_expires_4'}
          : $profile_txt{'sid_expires_5'};
        $expsectxt =
          ( $expiresec == 1 )
          ? $profile_txt{'sid_expires_3'}
          : $profile_txt{'sid_expires_2'};
        $expiretxt =
qq~$profile_txt{'sid_expires_1'} $expiremin $expmintxt $expiresec $expsectxt~;
    }
    return;
}

sub ProfileCheck {
    my @x = @_;
    PrepareProfile();

    my $sid_descript = $mycenter_profile_txt{'siddescript'};
    if ( $x[0] ) {
        $sid_descript = $mycenter_profile_txt{'timeoutdescript'};
        $redirsid     = $x[0];
        if ( $redirsid =~ s/2$//xsm ) {
            $yyjavascript .= qq~\nalert("$profile_txt{'897'}");~;
        }
    }
    else {
        $redirsid = $INFO{'page'} || 'profile';
    }

    $yymain .= $myprofile_a;
    $yymain =~ s/{yabb sid_descript}/$sid_descript/sm;
    $yymain =~
s/{yabb prof_act}/$scripturl?action=profileCheck2;username=$useraccount{$user}/sm;
    $yymain =~ s/{yabb redirsid}/$redirsid/sm;

    $yynavigation = qq~&rsaquo; $profile_txt{'900'}~;
    $yytitle      = $profile_txt{'900'};
    template();
    return;
}

sub ProfileCheck2 {
    PrepareProfile();

    my $password = encode_password( $FORM{'passwrd'} || $INFO{'passwrd'} );
    if ( $user eq $username && $password ne ${ $uid . $username }{'password'} )
    {
        fatal_error('current_password_wrong');
    }
    if ( ( $iamadmin || ( $iamgmod && $allow_gmod_profile ) )
        && $password ne ${ $uid . $username }{'password'} )
    {
        fatal_error('no_admin_password');
    }

    # Update the sessionID too
    ${ $uid . $username }{'session'} = encode_password($user_ip);
    UserAccount( $username, 'update' );

    # update only this cookie since we don't know when the others will expire
    $yySetCookies3 = write_cookie(
        -name    => "$cookiesession_name",
        -value   => "${$uid.$username}{'session'}",
        -path    => q{/},
        -expires => 'Sunday, 17-Jan-2038 00:00:00 GMT'
    );

    # Get a semi-secure SID - only for profile changes
    # cloak the sid -> no point giving anyone the means.
    $yySetLocation =
        "$scripturl?action="
      . ( $FORM{'redir'} || $INFO{'redir'} || 'profile' )
      . ";username=$useraccount{$user};sid="
      . cloak( reverse substr $date, 5, 5 )
      . ( $INFO{'newpassword'} ? ';newpassword=1' : q{} );
    redirectexit();
    return;
}

sub ProfileMenu {
    return if $view;

    if ($buddyListEnabled) {
        $bdlist = $myprofie_bdlist;
        $bdlist =~ s/{yabb menucolor3}/$menucolors[3]/sm;
        $bdlist =~ s/{yabb bduser}/$useraccount{$user}/sm;
    }

    if ( $pm_lev == 1 ) {
        $pmlevel = $myprofile_pmlevel;
        $pmlevel =~ s/{yabb menucolor4}/$menucolors[4]/sm;
        $pmlevel =~ s/{yabb pmuser}/$useraccount{$user}/sm;
    }
    if (
        $iamadmin
        || (   $iamgmod
            && $allow_gmod_profile
            && $gmod_access2{'profileAdmin'} eq 'on' )
      )
    {
        $showadmin = $myprofile_showadmin;
        $showadmin =~ s/{yabb menucolor5}/$menucolors[5]/sm;
        $showadmin =~ s/{yabb aduser}/$useraccount{$user}/sm;
    }
    $yymain .= $myprofile_menu;
    $yymain =~ s/{yabb menu_user}/$useraccount{$user}/gsm;
    $yymain =~ s/{yabb sid}/$INFO{'sid'}/gsm;
    $yymain =~ s/{yabb menucolor0}/$menucolors[0]/sm;
    $yymain =~ s/{yabb menucolor1}/$menucolors[1]/sm;
    $yymain =~ s/{yabb menucolor2}/$menucolors[2]/sm;
    $yymain =~ s/{yabb bdlist}/$bdlist/sm;
    $yymain =~ s/{yabb pmlevel}/$pmlevel/sm;
    $yymain =~ s/{yabb showadmin}/$showadmin/sm;
    return $yymain;
}

sub ModifyProfile {
    SidCheck($action);
    PrepareProfile();

    $menucolors[0] = 'selected-bg';
    ProfileMenu();

    if ($iamadmin) {
        $confdel_text =
          qq~$profile_txt{'775'} $profile_txt{'777'} $user $profile_txt{'778'}~;
        if ( $user eq $username ) {
            $passtext = $profile_txt{'821'};
        }
        else {
            $passtext = qq~$profile_txt{'2'} $profile_txt{'36'}~;
        }
    }
    else {
        $confdel_text =
          qq~$profile_txt{'775'} $profile_txt{'776'} $profile_txt{'778'}~;
        $passtext = $profile_txt{'821'};
    }

    $passtext .= qq~<br /><span class="small norm">$profile_txt{'895'}</span>~;

    my $scriptAction = q~profile2~;
    if ($view) {
        $scriptAction = q~myprofile2~;
        $yytitle      = $profile_txt{'editmyprofile'};
        $profiletitle = qq~$profile_txt{'editmyprofile'} ($user)~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle      = $profile_txt{'79'};
        $profiletitle = qq~$profile_txt{'79'} ($user)~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }

    if ( ${ $uid . $user }{'gender'} eq 'Male' ) {
        $GenderMale = ' selected="selected" ';
    }
    if ( ${ $uid . $user }{'gender'} eq 'Female' ) {
        $GenderFemale = ' selected="selected" ';
    }
    CalcAge( $user, 'parse' );

    my ( $editAgeTxt, $editAgeCount, $disableBdayFields, $editGenderTxt,
        $editGenderCount, $disableGenderField, $genderField, $bdayFields );
    $editGenderLimit ||= 0;
    if (   $editGenderLimit > 0
        && !$iamadmin
        && ( !$iamgmod || !$allow_gmod_profile ) )
    {
        if ( $editGenderLimit == 1 && ${ $uid . $user }{'gender'} eq q{} ) {
            $editGenderTxt = qq~$profile_txt{'gender_edit_1'}~;
        }
        elsif ( ${ $uid . $user }{'disablegender'} >= $editGenderLimit ) {
            $editGenderTxt      = qq~$profile_txt{'gender_edit_3'}~;
            $disableGenderField = q~ disabled="disabled"~;
            $genderField        = qq~
<input type="hidden" name="gender" value="${ $uid . $user }{'gender'}" />~;
        }
        elsif (${ $uid . $user }{'disablegender'} eq q{}
            && ${ $uid . $user }{'gender'} eq q{} )
        {
            if ( $editGenderCount == 1 ) {
                $editGenderTxt =
qq~ $profile_txt{'gender_edit_2'} $editGenderLimit $profile_txt{'dob_edit_5'}~;
            }
            else {
                $editGenderTxt =
qq~ $profile_txt{'gender_edit_2'} $editGenderLimit $profile_txt{'dob_edit_6'}~;
            }
        }
        elsif ( ${ $uid . $user }{'disablegender'} < $editGenderLimit ) {
            $editGenderCount =
              $editGenderLimit - ${ $uid . $user }{'disablegender'};
            if ( $editGenderCount == 1 ) {
                $editGenderTxt =
qq~ $profile_txt{'gender_edit_2'} $editGenderCount $profile_txt{'dob_edit_3'}~;
            }
            else {
                $editGenderTxt =
qq~ $profile_txt{'gender_edit_2'} $editGenderCount $profile_txt{'dob_edit_4'}~;
            }
        }
        $editGenderTxt = qq~<br /><span class="small">$editGenderTxt</span>~;
    }

    $editAgeLimit ||= 0;
    if ( $editAgeLimit > 0 && !$iamadmin && ( !$iamgmod || !$allow_gmod_profile ) )
    {
        if ( $editAgeLimit == 1 && ${ $uid . $user }{'disableage'} eq q{} ) {
            $editAgeTxt = qq~$profile_txt{'dob_edit_1'}~;
        }
        elsif ( ${ $uid . $user }{'disableage'} >= $editAgeLimit && ${ $uid . $user }{'bday'} ne q{}) {
            $editAgeTxt        = qq~$profile_txt{'dob_edit_7'}~;
            $disableBdayFields = q~ disabled="disabled"~;
            $bdayFields        = qq~
<input type="hidden" name="bday1" value="$umonth" />
<input type="hidden" name="bday2" value="$uday" />
<input type="hidden" name="bday3" value="$uyear" />~;
        }
        elsif (${ $uid . $user }{'disableage'} eq q{}
            && ${ $uid . $user }{'bday'} eq q{} )
        {
            if ( $editAgeCount == 1 ) {
                $editAgeTxt .=
qq~ $profile_txt{'dob_edit_2'} $editAgeLimit $profile_txt{'dob_edit_5'}~;
            }
            else {
                $editAgeTxt .=
qq~ $profile_txt{'dob_edit_2'} $editAgeLimit $profile_txt{'dob_edit_6'}~;
            }
        }
        elsif ( ${ $uid . $user }{'disableage'} < $editAgeLimit ) {
            $editAgeCount = $editAgeLimit - ${ $uid . $user }{'disableage'};
            if ( $editAgeCount == 1 ) {
                $editAgeTxt .=
qq~ $profile_txt{'dob_edit_2'} $editAgeCount $profile_txt{'dob_edit_3'}~;
            }
            else {
                $editAgeTxt .=
qq~ $profile_txt{'dob_edit_2'} $editAgeCount $profile_txt{'dob_edit_4'}~;
            }
        }
        $editAgeTxt = qq~<br /><span class="small">$editAgeTxt</span>~;
    }

    my $timeorder;
    my @selist = ( 2, 3, 6, 8 );
    if ( ${ $uid . $user }{'timeselect'} ) {
        for my $i (@selist) {
            if ( ${ $uid . $user }{'timeselect'} == $i ) { $timeorder = 1; }
        }
    }
    else {
        for my $i (@selist) {
            if ( $timeselected == $i ) { $timeorder = 1; }
        }
    }

    $selectyear = q{};
    $seluyear =
qq~$profile_txt{'566'}<select name="bday3"$disableBdayFields><option value="">--</option>\n~;
    for my $e ( 1905 .. ( $year - 3 ) ) {
        $seluyear .=
          qq~<option value="$e" ${isselected($uyear == $e)}>$e</option>\n~;
    }
    $seluyear .= q~</select> ~;

    $selectmnth = q{};
    $dayormonthm =
qq~<label for="bday1">$profile_txt{'564'}</label><select name="bday1" id="bday1"$disableBdayFields><option value="">--</option>\n~;
    for my $bb ( 1 .. 12 ) {
        if   ( $bb < 10 ) { $c = "0$bb"; }
        else              { $c = $bb; }
        $dayormonthm .=
          qq~<option value="$c" ${isselected($umonth == $bb)}>$c</option>\n~;
    }
    $dayormonthm .= q~</select> ~;

    $selectday = q{};
    $dayormonthd =
qq~<label for="bday2">$profile_txt{'565'}</label><select name="bday2" id="bday2"$disableBdayFields><option value="">--</option>\n~;
    for my $aa ( 1 .. 31 ) {
        if   ( $aa < 10 ) { $d = "0$aa"; }
        else              { $d = $aa; }
        $dayormonthd .=
          qq~<option value="$d" ${isselected($uday == $aa)}>$d</option>\n~;
    }
    $dayormonthd .= q~</select> ~;

    if   ($timeorder) { $dayormonth = $dayormonthd . $dayormonthm; }
    else              { $dayormonth = $dayormonthm . $dayormonthd; }
    $dayormonth =~ s/for="bday\d"/for="birthday"/oxsm;
    $dayormonth =~ s/id="bday\d"/id="birthday"/oxsm;

    $my_newpass  = ( $INFO{'newpassword'} ? $profile_txt{'80'} : q{} );
    $my_passchk  = password_check();
    $my_name_not = q{};
    if ($name_cannot_be_userid) {
        $my_name_not = qq~
                        <span class="small">$profile_txt{'8'}</span></label>~;
    }
    if ( $showage == 1 ) {
        my $checked = q{};
        if ( ${ $uid . $user }{'hideage'} ) { $checked = ' checked="checked"'; }
        $my_showageshow = $myprofile_showage;
        $my_showageshow =~ s/{yabb agechecked}/$checked/sm;
    }

    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        my $show_ext_prof = ext_editprofile( $user, 'edit' );
        $my_show_ext_prof = $show_ext_prof;
    }

    if ( $birthday_on_reg > 1 ) {
        $myrequirebd = qq~ <span class="small">$profile_txt{'563b'}</span>~;
    }
    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$INFO{'username'}};sid=$INFO{'sid'}" method="post" name="creator" accept-charset="$yymycharset">
$myprofile_edit~;
    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb my_newpass}/$my_newpass/sm;
    $showProfile =~ s/{yabb my_passchk}/$my_passchk/sm;
    $showProfile =~ s/{yabb my_name_not}/$my_name_not/sm;
    $showProfile =~ s/{yabb user}/${$uid.$user}{'realname'}/gsm;
    $showProfile =~ s/{yabb editGenderTxt}/$editGenderTxt/sm;
    $showProfile =~ s/{yabb disableGenderField}/$disableGenderField/sm;
    $showProfile =~ s/{yabb GenderMale}/$GenderMale/sm;
    $showProfile =~ s/{yabb GenderFemale}/$GenderFemale/sm;
    $showProfile =~ s/{yabb genderField}/$genderField/sm;
    $showProfile =~ s/{yabb editAgeTxt}/$editAgeTxt/sm;
    $showProfile =~ s/{yabb require_bd}/$myrequirebd/sm;
    $showProfile =~ s/{yabb bdaysel}/$dayormonth$seluyear$bdayFields/sm;
    $showProfile =~ s/{yabb showageshow}/$my_showageshow/sm;
    $showProfile =~ s/{yabb user_location}/${$uid.$user}{'location'}/sm;
    $showProfile =~ s/{yabb my_show_ext_prof}/$my_show_ext_prof/sm;
## Mod Hook showProfile1 ##

    if (   $sessions == 1
        && $sessionvalid == 1
        && ($staff)
        && $username eq $user )
    {
        LoadLanguage('Sessions');
        my $decanswer = ${ $uid . $user }{'sesanswer'};
        $questsel = qq~<select name="sesquest" id="sesquest" size="1">\n~;
        while ( ( $key, $val ) = each %sesquest_txt ) {
            if (   ${ $uid . $user }{'sesquest'} eq $key
                && ${ $uid . $user }{'sesquest'} ne q{} )
            {
                $sessel = q~ selected="selected"~;
            }
            elsif ( $key eq 'password' && ${ $uid . $user }{'sesquest'} eq q{} )
            {
                $sessel = q~ selected="selected"~;
            }
            else {
                $sessel = q{};
            }
            $questsel .= qq~<option value="$key"$sessel>$val</option>\n~;
        }
        $questsel .= qq~</select>\n~;
        $showProfile .= $myprofile_session;
        $showProfile =~ s/{yabb questsel}/$questsel/sm;
        $showProfile =~ s/{yabb decanswer}/$decanswer/sm;
        $showProfile =~ s/{yabb sesstext9}/$session_txt{'9'}/sm;
        $showProfile =~ s/{yabb sesstext9a}/$session_txt{'9a'}/sm;
    }
    if ( $self_del_user == 1 ) {
        if (   ( $iamadmin && ( $username ne $user ) )
            || ( $username ne 'admin' ) )
        {
            $show_confdel =
qq~ &nbsp; &nbsp; &nbsp; <input type="submit" name="moda" value="$profile_txt{'89'}" onclick="return confirm('$confdel_text')" class="button" />~;
        }
    }
    else {
        if ( $iamadmin && $username ne $user ) {
            $show_confdel =
qq~ &nbsp; &nbsp; &nbsp; <input type="submit" name="moda" value="$profile_txt{'89'}" onclick="return confirm('$confdel_text')" class="button" />~;
        }
    }
    $showProfile .= $myprofile_bottom;
    $showProfile =~ s/{yabb show_confdel}/$show_confdel/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfileContacts {
    SidCheck($action);
    PrepareProfile();

    $menucolors[1] = 'selected-bg';
    ProfileMenu();

    my $scriptAction = q~profileContacts2~;
    if ($view) {
        $scriptAction = q~myprofileContacts2~;
        $yytitle =
          qq~$profile_txt{'editmyprofile'} &rsaquo; $profile_txt{'819'}~;
        $profiletitle =
qq~$profile_txt{'editmyprofile'} ($user) &rsaquo; $profile_txt{'819'}~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle = qq~$profile_txt{'79'} &rsaquo; $profile_txt{'819'}~;
        $profiletitle =
          qq~$profile_txt{'79'} ($user) &rsaquo; $profile_txt{'819'}~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }

    ${ $uid . $user }{'aim'} =~ tr/+/ /;
    ${ $uid . $user }{'yim'} =~ tr/+/ /;
    if ($allow_hide_email) {
        my $checked = q{};
        if ( ${ $uid . $user }{'hidemail'} ) {
            $checked = ' checked="checked"';
        }
        $my_hidemail = $myprofile_hidemail;
        $my_hidemail =~ s/{yabb checked}/$checked/sm;
    }

    if ( !$minlinkweb ) { $minlinkweb = 0; }
    if (   ${ $uid . $user }{'postcount'} >= $minlinkweb
        || ${ $uid . $user }{'position'} eq 'Administrator'
        || ${ $uid . $user }{'position'} eq 'Global Moderator' )
    {
        $my_minlinkweb = $myprofile_minlinkweb;
        $my_minlinkweb =~ s/{yabb my_webtitle}/${$uid.$user}{'webtitle'}/sm;
        $my_minlinkweb =~ s/{yabb my_weburl}/${$uid.$user}{'weburl'}/sm;
    }
    if (
        $pm_lev == 1
        && (
            $enable_MCaway > 2
            || (
                $enable_MCaway
                && (   ${ $uid . $user }{'position'} eq 'Administrator'
                    || ${ $uid . $user }{'position'} eq 'Global Moderator'
                    || ${ $uid . $user }{'position'} eq 'Mid Moderator'
                    || is_moderator($user) )
            )
        )
      )
    {
        my $offChecked  = q~ selected="selected"~;
        my $awayChecked = q{};

        if ( ${ $uid . $user }{'offlinestatus'} eq 'away' ) {
            $offChecked  = q{};
            $awayChecked = q~ selected="selected"~;
        }

        my $awayreply = ${ $uid . $user }{'awayreply'};
        $awayreply =~ s/<br \/>/\n/gsm;
        $my_away = $myprofile_away;
        $my_away .=
qq~             <textarea name="awayreply" id="awayreply" rows="4" cols="50">$awayreply</textarea><br />~;
        $my_away .= $myprofile_away_b;
        $my_away =~ s/{yabb offChecked}/$offChecked/sm;
        $my_away =~ s/{yabb awayChecked}/$awayChecked/sm;
        $my_away =~ s/{yabb MaxAwayLen}/$MaxAwayLen/gsm;
    }
    if (
        (
               ${ $uid . $user }{'position'} eq 'Administrator'
            || ${ $uid . $user }{'position'} eq 'Global Moderator'
        )
        && $enable_MCstatusStealth
      )
    {
        my $stealthChecked = q{};
        if ( ${ $uid . $user }{'stealth'} ) {
            $stealthChecked = ' checked="checked"';
        }
        $my_stealth = $myprofile_stealth;
        $my_stealth =~ s/{yabb stealthChecked}/$stealthChecked/sm;
    }

    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        $my_extended .= ext_editprofile( $user, 'contact' );
    }

    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$INFO{'username'}};sid=$INFO{'sid'}" method="post" name="creator" accept-charset="$yymycharset">
$myprofile_contact
~;
    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb user_email}/${$uid.$user}{'email'}/sm;
    $showProfile =~ s/{yabb my_hidemail}/$my_hidemail/sm;
    $showProfile =~ s/{yabb my_icq}/${$uid.$user}{'icq'}/sm;
    $showProfile =~ s/{yabb my_aim}/${$uid.$user}{'aim'}/sm;
    $showProfile =~ s/{yabb my_yim}/${$uid.$user}{'yim'}/sm;
    $showProfile =~ s/{yabb my_gtalk}/${$uid.$user}{'gtalk'}/sm;
    $showProfile =~ s/{yabb my_skype}/${$uid.$user}{'skype'}/sm;
    $showProfile =~ s/{yabb my_myspace}/${$uid.$user}{'myspace'}/sm;
    $showProfile =~ s/{yabb my_facebook}/${$uid.$user}{'facebook'}/sm;
    $showProfile =~ s/{yabb my_twitter}/${$uid.$user}{'twitter'}/sm;
    $showProfile =~ s/{yabb my_youtube}/${$uid.$user}{'youtube'}/sm;
    $showProfile =~ s/{yabb my_minlinkweb}/$my_minlinkweb/sm;
    $showProfile =~ s/{yabb my_away}/$my_away/sm;
    $showProfile =~ s/{yabb my_stealth}/$my_stealth/sm;
    $showProfile =~ s/{yabb my_extended}/$my_extended/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfileOptions {
    SidCheck($action);
    PrepareProfile();

    $menucolors[2] = 'selected-bg';
    ProfileMenu();

    my $scriptAction = q~profileOptions2~;
    if ($view) {
        $scriptAction = q~myprofileOptions2~;
        $yytitle =
          qq~$profile_txt{'editmyprofile'} &rsaquo; $profile_txt{'818'}~;
        $profiletitle =
qq~$profile_txt{'editmyprofile'} ($user) &rsaquo; $profile_txt{'818'}~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle = qq~$profile_txt{'79'} &rsaquo; $profile_txt{'818'}~;
        $profiletitle =
          qq~$profile_txt{'79'} ($user) &rsaquo; $profile_txt{'818'}~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }

    if ( $allowpics && $upload_useravatar && $upload_avatargroup ) {
        $upload_useravatar = 0;
        foreach my $av_gr ( split /, /sm, $upload_avatargroup ) {
            if ( $av_gr eq ${ $uid . $user }{'position'} ) {
                $upload_useravatar = 1;
                last;
            }
            foreach ( split /,/xsm, ${ $uid . $user }{'addgroups'} ) {
                if ( $av_gr eq $_ ) { $upload_useravatar = 1; last; }
            }
        }
    }

    $my_allow_avatars = (
        ( $allowpics && $upload_useravatar )
        ? q~ enctype="multipart/form-data"~
        : q{}
    );

    if ($allowpics) {
        opendir( DIR, $facesdir )
          or fatal_error( 'cannot_open_dir',
            "($facesdir)!<br />$profile_txt{'681'}", 1 );
        @contents = readdir DIR;
        closedir DIR;
        $images = q{};
        foreach my $line ( sort @contents ) {
            ( $name, $extension ) = split /\./xsm, $line;
            $checked = q{};
            if ( $line eq ${ $uid . $user }{'userpic'} ) {
                $checked = ' selected="selected"';
            }
            if ( ${ $uid . $user }{'userpic'} =~ m{\Ahttps?://}sm
                && $line eq $my_blank_avatar )
            {
                $checked = ' selected="selected" ';
            }
            if (   $extension =~ /gif/ism
                || $extension =~ /jpg/ism
                || $extension =~ /jpeg/ism
                || $extension =~ /png/ism )
            {
                if ( $line eq $my_blank_avatar ) {
                    $images =
qq~                <option value="$line"$checked>$profile_txt{'422'}</option>\n$images~;
                }
                else {
                    $images .=
qq~                <option value="$line"$checked>$name</option>\n~;
                }
            }
        }
        my ( $pic, $s, $alt );
        my $tmp = $facesurl;
        if ( $tmp =~ /^(http(s?):\/\/)/xsm ) {
            ( $tmp, $s ) = ( $1, $2 );
        }
        if ( ${ $uid . $user }{'userpic'} =~ m{\Ahttps?://}sm ) {
            $pic     = ${ $uid . $user }{'userpic'};
            $checked = ' checked="checked" ';
            $tmp     = ${ $uid . $user }{'userpic'};
            if ($upload_useravatar) { $alt = $profile_txt{'473'}; }
        }
        else {
            $pic = "$facesurl/${$uid.$user}{'userpic'}";
        }

        $avatar_limit ||= 0;
        $my_up_avatar_a = (
            $upload_useravatar
            ? qq~<br />
            $profile_txt{'476'} $avatar_limit KB~
            : q{}
        );
        $my_up_avatar_b = (
            $upload_useravatar
            ? q~<br />
            <br />
            <input type="file" name="file_avatar" size="50" />~
            : q{}
        );

        $my_show_avatar = $myprofile_show_avatar_a;
        $my_show_avatar =~ s/{yabb my_up_avatar_a}/$my_up_avatar_a/sm;
        $my_show_avatar =~ s/{yabb my_up_avatar_b}/$my_up_avatar_b/sm;
        $my_show_avatar =~ s/{yabb av_pic}/$pic/sm;
        $my_show_avatar =~ s/{yabb av_alt}/$alt/sm;
        $my_show_avatar =~ s/{yabb av_s}/$s/gsm;
        $my_show_avatar =~ s/{yabb av_tmp}/$tmp/sm;
        $my_show_avatar =~ s/{yabb images}/$images/sm;
        $my_show_avatar =~ s/{yabb checked}/$checked/sm;
    }

    $signature = ${ $uid . $user }{'signature'};
    $signature =~ s/<br.*?>/\n/gsm;

    if ( $addmemgroup_enabled > 1 && %NoPost ) {
        my ( $addmemgroup, $selsize ) =
          DrawGroups( ${ $uid . $user }{'addgroups'},
            ${ $uid . $user }{'position'}, 0 );

        if ( $addmemgroup ) {
            $my_addmemgroup = $myprofile_addmemgroup;
            $my_addmemgroup =~ s/{yabb selsize}/$selsize/sm;
            $my_addmemgroup =~ s/{yabb addmemgroup}/$addmemgroup/sm;
        }
    }

    if (   $NewNotificationAlert
        || $enable_notifications == 1
        || $enable_notifications == 3 )
    {
        if ($NewNotificationAlert) {
            $my_notify_a = q~
                        <input type="checkbox" value="1" name="onlinealert" id="onlinealert"~
              . (
                ${ $uid . $user }{'onlinealert'} ? ' checked="checked"' : q{} )
              . qq~ /> <label for="onlinealert">$profile_txt{'onlinealertexplain'}</label>~;
        }
        if ( $enable_notifications == 1 || $enable_notifications == 3 ) {
            if ($NewNotificationAlert) {
                $my_notify_b = q~<br />
                        <br />~;
            }

            $my_notify_b .= qq~
                        <label for="notify_N">$profile_txt{'326'}</label>?&nbsp;<select name="notify_N" id="notify_N">
                        <option value="0"~
              . (
                (
                        !${ $uid . $user }{'notify_me'}
                      || ${ $uid . $user }{'notify_me'} == 2
                ) ? ' selected="selected"' : q{}
              )
              . qq~>$profile_txt{'164'}</option>
                        <option value="1"~
              . (
                (
                         ${ $uid . $user }{'notify_me'} == 1
                      || ${ $uid . $user }{'notify_me'} == 3
                ) ? ' selected="selected"' : q{}
              )
              . qq~>$profile_txt{'163'}</option>
                        </select>~;
        }
        $my_notify = $myprofile_notify;
        $my_notify =~ s/{yabb my_notify_a}/$my_notify_a/sm;
        $my_notify =~ s/{yabb my_notify_b}/$my_notify_b/sm;
    }

    if ($ttsureverse) {
        if ( !exists( ${ $uid . $user }{'reversetopic'} ) ) {
            ${ $uid . $user }{'reversetopic'} = $ttsreverse;
        }
        $my_reversi =
          ${ $uid . $user }{'reversetopic'} ? q~ checked="checked"~ : q{};
        $my_reverse = $myprofile_reverse;
        $my_reverse =~ s/{yabb my_reversi}/$my_reversi/sm;
    }

    my $rts = ${ $uid . $user }{'return_to'};
    for my $rt ( 1 .. 3 ) {
        $return_to_select .=
          $rts == $rt
          ? qq~<option value="$rt" selected="selected">$return_to_txt{$rt}</option>~
          : qq~<option value="$rt">$return_to_txt{$rt}</option>~;
    }
    my $return_to = $myprofile_return_to;
    $return_to =~ s/{yabb return_to_select}/$return_to_select/sm;

    my $tmptcnt = 0;
    foreach my $curtemplate (
        sort { $templateset{$a} cmp $templateset{$b} }
        keys %templateset
      )
    {
        $drawndirs .=
qq~<option value="$curtemplate"${isselected($curtemplate eq ${ $uid . $user }{'template'})}>$curtemplate</option>\n~;
        $tmptcnt++;
    }

    my $my_template = q{};
    if ( $tmptcnt > 1 ) {
    $my_template = $myprofile_template;
    $my_template =~ s/{yabb drawndirs}/$drawndirs/sm;
    }

    opendir DIR, $langdir;
    my @lfilesanddirs = readdir DIR;
    closedir DIR;
    my $lngcnt = 0;
    foreach my $fld ( sort { lc($a) cmp lc $b } @lfilesanddirs ) {
        if ( -e "$langdir/$fld/Main.lng" ) {
            my $displang = $fld;
            $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
            $drawnldirs .=
qq~<option value="$fld" ${isselected(${ $uid . $user }{'language'} eq $fld)}>$displang</option>~;
            $lngcnt++;
        }
    }

    my $my_show_lang = q{};
    if ( $lngcnt > 1 ) {
        $my_show_lang = $myprofile_show_lang;
        $my_show_lang =~ s/{yabb drawnldirs}/$drawnldirs/sm;
    }

    if ( $user_hide_avatars && $showuserpic && $allowpics )
    {    # checkbox to hide avatars in threads
        $my_show_avatar_opts = $myprofile_show_avatars;
        $my_hide_avatar =
          ${ $uid . $user }{'hide_avatars'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~ s/{yabb user_showavatar}/$my_hide_avatar/sm;
    }
    else { $my_show_avatar_opts = q{}; }

    if ( $user_hide_user_text && $showusertext )
    {    # checkbox to hide user-text in threads
        $my_show_avatar_opts .= $myprofile_hide_user_text;
        $my_hide_user_text =
          ${ $uid . $user }{'hide_user_text'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~ s/{yabb hide_user_text}/$my_hide_user_text/sm;
    }

    if ($user_hide_img) {    # checkbox to hide images in threads
        $my_show_avatar_opts .= $myprofile_hide_img;
        $my_hide_img =
          ${ $uid . $user }{'hide_img'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~ s/{yabb hide_img}/$my_hide_img/sm;
    }

    $allowattach ||= 0;
    if ( $user_hide_attach_img && $allowattach > 0 )
    {                        # checkbox to hide attached images in threads
        $my_show_avatar_opts .= $myprofile_hide_attach_img;
        $my_hide_attach_img =
          ${ $uid . $user }{'hide_attach_img'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~ s/{yabb hide_attach_img}/$my_hide_attach_img/sm;
    }

    if ($user_hide_signat) {    # checkbox to hide signatures in threads
        $my_show_avatar_opts .= $myprofile_hide_signat;
        $my_hide_signat =
          ${ $uid . $user }{'hide_signat'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~ s/{yabb hide_signat}/$my_hide_signat/sm;
    }

    if ( $user_hide_smilies_row && !$removenormalsmilies )
    {  # checkbox to hide the row of smilies below the the post-message-inputbox
        $my_show_avatar_opts .= $myprofile_hide_smilies_row;
        $my_hide_smilies_row =
          ${ $uid . $user }{'hide_smilies_row'} ? ' checked="checked"' : q{};
        $my_show_avatar_opts =~
          s/{yabb hide_smilies_row}/$my_hide_smilies_row/sm;
    }

    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        $my_extprofile = ext_editprofile( $user, 'options' );
    }

    my $cnnn = 0;
    for my $i ( 1 .. 5 ) {
        if ( ${ $uid . $user }{'numberformat'} == $i ) {
            $unfsl[$i] = ' selected="selected" ';
            $cnnn++;
        }
        else { $unfsl[$i] = q{}; }
    }
    for my $i ( 1 .. 5 ) {
        if ( $forumnumberformat == $i && $cnnn == 0 ) {
            $unfsl[$i] = ' selected="selected" ';
        }
    }

    my $cntm = 0;
    for my $j ( 1 .. 8 ) {
        if ( ${ $uid . $user }{'timeselect'} == $j ) {
            $tsl[$j] = ' selected="selected" ';
            $cntm++;
        }
        else { $tsl[$j] = q{}; }
    }
    for my $j ( 1 .. 8 ) {
        if ( $timeselected == $j && $cntm == 0 ) {
            $tsl[$j] = ' selected="selected" ';
        }
    }

    $my_num_option = qq~<option value="1"$unfsl[1]>10987.65</option>
                <option value="2"$unfsl[2]>10987,65</option>
                <option value="3"$unfsl[3]>10,987.65</option>
                <option value="4"$unfsl[4]>10.987,65</option>
                <option value="5"$unfsl[5]>10 987,65</option>~;

    $my_time_option = qq~<option value="1"$tsl[1]>$profile_txt{'480'}</option>
                <option value="5"$tsl[5]>$profile_txt{'484'}</option>
                <option value="4"$tsl[4]>$profile_txt{'483'}</option>
                <option value="8"$tsl[8]>$profile_txt{'483a'}</option>
                <option value="2"$tsl[2]>$profile_txt{'481'}</option>
                <option value="3"$tsl[3]>$profile_txt{'482'}</option>
                <option value="6"$tsl[6]>$profile_txt{'485'}</option>~;
    $my_timeformat = timeformat( $date, 1 );

    if ($enabletz) {
        eval {
            require DateTime;
            require DateTime::TimeZone;
        };
        my $user_tz_select = q{};
        $default_tz ||= 'UTC';
        if ( !$EVAL_ERROR ) {
            require DateTime;
            require DateTime::TimeZone;
            LoadLanguage('Countries');
            $mytz = ${ $uid . $user }{'user_tz'} || $default_tz;
            my @mycntry = sort { $countrytime_txt{$a} cmp $countrytime_txt{$b} } keys %countrytime_txt;
            my $myselect = q{};
            if ( $mytz eq 'UTC' ) {
                $myselect = ' selected="selected"';
            }
            $user_tz_select = q~<br /><select name="user_tz" id="user_tz">~;
            $user_tz_select .= qq~<option value="UTC"$myselect>UTC</option>~;
            for my $i (@mycntry) {
                {
                    if ( $i eq $mytz ) {
                        $myselect = ' selected="selected"';
                    }
                    else { $myselect = q{}; }
                    $user_tz_select .=
qq~<option value="$i"$myselect>$countrytime_txt{$i}</option>~;
                }
            }
            $user_tz_select .= q~</select>~;
        }
        else {
            $mytz = ${ $uid . $user }{'user_tz'} || $default_tz;
            $localopt = q{};
            if ( $mytz eq 'local' ) {
                $myselectb = ' selected="selected"';
            }
            elsif ( $mytz eq 'UTC' ) {
                $myselecta = ' selected="selected"';
            }
            if ( $default_tz eq 'local' ) {
                $localopt =
qq~\n<option value="local"$myselectb>$profile_txt{'372a'}</option>~;
            }
            $user_tz_select = q~<br /><select name="user_tz" id="user_tz">~;
            $user_tz_select .= qq~<option value="UTC"$myselecta>UTC</option>~;
            $user_tz_select .= $localopt;
            $user_tz_select .= q~</select>~;
        }
        $my_tz = $my_tz_select;
        $my_tz =~ s/{yabb my_user_tz}/$user_tz_select/sm;

    }
    else { $my_tz = q{}; }

    $my_dynamic =
      ${ $uid . $user }{'dynamic_clock'} ? ' checked="checked"' : q{};

    $my_time = $myprofile_time;
    $my_time =~ s/{yabb my_num_option}/$my_num_option/sm;
    $my_time =~ s/{yabb my_time_option}/$my_time_option/sm;
    $my_time =~ s/{yabb timeformat}/${$uid.$user}{'timeformat'}/sm;
    $my_time =~ s/{yabb my_timeformat}/$my_timeformat/sm;
    $my_time =~ s/{yabb my_tz_select}/$my_tz/sm;
    $my_time =~ s/{yabb my_dynamic}/$my_dynamic/sm;

    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$INFO{'username'}};sid=$INFO{'sid'}" method="post" name="creator"$my_allow_avatars>~;
    $showProfile .= $myprofile_options;
    $showProfile .=
qq~         <textarea name="signature" id="signature" rows="4" cols="30" class="width_100">$signature</textarea><br />~;
    $showProfile .= $myprofile_options_b;

    $showProfile =~ s/{yabb usertext}/${$uid.$user}{'usertext'}/sm;
    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb my_show_avatar}/$my_show_avatar/sm;
    $showProfile =~ s/{yabb MaxSigLen}/$MaxSigLen/gsm;
    $showProfile =~ s/{yabb my_addmemgroup}/$my_addmemgroup/sm;
    $showProfile =~ s/{yabb my_time}/$my_time/sm;
    $showProfile =~ s/{yabb my_notify}/$my_notify/sm;
    $showProfile =~ s/{yabb my_reverse}/$my_reverse/sm;
    $showProfile =~ s/{yabb my_return_to}/$return_to/sm;
    $showProfile =~ s/{yabb my_template}/$my_template/sm;
    $showProfile =~ s/{yabb my_show_lang}/$my_show_lang/sm;
    $showProfile =~ s/{yabb my_show_avatar_opts}/$my_show_avatar_opts/sm;
    $showProfile =~ s/{yabb my_extprofile}/$my_extprofile/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;

## Mod Hook showProfile_options ##

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfileBuddy {
    SidCheck($action);
    PrepareProfile();

    $menucolors[3] = 'selected-bg';
    ProfileMenu();

    my $scriptAction = q~profileBuddy2~;
    if ($view) {
        $scriptAction = q~myprofileBuddy2~;
        $yytitle =
qq~$profile_txt{'editmyprofile'} &rsaquo; $profile_buddy_list{'buddylist'}~;
        $profiletitle =
qq~$profile_txt{'editmyprofile'} ($user) &rsaquo; $profile_buddy_list{'buddylist'}~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle =
          qq~$profile_txt{'79'} &rsaquo; $profile_buddy_list{'buddylist'}~;
        $profiletitle =
qq~$profile_txt{'79'} ($user) &rsaquo; $profile_buddy_list{'buddylist'}~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }

    if ( !$yyjavascript ) { $yyjavascript = q{}; }
    $yyjavascript .= qq~
        function imWin() {
                window.open('$scripturl?action=imlist;sort=mlletter;toid=buddylist','Blist','status=no,height=345,width=464,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
        }
        // removes a user from the list
        function removeUser(oElement) {
                var oList = oElement.options;
                var indexToRemove = oList.selectedIndex;
                if (oList.length > 1 || (oList.length == 1 && oList[0].value != '0')) {
                        //alert('element [' + oElement.options[indexToRemove].value + ']');
                        if (confirm("$profile_buddy_list{'removealert'}")) {
                                oElement.remove(indexToRemove);
                        }
                }
        }
        function selectblNames() {
                var oList = document.getElementById('buddylist');
                for (var i = 0; i < oList.options.length; i++) {
                        oList.options[i].selected = true;
                }
        }
        ~;

    my $buildBuddyList = q{};
    if ( ${ $uid . $user }{'buddylist'} ) {
        my @buddies = split /\|/xsm, ${ $uid . $user }{'buddylist'};
        chomp @buddies;
        foreach my $buddy (@buddies) {
            LoadUser($buddy);
            if ( ${ $uid . $buddy }{'realname'} ) {
                $buildBuddyList .=
qq~<option value="$buddy">${$uid.$buddy}{'realname'}</option>~;
            }
        }
    }

    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$INFO{'username'}};sid=$INFO{'sid'}" method="post" name="creator" onsubmit="javascript: selectblNames();">~;
    $showProfile .= $myprofile_buddy;

    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb buildBuddyList}/$buildBuddyList/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfileIM {
    SidCheck($action);
    PrepareProfile();

    $menucolors[4] = 'selected-bg';
    ProfileMenu();

    $yyjavascript .= qq~
        function imWin() {
                window.open('$scripturl?action=imlist;sort=mlletter;toid=ignore','Ilist','status=no,height=345,width=464,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
        }
        // removes a user from the list
        function removeUser(oElement) {
                var oList = oElement.options;
                var indexToRemove = oList.selectedIndex;
                if (oList.length > 1 || (oList.length == 1 && oList[0].value != '0')) {
                        //alert('element [' + oElement.options[indexToRemove].value + ']');
                        if (confirm("$profile_buddy_list{'removealert'}")) {
                                oElement.remove(indexToRemove);
                        }
                }
        }
        function selectINames()        {
                var oList = document.getElementById('ignore');
                for (var i = 0; i < oList.options.length; i++) {
                        oList.options[i].selected = true;
                        }
                }
        ~;

    my $scriptAction = q~profileIM2~;
    if ($view) {
        $scriptAction = q~myprofileIM2~;
        $yytitle =
          qq~$profile_txt{'editmyprofile'} &rsaquo; $profile_imtxt{'38'}~;
        $profiletitle =
qq~$profile_txt{'editmyprofile'} ($user) &rsaquo; $profile_imtxt{'38'}~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle = qq~$profile_txt{79} &rsaquo; $profile_imtxt{'38'}~;
        $profiletitle =
          qq~$profile_txt{79} ($user) &rsaquo; $profile_imtxt{'38'}~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }
    my $ignoreallChecked = q{};
    if ( ${ $uid . $user }{'im_ignorelist'} eq q{*} ) {
        $ignoreallChecked = ' checked="checked"';
    }
    if (   ${ $uid . $user }{'im_ignorelist'}
        && ${ $uid . $user }{'im_ignorelist'} ne q{*} )
    {
        my @ignoreList = split /\|/xsm, ${ $uid . $user }{'im_ignorelist'};
        chomp @ignoreList;
        foreach my $ignoreName (@ignoreList) {
            LoadUser($ignoreName);
            my $ignoreUser;
            if ( ${ $uid . $ignoreName }{'realname'} ) {
                $ignoreUser = ${ $uid . $ignoreName }{'realname'};
            }
            else { $ignoreUser = $ignoreName; }
            $ignoreName = cloak($ignoreName);
            $my_ignore .=
qq~\n                        <option value="$ignoreName">$ignoreUser</option>~;
        }
    }

    if ( $enable_notifications > 1 ) {
        $my_PM_notifyme =
          ${ $uid . $user }{'notify_me'} < 2 ? ' selected="selected"' : q{};
        $my_PM_notifyme_2 =
          ${ $uid . $user }{'notify_me'} > 1 ? ' selected="selected"' : q{};

        $my_PMnotify = $myprofile_PMnotify;
        $my_PMnotify =~ s/{yabb my_PM_notifyme}/$my_PM_notifyme/sm;
        $my_PMnotify =~ s/{yabb my_PM_notifyme_2}/$my_PM_notifyme_2/sm;
    }

    if ( ${ $uid . $user }{'im_popup'} ) {
        $enable_userimpopup = ' checked="checked"';
    }
    if ( ${ $uid . $user }{'im_imspop'} ) {
        $popup_userim = 'checked="checked"';
    }
    my $pmviewMessChecked;
    if ( ${ $uid . $user }{'pmviewMess'} ) {
        $pmviewMessChecked = ' checked="checked"';
    }
    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        $my_extprofile .= ext_editprofile( $user, 'im' );
    }

    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$INFO{'username'}};sid=$INFO{'sid'}" method="post" name="creator" onsubmit="javascript:selectINames();" >~;
    $showProfile .= $myprofile_PMpref;

    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb my_ignore}/$my_ignore/sm;
    $showProfile =~ s/{yabb enable_userimpopup}/$enable_userimpopup/sm;
    $showProfile =~ s/{yabb popup_userim}/$popup_userim/sm;
    $showProfile =~ s/{yabb pmviewMessChecked}/$pmviewMessChecked/sm;
    $showProfile =~ s/{yabb my_extprofile}/$my_extprofile/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;
    $showProfile =~ s/{yabb my_PMnotify}/$my_PMnotify/sm;

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfileAdmin {
    is_admin_or_gmod();
    SidCheck($action);
    PrepareProfile();

    $menucolors[5] = 'selected-bg';
    ProfileMenu();

    my @grps = sort keys %Group;
    my @memstat = ();
    $mygrp = 0;
    for ( @grps ) {
        if ( ${ $uid . $user }{'position'} eq $_ ) {
            @memstat = split /\|/xsm, $Group{$_};
            $tt = $memstat[0];
            $mygrp = 1;
        }
    }
    if ( $mygrp != 1) {
        if ( ${ $uid . $user }{'position'} ) {
        $ttgrp = ${ $uid . $user }{'position'};
        ( $tt, undef ) = split /\|/xsm, $NoPost{$ttgrp}, 2;
        }
        else { $tt = ${ $uid . $user }{'position'}; }
    }

    $regreason = ${ $uid . $user }{'regreason'};
    $regreason =~ s/<br \/>/\n/gsm;

    my ( $tta, $selsize );
    if (%NoPost) {
        ( $tta, $selsize ) =
          DrawGroups( ${ $uid . $user }{'addgroups'}, q{}, 1 );
    }

    $userlastlogin = timeformat( ${ $uid . $user }{'lastonline'} );
    $userlastpost  = timeformat( ${ $uid . $user }{'lastpost'} );
    $userlastim    = timeformat( ${ $uid . $user }{'lastim'} );
    if ( $userlastlogin eq q{} ) { $userlastlogin = $profile_txt{'470'}; }
    if ( $userlastpost eq q{} )  { $userlastpost  = $profile_txt{'470'}; }
    if ( $userlastim eq q{} )    { $userlastim    = $profile_txt{'470'}; }

    my $scriptAction = q~profileAdmin2~;
    if ($view) {
        $scriptAction = q~myprofileAdmin2~;
        $yytitle =
          qq~$profile_txt{'editmyprofile'} &rsaquo; $profile_txt{'820'}~;
        $profiletitle =
qq~$profile_txt{'editmyprofile'} ($user) &rsaquo; $profile_txt{'820'}~;
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?action=mycenter" class="nav">$img_txt{'mycenter'}</a> &rsaquo; $profiletitle~;
    }
    else {
        $yytitle = qq~$profile_txt{'79'} &rsaquo; $profile_txt{'820'}~;
        $profiletitle =
          qq~$profile_txt{'79'} ($user) &rsaquo; $profile_txt{'820'}~;
        $yynavigation = qq~&rsaquo; $profiletitle~;
    }
    if ( $iamadmin ) {
        for ( @grps ) {
            @memstat = split /\|/xsm, $Group{$_};
            $my_group .=
qq~\n                        <option value="$_">$memstat[0]</option>~;
        }
    }

    my $z = 0;
    for (@nopostorder) {
        @memstat = split /\|/xsm,
          $NoPost{$_}, 5;
        $my_group .= qq~<option value="$_">$memstat[0]</option>~;
        $z++;
    }

    if ( $tta ne q{} ) {
        $my_tta = $myprofile_tta;
        $my_tta =~ s/{yabb selsize}/$selsize/sm;
        $my_tta =~ s/{yabb tta}/$tta/sm;
    }

    (
        $dr_secund, $dr_minute, $dr_hour, $dr_day, $dr_month,
        $dr_year,   undef,      undef,    undef
      )
      = gmtime(
          ${ $uid . $user }{'regtime'}
        ? ${ $uid . $user }{'regtime'}
        : $forumstart
      );
    $dr_month++;

    if ( $dr_month > 12 ) { $dr_month = 12; }   ## month cannot be above 12!
    if ( $dr_month < 1 )  { $dr_month = 1; }    ## neither can it be less than 1
    if ( $dr_day > 31 )   { $dr_day   = 31; }   ## day of month over 31
    if ( $dr_day < 1 )    { $dr_day   = 1; }
    if ( length($dr_year) > 2 ) {
        $dr_year = substr $dr_year, length($dr_year) - 2, 2;
    }
    if ( $dr_year < 90 && $dr_year > 50 ) {
        $dr_year = 90;
    }    ## a year over 50 is taken to be 1990
    if ( $dr_year > 20 && $dr_year < 51 ) {
        $dr_year = 20;
    }    ## a year 50 or lower is taken to be 2020
    if ( $dr_hour > 23 )   { $dr_hour   = 23; }
    if ( $dr_minute > 59 ) { $dr_minute = 59; }
    if ( $dr_secund > 59 ) { $dr_secund = 59; }

    $sel_day = qq~
            <select name="dr_day">\n~;
    for my $i ( 1 .. 31 ) {
        $day_val = sprintf '%02d', $i;
        if ( $dr_day == $i ) {
            $sel_day .=
qq~                <option value="$day_val" selected="selected">$i</option>\n~;
        }
        else {
            $sel_day .=
              qq~                <option value="$day_val">$i</option>\n~;
        }
    }
    $sel_day .= qq~            </select>\n~;

    $sel_month = qq~
            <select name="dr_month">\n~;
    for my $i ( 0 .. 11 ) {
        $z = $i + 1;
        $month_val = sprintf '%02d', $z;
        if ( $dr_month == $z ) {
            $sel_month .=
qq~                <option value="$month_val" selected="selected">$months[$i]</option>\n~;
        }
        else {
            $sel_month .=
qq~                <option value="$month_val">$months[$i]</option>\n~;
        }
    }
    $sel_month .= qq~            </select>\n~;

    $sel_year = qq~
            <select name="dr_year">\n~;
    for my $i ( 1990 .. $year ) {
        my $year_val = substr $i, 2, 2;
        if ( $dr_year == $year_val ) {
            $sel_year .=
qq~                <option value="$year_val" selected="selected">$i</option>\n~;
        }
        else {
            $sel_year .=
              qq~                <option value="$year_val">$i</option>\n~;
        }
    }
    $sel_year .= q~            </select>~;

    $time_sel = ${ $uid . $username }{'timeselect'};
    if ( $time_sel == 1 || $time_sel == 4 || $time_sel == 5 ) {
        $all_date = qq~$sel_month $sel_day $sel_year~;
    }
    else { $all_date = qq~$sel_day $sel_month $sel_year~; }
    $all_date =~ s/<select name/<select id="dr_day_month" name/osm;

    $sel_hour = qq~
            <select name="dr_hour">\n~;
    for my $i ( 0 .. 23 ) {
        my $hour_val = sprintf '%02d', $i;
        if ( $dr_hour == $i ) {
            $sel_hour .=
qq~                        <option value="$hour_val" selected="selected">$hour_val</option>\n~;
        }
        else {
            $sel_hour .=
qq~                        <option value="$hour_val">$hour_val</option>\n~;
        }
    }
    $sel_hour .= qq~                        </select>\n~;

    $sel_minute = qq~
                        <select name="dr_minute">\n~;
    for my $i ( 0 .. 59 ) {
        $minute_val = sprintf '%02d', $i;
        if ( $dr_minute == $i ) {
            $sel_minute .=
qq~                        <option value="$minute_val" selected="selected">$minute_val</option>\n~;
        }
        else {
            $sel_minute .=
qq~                        <option value="$minute_val">$minute_val</option>\n~;
        }
    }
    $sel_minute .= q~                        </select>~;

    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        $my_extprofile .= ext_editprofile( $user, 'admin' );
    }

    $myprofile_userinfo =
      qq~<input type="hidden" name="username" value="$INFO{'username'}" />~;
    $showProfile .= qq~
<form action="$scripturl?action=$scriptAction;username=$useraccount{$user};sid=$INFO{'sid'}" method="post" name="creator">~;
    $showProfile .= $myprofile_admin_a;
    AddModerators();
    $showProfile .= $myprofile_admin_b;
    $showProfile .=
qq~<textarea rows="4" cols="50" name="regreason" id="regreason">$regreason</textarea>~;
    $showProfile .= $myprofile_admin_bb;

    $showProfile =~ s/{yabb profiletitle}/$profiletitle/sm;
    $showProfile =~ s/{yabb myprofile_userinfo}/$myprofile_userinfo/sm;
    $showProfile =~ s/{yabb postcount}/${$uid.$user}{'postcount'}/sm;
    $showProfile =~ s/{yabb position}/${$uid.$user}{'position'}/gsm;
    $showProfile =~ s/{yabb tt}/$tt/sm;
    $showProfile =~ s/{yabb my_tta}/$my_tta/sm;
    $showProfile =~ s/{yabb my_group}/$my_group/sm;
    $showProfile =~ s/{yabb all_date}/$all_date/sm;
    $showProfile =~ s/{yabb sel_hour}/$sel_hour/sm;
    $showProfile =~ s/{yabb sel_minute}/$sel_minute/sm;
    $showProfile =~ s/{yabb dr_secund}/$dr_secund/sm;
    $showProfile =~ s/{yabb regreason}/$regreason/sm;
    $showProfile =~ s/{yabb userlastlogin}/$userlastlogin/sm;
    $showProfile =~ s/{yabb userlastpost}/$userlastpost/sm;
    $showProfile =~ s/{yabb userlastim}/$userlastim/sm;
    $showProfile =~ s/{yabb my_extprofile}/$my_extprofile/sm;
    $showProfile =~ s/{yabb sid_expires}/$expiretxt/sm;

## Mod Hook showProfile_admin ##

    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub ModifyProfile2 {
    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//sm;
        $value =~ s/\s+\Z//sm;
        $value =~ s/[\n\r]//gxsm;
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} eq $profile_txt{'88'} ) {
        if (   $sessions == 1
            && $sessionvalid == 1
            && ( $iamadmin || $iamgmod )
            && $username eq $user )
        {
            if ( $member{'sesquest'} eq 'password' ) {
                $member{'sesanswer'} = q{};
            }
            elsif ( $member{'sesanswer'} eq q{} ) {
                fatal_error('no_secret_answer');
            }
        }

        if ( $member{'passwrd1'} || $member{'passwrd2'} ) {
            if ( $member{'passwrd1'} ne $member{'passwrd2'} ) {
                fatal_error( 'password_mismatch', "$member{'username'}" );
            }
            if ( $member{'passwrd1'} eq q{} ) {
                fatal_error( 'no_password', "$member{'username'}" );
            }
            if ( $member{'passwrd1'} =~
                /[^\s\w!\@#\$\%\^&\*\(\)\+\|`~\-=\\:;'",\.\/\?\[\]\{\}]/xsm )
            {
                fatal_error( 'invalid_character',
                    "$profile_txt{'36'} $profile_txt{'241'}" );
            }
            if ( $member{'username'} eq $member{'passwrd1'} ) {
                fatal_error('password_is_userid');
            }
        }

        if (   ${ $uid . $user }{'gender'}
            && $editGenderLimit
            && ${ $uid . $user }{'disablegender'} >= $editGenderLimit
            && !$iamadmin
            && ( !$iamgmod || !$allow_gmod_profile ) )
        {
            if ( $member{'gender'} ne ${ $uid . $user }{'gender'} ) {
                fatal_error('not_allowed_gender_edit');
            }
        }

        if (   ${ $uid . $user }{'bday'}
            && $editAgeLimit
            && ${ $uid . $user }{'disableage'} >= $editAgeLimit
            && !$iamadmin
            && ( !$iamgmod || !$allow_gmod_profile ) )
        {
            ( $user_birth_month, $user_birth_day, $user_birth_year ) =
              split /\//xsm, ${ $uid . $user }{'bday'};
            if (   $member{'bday1'} != $user_birth_month
                || $member{'bday2'} != $user_birth_day
                || $member{'bday3'} != $user_birth_year )
            {
                fatal_error('not_allowed_birthdate_change');
            }
        }

        if ( ( $birthday_on_reg > 1 && !$iamadmin && ( !$iamgmod || !$allow_gmod_profile ) ) && ( $member{'bday1'} eq q{} || $member{'bday2'} eq q{} || $member{'bday3'} eq q{} ) )
        {
            fatal_error( 'invalid_birthdate', "($member{'bday1'}/$member{'bday2'}/$member{'bday3'})" );
        }
         elsif ( $member{'bday1'} ne q{} || $member{'bday2'} ne q{} || $member{'bday3'} ne q{} ) {
            if ( $member{'bday1'} !~ /^[0-9]+$/xsm || $member{'bday2'} !~ /^[0-9]+$/xsm || $member{'bday3'} !~ /^[0-9]+$/xsm || length( $member{'bday3'} ) < 4 ) {
                fatal_error( 'invalid_birthdate',
                    "($member{'bday1'}/$member{'bday2'}/$member{'bday3'})" );
            }
            elsif (   $member{'bday1'} < 1
                || $member{'bday1'} > 12
                || $member{'bday2'} < 1
                || $member{'bday2'} > 31
                || $member{'bday3'} < 1901
                || $member{'bday3'} > $year - 5 )
            {
                fatal_error( 'invalid_birthdate',
                    "($member{'bday1'}/$member{'bday2'}/$member{'bday3'})" );
            }
        }
        $member{'bday1'} =~ s/[^0-9]//gxsm;
        $member{'bday2'} =~ s/[^0-9]//gxsm;
        $member{'bday3'} =~ s/[^0-9]//gxsm;
        if ( $member{'bday1'} ) {
            $member{'bday'} =
              "$member{'bday1'}/$member{'bday2'}/$member{'bday3'}";
        }
        else { $member{'bday'} = q{}; }

        if ( ${ $uid . $user }{'bday'} ne "$member{'bday'}" ) {
            $Update_EventCal = 1;
        }

        if (
            $editGenderLimit
            && (   ${ $uid . $user }{'gender'} ne $member{'gender'}
                || ${ $uid . $user }{'gender'} eq q{} )
          )
        {
            if ( ${ $uid . $user }{'disablegender'} eq q{} ) {
                ${ $uid . $user }{'disablegender'} = 1;
            }
            else { ${ $uid . $user }{'disablegender'}++; }
        }
        if (
            $editAgeLimit
            && (   ${ $uid . $user }{'bday'} ne $member{'bday'}
                || ${ $uid . $user }{'bday'} eq q{} )
          )
        {
            if ( ${ $uid . $user }{'disableage'} eq q{} ) {
                ${ $uid . $user }{'disableage'} = 1;
            }
            else { ${ $uid . $user }{'disableage'}++; }
        }

        # EventCal Begin
        if (   ${ $uid . $user }{'bday'} ne "$member{'bday'}"
            || ${ $uid . $user }{'hideage'} ne "$member{'hideage'}" )
        {
            $Update_EventCal = 1;
        }

        # EventCal End

        if ($extendedprofiles) {  # run this before you start to save something!
            require Sources::ExtendedProfiles;
            my $error = ext_validate_submition( $username, $user );
            if ( $error ne q{} ) {
                fatal_error( 'extended_profiles_validation', $error );
            }
            ext_saveprofile($user);
        }

        if ( ${ $uid . $user }{'realname'} ne $member{'name'} ) {
            $member{'name'} =~ s/\t+/\ /gsm;
        }
        if ( $member{'name'} eq q{} ) { fatal_error('no_name'); }
        if ( $name_cannot_be_userid
            && lc $member{'name'} eq lc $member{'username'} )
        {
            fatal_error('name_is_userid');
        }

        LoadCensorList();
        if ( Censor( $member{'name'} ) ne $member{'name'} ) {
            fatal_error( 'name_censored', CheckCensor("$member{'name'}") );
        }

        if ( ${ $uid . $user }{'password'} eq
            encode_password( $member{'name'} ) )
        {
            fatal_error('password_is_userid');
        }

        FromChars( $member{'name'} );
        $convertstr = $member{'name'};
        $convertcut = 30;
        CountChars();
        $member{'name'} = $convertstr;
        if ($cliped) { fatal_error('name_too_long'); }
        if (
            $member{'name'} =~ /[^ \w\x80-\xFF\[\]\(\)#\%\+,\-\|\.:=\?\@\^]/sm )
        {
            fatal_error( 'invalid_character',
                "$profile_txt{'68'} $profile_txt{'241re'}" );
        }

        ToHTML( $member{'name'} );
        if ( $user ne 'admin' ) {

            # Check to see if name is reserved
            fopen( FILE, "$vardir/reservecfg.txt" )
              or fatal_error( 'cannot_open', "$vardir/reservecfg.txt", 1 );
            my @reservecfg = <FILE>;
            fclose(FILE);
            chomp @reservecfg;
            my $matchword = $reservecfg[0] eq 'checked';
            my $matchcase = $reservecfg[1] eq 'checked';
            my $matchname = $reservecfg[3] eq 'checked';
            my $namecheck =
                $matchcase eq 'checked'
              ? $member{'name'}
              : lc $member{'name'};

            fopen( FILE, "$vardir/reserve.txt" )
              or fatal_error( 'cannot_open', "$vardir/reserve.txt", 1 );
            my @reserve = <FILE>;
            fclose(FILE);
            foreach my $reserved (@reserve) {
                chomp $reserved;
                my $reservecheck = $matchcase ? $reserved : lc $reserved;
                if ($matchname) {
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
            }
        }

        if (
            (
                lc MemberIndex( 'check_exist', $member{'name'}, 1 ) eq
                lc $member{'name'}
            )
            && ( lc $member{'name'} ne lc ${ $uid . $user }{'realname'} )
            && ( lc $member{'name'} ne lc $member{'username'} )
          )
        {
            fatal_error( 'name_taken', "($member{'name'})" );
        }

        # rewrite attachments.txt with new username
        fopen( ATM, "<$vardir/attachments.txt", 1 )
          or fatal_error( 'cannot_open', "$vardir/attachments.txt" );
        my @attachments = <ATM>;
        fclose(ATM);

        for my $i ( 0 .. ( @attachments - 1 ) ) {
            $attachments[$i] =~
s/^(\d+\|\d+\|.*?)\|(.*?)\|/ ($2 eq ${$uid.$user}{'realname'} ? "$1|$member{'name'}|" : "$1|$2|") /esm;
        }
        fopen( ATM, ">$vardir/attachments.txt", 1 )
          or fatal_error( 'cannot_open', "$vardir/attachments.txt" );
        print {ATM} @attachments or croak "$croak{'print'} ATM";
        fclose(ATM);

   #Since we have not encountered a fatal error, time to rewrite our memberlist.
        ManageMemberinfo( 'update', $user, $member{'name'} );

        ToHTML( $member{'gender'} );
        FromChars( $member{'location'} );
        ToHTML( $member{'location'} );
        ToChars( $member{'location'} );
        ToHTML( $member{'bday'} );
        FromChars( $member{'sesquest'} );
        ToHTML( $member{'sesquest'} );
        ToChars( $member{'sesquest'} );

        # Time to print the changes to the username.vars file
        if ( $member{'passwrd1'} ) {
            ${ $uid . $user }{'password'} =
              encode_password( $member{'passwrd1'} );
        }
        ${ $uid . $user }{'realname'} = $member{'name'};
        ${ $uid . $user }{'gender'}   = $member{'gender'};
        ${ $uid . $user }{'location'} = $member{'location'};
        ${ $uid . $user }{'bday'}     = $member{'bday'};
        ${ $uid . $user }{'hideage'}  = $member{'hideage'};
        ${ $uid . $user }{'sesquest'} = $member{'sesquest'};

        ${ $uid . $user }{'sesanswer'} = $member{'sesanswer'};

        # EventCal Begin
        if ( $Update_EventCal == 1 ) {
            fopen( FILE, "$vardir/eventcalbday.db" );
            my @birthmembers = <FILE>;
            fclose(FILE);
            fopen( FILE, ">$vardir/eventcalbday.db" );
            my $cn = 0;
            foreach my $x (@birthmembers) {
                chomp $x;
                my ( $user_year, $user_month, $user_day, $user_xy, $user_hide )
                  = split /\|/xsm, $x;
                if ( $user_xy eq $user ) {
                    my ( $user_montha, $user_daya, $user_yeara ) =
                      split /\//xsm, $member{'bday'};
                    if ( $user_montha < 10 && length($user_montha) == 1 ) {
                        $user_montha = "0$user_montha";
                    }
                    if ( $user_daya < 10 && length($user_daya) == 1 ) {
                        $user_daya = "0$user_daya";
                    }
                    if   ( $member{'hideage'} ) { $nuser_hide = 1; }
                    else                        { $nuser_hide = q{}; }
                    print {FILE}
qq~$user_yeara|$user_montha|$user_daya|$user_xy|$nuser_hide\n~
                      or croak "$croak{'print'} birthday";
                    $cn++;
                }
                else {
                    print {FILE} qq~$x\n~ or croak "$croak{'print'} birthday";
                }
            }
            fclose(FILE);
            if ( $cn == 0 ) {
                fopen( FILE, ">>$vardir/eventcalbday.db" );
                ( $user_montha, $user_daya, $user_yeara ) = split /\//xsm,
                  $member{'bday'};
                if ( $user_montha < 10 && length($user_montha) == 1 ) {
                    $user_montha = "0$user_montha";
                }
                if ( $user_daya < 10 && length($user_daya) == 1 ) {
                    $user_daya = "0$user_daya";
                }
                if   ( $member{'hideage'} ) { $nuser_hide = 1; }
                else                        { $user_hide  = q{}; }
                print {FILE}
                  qq~$user_yeara|$user_montha|$user_daya|$user|$nuser_hide\n~
                  or croak "$croak{'print'} birthday";
                fclose(FILE);
            }
        }

        # EventCal End
        UserAccount( $user, 'update' );

        if ( $member{'passwrd1'} && $username eq $user ) {
            UpdateCookie(
                'write', $user,
                ${ $uid . $user }{'password'},
                ${ $uid . $user }{'session'},
                q{/}, q{}
            );
        }

        my $scriptAction = $view ? 'myprofileContacts' : 'profileContacts';
        $yySetLocation =
qq~$scripturl?action=$scriptAction;username=$useraccount{$member{'username'}};sid=$INFO{'sid'}~;

    }
    elsif ( $member{'moda'} eq $profile_txt{'89'} ) {
        if ( $member{'username'} eq 'admin' ) {
            fatal_error('cannot_kill_admin');
        }

        # For security, remove username from mod position
        KillModerator( $member{'username'} );

        $noteuser = $iamadmin ? $member{'username'} : $user;

        unlink "$memberdir/$noteuser.dat";
        unlink "$memberdir/$noteuser.vars";
        unlink "$memberdir/$noteuser.ims";
        unlink "$memberdir/$noteuser.msg";
        unlink "$memberdir/$noteuser.log";
        unlink "$memberdir/$noteuser.rlog";
        unlink "$memberdir/$noteuser.outbox";
        unlink "$memberdir/$noteuser.imstore";
        unlink "$memberdir/$noteuser.imdraft";

        if (   ${ $uid . $user }{'userpic'}
            && ${ $uid . $user }{'userpic'} =~
            /$facesurl\/UserAvatars\/(.+)/xsm )
        {
            unlink "$facesdir/UserAvatars/$1";
        }

        fopen( PMATTACH, "<$vardir/pm.attachments" )
          or fatal_error( 'cannot_open', "$vardir/pm.attachments", 1 );
        @pmattach = <PMATTACH>;
        fclose(PMATTACH);

        foreach my $pm_attach (@pmattach) {
            ( undef, undef, undef, $attach_file, undef, $attach_user ) =
              split /\|/xsm, $pm_attach;
            chomp $attach_user;
            if ( $noteuser eq $attach_user ) {
                unlink "$pmuploaddir/$attach_file";
            }
        }

        MemberIndex( 'remove', $noteuser );

        # EventCalbday Begin
        fopen( FILE, "$vardir/eventcalbday.db" );
        my @birthmembers = <FILE>;
        fclose(FILE);
        fopen( FILE, ">$vardir/eventcalbday.db" );
        foreach my $x (@birthmembers) {
            chomp $x;
            my ( undef, undef, undef, $user_xy, undef ) =
              split /\|/xsm, $x;
            if ( $user_xy ne $user ) {
                print {FILE} qq~$x\n~ or croak "$croak{'print'} birthday";
            }
            else {
                print {FILE} q{} or croak "$croak{'print'} no-birthday";
            }
        }
        fclose(FILE);

        # EventCalbday End

        if ( !$iamadmin ) {
            UpdateCookie('delete');
            $username = 'Guest';
            $iamguest = 1;
            $iamadmin = q{};
            $iamgmod  = q{};
            $iamfmod  = q{};
            $password = q{};
            $yyim     = q{};
            local $ENV{'HTTP_COOKIE'} = q{};
            $yyuname = q{};
        }
        $yySetLocation = $scripturl;

    }
    else {
        fatal_error('not_allowed');
    }
    redirectexit();
    return;
}

sub ModifyProfileContacts2 {
    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value, $newpassemail, $tempname );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        $value =~ s/\r//gxsm;
        if ( $key ne 'awayreply' ) { $value =~ s/\n//gxsm; }
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} ne $profile_txt{'88'} ) { fatal_error('not_allowed'); }

    if (   $emailnewpass
        && lc $member{'email'} ne lc ${ $uid . $user }{'email'}
        && !$iamadmin )
    {
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
        ${ $uid . $user }{'password'} = encode_password( $member{'passwrd1'} );
        $newpassemail = 1;
    }

    if ( $member{'email'} eq q{} ) { fatal_error('no_email'); }
    if ( $member{'email'} !~ /^[\w\-\.\+]+\@[\w\-\.\+]+\.\w{2,4}$/xsm ) {
        fatal_error( 'invalid_character',
            "$profile_txt{'69'} $profile_txt{'241e'}" );
    }
    if (
        ( $member{'email'} =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/xsm )
        || ( $member{'email'} !~
            /^.+@\[?(\w|[-.])+\.[a-zA-Z]{2,4}|[0-9]{1,4}\]?$/xsm )
      )
    {
        fatal_error('invalid_email');
    }
    LoadCensorList();
    if ( Censor( $member{'email'} ) ne $member{'email'} ) {
        fatal_error( 'censor2', CheckCensor("$member{'email'}") );
    }

    $member{'icq'} =~ s/[^0-9]//gxsm;
    $member{'aim'} =~ s/ /\+/gsm;
    $member{'yim'} =~ s/ /\+/gsm;

    ToHTML( $member{'email'} );
    ToHTML( $member{'icq'} );
    ToHTML( $member{'aim'} );
    ToHTML( $member{'yim'} );
    ToHTML( $member{'gtalk'} );
    ToHTML( $member{'skype'} );
    ToHTML( $member{'myspace'} );
    ToHTML( $member{'facebook'} );
    ToHTML( $member{'twitter'} );
    ToHTML( $member{'youtube'} );
    ToHTML( $member{'weburl'} );
    FromChars( $member{'webtitle'} );
    ToHTML( $member{'webtitle'} );
    ToChars( $member{'webtitle'} );
    ToHTML( $member{'offlinestatus'} );
    FromChars( $member{'awaysubj'} );
    ToHTML( $member{'awaysubj'} );
    ToChars( $member{'awaysubj'} );

    FromChars( $member{'awayreply'} );
    ToHTML( $member{'awayreply'} );
    $member{'awayreply'} =~ s/\n/<br \/>/gsm;
    $convertstr = $member{'awayreply'};
    $convertcut = $MaxAwayLen;
    CountChars();
    $member{'awayreply'} = $convertstr;
    ToChars( $member{'awayreply'} );

    if ($extendedprofiles) {    # run this before you start to save something!
        require Sources::ExtendedProfiles;
        my $error = ext_validate_submition( $username, $user );
        if ( $error ne q{} ) {
            fatal_error( 'extended_profiles_validation', $error );
        }
        ext_saveprofile($user);
    }

    # Check to see if email is already taken
    if ( lc ${ $uid . $user }{'email'} ne lc $member{'email'} ) {
        $testemail = lc $member{'email'};
        my $is_existing = MemberIndex( 'check_exist', $testemail, 2 );
        if ( lc $is_existing eq $testemail ) {
            fatal_error( 'email_taken', "($member{'email'})" );
        }
    }

# Since we haven't encountered a fatal error, time to rewrite our memberlist a little.
    ManageMemberinfo( 'update', $user, q{}, $member{'email'} );
## if enabled but not set, default offline status to 'offline'
    if ( $enable_MCaway && $member{'offlinestatus'} eq q{} ) {
        $member{'offlinestatus'} = 'offline';
    }

    # if user is switching 'away' to 'off/on', clean out the away-sent list
    if ( $FORM{'offlinestatus'} eq 'offline' ) {
        ${ $uid . $user }{'awayreplysent'} = q{};
    }

    # Time to print the changes to the username.vars file
    ${ $uid . $user }{'email'}    = $member{'email'};
    ${ $uid . $user }{'hidemail'} = $member{'hideemail'} ? 1 : 0;
    ${ $uid . $user }{'icq'}      = $member{'icq'};
    ${ $uid . $user }{'aim'}      = $member{'aim'};
    ${ $uid . $user }{'yim'}      = $member{'yim'};
    ${ $uid . $user }{'gtalk'}    = $member{'gtalk'};
    ${ $uid . $user }{'skype'}    = $member{'skype'};
    ${ $uid . $user }{'myspace'}  = $member{'myspace'};
    ${ $uid . $user }{'facebook'} = $member{'facebook'};
    ${ $uid . $user }{'twitter'}  = $member{'twitter'};
    ${ $uid . $user }{'youtube'}  = $member{'youtube'};
    ${ $uid . $user }{'webtitle'} = $member{'webtitle'};
    ${ $uid . $user }{'weburl'}   = (
        ( $member{'weburl'} && $member{'weburl'} !~ m{\Ahttps?://}sm )
        ? 'http://'
        : q{}
    ) . $member{'weburl'};
    ${ $uid . $user }{'offlinestatus'} = $member{'offlinestatus'};
    ${ $uid . $user }{'awaysubj'}      = $member{'awaysubj'};
    ${ $uid . $user }{'awayreply'}     = $member{'awayreply'};
    ${ $uid . $user }{'stealth'} =
      (      ${ $uid . $user }{'position'} eq 'Administrator'
          || ${ $uid . $user }{'position'} eq 'Global Moderator' )
      ? $member{'stealth'}
      : q{};

    UserAccount( $user, 'update' );

    if ( $emailnewpass && $newpassemail == 1 ) {
        RemoveUserOnline($user);    # Remove user from online log

        if ( $username eq $user ) {
            UpdateCookie('delete');
            $username = 'Guest';
            $iamguest = 1;
            $iamadmin = q{};
            $iamgmod  = q{};
            $iamfmod  = q{};
            $password = q{};
            $yyim     = q{};
            local $ENV{'HTTP_COOKIE'} = q{};
            $yyuname = q{};
        }
        FormatUserName( $member{'username'} );
        require Sources::Mailer;
        my $scriptAction = $view ? 'myprofile' : 'profile';
        sendmail(
            $member{'email'},
            qq~$profile_txt{'700'} $mbname~,
"$profile_txt{'733'} $member{'passwrd1'} $profile_txt{'734'} $member{'username'}.\n\n$profile_txt{'701'} $scripturl?action=$scriptAction;username=$useraccount{$member{'username'}}\n\n$profile_txt{'130'}"
        );
        require Sources::LogInOut;
        $sharedLogin_title = "$profile_txt{'34'}: $user";
        $sharedLogin_text  = $profile_txt{'638'};
        $shared_login      = sharedLogin();
        $yymain .= $shared_login;
        $yytitle = $profile_txt{'245'};
        template();
    }

    my $scriptAction = $view ? 'myprofileOptions' : 'profileOptions';
    $yySetLocation =
qq~$scripturl?action=$scriptAction;username=$useraccount{$member{'username'}};sid=$INFO{'sid'}~;
    redirectexit();
    return;
}

sub ModifyProfileOptions2 {
    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value, $tempname );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        $value =~ s/\r//gxsm;
        if ( $key ne 'signature' ) { $value =~ s/\n//gxsm; }
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} ne $profile_txt{'88'} ) { fatal_error('not_allowed'); }

    if ( !$minlinksig ) { $minlinksig = 0; }
    if (   ${ $uid . $user }{'postcount'} < $minlinksig
        && !$iamadmin
        && !$iamgmod )
    {
        if (   $member{'signature'} =~ m{http:\/\/}xsm
            || $member{'signature'} =~ m{https:\/\/}xsm
            || $member{'signature'} =~ m{ftp:\/\/}xsm
            || $member{'signature'} =~ m{www.}xsm
            || $member{'signature'} =~ m{ftp.}xsm =~ m{\[url}xsm
            || $member{'signature'} =~ m{\[link}xsm
            || $member{'signature'} =~ m{\[img}xsm
            || $member{'signature'} =~ m{\[ftp}xsm )
        {
            fatal_error('no_siglinks_allowed');
        }
    }
    FromChars( $member{'usertext'} );
    $convertstr = $member{'usertext'};
    $convertcut = 51;
    CountChars();
    $member{'usertext'} = $convertstr;
    ToHTML( $member{'usertext'} );
    ToChars( $member{'usertext'} );

    if ($allowpics) {
        opendir DIR,
          $facesdir
          or fatal_error( 'cannot_open_dir',
            "($facesdir)!<br \/>$profile_txt{'681'}", 1 );
        closedir DIR;
    }

    if ( $allowpics && $upload_useravatar && $upload_avatargroup ) {
        $upload_useravatar = 0;
        foreach my $av_gr ( split /, /sm, $upload_avatargroup ) {
            if ( $av_gr eq ${ $uid . $user }{'position'} ) {
                $upload_useravatar = 1;
                last;
            }
            foreach ( split /,/xsm, ${ $uid . $user }{'addgroups'} ) {
                if ( $av_gr eq $_ ) { $upload_useravatar = 1; last; }
            }
        }
    }

    if ($CGI_query) { $file = $CGI_query->upload('file_avatar'); }
    if ( $allowpics && $upload_useravatar && $file ) {
        if ( $file !~ /\.(gif|png|jpe?g)$/ixsm ) {
            LoadLanguage('FA');
            fatal_error( 'file_not_uploaded',
                "$file $fatxt{'20'} gif png jpeg jpg" );
        }
        else { $ext = $1; }
        my $fixfile = ${ $uid . $user }{'realname'};
        if ( $fixfile =~ /[^0-9A-Za-z\+\-\.:_]/xsm )
        {    # replace all inappropriate characters
                # Transliteration
            my @ISO_8859_1 =
              qw(A B V G D E JO ZH Z I J K L M N O P R S T U F H C CH SH SHH _ Y _ JE JU JA a b v g d e jo zh z i j k l m n o p r s t u f h c ch sh shh _ y _ je ju ja);
            my $x = 0;
            foreach (
                qw(À Á Â Ã Ä Å ¨ Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å ¸ æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ)
              )
            {
                $fixfile =~ s/$_/$ISO_8859_1[$x]/igxsm;
                $x++;
            }

            # END Transliteration. Thanks to "Velocity" for this contribution.
            $fixfile =~ s/[^0-9A-Za-z\+\-\.:_]/_/gxsm;
        }
        $fixfile .= ".$ext";

        require Sources::SpamCheck;
        my $spamdetected = spamcheck("$fixfile");
        if ( !$staff ) {
            if ( $spamdetected == 1 ) {
                ${ $uid . $username }{'spamcount'}++;
                ${ $uid . $username }{'spamtime'} = $date;
                UserAccount( $username, 'update' );
                $spam_hits_left_count =
                  $post_speed_count - ${ $uid . $username }{'spamcount'};
                fatal_error('tsc_alert');
            }
        }

        my ( $size, $buffer, $filesize, $file_buffer );
        while ( $size = read $file, $buffer, 512 ) {
            $filesize += $size;
            $file_buffer .= $buffer;
        }
        $avatar_limit ||= 0;
        if ( $avatar_limit > 0 && $filesize > ( 1024 * $avatar_limit ) ) {
            LoadLanguage('FA');
            fatal_error( 'file_not_uploaded',
                    "$fatxt{'21'} $file ("
                  . int( $filesize / 1024 )
                  . " KB) $fatxt{'21b'} "
                  . $avatar_limit );
        }
        $avatar_dirlimit ||= 0;
        if ( $avatar_dirlimit > 0 ) {
            my $dirsize = dirsize("$facesdir/UserAvatars");
            if ( $filesize > ( ( 1024 * $avatar_dirlimit ) - $dirsize ) ) {
                LoadLanguage('FA');
                fatal_error(
                    'file_not_uploaded',
                    "$fatxt{'22'} $file ("
                      . (
                        int( $filesize / 1024 ) -
                          $avatar_dirlimit +
                          int( $dirsize / 1024 )
                      )
                      . " KB) $fatxt{'22b'}"
                );
            }
        }

        if ( ${ $uid . $user }{'userpic'} =~ /$facesurl\/UserAvatars\/(.+)/xsm )
        {
            unlink "$facesdir/UserAvatars/$1";
        }
        $fixfile = check_existence( "$facesdir/UserAvatars", $fixfile );

 # create a new file on the server using the formatted ( new instance ) filename
        if ( fopen( NEWFILE, ">$facesdir/UserAvatars/$fixfile" ) ) {
            binmode NEWFILE;

            # needed for operating systems (OS) Windows, ignored by Linux
            print {NEWFILE} $file_buffer
              or croak "$croak{'print'} NEWFILE";    # write new file on HD
            fclose(NEWFILE);

        }
        else
        { # return the server's error message if the new file could not be created
            fatal_error( 'file_not_open', "$facesdir/UserAvatars" );
        }

     # check if file has actually been uploaded, by checking the file has a size
        if ( !-s "$facesdir/UserAvatars/$fixfile" ) {
            fatal_error( 'file_not_uploaded', $fixfile );
        }

        my $illegal;
        if ( $fixfile =~ /gif$/ixsm ) {
            my $header;
            fopen( ATTFILE, "$facesdir/UserAvatars/$fixfile" );
            read ATTFILE, $header, 10;
            my ( $giftest, undef, undef, undef, undef, undef ) =
              unpack 'a3a3C4', $header;
            fclose(ATTFILE);
            if ( $giftest ne 'GIF' ) { $illegal = $giftest; }
        }
        fopen( ATTFILE, "$facesdir/UserAvatars/$fixfile" );
        while ( read ATTFILE, $buffer, 1024 ) {
            if ( $buffer =~ /<(html|script|body)/igsm ) { $illegal = $1; last; }
        }
        fclose(ATTFILE);
        if ($illegal) {    # delete the file as it contains illegal code
            unlink "$facesdir/UserAvatars/$fixfile";
            ToHTML($illegal);
            fatal_error( 'file_not_uploaded',
                "$fixfile <= illegal code ($illegal) inside image file!" );
        }

        $member{'userpic'} = "$facesurl/UserAvatars/$fixfile";

    }
    elsif (
        $member{'userpicpersonalcheck'}
        && (   $member{'userpicpersonal'} =~ /\.gif\Z/ixsm
            || $member{'userpicpersonal'} =~ /\.jpe?g\Z/ixsm
            || $member{'userpicpersonal'} =~ /\.png\Z/ixsm )
      )
    {
        $member{'userpic'} = $member{'userpicpersonal'};
    }
    if ( $member{'userpic'} eq q{} || !$allowpics ) {
        $member{'userpic'} = $my_blank_avatar;
    }
    if ( $member{'userpic'} !~
        m{\A[0-9a-zA-Z_\.\#\%\-\:\+\?\$\&\~\.\,\@/]+\Z}xsm )
    {
        fatal_error( 'invalid_character', "$profile_txt{'592'}" );
    }
    if ( $member{'userpic'} ne ${ $uid . $user }{'userpic'}
        && ${ $uid . $user }{'userpic'} =~ /$facesurl\/UserAvatars\/(.+)/xsm )
    {
        unlink "$facesdir/UserAvatars/$1";
    }

    if ( $member{'usertemplate'} ne q{}
        && !$templateset{ $member{'usertemplate'} } )
    {
        fatal_error('invalid_template');
    }
    if ( $member{'usertemplate'} eq q{} ) {
        $member{'usertemplate'} = $template;
    }
    if ( $member{'userlanguage'} ne q{}
        && !-e "$langdir/$member{'userlanguage'}/Main.lng" )
    {
        fatal_error('invalid_language');
    }
    if ( $member{'userlanguage'} eq q{} ) {
        $member{'userlanguage'} = $language;
    }

    if ($extendedprofiles) {    # run this before you start to save something!
        require Sources::ExtendedProfiles;
        my $error = ext_validate_submition( $username, $user );
        if ( $error ne q{} ) {
            fatal_error( 'extended_profiles_validation', $error );
        }
        ext_saveprofile($user);
    }

    # update notifications if users language is changed
    if ( ${ $uid . $user }{'language'} ne "$member{'userlanguage'}" ) {
        require Sources::Notify;
        updateLanguage( $user, $member{'userlanguage'} );
    }

    if ( $addmemgroup_enabled > 1 ) {
        my %groups;
        map { $groups{$_} = 2; } split /,/xsm, ${ $uid . $user }{'addgroups'};
        map { $groups{$_} = 1; } split /, /sm, $member{'joinmemgroup'};
        my @nopostmember;
        for ( keys %NoPost ) {
            next if ${ $uid . $user }{'position'} eq $_;
            if ( $groups{$_} == 1 && ( split /\|/xsm, $NoPost{$_} )[10] ) {
                push @nopostmember, $_;
            }
            elsif ( $groups{$_} == 2 && !( split /\|/xsm, $NoPost{$_} )[10] ) {
                push @nopostmember, $_;
            }
        }
        $member{'joinmemgroup'} = join q{,}, @nopostmember;
        if ( $member{'joinmemgroup'} eq '###blank###' ) {
            $member{'joinmemgroup'} = q{};
        }
        if ( $member{'joinmemgroup'} ne ${ $uid . $user }{'addgroups'} ) {
            ManageMemberinfo( 'update', $user, q{}, q{}, q{}, q{},
                $member{'joinmemgroup'} );
        }
        if ( $member{'joinmemgroup'} eq '###blank###' ) {
            $member{'joinmemgroup'} = q{};
        }
        ${ $uid . $user }{'addgroups'} = $member{'joinmemgroup'};
    }

    FromChars( $member{'signature'} );
    ToHTML( $member{'signature'} );
    $member{'signature'} =~ s/\n/<br \/>/gsm;
    $convertstr = $member{'signature'};
    $convertcut = $MaxSigLen;
    CountChars();
    $member{'signature'} = $convertstr;
    ToChars( $member{'signature'} );

    ToHTML( $member{'userpic'} );
    ToHTML( $member{'usertemplate'} );
    ToHTML( $member{'userlanguage'} );
    ToHTML( $member{'timeformat'} );

    # Time to print the changes to the username.vars file
    ${ $uid . $user }{'usertext'}  = $member{'usertext'};
    ${ $uid . $user }{'userpic'}   = $member{'userpic'};
    ${ $uid . $user }{'signature'} = $member{'signature'};
    ${ $uid . $user }{'timeoffset'} =
      "$member{'usertimesign'}$member{'usertimehour'}.$member{'usertimemin'}";
    ${ $uid . $user }{'onlinealert'} = $member{'onlinealert'} ? 1 : 0;
    ${ $uid . $user }{'notify_me'} =
      $member{'notify_N'}
      ? (
        (
                !${ $uid . $user }{'notify_me'}
              || ${ $uid . $user }{'notify_me'} == 1
        ) ? 1 : 3
      )
      : (
        (
                 ${ $uid . $user }{'notify_me'} == 2
              || ${ $uid . $user }{'notify_me'} == 3
        ) ? 2 : 0
      );
    ${ $uid . $user }{'reversetopic'}  = $member{'reversetopic'} ? 1 : 0;
    ${ $uid . $user }{'user_tz'}       = $member{'user_tz'};
    ${ $uid . $user }{'dynamic_clock'} = $member{'dynamic_clock'} ? 1 : 0;
    ${ $uid . $user }{'timeselect'}    = int $member{'usertimeselect'};
    ${ $uid . $user }{'template'}      = $member{'usertemplate'};
    ${ $uid . $user }{'language'}      = $member{'userlanguage'};
    ${ $uid . $user }{'hide_avatars'} =
      ( $member{'hide_avatars'} && $user_hide_avatars ) ? 1 : 0;
    ${ $uid . $user }{'hide_user_text'} =
      ( $member{'hide_user_text'} && $user_hide_user_text ) ? 1 : 0;
    ${ $uid . $user }{'hide_img'} =
      ( $member{'hide_img'} && $user_hide_img ) ? 1 : 0;
    ${ $uid . $user }{'hide_attach_img'} =
      ( $member{'hide_attach_img'} && $user_hide_attach_img ) ? 1 : 0;
    ${ $uid . $user }{'hide_signat'} =
      ( $member{'hide_signat'} && $user_hide_signat ) ? 1 : 0;
    ${ $uid . $user }{'hide_smilies_row'} =
      ( $member{'hide_smilies_row'} && $user_hide_smilies_row ) ? 1 : 0;
    ${ $uid . $user }{'numberformat'} = int $member{'usernumberformat'};
    ${ $uid . $user }{'return_to'}    = $member{'return_to'};

    UserAccount( $user, 'update' );

    my $scriptAction;
    if (
        $iamadmin
        || (   $iamgmod
            && $allow_gmod_profile
            && $gmod_access2{'profileAdmin'} eq 'on' )
      )
    {
        $scriptAction = q~profileAdmin~;
    }
    else {
        $scriptAction = q~viewprofile~;
    }
    if ( $pm_lev == 1 ) {
        $scriptAction = q~profileIM~;
    }
    if ($buddyListEnabled) {
        $scriptAction = q~profileBuddy~;
    }
    if ($view) { $scriptAction = qq~my$scriptAction~; }
    $yySetLocation =
qq~$scripturl?action=$scriptAction;username=$useraccount{$member{'username'}};sid=$INFO{'sid'}~;
    redirectexit();
    return;
}

sub ModifyProfileBuddy2 {
    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value, $tempname );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        $value =~ s/[\n\r]//gxsm;
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} ne $profile_txt{'88'} ) { fatal_error('not_allowed'); }

    if ( $member{'buddylist'} ) {
        my @buddies = split /\,/xsm, $member{'buddylist'};
        chomp @buddies;
        $member{'buddylist'} = q{};
        foreach my $cloakedBuddy (@buddies) {
            $cloakedBuddy =~ s/^ //sm;
            $cloakedBuddy = decloak($cloakedBuddy);
            ToHTML($cloakedBuddy);
            $member{'buddylist'} = qq~$member{'buddylist'}\|$cloakedBuddy~;
        }
        $member{'buddylist'} =~ s/^\|//sm;
    }
    ${ $uid . $user }{'buddylist'} = $member{'buddylist'};
    UserAccount( $user, 'update' );

    my $scriptAction;
    if (
        $iamadmin
        || (   $iamgmod
            && $allow_gmod_profile
            && $gmod_access2{'profileAdmin'} eq 'on' )
      )
    {
        $scriptAction = q~profileAdmin~;
    }
    else {
        $scriptAction = q~viewprofile~;
    }
    if ( $pm_lev == 1 ) {
        $scriptAction = q~profileIM~;
    }
    if ($view) { $scriptAction = qq~my$scriptAction~; }
    $yySetLocation =
qq~$scripturl?action=$scriptAction;username=$useraccount{$member{'username'}};sid=$INFO{'sid'}~;
    redirectexit();
    return;
}

sub ModifyProfileIM2 {
    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value, $ignorelist );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        if ( $key ne 'ignore' ) { $value =~ s/[\n\r]//gxsm; }
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} ne $profile_txt{'88'} ) { fatal_error('not_allowed'); }

    if ( !$member{'ignoreall'} ) {
        my @ignoreList = split /\,/xsm, $member{'ignore'};
        chomp @ignoreList;
        foreach my $cloakedIgnore (@ignoreList) {
            $cloakedIgnore =~ s/\A //sm;
            $cloakedIgnore =~ s/ \Z//sm;
            $cloakedIgnore = decloak($cloakedIgnore);
            ToHTML($cloakedIgnore);
            $ignorelist .= qq~\|$cloakedIgnore~;
        }
        $ignorelist =~ s/\A\|//xsm;
    }
    else {
        $ignorelist = q{*};
    }

    # Time to print the changes to the username.vars file
    ${ $uid . $user }{'im_ignorelist'} = $ignorelist;
    ${ $uid . $user }{'notify_me'} =
      $member{'notify_PM'}
      ? (
        (
                !${ $uid . $user }{'notify_me'}
              || ${ $uid . $user }{'notify_me'} == 2
        ) ? 2 : 3
      )
      : (
        (
                 ${ $uid . $user }{'notify_me'} == 1
              || ${ $uid . $user }{'notify_me'} == 3
        ) ? 1 : 0
      );
    ${ $uid . $user }{'im_popup'}   = $member{'userpopup'}  ? 1 : 0;
    ${ $uid . $user }{'im_imspop'}  = $member{'popupims'}   ? 1 : 0;
    ${ $uid . $user }{'pmviewMess'} = $member{'pmviewMess'} ? 1 : 0;

    if ($extendedprofiles) {    # run this before you start to save something!
        require Sources::ExtendedProfiles;
        my $error = ext_validate_submition( $username, $user );
        if ( $error ne q{} ) {
            fatal_error( 'extended_profiles_validation', $error );
        }
        ext_saveprofile($user);
    }
    UserAccount( $user, 'update' );

    my $scriptAction = q~viewprofile~;
    if (
        $iamadmin
        || (   $iamgmod
            && $allow_gmod_profile
            && $gmod_access2{'profileAdmin'} eq 'on' )
      )
    {
        $scriptAction = q~profileAdmin~;
    }
    if ($view) { $scriptAction = qq~my$scriptAction~; }
    $yySetLocation =
qq~$scripturl?action=$scriptAction;username=$useraccount{$member{'username'}};sid=$INFO{'sid'}~;
    redirectexit();
    return;
}

sub ModifyProfileAdmin2 {
    is_admin_or_gmod();

    SidCheck($action);
    PrepareProfile();

    my ( %member, $key, $value );
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//sm;
        $value =~ s/\s+\Z//sm;
        if ( $key ne 'regreason' ) { $value =~ s/[\n\r]//gxsm; }
        $member{$key} = $value;
    }
    $member{'username'} = $user;

    if ( $member{'moda'} ne $profile_txt{'88'} ) {
        fatal_error('cannot_kill_admin');
    }

    if (
        !$iamadmin
        && (   $member{'settings7'} eq 'Administrator'
            || $member{'settings7'} eq 'Global Moderator' )
      )
    {
        $member{'settings7'} = ${ $uid . $user }{'position'};
    }

    if ( $member{'settings6'} eq q{} ) { $member{'settings6'} = 0; }
    if ( $member{'settings6'} !~ /\A[0-9]+\Z/xsm ) {
        fatal_error('invalid_postcount');
    }
    if (   $member{'username'} eq 'admin'
        && $member{'settings7'} ne 'Administrator' )
    {
        fatal_error('cannot_regroup_admin');
    }

    $dr_month  = $member{'dr_month'};
    $dr_day    = $member{'dr_day'};
    $dr_year   = $member{'dr_year'};
    $dr_hour   = $member{'dr_hour'};
    $dr_minute = $member{'dr_minute'};
    $dr_secund = $member{'dr_secund'};

    if ( $dr_month == 4 || $dr_month == 6 || $dr_month == 9 || $dr_month == 11 )
    {
        $max_days = 30;
    }
    elsif ( $dr_month == 2 && $dr_year % 4 == 0 ) {
        $max_days = 29;
    }
    elsif ( $dr_month == 2 && $dr_year % 4 != 0 ) {
        $max_days = 28;
    }
    else {
        $max_days = 31;
    }
    if ( $dr_day > $max_days ) { $dr_day = $max_days; }

    $member{'dr'} =
qq~$dr_month/$dr_day/$dr_year $maintxt{'107'} $dr_hour:$dr_minute:$dr_secund~;

    if (   $member{'settings6'} != ${ $uid . $user }{'postcount'}
        || $member{'settings7'} ne ${ $uid . $user }{'position'} )
    {
        if ( $member{'settings7'} ) {
            $grp_after = qq~$member{'settings7'}~;
        }
        else {
            for my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
                if ( $member{'settings6'} >= $postamount ) {
                    ( $title, undef ) = split /\|/xsm, $Post{$postamount}, 2;
                    $grp_after = $title;
                    last;
                }
            }
        }
        ManageMemberinfo( 'update', $user, q{}, q{}, $grp_after,
            $member{'settings6'} );
    }

    my %groups;
    map { $groups{$_} = 1; } split /, /sm, $member{'addgroup'};
    my @nopostmember;
    for ( keys %NoPost ) {
        next if $member{'settings7'} eq $_;
        if ( $groups{$_} ) { push @nopostmember, $_; }
    }
    $member{'addgroup'} = join q{,}, @nopostmember;
    if ( $member{'addgroup'} eq q{} ) { $member{'addgroup'} = '###blank###'; }
    if ( $member{'addgroup'} ne ${ $uid . $user }{'addgroups'} ) {
        ManageMemberinfo( 'update', $user, q{}, q{}, q{}, q{},
            $member{'addgroup'} );
    }
    if ( $member{'addgroup'} eq '###blank###' ) { $member{'addgroup'} = q{}; }
    ${ $uid . $user }{'addgroups'} = $member{'addgroup'};

    if ( $member{'dr'} ne ${ $uid . $user }{'regdate'} ) {
        $newreg = stringtotime( $member{'dr'} );
        $newreg = sprintf '%010d', $newreg;
        ManageMemberlist( 'update', $user, $newreg );
        ${ $uid . $user }{'regtime'} = $newreg;
    }

    if ( !$iamadmin ) { $member{'dr'} = ${ $uid . $user }{'regdate'}; }
    FromChars( $member{'regreason'} );
    ToHTML( $member{'regreason'} );
    ToChars( $member{'regreason'} );
    $member{'regreason'} =~ s/[\n\r]{1,2}/<br \/>/gsm;
    ${ $uid . $user }{'regreason'} = $member{'regreason'};
    ${ $uid . $user }{'postcount'} = $member{'settings6'};
    ${ $uid . $user }{'position'}  = $member{'settings7'};
    ${ $uid . $user }{'regdate'}   = $member{'dr'};
    if (   ${ $uid . $user }{'position'} ne 'Administrator'
        && ${ $uid . $user }{'position'} ne 'Global Moderator' )
    {
        ${ $uid . $user }{'stealth'} = q{};
    }

    if ($extendedprofiles) {    # run this before you start to save something!
        require Sources::ExtendedProfiles;
        my $error = ext_validate_submition( $username, $user );
        if ( $error ne q{} ) {
            fatal_error( 'extended_profiles_validation', $error );
        }
        ext_saveprofile($user);
    }
    UserAccount( $user, 'update' );

    AddModerators2( $user, $member{'addmod'} );
    my $scriptAction = $view ? 'myviewprofile' : 'viewprofile';
    $yySetLocation =
      qq~$scripturl?action=$scriptAction;username=$useraccount{$user}~;
    redirectexit();
    return;
}

sub ViewProfile {
    if ($iamguest) { fatal_error('members_only'); }

    # If someone registers with a '+' in their name It causes problems.
    # Get's turned into a <space> in the query string Change it back here.
    # Users who register with spaces get them replaced with _
    # So no problem there.
    $INFO{'username'} =~ tr/ /+/;

    $user = $INFO{'username'};
    if ($do_scramble_id)     { decloak($user); }
    if ( $user =~ m{/}xsm )  { fatal_error('no_user_slash'); }
    if ( $user =~ m{\\}xsm ) { fatal_error('no_user_backslash'); }

    if ( !LoadUser($user) )   { fatal_error('no_profile_exists'); }
    if ( $user eq $username ) { LoadMiniUser($user); }

    my ( $modify, $gender );
    my (
        $pic_row,      $buddybutton,   $row_addgrp,  $row_gender,
        $row_age,      $row_location,  $row_icq,     $row_aim,
        $row_yim,      $row_gtalk,     $row_skype,   $row_myspace,
        $row_facebook, $row_twitter,   $row_youtube, $row_email,
        $row_website,  $row_signature, $showusertext
    );
    my ($row_zodiac);

    # Convert forum start date to string, if there is no date set,
    # Defaults to 1st Jan, 2005
    $forumstart = $forumstart ? stringtotime($forumstart) : '1104537600';

    $memsettingsd[9] = ${ $uid . $user }{'aim'};
    $memsettingsd[9] =~ tr/+/ /;
    $memsettingsd[10] = ${ $uid . $user }{'yim'};
    $memsettingsd[10] =~ tr/+/ /;

    if ( ${ $uid . $user }{'regtime'} ) {
        $dr = timeformat( ${ $uid . $user }{'regtime'},0,0,0,1 );
    }
    else {
        $dr = $profile_txt{'470'};
    }

    CalcAge( $user, 'calc' );      # How old is he/she?
    CalcAge( $user, 'isbday' );    # is it the bday?
    if ($isbday) {
        $isbday = qq~<img src="$imagesdir/$my_bdaycake" />~;
    }

    ## only show the 'modify' button if not using 'my center' or admin/gmod viewing
    $modify =
      (
             !$view
          && ( $user ne 'admin' || $username eq 'admin' )
          && (
            $iamadmin
            || (   $iamgmod
                && $allow_gmod_profile
                && ${ $uid . $user }{'position'} ne 'Administrator' )
          )
      )
      ? qq~<a href="$scripturl?action=profileCheck;username=$useraccount{$user}">$img{'modify'}</a>~
      : '&nbsp;';

    if ($allowpics) {
        my $no_userpic;
        if ( ${ $uid . $user }{'userpic'} eq $my_blank_avatar ) {
            $no_userpic = $default_avatar ? $default_userpic : $nn_avatar;
            $pic =
qq~<img src="$imagesdir/$no_userpic" id="avatar_img_resize" alt="" style="display:none" />~;
        }
        elsif ( ${ $uid . $user }{'userpic'} =~ /^https?:\/\//xsm ) {
            $pic =
qq~<img src="${$uid.$user}{'userpic'}" id="avatar_img_resize" alt="" style="display:none" />~;
        }
        else {
            $pic =
qq~<img src="$facesurl/${$uid.$user}{'userpic'}" id="avatar_img_resize" alt="" style="display:none" />~;
        }
        $pic_row = qq~<div class="picrow">
                        $pic
                        </div>~;
    }

    if ( $buddyListEnabled && $user ne $username ) {
        loadMyBuddy();
        $buddybutton = '<br />'
          . (
            $mybuddie{$user}
            ? qq~<img src="$micon_bg{'buddylist'}" alt="$display_txt{'isbuddy'}" /> $display_txt{'isbuddy'}~
            : qq~<a href="$scripturl?action=addbuddy;name=$useraccount{$user}">$img{'addbuddy'}</a>~
          );
    }

    # Hide empty profile fields from display
    if ( $addmembergroup{$user} ) {
        $showaddgr = $addmembergroup{$user};
        $showaddgr =~ s/<br \/>/\, /gsm;
        $showaddgr =~ s/\A, //sm;
        $showaddgr =~ s/, \Z//sm;
        $row_addgrp .= qq~$showaddgr<br />~;
    }
    if ( ${ $uid . $user }{'gender'} ) {
        if ( ${ $uid . $user }{'gender'} eq 'Male' ) {
            $gender = $profile_txt{'238'};
        }
        elsif ( ${ $uid . $user }{'gender'} eq 'Female' ) {
            $gender = $profile_txt{'239'};
        }
        $row_gender = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'231'}: </b>
                        </div>
                        <div class="contactright">
                        $gender
                        </div>~;
    }
    if ($age) {
        if ( $showage == 1 && ${ $uid . $user }{'hideage'} && !$iamadmin ) {
            $age = qq~$profile_txt{'722'} &nbsp;~;
        }
        else { $age = qq~$age &nbsp; ~; }
        $row_age = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'420'}:</b>
                        </div>
                        <div class="contactright">
                        $age$isbday
                        </div>~;
            if ($showzodiac) {
            require Sources::EventCalBirthdays;
            my ($user_bdmon, $user_bdday, undef ) = split /\//xsm, ${ $uid . $user }{'bday'} ;
            $memberzodiac = starsign($user_bdday, $user_bdmon, 'text' );
            $row_zodiac = qq~
                        <div class="contactleft">
                        <b>$zodiac_txt{'sign'}:</b>
                        </div>
                        <div class="contactright">
                        $memberzodiac
                        </div>~;
        }
    }
    if ( ${ $uid . $user }{'location'} ) {
        $row_location = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'227'}: </b>
                        </div>
                        <div class="contactright">
                        ${$uid.$user}{'location'}
                        </div>~;
    }
    if ( ${ $uid . $user }{'icq'} && ${ $uid . $user }{'icq'} !~ m{\D}xsm ) {
        $row_icq .= qq~
                        <div class="contactleft">
                        <b>$profile_txt{'513'}:</b>
                        </div>
                        <div class="contactright">
                        <a href="http://web.icq.com/${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" target="_blank">
                        <img src="http://web.icq.com/whitepages/online?icq=${$uid.$user}{'icq'}&#38;img=5" alt="${$uid.$user}{'icq'}" /> ${$uid.$user}{'icq'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'aim'} ) {
        $row_aim = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'603'}: </b>
                        </div>
                        <div class="contactright">
                        <a href="aim:goim?screenname=${$uid.$user}{'aim'}&#38;message=Hi,+are+you+there?">
                        <img src="$imagesdir/$my_aim" alt="${$uid.$user}{'aim'}" /> $memsettingsd[9]</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'yim'} ) {
        $row_yim = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'604'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="http://opi.yahoo.com/online?u=${$uid.$user}{'yim'}&#38;m=g&#38;t=0" alt="${$uid.$user}{'yim'}" />
                        <a href="http://edit.yahoo.com/config/send_webmesg?.target=${$uid.$user}{'yim'}" target="_blank"> $memsettingsd[10]</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'gtalk'} ) {
        $row_gtalk = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'825'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$gtalk" alt="" />
                        <a href="#" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$user','','height=80,width=340,menubar=0,toolbar=0,scrollbars=0,resizable=1'); return false">$profile_txt{'825'} ${$uid.$user}{'realname'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'skype'} ) {
        $row_skype = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'827'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$imagesdir/$my_skype" alt="" />
                        <a href="javascript:void(window.open('callto://${$uid.$user}{'skype'}','skype','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'))">$profile_txt{'827'} ${$uid.$user}{'realname'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'myspace'} ) {
        $row_myspace = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'570'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$imagesdir/$my_myspace" alt="" />
                        <a href="http://www.myspace.com/${$uid.$user}{'myspace'}" target="_blank">$profile_txt{'570'} ${$uid.$user}{'realname'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'facebook'} ) {
        $row_facebook = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'573'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$imagesdir/$my_facebook" alt="" />
                        <a href="http://www.facebook.com/~
          . (
            ${ $uid . $user }{'facebook'} !~ /\D/xsm ? 'profile.php?id=' : q{} )
          . qq~${$uid.$user}{'facebook'}" target="_blank"> ${$uid.$user}{'facebook'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'twitter'} ) {
        $row_twitter = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'576'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$imagesdir/$my_twitter" alt="" />
                        <a href="http://twitter.com/${$uid.$user}{'twitter'}" target="_blank">$profile_txt{'576'} ${$uid.$user}{'realname'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'youtube'} ) {
        $row_youtube = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'579'}: </b>
                        </div>
                        <div class="contactright">
                        <img src="$imagesdir/$my_youtube" alt="" />
                        <a href="http://www.youtube.com/${$uid.$user}{'youtube'}" target="_blank">$profile_txt{'579'} ${$uid.$user}{'realname'}</a>
                        </div>~;
    }
    if (   !${ $uid . $user }{'hidemail'}
        || $iamadmin
        || !$allow_hide_email
        || $view )
    {
        my $rowEmail = q{};
        if ($view) {
            if ( !${ $uid . $user }{'hidemail'} ) {
                $rowEmail = $profile_txt{'showingemail'};
            }
            else {
                my ( $admtitle, undef ) =
                  split /\|/xsm, $Group{'Administrator'}, 2;
                $rowEmail =
qq~$profile_txt{'notshowingemail'} $admtitle$profile_txt{'notshowingemailend'}~;
            }
        }
        else {
            $rowEmail = enc_eMail(
                "$profile_txt{'889'} ${$uid.$user}{'realname'}",
                ${ $uid . $user }{'email'},
                q{}, q{}, 1
            );
        }

        $row_email = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'69'}: </b>
                        </div>
                        <div class="contactright">
                        $rowEmail
                        </div>~;
    }
    if ( !$minlinkweb ) { $minlinkweb = 0; }
    if (
           ${ $uid . $user }{'weburl'}
        && ${ $uid . $user }{'webtitle'}
        && (   ${ $uid . $user }{'postcount'} >= $minlinkweb
            || ${ $uid . $user }{'position'} eq 'Administrator'
            || ${ $uid . $user }{'position'} eq 'Global Moderator' )
      )
    {
        $row_website = qq~
                        <div class="contactleft">
                        <b>$profile_txt{'96'}: </b>
                        </div>
                        <div class="contactright">
                        <a href="${$uid.$user}{'weburl'}" target="_blank">${$uid.$user}{'webtitle'}</a>
                        </div>~;
    }
    if ( ${ $uid . $user }{'signature'} ) {

        # do some ubbc on the signature to display in the view profile area
        $message     = ${ $uid . $user }{'signature'};
        $displayname = ${ $uid . $user }{'realname'};

        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC(1);
        }

        ToChars($message);

        # Censor the signature.
        LoadCensorList();
        $message = Censor($message);

        $row_signature = $myrow_sig;
        $row_signature =~ s/{yabb message}/$message/sm;
    }

    # End empty field checking

    # Just maths below...
    $post_count = ${ $uid . $user }{'postcount'};
    if ( !$post_count ) { $post_count = 0 }

    $string_regdate = stringtotime( ${ $uid . $user }{'regdate'} );
    $string_curdate = $date;

    if ( $string_curdate < $forumstart ) { $string_curdate = $forumstart }

    $member_for_days = int( ( $string_curdate - $string_regdate ) / 86400 );

    if   ( $member_for_days < 1 ) { $tmpmember_for_days = 1; }
    else                          { $tmpmember_for_days = $member_for_days; }
    $post_per_day    = sprintf '%.2f', ( $post_count / $tmpmember_for_days );
    $member_for_days = NumberFormat($member_for_days);
    $post_per_day    = NumberFormat($post_per_day);
    $post_count      = NumberFormat($post_count);

    # End statistics.
    if ( ${ $uid . $user }{'usertext'} ) {

        # Censor the usertext and wrap it
        LoadCensorList();
        $showusertext =
          WrapChars( Censor( ${ $uid . $user }{'usertext'} ), 20 );
    }

    if ( !$view ) {
        $yynavigation = qq~&rsaquo; $profile_txt{'92'}~;
        if ( $iamadmin || $iamgmod ) {
            $my_not_view_b .= qq~
                <img src="$imagesdir/$my_profile" alt="" />&nbsp; <b>$profile_txt{'35'}: $INFO{'username'}</b>~;
        }
        else {
            $my_not_view_b .= qq~
                <img src="$imagesdir/$my_profile" alt="" />&nbsp; <b>$profile_txt{'68'}: ${$uid.$INFO{'username'}}{'realname'}</b>~;
        }
        $my_not_view = $myshow_b;
        $my_not_view =~ s/{yabb my_not_view_b}/$my_not_view_b/sm;
    }
    $my_online = userOnLineStatus($user);

    my $userismod;
    if (   ${ $uid . $user }{'position'} ne 'Administrator'
        && ${ $uid . $user }{'position'} ne 'Global Moderator'
        && ${ $uid . $user }{'position'} ne 'Mid Moderator' )
    {
        $userismod = is_moderator($user);
    }
    if ($userismod) {
        @memstats = split /\|/xsm, $Group{'Moderator'};
        my $starnum        = $memstats[1];
        my $memberstartemp = q{};
        if ( $memstats[2] !~ /\//xsm ) { $memstats[2] = "$imagesdir/$memstats[2]"; }
        while ( $starnum-- > 0 ) {
            $memberstartemp .= qq~<img src="$memstats[2]" alt="*" />~;
        }
        $memberstar = $memberstartemp ? "$memberstartemp<br />" : q{};

        *get_subboards = sub {
            my @x = @_;
            $indent += 2;
            foreach my $board (@x) {
                my $dash;
                if ( $indent > 2 ) { $dash = q{-}; }

                ( $boardname, $boardperms, $boardview ) =
                  split /\|/xsm, $board{$board};
                if (   ${ $uid . $board }{'ann'} == 1
                    || ${ $uid . $board }{'rbin'} == 1 )
                {
                    next;
                }
                $moderators = ${ $uid . $board }{'mods'};
                my @BoardModerators = split /, ?/sm, $moderators;
                for my $thisMod (@BoardModerators) {
                    if ( $thisMod eq $user ) {
                        ( $boardname, $boardperms, $boardview ) =
                          split /\|/xsm, $board{"$board"};
                        ToChars($boardname);
                        if ( !${ $uid . $board }{'canpost'}
                            && $subboard{$board} )
                        {
                            $my_brd = 'boardselect';
                        }
                        else { $my_brd = 'board'; }
                        $my_mod_star .=
                            qq~<a href="$scripturl?$my_brd=$board" class="a">~
                          . ( '&nbsp;' x $indent )
                          . ( $dash x ( $indent / 2 ) )
                          . qq~$boardname</a><br />\n~;
                    }
                }
                if ( $subboard{$board} ) {
                    get_subboards( split /\|/xsm, $subboard{$board} );
                }
            }
            $indent -= 2;
        };

        for my $catid (@categoryorder) {
            (@bdlist) = split /\,/xsm, $cat{$catid};
            my $indent = -2;
            get_subboards(@bdlist);
        }

        $my_star = $myshow_star;
        $my_star =~ s/{yabb title}/$memstats[0]/sm;
        $my_star =~ s/{yabb memberstar}/$memberstar/sm;
        $my_star =~ s/{yabb my_mod_star}/$my_mod_star/sm;
    }
    if ( $row_gender || $row_age || $row_location ) {
        $my_gender = $myshow_gender;
        $my_gender =~ s/{yabb row_gender}/$row_gender/sm;
        $my_gender =~ s/{yabb row_age}/$row_age/sm;
        $my_gender =~ s/{yabb row_zodiac}/$row_zodiac/sm;
        $my_gender =~ s/{yabb row_location}/$row_location/sm;
    }
    if ($extendedprofiles) {
        require Sources::ExtendedProfiles;
        $my_extprofile .= ext_viewprofile($user);
    }

    CheckUserPM_Level($user);
    if (
          !$view
        && $user ne $username
        && (
            $PM_level == 1
            || (   $PM_level == 2
                && $UserPM_Level{$user} > 1
                && ($staff) )
            || (   $PM_level == 3
                && $UserPM_Level{$user} == 3
                && ( $iamadmin || $iamgmod ) )
            || (   $PM_level == 4
                && $UserPM_Level{$user} == 4
                && ( $iamadmin || $iamgmod || $iamfmod ) )
        )
      )
    {
        $my_userlevel = qq~
            <div class="contactleft">
                <b>$profile_txt{'144'}: </b>
            </div>
            <div class="contactright">
                <a href="$scripturl?action=imsend;to=$useraccount{$user}">$profile_txt{'688'} ${$uid.$user}{'realname'}</a>
            </div>~;
    }
    $userlastlogin = timeformat( ${ $uid . $user }{'lastonline'} );
    $userlastpost  = timeformat( ${ $uid . $user }{'lastpost'} );
    $userlastim    = timeformat( ${ $uid . $user }{'lastim'} );
    if ( $userlastlogin eq q{} ) { $userlastlogin = "$profile_txt{'470'}"; }
    if ( $userlastpost eq q{} )  { $userlastpost  = "$profile_txt{'470'}"; }
    if ( $userlastim eq q{} )    { $userlastim    = "$profile_txt{'470'}"; }
    my ( $lastonline, $lastpost, $lastPM );
    ## MF-B code fix for lpd
    if ( ${ $uid . $user }{'postcount'} > 0 ) {
        $userlastpost = usersrecentposts(1);
    }
    ####
    if ( !$view ) {
        $lastonline = qq~$profile_amv_txt{'9'}~;
        $lastpost   = qq~$profile_amv_txt{'10'}~;
        $lastPM     = qq~$profile_amv_txt{'11'}~;

    }
    else {
        $lastonline = qq~$profile_amv_txt{'mylastonline'}~;
        $lastpost   = qq~$profile_amv_txt{'mylastpost'}~;
        $lastPM     = qq~$profile_amv_txt{'mylastpm'}~;
    }
    if ( $pm_lev == 1 ) {
        $my_lastPM = qq~
            <div class="contactleft"><b>$lastPM: </b></div>
            <div class="contactright">$userlastim</div>~;
    }
    if (   ( $iamadmin || $iamgmod || $iamfmod )
        && !$view
        && $user ne $username
        && $user ne 'admin' )
    {
        $is_banned = check_banlist( "${$uid.$user}{'email'}", q{}, "$user" );
        $ban_user_email = ${ $uid . $user }{'email'};
        $ban_user_email =~ s/([^A-Za-z0-9])/sprintf('%%%02X', ord($1))/segm;
        require Sources::Security;
        if ( $is_banned =~ /E/sm ) {
            $ban_email_link =
qq~<span class="small">[ <a href="$scripturl?action=ipban_update;ban_email=$ban_user_email;username=$useraccount{$user};unban=1" onclick="return confirm('$profile_txt{'904a'}${$uid.$user}{'email'}');">$profile_txt{'904'}</a> ]</span>~;
        }
        elsif ( ${ $uid . $user }{'position'} ne 'Administrator' ) {
            $ban_email_link = qq~<span class="small">[ $profile_txt{'907'}: ~;
            my $bansep = $#timeban;
            my $levsep = q~ | ~;
            for my $i (@timeban) {
                if ( !$bansep-- ) { $levsep = q{}; }
                $ban_email_link .=
qq~<a href="$scripturl?action=ipban_update;ban_email=$ban_user_email;username=$useraccount{$user};lev=$i" onclick="return confirm('$profile_txt{'907a'}${$uid.$user}{'email'}');">$profile_txt{$i}</a>$levsep~;
            }
            $ban_email_link .= q~ ]</span>~;
        }
        else {
            $ban_email_link = q{};
        }
        $ban_user_name = $useraccount{$user};

        if ( $is_banned =~ /U/sm ) {
            $ban_user_link =
qq~<span class="small">[ <a href="$scripturl?action=ipban_update;ban_memname=$ban_user_name;username=$useraccount{$user};unban=1" onclick="return confirm('$profile_txt{'903a'}$user');">$profile_txt{'903'}</a> ]</span>~;
        }
        elsif ( ${ $uid . $user }{'position'} ne 'Administrator' ) {
            $ban_user_link = qq~<span class="small">[ $profile_txt{'906'}: ~;
            my $bansep = $#timeban;
            my $levsep = q~ | ~;
            for my $i (@timeban) {
                if ( !$bansep-- ) { $levsep = q{}; }
                $ban_user_link .=
qq~<a href="$scripturl?action=ipban_update;ban_memname=$ban_user_name;username=$useraccount{$user};lev=$i" onclick="return confirm('$profile_txt{'906a'}$user');">$profile_txt{$i}</a>$levsep~;
            }
            $ban_user_link .= q~ ]</span>~;
        }
        else {
            $ban_user_link = q{};
        }

        # Shows the banning stuff for IP's
        @banlink        = ();
        $ip_ban_options = q{};
        if ( ${ $uid . $user }{'lastips'} ) {
            @ip_ban = split /\|/xsm, ${ $uid . $user }{'lastips'};
            for my $ip ( 0 .. ( @ip_ban - 1 ) ) {
                if ( check_banlist( q{}, "$ip_ban[$ip]", q{} ) ) {
                    $banlink[$ip] =
qq~<span class="small">[ <a href="$scripturl?action=ipban_update;ban=$ip_ban[$ip];username=$useraccount{$user};unban=1" onclick="return confirm('$profile_txt{'905a'}$ip_ban[$ip]');">$profile_txt{'905'}</a> ]</span>~;
                }
                elsif ( ${ $uid . $user }{'position'} ne 'Administrator' ) {
                    $banlink[$ip] =
                      qq~<span class="small">[ $profile_txt{'908'}: ~;
                    my $bansep = $#timeban;
                    my $levsep = q~ | ~;
                    for my $i (@timeban) {
                        if ( !$bansep-- ) { $levsep = q{}; }
                        $banlink[$ip] .=
qq~<a href="$scripturl?action=ipban_update;ban=$ip_ban[$ip];username=$useraccount{$user};lev=$i" onclick="return confirm('$profile_txt{'908a'}$ip_ban[$ip]');">$profile_txt{$i}</a>$levsep~;
                    }
                    $banlink[$ip] .= q~ ]</span>~;
                }
                else {
                    $banlink[$ip] .= q{};
                }
            }
            for my $i ( 0 .. ( @ip_ban - 1 ) ) {
                if ( $ip_ban[$i] ) {
                    my $lookupIP =
                      ($ipLookup)
                      ? qq~<a href="$scripturl?action=iplookup;ip=$ip_ban[$i]">$ip_ban[$i]</a>~
                      : qq~$ip_ban[$i]~;
                    $ip_ban_options .= qq~$lookupIP<br />$banlink[$i]<br />~;
                }
            }
        }

        $my_banning = $myshow_banning;
        $my_banning =~ s/{yabb ban_user}/$user/sm;
        $my_banning =~ s/{yabb ban_user_link}/$ban_user_link/sm;
        $my_banning =~ s/{yabb ban_email}/${$uid.$user}{'email'}/sm;
        $my_banning =~ s/{yabb ban_email_link}/$ban_email_link/sm;
        $my_banning =~ s/{yabb ip_ban_options}/$ip_ban_options/sm;
    }
    if ( ${ $uid . $user }{'position'} eq 'Administrator' && !$iamadmin ) {
        $my_banning = q{};
    }

    if (   $iamadmin
        && !$view
        && $user ne $username
        && ${ $uid . $user }{'position'} ne 'Administrator' )
    {
        $my_reminder = $myshow_reminder;
        $my_reminder =~ s/{yabb my_realname}/${$uid.$user}{'realname'}/sm;
    }

    if (   ${ $uid . $user }{'postcount'} > 0
        && $maxrecentdisplay > 0
        && !$view )
    {
        my ( $x, $y ) = ( int( $maxrecentdisplay / 5 ), 0 );
        if ($x) {
            for my $i ( 1 .. 5 ) {
                $y = $i * $x;
                $my_recent_display .= qq~
                        <option value="$y">$y</option>~;
            }
        }
        if ( $maxrecentdisplay > $y ) {
            $my_recent_display .= qq~
                        <option value="$maxrecentdisplay">$maxrecentdisplay</option>~;
        }

        $my_recent = $myshow_recent;
        $my_recent =~ s/{yabb user}/$useraccount{$user}/sm;
        $my_recent =~ s/{yabb my_recent_display}/$my_recent_display/sm;
        $my_recent =~ s/{yabb my_realname}/${$uid.$user}{'realname'}/sm;
    }

    $showProfile .= $myshow_profile;
    $showProfile =~ s/{yabb pic_row}/$pic_row/sm;
    $showProfile =~ s/{yabb realname}/${$uid.$user}{'realname'}/sm;
    $showProfile =~ s/{yabb col_title_user}/$col_title{$user}/sm;
    $showProfile =~ s/{yabb row_addgrp}/$row_addgrp/sm;
    $showProfile =~ s/{yabb memberstar_user}/$memberstar{$user}/sm;
    $showProfile =~ s/{yabb my_online}/$my_online/sm;
    $showProfile =~ s/{yabb showusertext}/$showusertext/sm;
    $showProfile =~ s/{yabb buddybutton}/$buddybutton/sm;
    $showProfile =~ s/{yabb modify}/$modify/sm;
    $showProfile =~ s/{yabb my_star}/$my_star/sm;
    $showProfile =~ s/{yabb post_count}/$post_count/sm;
    $showProfile =~ s/{yabb post_per_day}/$post_per_day/sm;
    $showProfile =~ s/{yabb dr}/$dr/sm;
    $showProfile =~ s/{yabb member_for_days}/$member_for_days/sm;
    $showProfile =~ s/{yabb my_gender}/$my_gender/sm;
    $showProfile =~ s/{yabb my_extprofile}/$my_extprofile/sm;
    $showProfile =~ s/{yabb my_userlevel}/$my_userlevel/sm;
    $showProfile =~ s/{yabb row_email}/$row_email/sm;
    $showProfile =~ s/{yabb row_website}/$row_website/sm;
    $showProfile =~ s/{yabb row_aim}/$row_aim/sm;
    $showProfile =~ s/{yabb row_skype}/$row_skype/sm;
    $showProfile =~ s/{yabb row_yim}/$row_yim/sm;
    $showProfile =~ s/{yabb row_gtalk}/$row_gtalk/sm;
    $showProfile =~ s/{yabb row_myspace}/$row_myspace/sm;
    $showProfile =~ s/{yabb row_facebook}/$row_facebook/sm;
    $showProfile =~ s/{yabb row_twitter}/$row_twitter/sm;
    $showProfile =~ s/{yabb row_youtube}/$row_youtube/sm;
    $showProfile =~ s/{yabb row_icq}/$row_icq/sm;
    $showProfile =~ s/{yabb row_signature}/$row_signature/sm;
    $showProfile =~ s/{yabb lastonline}/$lastonline/sm;
    $showProfile =~ s/{yabb userlastlogin}/$userlastlogin/sm;
    $showProfile =~ s/{yabb lastpost}/$lastpost/sm;
    $showProfile =~ s/{yabb userlastpost}/$userlastpost/sm;
    $showProfile =~ s/{yabb my_lastPM}/$my_lastPM/sm;
    $showProfile =~ s/{yabb my_banning}/$my_banning/sm;
    $showProfile =~ s/{yabb my_reminder}/$my_reminder/sm;
    $showProfile =~ s/{yabb my_recent}/$my_recent/sm;
## Mod Hook showProfile2 ##

    $yytitle = $profile_txt{'92u'};
    $yytitle =~ s/USER/${$uid.$user}{'realname'}/gsm;
    if ( !$view ) {
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub usersrecentposts {
    my @x = @_;
    if ($iamguest)                      { fatal_error('members_only'); }
    if ( $INFO{'username'} =~ /\//xsm ) { fatal_error('no_user_slash'); }
    if ( $INFO{'username'} =~ /\\/xsm ) {
        fatal_error('no_user_backslash');
    }
    if ( !-e ("$memberdir/$INFO{'username'}.vars") ) {
        fatal_error('no_profile_exists');
    }
    if ( $action =~ /^(?:my)?usersrecentposts$/xsm ) { spam_protection(); }

    my $curuser = $INFO{'username'};
    LoadUser($curuser);

    my $display = $FORM{'viewscount'} ? $FORM{'viewscount'} : $x[0];
    if ( !$display ) { $display = 5; }
    elsif ( $display =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }
    if ( $display > $maxrecentdisplay ) { $display = $maxrecentdisplay; }

    my (
        %data,              $numfound,    %threadfound, %boardtxt,
        %recentthreadfound, $recentfound, $save_recent, $boardperms,
        %boardcat,          %catinfos,    $curboard,    $c,
        @messages,          $tnum,        $tsub,        $tname,
        $temail,            $tdate,       $treplies,    $tusername,
        $ticon,             $tstate,      $mname,       $memail,
        $mdate,             $musername,   $micon,       $mattach,
        $mip,               $mns,         $counter,     $board,
        $notify,            $catid
    );

    Recent_Load($curuser);
    my @recent =
      reverse sort { ${ $recent{$a} }[1] <=> ${ $recent{$b} }[1] }
      grep         { ${ $recent{$_} }[1] > 0 } keys %recent;
    my $recentcount = keys %recent;
    my @data;
    $#data = $display - 1;
    @data = map { 0 } @data;

    get_forum_master();
    foreach my $catid (@categoryorder) {
        foreach ( split /\,/xsm, $cat{$catid} ) {
            $boardcat{$_} = $catid;
            @{ $catinfos{$_} } = split /\|/xsm, $catinfo{$catid}, 3;
        }
    }

  RECENTCHECK: foreach my $thread (@recent) {
        MessageTotals( 'load', $thread );
        if ( ${$thread}{'board'} eq q{} ) {
            $save_recent = 1;
            delete $recent{$thread};
            $recentcount--;
            next RECENTCHECK;
        }
        $curboard = ${$thread}{'board'};

        if ( !$boardtxt{$curboard} ) {
            ( $boardname{$curboard}, $boardperms, undef ) = split /\|/xsm,
              $board{$curboard};

            if (
                !$iamadmin
                && (  !CatAccess( ${ $catinfos{$curboard} }[1] )
                    || AccessCheck( $curboard, q{}, $boardperms ) ne 'granted' )
              )
            {
                $recentcount--;
                next RECENTCHECK;
            }

            fopen( FILE, "$boardsdir/$curboard.txt" );
            @{ $boardtxt{$curboard} } = <FILE>;
            fclose(FILE);

            if ( !@{ $boardtxt{$curboard} } ) {
                $save_recent = 1;
                delete $recent{$thread};
                $recentcount--;
                next RECENTCHECK;
            }
        }
        elsif ($numfound) {
            if ( exists $recentthreadfound{$thread} ) {
                $recentfound += $recentthreadfound{$thread};
            }
            last
              if $recentfound >= $display
              && $data[-1] > ${ $recent{$thread} }[1];
            next;
        }

        for my $i ( 0 .. ( @{ $boardtxt{$curboard} } - 1 ) ) {
            (
                $tnum,     $tsub,      $tname, $temail, $tdate,
                $treplies, $tusername, $ticon, $tstate
            ) = split /\|/xsm, ${ $boardtxt{$curboard} }[$i];

            if (   ( $display == 1 && $thread == $tnum )
                || ( $display > 1 && exists $recent{$tnum} ) )
            {
                if ( $tstate =~ /h/sm && !$iamadmin && !$iamgmod ) {
                    $recentcount--;
                }
                else {
                    fopen( FILE, "$datadir/$tnum.txt" );
                    @messages = <FILE>;
                    fclose(FILE);

                    my $usercheck = 0;

                    for my $c ( reverse 0 .. $#messages ) {
                        (
                            $msub,      $mname, $memail,  $mdate,
                            $musername, $micon, $mattach, $mip,
                            $message,   $mns
                        ) = split /\|/xsm, $messages[$c];

                        if ( $curuser eq $musername ) {
                            my @i = ( @data, $mdate );
                            @data = reverse sort { $a <=> $b } @i;
                            if ( pop(@data) < $mdate ) {
                                chomp $mns;
                                $data{$mdate} = [
                                    $curboard, $tnum,    $c,
                                    $tname,    $msub,    $mname,
                                    $memail,   $mdate,   $musername,
                                    $micon,    $mattach, $mip,
                                    $message,  $mns,     $tstate,
                                    $tusername
                                ];
                                if ( !$usercheck ) {
                                    $numfound++;
                                    $threadfound{$tnum} = 1;
                                }
                                if ( exists $recent{$tnum} ) {
                                    $recentthreadfound{$tnum}++;
                                    if ( $thread == $tnum ) {
                                        $recentfound++;
                                    }
                                }
                                if ( ${ $recent{$tnum} }[1] < $mdate ) {
                                    $save_recent = 1;
                                    ${ $recent{$tnum} }[1] = $mdate;
                                }
                            }
                            $usercheck = 1;
                        }
                    }
                    if ( !$usercheck ) {
                        $save_recent = 1;
                        delete $recent{$tnum};
                        $recentcount--;
                    }
                }
            }
        }
    }

    if ( $recentfound < $display && $numfound < $recentcount ) {
      CATEGORYCHECK: foreach my $catid (@categoryorder) {
            if ( !CatAccess( ( split /\|/xsm, $catinfo{$catid}, 3 )[1] ) ) {
                next CATEGORYCHECK;
            }

          BOARDCHECK:
            foreach my $curboard ( split /\,/xsm, $cat{$catid} ) {
                if ( !$boardtxt{$curboard} ) {
                    ( $boardname{$curboard}, $boardperms, undef ) =
                      split /\|/xsm, $board{$curboard};

                    if ( !$iamadmin
                        && AccessCheck( $curboard, q{}, $boardperms ) ne
                        'granted' )
                    {
                        next BOARDCHECK;
                    }

                    my $bdmods = ${ $uid . $curboard }{'mods'};
                    $bdmods =~ s/\, /\,/gsm;
                    $bdmods =~ s/\ /\,/gsm;
                    my %moderators = ();
                    my $pswiammod  = 0;
                    foreach my $curuser ( split /\,/xsm, $bdmods ) {
                        if ( $username eq $curuser ) { $pswiammod = 1; }
                    }
                    my $bdmodgroups = ${ $uid . $curboard }{'modgroups'};
                    $bdmodgroups =~ s/\, /\,/gsm;
                    my %moderatorgroups = ();
                    foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                        if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                            $pswiammod = 1;
                        }
                        foreach my $memberaddgroups ( split /\, /sm,
                            ${ $uid . $username }{'addgroups'} )
                        {
                            chomp $memberaddgroups;
                            if ( $memberaddgroups eq $curgroup ) {
                                $pswiammod = 1;
                                last;
                            }
                        }
                    }
                    my $cookiename = "$cookiepassword$curboard$username";
                    my $crypass    = ${ $uid . $curboard }{'brdpassw'};
                    if (   !$staff
                        && !$pswiammod
                        && $yyCookies{$cookiename} ne $crypass )
                    {
                        next;
                    }
                    fopen( FILE, "$boardsdir/$curboard.txt" )
                      || next BOARDCHECK;
                    @{ $boardtxt{$curboard} } = <FILE>;
                    fclose(FILE);
                }

                for my $i ( 0 .. ( @{ $boardtxt{$curboard} } - 1 ) ) {
                    (
                        $tnum,      $tsub,  $tname,
                        $temail,    $tdate, $treplies,
                        $tusername, $ticon, $tstate
                    ) = split /\|/xsm, ${ $boardtxt{$curboard} }[$i];

                    if ( exists( $recent{$tnum} )
                        && !exists $threadfound{$tnum} )
                    {
                        if ( $tstate !~ /h/sm || $iamadmin || $iamgmod ) {
                            fopen( FILE, "$datadir/$tnum.txt" );
                            @messages = <FILE>;
                            fclose(FILE);

                            my $usercheck = 0;

                            for my $c ( reverse 0 .. $#messages ) {
                                (
                                    $msub,      $mname, $memail,  $mdate,
                                    $musername, $micon, $mattach, $mip,
                                    $message,   $mns
                                ) = split /\|/xsm, $messages[$c];

                                if ( $curuser eq $musername ) {
                                    my @i = @data;
                                    push @i, $mdate;
                                    @data = reverse sort { $a <=> $b } @i;
                                    if ( pop(@data) != $mdate ) {
                                        chomp $mns;
                                        $data{$mdate} = [
                                            $curboard,  $tnum,
                                            $c,         $tname,
                                            $msub,      $mname,
                                            $memail,    $mdate,
                                            $musername, $micon,
                                            $mattach,   $mip,
                                            $message,   $mns,
                                            $tstate,    $tusername
                                        ];
                                        if ( ${ $recent{$tnum} }[1] < $mdate ) {
                                            $save_recent = 1;
                                            ${ $recent{$tnum} }[1] = $mdate;
                                        }
                                    }
                                    $usercheck = 1;
                                }
                            }

                            if ( !$usercheck ) {
                                $save_recent = 1;
                                delete $recent{$tnum};
                            }
                        }
                    }
                }
            }
        }
    }

    undef %boardtxt;

    if ($save_recent) { Recent_Save($curuser); }

    if ( $display == 1 ) {
        return if !$data[0];
        (
            $board,     $tnum,  $c,       $tname,
            $msub,      $mname, $memail,  $mdate,
            $musername, $micon, $mattach, $mip,
            $message,   $mns,   $tstate,  $tusername
        ) = @{ $data{ $data[0] } };
        ToChars($msub);
        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        return ( timeformat($mdate)
              . qq~<br />$profile_txt{'view'} &rsaquo; <a href="$scripturl?num=$tnum/$c#$c">$msub</a>~
        );
    }

    LoadCensorList();

    for my $i ( 0 .. ( @data - 1 ) ) {
        next if !$data[$i];

        (
            $board,     $tnum,  $c,       $tname,
            $msub,      $mname, $memail,  $mdate,
            $musername, $micon, $mattach, $mip,
            $message,   $mns,   $tstate,  $tusername
        ) = @{ $data{ $data[$i] } };
        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        wrap();
        $displayname = $mname;
        ( $message, undef ) = Split_Splice_Move( $message, $tnum );
        if ($enable_ubbc) {
            $ns = $mns;
            enable_yabbc();
            DoUBBC();
        }
        wrap2();
        ToChars($msub);
        ToChars($message);
        $msub    = Censor($msub);
        $message = Censor($message);
        ToChars( ${ $catinfos{$board} }[0] );
        ToChars( $boardname{$board} );

        $counter++;

        if ( $tusername !~ m{Guest}sm ) {
            if ( -e ("$memberdir/$tusername.vars") ) {
                LoadUser($tusername);
                $mytname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tusername}" rel="nofollow">$format_unbold{$tusername}</a>~;
            }
            else { $mytname = qq~$tname - $maintxt{'470a'}~; }
        }
        else {
            $mytname = "$tname ($maintxt{'28'})";
        }

        $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$curuser}" rel="nofollow">$format_unbold{$curuser}</a>~;

        $mdate = timeformat($mdate);

        get_template('MyPosts');
        $mypostborder = q{};
        if ( $action eq 'myusersrecentposts' ) {
            $mypostborder = ' class="mypostborder"';
        }

        $showProfile .= $myshow_recent_a;

        $showProfile =~ s/{yabb counter}/$counter/sm;
        $showProfile =~ s/{yabb brdcat}/$boardcat{$board}/sm;
        $showProfile =~ s/{yabb brd}/$boardcat{$board}/sm;
        $showProfile =~ s/{yabb catinfobrd}/${$catinfos{$board}}[0]/sm;
        $showProfile =~ s/{yabb brdbrd}/$boardname{$board}/sm;
        $showProfile =~ s/{yabb tnum}/$tnum\/$c#$c/sm;
        $showProfile =~ s/{yabb msub}/$msub/sm;
        $showProfile =~ s/{yabb mdate}/$mdate/sm;
        $showProfile =~ s/{yabb tname}/$mytname/sm;
        $showProfile =~ s/{yabb poster}/$mname/sm;
        $showProfile =~ s/{yabb mypostborder}/$mypostborder/sm;

        if ( $tstate != 1 ) {
            if ( ${ $uid . $username }{'thread_notifications'} =~
                /\b$tnum\b/xsm )
            {
                $notify =
qq~$menusep<a href="$scripturl?action=notify3;num=$tnum/$c;oldnotify=1">$img{'del_notify'}</a>~;
            }
            else {
                $notify =
qq~$menusep<a href="$scripturl?action=notify2;num=$tnum/$c;oldnotify=1">$img{'add_notify'}</a>~;
            }
            $showProfile .=
qq~<a href="$scripturl?board=$board;action=post;num=$tnum/$c#$c;title=PostReply">$img{'reply'}</a>$menusep<a href="$scripturl?board=$board;action=post;num=$tnum;quote=$c;title=PostReply">$img{'recentquote'}</a>$notify &nbsp;~;
        }

        $showProfile .= $myshow_recent_b;
        $showProfile =~ s/{yabb recentmsg}/$message/sm;
    }

    if ( !$counter ) {
        $showProfile .= qq~<b>$profile_txt{'755'}</b>~;
    }
    elsif ( !$view ) {
        $showProfile .=
qq~<p><a href="$scripturl?action=viewprofile;username=$useraccount{$curuser}"><b>$profile_txt{'92u'}</b></a></p>~;
        $showProfile =~ s/USER/${$uid.$curuser}{'realname'}/gsm;
    }

    $yytitle = "$profile_txt{'458'} ${$uid.$curuser}{'realname'}";
    if ( !$view ) {
        $yynavigation = qq~&rsaquo; $maintxt{'213'}~;
        $yymain .= $showProfile;
        template();
    }
    return;
}

sub DrawGroups {
    my ( $availgroups, $position, $show_additional ) = @_;
    my ( %groups, $groupsel );
    map { $groups{$_} = 1; } split /,/xsm, $availgroups;

    for my $key (@nopostorder) {
        my (
            $name, undef, undef, undef, undef, undef,
            undef, undef, undef, undef, $additional
        ) = split /\|/xsm, $NoPost{$key};
        next if ( !$show_additional && !$additional ) || $position eq $key;

        $groupsel .=
            qq~<option value="$key"~
          . ( $groups{$key} ? ' selected="selected"' : q{} )
          . qq~>$name</option>~;
        $selsize++;
    }
    return ( $groupsel, ( $selsize > 6 ? 6 : $selsize ) );
}

sub isselected {
    my ($inp) = @_;

    # Return a ref so we can be used like ${isselected($var)} inside a string
    return \' selected="selected"' if $inp;
    return \q{};
}
1;
