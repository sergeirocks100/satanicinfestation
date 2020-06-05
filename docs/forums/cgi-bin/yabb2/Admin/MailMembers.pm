###############################################################################
# MailMembers.pm                                                              #
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

$mailmemberspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

if ($iamguest) { fatal_error('no_access'); }

LoadLanguage('Main');
LoadLanguage('MemberList');

$reused = 0;

sub Mailing {
    if ($iamguest) { fatal_error('no_access'); }
    $yymain .= qq~
<div class="rightboxdiv">
    <table class="bordercolor border-space pad-cell">
        <tr>
            <td class="titlebg">
                $admin_img{'register'}<b> $admintxt{'19'}</b>
                <form action="$adminurl?action=mailinggrps" method="post" name="mailgrps" style="display: inline;" accept-charset="$yymycharset">
                    <span style="float: right;">
                    <input type="submit" value="$amv_txt{'53'}" class="button" />
                    </span>
                </form>
            </td>
        </tr>
    </table>
    <script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
    <form name="adv_membermail" action="$adminurl?action=mailing2" method="post" style="display: inline;" onsubmit="return checkIfSelected(); return submitproc();" accept-charset="$yymycharset">
        <div class="windowbg2 border">
            <div class="windowbg2 border" style="float: left; width: 44%; margin: 1%; height:260px">
                <table class="windowbg2 pad-cell" style="width: 98%">
                    <tr>
                        <td><label for="field1"><b>$amv_txt{'40'}:</b><br /><span class="small">$amv_txt{'46'}</span></label></td>
                    </tr><tr>
                        <td>
~;
    my $grpselect;
    my $groupcnt = 0;
    foreach ( sort { $a cmp $b } keys %Group ) {
        if ( $_ ne 'Moderator' ) {
            ( $title, $dummy ) = split /\|/xsm, $Group{$_}, 2;
            $grpselect .= qq~\n<option value="$_"> $title</option>~;
            $groupcnt++;
        }
    }
    foreach (@nopostorder) {
        ( $title, $dummy ) = split /\|/xsm, $NoPost{$_}, 2;
        $grpselect .= qq~\n<option value="$_"> $title</option>~;
        $groupcnt++;
    }
    foreach ( reverse sort { $a <=> $b } keys %Post ) {
        ( $title, $dummy ) = split /\|/xsm, $Post{$_}, 2;
        $grpselect .= qq~\n<option value="$title"> $title</option>~;
        $groupcnt++;
    }
    if ( $groupcnt > 12 ) { $groupcnt = 12; }
    $yymain .= qq~
                            <select name="field1" id="field1" size="$groupcnt" multiple="multiple" style="width: 100%; font-size: 11px;">
                            $grpselect
                            </select>
                            <label for="check_all"><b>$amv_txt{"42a"}: </b></label><input type="checkbox" name="check_all" id="check_all" value="1" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="javascript: if (this.checked) selectCheckAll(true); else selectCheckAll(false);" />
                        </td>
                    </tr>
                </table>
            </div>
~;

    if ( $groupcnt != 0 ) {
        $yymain .= qq~
<div class="windowbg2 border" style="float: left; width: 50%; margin: 1%; height:260px">
    <table class="windowbg2 pad-cell" style="width: 98%">
        <tr>
            <td><label for="emailsubject"><b>$amv_txt{'1'}:</b></label></td>
        </tr><tr>
            <td><input type="text" value="" size="40" name="emailsubject" id="emailsubject" style="width: 100%" /></td>
        </tr><tr>
            <td><label for="emailtext"><b>$amv_txt{'2'}:</b></label></td>
        </tr><tr>
            <td><textarea cols="38" rows="9" name="emailtext" id="emailtext" style="width:100%"></textarea></td>
        </tr><tr>
            <td><span class="small">$amv_txt{'39'}</span></td>
        </tr>
    </table>
        <input type="hidden" name="reused" value="$reused" />
</div>
<div class="windowbg2" style="float: left; width: 44%; margin: 0 1%; border: 0;">
    <table class="windowbg2 pad-cell" style="width: 98%">
        <tr>
            <td class="windowbg2 vtop"><b>$amv_txt{'49'}:</b></td>
        </tr>
    </table>
</div>
<div class="windowbg2" style="float: left; width: 50%; margin: 0 1%; border: 0;">
    <table class="windowbg2 pad-cell" style="width: 98%">
        <tr>
            <td class="windowbg2 vtop"><b>$amv_txt{'47'}:</b></td>
        </tr>
    </table>
</div>
<div class="windowbg2 border" style="float: left; width: 44%; margin: 1%; height:145px">
    <table class="windowbg2 pad-cell" style="width: 98%">
        <tr>
            <td class="windowbg2 vtop">
                <span class="small">$amv_txt{'50'}</span>
            </td>
        </tr><tr>
            <td class="windowbg2 center vtop">
                <input type="submit" name="convert" value="$amv_txt{'49'}" style="width: 100%;" class="button" />
            </td>
        </tr>~;

        if ( -e "$vardir/yabbaddress.csv" ) {
            $yymain .= qq~<tr>
            <td class="windowbg2 center vtop">
                <input type="button" value="$amv_txt{'51'}" class="button" onclick="MailListWin('$adminurl?action=mailing3');" />
            </td>
        </tr>~;
        }

        $yymain .= q~
    </table>
</div>
<script type="text/javascript">
    function MailListWin(FileName,WindowName) {
        WindowFeature="resizable=no,scrollbars=yes,menubar=yes,directories=no,toolbar=no,location=no,status=no,width=400,height=400,screenX=0,screenY=0,top=0,left=0";
        newWindow=open(FileName,WindowName,WindowFeature);
        if (newWindow.opener === null || newWindow.opener === undefined ) { newWindow.opener = self; }
        if (newWindow.focus) { newWindow.focus(); }
    }
</script>
<div class="windowbg2 border" style="float: left; width: 50%; margin: 1%; overflow: auto; height:145px">
    ~;
        if ( -e ("$vardir/maillist.dat") ) {
            fopen( FILE, "$vardir/maillist.dat" );
            @maillist = <FILE>;
            fclose(FILE);
            $yymain .= q~
        <table class="windowbg2 pad-cell" style="width: 98%">
            <colgroup>
                <col span="4" style="width:auto" />
            </colgroup>
~;
            foreach my $curmail (@maillist) {
                chomp $curmail;
                ( $otime, $osubject, $otext, $osender ) = split /\|/xsm,
                  $curmail;
                LoadUser($osender);
                $thetime = timeformat($otime);

                $jsubject = $osubject;
                $jtext = $otext;
                ToJS($jsubject);
                ToJS($jtext);

                $yymain .= qq~<tr>
                <td class="windowbg2">
                    <input type="radio" name="usemail" value="$otime" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="showMail('$jsubject', '$jtext', '$otime');" />
                </td>
                <td class="windowbg2 vtop"><span class="small">$thetime<br />${$uid.$osender}{'realname'}</span></td>
                <td class="windowbg2 vtop"><span class="small">$osubject</span></td>
                <td class="windowbg2"><a href="$adminurl?action=deletemail;delmail=$otime"><img src="$admin_img{'admin_rem'}" alt="del" /></a></td>
            </tr>~;
            }
            $yymain .= q~
            <tr><td class="windowbg2 small" colspan="4">&nbsp;</td></tr>
        </table>
        ~;
        }
        $yymain .= qq~
    </div>

    <div class="windowbg2" style="float: left; width: 44%; margin: 1%; margin-top: 0; border: 0;">
    &nbsp;
    </div>
    <div class="windowbg2" style="float: left; width: 50%; margin: 1%; margin-top: 0; border: 0;">
        <table>
    <tr>
                <td class="center">
        <input type="submit" name="mailsend" value="$amv_txt{'41'}" style="width: 100%;" class="button" />
    </td>
    </tr>
    </table>
    </div>
    <div style="clear: both;"></div>
</div>
</form>

<script type="text/javascript">
function checkIfSelected() {
    for(var x = 0; x < document.adv_membermail.field1.options.length; x++) {
        if(document.adv_membermail.field1.options[x].selected) return true;
        alert("$amv_txt{'48a'}"); return false;
    }
}
function selectCheckAll(tchecked) {
    for(var x = 0; x < document.adv_membermail.field1.options.length; x++) document.adv_membermail.field1.options[x].selected = tchecked;
}

function showMail(thesubject, thetext, thetime) {
    thetext=thetext.replace(/\<br \\/\>/g, "\\n");
    document.adv_membermail.emailsubject.value = thesubject;
    document.adv_membermail.emailtext.value = thetext;
    document.adv_membermail.reused.value = thetime;
}
</script>
</div>
    ~;
    }

    $yytitle = $admin_txt{'6'};
    $action_area = 'mailing';
    AdminTemplate();
    return;
}

