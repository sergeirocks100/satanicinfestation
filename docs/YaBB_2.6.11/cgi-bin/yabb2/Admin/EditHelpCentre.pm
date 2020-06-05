###############################################################################
# EditHelpCentre.pm                                                           #
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

$edithelpcentrepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('HelpCentre');
$yytitle = $helptxt{'1'};

sub HelpEdit {
    $page      = $FORM{'page'};
    $help_area = $INFO{'area'};

    if ( $page eq 'user00_agreement' ) {
        $yySetLocation =
qq~$adminurl?action=modagreement;agreementlanguage=$language;destination=helpadmin~;
        redirectexit();
    }

    require "$helpfile/$language/$help_area/$page.help";

    $SectionName =~ s/_/ /gsm;
    $admin_list = qq~<tr>
        <td class="windowbg2">
            <label for="SectionName"><b>$helptxt{'7a'}</b></label>: <input type="text" maxlength="50" size="50" value="$SectionName" name="SectionName" id="SectionName" />
        </td>
    </tr>~;

    $aa = 1;
    while ( ${ SectionSub . $aa } ) {
        ${ SectionSub . $aa } =~ s/_/ /gsm;
        my $hmessage;
        $hmessage = ${ SectionBody . $aa };

        $admin_list .= qq~<tr>
        <td class="windowbg">
            <label for="SectionSub$aa"><b>$helptxt{'7b'}</b></label>: <input type="text" maxlength="50" size="50" value="${SectionSub.$aa}" name="SectionSub$aa" id="SectionSub$aa" />
        </td>
    </tr><tr>
        <td class="windowbg2" style="padding-bottom:1em">
            <textarea rows="10" name="SectionBody$aa" style="width: 99%">$hmessage</textarea>
        </td>
    </tr>~;
        $aa++;
    }

    $yymain .= qq~
<form name="help_update" action="$adminurl?action=helpediting2" method="post" accept-charset="$yymycharset">
    <input type="hidden" name="area" value="$help_area" />
    <input type="hidden" name="page" value="$page" />
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <td class="titlebg">
                    $admin_img{'prefimg'} <b>$helptxt{'7'}</b>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor borderstyle rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            $admin_list
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
    </div>
</form>~;

    $yytitle     = "$helptxt{'7'}";
    $action_area = 'helpadmin';
    AdminTemplate();
    return;
}

sub HelpEdit2 {
    $Area = $FORM{'area'};
    $Page = $FORM{'page'};

    fopen(HELPORDER, ">$helpfile/$language/$Area/$Page.help");

    $FORM{'SectionName'} =~ s/ /_/gsm;
    print HELPORDER qq~\$SectionName = "$FORM{'SectionName'}";\n\n~;
    $aa = 1;
    while ($FORM{"SectionBody$aa"}) {

        $FORM{"SectionBody$aa"} =~ tr/\r//d;
        $FORM{"SectionBody$aa"} =~ s/\cM//gxsm;
        $FORM{"SectionBody$aa"} =~
          s/\[([^\]]{0,30})\n([^\]]{0,30})\]/\[$1$2\]/gxsm;
        $FORM{"SectionBody$aa"} =~
          s/\[\/([^\]]{0,30})\n([^\]]{0,30})\]/\[\/$1$2\]/gxsm;
        $FORM{"SectionBody$aa"} =~
          s/(\w+:\/\/[^<>\s\n\"\]\[]+)\n([^<>\s\n\"\]\[]+)/$1\n$2/gxsm;
        $FORM{"SectionBody$aa"} =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
        $FORM{"SectionBody$aa"} =~ s/@/\\@/gxsm;

        $FORM{"SectionSub$aa"} =~ s/ /_/gsm;

        print {HELPORDER} qq~### Section $aa\n~
          or croak "$croak{'print'} HELPORDER";
        print {HELPORDER} qq~#############################################\n~
          or croak "$croak{'print'} HELPORDER";
        print {HELPORDER} qq~\$SectionSub$aa = "$FORM{"SectionSub$aa"}";\n~
          or croak "$croak{'print'} HELPORDER";
        print {HELPORDER}
          qq~\$SectionBody$aa = qq\~$FORM{"SectionBody$aa"}\~;\n~
          or croak "$croak{'print'} HELPORDER";
        print {HELPORDER}
          qq~#############################################\n\n\n~
          or croak "$croak{'print'} HELPORDER";

        $aa++;
    }
    print {HELPORDER} q~1;~ or croak "$croak{'print'} HELPORDER";

    fclose(HELPORDER);

    $yymain .= "$helptxt{'8'}";
    $yytitle       = "$helptxt{'7'}";
    $yySetLocation = qq~$adminurl?action=helpadmin~;
    redirectexit();
    return;
}

