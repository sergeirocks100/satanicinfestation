###############################################################################
# Palette.pm                                                                  #
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

$palettepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub ColorPicker {
    my $picktask = $INFO{'task'};

    if ( $INFO{'palnr'} && $iamadmin ) {
        my @new_pal;
        for my $i ( 0 .. ( @pallist - 1 ) ) {
            if ( $i == ( $INFO{'palnr'} - 1 ) && $INFO{'palcolor'} ) {
                push @new_pal, "#$INFO{'palcolor'}";
            }
            else { push @new_pal, "$pallist[$i]"; }
        }
        @pallist = @new_pal;

        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');
    }

    $gzcomp = 0;
    print_output_header();

    print qq~
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$abbr_lang" lang="$abbr_lang">
<head>
<title>Palette</title>
<meta http-equiv="Content-Type" content="text/html; charset=$yymycharset" />
<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />

<script type="text/javascript">
var picktask = '$picktask';

function Pickshowcolor(color) {
    if ( c=color.match(/rgb\\((\\d+?)\\, (\\d+?)\\, (\\d+?)\\)/i) ) {
        var rhex = tohex(c[1]);
        var ghex = tohex(c[2]);
        var bhex = tohex(c[3]);
        var newcolor = '#'+rhex+ghex+bhex;
    }
    else {
        newcolor = color;
    }
    if(picktask == "post") {
        passcolor=newcolor.replace(/#/, "");
        if(document.getElementById("defpal1").checked) {
            opener.document.getElementById("defaultpal1").style.backgroundColor=newcolor;
            location.href='$scripturl?action=palette;palnr=1;palcolor=' + passcolor + ';task=$picktask';
        }
        else if(document.getElementById("defpal2").checked) {
            opener.document.getElementById("defaultpal2").style.backgroundColor=newcolor;
            location.href='$scripturl?action=palette;palnr=2;palcolor=' + passcolor + ';task=$picktask';
        }
        else if(document.getElementById("defpal3").checked) {
            opener.document.getElementById("defaultpal3").style.backgroundColor=newcolor;
            location.href='$scripturl?action=palette;palnr=3;palcolor=' + passcolor + ';task=$picktask';
        }
        else if(document.getElementById("defpal4").checked) {
            opener.document.getElementById("defaultpal4").style.backgroundColor=newcolor;
            location.href='$scripturl?action=palette;palnr=4;palcolor=' + passcolor + ';task=$picktask';
        }
        else if(document.getElementById("defpal5").checked) {
            opener.document.getElementById("defaultpal5").style.backgroundColor=newcolor;
            location.href="$scripturl?action=palette;palnr=5;palcolor=" + passcolor + ';task=$picktask';
        }
        else if(document.getElementById("defpal6").checked) {
            opener.document.getElementById("defaultpal6").style.backgroundColor=newcolor;
            location.href='$scripturl?action=palette;palnr=6;palcolor=' + passcolor + ';task=$picktask';
        }
        else {
            window.close();
            opener.AddSelText("[color="+newcolor+"]","[/color]");
        }
    }
    else {
        if(picktask == "templ") opener.previewColor(newcolor);
        if(picktask == "templ_0") opener.previewColor_0(newcolor);
        if(picktask == "templ_1") opener.previewColor_1(newcolor);
    }
//  window.close();
}

</script>
</head>

<body>
<div class="windowbg" style="position: absolute; top: 0px; left: 0px; width: 300px; height: 308px; border: 1px black outset;">
<div style="position: relative; top: 4px; left: 5px; width: 288px; height: 209px; padding-left: 1px; padding-top: 1px; border: 0px; background-color: black;">~
      or croak "$croak{'print'} colorpicker";

    foreach my $z ( 0 .. 255 ) {
        showcolor($z);
    }
    print q~
    <span class="showcolor" style="background-color: #222222;" onclick="Pickshowcolor('#222222')">&nbsp;</span>
    <span class="showcolor" style="background-color: #333333;" onclick="Pickshowcolor('#333333')">&nbsp;</span>
    <span class="showcolor" style="background-color: #444444;" onclick="Pickshowcolor('#444444')">&nbsp;</span>
    <span class="showcolor" style="background-color: #555555;" onclick="Pickshowcolor('#555555')">&nbsp;</span>
    <span class="showcolor" style="background-color: #666666;" onclick="Pickshowcolor('#666666')">&nbsp;</span>
    <span class="showcolor" style="background-color: #777777;" onclick="Pickshowcolor('#777777')">&nbsp;</span>
    <span class="showcolor" style="background-color: #888888;" onclick="Pickshowcolor('#888888')">&nbsp;</span>
    <span class="showcolor" style="background-color: #aaaaaa;" onclick="Pickshowcolor('#aaaaaa')">&nbsp;</span>
    <span class="showcolor" style="background-color: #bbbbbb;" onclick="Pickshowcolor('#bbbbbb')">&nbsp;</span>
    <span class="showcolor" style="background-color: #cccccc;" onclick="Pickshowcolor('#cccccc')">&nbsp;</span>
    <span class="showcolor" style="background-color: #dddddd;" onclick="Pickshowcolor('#dddddd')">&nbsp;</span>
    <span class="showcolor" style="background-color: #eeeeee;" onclick="Pickshowcolor('#eeeeee')">&nbsp;</span>
    <form name="dodefpal" id="dodefpal" action="">~
      or croak "$croak{'print'} input";

    if ( $iamadmin && $picktask eq 'post' ) {
        print qq~
    <span id="defpal_1" class="defpalx" style="background-color: $pallist[0]"><input type="radio" name="defpal" id="defpal1" value="defcolor1" class="defpal_b" style="background-color: $pallist[0];" title="Default palette" /></span>
    <span id="defpal_2" class="defpalx" style="background-color:$pallist[1]"><input type="radio" name="defpal" id="defpal2" value="defcolor2" style="background-color:$pallist[1];" class="defpal_b" title="Default palette" /></span>
    <span id="defpal_3" style="background-color:$pallist[2]" class="defpalx"><input type="radio" name="defpal" id="defpal3" value="defcolor3" style="background-color:$pallist[2];" class="defpal_b" title="Default palette" /></span>
    <span id="defpal_4" style="background-color:$pallist[3]" class="defpalx"><input type="radio" name="defpal" id="defpal4" value="defcolor4" style="background-color:$pallist[3];" class="defpal_b" title="Default palette" /></span>
    <span id="defpal_5" style="background-color:$pallist[4]" class="defpalx"><input type="radio" name="defpal" id="defpal5" value="defcolor5" style="background-color:$pallist[4];" class="defpal_b" title="Default palette" /></span>
    <span id="defpal_6" style="background-color:$pallist[5]" class="defpalx"><input type="radio" name="defpal" id="defpal6" value="defcolor6" style="background-color:$pallist[5];" class="defpal_b" title="Default palette" /></span>~
          or croak "$croak{'print'} input";
    }
    else {
        print q~
    <input type="hidden" id="defpal1" value="" />
    <input type="hidden" id="defpal2" value="" />
    <input type="hidden" id="defpal3" value="" />
    <input type="hidden" id="defpal4" value="" />
    <input type="hidden" id="defpal5" value="" />
    <input type="hidden" id="defpal6" value="" />
    ~ or croak "$croak{'print'} input";
    }

    print qq~
    <input type="submit" class="none" /></form>
</div>
<div style="position: relative; top: 9px; left: 5px; width: 289px; height: 17px; border: 1px black solid;">
    <span id="viewcolor" style="float: left; width: 192px; height: 17px; border-right: 1px black solid; font-size: 5px; cursor: pointer;" onclick="Pickshowcolor(this.style.backgroundColor)">&nbsp;</span>
    <span style="float: right; width: 72px; height: 15px;">
    <input class="windowbg" name="viewcode" id="viewcode" type="text" style="width: 70px; font-size: 11px; border: 0px; display: inline;" readonly="readonly" />
    </span>
</div>
<div class="catbg" style="position: relative; top: 15px; left: 10px; width: 277px; height: 56px; border-width: 1px; border-style: outset;">
    <img src="$defaultimagesdir/knapbagrms01.gif" alt="" style="position:absolute; top:0; left:0; z-index:1; width:275px; height:16px;" />
    <img src="$defaultimagesdir/knapred.gif" id="knapImg1" alt="" class="skyd" style="position:absolute; left:4px; top:2px; cursor:pointer; z-index:2; width:13px; height:15px;" />
    <img src="$defaultimagesdir/knapbagrms01.gif" alt="" style="position:absolute; top:16px; left:0; z-index:1; width:275px; height:16px;" />
    <img src="$defaultimagesdir/knapgreen.gif" id="knapImg2" alt="" class="skyd" style="position:absolute; left:4px; top:18px; cursor:pointer; z-index:2; width:13px; height:15px;" />
    <img src="$defaultimagesdir/knapbagrms01.gif" alt="" style="position:absolute; top:32px; left:0; z-index:1; width:275px; height:16px;" />
    <img src="$defaultimagesdir/knapblue.gif" id="knapImg3" alt="" class="skyd" style="position:absolute; left:4px; top:34px; cursor:pointer; z-index:2; width:13px; height:15px;" />
</div>
</div>

<script src="$yyhtml_root/palette.js" type="text/javascript"></script>

</body>
</html>~ or croak "$croak{'print'} body";
    return;
}

sub showcolor {

    #deep nest removed to sub#
    my ($z) = @_;
    if ( $z % 51 == 0 ) {
        my $c1 = sprintf '%02x', $z;
        foreach my $y ( 0 .. 255 ) {
            if ( $y % 51 == 0 ) {
                my $c2 = sprintf '%02x', $y;
                foreach my $x ( 0 .. 255 ) {
                    if ( $x % 51 == 0 ) {
                        my $c3 = sprintf '%02x', $x;
                        print
qq~\n    <span title="#$c3$c2$c1" class="deftrows" style="background-color: #$c3$c2$c1;" onclick="Pickshowcolor('#$c3$c2$c1')">&nbsp;</span>~
                          or croak "$croak{'print'} span";
                    }
                }
            }
        }
    }
    return;
}
1;
