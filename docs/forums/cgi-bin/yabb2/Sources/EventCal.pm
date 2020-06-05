###############################################################################
# EventCal.pm                                                                 #
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
#use warnings;
#no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
use Time::Local;
our $VERSION = '2.6.11';

$eventcalpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('EventCal');
LoadLanguage('Post');
LoadLanguage('LivePreview');

require Sources::SpamCheck;
require Sources::PostBox;
require Sources::Post;

get_micon();
get_template('Calendar');


if ( eval { require "$vardir/eventcalIcon.txt"; 1 } ) {
    $i = 0;
    while ( $CalIconURL[$i] ) {
        $cal_icon{"$CalIconURL[$i]"} = qq~<img src="$yyhtml_root/EventIcons/$CalIconURL[$i]" alt="$CalIDescription[$i]" />~;
        $cal_icon_bg{"$CalIconURL[$i]"} = qq~$yyhtml_root/EventIcons/$CalIconURL[$i]~;
        $var_cal{"$CalIconURL[$i]"} = $CalIDescription[$i];
        $add_cal_icon[$i] = qq~$CalIconURL[$i]|$CalIDescription[$i]~;
    $i++;
    }
}

$jsCal = qq~
var jsCal = new Hash(
'eventinfo', '$cal_icon_bg{'eventinfo'}',
'eventmore', '$cal_icon_bg{'eventmore'}',
'eventmorebd', '$cal_icon_bg{'eventmore'}',
'eventmoreadd', '$cal_icon_bg{'eventmore'}',
'eventannounce', '$cal_icon_bg{'eventannounce'}',
'eventholiday', '$cal_icon_bg{'eventholiday'}',
'eventnote', '$cal_icon_bg{'eventnote'}',
'eventparty', '$cal_icon_bg{'eventparty'}',
'eventcelebration', '$cal_icon_bg{'eventcelebration'}',
'eventsport', '$cal_icon_bg{'eventsport'}',
'eventmedia', '$cal_icon_bg{'eventmedia'}',
'eventmeeting', '$cal_icon_bg{'eventmeeting'}'~;
for $i (@add_cal_icon) {
     my($i_a,$i_b) = split /\|/xsm, $i;
    $jsCal .= qq~,\n'$i_a', '$yyhtml_root/EventIcons/$i_a'~;
}
$jsCal .= qq~);\n~;

$jsCal_txt = qq~
var jsCaltxt = new Hash(
'eventinfo', '$var_cal{'eventinfo'}',
'eventannounce', '$var_cal{'eventannounce'}',
'eventholiday', '$var_cal{'eventholiday'}',
'eventnote', '$var_cal{'eventnote'}',
'eventparty', '$var_cal{'eventparty'}',
'eventcelebration', '$var_cal{'eventcelebration'}',
'eventsport', '$var_cal{'eventsport'}',
'eventmedia', '$var_cal{'eventmedia'}',
'eventmeeting', '$var_cal{'eventmeeting'}'~;
for $i (@add_cal_icon) {
     my($i_a,$i_b) = split /\|/xsm, $i; #
    $jsCal_txt .= qq~,\n'$i_a', '$i_b'~;
}
$jsCal_txt .= qq~);\n~;

sub eventcal {
    my ( $ssicalmode, $ssicaldisplay ) = @_;
    my ( $i, $eventfound );
    ## SSI Variables ##

    # Access check to add events begin

    if ( !$Show_EventCal || ( $iamguest && $Show_EventCal != 2 ) ) {
        fatal_error('not_allowed');
    }

    my $Allow_Event_Imput = 0;
    if ($iamadmin) { $Allow_Event_Imput = 1; }
    elsif ( $CalEventPerms eq q{} ) { $Allow_Event_Imput = 1; }
    elsif ( $iamguest && $CalEventPerms ) { $Allow_Event_Imput = 0; }
    else {
      TOPLOOP: foreach my $element ( split /,/xsm, $CalEventPerms ) {
            if ( $element eq ${ $uid . $username }{'position'} ) {
                $Allow_Event_Imput = 1;
                last;
            }
            foreach ( split /,/xsm, $memberaddgroup{$username} ) {
                if ( $element eq $_ ) { $Allow_Event_Imput = 1; last TOPLOOP; }
            }
        }
        if ( !$Allow_Event_Imput && $CalEventMods ) {
            foreach ( split /,/xsm, $CalEventMods ) {
                if ( $_ eq $username ) { $Allow_Event_Imput = 1; last; }
            }
        }
    }

    # Access check to add events end

    # GoTo Box begin

    if ( $INFO{'calgotobox'} == 1 ) {
        $goyear = $FORM{'calyear'};
        $gomon  = $FORM{'calmon'};
        $goday  = $FORM{'calday'};

        if ($goday) {
            $yySetLocation =
qq~$scripturl?action=eventcal;calshow=1;eventdate=$goyear$gomon$goday;showmini=1~;
            redirectexit();
        }
        else {
            $yySetLocation =
qq~$scripturl?action=eventcal;calshow=1;calmon=$gomon;calyear=$goyear~;
            redirectexit();
        }
    }

    # GoTo Box end

    # Time/Days begin

    my ( $sel_year, $sel_mon, $sel_day );
    my $event_date = $INFO{'eventdate'};
    if ($event_date) {
        if ( $event_date =~ /(\d{4})(\d{2})(\d{2})/xsm ) {
            ( $sel_year, $sel_mon, $sel_day ) = ( $1, $2, $3 );
        }
    }

    my $newdate = $date;
    my $toffs = 0;
    if ($enabletz) {
        $toffs = toffs($date);
    }

    if ( $INFO{'calyear'} ) {
        $ausgabe1    = qq~$INFO{'calmon'}/01/$INFO{'calyear'} am 00:00:00~;
        $heute       = stringtotime($ausgabe1);
        $daterechnug = $heute;
    }
    else {
        $heute       = $date;
        $daterechnug = $date;
    }

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst ) =
      gmtime( $heute + $toffs );
    $year += 1900;

    my ( undef, undef, undef, $callnewday, $callnewmonth, $callnewyear, undef )
      = gmtime( $newdate + $toffs );
    $callnewyear += 1900;
    $callnewmonth++;

    if ( $INFO{'calyear'} ) {
        $year = $INFO{'calyear'};
        $mon  = $INFO{'calmon'} - 1;
    }
#    timeformatcal($date);    # get only correct $mytimeselected

    # Time/Days end

    # Get Navi begin

    if ( !$INFO{'calmon'} )      { $INFO{'calmon'} = $mon + 1; }
    if ( !$INFO{'calmon'} > 12 ) { $INFO{'calmon'} = 12; }

    $next_mon  = $INFO{'calmon'} + 1;
    $next_year = $year;
    $st_mon    = $next_mon;
    if ( $st_mon < 10 ) { $st_mon = "0$st_mon"; }
    $stnext     = 'calmon_' . $st_mon;
    $stnextname = $var_cal{$stnext};
    $last_mon   = $INFO{'calmon'} - 1;
    $st_mon     = "$last_mon";
    if ( $st_mon < 10 ) { $st_mon = "0$st_mon"; }
    $stlast     = 'calmon_' . $st_mon;
    $stlastname = $var_cal{$stlast};
    $last_year  = $year;
    if ( $INFO{'calmon'} == 12 ) { $next_mon = 1;  $next_year = $year + 1; }
    if ( $INFO{'calmon'} == 1 )  { $last_mon = 12; $last_year = $year - 1; }
    if ( $next_mon < 10 ) { $next_mon = "0$next_mon"; }
    if ( $last_mon < 10 ) { $last_mon = "0$last_mon"; }
    $next_link =
qq~<a href="$scripturl?action=eventcal;calshow=1;calmon=$next_mon;calyear=$next_year;" title="$stnextname $next_year"> -&raquo;</a>~;
    $last_link =
qq~<a href="$scripturl?action=eventcal;calshow=1;calmon=$last_mon;calyear=$last_year" title="$stlastname $last_year">&laquo;- </a>~;

    # Get Navi end

    # EventCal System begin

    $viewyear = $year;
    $viewyear = substr $viewyear, 2, 4;
    my @mon_days = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    $days = $mon_days[$mon];
    $wday1 = ( gmtime( timegm( 0, 0, 0, 1, $mon, $year ) ) )[6];
    if ($ShowSunday) { $wday1++; }
    if ( $wday1 == 0 ) { $wday1 = 7; }
    $mon++;
    $caltoday = "$year" . sprintf( '%02d', $mon ) . sprintf '%02d', $mday;
    $st_mon = "$mon";
    if ( $st_mon < 10 ) { $st_mon = "0$st_mon"; }
    $st       = 'calmon_' . $st_mon;
    $view_mon = $mon;
    if ( $view_mon < 10 ) { $view_mon = "0$view_mon"; }

    if ( !$Show_ColorLinks ) {
        ManageMemberinfo('load');
    }

    # EventCal System end

    # Add Events and GoTo begin

    for my $i ( 1 .. 31 ) {
        my $sel = q{};
        if ( $mday == $i && !$sel_day ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_day == $i ) {
            $sel = ' selected="selected"';
        }
        $sdays_inner .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
        $boxdays_inner .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
    }

    for my $i ( 1 .. 12 ) {
        my $sel = q{};
        if ( $mon == $i && !$sel_mon ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_mon == $i ) {
            $sel = ' selected="selected"';
        }
        $smonths_inner .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
        $boxmonths_inner .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
    }

    my $gyears3 = $year - 3;
    my $gyears2 = $year - 2;
    my $gyears1 = $year - 1;
    for my $i ( $year .. ( $year + 3 ) ) {
        my $sel = q{};
        if ( $year == $i && !$sel_year ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_year == $i ) {
            $sel = ' selected="selected"';
        }
        $syears_inner   .= qq~        <option value="$i"$sel>$i</option>\n~;
        $boxyears_inner .= qq~        <option value="$i"$sel>$i</option>\n~;
    }
