###############################################################################
# EventCalSet.pm                                                              #
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

$eventcalsetpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('EventCal');
$admin_images = "$yyhtml_root/Templates/Admin/default";

## Calendar Setting ##

sub EventCalSet {
    is_admin_or_gmod();
    my ($caleventprivatechecked, $chkDelete_EventsUntil);

    # figure out what to print

    if    ( !$Scroll_Events )     { $aevt1 = ' selected="selected"'; }
    elsif ( $Scroll_Events == 1 ) { $aevt2 = ' selected="selected"'; }
    elsif ( $Scroll_Events == 2 ) { $aevt3 = ' selected="selected"'; }
    elsif ( $Scroll_Events == 3 ) { $aevt4 = ' selected="selected"'; }

    if ( !$Show_EventCal ) { $bevt1 = ' selected="selected"'; }
    elsif ( $Show_EventCal == 1 ) {
        $bevt2           = ' selected="selected"';
    }
    elsif ( $Show_EventCal == 2 ) {
        $bevt3           = ' selected="selected"';
      }

    if    ( !$Show_EventButton )     { $cevt1 = ' selected="selected"'; }
    elsif ( $Show_EventButton == 1 ) { $cevt2 = ' selected="selected"'; }
    elsif ( $Show_EventButton == 2 ) { $cevt3 = ' selected="selected"'; }

    if ( !$Show_BirthdaysList ) { $devt1 = ' selected="selected"'; }
    elsif ( $Show_BirthdaysList == 1 ) {
        $devt2         = ' selected="selected"';
    }
    elsif ( $Show_BirthdaysList == 2 ) {
        $devt3         = ' selected="selected"';
    }

    if    ( !$Show_BirthdayButton )     { $eevt1 = ' selected="selected"'; }
    elsif ( $Show_BirthdayButton == 1 ) { $eevt2 = ' selected="selected"'; }
    elsif ( $Show_BirthdayButton == 2 ) { $eevt3 = ' selected="selected"'; }

    if    ( !$Show_BirthdayDate )     { $fevt1 = ' selected="selected"'; }
    elsif ( $Show_BirthdayDate == 1 ) { $fevt2 = ' selected="selected"'; }
    elsif ( $Show_BirthdayDate == 2 ) { $fevt3 = ' selected="selected"'; }

    if    ( !$Show_EventBirthdays )     { $gevt1 = ' selected="selected"'; }
    elsif ( $Show_EventBirthdays == 1 ) { $gevt2 = ' selected="selected"'; }
    elsif ( $Show_EventBirthdays == 2 ) { $gevt3 = ' selected="selected"'; }

    if ($Show_caltoday)       { $Show_caltodaych = 'checked="checked"'; }
    if ($Show_BirthdaysList)  { $onbirthlistchecked     = 'checked="checked"'; }
    if ($Show_MiniCalIcons)   { $onminiiconchecked      = 'checked="checked"'; }
    if ($ShowSunday)          { $onsundaychecked        = 'checked="checked"'; }
    if ($CalEventPrivate)     { $caleventprivatechecked = 'checked="checked"'; }
    if ($Delete_EventsUntil)  { $chkDelete_EventsUntil = 'checked="checked"'; }
    if ($DisplayCalEvents)    { $dcaleventschecked      = 'checked="checked"'; }
    if ($Show_ColorLinks)     { $oncolorlinkschecked    = 'checked="checked"'; }
    if ($No_ShortUbbc)        { $onnosubbcchecked       = 'checked="checked"'; }
    if ($Show_BdColorLinks)   { $onbdcolorlinkschecked  = 'checked="checked"'; }
    if ($Show_BdStarsign)     { $onbdstarchecked  = 'checked="checked"'; }
    $Event_TodayColor = lc $Event_TodayColor;

    if    ( !$CalEventNoName )     { $noname1 = ' selected="selected"'; }
    elsif ( $CalEventNoName == 1 ) { $noname2 = ' selected="selected"'; }
    elsif ( $CalEventNoName == 2 ) { $noname3 = ' selected="selected"'; }

    require Admin::ManageBoards;
    $CalEventPerms =~ s/,/, /gsm;
    $CalEventPerms = DrawPerms($CalEventPerms);

    $yymain .= qq~
            <form action="$adminurl?action=eventcal_set2" method="post" onsubmit="savealert()" accept-charset="$yymycharset">
            <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <colgroup>
                    <col span="2" style="width: 50%" />
                </colgroup>
                <tr>
                    <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$event_cal{'1'}</b></td>
                </tr><tr>
                    <td class="catbg" colspan="2"><span class="small">$event_cal{'21'}</span></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_EventCal">$event_cal{'3'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_EventCal" id="Show_EventCal" size="1">
                        <option value="0"$bevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$bevt2>$userlevel_txt{'members'}</option>
                        <option value="2"$bevt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_EventButton">$event_cal{'4'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_EventButton" id="Show_EventButton" size="1">
                        <option value="0"$cevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$cevt2>$userlevel_txt{'members'}</option>
                        <option value="2"$cevt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_EventBirthdays">$event_cal{'5'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_EventBirthdays" id="Show_EventBirthdays" size="1">
                        <option value="0"$gevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$gevt2>$userlevel_txt{'members'}</option>
                        <option value="2"$gevt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="ShowSunday">$event_cal{'36'}<br /><span class="small">$event_cal{'37'}</span></label></td>
                    <td class="windowbg2"><input type="checkbox" name="ShowSunday" id="ShowSunday" $onsundaychecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Event_TodayColor">$event_cal{'8'}</label></td>
                    <td class="windowbg2">
                        <input type="text" size="7" maxlength="7" name="Event_TodayColor" id="Event_TodayColor" value="$Event_TodayColor" onkeyup="previewColor(this.value);" />
                        <span id="Event_TodayColor2" style="background-color:$Event_TodayColor">&nbsp; &nbsp; &nbsp;</span> <img src="$admin_images/palette1.gif" style="cursor: pointer; vertical-align:top" onclick="window.open('$scripturl?action=palette;task=templ', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" />
                        <script type="text/javascript">
            function previewColor(color) {
                document.getElementById('Event_TodayColor2').style.background = color;
                document.getElementsByName("Event_TodayColor")[0].value = color;
            }
                        </script>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_caltoday">$event_cal{'showtoday'}</label></td>
                    <td class="windowbg2"><input type="checkbox" name="Show_caltoday" id="Show_caltoday" value="1" $Show_caltodaych /></td>
                </tr><tr>
                    <td class="catbg" colspan="2"><span class="small">$event_cal{'22'}</span></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_MiniCalIcons">$event_cal{'43'}</label></td>
                    <td class="windowbg2"><input type="checkbox" name="Show_MiniCalIcons" id="Show_MiniCalIcons" $onminiiconchecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_ColorLinks">$event_cal{'44'}<br /><span class="small">$event_cal{'45'}</span></label></td>
                    <td class="windowbg2"><input type="checkbox" name="Show_ColorLinks" id="Show_ColorLinks" $oncolorlinkschecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Scroll_Events">$event_cal{'9'}<br /><span class="small">$event_cal{'10'}</span></label></td>
                    <td class="windowbg2">
                        <select name="Scroll_Events" id="Scroll_Events" size="1">
                        <option value="0"$aevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$aevt2>$event_cal{'12'} ($event_cal{'56'})</option>
                        <option value="3"$aevt4>$event_cal{'12'} ($event_cal{'57'})</option>
                        <option value="2"$aevt3>$event_cal{'13'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="DisplayCalEvents">$event_cal{'20'}</label></td>
                    <td class="windowbg2"><input type="checkbox" name="DisplayCalEvents" id="DisplayCalEvents" $dcaleventschecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="DisplayEvents">$event_cal{'34'}<br /><span class="small">$event_cal{'35'}</span></label></td>
                    <td class="windowbg2"><input type="text" name="DisplayEvents" id="DisplayEvents" size="5" value="$DisplayEvents" /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="CalShortEvent">$event_cal{'6'}<br /><span class="small">$event_cal{'7'}</span></label></td>
                    <td class="windowbg2">
                        <input type="text" name="CalShortEvent" id="CalShortEvent" size="5" value="$CalShortEvent" /><br />
                        <input type="checkbox" name="No_ShortUbbc" id="No_ShortUbbc" $onnosubbcchecked /> <span class="small"><label for="No_ShortUbbc">$event_cal{'58'}</label></span>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Delete_EventsUntil">$event_cal{'52'}</label></td>
                    <td class="windowbg2"><input type="checkbox" name="Delete_EventsUntil" id="Delete_EventsUntil" value="1" $chkDelete_EventsUntil /></td>
                </tr><tr>
                    <td class="catbg" colspan="2"><span class="small">$event_cal{'23'}</span></td>
                </tr><tr>
                    <td class="windowbg2"><label for="CalEventPerms">$event_cal{'14'}<br /><span class="small">$event_cal{'15'}</span></label></td>
                    <td class="windowbg2"><select multiple="multiple" name="CalEventPerms" id="CalEventPerms" size="5">$CalEventPerms</select></td>
                </tr><tr>
                    <td class="windowbg2"><label for="CalEventMods">$event_cal{'16'}<br /><span class="small">$event_cal{'17'}</span></label></td>
                    <td class="windowbg2"><input type="text" name="CalEventMods" id="CalEventMods" size="35" value="$CalEventMods" /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="CalEventPrivate">$event_cal{'18'}<br /><span class="small">$event_cal{'19'}</span></label></td>
                    <td class="windowbg2"><input type="checkbox" name="CalEventPrivate" id="CalEventPrivate" $caleventprivatechecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="CalEventNoName">$event_cal{'24'}</label></td>
                    <td class="windowbg2">
                        <select name="CalEventNoName" id="CalEventNoName" size="1">
                        <option value="0"$noname1>$userlevel_txt{'gmodadmin'}</option>
                        <option value="1"$noname2>$userlevel_txt{'members'}</option>
                        <option value="2"$noname3>$userlevel_txt{'none'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="catbg" colspan="2"><span class="small">$event_cal{'49'}</span></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_BirthdaysList">$event_cal{'42'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_BirthdaysList" id="Show_BirthdaysList" size="1">
                        <option value="0"$devt1>$userlevel_txt{'none'}</option>
                        <option value="1"$devt2>$userlevel_txt{'members'}</option>
                        <option value="2"$devt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_BirthdayButton">$event_cal{'48'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_BirthdayButton" id="Show_BirthdayButton" size="1">
                        <option value="0"$eevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$eevt2>$userlevel_txt{'members'}</option>
                        <option value="2"$eevt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_BirthdayDate">$event_cal{'50'}</label></td>
                    <td class="windowbg2">
                        <select name="Show_BirthdayDate" id="Show_BirthdayDate" size="1">
                        <option value="0"$fevt1>$userlevel_txt{'none'}</option>
                        <option value="1"$fevt2>$userlevel_txt{'members'}</option>
                        <option value="2"$fevt3>$userlevel_txt{'all'}</option>
                        </select>
                    </td>
                </tr><tr>
                    <td class="windowbg2"><label for="calsplit">$admin_txt{'calsplit'}</label></td>
                    <td class="windowbg2"><input type="text" size="5" name="calsplit" id="calsplit" value="$calsplit" /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="MaxCalMessLen">$admin_txt{'498e'}</label></td>
                    <td class="windowbg2"><input type="text" size="5" name="MaxCalMessLen" id="MaxCalMessLen" value="$MaxCalMessLen" /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="AdMaxCalMessLen">$admin_txt{'498f'}</label></td>
                    <td class="windowbg2"><input type="text" size="5" name="AdMaxCalMessLen" id="AdMaxCalMessLen" value="$AdMaxCalMessLen" /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_BdColorLinks">$event_cal{'44'}<br /><span class="small">$event_cal{'45'}</span></label></td>
                    <td class="windowbg2"><input type="checkbox" name="Show_BdColorLinks" id="Show_BdColorLinks" $onbdcolorlinkschecked /></td>
                </tr><tr>
                    <td class="windowbg2"><label for="Show_BdStarsign">$event_cal{'42a'}</label></td>
                    <td class="windowbg2"><input type="checkbox" name="Show_BdStarsign" id="Show_BdStarsign" $onbdstarchecked /></td>
                </tr>
            </table>
            </div>
            <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <tr>
                    <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
                </tr><tr>
                    <td class="catbg center">
                        <input type="submit" name="savesetting" value="$event_cal{'31'}" class="button" />&nbsp;<input type="submit" name="rebuiltbd" value="$event_cal{'54'}" class="button" />
                        <br /><input type="submit" name="del_old_events" value="$event_cal{'del'}" class="button" />
                    </td>
                </tr>
            </table>
            </div>
            </form>~;

    ## Calendar Event-Icon Setting ##

    eval { require "$vardir/eventcalIcon.txt"; };

    $yymain .= qq~
            <form action="$adminurl?action=eventcal_set3" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
            <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <colgroup>
                    <col span="2" style="width:40%" />
                    <col span="2" style="width:10%" />
                 </colgroup>
                <tr>
                    <td class="titlebg" colspan="4">$admin_img{'prefimg'} <b>$event_cal{'26'}</b></td>
                </tr><tr>
                    <td class="windowbg2" colspan="4"><div class="pad-more">$event_cal{'33'}</div></td>
                </tr><tr>
                    <td class="catbg center small">$event_cal{'27'}</td>
                    <td class="catbg center small">$event_cal{'28'}</td>
                    <td class="catbg center small">$event_cal{'29'}</td>
                    <td class="catbg center small">$var_cal{'caldel'}</td>
                </tr>~;

    $i = 0;
    my $add_icon = 1;
    while ( $CalIconURL[$i] ) {
        $yymain .= qq~<tr>
                    <td class="windowbg2 center" style="white-space:nowrap">
                        <input type="file" name="caliimg[$i]" id="caliimg[$i]" size="35"  />
                        <input type="hidden" name="cur_caliimg[$i]" value="$CalIconURL[$i]" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('caliimg[$i]').value='';">X</span>
                        <div class="small bold">$admin_txt{'current_img'}: <a href="$yyhtml_root/EventIcons/$CalIconURL[$i]" target="_blank">$CalIconURL[$i]</a></div>
                    </td>
                    <td class="windowbg2 center"><input type="text" name="calidescr[$i]" value="$CalIDescription[$i]" /></td>
                    <td class="windowbg2 center"><img src="$yyhtml_root/EventIcons/$CalIconURL[$i]" alt="" /></td>
                    <td class="windowbg2 center"><input type="checkbox" name="calidelbox[$i]" value="1" /></td>
                </tr>~;
        $i++;
        $add_icon++;
    }
    my $added_icons = $i;
    $yymain .= qq~<tr>
                    <td class="windowbg2 center" style="white-space:nowrap"><input type="file" name="caliimg[$i]" id="caliimg[$i]" size="35" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('caliimg[$i]').value='';">X</span></td>
                    <td class="windowbg2 center"><input type="text" name="calidescr[$i]" /></td>
                    <td class="windowbg2 center" colspan="2">
                        <img src="$imagesdir/cat_expand.png" alt="$event_cal{'59'}" title="$event_cal{'59'}" class="cursor" style="visibility: visible;" id="add_icon$i" onclick="addIcons($add_icon);" />
                        <img src="$imagesdir/cat_collapse.png" alt="" style="visibility: hidden;" /> <!-- Used only for alignment purposes -->
                    </td>
                </tr>~;
    for ( 1 .. 3 ) {
        $i++;
        $add_icon++;
        $yymain .= qq~<tr id="add_icons$i" style="display: none;">
                    <td class="windowbg2 center"><input type="file" name="caliimg[$i]" id="caliimg[$i]" size="35" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('caliimg[$i]').value='';">X</span></td>
                    <td class="windowbg2 center"><input type="text" name="calidescr[$i]" id="calidescr[$i]" /></td>
                    <td class="windowbg2 center" colspan="2">
                        <img src="$imagesdir/cat_expand.png" alt="$event_cal{'59'}" title="$event_cal{'59'}" class="cursor" style="visibility: visible;" id="add_icon$i" onclick="addIcons($add_icon);" />
                        <img src="$imagesdir/cat_collapse.png" alt="$event_cal{'60'}" title="$event_cal{'60'}" class="cursor" style="visibility: visible;" id="col_icon$i" onclick="removeIcons($i);" />
                    </td>
                </tr>~;
    }

    $yymain .= qq~
            </table>
            </div>
            <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <tr>
                    <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
                </tr><tr>
                    <td class="catbg center">
                        <input type="hidden" name="calimg_count" value="$i" />
                        <input type="submit" value="$event_cal{'32'}" class="button" />
                    </td>
                </tr>
            </table>
            </div>
<script type="text/javascript">
ic_added = $added_icons + 1;

function addIcons(addic_id) {
    var curic_id = addic_id - 1;
    var ic_count = $i;
    document.getElementById('add_icons' + addic_id).style.display = 'table-row';
    document.getElementById('add_icon' + curic_id).style.visibility = 'hidden';
    if (addic_id != ic_added) {
        document.getElementById('col_icon' + curic_id).style.visibility =' hidden';
    }
    if (addic_id == ic_count) {
        document.getElementById('add_icon' + ic_count).style.visibility = 'hidden';
    }
}
function removeIcons(remic_id) {
    var previc_id = remic_id - 1;
    document.getElementById('add_icons' + remic_id).style.display = 'none';
    document.getElementById('add_icon' + previc_id).style.visibility = 'visible';
    if (remic_id != ic_added) {
        document.getElementById('col_icon' + previc_id).style.visibility = 'visible';
    }
    ic_elements = ["caliimg","calidescr"];
    for (var i=0; i<ic_elements.length; i++) {
        document.getElementById(ic_elements[i] + '[' + remic_id + ']').value = '';
    }
}
</script>
        </form>~;

    $yytitle     = $event_cal{'1'};
    $action_area = 'eventcal_set';
    AdminTemplate();
    exit;
}

## Save Calendar Setting ##

sub EventCalSet2 {
    is_admin_or_gmod();

    if ( $FORM{'rebuiltbd'} eq "$event_cal{'54'}" ) {
        unlink "$vardir/eventcalbday.db";

        fopen( FILE, "$memberdir/memberlist.txt" );
        @birthmembers = <FILE>;
        fclose(FILE);
        fopen( FILE, ">$vardir/eventcalbday.db" );
        foreach my $user_name (@birthmembers) {
            ( $user_xy, $dummy ) = split /\t/sm, $user_name;
            chomp $user_xy;
            LoadUser($user_xy);
            $user_xy_bd = ${ $uid . $user_xy }{'bday'};
            if ($user_xy_bd) {
                ( $user_month, $user_day, $user_year ) =
                  split /\//xsm, $user_xy_bd;
                if ( $user_month < 10 && length($user_month) == 1 ) {
                    $user_month = "0$user_month";
                }
                if ( $user_day < 10 && length($user_day) == 1 ) {
                    $user_day = "0$user_day";
                }
                if (${ $uid . $user_xy }{'hideage'}){$user_hide = 1;}
                else {$user_hide = q{};}
                print {FILE} qq~$user_year|$user_month|$user_day|$user_xy|$user_hide\n~ or qq~$croak{'print'} eventcalbday.db~;
            }
        }
        fclose(FILE);

        $yySetLocation = qq~$adminurl?action=eventcal_set;rebok=1~;
        redirectexit();
    }
    elsif ( $FORM{'del_old_events'} eq "$event_cal{'del'}" ) {
        del_old_events();
    }
    else { eventcal_save();}
    return;
}

## Save Calendar Event-Icon Setting ##

sub EventCalSet3 {
    is_admin_or_gmod();

    my $count = 0;
    my $tempA = 0;
    my @eventcalIcon;
    $calimg_count = $FORM{'calimg_count'};

    for ( 1 .. $calimg_count ) {

        if ( $FORM{"calidescr[$tempA]"} ne q{} && ( $FORM{"caliimg[$tempA]"} eq q{} && $FORM{"cur_caliimg[$tempA]"} eq q{} ) ) { fatal_error('', $event_cal{'error_image'}); }
        if ( $FORM{"calidescr[$tempA]"} eq q{} && ( $FORM{"caliimg[$tempA]"} ne q{} || $FORM{"cur_caliimg[$tempA]"} ne q{} ) ) { fatal_error('', $event_cal{'error_desc'}); }
        if ( $FORM{"calidelbox[$tempA]"} != 1 && $FORM{"calidescr[$tempA]"} ne q{} && ( $FORM{"caliimg[$tempA]"} ne q{} || $FORM{"cur_caliimg[$tempA]"} ne q{} ) ) {
            if ( $FORM{"caliimg[$tempA]"} ne q{} ) {
                $FORM{"caliimg[$tempA]"} = UploadFile("caliimg[$tempA]", 'EventIcons', 'png jpg jpeg gif', '100', '0');
                unlink "$htmldir/EventIcons/$FORM{\"cur_caliimg[$tempA]\"}";
            }
            else {
                $FORM{"caliimg[$tempA]"} = $FORM{"cur_caliimg[$tempA]"};
            }
            push @eventcalIcon,
qq~\$CalIconURL[$count] = "$FORM{"caliimg[$tempA]"}";\n\$CalIDescription[$count] = "$FORM{"calidescr[$tempA]"}";\n\n~;
            $count++;
        }
        if ( $FORM{"calidelbox[$tempA]"} == 1 ) {
            unlink "$htmldir/EventIcons/$FORM{\"cur_caliimg[$tempA]\"}";
        }
        $tempA++;

    }
    push @eventcalIcon, '1;';
    fopen( FILE, ">$vardir/eventcalIcon.txt" );
    print {FILE} @eventcalIcon or croak "$croak{'print'} eventcalIcon";
    fclose(FILE);

    $yySetLocation = qq~$adminurl?action=eventcal_set~;
    redirectexit();
    return;
}

sub eventcal_save {
    is_admin_or_gmod();

    if ( $FORM{'Event_TodayColor'}   eq q{} ) { fatal_error('invalid_value', "$event_cal{'8'}"); }
    if ( $FORM{'DisplayEvents'}      eq q{} ) { fatal_error('invalid_value', "$event_cal{'34'}"); }
    if ( $FORM{'CalShortEvent'}      eq q{} ) { fatal_error('invalid_value', "$event_cal{'6'}"); }
    if ( $FORM{'MaxCalMessLen'}      eq q{} ) { fatal_error('invalid_value', "$admin_txt{'498e'}"); }
    if ( $FORM{'AdMaxCalMessLen'}    eq q{} ) { fatal_error('invalid_value', "$admin_txt{'498f'}"); }
    # Set 1 or 0 if box was checked or not
    map { ${$_} = $FORM{$_} ? 1 : 0; }
          qw{Show_MiniCalIcons CalEventPrivate DisplayCalEvents ShowSunday Show_ColorLinks No_ShortUbbc Show_BdColorLinks Show_BdStarsign};

# If empty fields are submitted, set them to default-values to save yabb from crashing
        $DisplayEvents = $FORM{'DisplayEvents'};
        $DisplayEvents =~ s/[^\d]//gxsm;
        $DisplayEvents    = $DisplayEvents            || 0;
        $Scroll_Events    = $FORM{'Scroll_Events'}    || 0;
        $Show_EventCal    = $FORM{'Show_EventCal'}    || 0;
        $Show_EventButton = $FORM{'Show_EventButton'} || 0;
        if ( $Show_EventButton > $Show_EventCal ) {
            $Show_EventButton = $Show_EventCal;
        }
        $Show_EventBirthdays = $FORM{'Show_EventBirthdays'} || 0;
        if ( $Show_EventBirthdays > $Show_EventCal ) {
            $Show_EventBirthdays = $Show_EventCal;
        }
        $Show_BirthdaysList  = $FORM{'Show_BirthdaysList'}  || 0;
        $Show_BirthdayButton = $FORM{'Show_BirthdayButton'} || 0;
        if ( $Show_BirthdayButton > $Show_BirthdaysList ) {
            $Show_BirthdayButton = $Show_BirthdaysList;
        }
        $Show_BirthdayDate = $FORM{'Show_BirthdayDate'} || 0;
        $CalEventNoName    = $FORM{'CalEventNoName'}    || 0;
        $Event_TodayColor =
          uc( $FORM{'Event_TodayColor'} || '#f00' ) . '#000';
        $Event_TodayColor =~ s/[^a-fA-F0-9#]//gxsm;
        $Event_TodayColor = substr $Event_TodayColor, 0, 7;
        $Delete_EventsUntil = $FORM{'Delete_EventsUntil'} || 0;
        $CalShortEvent = $FORM{'CalShortEvent'} || 0;
        $CalShortEvent =~ s/[^\d]//gxsm;
        $CalEventPerms = $FORM{'CalEventPerms'} || q{};
        $CalEventPerms =~ s/^\s*,\s*|\s*,\s*$//gsm;
        $CalEventPerms =~ s/\s*,\s*/,/gsm;
        $CalEventMods = $FORM{'CalEventMods'} || q{};
        $CalEventMods =~ s/^\s*,\s*|\s*,\s*$//gsm;
        $CalEventMods =~ s/\s*,\s*/,/gsm;
        $MaxCalMessLen = $FORM{'MaxCalMessLen'};
        $MaxCalMessLen =~ s/[^\d]//gxsm;
        $AdMaxCalMessLen = $FORM{'AdMaxCalMessLen'};
        $AdMaxCalMessLen =~ s/[^\d]//gxsm;
        $calsplit = $FORM{'calsplit'} || 0;
        $calsplit =~ s/[^\d]//gxsm;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=eventcal_set~;
    redirectexit();
    return;
}

sub del_old_events {
    $caltoday = 1;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst ) = gmtime( $date );
        $year += 1900;
        $mon++;
        $caltoday = $year . sprintf( '%02d', $mon ) . sprintf '%02d', $mday;

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

   $yySetLocation = qq~$adminurl?action=eventcal_set~;
    redirectexit();
    return;
}
1;
