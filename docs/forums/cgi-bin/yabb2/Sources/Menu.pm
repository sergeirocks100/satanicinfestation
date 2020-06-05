###############################################################################
# Menu.pm                                                                     #
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
#-----------------------------------------------------------------------------#
# CSS Buttons 4 YaBB 2.5                                                      #
#  Copyright (c) 2010 'Carsten Dalgaard' - All Rights Reserved                #
# Released: December 12, 2010                                                 #
# e-mail: post@carsten-dalgaard.dk                                            #
#  Added to YaBB core with the writer's permission, January 28, 2013          #
###############################################################################
# use strict;
# use warnings;
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$menupmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
get_micon();

sub SetMenu {
    if ( -e ("Templates/$usestyle/Menu.def") ) {
        $Menu_def = qq~Templates/$usestyle/Menu.def~;
    }
    else { $Menu_def = q~Templates/default/Menu.def~; }

    fopen( MENUFILE, "$Menu_def" );
    %img = map { /(.*),(.*)/xsm } <MENUFILE>;
    fclose(MENUFILE);

    while ( ( $key, $value ) = each %img ) {
        chomp $value;
        (
            $button_icon, $button_text, $text_num, $alt_text,
            $alt_num,     $span_class,  $imgext,   $mod_or_not
        ) = split /\|/xsm, $value;
        if ( !$alt_text ) {
            $alt_text = $button_text;
            $alt_num  = $text_num;
        }
        if ( $mod_or_not eq 'mod' ) {
            $button_imgurl = qq~$modimgurl~;
        }
        else {
            $button_imgurl = qq~$yyhtml_root/Templates/Forum/$usestyle~;
            if ( !-e ("$htmldir/Templates/Forum/$usestyle/$button_icon.$imgext")
              )
            {
                $button_imgurl = qq~$yyhtml_root/Templates/Forum/default~;
            }
        }
        if   ( $key eq 'help' ) { $helpstyle = q~ cursor: help;~; }
        else                    { $helpstyle = q~ cursor: pointer;~; }
        if (   $key ne 'lastpost'
            && $key ne 'pollicon'
            && $key ne 'polliconnew'
            && $key ne 'polliconclosed' )
        {
            if ( $UseMenuType == 0 ) {
                $menusep = $my_sep;
                $img{$key} =
qq~<img src="$button_imgurl/$button_icon.$imgext" alt="${$alt_text}{$alt_num}" /> <span style="white-space: nowrap;" class="$span_class" title="${$alt_text}{$alt_num}">${$button_text}{$text_num}</span> ~;
            }
            elsif ( $UseMenuType == 1 ) {
                $menusep = $my_sep;
                $img{$key} =
qq~<span style="white-space: nowrap;" class="$span_class" title="${$alt_text}{$alt_num}">${$button_text}{$text_num}</span> ~;
            }
            else {
                $menusep =
qq~<img src='$yyhtml_root/Templates/Forum/$usestyle/buttonsep.png' class='cssbutton1' alt='' title='' />~;
                $img{$key} =
qq~<span class="buttonleft cssbutton2" title="${$alt_text}{$alt_num}" style="$helpstyle">~;
                $img{$key} .= q~<span class="buttonright cssbutton3">~;
                $img{$key} .=
qq~<span class="buttonimage cssbutton4" style="background-image: url($button_imgurl/$button_icon.$imgext);">~;
                $img{$key} .=
qq~<span class="buttontext cssbutton5">${$button_text}{$text_num}</span></span></span></span>~;
            }
        }
        else {
            $img{$key} =
qq~<img src="$button_imgurl/$button_icon.$imgext" alt="${$button_text}{$text_num}" />~;
        }
    }
    return;
}