## date selections  - formated ##
    my $sdays = qq~ <label for="selday">$var_cal{'calday'}</label>
    <select class="input" name="selday" id="selday" onchange="autoPreview()">
        $sdays_inner
    </select>~;
    my $boxdays =
qq~ <label for="calday"><span class="small">$var_cal{'calday'}</span></label>
    <select class="input" name="calday" id="calday">
    <option value="0">---</option>
        $boxdays_inner
        </select>~;
    my $smonths = qq~ <label for="selmon">$var_cal{'calmonth'}</label>
    <select class="input" name="selmon" id="selmon" onchange="autoPreview()">
        $smonths_inner
    </select>~;
    my $boxmonths =
qq~ <label for="calmon"><span class="small">$var_cal{'calmonth'}</span></label>
    <select class="input" name="calmon" id="calmon">
        $boxmonths_inner
    </select>~;
    my $syears = qq~ <label for="selyear">$var_cal{'calyear'}</label>
    <select class="input" name="selyear" id="selyear" onchange="autoPreview()">
        $syears_inner
    </select>~;
    my $boxyears =
qq~ <label for="calyear"><span class="small">&nbsp;$var_cal{'calyear'}</span></label>
    <select class="input" name="calyear" id="calyear">
        <option value="$gyears3">$gyears3</option>
        <option value="$gyears2">$gyears2</option>
        <option value="$gyears1">$gyears1</option>
        $boxyears_inner
    </select>~;

    my $addevdate;
    if (   $mytimeselected == 8
        || $mytimeselected == 6
        || $mytimeselected == 3
        || $mytimeselected == 2 )
    {
        $addevdate     .= $sdays . $smonths;
        $calgotobox_dm .= $boxdays . $boxmonths;
    }
    else {
        $addevdate     .= $smonths . $sdays;
        $calgotobox_dm .= $boxmonths . $boxdays;
    }
    $addevdate .= $syears;
    my $calgotobox = qq~
    <form action="$scripturl?action=eventcal;calshow=1;calgotobox=1" method="post">
    <span class="small"><b>$var_cal{'calsubmit'}</b></span>
     $calgotobox_dm$boxyears &nbsp; <input type="submit" name="Go" value="$var_cal{'calgo'}" />
    </form>\n~;

    # Add Events and GoTo end

    # YaBBC Section begin

    my $mycalout_post;
    if ( $INFO{'addnew'} == 1 ) {
        if ( $INFO{'edit_cal_even'} ) {
            $var_cal{'calevent'} = "$var_cal{'caledit'}:";
        }

        $calicon = 'eventinfo';

        ## Edit Infos Begin ##
        if    ( $INFO{'edit_typ'} == 0 ) { $aevt1 = ' selected="selected"'; }
        elsif ( $INFO{'edit_typ'} == 1 ) { $aevt2 = ' selected="selected"'; }
        elsif ( $INFO{'edit_typ'} == 2 ) { $aevt3 = ' selected="selected"'; }
        else                             { $aevt2 = ' selected="selected"'; }

        if    ( $INFO{'edit_typ1'} == 0 ) { $a1evt1 = ' selected="selected"'; }
        elsif ( $INFO{'edit_typ1'} == 2 ) { $a1evt2 = ' selected="selected"'; }
        elsif ( $INFO{'edit_typ1'} == 3 ) { $a1evt3 = ' selected="selected"'; }
        else                              { $a1evt1 = ' selected="selected"'; }

        if ( $INFO{'edit_icon'} ) {
            $class = "calicon_$INFO{'edit_icon'}";
            ${$class} = ' selected="selected"';
            $calicon = "$INFO{'edit_icon'}";
        }

        if ( $INFO{'edit_nonam'} == 1 ) { $cecknonam = 'checked="checked"' }
        ## Edit Infos End ##

        if (   ( $CalEventNoName == 0 && ( $iamadmin || $iamgmod ) )
            || ( $CalEventNoName == 1 && !$iamguest ) )
        {
            $option_noname = $mycal_noname;
            $option_noname =~ s/{yabb cecknonam}/$cecknonam/sm;
        }

        if ( $iamadmin || $iamgmod || ( $CalEventPrivate == 1 && !$iamguest ) )
        {
            $option_private =
              qq~<option value="2"$aevt3>$var_cal{'calprivate'}</option>~;
        }

        $mycalout_caltype = qq~
            <select name="caltype" id="caltype" size="1" onchange="autoPreview();">
                <option value="0"$aevt1>$var_cal{'calpublic'}</option>
                <option value="1"$aevt2>$var_cal{'calmembers'}</option>
                $option_private
            </select> /
            <select name="caltype2" size="1">
                <option value="0"$a1evt1>$var_cal{'onlyone'}</option>
                <option value="2"$a1evt2>$var_cal{'eventinfo'} ($var_cal{'monthly'})</option>
                <option value="3"$a1evt3>$var_cal{'eventinfo'} ($var_cal{'yearly'})</option>
            </select>~;
        $mycalout_calicon = qq~
            <select name="calicon" id="calicon" onchange="calshowimage(); autoPreview()">
                <option value="eventinfo"$calicon_eventinfo>$var_cal{'eventinfo'}</option>
                <option value="eventholiday"$calicon_eventholiday>$var_cal{'eventholiday'}</option>
                <option value="eventannounce"$calicon_eventannounce>$var_cal{'eventannounce'}</option>
                <option value="eventnote"$calicon_eventnote>$var_cal{'eventnote'}</option>
                <option value="eventparty"$calicon_eventparty>$var_cal{'eventparty'}</option>
                <option value="eventcelebration"$calicon_eventcelebration>$var_cal{'eventcelebration'}</option>
                <option value="eventsport"$calicon_eventsport>$var_cal{'eventsport'}</option>
                <option value="eventmedia"$calicon_eventmedia>$var_cal{'eventmedia'}</option>
                <option value="eventmeeting"$calicon_eventmeeting>$var_cal{'eventmeeting'}</option>~;

        if ( eval { require "$vardir/eventcalIcon.txt"; 1 } ) {
            $i = 0;
            while ( $CalIconURL[$i] ) {
                if ( $INFO{'edit_icon'} eq $CalIconURL[$i] ) {
                    $eveic[$i] = ' selected';
                }
                $mycalout_calicon .= qq~
                    <option value="$CalIconURL[$i]"$eveic[$i]>$CalIDescription[$i]</option>~;
                $i++;
            }
        }
        $mycalout_calicon .= q~
            </select>~;

        if ( $enable_ubbc && $showyabbcbutt ) {
            require Sources::ContextHelp;
            ContextScript('post');
            $mycalout_cthelp = $ctmain;
            $mycalout_cthelp .=
qq~<script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>~;
            $mycalout_cthelp .= postbox();
        }

        # SpellChecker start
        if ($enable_spell_check) {
            $yyinlinestyle .= googiea();
            $userdefaultlang = ( split /-/xsm, $abbr_lang )[0];
            $userdefaultlang ||= 'en';
            $mycalout_googie = googie($userdefaultlang);
        }

        # SpellChecker end

        if (
            !$removenormalsmilies
            && (   !${ $uid . $username }{'hide_smilies_row'}
                || !$user_hide_smilies_row )
          )
        {
            if ( $smiliestyle == 1 ) {
                $smiliewinlink = qq~$scripturl?action=smilieput~;
            }
            else { $smiliewinlink = qq~$scripturl?action=smilieindex~; }
            $mycalout_smilieslist .= smilies_list();

            $mycalout_smilies = qq~
            <script type="text/javascript">
                moresmiliecode = new Array($more_smilie_array);
                function MoreSmilies(i) {
                    AddTxt=moresmiliecode[i];
                    AddText(AddTxt);
                }
                function smiliewin() {
                    window.open("$smiliewinlink", 'list', 'width=$winwidth, height=$winheight, scrollbars=yes');
                }
            </script>
            $mycalout_smilieslist
            <span class="small"><a href="javascript: smiliewin();">$post_smiltxt{'17'}</a></span>\n~;
        }

        $mycalout_chars = qq~
<script src="$yyhtml_root/ajax.js" type="text/javascript"></script>
<script type="text/javascript">
    function Hash() {
        this.length = 0;
        this.items = new Array();
        for (var i = 0; i < arguments.length; i += 2) {
            if (typeof(arguments[i + 1]) != 'undefined') {
                this.items[arguments[i]] = arguments[i + 1];
                this.length++;
            }
        }

        this.getItem = function(in_key) {
            return this.items[in_key];
        };
    }
   $jsCal
   $jsCal_txt
   function calshowimage() {
        var icon_set = document.postmodify.calicon.options[document.postmodify.calicon.selectedIndex].value;
        var icon_show = jsCal.getItem(icon_set);
        document.images.liveicons.src = icon_show;
        document.images.calicons.src = icon_show;
   }
   // count left characters START
   ~;
        $my_ajxcall = 'ajxcal';
        $mycalout_chars .= my_liveprev();
        $mycalout_chars .= q~</script>
~;
        $guestpost_fields =
            $iamguest
          ? $mycal_guest_fields
          : q{};
        $guestpost_fields =~ s/{yabb name}/$FORM{'name'}/sm;
        $guestpost_fields =~ s/{yabb email}/$FORM{'email'}/sm;

        if ( $iamguest && $gpvalid_en ) {
            require Sources::Decoder;
            validation_code();
            $verification_field = $mycal_validation;
            $verification_field =~ s/{yabb showcheck}/$showcheck/sm;
            $verification_field =~ s/{yabb flood_text}/$flood_text/sm;
        }
        if (   $iamguest
            && $spam_questions_gp
            && -e "$langdir/$language/spam.questions" )
        {
            SpamQuestion();
            my $verification_question_desc;
            if ($spam_questions_case) {
                $verification_question_desc =
                  qq~<br />$var_cal{'verification_question_case'}~;
            }
            $mycalout_spamquestion = $mycal_spamquest;
            $mycalout_spamquestion =~ s/{yabb spam_question}/$spam_question/sm;
            $mycalout_spamquestion =~
s/{yabb verification_question_desc}/$verification_question_desc/sm;
            $mycalout_spamquestion =~
              s/{yabb spam_question_id}/$spam_question_id/sm;
            $mycalout_spamquestion =~ s/{yabb spam_question_image}/$spam_image/sm;
        }
        if ($iamguest) {
            $liveusernamelink =
qq~<br /><b>$var_cal{'by'}</b> <span id="savename"></span> ($var_cal{'guest'})~;
        }
        else {
            $liveusernamelink =
              qq~<br /><b>$var_cal{'by'}</b> $format{$username}~;
        }

        if ( !$INFO{'edit_cal_even'} ) {
            $submittxt     = "$var_calpost{'event_send'}";
            $mycalout_send = qq~
            <input id="calsubmit" class="button" type="submit" name="calsubmit" value="$submittxt" accesskey="s" />
            ~;
            if ($speedpostdetection) {
                $post = 'calsubmit';
                $mycalout_send .= q~
                    <script type="text/javascript">~
                  . speedpost() . q~</script>~;
            }
            $mycalout_send .= $mycal_endaddform;
        }
        $col_row ||= 0;
        $mycalout_post2 = postbox2();
        $mycalout_post3 = postbox3();

        $livemsgimg =
          qq~<img src="$cal_icon_bg{$calicon}" name="liveicons" alt="" />~;
        $my_evtitle = q~<span id="ev_title"></span>~;
        $my_private = q~<span id="ev_private"></span>~;

        $messageblock = $mycal_liveprev;
        $messageblock =~ s/{yabb css}/$css/gsm;
        $messageblock =~ s/{yabb eventuserlink}/$liveusernamelink/gsm;
        $messageblock =~ s/{yabb cdate}/<span id="cdate"><\/span>/gsm;
        $messageblock =~ s/{yabb my_cal_icon}/$livemsgimg/gsm;
        $messageblock =~ s/{yabb my_cal_private}/$my_private/sm;
        $messageblock =~ s/{yabb icon_text}/$my_evtitle/sm;
        $messageblock =~
          s/{yabb message}/<span id="savemess"><\/span>/gsm;
        $messageblock =~ s/{yabb (.+?)}//gsm;

        $my_postsection_ajx = my_check_prev();
    }

    $my_subcheck = qq~
