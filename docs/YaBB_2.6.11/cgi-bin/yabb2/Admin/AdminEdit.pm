###############################################################################
# AdminEdit.pm                                                                #
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

$admineditpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Register');

sub GmodSettings {
    is_admin();

    LoadLanguage('GModPrivileges');

    if ( !-e ("$vardir/gmodsettings.txt") ) { GmodSettings2(); }
    require "$vardir/gmodsettings.txt";

    if ( $gmod_newfile eq q{} ) { GmodSettings2(); }

    fopen( MODACCESS, "$vardir/gmodsettings.txt" );
    @scriptlines = <MODACCESS>;
    fclose(MODACCESS);

    $startread = 0;
    $counter   = 0;
    foreach my $scriptline (@scriptlines) {
        chomp $scriptline;
        if ( substr( $scriptline, 0, 1 ) eq q{'} ) {
            $scriptline =~ s/newsettings\;page\=//xsm;
            if ( $scriptline =~ /\"(.*?)\"/sm ) {
                $allow = $1;
            }
            if ( $scriptline =~ /\'(.*?)\'/sm ) {
                $actionfound = $1;
            }
            push @actfound, $actionfound;
            push @allowed,  $allow;
            $counter++;
        }
    }
    @actfound = sort @actfound;
    $column  = int( $counter / 2 );
    $counter = 0;
    $aa      = 0;
    foreach my $actfound (@actfound) {
        $checked = q{};
        if ( $allowed[$aa] eq 'on' ) { $checked = ' checked="checked"'; }
        $dismenu .=
qq~\n<input type="checkbox" name="$actfound" id="$actfound"$checked />&nbsp;<label for="$actfound"><img src="$admin_img{'question'}" alt="$reftxt{'1a'} $gmodprivexpl_txt{$actfound}" title="$reftxt{'1a'} $gmodprivexpl_txt{$actfound}" /> $actfound</label><br />~;
        $counter++;
        $aa++;
        if ( $counter > $column + 1 ) {
            $dismenu .= q~</td><td class="windowbg2 vtop">~;
            $counter = 0;
        }
    }

    if ($allow_gmod_admin) { $gmod_selected_a = ' checked="checked"'; }
    if ($allow_gmod_profile) {
        $gmod_selected_p = ' checked="checked"';
        if ($allow_gmod_aprofile) { $gmod_selected_ap = ' checked="checked"'; }
    }
    else {
        $gmod_selected_ap = ' disabled="disabled"';
    }

    $yymain .= qq~
<form action="$adminurl?action=gmodsettings2" method="post" enctype="application/x-www-form-urlencoded">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <colgroup>
                <col span="2" style="width:50%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$gmod_settings{'1'}</b></td>
            </tr><tr>
                <td class="windowbg2" colspan="2">
                    <div class="pad-more">
                        <input type="checkbox" id="allow_gmod_admin" name="allow_gmod_admin"$gmod_selected_a /> <label for="allow_gmod_admin">$gmod_settings{'2'}</label><br />
                        <input type="checkbox" id="allow_gmod_profile" name="allow_gmod_profile"$gmod_selected_p onclick="depend(this.checked);" /> <label for="allow_gmod_profile">$gmod_settings{'3'}</label><br />
                        <input type="checkbox" id="allow_gmod_aprofile" name="allow_gmod_aprofile"$gmod_selected_ap /> <label for="allow_gmod_aprofile">$gmod_settings{'3a'}</label>
                    </div>
                </td>
            </tr><tr>
                <td class="catbg" colspan="2"><span class="small">$gmod_settings{'4'}</span></td>
            </tr><tr>
                <td class="windowbg2 vtop">$dismenu</td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
            </tr><tr>
                <td class="catbg center">
                    <input type="submit" value="$reftxt{'4'}" class="button" />
                </td>
            </tr>
        </table>
    </div>
</form>
<script type="text/javascript">
function depend(value) {
      if (value) {
            document.getElementById('allow_gmod_aprofile').disabled = false;
      } else {
            document.getElementById('allow_gmod_aprofile').checked = false;
            document.getElementById('allow_gmod_aprofile').disabled = true;
      }
}
</script>

~;
    $yytitle     = "$gmod_settings{'1'}";
    $action_area = 'gmodaccess';
    AdminTemplate();
    return;
}

sub EditBots {
    is_admin_or_gmod();
    my ($line);
    $yymain .= qq~
<form action="$adminurl?action=editbots2" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <td class="titlebg">$admin_img{'xx'} <b>$admin_txt{'18'}</b></td>
            </tr><tr>
                <td class="windowbg2">
                    <div class="pad-more small">$admin_txt{'19'}</div>
                </td>
            </tr><tr>
                <td class="windowbg2 center">
                    <div class="pad-more">
                        <textarea cols="70" rows="35" name="bots" style="width:98%">~;
    fopen( BOTS, "$vardir/bots.hosts" );
    while ( $line = <BOTS> ) { chomp $line; $yymain .= qq~$line\n~; }
    fclose(BOTS);
    $yymain .= qq~</textarea>
                    </div>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
            </tr><tr>
                <td class="catbg center">
                    <input class="button" type="submit" value="$admin_txt{'10'}" />
                </td>
            </tr>
        </table>
    </div>
</form>
~;
    $yytitle     = "$admin_txt{'18'}";
    $action_area = 'editbots';
    AdminTemplate();
    return;
}

sub EditBots2 {
    is_admin_or_gmod();

    fopen( BOTS, ">$vardir/bots.hosts", 1 );
    print {BOTS} map { "$_\n"; }
      sort { ( split /\|/xsm, $a )[1] cmp( split /\|/xsm, $b )[1] }
      split /[\n\r]+/xsm, $FORM{'bots'}
      or croak "$croak{'print'} BOTS";
    fclose(BOTS);

    $yySetLocation = qq~$adminurl?action=editbots~;
    redirectexit();
    return;
}

sub SetCensor {
    is_admin_or_gmod();
    my ( $censorlanguage, $line );
    if ( $FORM{'censorlanguage'} ) { $censorlanguage = $FORM{'censorlanguage'} }
    else                           { $censorlanguage = $lang; }
    opendir LNGDIR, $langdir;
    my @lfilesanddirs = readdir LNGDIR;
    closedir LNGDIR;

    foreach my $fld ( sort { lc($a) cmp lc $b } @lfilesanddirs ) {
        if (   -d "$langdir/$fld"
            && $fld =~ m{\A[0-9a-zA-Z_\#\%\-\:\+\?\$\&\~\,\@/]+\Z}sm
            && -e "$langdir/$fld/Main.lng" )
        {
                $displang = $fld;
                $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
                if ( $censorlanguage eq $fld ) {
                  $drawnldirs .= qq~<option value="$fld" selected="selected">$displang</option>~;
            }
            else { $drawnldirs .= qq~<option value="$fld">$displang</option>~; }
        }
    }

    my ( @censored, $i );
    fopen( CENSOR, "$langdir/$censorlanguage/censor.txt" );
    @censored = <CENSOR>;
    fclose(CENSOR);
    foreach my $i (@censored) {
        $i =~ tr/\r//d;
        $i =~ tr/\n//d;
    }
    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: -1px;">
        <tr>
            <th class="titlebg">
                $admin_img{'banimg'}<span class="legend"> <b>$admin_txt{'135'}</b></span>
            </th>
        </tr><tr>
            <td class="windowbg2">
            <form action="$adminurl?action=setcensor" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
                $templs{'7'}
                <select name="censorlanguage" id="censorlanguage" size="1">
                    $drawnldirs
                </select>
                <input type="submit" value="$admin_txt{'462'}" class="button" />
            </form>
            </td>
        </tr>
    </table>
</div>
<form action="$adminurl?action=setcensor2" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
    <div class="bordercolor rightboxdiv">
        <table class="border-space" style="margin-bottom: .5em;">
            <tr>
                <td class="windowbg2">
                    <div class="pad-more">
                        <label for="censored">$admin_txt{'136'}</label>
                    </div>
                </td>
            </tr><tr>
                <td class="windowbg2 center">
                    <div class="pad-more">
                        <input type="hidden" name="censorlanguage" value="$censorlanguage" />
                        <textarea rows="35" cols="15" name="censored" id="censored" style="width:90%">~;
    foreach my $i (@censored) {
        if ( !$i || $i !~ m/.+[\=~].+/sm ) { next; }
        $yymain .= "$i\n";
    }
    $yymain .= qq~</textarea>
                    </div>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
            </tr><tr>
                <td class="catbg center">
                    <input type="submit" value="$admin_txt{'10'} $censorlanguage" class="button" />
                </td>
            </tr>
        </table>
    </div>
</form>
~;
    $yytitle     = "$admin_txt{'135'}";
    $action_area = 'setcensor';
    AdminTemplate();
    return;
}

sub SetCensor2 {    # don't use &FromChars() here!!!
    is_admin_or_gmod();
    $FORM{'censored'} =~ tr/\r//d;
    $FORM{'censored'} =~ s/\A[\s\n]+//xsm;
    $FORM{'censored'} =~ s/[\s\n]+\Z//xsm;
    $FORM{'censored'} =~ s/\n\s*\n/\n/gxsm;
    if ( $FORM{'censorlanguage'} ) {
        $censorlanguage = $FORM{'censorlanguage'};
    }
    else { $censorlanguage = $lang; }
    my @lines = split /\n/xsm, $FORM{'censored'};
    fopen( CENSOR, ">$langdir/$censorlanguage/censor.txt", 1 );

    foreach my $i (@lines) {
        $i =~ tr/\n//d;
        if ( !$i || $i !~ m/.+[\=~].+/sm ) { next; }
        print {CENSOR} "$i\n" or croak "$croak{'print'} CENSOR";
    }
    fclose(CENSOR);
    $yySetLocation = qq~$adminurl?action=setcensor~;
    redirectexit();
    return;
}

sub SetReserve {
    is_admin_or_gmod();
    fopen( RESERVE, "$vardir/reserve.txt" );
    my @reserved = <RESERVE>;
    fclose(RESERVE);
    fopen( RESERVECFG, "$vardir/reservecfg.txt" );
    my @reservecfg = <RESERVECFG>;
    fclose(RESERVECFG);
    for my $i ( 0 .. ( @reservecfg - 1 ) ) {
        chomp $reservecfg[$i];
        if ( $reservecfg[$i] ) { $reservecheck[$i] = q~ checked="checked"~; }
    }
    $yymain .= qq~
<form action="$adminurl?action=setreserve2" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
    <div class="bordercolor rightboxdiv">
    <table class="border-space" style="margin-bottom: .5em;">
        <tr>
           <td class="titlebg">$admin_img{'profile'} <b>$admin_txt{'341'}</b></td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$admin_txt{'699'}</div>
            </td>
        </tr><tr>
            <td class="windowbg2"><div class="pad-more">
                $admin_txt{'342'}
                <p class="center"><textarea cols="40" rows="35" name="reserved" style="width:95%">~;
    foreach my $i (@reserved) {
        chomp $i;
        $i =~ s/\t//gxsm;
        if ( $i !~ m{\A[\S|\s]*[\n\r]*\Z}sm ) { next; }
        $yymain .= "$i\n";
    }
    $yymain .= qq~</textarea>
      </p>
      <input type="checkbox" name="matchword" id="matchword" value="checked"$reservecheck[0] />
      <label for="matchword">$admin_txt{'726'}</label><br />
      <input type="checkbox" name="matchcase" id="matchcase" value="checked"$reservecheck[1] />
      <label for="matchcase">$admin_txt{'727'}</label><br />
      <input type="checkbox" name="matchuser" id="matchuser" value="checked"$reservecheck[2] />
      <label for="matchuser">$admin_txt{'728'}</label><br />
      <input type="checkbox" name="matchname" id="matchname" value="checked"$reservecheck[3] />
      <label for="matchname">$admin_txt{'729'}</label>
            </div></td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" value="$admin_txt{'10'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
~;
    $yytitle     = "$admin_txt{'341'}";
    $action_area = 'setreserve';
    AdminTemplate();
    return;
}

sub SetReserve2 {
    is_admin_or_gmod();
    $FORM{'reserved'} =~ tr/\r//d;
    $FORM{'reserved'} =~ s/\A[\s\n]+//xsm;
    $FORM{'reserved'} =~ s/[\s\n]+\Z//xsm;
    $FORM{'reserved'} =~ s/\n\s*\n/\n/gxsm;
    fopen( RESERVE, ">$vardir/reserve.txt", 1 );
    my $matchword = $FORM{'matchword'} eq 'checked' ? 'checked' : q{};
    my $matchcase = $FORM{'matchcase'} eq 'checked' ? 'checked' : q{};
    my $matchuser = $FORM{'matchuser'} eq 'checked' ? 'checked' : q{};
    my $matchname = $FORM{'matchname'} eq 'checked' ? 'checked' : q{};
    print {RESERVE} $FORM{'reserved'} or croak "$croak{'print'} RESERVE";
    fclose(RESERVE);
    fopen( RESERVECFG, "+>$vardir/reservecfg.txt" );
    print {RESERVECFG} "$matchword\n" or croak "$croak{'print'} RESERVECFG";
    print {RESERVECFG} "$matchcase\n" or croak "$croak{'print'} RESERVECFG";
    print {RESERVECFG} "$matchuser\n" or croak "$croak{'print'} RESERVECFG";
    print {RESERVECFG} "$matchname\n" or croak "$croak{'print'} RESERVECFG";
    fclose(RESERVECFG);
    $yySetLocation = qq~$adminurl?action=setreserve~;
    redirectexit();
    return;
}

sub ModifyAgreement {
    is_admin_or_gmod();

    opendir LNGDIR, $langdir;
    my @lfilesanddirs = readdir LNGDIR;
    closedir LNGDIR;

    my $agreementlanguage =
         $FORM{'agreementlanguage'}
      || $INFO{'agreementlanguage'}
      || $lang;
    foreach my $fld (sort {lc($a) cmp lc $b} @lfilesanddirs) {
        if (-e "$langdir/$fld/Main.lng") {
            $displang = $fld;
            $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
            if ($agreementlanguage eq $fld) {
                $drawnldirs .= qq~<option value="$fld" selected="selected">$displang</option>~; }
            else { $drawnldirs .= qq~<option value="$fld">$displang</option>~; }
        }
    }

    my ( $fullagreement, $line );
    fopen( AGREE, "$langdir/$agreementlanguage/agreement.txt" );
    while ( $line = <AGREE> ) {
        $line =~ tr/[\r\n]//d;
        FromHTML($line);
        $fullagreement .= qq~$line\n~;
    }
    fclose(AGREE);
    $yymain .= qq~
 <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: -1px;">
        <tr>
            <td class="titlebg">$admin_img{'xx'} <b>$admin_txt{'764'}</b></td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                    <label for="agreement">$admin_txt{'765'}</label>
                </div>
            </td>
        </tr><tr>
           <td class="windowbg2">
                <form action="$adminurl?action=modagreement" method="post" enctype="application/x-www-form-urlencoded">
                $templs{'8'}
                <select name="agreementlanguage" id="agreementlanguage" size="1">
                $drawnldirs
                </select>
                <input type="submit" value="$admin_txt{'462'}" class="button" />
                </form>
            </td>
        </tr>
    </table>
</div>
<form action="$adminurl?action=modagreement2" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
<div class="bordercolor borderstyle rightboxdiv">
    <table class="border-space" style="margin-bottom: .5em;">
        <tr>
            <td class="windowbg2 center">
                <div class="pad-more">
                <input type="hidden" name="destination" value="$INFO{'destination'}" />
                <input type="hidden" name="agreementlanguage" value="$agreementlanguage" />
                <textarea rows="35" cols="95" name="agreement" id="agreement" style="width:95%">$fullagreement</textarea>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" value="$admin_txt{'10'} $agreementlanguage" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
~;
    $yytitle     = "$admin_txt{'764'}";
    $action_area = 'modagreement';
    AdminTemplate();
    return;
}

sub ModifyAgreement2 {
    is_admin_or_gmod();

    if ( $FORM{'agreementlanguage'} ) {
        $agreementlanguage = $FORM{'agreementlanguage'};
    }
    else { $agreementlanguage = $lang; }
    $FORM{'agreement'} =~ tr/\r//d;
    $FORM{'agreement'} =~ s/\A\n+//xsm;
    $FORM{'agreement'} =~ s/\n+\Z//xsm;
    fopen( AGREE, ">$langdir/$agreementlanguage/agreement.txt" );
    print {AGREE} $FORM{'agreement'} or croak "$croak{'print'} AGREE";
    fclose(AGREE);

    $FORM{'agreement'} =~ s/\n/<br \/>\n/gsm;
    fopen( HELPAGREE,
        ">$helpfile/$agreementlanguage/User/user00_agreement.help" );
    $my_regtitle = $register_txt{'764a'};
    $my_regtitle =~ s/ /_/gsm;
    print {HELPAGREE} qq^\$SectionName = "$my_regtitle";

### Section 1
#############################################
\$SectionSub1 = "{yabb_boardname}_$my_regtitle";
\$SectionBody1 = qq~<p>$FORM{'agreement'}</p>~;
#############################################


1;^ or croak "$croak{'print'} HELPAGREE";
    fclose(HELPAGREE);

    $yySetLocation =
      $FORM{'destination'}
      ? qq~$adminurl?action=$FORM{'destination'}~
      : qq~$adminurl?action=modagreement;agreementlanguage=$FORM{'agreementlanguage'}~;
    redirectexit();
    return;
}

sub GmodSettings2 {
    is_admin();

    # modstyle is set the same as modcss as modcss is useless without it.
    $mynewsettings =
         $FORM{'main'}
      || $FORM{'advanced'}
      || $FORM{'news'}
      || $FORM{'security'}
      || $FORM{'antispam'};

    if ( $FORM{'deletemultimembers'} eq 'on' || $FORM{'addmember'} eq 'on' ) {
        $FORM{'viewmembers'} = 'on';
    }

    my $filler =
q~                                                                               ~;
    my $setfile = << "EOF";
### Gmod Related Setttings ###

\$allow_gmod_admin = "$FORM{'allow_gmod_admin'}"; #
\$allow_gmod_profile = "$FORM{'allow_gmod_profile'}"; #
\$allow_gmod_aprofile = "$FORM{'allow_gmod_aprofile'}"; #
\$gmod_newfile = 'on'; #

### Areas Gmods can Access ###

%gmod_access = (
'ext_admin',"$FORM{'ext_admin'}",

'newsettings;page=main',"$FORM{'main'}",
'newsettings;page=advanced', "$FORM{'advanced'}",
'editbots',"$FORM{'editbots'}",

'newsettings;page=news',"$FORM{'news'}",
'smilies',"$FORM{'smilies'}",
'setcensor',"$FORM{'setcensor'}",
'modagreement',"$FORM{'modagreement'}",
'eventcal_set',"$FORM{'eventcal_set'}",
'bookmarks',"$FORM{'bookmarks'}",

'referer_control',"$FORM{'referer_control'}",
'newsettings;page=security',"$FORM{'security'}",
'setup_guardian',"$FORM{'setup_guardian'}",
'newsettings;page=antispam',"$FORM{'antispam'}",
'spam_questions',"$FORM{'spam_questions'}",
'honeypot',"$FORM{'honeypot'}",
'managecats',"$FORM{'managecats'}",
'manageboards',"$FORM{'manageboards'}",
'helpadmin',"$FORM{'helpadmin'}",
'editemailtemplates',"$FORM{'editemailtemplates'}",

'addmember',"$FORM{'addmember'}",
'viewmembers',"$FORM{'viewmembers'}",
'deletemultimembers',"$FORM{'deletemultimembers'}",
'modmemgr',"$FORM{'modmemgr'}",
'mailing',"$FORM{'mailing'}",
'ipban',"$FORM{'ipban'}",
'setreserve',"$FORM{'setreserve'}",

'modskin',"$FORM{'modskin'}",
'modcss',"$FORM{'modcss'}",
'modtemp',"$FORM{'modtemp'}",

'clean_log',"$FORM{'clean_log'}",
'boardrecount',"$FORM{'boardrecount'}",
'rebuildmesindex',"$FORM{'rebuildmesindex'}",
'membershiprecount',"$FORM{'membershiprecount'}",
'rebuildmemlist',"$FORM{'rebuildmemlist'}",
'rebuildmemhist',"$FORM{'rebuildmemhist'}",
'rebuildnotifications',"$FORM{'rebuildnotifications'}",
'deleteoldthreads',"$FORM{'deleteoldthreads'}",
'manageattachments',"$FORM{'manageattachments'}",
'backupsettings',"$FORM{'backupsettings'}",

'detailedversion',"$FORM{'detailedversion'}",
'stats',"$FORM{'stats'}",
'showclicks',"$FORM{'showclicks'}",
'errorlog',"$FORM{'errorlog'}",

'view_reglog',"$FORM{'view_reglog'}",

'modlist',"$FORM{'modlist'}",
);

%gmod_access2 = (
admin => "$FORM{'allow_gmod_admin'}",

newsettings => "$mynewsettings",
newsettings2 => "$mynewsettings",
eventcal_set2 => "$FORM{'eventcal_set'}",
eventcal_set3 => "$FORM{'eventcal_set'}",
bookmarks2 => "$FORM{'bookmarks'}",
bookmarks_add => "$FORM{'bookmarks'}",
bookmarks_add2 => "$FORM{'bookmarks'}",
bookmarks_edit => "$FORM{'bookmarks'}",
bookmarks_edit2 => "$FORM{'bookmarks'}",
bookmarks_delete => "$FORM{'bookmarks'}",
bookmarks_delete2 => "$FORM{'bookmarks'}",
spam_questions2 => "$FORM{'spam_questions'}",
spam_questions_add => "$FORM{'spam_questions'}",
spam_questions_add2 => "$FORM{'spam_questions'}",
spam_questions_edit => "$FORM{'spam_questions'}",
spam_questions_edit2 => "$FORM{'spam_questions'}",
spam_questions_delete => "$FORM{'spam_questions'}",
spam_questions_delete2 => "$FORM{'spam_questions'}",
honeypot2 => "$FORM{'honeypot'}",
honeypot_add => "$FORM{'honeypot'}",
honeypot_add2 => "$FORM{'honeypot'}",
honeypot_edit => "$FORM{'honeypot'}",
honeypot_edit2 => "$FORM{'honeypot'}",
honeypot_delete => "$FORM{'honeypot'}",
honeypot_delete2 => "$FORM{'honeypot'}",
deleteattachment => "$FORM{'manageattachments'}",
manageattachments2 => "$FORM{'manageattachments'}",
removeoldattachments => "$FORM{'manageattachments'}",
removebigattachments => "$FORM{'manageattachments'}",
rebuildattach => "$FORM{'manageattachments'}",
remghostattach => "$FORM{'manageattachments'}",

profile => "$FORM{'allow_gmod_profile'}",
profile2 => "$FORM{'allow_gmod_profile'}",
profileAdmin => "$FORM{'allow_gmod_aprofile'}",
profileAdmin2 => "$FORM{'allow_gmod_aprofile'}",
profileContacts => "$FORM{'allow_gmod_profile'}",
profileContacts2 => "$FORM{'allow_gmod_profile'}",
profileIM => "$FORM{'allow_gmod_profile'}",
profileIM2 => "$FORM{'allow_gmod_profile'}",
profileOptions => "$FORM{'allow_gmod_profile'}",
profileOptions2 => "$FORM{'allow_gmod_profile'}",

ext_edit => "$FORM{'ext_admin'}",
ext_edit2 => "$FORM{'ext_admin'}",
ext_create => "$FORM{'ext_admin'}",
ext_reorder => "$FORM{'ext_admin'}",
ext_convert => "$FORM{'ext_admin'}",

myprofileAdmin => "$FORM{'allow_gmod_aprofile'}",
myprofileAdmin2 => "$FORM{'allow_gmod_aprofile'}",

delgroup => "$FORM{'modmemgr'}",
editgroup => "$FORM{'modmemgr'}",
editAddGroup2 => "$FORM{'modmemgr'}",
modmemgr2 => "$FORM{'modmemgr'}",
assigned => "$FORM{'modmemgr'}",
assigned2 => "$FORM{'modmemgr'}",

reordercats => "$FORM{'managecats'}",
reordercats2 => "$FORM{'managecats'}",
modifycatorder => "$FORM{'managecats'}",
modifycat => "$FORM{'managecats'}",
createcat => "$FORM{'managecats'}",
catscreen => "$FORM{'managecats'}",
addcat => "$FORM{'managecats'}",
addcat2 => "$FORM{'managecats'}",

modskin => "$FORM{'modskin'}",
modskin2 => "$FORM{'modskin'}",
modcss => "$FORM{'modcss'}",
modcss2 => "$FORM{'modcss'}",
modstyle => "$FORM{'modcss'}",
modstyle2 => "$FORM{'modcss'}",
modtemplate2 => "$FORM{'modtemp'}",
modtemp2 => "$FORM{'modtemp'}",

modifyboard => "$FORM{'manageboards'}",
addboard => "$FORM{'manageboards'}",
addboard2 => "$FORM{'manageboards'}",
reorderboards => "$FORM{'manageboards'}",
reorderboards2 => "$FORM{'manageboards'}",
boardscreen => "$FORM{'manageboards'}",

smilieput => "$FORM{'smilies'}",
smilieindex => "$FORM{'smilies'}",
smiliemove => "$FORM{'smilies'}",
addsmilies => "$FORM{'smilies'}",

addmember => "$FORM{'addmember'}",
addmember2 => "$FORM{'addmember'}",
ml => "$FORM{'viewmembers'}",
deletemultimembers => "$FORM{'deletemultimembers'}",

mailmultimembers => "$FORM{'mailing'}",
mailing2 => "$FORM{'mailing'}",

activate => "$FORM{'view_reglog'}",
admin_descision => "$FORM{'view_reglog'}",
apr_regentry => "$FORM{'view_reglog'}",
del_regentry => "$FORM{'view_reglog'}",
rej_regentry => "$FORM{'view_reglog'}",
view_regentry => "$FORM{'view_reglog'}",
clean_reglog => "$FORM{'view_reglog'}",

cleanerrorlog => "$FORM{'errorlog'}",
deleteerror => "$FORM{'errorlog'}",

modagreement2 => "$FORM{'modagreement'}",
advsettings2 => "$FORM{'advsettings'}",
referer_control2 => "$FORM{'referer_control'}",
removeoldthreads => "$FORM{'deleteoldthreads'}",
ipban2 => "$FORM{'ipban'}",
setcensor2 => "$FORM{'setcensor'}",
setreserve2 => "$FORM{'setreserve'}",

editbots2 => "$FORM{'editbots'}",
);

1;
EOF

    $setfile =~
      s/(.+\;)\s+(\#.+$)/$1 . substr( $filler, 0, (70-(length $1)) ) . $2 /gesm;
    $setfile =~ s/(.{64,}\;)\s+(\#.+$)/$1 . "\n   " . $2/gesm;
    $setfile =~ s/^\s\s\s+(\#.+$)/substr( $filler, 0, 70 ) . $1/gesm;

    fopen( MODACCESS, ">$vardir/gmodsettings.txt" );
    print {MODACCESS} $setfile or croak "$croak{'print'} MODACCESS";
    fclose(MODACCESS);

    $yySetLocation = qq~$adminurl?action=gmodaccess~;
    redirectexit();
    return;
}

sub EditPaths {

    # Simple output of env variables, for troubleshooting
    if ( $ENV{'SCRIPT_FILENAME'} ne q{} ) {
        $support_env_path = $ENV{'SCRIPT_FILENAME'};

        # replace \'s with /'s for Windows Servers
        $support_env_path =~ s/\\/\//gxsm;

        # Remove Setupl.pl and cgi - and also nph- for buggy IIS.
        $support_env_path =~ s/(nph-)?AdminIndex.(pl|cgi)//igxsm;
    }
    elsif ( $ENV{'PATH_TRANSLATED'} ne q{} ) {
        $support_env_path = $ENV{'PATH_TRANSLATED'};

        # replace \'s with /'s for Windows Servers
        $support_env_path =~ s/\\/\//gxsm;

        # Remove Setupl.pl and cgi - and also nph- for buggy IIS.
        $support_env_path =~ s/(nph-)?AdminIndex.(pl|cgi)//igxsm;
    }

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg"><b>$edit_paths_txt{'33'}</b></td>
        </tr><tr>
            <td class="catbg"><span class="small">$edit_paths_txt{'34'}</span></td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                  $support_env_path
                </div>
            </td>
        </tr>
    </table>
</div>
<form action="$adminurl?action=editpaths2" method="post" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <td class="titlebg">
                    $admin_img{'prefimg'}&nbsp;<b>$edit_paths_txt{'1'}</b>
                </td>
            </tr><tr>
                <td class="catbg"><span class="small">$edit_paths_txt{'2'}</span></td>
            </tr><tr>
                <td class="windowbg2">
                    <div class="setting-cell">
                        <label for="boarddir">$edit_paths_txt{'4'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="boarddir" id="boarddir" size="50" value="$boarddir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="admindir">$edit_paths_txt{'9'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="admindir" id="admindir" size="50" value="$admindir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="boardsdir">$edit_paths_txt{'5'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="boardsdir" id="boardsdir" size="50" value="$boardsdir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="helpfile">$edit_paths_txt{'12'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="helpfile" id="helpfile" size="50" value="$helpfile" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="langdir">$edit_paths_txt{'11'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="langdir" id="langdir" size="50" value="$langdir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="memberdir">$edit_paths_txt{'7'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="memberdir" id="memberdir" size="50" value="$memberdir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="datadir">$edit_paths_txt{'6'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="datadir" id="datadir" size="50" value="$datadir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="sourcedir">$edit_paths_txt{'8'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="sourcedir" id="sourcedir" size="50" value="$sourcedir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="templatesdir">$edit_paths_txt{'13'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="templatesdir" id="templatesdir" size="50" value="$templatesdir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="vardir">$edit_paths_txt{'10'}</label>
                    </div>
                    <div class="setting-cell2" style="margin-bottom:.5em">
                        <input type="text" name="vardir" id="vardir" size="50" value="$vardir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="htmldir">$edit_paths_txt{'16'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="htmldir" id="htmldir" size="50" value="$htmldir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="uploaddir">$edit_paths_txt{'20'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="uploaddir" id="uploaddir" size="50" value="$uploaddir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="pmuploaddir">$edit_paths_txt{'20a'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="pmuploaddir" id="pmuploaddir" size="50" value="$pmuploaddir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="facesdir">$edit_paths_txt{'17'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="facesdir" id="facesdir" size="50" value="$facesdir" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="modimgdir">$edit_paths_txt{'19'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="modimgdir" id="modimgdir" size="50" value="$modimgdir" />
                    </div>
                </td>
            </tr><tr>
                <td class="catbg"><span class="small">$edit_paths_txt{'21'}</span></td>
            </tr><tr>
                <td class="windowbg2">
                    <div class="setting-cell">
                        <label for="boardurl">$edit_paths_txt{'3'}</label>
                    </div>
                    <div class="setting-cell2"  style="margin-bottom:.5em">
                        <input type="text" name="boardurl" id="boardurl" size="50" value="$boardurl" />
                    </div>
                    <div class="setting-cell">
                        <label for="yyhtml_root">$edit_paths_txt{'28'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="yyhtml_root" id="yyhtml_root" size="50" value="$yyhtml_root" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="uploadurl">$edit_paths_txt{'32'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="uploadurl" id="uploadurl" size="50" value="$uploadurl" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="pmuploadurl">$edit_paths_txt{'32a'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="pmuploadurl" id="pmuploadurl" size="50" value="$pmuploadurl" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="facesurl">$edit_paths_txt{'29'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="facesurl" id="facesurl" size="50" value="$facesurl" />
                    </div>
                    <br />
                    <div class="setting-cell">
                        <label for="modimgurl">$edit_paths_txt{'31'}</label>
                    </div>
                    <div class="setting-cell2">
                        <input type="text" name="modimgurl" id="modimgurl" size="50" value="$modimgurl" />
                    </div>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
            </tr><tr>
                <td class="catbg center">
                    <input type="hidden" name="lastsaved" value="${$uid.$username}{'realname'}" />
                    <input type="hidden" name="lastdate" value="$date" />
                    <input class="button" type="submit" value="$admin_txt{'10'}" />
                </td>
            </tr>
        </table>
    </div>
</form>
~;
    $yytitle     = "$edit_paths_txt{'1'}";
    $action_area = 'editpaths';
    AdminTemplate();
    return;
}

sub EditPaths2 {
    LoadCookie();    # Load the user's cookie (or set to guest)
    LoadUserSettings();
    if ( !$iamadmin ) { fatal_error('no_access'); }

    $lastsaved    = $FORM{'lastsaved'};
    $lastdate     = $FORM{'lastdate'};
    $boardurl     = $FORM{'boardurl'};
    $boarddir     = $FORM{'boarddir'};
    $htmldir      = $FORM{'htmldir'};
    $uploaddir    = $FORM{'uploaddir'};
    $uploadurl    = $FORM{'uploadurl'};
    $pmuploaddir  = $FORM{'pmuploaddir'};
    $pmuploadurl  = $FORM{'pmuploadurl'};
    $yyhtml_root  = $FORM{'yyhtml_root'};
    $datadir      = $FORM{'datadir'};
    $boardsdir    = $FORM{'boardsdir'};
    $memberdir    = $FORM{'memberdir'};
    $sourcedir    = $FORM{'sourcedir'};
    $admindir     = $FORM{'admindir'};
    $vardir       = $FORM{'vardir'};
    $langdir      = $FORM{'langdir'};
    $helpfile     = $FORM{'helpfile'};
    $templatesdir = $FORM{'templatesdir'};
    $facesdir     = $FORM{'facesdir'};
    $facesurl     = $FORM{'facesurl'};
    $modimgdir    = $FORM{'modimgdir'};
    $modimgurl    = $FORM{'modimgurl'};

    my $filler =
q~                                                                               ~;
    my $setfile = << "EOF";
###############################################################################
# Paths.pm                                                                    #
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

\$lastsaved = "$lastsaved";
\$lastdate = "$lastdate";

########## Directories ##########

\$boardurl = "$boardurl";                       # URL of your board's folder (without trailing '/')
\$boarddir = "$boarddir";                       # The server path to the board's folder (usually can be left as '.')
\$boardsdir = "$boardsdir";                     # Directory with board data files
\$datadir = "$datadir";                         # Directory with messages
\$memberdir = "$memberdir";                     # Directory with member files
\$sourcedir = "$sourcedir";                     # Directory with YaBB source files
\$admindir = "$admindir";                       # Directory with YaBB admin source files
\$vardir = "$vardir";                           # Directory with variable files
\$langdir = "$langdir";                         # Directory with Language files and folders
\$helpfile = "$helpfile";                       # Directory with Help files and folders
\$templatesdir = "$templatesdir";               # Directory with template files and folders
\$htmldir = "$htmldir";                         # Base Path for all public-html files and folders
\$facesdir = "$facesdir";                       # Base Path for all avatar files
\$uploaddir = "$uploaddir";                     # Base Path for all attachment files
\$uploaddir = "$uploaddir";                     # Base Path for post attachment files
\$pmuploaddir = "$pmuploaddir";                 # Base Path for pm attachment files
\$modimgdir = "$modimgdir";                       # Base Path for all mod images

########## URLs ##########

\$yyhtml_root = "$yyhtml_root";                       # Base URL for all html/css files and folders
\$facesurl = "$facesurl";                       # Base URL for all avatar files
\$uploadurl = "$uploadurl";                     # Base URL for all attachment files
\$uploadurl = "$uploadurl";                     # Base URL for post attachment files
\$pmuploadurl = "$pmuploadurl";                 # Base URL for pm attachment files
\$modimgurl = "$modimgurl";                     # Base URL for all mod images

1;
EOF

    fopen( FILE, '>Paths.pm' );
    print {FILE} nicely_aligned_file($setfile) or croak "$croak{'print'} FILE";
    fclose(FILE);

    $yySetLocation = qq~$adminurl?action=editpaths~;
    redirectexit();
    return;
}

sub nicely_aligned_file {
    my $filler = q{ } x 70;
        # Make files look nicely aligned. The comment starts after 70 Col

    my $setfile = shift;
    $setfile =~ s/(.+;)[ \t]+(#.+$)/ $1 . substr($filler,(length $1 < 70 ? length $1 : 69)) . $2 /gem;
    $setfile =~ s/\t+(#.+$)/$filler$1/gsm;
    *cut_comment = sub {    # line break of too long comments
        my @x = @_;
        my ( $comment, $length ) =
          ( q{}, 140 );    # 120 Col is the max width of page
        my $var_length = length $x[0];
        while ( $length < $var_length ) { $length += 140; }
        foreach ( split / +/sm, $x[1] ) {
            if ( ( $var_length + length($comment) + length $_ ) > $length ) {
                $comment =~ s/ $//sm;
                $comment .= "\n$filler#  $_ ";
                $length += 140;
            }
            else { $comment .= "$_ "; }
        }
        $comment =~ s/ $//sm;
        return $comment;
    };
    $setfile =~ s/(.+)(#.+$)/ $1 . cut_comment($1,$2) /gem;
    return $setfile;

}

1;