sub HelpSet2 {
    $UseHelp_Perms = $FORM{'UseHelp_Perms'} ? 1 : 0;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yymain .= "$helptxt{'8'}";
    $yytitle       = "$helptxt{'7'}";
    $yySetLocation = qq~$adminurl?action=helpadmin~;
    redirectexit();
    return;
}

sub MainAdmin {
    my ( $admin_list, $adminlist, $gmod_list, $gmodlist, $moderator_list,
        $moderatorlist, $user_list, $userlist );

    $admincount = 0;
    opendir HELPDIR, "$helpfile/$language/Admin";
    @contents = readdir HELPDIR;
    closedir HELPDIR;
    foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
        ( $name, $extension ) = split /\./xsm, $line;
        if ( $extension !~ /help/ism ) { next; }
        $select = q{};
        if ( $admincount == 0 ) { $select = q~ selected="selected"~; }
        $admin_list .= qq~<option value="$name"$select>$name</option>~;
        $admin_lst  .= qq~$name\n~;
        $admincount++;
    }
    if ( !-e ("$vardir/Admin.helporder") ) {
        fopen( HELPORDER, ">$vardir/Admin.helporder" )
          or croak("couldn't write order file - check permissions on $vardir");
        print {HELPORDER} qq~$admin_lst~ or croak "$croak{'print'} HELPORDER";
        fclose(HELPORDER);
    }
    fopen( HELPORDER, "$vardir/Admin.helporder" );
    @adminorderlist = <HELPORDER>;
    fclose(HELPORDER);
    foreach my $line (@adminorderlist) {
        chomp $line;
        $adminlist .= "$line\n";
    }

    $gmodcount = 0;
    opendir HELPDIR, "$helpfile/$language/Gmod";
    @contents = readdir HELPDIR;
    closedir HELPDIR;
    foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
        ( $name, $extension ) = split /\./xsm, $line;
        if ( $extension !~ /help/ism ) { next; }
        $select = q{};
        if ( $gmodcount == 0 ) { $select = q~ selected="selected"~; }
        $gmod_list .= qq~<option value="$name"$select>$name</option>~;
        $gmod_lst  .= qq~$name\n~;
        $gmodcount++;
    }
    if ( !-e ("$vardir/Gmod.helporder") ) {
        fopen( HELPORDER, ">$vardir/Gmod.helporder" )
          or croak("couldn't write order file - check permissions on $vardir");
        print {HELPORDER} qq~$gmod_lst~ or croak "$croak{'print'} HELPORDER";
        fclose(HELPORDER);
    }
    fopen( HELPORDER, "$vardir/Gmod.helporder" );
    @gmodorderlist = <HELPORDER>;
    fclose(HELPORDER);
    foreach my $line (@gmodorderlist) {
        chomp $line;
        $gmodlist .= "$line\n";
    }

    $modcount = 0;
    opendir HELPDIR, "$helpfile/$language/Moderator";
    @contents = readdir HELPDIR;
    closedir HELPDIR;
    foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
        ( $name, $extension ) = split /\./xsm, $line;
        if ( $extension !~ /help/ism ) { next; }
        $select = q{};
        if ( $modcount == 0 ) { $select = q~ selected="selected"~; }
        $moderator_list .= qq~<option value="$name"$select>$name</option>~;
        $moderator_lst  .= qq~$name\n~;
        $modcount++;
    }
    if ( !-e ("$vardir/Moderator.helporder") ) {
        fopen( HELPORDER, ">$vardir/Moderator.helporder" )
          or croak("couldn't write order file - check permissions on $vardir");
        print {HELPORDER} qq~$moderator_lst~ or croak "$croak{'print'} HELPORDER";
        fclose(HELPORDER);
    }
    fopen( HELPORDER, "$vardir/Moderator.helporder" );
    @modorderlist = <HELPORDER>;
    fclose(HELPORDER);
    foreach my $line (@modorderlist) {
        chomp $line;
        $moderatorlist .= "$line\n";
    }

    $usercount = 0;
    opendir HELPDIR, "$helpfile/$language/User";
    @contents = readdir HELPDIR;
    closedir HELPDIR;
    foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
        ( $name, $extension ) = split /\./xsm, $line;
        if ( $extension !~ /help/ism ) { next; }
        $select = q{};
        if ( $usercount == 0 ) { $select = q~ selected="selected"~; }
        $user_list .= qq~<option value="$name"$select>$name</option>~;
        $user_lst  .= qq~$name\n~;
        $usercount++;
    }
    if ( !-e ("$vardir/User.helporder") ) {
        fopen( HELPORDER, ">$vardir/User.helporder" )
          or croak("couldn't write order file - check permissions on $vardir");
        print {HELPORDER} qq~$user_lst~ or croak "$croak{'print'} HELPORDER";
        fclose(HELPORDER);
    }
    fopen( HELPORDER, "$vardir/User.helporder" );
    @userorderlist = <HELPORDER>;
    fclose(HELPORDER);
    foreach my $line (@userorderlist) {
        chomp $line;
        $userlist .= qq~$line\n~;
    }

    if ( $admincount < 4 ) { $admincount = 4; }
    if ( $gmodcount < 4 )  { $gmodcount  = 4; }
    if ( $modcount < 4 )   { $modcount   = 4; }
    if ( $usercount < 4 )  { $usercount  = 4; }

    my $perms_check = q{};
    if ( $UseHelp_Perms == 1 ) {
        $perms_check = q~ checked='checked'~;
    }
    $yymain .= qq~<form action="$adminurl?action=helpsettings2" method="post" style="display: inline">
            <table class="bordercolor border-space pad-cell" style="width:44em; margin-bottom:.5em">
                <tr>
                    <td class="titlebg">
                        $admin_img{'prefimg'} <b>$helptxt{'7'}</b>
                    </td>
                </tr><tr>
                    <td class="windowbg2">
                        <label for="UseHelp_Perms">$helptxt{'9'}</label> <input type="checkbox" name="UseHelp_Perms" id="UseHelp_Perms" value="1"$perms_check />
                    </td>
                </tr><tr>
                    <td class="catbg center">
                        <input type="submit" value="$admin_txt{'10'}" class="button" />
                    </td>
                </tr>
            </table>
        </form>

        <script type="text/javascript">