<script type="text/javascript">
    var postas = '$post';
    function checkForm(theForm) {
        var isError = 0;
        var msgError = "$post_txt{'751'}\\n";
    ~;
    if ($iamguest) {
        $my_subcheck .=
qq~if (theForm.name.value === "" || theForm.name.value == "_" || theForm.name.value == " ") { msgError += "\\n - $post_txt{'75'}"; if (isError === 0) isError = 2; }
        if (theForm.name.value.length > 25)  { msgError += "\\n - $post_txt{'568'}"; if (isError === 0) isError = 2; }
        if (theForm.email.value === "") { msgError += "\\n - $post_txt{'76'}"; if (isError === 0) isError = 3; }
        if (! checkMailaddr(theForm.email.value)) { msgError += "\\n - $post_txt{'500'}"; if (isError === 0) isError = 3; }~;
    }

    $checkallcaps ||= 0;
    $my_subcheck .= qq~
    if (theForm.message.value === "") { msgError += "\\n - $post_txt{'78'}"; if (isError === 0) isError = 5; }
    else if ($checkallcaps && theForm.message.value.search(/[A-Z]{$checkallcaps,}/g) != -1) {
        if (isError === 0) { msgError = " - $post_txt{'79'}"; isError = 5; }
        else { msgError += "\\n - $post_txt{'79'}"; }
    }
    if (isError > 0) {
        alert(msgError);
        if (isError == 1) imWin();
        else if (isError == 2) theForm.name.focus();
        else if (isError == 3) theForm.email.focus();
        else if (isError == 5) theForm.message.focus();
        return false;
    }
    return true;
}
</script>
~;

    $mycalout_post = qq~
