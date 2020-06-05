###############################################################################
# Smilies.pm                                                                  #
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
our $VERSION = '2.6.11';

our $smiliespmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

$admin_images = "$yyhtml_root/Templates/Admin/default";

sub SmiliePanel {
    is_admin_or_gmod();
    if    ( $smiliestyle == 1 ) { $ss1 = q{ selected="selected"}; }
    elsif ( $smiliestyle == 2 ) { $ss2 = q{ selected="selected"}; }
    @sa = ();
    foreach my $i ( 1 .. 4 ) {
        if ( $showadded == $i ) {
            $sa[$i] = q{ selected="selected"};
        }
    }
    @ssm = ();
    foreach my $i ( 1 .. 4 ) {
        if ( $showsmdir == $i ) {
            $ssm[$i] = q{ selected="selected"};
        }
    }
    if ( $detachblock == 1 )  { $dblock   = q{ checked="checked"}; }
    if ($removenormalsmilies) { $remnosmi = q{ checked="checked"}; }
    opendir DIR, "$htmldir/Smilies";
    @contents = readdir DIR;
    closedir DIR;
    $smilieslist = q{};

    foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
        my ( $name, $extension ) = split /\./xsm, $line;
        if (   $extension =~ /gif/ism
            || $extension =~ /jpg/ism
            || $extension =~ /jpeg/ism
            || $extension =~ /png/ism )
        {
            if ( $line !~ /banner/ism ) {
                $smilieslist .= qq~<tr>
    <td class="windowbg2 center">
        <input type="radio" name="showinbox" value="$name"~
                  . ( $showinbox eq $name ? ' checked="checked"' : q{} )
                  . qq~ /></td>
    <td class="windowbg2 center">[smiley=$line]</td>
    <td class="windowbg2 center">$line</td>
    <td class="windowbg2 center">$name</td>
    <td class="windowbg2 center" colspan="4"><img src="$yyhtml_root/Smilies/$line" alt="$name" title="$name" /></td>
  </tr>~;
            }
        }
    }
    $yymain .= qq~