var nline = '\\n';
myRe=/\\n\$/;
myRg=/\\n\\s*?\\n/;
function addadminhelp() {
    thisstr = document.adminorder.order.value;
    if( ! myRe.test(thisstr) && document.adminorder.order.value !== '' ) document.adminorder.order.value = document.adminorder.order.value + nline;
    if( myRg.test(thisstr) ) document.adminorder.order.value = document.adminorder.order.value.replace(/\\n\\s*?\\n/, "\\n" + document.adminhelp.page.options[document.adminhelp.page.selectedIndex].value + "\\n");
    else document.adminorder.order.value += document.adminhelp.page.options[document.adminhelp.page.selectedIndex].value + nline;
}
function addgmodhelp() {
    thisstr = document.gmodorder.order.value;
    if( ! myRe.test(thisstr) && document.gmodorder.order.value !== '' ) document.gmodorder.order.value = document.gmodorder.order.value + nline;
    if( myRg.test(thisstr) ) document.gmodorder.order.value = document.gmodorder.order.value.replace(/\\n\\s*?\\n/, "\\n" + document.gmodhelp.page.options[document.gmodhelp.page.selectedIndex].value + "\\n");
    else document.gmodorder.order.value += document.gmodhelp.page.options[document.gmodhelp.page.selectedIndex].value + nline;
}
function addmodhelp() {
    thisstr = document.modorder.order.value;
    if( ! myRe.test(thisstr) && document.modorder.order.value !== '' ) document.modorder.order.value = document.modorder.order.value + nline;
    if( myRg.test(thisstr) ) document.modorder.order.value = document.modorder.order.value.replace(/\\n\\s*?\\n/, "\\n" + document.modhelp.page.options[document.modhelp.page.selectedIndex].value + "\\n");
    else document.modorder.order.value += document.modhelp.page.options[document.modhelp.page.selectedIndex].value + nline;
}
function adduserhelp() {
    thisstr = document.userorder.order.value;
    if( ! myRe.test(thisstr) && document.userorder.order.value !== '' ) document.userorder.order.value = document.userorder.order.value + nline;
    if( myRg.test(thisstr) ) document.userorder.order.value = document.userorder.order.value.replace(/\\n\\s*?\\n/, "\\n" + document.userhelp.page.options[document.userhelp.page.selectedIndex].value + "\\n");
    else document.userorder.order.value += document.userhelp.page.options[document.userhelp.page.selectedIndex].value + nline;
}
        </script>
        <table class="bordercolor border-space pad-cell" style="width:44em">
            <tr>
                <td class="titlebg">$admin_img{'prefimg'} <b>$helptxt{'7'}</b></td>
            </tr><tr>
                <td class="windowbg2">
                    <div class="pad-more small">$helptxt{'10'}</div>
                </td>
            </tr><tr>
                <td class="catbg"><i>$helptxt{'6'}</i></td>
            </tr><tr>
                <td class="windowbg2 center">
                    <form name="adminhelp" action="$adminurl?action=helpediting;area=Admin" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span class="help-box">
                        <select name="page" size="$admincount" class="help-page">
                            $admin_list
                            </select>
                            <br />
                            <input type="submit" value="$admin_txt{'53'}" class="button" />
                        </span>
                    </form>
                    <span class="help-add"><input type="button" value="\-\>" onclick="addadminhelp()" /></span>
                    <form name="adminorder" action="$adminurl?action=helporder;area=Admin" method="post" style="display: inline">
                        <span style="float: right; text-align: center; width: 200px;">
                            <textarea name="order" cols="29" rows="$admincount" class="help-page">$adminlist</textarea>
                            <input type="hidden" value="$admin_lst" name="testlst" />
                            <br />
                            <input type="submit" value="$admin_txt{'10'}" class="button" />
                        </span>
                    </form>
                </td>
            </tr><tr>
                <td class="catbg"><i>$helptxt{'5'}</i></td>
            </tr><tr>
                <td class="windowbg2 center">
                    <form name="gmodhelp" action="$adminurl?action=helpediting;area=Gmod" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span class="help-box">
                            <select name="page" size="$gmodcount" class="help-page">
                                $gmod_list
                            </select>
                            <br />
                            <input type="submit" value="$admin_txt{'53'}" class="button" />
                        </span>
                    </form>
                    <span class="help-add">
                        <input type="button" value="\-\>" onclick="addgmodhelp()" />
                    </span>
                    <form name="gmodorder" action="$adminurl?action=helporder;area=Gmod" method="post" style="display: inline">
                        <span style="float: right; text-align: center; width: 200px;">
                            <textarea name="order" cols="29" rows="$gmodcount" class="help-page">$gmodlist</textarea>
                            <input type="hidden" value="$gmod_lst" name="testlst" />
                            <br />
                            <input type="submit" value="$admin_txt{'10'}" class="button" />
                        </span>
                    </form>
                </td>
            </tr><tr>
                <td class="catbg"><i>$helptxt{'4'}</i></td>
            </tr><tr>
                <td class="windowbg2 center">
                    <form name="modhelp" action="$adminurl?action=helpediting;area=Moderator" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span class="help-box">
                        <select name="page" size="$modcount" class="help-page">
                            $moderator_list
                            </select>
                            <br />
                            <input type="submit" value="$admin_txt{'53'}" class="button" />
                        </span>
                    </form>
                    <span class="help-add">
                        <input type="button" value="\-\>" onclick="addmodhelp()" />
                    </span>
                    <form name="modorder" action="$adminurl?action=helporder;area=Moderator" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span style="float: right; text-align: center; width: 200px;">
                            <textarea name="order" cols="29" rows="$modcount" class="help-page">$moderatorlist</textarea>
                            <input type="hidden" value="$moderator_lst" name="testlst" />
                            <br />
                            <input type="submit" value="$admin_txt{'10'}" class="button" />
                        </span>
                    </form>
                </td>
            </tr><tr>
                <td class="catbg"><i>$helptxt{'3'}</i></td>
            </tr><tr>
                <td class="windowbg2 center">
                    <form name="userhelp" action="$adminurl?action=helpediting;area=User" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span class="help-box">
                            <select name="page" size="$usercount" class="help-page">
                                $user_list
                            </select>
                            <br />
                            <input type="submit" value="$admin_txt{'53'}" class="button" />
                        </span>
                    </form>
                    <span class="help-add">
                        <input type="button" value="\-\>" onclick="adduserhelp()" />
                    </span>
                    <form name="userorder" action="$adminurl?action=helporder;area=User" method="post" style="display: inline" accept-charset="$yymycharset">
                        <span style="float: right; text-align: center; width: 200px;">
                            <textarea name="order" cols="29" rows="$usercount" class="help-page">$userlist</textarea>
                            <input type="hidden" value="$user_lst" name="testlst" />
                            <br />
                            <input type="submit" value="$admin_txt{'10'}" class="button" />
                        </span>
                    </form>
                </td>
            </tr>
        </table>