<script src="$yyhtml_root/ajax.js" type="text/javascript"></script>
$my_subcheck
<form action="$scripturl?action=add_cal" name="postmodify" method="post" onsubmit="if(!checkForm(this)) {return false} else {return submitproc()}" accept-charset="$yymycharset">
$mycalout_addevent
~;

    $mycalout_post =~ s/{yabb calevent}/$var_cal{'calevent'}/sm;
    $mycalout_post =~ s/{yabb addevdate}/$addevdate/sm;
    $mycalout_post =~ s/{yabb option_noname}/$option_noname/sm;
    $mycalout_post =~ s/{yabb mycalout_caltype}/$mycalout_caltype/sm;
    $mycalout_post =~ s/{yabb mycalout_calicon}/$mycalout_calicon/sm;
    $mycalout_post =~ s/{yabb calicon}/$calicon/gsm;
    $mycalout_post =~ s/{yabb caliconimg}/$cal_icon_bg{$calicon}/gsm;
    $mycalout_post =~ s/{yabb mycalout_cthelp}/$mycalout_cthelp/sm;
    $mycalout_post =~ s/{yabb mycalout_post2}/$mycalout_post2/sm;
    $mycalout_post =~ s/{yabb mycalout_googie}/$mycalout_googie/sm;
    $mycalout_post =~ s/{yabb mycalout_smilies}/$mycalout_smilies/sm;
    $mycalout_post =~ s/{yabb mycalout_post3}/$mycalout_post3/sm;
    $mycalout_post =~ s/{yabb mycalout_chars}/$mycalout_chars/sm;
    $mycalout_post =~ s/{yabb mycalout_validation}/$verification_field/sm;
    $mycalout_post =~ s/{yabb guestpost_fields}/$guestpost_fields/sm;
    $mycalout_post =~ s/{yabb mycalout_spamquestion}/$mycalout_spamquestion/sm;
    $mycalout_post =~ s/{yabb nscheck}/$nscheck/sm;
    $mycalout_post =~ s/{yabb mycalout_send}/$mycalout_send/sm;
    $mycalout_post =~ s/{yabb messageblock}/$messageblock/sm;
    $mycalout_post =~ s/{yabb my_postsection_ajx}/$my_postsection_ajx/sm;

    # YaBBC Section end

    # Event data begin

    if ( $INFO{'eventdate'} ) { $bd_year = substr $INFO{'eventdate'}, 0, 4; }
    else                      { $bd_year = $year; }

    my @caldata;
    ## Get Birthdays ##
    if ( ( $Show_EventBirthdays == 1 && !$iamguest )
        || $Show_EventBirthdays == 2 )
    {
        fopen( EVENTBIRTH, "$vardir/eventcalbday.db" );
        my @birthmembers = <EVENTBIRTH>;
        fclose(EVENTBIRTH);

        foreach my $x (@birthmembers) {
            chomp $x;
            (
                $user_bdyear, $user_bdmon,  $user_bdday,
                $user_bdname, $user_bdhide, $ns
            ) = split /\|/xsm, $x;

            if (
                (
                       ( $user_bdmon < $view_mon )
                    || ( $user_bdmon == $view_mon ) && ( $user_bdday < $mday )
                )
                && ( !$INFO{'showmini'} )
                && ( !$INFO{'showthisdate'} )
              )
            {
                $bd_y      = $year;
                $bday_date = "$bd_y$user_bdmon$user_bdday";
                $age       = $bd_y - $user_bdyear;
            }
            else {
                $bd_y      = $bd_year;
                $bday_date = "$bd_y$user_bdmon$user_bdday";
                $age       = $bd_y - $user_bdyear;
            }

            %{ bday . $bd_year . $user_bdmon . $user_bdday } = (
                'caleventdate' => "$bd_year$user_bdmon$user_bdday",
                'calyear'      => "$bd_year",
                'calmon'       => "$user_bdmon",
                'calday'       => "$user_bdday",
                'caltype'      => '0',
                'calname'      => "$user_bdname",
                'caltime'      => "$user_bdname",
                'calhide'      => "$user_bdhide",
                'calicon'      => 'birthday',
                'calevent'     => "$string",
                'calnoname'    => '0',
                'ns'           => "$ns",
            );

            push @caldata,
qq~$bday_date|0|$user_bdname|$user_bdname|$user_bdhide|<span class="small">$age</span>|birthday|0|$ns~;
        }
    }

    ## Get Events ##
    fopen( EVENTFILE, "$vardir/eventcal.db" );
    my @calinput = <EVENTFILE>;
    fclose(EVENTFILE);
    foreach my $eventline ( sort @calinput ) {
        chomp $eventline;
        my (
            $cal_date,  $cal_type,  $cal_name, $cal_time,
            $cal_hide,  $cal_event, $cal_icon, $cal_noname,
            $cal_type2, $ns,        $g
        ) = split /\|/xsm, $eventline;

        if ( $cal_date =~ /(\d{4})(\d{2})(\d{2})/xsm ) {
            ( $c_year, $c_mon, $c_day ) = ( $1, $2, $3 );
        }

        if ( $cal_type == 2 ) {
            next if $cal_name ne $username;
            %{ private . $c_year . $c_mon . $c_day . $username . '2' } =
              ( 'private' => 2, );
        }
        elsif ( $cal_type == 1 && $iamguest ) { next; }

        if ( $cal_icon eq q{} ) { $cal_icon = 'eventinfo'; }

        if ( $cal_type2 == 2 ) {
            $c_mon  = $st_mon;
            $c_year = $bd_year;
            if (   ( $c_mon < $view_mon )
                || ( $c_mon == $view_mon )
                && ( $c_day < $mday )
                && ( !$INFO{'calmon'} ) )
            {
                $cd_year = $bd_year + 1;
            }
            else {
                $cd_year = $bd_year;
            }
            $cal_date = "$cd_year$st_mon$c_day";

        }
        elsif ( $cal_type2 == 3 ) {
            $c_year = $bd_year;
            if (   ( $c_mon < $view_mon )
                || ( $c_mon == $view_mon )
                && ( $c_day < $mday )
                && ( !$INFO{'calmon'} ) )
            {
                $cd_year = $bd_year + 1;
            }
            else {
                $cd_year = $bd_year;
            }
            $cal_date = "$cd_year$c_mon$c_day";
        }

        if   ( $CalEventNoName == 2 ) { $cal_noname = 1; }
        else                          { $cal_noname = $cal_noname; }

        %{ event . $c_year . $c_mon . $c_day } = (
            'caleventdate' => $cal_date,
            'calyear'      => $c_year,
            'calmon'       => $c_mon,
            'calday'       => $c_day,
            'caltype'      => $cal_type,
            'calname'      => $cal_name,
            'caltime'      => $cal_time,
            'calhide'      => $cal_hide,
            'calicon'      => $cal_icon,
            'calevent'     => $cal_event,
            'calnoname'    => $cal_noname,
            'caltype2'     => $cal_type2,
            'ns'           => $ns,
            'g'            => $g,
        );

        push @caldata,
qq~$cal_date|$cal_type|$cal_name|$cal_time|$cal_hide|$cal_event|$cal_icon|$cal_noname|$cal_type2|$ns|$g~;

    }

    # Event data end

    # Show/Edit Events begin

    if ( $INFO{'showthisdate'} || $INFO{'showmini'} || $INFO{'edit_cal_even'} )
    {
        $event_id =
          ( $INFO{'showthisdate'} == 2 && $do_scramble_id )
          ? decloak( $INFO{'calid'} )
          : $INFO{'calid'};
        $event_date = $INFO{'eventdate'};
        $d_year     = substr $event_date, 0, 4;
        $d_mon      = substr $event_date, 4, 2;
        $d_day      = substr $event_date, 6, 2;

        $mybtime   = stringtotime(qq~$d_mon/$d_day/$d_year~);
        $mybtimein = timeformatcal($mybtime, $Show_caltoday);
        $cdate     = dtonly($mybtimein);

        if ( $INFO{'showmini'} ) {
            $mycalout_top = $mycalout_gottobox;

            foreach my $cal_events ( sort @caldata ) {
                my (
                    $cdat, $ctyp,   $cnam,  $ctim, $chide, $ceve,
                    $cico, $cnonam, $ctyp2, $ns,   $g
                ) = split /\|/xsm, $cal_events;
                if ( !$Show_ColorLinks ) {
                    $memrealname = ( split /\|/xsm, $memberinf{$cnam}, 2 )[0];
                }
                if ( $cdat =~ /(\d{4})(\d{2})(\d{2})/xsm ) {
                    ( $dd_year, $dd_mon, $dd_day ) = ( $1, $2, $3 );
                }
                if   ( $ctyp2 == 2 ) { $cdat = "$bd_year$d_mon$dd_day"; }
                else                 { $cdat = "$cdat"; }
                if   ( $ctyp2 == 3 ) { $cdat = "$bd_year$dd_mon$dd_day"; }
                else                 { $cdat = "$cdat"; }
                $delete_event = q{};
                $edit_event   = q{};
                $icon_text    = $var_cal{$cico};
                $cal_icon     = $cal_icon{$cico};
#                if ( !$var_cal{$cico} ) { $icon_text = calicontext($cico); }

                if ( $ns eq 'NS' ) {
                    $message = q~[noparse]~ . $ceve . q~[/noparse]~;
                }
                else {
                    $message = $ceve;
                }
                enable_yabbc();
                DoUBBC();
                $event_message = $message;

                if ( $event_date == $cdat && !$INFO{'edit_cal_even'} ) {
                    $eventfound = 1;
                    if ( $g eq 'g' || lc $cnam eq 'guest') {
                        $eventuserlink = qq~$cnam ($var_cal{'guest'})~;
                    }
                    elsif ( $g ne 'g' && !-e "$memberdir/$cnam.vars" ) {
                        $eventuserlink = qq~$cnam ($var_cal{'exmem'})~;
                    }
                    elsif ($Show_ColorLinks) {
                        LoadUser($cnam);
                        $eventuserlink = qq~$link{$cnam}~;
                    }
                    else {
                        LoadUser($cnam);
                        if ( $iamguest ) {
                            $eventuserlink = qq~$format_unbold{$cnam}~;
                        }
                        else {
                            $eventuserlink =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$cnam}" rel="nofollow">$format_unbold{$cnam}</a>~;
                        }
                    }
                    $eventbduserlink = $eventuserlink;
                    if (   $CalEventNoName == 1
                        && $cnonam == 1
                        && ( $iamadmin || $iamgmod ) )
                    {
                        $cnonam = 0;
                    }
                    else { $cnonam = $cnonam; }
                    if ( $cnonam == 1 ) { $eventuserlink = q{}; }
                    else {
                        $eventuserlink =
                          "<br /><b>$var_cal{'by'}</b> $eventuserlink";
                    }

                    if ( $cico eq 'birthday' ) {
                        if ( $showage && $chide == 1 ) {
                            $greet = $var_cal{'bdayhide'};
                            $cdate = bdayno_year($mybtimein);
                        }
                        else {
                            $greet =
                              qq~$var_cal{'calis'} $ceve $var_cal{'calold'}~;
                        }
                        $myevent_ann = q{};
                        $mycalout_greet .= $mycal_greet;
                        $mycalout_greet =~ s/{yabb cdate}/$cdate/sm;
                        $mycalout_greet =~
                          s/{yabb eventbduserlink}/$eventbduserlink/sm;
                        $mycalout_greet =~ s/{yabb greet}/$greet/sm;
                        $mycalout_greet =~ s/{yabb myevent_ann}/$myevent_ann/sm;
                        $mycalout_greet =~
                          s/{yabb my_cal_icon}/$cal_icon{'eventbd'}/sm;
                    }
                    else {
                        $mycalout_greet .= $mycal_greet_b;
                        $myevent_ann =
                          qq~<b>$var_cal{'calsubtitle'}:</b><br /><br />~;

                        if ( $ctyp == 2 ) {
                            $mycalout_greet .=
qq~$cal_icon{'eventprivate'} $cal_icon{$cico} $cdate <b>$icon_text</b> $eventuserlink~;
                        }
                        else {
                            $mycalout_greet .=
qq~$cal_icon{$cico} $cdate <b>$icon_text</b> $eventuserlink~;
                        }

                        $mycalout_greet .= $mycal_greet_c;
                        $mycalout_greet =~
                          s/{yabb event_message}/$event_message/sm;

                        if (
                            !$iamguest
                            && (   $username eq $cnam
                                || $iamadmin
                                || $iamgmod )
                          )
                        {
                            $mycalout_greet .= $mycal_greet_b;
                            $mycalout_greet .= qq~
                        <a href="$scripturl?action=eventcal;calshow=1;eventdate=$cdat;calid=$ctim;edit_cal_even=1;addnew=1;edit_typ=$ctyp;edit_icon=$cico;edit_nonam=$cnonam;edit_typ1=$ctyp2" title='$var_cal{'caledit'}'>
                        $cal_icon{'modify'} $var_cal{'caledit'}</a>&nbsp;&nbsp;&nbsp;
                        <a href="javascript:if(confirm('$var_cal{'caldelalert'}')){ location.href='$scripturl?action=del_cal;caldel=1;calid=$ctim'; }" title='$var_cal{'caldel'}'>
                        $cal_icon{'delete'} $var_cal{'caldel'}</a>~;
                            $mycalout_greet .= $mycal_greet_rowend;
                        }
                    }
                }
            }

            if (   !exists( ${ event . $d_year . $d_mon . $d_day }{'calday'} )
                && !$eventfound
                && !exists( ${ bday . $d_year . $d_mon . $d_day }{'calday'} ) )
            {
                $mycalout_no = $mycalout_noevent;
            }
            if ( $Allow_Event_Imput && !$INFO{'addnew'} == 1 ) {
                $ShowEventAddLink2 =
qq~<span class="small"> $cal_icon{'eventmoreadd'} <a href="$scripturl?action=eventcal;calshow=1;addnew=1">$var_calpost{'getaddevent'}</a></span><br />~;
            }
            if ( $Show_BirthdaysList && (!$iamguest || $Show_BirthdaysList != 1) ) {
                $ShowBirthdaysLink2 =
qq~<span class="small"> $cal_icon{'eventmorebd'} <a href="$scripturl?action=birthdaylist">$var_cal{'calbdaylist'}</a></span>~;
            }
            if ( $ShowEventAddLink2 || $ShowBirthdaysLink2 ) {
                $event_link = $myevent_link;
                $event_link =~ s/{yabb ShowBirthdaysLink2}/$ShowBirthdaysLink2/sm;
                $event_link =~ s/{yabb ShowEventAddLink2}/$ShowEventAddLink2/sm;
            }
            $yymain .= $mycalout_showevent;
            $yymain =~ s/{yabb mycalout_top}/$mycalout_top/sm;
            $yymain =~ s/{yabb calgotobox}/$calgotobox/sm;
            $yymain =~ s/{yabb mycalout_greet}/$mycalout_greet/sm;
            $yymain =~ s/{yabb mycalout_no}/$mycalout_no/sm;
            $yymain =~ s/{yabb myevent_ann}/$myevent_ann/sm;
            $yymain =~ s/{yabb nscheck}/$nscheck/sm;
            $yymain =~ s/{yabb ShowEventAddLink2}/$event_link/sm;

            $yytitle = $var_cal{'yytitle'};
            template();
            exit;
        }

        ## Show Edit Events ##

        if ( $INFO{'edit_cal_even'} || $INFO{'showthisdate'} ) {
            $mycalout_top = $mycalout_gottobox;

            foreach my $cal_events ( sort @caldata ) {
                my (
                    $cdat, $ctyp,   $cnam,  $ctim, $chide, $ceve,
                    $cico, $cnonam, $ctyp2, $ns,   $g
                ) = split /\|/xsm, $cal_events;
                if ( !$Show_ColorLinks ) {
                    $memrealname = ( split /\|/xsm, $memberinf{$cnam}, 2 )[0];
                }
                if ( $cico eq q{} ) { $cico = 'eventinfo'; }
                if ( $cdat =~ /(\d{4})(\d{2})(\d{2})/xsm ) {
                    ( $dd_year, $dd_mon, $dd_day ) = ( $1, $2, $3 );
                }
                if   ( $ctyp2 == 2 ) { $cdat = "$d_year$d_mon$dd_day"; }
                else                 { $cdat = "$cdat"; }
                if   ( $ctyp2 == 3 ) { $cdat = "$d_year$dd_mon$dd_day"; }
                else                 { $cdat = "$cdat"; }
                $delete_event = q{};
                $edit_event   = q{};
                $icon_text    = $var_cal{$cico};
#                if ( !$var_cal{$cico} ) { $icon_text = calicontext($cico); }

                if ( $ns eq 'NS' ) {
                    $message = q~[noparse]~ . $ceve . q~[/noparse]~;
                }
                else { $message = $ceve; }
                enable_yabbc();
                DoUBBC();
                $event_message = $message;

                if ( $event_id eq $ctim && $cdat == $event_date ) {
                    $eventfound = 1;
                    if ( $g eq 'g'|| lc $cnam eq 'guest' ) {
                        $eventuserlink = qq~$cnam ($var_cal{'guest'})~;
                    }
                    elsif ( $g ne 'g' && !-e "$memberdir/$cnam.vars" ) {
                        $eventuserlink = qq~$cnam ($var_cal{'exmem'})~;
                    }
                    elsif ($Show_ColorLinks) {
                        LoadUser($cnam);
                        $eventuserlink = $link{$cnam};
                    }
                    else {
                        LoadUser($cnam);
                        if ( $iamguest ) {
                            $eventuserlink = qq~$format_unbold{$cnam}~;
                        }
                        else {
                            $eventuserlink =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$cnam}" rel="nofollow">$format_unbold{$cnam}</a>~;
                        }
                    }
                    $eventbduserlink = $eventuserlink;
                    if (   $CalEventNoName == 1
                        && $cnonam == 1
                        && ( $iamadmin || $iamgmod ) )
                    {
                        $cnonam = 0;
                    }
                    else { $cnonam = $cnonam; }
                    if ( $cnonam == 1 ) { $eventuserlink = q{}; }
                    else {
                        $eventuserlink =
                          "<br /><b>$var_cal{'by'}</b>  $eventuserlink";
                    }

                    if ( $cico eq 'birthday' && $cdat == $event_date ) {
                        if ( $showage && $chide == 1 ) {
                            $greet = $var_cal{'bdayhide'};
                        }
                        else {
                            $greet =
                              qq~$var_cal{'calis'} $ceve $var_cal{'calold'}~;
                        }
                        $mycalout_greet .= $mycal_greet;
                        $mycalout_greet =~ s/{yabb cdate}/$cdate/sm;
                        $mycalout_greet =~
                          s/{yabb eventbduserlink}/$eventbduserlink/sm;
                        $mycalout_greet =~ s/{yabb greet}/$greet/sm;
                    }
                    else {
                        $mycalout_greet .= $mycal_greet_b;
                        if ( $ctyp == 2 ) {
                            $mycalout_greet .=
qq~$cal_icon{'eventprivate'} $cal_icon{$cico} $cdate <b>$icon_text</b> $eventuserlink~;
                        }
                        else {
                            $mycalout_greet .=
qq~$cal_icon{$cico} $cdate <b>$icon_text</b> $eventuserlink~;
                        }
                        $mycalout_greet .= $mycal_greet_c;
                        $mycalout_greet =~
                          s/{yabb event_message}/$event_message/sm;

                        if (
                            !$iamguest
                            && (   $username eq $cnam
                                || $iamadmin
                                || $iamgmod )
                            && !$INFO{'edit_cal_even'}
                          )
                        {
                            $mycalout_greet .= $mycal_greet_b . qq~
            <a href="$scripturl?action=eventcal;calshow=1;eventdate=$cdat;calid=$ctim;edit_cal_even=1;addnew=1;edit_typ=$ctyp;edit_icon=$cico;edit_nonam=$cnonam;edit_typ1=$ctyp2" title='$var_cal{'caledit'}'>$cal_icon{'modify'} $var_cal{'caledit'}</a>&nbsp;&nbsp;&nbsp;<a href="javascript:if(confirm('$var_cal{'caldelalert'}')){ location.href='$scripturl?action=del_cal;caldel=1;calid=$ctim'; }" title="$var_cal{'caldel'}">$cal_icon{'delete'} $var_cal{'caldel'}</a>~
                              . $mycal_greet_rowend;
                        }
                    }

                    if ( $INFO{'edit_cal_even'}
                        && ( $username eq $cnam || $iamadmin || $iamgmod ) )
                    {
                        $editmessage = $ceve;
                        $editmessage =~ s/<\//\&lt\;\//isgxm;
                        $editmessage =~ s/<br \/>/\n/gsm;
                        $editmessage =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/igsm;
                        ToChars($editmessage);

                        if ( $ns eq 'NS' ) { $nsc = q~checked="checked"~; }
                        $mycalout_greet .= $mycalout_edit_box;
                        $mycalout_greet =~ s/{yabb event_id}/$event_id/sm;
                        $mycalout_greet =~
                          s/{yabb mycalout_post}/$mycalout_post/sm;
                        $mycalout_greet =~ s/{yabb calevent}/$editmessage/sm;
                        $mycalout_greet =~ s/{yabb nscheck}/$nsc/sm;
                        $mycalout_greet =~
                          s/{yabb modify}/$cal_icon{'modify'}/sm;
                    }
                }
            }
            $yymain .= $mycalout_edit;
            $yymain =~ s/{yabb mycalout_top}/$mycalout_top/sm;
            $yymain =~ s/{yabb calgotobox}/$calgotobox/sm;
            $yymain =~ s/{yabb mycalout_greet}/$mycalout_greet/sm;

            $yytitle = $var_cal{'yytitle'};
            template();
            exit;
        }
    }

    # Show/Edit Events end

    # Print Events begin

    $countdownload = $CD_onoff || 0;    # Fix for Countdown Mod by XTC

    $outstring = q~ ~;
    if ( $Scroll_Events == 1 ) {
        $outstring .=
q~<marquee behavior='scroll' direction='up' height='130' scrollamount='1' scrolldelay='1' onmouseover='this.stop()' onmouseout='this.start()' id="scroller">~;
    }
    elsif ( $Scroll_Events == 2 ) {
        $outstring .= '<div style="overflow:auto;height:150px;">';
    }
    elsif ( $Scroll_Events == 3 ) {
        $yyinlinestyle .=
qq~\n<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/calscroller.css" type="text/css" />~;
        $outstring .= qq~
<script type="text/javascript">
    // initial position
    var countdownmod=$countdownload;

    window.onload = function() {
        initDOMnews();
        if(countdownmod==1) countdown();
    };

    // initial position
    var startpos=120;
    // end position
    var endpos=-130;
    // scrolling speed
    var speed=10;
    // pause before scrolling again
    var pause=2000;
    // scroller box id
    var newsID='eventcaldata';
    // class to add when js is available
    var classAdd='hasJS';
    var counter=0;
    var total=1;

    var scrollpos=startpos;
    // Initialize scroller
    function initDOMnews() {
        var n=document.getElementById(newsID);
        if(!n){return;}
        n.className=classAdd;
        interval=setInterval('scrollDOMnews()',speed);
    }

    function scrollDOMnews() {
        var n=document.getElementById(newsID).getElementsByTagName('div');

        n[counter].style.top=scrollpos+'px';
        // stop scrolling when it reaches the top
        if (scrollpos===0) {
            clearInterval(interval);
            setTimeout("interval=setInterval('scrollDOMnews()',speed);", pause);
        }
        if (scrollpos==endpos) {
            counter++;
            if (!n[counter]) {
                counter=0;
            }
            (n[counter]) ? counter : counter=0;
            scrollpos=startpos;
        }
        scrollpos = scrollpos - 1;
    }
</script>
    <div id="eventcaldata">~;
    }
    if ( $Scroll_Events != 3 ) {
        $outstring .= $my_outstring;
    }

    my ( $caleventbegin, $caleventend );
    if ($ssicaldisplay) { $DisplayEvents = $ssicaldisplay; }
    $DisplayEvents ||= 0;
    if ( $DisplayEvents > 0 ) {
        ( undef, undef, undef, $d_cal, $m_cal, $y_cal, undef, undef, undef ) =
          gmtime( $daterechnug + ( 86400 * $DisplayEvents ) );
        $m_cal++;
        $y_cal += 1900;
        $caleventbegin = "$year" . sprintf( '%02d', $mon ) . sprintf '%02d', $mday;
        $caleventend =
          "$y_cal" . sprintf( '%02d', $m_cal ) . sprintf '%02d',
          $d_cal;
    }
    foreach my $cal_events ( sort @caldata ) {
        my (
            $cdate, $ctype,   $cname,  $ctime, $chide, $cevent,
            $cicon, $cnoname, $ctype2, $ns,    $g
        ) = split /\|/xsm, $cal_events;
        if ( !$Show_ColorLinks ) {
            $memrealname = ( split /\|/xsm, $memberinf{$cname}, 2 )[0];
        }
        if ( $cdate =~ /(\d{4})(\d{2})(\d{2})/xsm ) {
            ( $cyear, $cmon, $cday ) = ( $1, $2, $3 );
        }
        if ( $DisplayEvents > 0 && !$INFO{'calyear'} ) {
            if ( $cdate >= $caleventbegin && $cdate <= $caleventend ) {
                $event_found = 1;
            }
            else { $event_found = 0; }
            if ( $DisplayEvents == 1 ) {
                $event_index =
                  qq~$var_cal{'caltoday'} $var_cal{'calsubtitle'}:~;
            }
            else {
                $event_index =
qq~$var_cal{'calcoming'} $var_cal{'calsubtitle'} ($DisplayEvents $var_cal{'caldays'}):~;
            }
        }
        else {
            if ( $view_mon == $cmon && $year == $cyear ) {
                $event_found = 1;
            }
            else { $event_found = 0; }
            if ( $INFO{'calyear'} || $DisplayEvents == 0 ) {
                $event_index =
                  qq~$var_cal{$st} $year - $var_cal{'calsubtitle'}:~;
            }
        }

        if ( $cicon eq q{} ) { $cico = 'eventinfo'; }
        $CalShortEvent ||= 0;
        if ( $CalShortEvent > 0 && length($cevent) > $CalShortEvent ) {
            if ( $ctime ne 'birthday' ) {
                if ( $enable_ubbc && $No_ShortUbbc == 1 ) {
                    $cevent =~ s/\[url(.*?)\](.*?)\[\/url\]/$2/isgxm;
                    $cevent =~ s/\[ftp(.*?)\](.*?)\[\/ftp\]/$2/isgxm;
                    $cevent =~ s/\[email(.*?)\](.*?)\[\/email\]/$2/isgxm;
                    $cevent =~ s/\[link(.*?)\](.*?)\[\/link\]/$2/isgxm;
                    $cevent =~ s/\[img\](.*?)\[\/img\]//isgxm;
                    $cevent =~ s/\[flash\](.*?)\[\/flash\]//igsxm;
                    $cevent =~ s/\[b\](.*?)\[\/b\]/*$1*/isgxm;
                    $cevent =~ s/\[i\](.*?)\[\/i\]/\/$1\//isgxm;
                    $cevent =~ s/\[u\](.*?)\[\/u\]/_$1_/isgsm;
                    $cevent =~ s/\[.*?\]//gsxm;
                    $cevent =~ s/https?:\/\///igxsm;
                }
                $convertstr = $cevent;
                $convertcut = $CalShortEvent;
                CountChars();
                $cevent = $convertstr;
                if ($cliped) { $cevent .= ' ...'; }
                $cevent .=
qq~<br /><br /><a href="$scripturl?action=eventcal;calshow=1;eventdate=$cyear$cmon$cday;calid=$ctime;showthisdate=1" title="$var_cal{'calshowevent'}"><span style="color:#FF6600">$var_cal{'calmore'}</span> $cal_icon{'eventmore'}</a>~;

# There MUST be two spaces after "<a" and "<img" here or you will get this message here after going through &DoUBBC: "Multimedia File Viewing and Clickable Links are available for Registered Members only!! You need to Login or Register"
            }
        }
        if ( $enable_ubbc && $ns ne 'NS' ) {
            $message = $cevent;
            enable_yabbc();
            DoUBBC();
            $cevent = $message;
        }

        if ( $event_found == 1 ) {
            $mybtime   = stringtotime(qq~$cmon/$cday/$cyear~);
            $mybtimein = timeformatcal($mybtime, $Show_caltoday);
            $cdate     = dtonly($mybtimein);

            if ( $showage && $chide ) {
                $cdate = bdayno_year($mybtimein);
            }
            $cdate =
qq~<a href="$scripturl?action=eventcal;calshow=1;eventdate=$cyear$cmon$cday;calid=~
              . ( $do_scramble_id ? cloak($ctime) : $ctime )
              . qq~;showthisdate=2" title="$var_cal{'calshowevent'}">$cdate</a>~;
            $cal_time  = stringtotime($ctime);
            $icon_text = "$var_cal{$cicon}";
            if ( $g eq 'g' || lc $cname eq 'guest' ) {
                $eventuserlink = qq~$cname ($var_cal{'guest'})~;
            }
            elsif ( $g ne 'g' && !-e "$memberdir/$cname.vars" ) {
                $eventuserlink = qq~$cname ($var_cal{'exmem'})~;
            }
            elsif ($Show_ColorLinks) {
                LoadUser($cname);
                $eventuserlink = $link{$cname};
            }
            else {
                LoadUser($cname);
                if ( $iamguest ) {
                    $eventuserlink = qq~$format_unbold{$cnam}~;
                }
                else {
                    $eventuserlink =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$cname}" rel="nofollow">$format_unbold{$cname}</a>~;
                }
            }
            $eventbduserlink = $eventuserlink;
            if (   $CalEventNoName == 1
                && $cnoname == 1
                && ( $iamadmin || $iamgmod ) )
            {
                $cnoname = 0;
            }
            else { $cnoname = $cnoname; }
            if ( $cnoname == 1 ) { $eventuserlink = q{}; }
            else {
                $eventuserlink =
qq~<br /><b>$var_cal{'by'}</b> $eventuserlink<hr class="hr" />~;
            }
            if ( $Scroll_Events == 3 ) {
                if ( $cicon eq 'birthday' ) {
                    if ( $showage && $chide ) {
                        $greet = $var_cal{'bdayhide'};
                    }
                    else {
                        $greet =
                          qq~$var_cal{'calis'} $cevent $var_cal{'calold'}~;
                    }
                    $outstring .=
qq~<div class="small">$cal_icon{'eventbd'} $cdate <b>$var_cal{'calbirthday'}</b><br /> $eventbduserlink $greet<hr class="hr2" /></div>~;
                }
                elsif ( $ctype == 2 ) {
                    $outstring .=
qq~<div class="small">$cal_icon{'eventprivate'} $cal_icon{$cicon} $cdate <b>$icon_text</b> $eventuserlink$cevent<hr class="hr2" /></div>~;
                }
                else {
                    $outstring .=
qq~<div class="small">$cal_icon{$cicon} $cdate <b>$icon_text</b> $eventuserlink$cevent<hr class="hr2" /></div>~;
                }
            }
            else {
                if ( $cicon eq 'birthday' ) {
                    if ( $showage && $chide == 1 ) {
                        $greet = $var_cal{'bdayhide'};
                    }
                    else {
                        $greet =
                          qq~$var_cal{'calis'} $cevent $var_cal{'calold'}~;
                    }
                    $outstring .= $mycal_outstring_bday;
                    $outstring =~ s/{yabb cdate}/$cdate/sm;
                    $outstring =~ s/{yabb eventbduserlink}/$eventbduserlink/sm;
                    $outstring =~ s/{yabb greet}/$greet/sm;
                    $outstring =~ s/{yabb my_cal_icon}/$cal_icon{'eventbd'}/sm;
                }
                elsif ( $ctype == 2 ) {
                    $outstring .= $mycal_outstring_private;
                    $outstring =~ s/{yabb cicon}/$cal_icon{$cicon}/sm;
                    $outstring =~ s/{yabb cdate}/$cdate/sm;
                    $outstring =~ s/{yabb icon_text}/$icon_text/gsm;
                    $outstring =~ s/{yabb eventuserlink}/$eventuserlink/sm;
                    $outstring =~ s/{yabb cevent}/$cevent/sm;
                    $outstring =~
                      s/{yabb my_cal_icon}/$cal_icon{'eventprivate'}/sm;
                    $outstring =~ s/{yabb my_cal_icon_ev}/$cal_icon{$cicon}/sm;

                }
                else {
                    $outstring .= $mycal_outstring;
                    $outstring =~ s/{yabb cicon}/$cal_icon{$cicon}/sm;
                    $outstring =~ s/{yabb cdate}/$cdate/sm;
                    $outstring =~ s/{yabb icon_text}/$icon_text/gsm;
                    $outstring =~ s/{yabb eventuserlink}/$eventuserlink/sm;
                    $outstring =~ s/{yabb cevent}/$cevent/sm;
                    $outstring =~ s/{yabb my_cal_icon_ev}/$cal_icon{$cicon}/sm;
                }
            }
        }
    }
    if ( $Scroll_Events != 3 ) { $outstring .= '</table>'; }
    if ( $Scroll_Events == 1 ) { $outstring .= '</marquee>'; }
    if ( $Scroll_Events == 2 || $Scroll_Events == 3 ) {
        $outstring .= '</div><br />';
    }

    # Print Events end

    # Print Mini EventCal begin

    if ($Show_BirthdaysList && ( !$iamguest || $Show_BirthdaysList != 1 ) ) {
        $ShowBirthdaysLink =
qq~<span class="small"> $cal_icon{'eventmorebd'} <a href="$scripturl?action=birthdaylist">$var_cal{'calbdaylist'}</a></span>~;
    }
    if ( $Allow_Event_Imput && !$INFO{'addnew'} == 1 ) {
        $ShowEventAddLink =
qq~<br /><span class="small"> $cal_icon{'eventmoreadd'} <a href="$scripturl?action=eventcal;calshow=1;addnew=1">$var_calpost{'getaddevent'}</a></span>~;
    }

    $mon_name = $var_cal{$st};

    if ( $mon == 2 ) {
        if ( $year % 4 == 0 ) { $days = 29; }
    }
    for my $i ( 1 .. 7 ) {
        $st = "calday_$i";
        $dstr[ $i - 1 ] = $mycal_showday_dstr;
        $dstr[ $i - 1 ] =~ s/{yabb cal_day}/$cal_day/sm;
        $dstr[ $i - 1 ] =~ s/{yabb var_cal_st}/$var_cal{$st}/sm;
    }
    $dcnt  = 0;
    $e_day = $wday1;
    if ( $wday1 > 1 ) {
        for my $i ( 1 .. ( $wday1 - 1 ) ) {
            $cal_out_d .= $mycal_showday_blnk;
        }
    }
    if ( !$Event_TodayColor ) { $Event_TodayColor = '#FF0000'; }

    for my $i ( 1 .. $days ) {
        $dddd = $i;
        if ( $dddd < 10 ) { $dddd = "0$dddd"; }

        $sel = qq~<span class="small">$i</span>~;
        if (   $i == $callnewday
            && $mon == $callnewmonth
            && $year == $callnewyear )
        {
            $sel =
qq~<span class="small" style="color:$Event_TodayColor"><b>$i</b></span>~;
        }

        $cal_pic = q{};
        if (  !exists( ${ event . $year . $view_mon . $dddd }{'calday'} )
            && exists( ${ bday . $year . $view_mon . $dddd }{'calday'} ) )
        {
            $cal_pic = "$cal_icon_bg{'eventbd'}";
        }
        if ( exists( ${ event . $year . $view_mon . $dddd }{'calday'} )
            && !exists( ${ bday . $year . $view_mon . $dddd }{'calday'} ) )
        {
            $cal_pic = "$cal_icon_bg{'eventinfo'}";
        }
        if (   exists( ${ event . $year . $view_mon . $dddd }{'calday'} )
            && exists( ${ bday . $year . $view_mon . $dddd }{'calday'} ) )
        {
            $cal_pic = "$cal_icon_bg{'eventinfobd'}";
        }
        if (
            exists(
                ${ private . $year . $view_mon . $dddd . $username . '2' }
                  {'private'}
            )
          )
        {
            $cal_pic = "$cal_icon_bg{'eventprivate'}";
        }
        if ($Show_MiniCalIcons) { $cal_pic = q{}; }

        if (   exists( ${ bday . $year . $view_mon . $dddd }{'calday'} )
            || exists( ${ event . $year . $view_mon . $dddd }{'calday'} ) )
        {
            $cal_out_dy .= $mycal_showday;
            $cal_out_dy =~ s/{yabb cal_days}/$cal_days/sm;
            $cal_out_dy =~ s/{yabb cal_pic}/$cal_pic/sm;
            $cal_out_dy =~ s/{yabb year}/$year/sm;
            $cal_out_dy =~ s/{yabb view_mon}/$view_mon/sm;
            $cal_out_dy =~ s/{yabb dddd}/$dddd/sm;
            $cal_out_dy =~ s/{yabb sel}/$sel/sm;
        }
        else {
            $cal_out_dy .= $mycal_showday_b;
            $cal_out_dy =~ s/{yabb cal_days}/$cal_days/sm;
            $cal_out_dy =~ s/{yabb sel}/$sel/sm;
        }

        $e_day++;
        $wday1++;
        if ( $wday1 > 7 && $i != $days ) {
            $wday1 = 1;
            $cal_out_dy .= $mycal_trtr;
        }
    }

    $endrow = 42;
    if ( $e_day < 36 ) { $endrow = 35; }
    $endday = $endrow - $e_day + 2;
    if ( $endday < 8 ) {
        if ( !$cal_out && $endday > 1 ) { $cal_out = $mycal_tr; }
        for my $i ( 1 .. ( $endday - 1 ) ) {
            $cal_out_blnk .= $mycal_showday_blnk;
        }
    }
    $cal_out = $mycal_dy_top;
    $cal_out =~ s/{yabb cal_out_d}/$cal_out_d/sm;
    $cal_out =~ s/{yabb cal_out_dy}/$cal_out_dy/sm;
    $cal_out =~ s/{yabb cal_out_blnk}/$cal_out_blnk/sm;

    if ($ShowSunday) {
        $weekdays =
          qq~$dstr[6]$dstr[0]$dstr[1]$dstr[2]$dstr[3]$dstr[4]$dstr[5]~;
    }
    else {
        $weekdays =
          qq~$dstr[0]$dstr[1]$dstr[2]$dstr[3]$dstr[4]$dstr[5]$dstr[6]~;
    }

    # Print Mini EventCal end

    # EventCal Output begin

    $cal_displayssi .= $mycal_displayssi;
    $cal_displayssi =~ s/{yabb last_link}/$last_link/sm;
    $cal_displayssi =~ s/{yabb mon_name}/$mon_name/sm;
    $cal_displayssi =~ s/{yabb year}/$year/sm;
    $cal_displayssi =~ s/{yabb next_link}/$next_link/sm;
    $cal_displayssi =~ s/{yabb next_link}/$next_link/sm;
    $cal_displayssi =~ s/{yabb weekdays}/$weekdays/sm;
    $cal_displayssi =~ s/{yabb cal_out}/$cal_out/sm;

    my $cal_display_show;
    $cal_display_show = $mycalout_goto_main;

    if ( $outstring !~ /$yyhtml_root\//xsm ) {
        $outstring = $my_out_a;
        $outstring =~ s/{yabb cal_eventinfo}/$cal_icon{'eventinfo'}/sm;
    }

    if ( $DisplayCalEvents || $INFO{'calshow'} ) {
        $cal_display_calevent = qq~
                <b>$event_index</b><br />
                $outstring~;
    }

    if ($Allow_Event_Imput) {

        #        $cal_allow = $mycal_td_tr;
        $cal_allow = q~~;

        if ( $INFO{'addnew'} == 1 ) {
            $cal_allow .= $mycal_addnew_left;
            $cal_allow =~ s/{yabb mycalout_post}/$mycalout_post/sm;
            $cal_allow =~ s/{yabb cal_modify}/$cal_icon{'modify'}/sm;
        }
    }
    $cal_display = $mycal_show_ssi;
    $cal_display =~ s/{yabb cal_display_show}/$cal_display_show/sm;
    $cal_display =~ s/{yabb calgotobox}/$calgotobox/sm;
    $cal_display =~ s/{yabb cal_displayssi}/$cal_displayssi/sm;
    $cal_display =~ s/{yabb ShowBirthdaysLink}/$ShowBirthdaysLink/sm;
    $cal_display =~ s/{yabb ShowEventAddLink}/$ShowEventAddLink/sm;
    $cal_display =~ s/{yabb cal_display_calevent}/$cal_display_calevent/sm;
    $cal_display =~ s/{yabb cal_allow}/$cal_allow/sm;

    ## Print EventCal SSI ##
    if    ( $ssicalmode == 1 ) { return $cal_display; }
    elsif ( $ssicalmode == 2 ) { return $cal_displayssi; }
    elsif ( $ssicalmode == 3 ) { return $outstring; }

