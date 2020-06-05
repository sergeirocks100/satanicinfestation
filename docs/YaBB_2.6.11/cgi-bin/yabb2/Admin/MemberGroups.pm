###############################################################################
# MemberGroups.pm                                                             #
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

$membergroupspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

$admin_images = "$yyhtml_root/Templates/Admin/default";

sub EditMemberGroups {
    is_admin_or_gmod();

#            (
#                $title,     $stars,       $starpic,    $color,
#                $noshow,    $viewperms,   $topicperms, $replyperms,
#                $pollperms, $attachperms, $additional
#            )

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'guest'}&nbsp;<b>$admin_txt{'8'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$admin_txt{'11'}</div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <colgroup>
            <col style="width: 25%" />
            <col style="width: 15%" />
            <col style="width: 10%" />
            <col style="width: 25%" />
            <col style="width: 10%" />
            <col style="width: 15%" />
        </colgroup>
        <tr>
            <td class="titlebg" colspan="6">
                $admin_img{'guest'}&nbsp;<b>$admin_txt{'12'}</b>
            </td>
        </tr><tr>
            <td class="catbg center"><b>$amgtxt{'03'}</b></td>
            <td class="catbg center"><b>$amgtxt{'19'}</b></td>
            <td class="catbg center"><b>$amgtxt{'08'}</b></td>
            <td class="catbg center"><b>$amgtxt{'01'}</b></td>
            <td class="catbg center"><b>$admin_txt{'53'}</b></td>
            <td class="catbg center"><b>&nbsp;</b></td>~;
    my @grps = sort keys %Group;
    my @memstats = ();
    for ( @grps ) {
        @memstats = split /\|/xsm, $Group{$_};
        $memstats[4] = ( $memstats[4] == 1 ) ? "$admin_txt{'164'}" : "$admin_txt{'163'}";
        $yymain .= qq~
        </tr><tr>
            <td class="windowbg2 center">$memstats[0]</td>
            <td class="windowbg2 center"><img src="$imagesdir/$memstats[2]" alt="" /> x $memstats[1]</td>~;

    if ( $memstats[3] ) {
        $thecolname = hextoname($memstats[3]);
        $yymain .= qq~
            <td class="windowbg2 center"><span style="color:$memstats[3]">$thecolname</span></td>~;
    }
    else {
        $yymain .= q~
            <td class="windowbg2 center">&nbsp;</td>~;
    }
	$mgrp = $_;
	$mgrp =~ s/\ /%20/gsm;
    $yymain .= qq~
            <td class="windowbg2 center">$memstats[4]</td>
            <td class="windowbg2 center"><a href="$adminurl?action=editgroup;group=$mgrp">$admin_txt{'53'}</a></td>
            <td class="windowbg2 center">&nbsp;</td>~;
    }
    $yymain .= q~
        </tr>
    </table>
</div>
~;

    my $colspan = 6;
    my $colgroup = q~<colgroup>
            <col  style="width: 25%" />
            <col  style="width: 15%" />
            <col  style="width: 10%" />
            <col  style="width: 25%" />
            <col  style="width: 10%" />
            <col  style="width: 15%" />
        </colgroup>
~;

    if ( $addmemgroup_enabled > 0 ) {
        $additional_tablehead =
          qq~<td class="catbg center"><b>$amgtxt{'83'}</b></td>~;
        $colspan = 7;
        $colgroup = q~<colgroup>
            <col style="width: 25%" />
            <col  style="width: 15%" />
            <col  style="width: 10%" />
            <col  style="width: 20%" />
            <col  style="width: 15%" />
            <col  style="width: 5%" />
            <col  style="width: 10%" />
        </colgroup>
~;    }
    my $reorderlink = q{};
    if ($#nopostorder) {
        $reorderlink =
qq~ | <a href="$adminurl?action=reordergroup">$admintxt{'reordergroups'}</a>~;
    }

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        $colgroup
        <tr>
            <td class="titlebg" colspan="$colspan">
                $admin_img{'guest'}&nbsp;<b>$amgtxt{'37'} (<a href="$adminurl?action=editgroup">$admintxt{'18c'}</a>$reorderlink)</b>
            </td>
        </tr><tr>
            <td class="catbg center"><b>$amgtxt{'03'}</b></td>
            <td class="catbg center"><b>$amgtxt{'19'}</b></td>
            <td class="catbg center"><b>$amgtxt{'08'}</b></td>
            <td class="catbg center"><b>$amgtxt{'01'}</b></td>
            $additional_tablehead
            <td class="catbg center"><b>$admin_txt{'53'}</b></td>
            <td class="catbg center"><b>$admin_txt{'54'}</b></td>
        </tr>~;

    $count = 0;
    for (@nopostorder) {
        @memstats = split /\|/xsm, $NoPost{$_};
        $memstats[4] = ( $memstats[4] == 1 ) ? "$admin_txt{'164'}" : "$admin_txt{'163'}";
        $memstats[10] =
          ( $memstats[10] == 0 ) ? "$admin_txt{'164'}" : "$admin_txt{'163'}";
        if ( !$stars ) { $stars = 0; }
        $yymain .= qq~<tr>
            <td class="windowbg2 center">$memstats[0]</td>
            <td class="windowbg2 center"><img src="$imagesdir/$memstats[2]" alt="" /> x $memstats[1]</td>~;

        if ($memstats[3]) {
            $thecolname = hextoname($memstats[3]);
            $yymain .= qq~
            <td class="windowbg2 center"><span style="color:$memstats[3]">$thecolname</span></td>~;
        }
        else {
            $yymain .= q~
            <td class="windowbg2 center">&nbsp;</td>~;
        }

        $yymain .= qq~
            <td class="windowbg2 center">$memstats[4]</td>~;

        if ( $addmemgroup_enabled > 0 ) {
            $yymain .= qq~
            <td class="windowbg2 center">$memstats[10]</td>~;
        }

        $yymain .= qq~
            <td class="windowbg2 center"><a href="$adminurl?action=editgroup;group=NP|$_">$admin_txt{'53'}</a></td>
            <td class="windowbg2 center"><a href="$adminurl?action=delgroup;group=NP|$_">$admin_txt{'54'}</a></td>
        </tr>~;
        $count++;
    }

    if ( $count == 0 ) {
        $yymain .= qq~<tr>
            <td class="windowbg2 center" colspan="6">$amgtxt{'35'}</td>
        </tr>~;
    }

    $yymain .= qq~
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <colgroup>
            <col style="width: 25%" />
            <col style="width: 15%" />
            <col style="width: 10%" />
            <col style="width: 25%" />
            <col style="width: 10%" />
            <col style="width: 15%" />
        </colgroup>
        <tr>
            <td class="titlebg" colspan="6">
                $admin_img{'guest'}&nbsp;<b>$amgtxt{'40'}&nbsp;(<a href="$adminurl?action=editgroup1">$admintxt{'18c'}</a>)</b>
            </td>
        </tr><tr>
            <td class="catbg center"><b>$amgtxt{'03'}</b></td>
            <td class="catbg center"><b>$amgtxt{'19'}</b></td>
            <td class="catbg center"><b>$amgtxt{'08'}</b></td>
            <td class="catbg center"><b>$admin_txt{'21'}</b></td>
            <td class="catbg center"><b>$admin_txt{'53'}</b></td>
            <td class="catbg center"><b>$admin_txt{'54'}</b></td>
        </tr>~;

    my $count = 0;
    for ( reverse sort { $a <=> $b } keys %Post ) {
        @memstats = split /\|/xsm, $Post{$_};
        $memstats[4] = ( $memstats[4] == 1 ) ? "$admin_txt{'164'}" : "$admin_txt{'163'}";
        if ( !$memstats[1] )             { $memstats[1]   = 0; }
        if ( $memstats[2] !~ /\//xsm ) { $memstats[2] = "$imagesdir/$memstats[2]"; }
        $yymain .= qq~<tr>
            <td class="windowbg2 center">$memstats[0]</td>
            <td class="windowbg2 center"><img src="$memstats[2]" alt="" /> x $memstats[1]</td>~;

        if ($memstats[3]) {
            $thecolname = hextoname($memstats[3]);
            $yymain .= qq~
            <td class="windowbg2 center"><span style="color: $memstats[3];">$thecolname</span></td>~;
        }
        else {
            $yymain .= q~
            <td class="windowbg2 center">&nbsp;</td>~;
        }

        $yymain .= qq~
            <td class="windowbg2 center">$_</td>
            <td class="windowbg2 center"><a href="$adminurl?action=editgroup;group=P|$_">$admin_txt{'53'}</a></td>
            <td class="windowbg2 center"><a href="$adminurl?action=delgroup;group=P|$_">$admin_txt{'54'}</a></td>
        </tr>~;
        $count++;
    }

    if ( $count == 0 ) {
        $yymain .= qq~<tr>
            <td class="windowbg2" colspan="6">$amgtxt{'36'}</td>
        </tr>~;
    }
    $yymain .= q~
    </table>
</div>
~;

    $yytitle     = $admin_txt{'8'};
    $action_area = 'modmemgr';

    AdminTemplate();
    return;
}

sub hextoname {
    ($colorname) = @_;
    $colorname =~ s/aqua|#00FFFF/$amgtxt{'56'}/ism;
    $colorname =~ s/black|#000000/$amgtxt{'57'}/ism;
    $colorname =~ s/blue|#0000FF/$amgtxt{'58'}/ism;
    $colorname =~ s/fuchsia|#FF00FF/$amgtxt{'59'}/ism;
    $colorname =~ s/gray|#808080/$amgtxt{'60'}/ism;
    $colorname =~ s/green|#008000/$amgtxt{'61'}/ism;
    $colorname =~ s/lime|#00FF00/$amgtxt{'62'}/ism;
    $colorname =~ s/maroon|#800000/$amgtxt{'63'}/ism;
    $colorname =~ s/navy|#000080/$amgtxt{'64'}/ism;
    $colorname =~ s/olive|#808000/$amgtxt{'65'}/ism;
    $colorname =~ s/purple|#800080/$amgtxt{'66'}/ism;
    $colorname =~ s/red|#FF0000/$amgtxt{'67'}/ism;
    $colorname =~ s/silver|#C0C0C0/$amgtxt{'68'}/ism;
    $colorname =~ s/teal|#008080/$amgtxt{'69'}/ism;
    $colorname =~ s/white|#FFFFFF/$amgtxt{'70'}/ism;
    $colorname =~ s/yellow|#FFFF00/$amgtxt{'71'}/ism;
    $colorname =~ s/#DEB887/$amgtxt{'75'}/ism;
    $colorname =~ s/#FFD700/$amgtxt{'76'}/ism;
    $colorname =~ s/#FFA500/$amgtxt{'77'}/ism;
    $colorname =~ s/#A0522D/$amgtxt{'78'}/ism;
    $colorname =~ s/#87CEEB/$amgtxt{'79'}/ism;
    $colorname =~ s/#6A5ACD/$amgtxt{'80'}/ism;
    $colorname =~ s/#4682B4/$amgtxt{'81'}/ism;
    $colorname =~ s/#9ACD32/$amgtxt{'82'}/ism;
    return $colorname;
}

sub editAddGroup {
    is_admin_or_gmod();
    my @memstats = ();
    if ( $INFO{'group'} ) {
        $viewtitle = $admintxt{'18a'};
        ( $type, $element ) = split /\|/xsm, $INFO{'group'};
        if ( $element ne q{} ) {
            if ( $type eq 'P' ) {
                $posts = $element;
                @memstats = split /\|/xsm, $Post{$element};
            }
            else {
                $noposts   = $element;
                $choosable = 1;
                @memstats = split /\|/xsm, $NoPost{$element};
            }
        }
        else {
            @memstats = split /\|/xsm, $Group{ $INFO{'group'} };
        }
    }
    else {
        $viewtitle = $admintxt{'18b'};
        $memstats[0]    = q{};
        $memstats[1]    = q{};
        $memstats[2]    = q{};
        $memstats[3]     = q{};
        $posts     = q{};
        $noposts   = 1;
        for ( sort { $a <=> $b } keys %NoPost ) {
            $noposts = $_ + 1;
        }
    }

    if ( $stars !~ /\A[0-9]+\Z/xsm ) { $stars = 0; }

    $otherdisable = q~ disabled="disabled"~;

    # Get star selected if needed.
    my @starsgif = (
        q{},            'staradmin.png',  'stargmod.png', 'starfmod.png', 'starmod.png',
        'starblue.png', 'starsilver.png', 'stargold.png',
    );
    my @starstxt = ( q{}, "$amgtxt{'20'}","$amgtxt{'21'}","$amgtxt{'21a'}","$amgtxt{'22'}",
        "$amgtxt{'23'}","$amgtxt{'24'}","$amgtxt{'25'}",
    );
    my @stara = ();
    $pick         = $memstats[2];
    $otherdisable = q{};
    my $stsel = 0;
    foreach my $i ( 1 .. 7 ) {
        if ( $memstats[2] eq $starsgif[$i] ) {
            $stara[$i] = q{ selected="selected"};
            $stsel++;
        }
    }
    if ( $stsel == 0 ) {
        $stara[8] = q{ selected="selected"};
    }
    my $starurl =
        ( $memstats[2] !~ m{http://}xsm ? "$imagesdir/" : q{} )
      . ( $memstats[2]                  ? $memstats[2]      : 'blank.gif' );

    $memstats[3] =~ s/\#//gxsm;

    $pc = q~ checked="checked"~;
    $pd = q{};
    $pt = q{};

    if ($memstats[4])     { $pc   = q{}; }
    if ($memstats[10]) { $admg = q~ checked="checked"~; }

    if ( $posts eq q{} && $action ne 'editgroup1' ) {
        $post2 = q{ checked="checked"};
        $pt    = q{ disabled="disabled"};
    }
    else { $post1 = q~ checked="checked"~; $pd = q~ disabled="disabled"~; }

    if ( $memstats[5] == 1 ) { $vc  = q~ checked="checked"~; }
    if ( $memstats[6] == 1 ) { $tc  = q~ checked="checked"~; }
    if ( $memstats[7] == 1 ) { $rc  = q~ checked="checked"~; }
    if ( $memstats[8] == 1 ) { $poc = q~ checked="checked"~; }
    if ( $memstats[9] == 1 ) { $ac  = q~ checked="checked"~; }

    $yymain .= qq~
<form name="groups" action="$adminurl?action=editAddGroup2" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
<input type="hidden" name="original" value="$INFO{'group'}" />
<input type="hidden" name="origin" value="$action" />

<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width:40%" />
        <col style="width:60%" />
    </colgroup>
    <tr>
        <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$viewtitle</b></td>
    </tr><tr>
        <td class="windowbg"><label for="title">$amgtxt{'51'}:</label></td>
        <td class="windowbg2"><input type="text" name="title" id="title" value="$memstats[0]" /></td>
    </tr><tr>
        <td class="windowbg"><label for="numstars">$amgtxt{'05'}</label></td>
        <td class="windowbg2"><input type="text" name="numstars" id="numstars" size="2" value="$memstats[1]" /></td>
    </tr><tr>
        <td class="windowbg"><label for="starsadmin">$amgtxt{'38'}:</label></td>
        <td class="windowbg2">
            <select name="starsadmin" id="starsadmin" onchange="stars(this.value); showimage();">~;
    for my $i ( 1 .. 7 ) {
            $yymain .= qq~                <option value="$starsgif[$i]"$stara[$i]>$starstxt[$i]</option>\n~;
    }
    $yymain .= qq~                <option value="other"$stara[8]>$amgtxt{'26'}</option>
            </select>
            &nbsp;
            <label for="otherstar"><b>$amgtxt{'26'}</b></label> <input type="file" name="otherstar" id="otherstar" size="35"$otherdisable /><input type="hidden" name="cur_otherstar" value="$pick" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('otherstar').value='';">X</span>
            &nbsp;
            <img src="$starurl" id="starpic" alt="" />
        </td>
    </tr><tr>
        <td class="windowbg"><label for="color">$amgtxt{'08'}:</label></td>
        <td class="windowbg2" >
            <select name="color" id="color" onchange="viscolor(this.options[this.selectedIndex].value);">
            <option value="">--</option>
            <option value="00FFFF">$amgtxt{'56'}</option>
            <option value="000000">$amgtxt{'57'}</option>
            <option value="0000FF">$amgtxt{'58'}</option>
            <option value="FF00FF">$amgtxt{'59'}</option>
            <option value="808080">$amgtxt{'60'}</option>
            <option value="008000">$amgtxt{'61'}</option>
            <option value="00FF00">$amgtxt{'62'}</option>
            <option value="800000">$amgtxt{'63'}</option>
            <option value="000080">$amgtxt{'64'}</option>
            <option value="808000">$amgtxt{'65'}</option>
            <option value="800080">$amgtxt{'66'}</option>
            <option value="FF0000">$amgtxt{'67'}</option>
            <option value="C0C0C0">$amgtxt{'68'}</option>
            <option value="008080">$amgtxt{'69'}</option>
            <option value="FFFFFF">$amgtxt{'70'}</option>
            <option value="FFFF00">$amgtxt{'71'}</option>
            <option value="DEB887">$amgtxt{'75'}</option>
            <option value="FFD700">$amgtxt{'76'}</option>
            <option value="FFA500">$amgtxt{'77'}</option>
            <option value="A0522D">$amgtxt{'78'}</option>
            <option value="87CEEB">$amgtxt{'79'}</option>
            <option value="6A5ACD">$amgtxt{'80'}</option>
            <option value="4682B4">$amgtxt{'81'}</option>
            <option value="9ACD32">$amgtxt{'82'}</option>
            </select> &nbsp;
            <span id="grpcolor"~
      . ( $memstats[3] ne q{} ? qq* style="color: #$memstats[3];"* : q{} )
      . qq~><label for="color2"><b>$amgtxt{'08'}</b></label></span>
            #<input type="text" name="color2" id="color2" size="6" value="$memstats[3]" maxlength="6" onkeyup="viscolor(this.value);" /> &nbsp;
            <img src="$admin_images/palette1.gif" style="cursor: pointer; vertical-align:top" onclick="window.open('$scripturl?action=palette;task=templ', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" />
        </td>
    </tr>~;

    # Get color selected
    $yymain =~ s/(<option value="$memstats[3]")/$1 selected="selected"/sm;

    if ( !exists $Group{ $INFO{'group'} } ) {
        $yymain .= qq~<tr>
        <td class="windowbg"><label for="postindepend">$amgtxt{'39a'}</label></td>
        <td class="windowbg2">
            <input type="radio" name="postdepend" id="postindepend" value="No" $post2 class="windowbg2" style="border: 0; vertical-align: middle;" onclick="depend(this.value)" />
            <br />
            <label for="viewpublic"><b>$amgtxt{'42'}?</b>
            <input type="checkbox" name="viewpublic" id="viewpublic" value="1"$pc$pd style="vertical-align: middle;" /> <br />$amgtxt{'43'}</label>
            <input type="hidden" name="noposts" id="noposts" value="$noposts" />
        </td>
    </tr><tr>
        <td class="windowbg"><label for="postdepend">$amgtxt{'39'}</label></td>
        <td class="windowbg2">
            <input type="radio" name="postdepend" id="postdepend" value="Yes" $post1 class="windowbg2" style="border: 0; vertical-align: middle;" onclick="depend(this.value)" />
            <br />
            <label for="posts"><b>$amgtxt{'04'}</b></label> <input type="text" name="posts" id="posts" size="5" value="$posts"$pt style="vertical-align: middle;" />
        </td>
    </tr>~;
    }
    else {
        $yymain .= qq~<tr>
        <td class="windowbg"><label for="viewpublic"><b>$amgtxt{'42'}</b> <br /><b>$amgtxt{'43'}</b></label></td>
        <td class="windowbg2">
            <input type="checkbox" name="viewpublic" id="viewpublic" value="1"$pc$pd style="vertical-align: middle;" />
        </td>
    </tr>~;
    }

    if ( $addmemgroup_enabled > 0 ) {
        if ( $choosable
            || ( !$choosable && $action ne 'editgroup1' && !$INFO{'group'} ) )
        {
            $yymain .= qq~<tr>
        <td class="windowbg"><label for="additional">$amgtxt{'83'}</label></td>
        <td class="windowbg2">
            <input type="checkbox" name="additional" id="additional" value="1"$admg style="vertical-align: middle;" /> <br /><label for="additional">$amgtxt{'84'}</label>
        </td>
    </tr>~;
        }
    }
    if ( $INFO{'group'} ne 'Administrator' ) {
        $yymain .= qq~
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <colgroup>
            <col span="5" style="width: 20%" />
        </colgroup>
        <tr>
            <td class="titlebg" colspan="5">
                $admin_img{'prefimg'} <b>$amgtxt{'44'}</b>
            </td>
        </tr><tr>
            <td class="catbg center"><label for="view"><span class="small">$amgtxt{'45'} $amgtxt{'46'}</span></label></td>
            <td class="catbg center"><label for="topics"><span class="small">$amgtxt{'45'} $amgtxt{'47'}</span></label></td>
            <td class="catbg center"><label for="reply"><span class="small">$amgtxt{'45'} $amgtxt{'48'}</span></label></td>
            <td class="catbg center"><label for="polls"><span class="small">$amgtxt{'45'} $amgtxt{'49'}</span></label></td>
            <td class="catbg center"><label for="attach"><span class="small">$amgtxt{'45'} $amgtxt{'50'}</span></label></td>
        </tr><tr>
            <td class="windowbg2 center"><span class="small"><input type="checkbox" name="view" id="view" value="1"$vc /></span></td>
            <td class="windowbg2 center"><span class="small"><input type="checkbox" name="topics" id="topics" value="1"$tc /></span></td>
            <td class="windowbg2 center"><span class="small"><input type="checkbox" name="reply" id="reply" value="1"$rc /></span></td>
            <td class="windowbg2 center"><span class="small"><input type="checkbox" name="polls" id="polls" value="1"$poc /></span></td>
            <td class="windowbg2 center"><span class="small"><input type="checkbox" name="attach" id="attach" value="1"$ac /></span></td>
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
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
</div>
</form>

<script type="text/javascript">
function viscolor(v) {
    v = v.toUpperCase();
    v = v.replace(/[^A-F0-9]/g, '');
    if (v) document.getElementById('grpcolor').style.color = '#' + v;
    else   document.getElementById('grpcolor').style.color = '#000000';
    document.getElementById('color2').value = v;
    j = 0;
    for (i = 0; i < document.getElementById('color').length; i++) {
        if (document.getElementById('color').options[i].value == v) {
                document.getElementById('color').options[i].selected = true;
                j = 1; break;
            }
    }
    if (j === 0) document.getElementById('color').options[0].selected = true;
}

function previewColor(color) {
    color = color.replace(/#/, '');
    document.getElementById('color2').value = color;
    viscolor(color);
}

function stars(value) {
    if (value == "other") document.getElementById('otherstar').disabled = false;
    else document.getElementById('otherstar').disabled = true;
}

function showimage() {
    selected = document.groups.starsadmin.options[document.groups.starsadmin.selectedIndex].value;
    useimg = (selected != "other") ? "$imagesdir/"+selected : "$imagesdir/blank.gif";
    document.images.starpic.src=useimg;
    if (document.images.starpic.complete === false) {
        useimg = (selected != "other") ? "$defaultimagesdir/"+selected :  "$defaultimagesdir/blank.gif";
        document.images.starpic.src=useimg;
    }
}

function depend(value) {
    if (value == "Yes") {
        document.getElementById('posts').disabled = false;
        if (document.getElementById('posts').value === '') document.getElementById('posts').value = 0;
        document.getElementById('viewpublic').checked = true;
        document.getElementById('viewpublic').disabled = true;
    } else{
        document.getElementById('posts').disabled = true;
        document.getElementById('viewpublic').disabled = false;
    }
}
</script>
~;
    $yytitle     = $admin_txt{'8'};
    $action_area = 'modmemgr';
    AdminTemplate();
    return;
}

sub editAddGroup2 {
    is_admin_or_gmod();

# Additional checks are:
# If post independent -> post dependent, then need to kill off post independent
# If post dependent -> post independent, then need to kill off post dependent.
# If post dependent -> NEW post dependent, then need to kill off OLD post dependent.
    $newpostdep = 0;

    if ( !$FORM{'title'} ) { fatal_error('no_group_name'); }
    $name = $FORM{'title'};

    $name =~ s/&amp;/&/gsm;
    $name =~ s/'/&#39;/gxsm;     #' make my syntax checker happy;
    $name =~ s/,/&#44;/gxsm;
    $name =~ s/\|/&#124;/gxsm;
    $lcname = lc $name;

    if ( $FORM{'starsadmin'} eq 'other' ) {
        $cur_otherstar = $FORM{'cur_otherstar'};
        if ( $FORM{'otherstar'} ne q{} ) {
            $star = UploadFile('otherstar', 'Templates/Forum/default', 'png jpg jpeg gif', '250', '0');
            if ( $cur_otherstar !~ /^(staradmin|stargmod|starfmod|starmod|starsilver|starblue|stargold).png$/ ) {
                unlink "$htmldir/Templates/Forum/default/$cur_otherstar";
            }
        }
        else {
            $star = $cur_otherstar;
        }
    }
    else { $star = $FORM{'starsadmin'}; }
    $color = $FORM{'color2'} ne q{} ? "#$FORM{'color2'}" : q{};
    $postdepend = $FORM{'postdepend'};
    if ( $FORM{'posts'} !~ /\d+/xsm && $postdepend eq 'Yes' ) {
        fatal_error('no_post_number');
    }
    else { $posts = $FORM{'posts'} }
    if ( $postdepend eq 'No' ) { $noposts = $FORM{'noposts'}; }

    if   ( $FORM{'viewpublic'} ) { $viewpublic = 0 }
    else                         { $viewpublic = 1 }
    $view       = $FORM{'view'}       || 0;
    $topics     = $FORM{'topics'}     || 0;
    $reply      = $FORM{'reply'}      || 0;
    $polls      = $FORM{'polls'}      || 0;
    $attach     = $FORM{'attach'}     || 0;
    $additional = $FORM{'additional'} || 0;
    $original   = $FORM{'original'};

    # all the checks.
    if ( $original ne q{} ) {
        ( $type, $element ) = split /\|/xsm, $original;

        # Ignoring Administrative groups.
        if ( $element ne q{} ) {
            if ( $type eq 'P' ) {
                if ( $element != $posts || $postdepend eq 'No' ) {
                    if ($iamgmod) { fatal_error('newpostdep_gmod'); }

                    delete $Post{$element};
                    $newpostdep = 1;
                    $noposts    = 1;
                    foreach ( sort { $a <=> $b } keys %NoPost ) {
                        $noposts = $_ + 1;
                    }
                }
            }
            elsif ( $type eq 'NP' ) {
                if ( $element != $noposts || $postdepend eq 'Yes' ) {
                    delete $NoPost{$element};
                    for my $i ( 0 .. ( @nopostorder - 1 ) ) {
                        if ( $nopostorder[$i] == $element ) {
                            splice @nopostorder, $i, 1;
                            last;
                        }
                    }
                }
            }
        }
    }

    if ( ( split /\|/xsm, $Group{$original}, 2 )[0] ne $name ) {
        if ( $lcname eq lc( ( split /\|/xsm, $Group{'Administrator'}, 2 )[0] ) )
        {
            fatal_error( 'double_group', $lcname );
        }
        if (
            $lcname eq lc( ( split /\|/xsm, $Group{'Global Moderator'}, 2 )[0] )
          )
        {
            fatal_error( 'double_group', $lcname );
        }
        if (
            $lcname eq lc( ( split /\|/xsm, $Group{'Mid Moderator'}, 2 )[0] )
          )
        {
            fatal_error( 'double_group', $lcname );
        }
        if ( $lcname eq lc( ( split /\|/xsm, $Group{'Moderator'}, 2 )[0] ) ) {
            fatal_error( 'double_group', $lcname );
        }
    }

    # Check Post Independent
    foreach my $key ( keys %NoPost ) {
        if ( $type eq 'NP' && $key eq $element ) { next; }
        ( $value, undef ) = split /\|/xsm, $NoPost{$key}, 2;
        $lcvalue = lc $value;
        if ( $lcname eq $lcvalue ) {
            fatal_error( 'double_group', $lcname );
        }
    }

    # Check Post Dependent
    foreach my $key ( keys %Post ) {
        if ( $type eq 'P' && $key eq $element ) { next; }
        ( $value, undef ) = split /\|/xsm, $Post{$key}, 2;
        $lcvalue = lc $value;
        if ( $lcname eq $lcvalue ) {
            fatal_error( 'double_group', $lcname );
        }
    }

    if ( $FORM{'numstars'} !~ /\A[0-9]+\Z/xsm ) { $FORM{'numstars'} = 0; }

# Now, we must deliberate on what type of thing this group is, and add/read(when editing) it.
# First, using original variable, we check to see it's not a perma-group.
    ( $type, $element ) = split /\|/xsm, $original;
    if ( $element eq q{} && $original ne q{} ) {

# We have a perma-group! $type is now equal to the perma group or key for the hash.
# add in code to actually set the line.
        $Group{"$type"} =
"$name|$FORM{'numstars'}|$star|$color|$viewpublic|$view|$topics|$reply|$polls|$attach|$additional";
    }
    else {

        # post dependent group.
        if ( $postdepend eq 'Yes' ) {
            foreach my $key ( keys %Post ) {
                if (
                    $posts == $key
                    && (   $FORM{'origin'} eq 'editgroup1'
                        || $original ne "P|$posts" )
                  )
                {
                    fatal_error( 'double_count', "($posts)" );
                }
            }

            if ($iamgmod) { fatal_error('newpostdep_gmod'); }

            $Post{$posts} =
"$name|$FORM{'numstars'}|$star|$color|0|$view|$topics|$reply|$polls|$attach|$additional";
            $newpostdep = 1;

            # no post group
        }
        else {
            $NoPost{$noposts} =
"$name|$FORM{'numstars'}|$star|$color|$viewpublic|$view|$topics|$reply|$polls|$attach|$additional";
            my $isinorder;
            for my $i ( 0 .. ( @nopostorder - 1 ) ) {
                if (   $NoPost{ $nopostorder[$i] }
                    && $nopostorder[$i] == $noposts )
                {
                    $isinorder = 1;
                    last;
                }
            }
            if ( !$isinorder ) { push @nopostorder, $noposts; }
        }
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    # save @nopostorder, %Group, %NoPost and %Post

    if ($newpostdep) {
        $yySetLocation =
          qq~$adminurl?action=rebuildmemlist;actiononfinish=modmemgr~;
    }
    else {
        $yySetLocation = qq~$adminurl?action=modmemgr~;
    }
    redirectexit();
    return;
}

sub permImage {
    my @x = @_;
    my $viewperms =
      ( $x[0] != 1 ) ? qq~<img src="$imagesdir/open.gif" alt="" />~ : q{};
    my $topicperms =
      ( $x[1] != 1 ) ? qq~<img src="$imagesdir/new_thread.gif" alt="" />~ : q{};
    my $replyperms =
      ( $x[2] != 1 ) ? qq~<img src="$imagesdir/reply.gif" alt="" />~ : q{};
    my $pollperms =
      ( $x[3] != 1 ) ? qq~<img src="$imagesdir/poll_create.gif" alt="" />~ : q{};
    my $attachperms =
      ( $x[4] != 1 ) ? qq~<img src="$imagesdir/paperclip.gif" alt="" />~ : q{};

    return "$viewperms $topicperms $replyperms $pollperms $attachperms";
}

sub deleteGroup {
    if ( $INFO{'group'} ) {
        ( $type, $element ) = split /\|/xsm, $INFO{'group'};
        if ( $element ne q{} ) {
            if ( $type eq 'P' ) {
                delete $Post{$element};
            }
            elsif ( $type eq 'NP' ) {
                delete $NoPost{$element};
                KillModeratorGroup($element);
            }
        }
    }
    else {
        fatal_error('no_info');
    }

    my @new_nopostorder;
    foreach (@nopostorder) {
        if ( $NoPost{$_} ) { push @new_nopostorder, $_; }
    }
    @nopostorder = @new_nopostorder;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    # save @nopostorder, %Group, %NoPost and %Post

    $yySetLocation =
      qq~$adminurl?action=rebuildmemlist;actiononfinish=modmemgr~;
    redirectexit();
    return;
}

sub reorderGroups {
    $selsize = 0;
    foreach (@nopostorder) {
        if ( $NoPost{$_} ) {
            ( $title, undef ) = split /\|/xsm, $NoPost{$_}, 2;
            if ( $_ eq $INFO{'thegroup'} ) {
                $orderopt .=
                  qq~<option value="$_" selected="selected">$title</option>~;
            }
            else {
                $orderopt .= qq~<option value="$_">$title</option>~;
            }
            $selsize++;
        }
    }

    $rowspan = $#nopostorder + 2;
    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <colgroup>
            <col span="2" style="width:33%" />
            <col style="width:34%" />
        </colgroup>
        <tr>
            <td class="titlebg" colspan="3">
                <img src="$imagesdir/guest.gif" alt="" />&nbsp;<b>$admintxt{'reordergroups2'}</b>
            </td>
        </tr><tr>
            <td class="catbg center"><b>$amgtxt{'03'}</b></td>
            <td class="catbg center"><b>$amgtxt{'19'}</b></td>
            <td class="windowbg center" rowspan="$rowspan">
                <form action="$adminurl?action=reordergroup2" method="post" name="groupsorder" style="display: inline; white-space: nowrap;" accept-charset="$yymycharset">
                    <select name="ordergroups" class="small" size="$selsize" style="width: 130px;">
                        $orderopt
                    </select>
                    <br />
                    <input type="submit" value="$admin_txt{'739a'}" name="moveup" style="font-size: 11px; width: 65px;" class="button" /><input type="submit" value="$admin_txt{'739b'}" name="movedown" style="font-size: 11px; width: 65px;" class="button" />
                </form>
            </td>
        </tr>~;

    foreach (@nopostorder) {
        ( $title, $stars, $starpic, $color, undef ) = split /\|/xsm,
          $NoPost{$_}, 5;
        if ( !$stars ) { $stars = '0'; }
        $yymain .= q~<tr>
            <td class="windowbg2">~;

        if ($color) {
            $yymain .= qq~<span style="color:$color"><b>$title</b></span>~;
        }
        else { $yymain .= qq~<b>$title</b>~; }
        $yymain .= q~
            </td>
            <td class="windowbg2 center">~;

        for ( 1 .. $stars ) {
            $yymain .= qq~<img src="$imagesdir/$starpic" alt="" />~;
        }

        $yymain .= q~
            </td>
        </tr>~;
    }

    $yymain .= q~
    </table>
</div>~;

    $yytitle     = $admintxt{'reordergroups'};
    $action_area = 'modmemgr';

    AdminTemplate();
    return;
}

sub reorderGroups2 {
    my $moveitem = $FORM{'ordergroups'};

    if ($moveitem) {
        for my $i ( 0 .. ( @nopostorder - 1 ) ) {
            if (
                $nopostorder[$i] == $moveitem
                && (   ( $FORM{'moveup'} && $i > 0 && $i <= $#nopostorder )
                    || ( $FORM{'movedown'} && $i < $#nopostorder && $i >= 0 ) )
              )
            {
                my $j = $FORM{'moveup'} ? $i - 1 : $i + 1;
                $nopostorder[$i] = $nopostorder[$j];
                $nopostorder[$j] = $moveitem;
                last;
            }
        }
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    # save @nopostorder

    $yySetLocation = qq~$adminurl?action=reordergroup;thegroup=$moveitem~;
    redirectexit();
    return;
}

1;