~;

    $yytitle     = "$helptxt{'7'}";
    $action_area = 'helpadmin';
    AdminTemplate();
    return;
}

sub SetOrderFile {
    my $help_area   = $INFO{'area'};
    my %verify_hash = ();
    $FORM{'order'}   =~ s/\r//gxsm;
    $FORM{'testlst'} =~ s/\r//gxsm;
    $oldorder = $FORM{'testlst'};
    $neworder = $FORM{'order'};
    @oldorder = split /\n/xsm, $oldorder;
    @neworder = split /\n/xsm, $neworder;
    foreach (@oldorder) {
        $_ =~ s/[\n\r]//gxsm;
        $verify_hash{"$_"}++;
    }
    $theorder = q{};
    foreach my $order (@neworder) {
        $order =~ s/[\n\r]//gxsm;
        if ( $order eq q{} ) { next; }
        if ( !exists $verify_hash{$order} ) { next; }
        $theorder .= "$order\n";
    }
    fopen( HELPORDER, ">$vardir/$help_area.helporder" )
      or croak("couldn't write order file - check permissions on $vardir");
    print {HELPORDER} qq~$theorder~ or croak "$croak{'print'} HELPORDER";
    fclose(HELPORDER);
    $yytitle       = "$helptxt{'7'}";
    $yySetLocation = qq~$adminurl?action=helpadmin~;
    redirectexit();
    return;
}

1;