<form action="$adminurl?action=addsmilies" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width: 5%" />
        <col span="3" style="width: 20%" />
        <col style="width: 15%" />
        <col style="width: 10%" />
        <col span="2" style="width: 5%" />
    </colgroup>
    <tr>
        <td class="titlebg" colspan="8" style="height:22px">&nbsp;<img src="$imagesdir/grin.gif" alt="" /><b>&nbsp;$smiltxt{'3'}</b><br /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="removenormalsmilies">$smiltxt{'24'}</label></td>
        <td class="windowbg2" colspan="4"><input type="checkbox" name="removenormalsmilies" id="removenormalsmilies" value="1"$remnosmi /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="smiliestyle">$smiltxt{'4'}</label></td>
        <td class="windowbg2" colspan="4">
            <select name="smiliestyle" id="smiliestyle">
                <option value="1"$ss1>$smiltxt{'5'}</option>
                <option value="2"$ss2>$smiltxt{'6'}</option>
            </select>
        </td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="showadded">$smiltxt{'7'}</label></td>
        <td class="windowbg2" colspan="4">
            <select name="showadded" id="showadded">
                <option value="1"$sa[1]>$smiltxt{'8'}</option>
                <option value="2"$sa[2]>$smiltxt{'9'}</option>
                <option value="3"$sa[3]>$smiltxt{'10'}</option>
                <option value="4"$sa[4]>$smiltxt{'11'}</option>
            </select>
        </td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="showsmdir">$smiltxt{'2'}</label></td>
        <td class="windowbg2" colspan="4">
            <select name="showsmdir" id="showsmdir">
                <option value="1"$ssm[1]>$smiltxt{'8'}</option>
                <option value="2"$ssm[2]>$smiltxt{'9'}</option>
                <option value="3"$ssm[3]>$smiltxt{'10'}</option>
                <option value="4"$ssm[4]>$smiltxt{'11'}</option>
            </select>
        </td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="detachblock">$smiltxt{'12'}<br /> $smiltxt{'13'}</label></td>
        <td class="windowbg2" colspan="4"><input type="checkbox" name="detachblock" id="detachblock" value="1"$dblock /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="winwidth">$smiltxt{'14'}</label></td>
        <td class="windowbg2" colspan="4"><input type="text" size="10" name="winwidth" id="winwidth" value="$winwidth" /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="winheight">$smiltxt{'15'}</label></td>
        <td class="windowbg2" colspan="4"><input type="text" size="10" name="winheight" id="winheight" value='$winheight' /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="showinbox">$smiltxt{'23'}</label></td>
        <td class="windowbg2" colspan="4"><input type="radio" name="showinbox" id="showinbox" value=""~
              . ( !$showinbox ? ' checked="checked"' : q{} ) . qq~ /></td>
    </tr><tr>
        <td class="windowbg2" colspan="4">$smiltxt{'18'}</td>
        <td class="windowbg2" colspan="4">$yyhtml_root/Smilies</td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="popback">$smiltxt{'20'}</label></td>
        <td class="windowbg2" colspan="4">
        #<input type="text" size="10" name="popback" id="popback" value="$popback" onkeyup="previewColor(this.value);" />
            <span id="popback_color" style="background-color: #$popback;">&nbsp; &nbsp; &nbsp;</span> <img src="$admin_images/palette1.gif" style="cursor: pointer; vertical-align: top;" onclick="window.open('$scripturl?action=palette;task=templ', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" />
            <script type="text/javascript">
            function previewColor(color) {
                color = color.replace(/#/, '');
                document.getElementById('popback_color').style.background = '#' + color;
                document.getElementsByName("popback")[0].value = color;
            }
            </script>
        </td>
    </tr><tr>
        <td class="windowbg2" colspan="4"><label for="poptext">$smiltxt{'19'}</label></td>
        <td class="windowbg2" colspan="4">
        #<input type="text" size="10" name="poptext" id="poptext" value="$poptext" onkeyup="previewColor_0(this.value);"/>
            <span id="poptext_color" style="background-color: #$poptext;">&nbsp; &nbsp; &nbsp;</span> <img src="$admin_images/palette1.gif" style="cursor: pointer; vertical-align: top;" onclick="window.open('$scripturl?action=palette;task=templ_0', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" />
            <script type="text/javascript">
            function previewColor_0(color) {
                color = color.replace(/#/, '');
                document.getElementById('poptext_color').style.background = '#' + color;
                document.getElementsByName("poptext")[0].value = color;
            }
            </script>
        </td>
    </tr><tr>
        <td class="titlebg" colspan="8">&nbsp;<img src="$imagesdir/grin.gif" alt="" /><b>&nbsp;$asmtxt{'11'}</b></td>
    </tr><tr>
        <td class="catbg center small">$smiltxt{'22'}</td>
        <td class="catbg center small">$asmtxt{'02'}</td>
        <td class="catbg center small">$asmtxt{'03'}</td>
        <td class="catbg center small">$asmtxt{'04'}</td>
        <td class="catbg center small">$asmtxt{'05'}</td>
        <td class="catbg center small">$asmtxt{'06'}</td>
        <td class="catbg center small">$asmtxt{'07'}</td>
        <td class="catbg center small">$asmtxt{'12'}</td>
    </tr>~;

    $i = 0;
    my $add_smiley = 1;
    foreach (@SmilieURL) {
        if ( $i != 0 ) {
            $up =
qq~<a href="$adminurl?action=smiliemove;index=$i;moveup=1"><img src="$imagesdir/smiley_up.gif" alt="$asmtxt{'13'}" title="$asmtxt{'13'}" /></a>~;
        }
        else {
            $up = qq~<img src="$imagesdir/smiley_up.gif" alt="" />~;
        }
        if ( $SmilieURL[ $i + 1 ] ) {
            $down =
qq~<a href="$adminurl?action=smiliemove;index=$i;movedown=1"><img src="$imagesdir/smiley_down.gif" alt="$asmtxt{'14'}" title="$asmtxt{'14'}" /></a>~;
        }
        else {
            $down = qq~<img src="$imagesdir/smiley_down.gif" alt="" />~;
        }
        $yymain .= qq~<tr>
    <td class="windowbg2 center"><input type="radio" name="showinbox" value="$SmilieDescription[$i]"~
          . ( $showinbox eq $SmilieDescription[$i] ? ' checked="checked"' : q{} )
          . qq~ /></td>
    <td class="windowbg2 center"><input type="text" name="scd[$i]" value="$SmilieCode[$i]" /></td>
    <td class="windowbg2 center" style="white-space: nowrap;">
        <input type="file" name="smimg[$i]" id="smimg[$i]" size="35" />
        <input type="hidden" name="cur_smimg[$i]" value="$SmilieURL[$i]" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('smimg[$i]').value='';">X</span>
        <div class="small bold">$admin_txt{'current_img'}: <a href="$yyhtml_root/Templates/Forum/default/$SmilieURL[$i]" target="_blank">$SmilieURL[$i]</a></div>
    </td>
    <td class="windowbg2 center"><input type="text" name="sdescr[$i]" value="$SmilieDescription[$i]" /></td>
    <td class="windowbg2 center"><input type="checkbox" name="smbox[$i]" value="1"~
          . ( $SmilieLinebreak[$i] eq '<br />' ? ' checked="checked"' : q{} )
          . q~ /></td>
    <td class="windowbg2 center"><img src="~
          . (
              $SmilieURL[$i] =~ /\//ixsm
            ? $SmilieURL[$i]
            : qq~$imagesdir/$SmilieURL[$i]~
          )
          . qq~" alt="" /></td>
    <td class="windowbg2 center"><input type="checkbox" name="delbox[$i]" value="1" /></td>
    <td class="windowbg2 center">$up $down</td>
  </tr>~;
        $i++;
        $add_smiley++;
    }
    my $added_smilies = $i;
    $yymain .= qq~<tr>
    <td class="titlebg" colspan="8">&nbsp;<img src="$imagesdir/grin.gif" alt="" /><b>&nbsp;$asmtxt{'08'}</b></td>
  </tr><tr>
    <td class="windowbg2 center">&nbsp;</td>
    <td class="windowbg2 center"><input type="text" name="scd[$i]" /></td>
    <td class="windowbg2 center" style="white-space: nowrap;"><input type="file" name="smimg[$i]" id="smimg[$i]" size="35" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('smimg[$i]').value='';">X</span></td>
    <td class="windowbg2 center"><input type="text" name="sdescr[$i]" /></td>
    <td class="windowbg2 center"><input type="checkbox" name="smbox[$i]" value="1" /></td>
    <td class="windowbg2 center" colspan="3">
        <img src="$imagesdir/cat_expand.png" alt="$smiltxt{'25'}" title="$smiltxt{'25'}" class="cursor" style="visibility: visible;" id="add_smiley$i" onclick="addSmilies($add_smiley);" />
        <img src="$imagesdir/cat_collapse.png" alt="" style="visibility: hidden;" /> <!-- Used only for alignment purposes -->
    </td>
  </tr>~;
    for ( 1 .. 4 ) {
        $i++;
        $add_smiley++;
        $yymain .= qq~<tr id="add_smilies$i" style="display: none;">
    <td class="windowbg2 center">&nbsp;</td>
    <td class="windowbg2 center"><input type="text" name="scd[$i]" id="scd[$i]" /></td>
    <td class="windowbg2 center" style="white-space: nowrap;"><input type="file" name="smimg[$i]" id="smimg[$i]" size="35" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('smimg[$i]').value='';">X</span></td>
    <td class="windowbg2 center"><input type="text" name="sdescr[$i]" id="sdescr[$i]" /></td>
    <td class="windowbg2 center"><input type="checkbox" name="smbox[$i]" id="smbox[$i]" value="1" /></td>
    <td class="windowbg2 center" colspan="3">
        <img src="$imagesdir/cat_expand.png" alt="$smiltxt{'25'}" title="$smiltxt{'25'}" class="cursor" style="visibility: visible;" id="add_smiley$i" onclick="addSmilies($add_smiley);" />
        <img src="$imagesdir/cat_collapse.png" alt="$smiltxt{'26'}" title="$smiltxt{'26'}" class="cursor" style="visibility: visible;" id="col_smiley$i" onclick="removeSmilies($i);" />
    </td>
  </tr>~;
}
    $yymain .= qq~<tr>
    <td class="titlebg" colspan="8">&nbsp;<img src="$imagesdir/grin.gif" alt="" /><b>&nbsp;$smiltxt{'2'}</b></td>
  </tr><tr>
    <td class="catbg center small">$smiltxt{'22'}</td>
    <td class="catbg center small">$asmtxt{'02'}</td>
    <td class="catbg center small">$asmtxt{'03'}</td>
    <td class="catbg center small">$asmtxt{'04'}</td>
    <td class="catbg center small" colspan="4">$asmtxt{'06'}</td>
  </tr>$smilieslist
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="hidden" name="smimg_count" value="$i" />
            <input type="submit" value="$asmtxt{'09'}" class="button" />&nbsp;<input type="reset" value="$asmtxt{'10'}" class="button" />
        </td>
    </tr>
</table>
</div>
<script type="text/javascript">
sm_added = $added_smilies + 1;

function addSmilies(addsm_id) {
    var cursm_id = addsm_id - 1;
    var sm_count = $i;
    document.getElementById('add_smilies' + addsm_id).style.display = 'table-row';
    document.getElementById('add_smiley' + cursm_id).style.visibility = 'hidden';
    if (addsm_id != sm_added) {
        document.getElementById('col_smiley' + cursm_id).style.visibility =' hidden';
    }
    if (addsm_id == sm_count) {
        document.getElementById('add_smiley' + sm_count).style.visibility = 'hidden';
    }
}
function removeSmilies(remsm_id) {
    var prevsm_id = remsm_id - 1;
    document.getElementById('add_smilies' + remsm_id).style.display = 'none';
    document.getElementById('add_smiley' + prevsm_id).style.visibility = 'visible';
    if (remsm_id != sm_added) {
        document.getElementById('col_smiley' + prevsm_id).style.visibility = 'visible';
    }
    sm_elements = ["scd","smimg","sdescr"];
    for (var i=0; i<sm_elements.length; i++) {
        document.getElementById(sm_elements[i] + '[' + remsm_id + ']').value = '';
    }
    document.getElementById('smbox[' + remsm_id + ']').checked = false;
}
</script>
</form>
~;

    $yytitle     = "$asmtxt{'01'}";
    $action_area = 'smilies';
    AdminTemplate();

    return;
}

sub AddSmilies {
    is_admin_or_gmod();

    $smiliestyle = $FORM{'smiliestyle'};
    $showadded   = $FORM{'showadded'};
    $showsmdir   = $FORM{'showsmdir'};
    $detachblock = $FORM{'detachblock'};
    $winwidth    = $FORM{'winwidth'};
    $winheight   = $FORM{'winheight'};
    $popback     = $FORM{'popback'};
    $popback =~ s/[^a-f0-9]//igxsm;
    $poptext = $FORM{'poptext'};
    $poptext =~ s/[^a-f0-9]//igxsm;
    $showinbox           = $FORM{'showinbox'};
    $removenormalsmilies = $FORM{'removenormalsmilies'};
    $count_smimg = $FORM{'smimg_count'};

    if ( $winwidth  eq q{} ) { fatal_error('invalid_value', "$smiltxt{'14'}"); }
    if ( $winheight eq q{} ) { fatal_error('invalid_value', "$smiltxt{'15'}"); }
    if ( $popback   eq q{} ) { fatal_error('invalid_value', "$smiltxt{'20'}"); }
    if ( $poptext   eq q{} ) { fatal_error('invalid_value', "$smiltxt{'19'}"); }

    @SmilieURL         = ();
    @SmilieCode        = ();
    @SmilieDescription = ();
    @SmilieLinebreak   = ();
    my $temp_a = 0;
    for ( 1 .. $count_smimg ) {
        if ( $FORM{"scd[$temp_a]"} ne q{} || $FORM{"smimg[$temp_a]"} ne q{} || $FORM{"sdescr[$temp_a]"} ne q{} ) {
            if ( $FORM{"scd[$temp_a]"} eq q{} ) { fatal_error('', $smiltxt{'error_code'}); }
            if ( $FORM{"smimg[$temp_a]"} eq q{} && $FORM{"cur_smimg[$temp_a]"} eq q{} ) { fatal_error(q{}, $smiltxt{'error_image'}); }
            if ( $FORM{"sdescr[$temp_a]"} eq q{} ) { fatal_error('', $smiltxt{'error_desc'}); }
        }
        if ( $FORM{"delbox[$temp_a]"} != 1 && $FORM{"sdescr[$temp_a]"} ne q{} && ( $FORM{"smimg[$temp_a]"} ne q{} || $FORM{"cur_smimg[$temp_a]"} ne q{} ) ) {
            if ( $FORM{"smimg[$temp_a]"} ne q{} ) {
                $FORM{"smimg[$temp_a]"} = UploadFile("smimg[$temp_a]", 'Templates/Forum/default', 'png jpg jpeg gif', '100', '0');
            }
            else {
                $FORM{"smimg[$temp_a]"} = $FORM{"cur_smimg[$temp_a]"};
            }
            push @SmilieURL, $FORM{"smimg[$temp_a]"};

            ToHTML( $FORM{"scd[$temp_a]"} );
            $FORM{"scd[$temp_a]"} =~ s/\$/&#36;/gxsm;
            $FORM{"scd[$temp_a]"} =~ s/\@/&#64;/gxsm;
            push @SmilieCode, $FORM{"scd[$temp_a]"};

            ToHTML( $FORM{"sdescr[$temp_a]"} );
            $FORM{"sdescr[$temp_a]"} =~ s/\$/&#36;/gxsm;
            $FORM{"sdescr[$temp_a]"} =~ s/\@/&#64;/gxsm;
            push @SmilieDescription, $FORM{"sdescr[$temp_a]"};

            push @SmilieLinebreak, ( $FORM{"smbox[$temp_a]"} ? '<br />' : q{} );
        }
        if ( $FORM{"delbox[$temp_a]"} == 1 && $FORM{"cur_smimg[$temp_a]"} !~ /^(exclamation|question).png$/) {
            unlink "$htmldir/Templates/Forum/default/$FORM{\"cur_smimg[$temp_a]\"}";
        }
        ++$temp_a;
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=smilies~;
    redirectexit();
    return;
}

sub SmilieMove {
    is_admin_or_gmod();

    if ( exists $INFO{'index'} ) {
        for my $i ( 0 .. ( @SmilieURL - 1 ) ) {
            if (
                $i == $INFO{'index'}
                && (   ( $INFO{'movedown'} && $i >= 0 && $i < $#SmilieURL )
                    || ( $INFO{'moveup'} && $i <= $#SmilieURL && $i > 0 ) )
              )
            {
                my $j = $INFO{'moveup'} ? $i - 1 : $i + 1;

                my $moveit = $SmilieURL[$i];
                $SmilieURL[$i] = $SmilieURL[$j];
                $SmilieURL[$j] = $moveit;

                $moveit         = $SmilieCode[$i];
                $SmilieCode[$i] = $SmilieCode[$j];
                $SmilieCode[$j] = $moveit;

                $moveit                = $SmilieDescription[$i];
                $SmilieDescription[$i] = $SmilieDescription[$j];
                $SmilieDescription[$j] = $moveit;

                $moveit              = $SmilieLinebreak[$i];
                $SmilieLinebreak[$i] = $SmilieLinebreak[$j];
                $SmilieLinebreak[$j] = $moveit;
                last;
            }
        }
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=smilies~;
    redirectexit();
    return;
}

1;
