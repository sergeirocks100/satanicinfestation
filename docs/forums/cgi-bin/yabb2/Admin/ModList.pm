###############################################################################
# ModList.pm                                                                  #
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
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$modlistpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub ListMods {
    my @installed_mods = ();

    # You need to list your mod in this file for full compliance.
    # Add it in the following way:
    #        $my_mod = "Name of Mod|Author|Description|Version|Date Released";
    #        push @installed_mods, $my_mod;
    # It is recommended that you do a "add before" on the end boardmod tag
    # This preserves the installation order.

    # Also note, you should pick a unique name instead of "$my_mod".
    # If your mod is called "SuperMod For Doing Cool Things"
    # You could use "$SuperMod_CoolThings"

### BOARDMOD ANCHOR ###
### END BOARDMOD ANCHOR ###
    our ( $yymain, %mod_list, $imagesdir, $yytitle );
    my ( $action_area,  $mod_text_list, $full_description );
    $total_mods = @installed_mods;

    if ( !@installed_mods ) {
        $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <div class="pad-more"><table class="border-space pad-cell">
        <tr>
            <td class="titlebg">
                $admin_img{'prefimg'} <b>$mod_list{'5'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                    $mod_list{'8'} <a href="http://www.boardmod.org" target="_blank">$mod_list{'9'}</a>
                </div>
            </td>
        </tr>
    </table>
</div>
~;
        $yytitle     = $mod_list{'6'};
        $action_area = 'modlist';
        AdminTemplate();
    }

    foreach my $modification (@installed_mods) {
        chomp $modification;
        my ( $mod_anchor, $mod_author, $mod_desc, $mod_version, $mod_date ) =
          split /\|/xsm, $modification;

        my $mod_displayname = $mod_anchor;
        $mod_displayname =~ s/\_/ /gxsm;
        $mod_anchor      =~ s/ /\_/gsm;
        $mod_anchor      =~ s/[^\w]//gxsm;

        $mod_text_list .= qq~<tr>
            <td class="windowbg2">
                <a href="#$mod_anchor">$mod_displayname</a>
            </td>
            <td class="windowbg2">
                $mod_author
            </td>
            <td class="windowbg2">
                $mod_version
            </td>
        </tr>~;

        $full_description .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <a id="$mod_anchor">$admin_img{'prefimg'}</a> <b>$mod_displayname</b> &nbsp; <span class="small">$mod_list{'4'}: $mod_version</span>
            </td>
        </tr><tr>
            <td class="catbg">
                <span class="small">$mod_list{'2'}: $mod_author</span>
            </td>
        </tr><tr>
            <td class="windowbg2">
                $mod_desc
            </td>
        </tr><tr>
            <td class="catbg right">
                <div class="pad-more small">$mod_list{'3'}: $mod_date</div>
            </td>
        </tr>
    </table>
</div>~;
    }

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg" colspan="3">
                $admin_img{'prefimg'} <b>$mod_list{'5'} ($total_mods)</b>
            </td>
        </tr><tr>
            <td class="catbg">
                <span class="small">$mod_list{'1'}</span>
            </td>
            <td class="catbg">
                <span class="small">$mod_list{'2'}</span>
            </td>
            <td class="catbg">
                <span class="small">$mod_list{'4'}</span>
            </td>
        </tr>
        $mod_text_list
     </table>
</div>
$full_description
~;

    $yytitle     = $mod_list{'6'};
    $action_area = 'modlist';
    AdminTemplate();
    return $yymain;
}

1;