sub SetImage {
    my ( $img_name, $UseMenuT ) = @_;

    if ( -e ("Templates/$usestyle/Menu.def") ) {
        $Menu_def = qq~Templates/$usestyle/Menu.def~;
    }
    else { $Menu_def = q~Templates/default/Menu.def~; }

    fopen( MENUFILE, "$Menu_def" );
    %img_set = map { /(.*),(.*)/xsm } <MENUFILE>;
    fclose(MENUFILE);

    my $imgname = $img_set{$img_name};

    (
        $button_icon, $button_text, $text_num, $alt_text,
        $alt_num,     $span_class,  $imgext,   $mod_or_not
    ) = split /\|/xsm, $imgname;
    chomp $mod_or_not;
    if ( !$alt_text ) {
        $alt_text = $button_text;
        $alt_num  = $text_num;
    }
    if ( $mod_or_not eq 'mod' ) {
        $button_imgurl = qq~$modimgurl~;
    }
    else {
        $button_imgurl = qq~$yyhtml_root/Templates/Forum/$usestyle~;
        if ( !-e ("$htmldir/Templates/Forum/$usestyle/$button_icon.$imgext")
          )
        {
            $button_imgurl = qq~$yyhtml_root/Templates/Forum/default~;
        }
    }
    if   ( $key eq 'help' ) { $helpstyle = q~ cursor: help;~; }
    else                    { $helpstyle = q~~; }
    if ( $UseMenuT == 0 ) {
        $menusep = $my_sep;
        if ( $img_name eq 'gtalk' ) {
            $img_out =
qq~<img src="$button_imgurl/$button_icon.$imgext" class="cursor" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=0,toolbar=0,scrollbars=0,resizable=1'); return false" alt="$thegtalkname" title="$thegtalkname" />~;
        }
        else {
            $img_out =
qq~<img src="$button_imgurl/$button_icon.$imgext" alt="${$alt_text}{$alt_num}" /> <span style="white-space: nowrap;" class="$span_class" title="${$alt_text}{$alt_num}">${$button_text}{$text_num}</span>~;
        }
    }
    elsif ( $UseMenuT == 1 ) {
        $menusep = $my_sep;
        if ( $img_name eq 'gtalk' ) {
            $img_out =
qq~<span style="white-space: nowrap;" class="$span_class cursor" title="${$alt_text}{$alt_num}" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=0,toolbar=0,scrollbars=0,resizable=1'); return false">${$button_text}{$text_num}</span>~;
        }
        else {
            $img_out =
qq~<span style="white-space: nowrap;" class="$span_class" title="${$alt_text}{$alt_num}">${$button_text}{$text_num}</span>~;
        }
    }
    elsif ( $UseMenuT == 3 ) {
        $menusep = q{};
        $img_out =
          qq~$button_imgurl/$button_icon.$imgext|${$button_text}{$text_num}~;
    }
    else {
        $menusep =
qq~<img src='$yyhtml_root/Templates/Forum/$usestyle/buttonsep.png' class='cssbutton1' alt='' title='' />~;
        if ( $img_name eq 'gtalk' ) {
            $img_out =
              qq~<span class="buttonleft cssbutton2" style="$helpstyle">~;
            $img_out .= q~<span class="buttonright cssbutton3">~;
            $img_out .=
qq~<span class="buttonimage cssbutton4 cursor" style="background-image: url($button_imgurl/$button_icon.$imgext);" onclick="window.open('$scripturl?action=setgtalk;gtalkname=$thegtalkuser','','height=80,width=340,menubar=0,toolbar=0,scrollbars=0,resizable=1'); return false" title="${$button_text}{$alt_num}">~;
            $img_out .=
qq~<span class="buttontext cssbutton5">${$button_text}{$text_num}</span></span></span></span>~;
        }
        else {
            $img_out =
qq~<span class="buttonleft cssbutton2" title="${$alt_text}{$alt_num}" style="$helpstyle">~;
            $img_out .= q~<span class="buttonright cssbutton3">~;
            $img_out .=
qq~<span class="buttonimage cssbutton4" style="background-image: url($button_imgurl/$button_icon.$imgext);">~;
            $img_out .=
qq~<span class="buttontext cssbutton5">${$button_text}{$text_num}</span></span></span></span>~;
        }
    }
    return $img_out;
}

1;