sub Mailing2 {
    if ($iamguest) { fatal_error('no_access'); }
    if ( !$FORM{'mailsend'} && !$FORM{'convert'} ) { fatal_error('no_access'); }
    @convlist = ();
    if ( $FORM{'mailsend'} && $FORM{'emailtext'} ne q{} ) {
        $FORM{'emailsubject'} =~ s/\|/&#124;/gsm;
        $FORM{'emailtext'}    =~ s/\|/&#124;/gsm;
        $FORM{'emailtext'}    =~ s/\r//gsm;
        $mailline =
          qq~$date|$FORM{'emailsubject'}|$FORM{'emailtext'}|$username~;
        MailList($mailline);
    }
    (@mailgroups) = split /\, /sm, $FORM{'field1'};
    ManageMemberinfo('load');
    $i = 0;
    my ( $emailsubject, $emailtext );
    foreach my $user ( keys %memberinf ) {
        ( $memrealname, $mememail, $memposition, $memposts, $memaddgrp ) =
          split /\|/xsm, $memberinf{$user};
        FromHTML($memrealname);

        if ( $FORM{'mailsend'} && $FORM{'emailtext'} ne q{} ) {
            $emailsubject = $FORM{'emailsubject'};
            $emailsubject =~ s/\[name\]/$memrealname/igxsm;
            $emailsubject =~ s/\[username\]/$user/igxsm;
            $emailtext = $FORM{'emailtext'};
            $emailtext =~ s/\[name\]/$memrealname/igxsm;
            $emailtext =~ s/\[username\]/$user/igxsm;
        }

        $mailit = 0;
        foreach my $element (@mailgroups) {
            chomp $element;
            if ( $element eq $memposition ) { $mailit = 1; }
            foreach my $memberaddgroups ( split /, /sm, $memaddgrp ) {
                chomp $memberaddgroups;
                if ( $element eq $memberaddgroups ) { $mailit = 1; last; }
            }
            if ($mailit) { last; }
        }
        if ( $mailit && $FORM{'mailsend'} ) {
            require Sources::Mailer;
            sendmail( $mememail, $emailsubject, $emailtext );
        }
        elsif ( $mailit && $FORM{'convert'} ) {
            if ( $memrealname =~ /&#(\d{3,}?)\;/igxsm ) { $memrealname = $user; }
            $convlist[$i] = qq~$memrealname\;$mememail\n~;
            $i++;
        }
    }
    undef %memberinf;
    if (@convlist) {
        fopen( ADDRESSLIST, ">$vardir/yabbaddress.csv", 1 );
        print {ADDRESSLIST} "Name\;E-mail Address\n"
          or croak "$croak{'print'} ADDRESSLIST";
        print {ADDRESSLIST} @convlist or croak "$croak{'print'} ADDRESSLIST";
        fclose(ADDRESSLIST);
    }
    elsif ( $FORM{'convert'} ) {
        unlink "$vardir/yabbaddress.csv";
    }

    $yySetLocation = qq~$adminurl?action=mailing~;
    redirectexit();
    return;
}

sub Mailing3 {
    fopen( FILE, "$vardir/yabbaddress.csv" );
    @addlist = <FILE>;
    fclose(FILE);
    print qq~Content-disposition: inline; filename=yabbaddress.csv\n\n~ or croak "$croak{'print'} yabbaddress";
    foreach my $curadd (@addlist) {
        chomp $curadd;
        print qq~$curadd\n~ or croak "$croak{'print'} yabbaddress";
    }
    return;
}

sub MailingMembers {
    $sortmode = q{};
    $selPos   = q{};
    $selUser  = q{};

    if ( $FORM{'sortform'} eq 'position' ) {
        $selPos = q~ selected="selected"~;
    }
    else { $selUser = q~ selected="selected"~; }

    if ( $INFO{'sort'} ne q{} ) { $sortmode = ';sort=' . $INFO{'sort'}; }
    elsif ( $FORM{'sortform'} ne q{} ) {
        $sortmode = ';sort=' . $FORM{'sortform'};
    }

    if ($iamguest) { fatal_error('no_access'); }
    $yymain .= qq~
<div class="rightboxdiv">
    <table class="bordercolor border-space pad-cell">
    <tr>
            <td class="titlebg">
        <span style="float: left;">
             $admin_img{'register'}<b> $admintxt{'19'}</b>
        </span>
                <form action="$adminurl?action=mailinggrps" method="post" name="selsort" style="display: inline" accept-charset="$yymycharset">
        <span style="float: right;">
        <label for="sortform"><b>$ml_txt{'1'}</b></label>
        <select name="sortform" id="sortform" style="font-size: 9pt;" onchange="submit()">
            <option value="username"$selUser>$ml_txt{'35'}</option>
            <option value="position"$selPos>$ml_txt{'87'}</option>
        </select>
        &nbsp;
        <input type="button" value="$amv_txt{'54'}" class="button" onclick="window.location.href=\'$adminurl?action=mailing\'" />
        </span>
        </form>
        </td>
    </tr>
    </table>
    <script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
    <form name="adv_membermail" action="$adminurl?action=mailmultimembers;$sortmode" method="post" style="display: inline" onsubmit="return checkIfChecked(this); return submitproc()" accept-charset="$yymycharset">
    <input type="hidden" name="button" value="1" />
    <div class="windowbg2 border">
        <div class="windowbg border" style="float: left; width: 44%; margin: 1%; overflow: auto; height:260px">
            <table class="windowbg pad-cell" style="width:98%">
    ~;

    %TopMembers = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        ( $memberrealname, undef, $memposition, $memposts ) = split /\|/xsm,
          $value;
        $pstsort    = 99_999_999 - $memposts;
        $sortgroups = q{};
        $j          = 0;

        if ( $membername eq $username ) {
            $sortgroups = '!!!';
        }
        else {
            if (   $FORM{'sortform'} eq 'position'
                || $INFO{'sort'} eq 'position' )
            {
                foreach my $key ( keys %Group ) {
                    if ( $memposition eq $key ) {
                        if ( $key eq 'Administrator' ) {
                            $sortgroups = "aaa.$pstsort.$memberrealname";
                        }
                        elsif ( $key eq 'Global Moderator' ) {
                            $sortgroups = "bbb.$pstsort.$memberrealname";
                        }
                        elsif ( $key eq 'Mid Moderator' ) {
                            $sortgroups = "bcc.$pstsort.$memberrealname";
                        }
                    }
                }
                if ( !$sortgroups ) {
                    foreach ( sort { $a <=> $b } keys %NoPost ) {
                        if ( $memposition eq $_ ) {
                            $sortgroups =
                              "ddd.$memposition.$pstsort.$memberrealname";
                        }
                    }
                }
                if ( !$sortgroups ) {
                    $sortgroups = "eee.$pstsort.$memposition.$memberrealname";
                }

            }
            else {
                $sortgroups = $memberrealname;
            }
        }
        $TopMembers{$membername} = $sortgroups;
    }
    my @toplist =
      sort { lc $TopMembers{$a} cmp lc $TopMembers{$b} } keys %TopMembers;

    $memcount = @toplist;

    $bb        = 0;
    $numshown  = 0;
    $actualnum = 0;

    while ( ( $numshown < $memcount ) ) {
        $user = $toplist[$bb];

        ( $memrealname, $mememail, $memposition, $memposts ) = split /\|/xsm,
          $memberinf{$user};

        if   ( $user eq $username ) { $bagcolor = 'windowbg2'; }
        else                        { $bagcolor = 'windowbg'; }
        if ( $memrealname ne q{} ) {
            $addel =
qq~<input type="checkbox" name="member$actualnum" value="$user" class="windowbg" style="border: 0;" />~;
            $actualnum++;

            my $memberinfo = "$memposition";
            if ( $memberinfo eq 'Administrator' ) {
                ( $memberinfo, undef ) = split /\|/xsm, $Group{'Administrator'},
                  2;
            }
            elsif ( $memberinfo eq 'Global Moderator' ) {
                ( $memberinfo, undef ) = split /\|/xsm,
                  $Group{'Global Moderator'}, 2;
            }
            elsif ( $memberinfo eq 'Mid Moderator' ) {
                ( $memberinfo, undef ) = split /\|/xsm,
                  $Group{'Mid Moderator'}, 2;
            }
            else {
                foreach my $key ( sort { $a <=> $b } keys %NoPost ) {
                    if ( $key eq $memberinfo ) {
                        ( $memberinfo, undef ) = split /\|/xsm, $NoPost{$key},
                          2;
                    }
                }
            }

            $viewmembinfo = $memberinfo;
            ToJS($memberinfo);
            $tmp_postcount = $memposts;
            $checkinfo     = $memberinfo;
            $checkinfo =~ s/\, /\'\|\'/gsm;
            $CheckingAll .= qq~"'$checkinfo'", ~;

            if   ($do_scramble_id) { $cloakusername = cloak($user); }
            else                   { $cloakusername = $user; }
            ToChars($memrealname);
            $linkuser =
qq~<a href="$scripturl?action=viewprofile;username=$cloakusername"><b>$memrealname</b></a>~;

            $yymain .= qq~<tr>
                <td class="$bagcolor center">$addel</td>
                <td class="$bagcolor">$linkuser - $viewmembinfo</td>
            </tr>~;
        }

        $numshown++;
        $bb++;
    }
    undef @toplist;
    undef %memberinf;

    $yymain .= q~
    </table>
    </div>
    ~;

    if ( $memcount != 0 ) {
        if ( $FORM{'sortform'} eq q{} ) { $FORM{'sortform'} = $INFO{'sort'}; }
        if ( !$FORM{'reversed'} ) { $FORM{'reversed'} = $INFO{'reversed'}; }

        @groupinfo = ();
        $i         = 0;
        $z         = 0;

        ( $title, $dummy ) = split /\|/xsm, $Group{'Administrator'}, 2;
        ToJS($title);
        $groupinfo[$i] = $title;
        $i++;
        $grp_data = qq~"'$title'", ~;

        ( $title, $dummy ) = split /\|/xsm, $Group{'Global Moderator'}, 2;
        ToJS($title);
        $groupinfo[$i] = $title;
        $i++;
        $grp_data .= qq~"'$title'", ~;

        ( $title, $dummy ) = split /\|/xsm, $Group{'Mid Moderator'}, 2;
        ToJS($title);
        $groupinfo[$i] = $title;
        $i++;
        $grp_data .= qq~"'$title'", ~;

        foreach (@nopostorder) {
            ( $title, $dummy ) = split /\|/xsm, $NoPost{$_}, 2;
            ToJS($title);
            $groupinfo[$i] = $title;
            $grp_data .= qq~"'$title'", ~;
            $i++;
            $z++;
        }

        $groupcnt = $i;
        $grp_data .= q~""~;

        $yymain .= qq~
    <div class="windowbg2 border padd-cell" style="float: left; width: 50%; margin: 1%; height:260px">
        <table class="windowbg2 pad-cell">
        <tr>
               <td><label for="emailsubject"><b>$amv_txt{'1'}:</b></label></td>
            </tr><tr>
                <td><input type="text" value="" size="40" name="emailsubject" id="emailsubject" style="width: 100%" /></td>
            </tr><tr>
                <td><label for="emailtext"><b>$amv_txt{'2'}:</b></label></td>
            </tr><tr>
                <td><textarea cols="38" rows="9" name="emailtext" id="emailtext" style="width:100%"></textarea></td>
            </tr><tr>
                <td><span class="small">$amv_txt{'39'}</span></td>
        </tr>
    </table>
        <input type="hidden" name="reused" value="$reused" />
    </div>

    <div class="windowbg2" style="float: left; width: 44%; margin: 0 1% 1% 1%; border: 0;">
        <table class="windowbg2 pad-cell">
        <tr>
            <td class="windowbg2 vtop" style="white-space: nowrap;"><label for="check_all"><b>$amv_txt{'42'}:</b></label></td>
            <td class="windowbg2 vtop"><input type="checkbox" name="check_all" id="check_all" value="1" class="windowbg2" style="border: 0;" onclick="javascript: if (this.checked) selectCheckAllmemb(true); else selectCheckAllmemb(false);" /></td>
        </tr><tr>
            <td class="windowbg2 vtop" style="white-space: nowrap;"><label for="field1"><b>$amv_txt{'40'}:</b></label></td>
            <td class="windowbg2 vtop">
        <label for="field1"><span class="small">$amv_txt{'46'}</span></label><br />
        <select name="field1" id="field1" size="$groupcnt" multiple="multiple" onchange="selectCheck()">~;

        $i = 0;
        while ( $i < $groupcnt ) {
            $yymain .= qq~
            <option value="$i">$groupinfo[$i]</option>~;
            $i++;
        }

        $yymain .= qq~
        </select>
    </td>
    </tr>
    </table>
    </div>
    <div class="windowbg2" style="float: left; width: 50%; margin: 0 1%; border: 0;">
        <table class="windowbg2 pad-cell">
            <tr>
                <td class="windowbg2 vtop"><b>$amv_txt{'47'}:</b></td>
            </tr>
    </table>
    </div>
    <div class="windowbg2 border" style="float: left; width: 50%; margin: 1%; overflow: auto; height:115px">
    ~;
        if ( -e ("$vardir/maillist.dat") ) {
            fopen( FILE, "$vardir/maillist.dat" );
            @maillist = <FILE>;
            fclose(FILE);
            $yymain .= q~
        <table class="windowbg2 pad-cell" style="width: 98%">
            <colgroup>
                <col span="4" style="width:auto" />
            </colgroup>
        ~;
            foreach my $curmail (@maillist) {
                chomp $curmail;
                ( $otime, $osubject, $otext, $osender ) = split /\|/xsm,
                  $curmail;
                LoadUser($osender);
                $thetime = timeformat($otime);

                $jsubject = $osubject;
                $jtext    = $otext;
                ToJS($jsubject);
                ToJS($jtext);

                $yymain .= qq~<tr>
                <td class="windowbg2">
                    <input type="radio" name="usemail" value="$otime" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="showMailmemb('$jsubject', '$jtext', '$otime');" />
                </td>
                <td class="windowbg2 vtop"><span class="small">$thetime<br />${$uid.$osender}{'realname'}</span></td>
                <td class="windowbg2 vtop"><span class="small">$osubject</span></td>
                <td class="windowbg2"><a href="$adminurl?action=deletemail;delmail=$otime"><img src="$admin_img{'admin_rem'}" alt="del" /></a></td>
            </tr>~;
            }
            $yymain .= q~
            <tr><td class="windowbg2 small" colspan="4">&nbsp;</td></tr>
        </table>
        ~;
        }
        $yymain .= qq~
    </div>
    <div class="windowbg2" style="float: left; width: 44%; margin: 0 1% 1% 1%; border: 0;">
        <table>
            <tr>
                <td class="center">&nbsp;</td>
            </tr>
    </table>
    </div>
    <div class="windowbg2" style="float: left; width: 50%; margin: 0 1% 1% 1%; border: 0;">
        <table>
            <tr>
                <td class="center">
                    <input type="submit" name="mailsend" value="$amv_txt{'41'}" style="width: 100%;" class="button" />
                </td>
            </tr>
        </table>
    </div>
    <div style="clear: both;"></div>
</div>
</form>
<script  type="text/javascript">
mem_data = new Array ( $CheckingAll"" );
group_data = new Array ( $grp_data );

function selectCheckAllmemb(tchecked) {
    for(var x = 0; x < document.adv_membermail.field1.options.length; x++) document.adv_membermail.field1.options[x].selected = tchecked;
    for(var i = 1; i <= $actualnum; i++) document.adv_membermail.elements[i].checked = tchecked;
}

function selectCheck() {
    var z = 1;
    var grpcnt = 0;
    grp_data = new Array ();

    for(x = 0; x < document.adv_membermail.field1.options.length; x++) {
        if (document.adv_membermail.field1.options[x].selected) {
            grp_data[grpcnt] = group_data[document.adv_membermail.field1.options[x].value];
            grpcnt++;
        }
    }

    if (grpcnt < document.adv_membermail.field1.options.length) { document.adv_membermail.check_all.checked = false; }

    for (var i = 0; i < $actualnum; i++) {
        var check = 0;
        for(x = 0; x < grpcnt; x++) {
            var limit = grp_data[x];
            var value = mem_data[i].split("|");
            var j = 0;
            while(value[j]) {
                if (value[j] == limit) { check = 1; x = grpcnt; }
                j++;
            }
        }
        if (check == 1) {document.adv_membermail.elements[z].checked = true;}
        else {document.adv_membermail.elements[z].checked = false;}
        z++;
    }
}

function checkIfChecked(theForm) {
    var nonechecked = true;
    for(var i = 1; i <= $actualnum; i++) {
        if (document.adv_membermail.elements[i].checked) nonechecked = false;
    }
    if (nonechecked) { alert("$amv_txt{'48'}"); return false; }
    return true;
}

function showMailmemb(thesubject, thetext, thetime) {
    thetext=thetext.replace(/\<br \\/\>/g, "\\n");
    document.adv_membermail.emailsubject.value = thesubject;
    document.adv_membermail.emailtext.value = thetext;
    document.adv_membermail.reused.value = thetime;
}
</script>
</div>
    ~;
    }

    $yytitle     = "$admin_txt{'6'}";
    $action_area = 'mailing';
    AdminTemplate();
    return;
}

sub ToJS {
    $_[0] =~ s/;/&#059;/gsm;
    $_[0] =~ s/\!/&#33;/gsm;
    $_[0] =~ s/\(/&#40;/gsm;
    $_[0] =~ s/\)/&#41;/gsm;
    $_[0] =~ s/\-/&#45;/gsm;
    $_[0] =~ s/\./&#46;/gsm;
    $_[0] =~ s/\:/&#58;/gsm;
    $_[0] =~ s/\?/&#63;/gsm;
    $_[0] =~ s/\[/&#91;/gsm;
    $_[0] =~ s~\\~&#92;&#92;~gsm;
    $_[0] =~ s/\]/&#93;/gsm;
    $_[0] =~ s/\^/&#94;/gsm;
    $_[0] =~ s/\"/&#34;/gsm;
    $_[0] =~ s/\'/&#96;/gsm;
    $_[0] =~ s/\</&#60;/gsm;
    $_[0] =~ s/\>/&#62;/gsm;
}

1;