####################################################################################################################

    ## Print EventCal in new window ##
    if ( $INFO{'calshow'} == 1 ) {
        $yymain .= $mycalout_notboard;
        $yymain =~ s/{yabb cal_display}/$cal_display/gsm;

        $yytitle = $var_cal{'yytitle'};
        template();
        return;
    }

    $mycalout_board;
    $mycalout_board =~ s/{yabb cal_display}/$cal_display/sm;
    return $mycalout_board;
}

# EventCal Output end

# EventCal Subs begin

## Delete Events ##

sub del_cal {
    if ($iamguest) { fatal_error('not_allowed'); }
    if ( $INFO{'caldel'} == 1 ) {
        if ( -e "$vardir/eventcal.db" ) {
            fopen( FILE, "<$vardir/eventcal.db" );
            my @caldata = <FILE>;
            fclose(FILE);

            fopen( FILE, ">$vardir/eventcal.db" );
            print {FILE} grep { !/$INFO{'calid'}/sm } @caldata
              or croak "$croak{'print'} eventcal.db";
            fclose(FILE);
        }
    }

    del_old_events();
    $yySetLocation = qq~$scripturl?action=eventcal;calshow=1~;
    redirectexit();
    return;
}

## Add Events ##

sub add_cal {
    if ( !$Show_EventCal || ( $iamguest && $Show_EventCal != 2 ) ) {
        fatal_error('not_allowed');
    }
    if ( $iamguest && $gpvalid_en ) {
        require Sources::Decoder;
        validation_check( $FORM{'verification'} );
    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    }
    if ( !${ $uid . $username }{'email'} ) {
        $FORM{'name'} =~ s/\A\s+//xsm;
        $FORM{'name'} =~ s/\s+\Z//xsm;
        if (   $FORM{'name'} eq q{}
            || $FORM{'name'} eq q{_}
            || $FORM{'name'} eq q{ } )
        {
            Preview( $post_txt{'75'} );
        }
        if ( length( $FORM{'name'} ) > 25 ) {
            Preview( $post_txt{'568'} );
        }
        if ( $FORM{'email'} eq {} ) { Preview("$post_txt{'76'}"); }
        if ( $FORM{'email'} !~ /[\w\-\.\+]+\@[\w\-\.\+]+\.(\w{2,4}$)/xsm ) {
            Preview("$post_txt{'240'} $post_txt{'69'} $post_txt{'241'}");
        }
        if (
            ( $FORM{'email'} =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/xsm )
            || ( $FORM{'email'} !~
                /^.+@\[?(\w|[-.])+\.([a-zA-Z]{2,4}|[0-9]{1,4})\]?$/xsm )
          )
        {
            Preview("$post_txt{'500'}");
        }
    }
    email_domain_check($email);

    if ( length( $FORM{'message'} ) > 0 ) {
        $calmessage = $FORM{'message'};
        $calmessage =~ s/\|//gxsm;
        $calmessage =~ s/\cM//gxsm;
        $calmessage =~ s/\:\`\(/\:\'\(/gxsm;

        #' make my syntax checker happy;
        $calmessage =~ s/\[([^\]]{0,30})\n([^\]]{0,30})\]/\[$1$2\]/gxsm;
        $calmessage =~ s/\[\/([^\]]{0,30})\n([^\]]{0,30})\]/\[\/$1$2\]/gxsm;
        $calmessage =~
          s/(\w+:\/\/[^<>\s\n\"\]\[]+)\n([^<>\s\n\"\]\[]+)/$1\n$2/gxsm;
        FromChars($calmessage);
        ToHTML($calmessage);
        $calmessage =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
        $calmessage =~ s/\n/<br \/>/gsm;
        $calmessage =~ s/([\000-\x09\x0b\x0c\x0e-\x1f\x7f])/\x0d/gxsm;
        if ($iamguest) {
            $guestname = $FORM{'name'};
            FromChars($guestname);
            ToHTML($guestname);
        }
        fopen( EVENTFILE, "$vardir/eventcal.db" );
        my @calinput = <EVENTFILE>;
        fclose(EVENTFILE);
        if ( $FORM{'editid'} ) {
            for my $i ( 0 .. ( @calinput - 1 ) ) {
                chomp $calinput[$i];
                (
                    $c_date,  $c_type,  $c_name, $c_time,
                    $c_hide,  $c_event, $c_icon, $c_noname,
                    $c_type2, $ns,      $g
                ) = split /\|/xsm, $calinput[$i];
                if ( $c_time == $FORM{'editid'} ) {
                    $calinput[$i] =
"$FORM{'selyear'}$FORM{'selmon'}$FORM{'selday'}|$FORM{'caltype'}|$c_name|$c_time||$calmessage|$FORM{'calicon'}|$FORM{'calnoname'}|$FORM{'caltype2'}|$FORM{'ns'}|$g\n";
                }
                else {
                    $calinput[$i] =
"$c_date|$c_type|$c_name|$c_time|$c_hide|$c_event|$c_icon|$c_noname|$c_type2|$ns|$g\n";
                }
            }
        }
        else {
            if ($iamguest) { $username = $guestname; $g = 'g' }
            push @calinput,
"$FORM{'selyear'}$FORM{'selmon'}$FORM{'selday'}|$FORM{'caltype'}|$username|$date||$calmessage|$FORM{'calicon'}|$FORM{'calnoname'}|$FORM{'caltype2'}|$FORM{'ns'}|$g\n";
        }
        fopen( EVENTFILE, ">$vardir/eventcal.db" );
        print {EVENTFILE} @calinput or croak "$croak{'print'} EVENTFILE";
        fclose(EVENTFILE);

        if ( !$iamguest
            && ${ $uid . $username }{'postlayout'} ne
qq~$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}~
          )
        {
            ${ $uid . $username }{'postlayout'} =
qq~$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}~;
            UserAccount( $username, 'update' );
        }
    }

    del_old_events();
    $yySetLocation =
qq~$scripturl?action=eventcal;calshow=1;calmon=$FORM{'selmon'};calyear=$FORM{'selyear'}~;
    redirectexit();
    return;
}

## Delete old events ##

sub del_old_events {
    return if !$Delete_EventsUntil;
    my $caltoday = $Delete_EventsUntil;
    if ( $caltoday == 1 ) {

        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst ) =
          gmtime($date);
        $year += 1900;
        $mon++;
        $caltoday = $year . sprintf( '%02d', $mon ) . sprintf '%02d', $mday;
    }

    fopen( EVENTFILE, "$vardir/eventcal.db" );
    my @calinput = <EVENTFILE>;
    fclose(EVENTFILE);
    for my $i ( 0 .. ( @calinput - 1 ) ) {
        ( $c_date, undef, undef, undef, undef, undef, undef, $c_type2, undef ) =
          split /\|/xsm, $calinput[$i];
        chop $c_type2;
        if ( $c_date < $caltoday && $c_type2 < 2 ) { $calinput[$i] = q{}; }
    }
    fopen( EVENTFILE, ">$vardir/eventcal.db" );
    print {EVENTFILE} @calinput or croak "$croak{'print'} EVENTFILE";
    fclose(EVENTFILE);
    return;
}

## Event Icon ##

sub calicontext {
    my ($currenticon) = @_;

    if ( eval { require "$vardir/eventcalIcon.txt"; 1 } ) {
        my $i = 0;
        while ( $CalIconURL[$i] ) {
            if ( $CalIconURL[$i] eq "$currenticon" ) {
                $icon_out = "$CalIDescription[$i]";
            }
            $i++;
        }
    }
    return $icon_out;
}

1;
