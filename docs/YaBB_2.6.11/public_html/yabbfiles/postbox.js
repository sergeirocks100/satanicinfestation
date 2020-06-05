//##############################################################################
//# postbox.js                                                                 #
//##############################################################################
//# YaBB: Yet another Bulletin Board                                           #
//# Open-Source Community Software for Webmasters                              #
//# Version:        YaBB 2.6.11                                                #
//# Packaged:       December 2, 2014                                           #
//# Distributed by: http://www.yabbforum.com                                   #
//# ===========================================================================#
//# Copyright (c) 2000-2014 YaBB (www.yabbforum.com) - All Rights Reserved.    #
//# Software by:  The YaBB Development Team                                    #
//#               with assistance from the YaBB community.                     #
//##############################################################################

//YaBB 2.6.11 $Revision: 1611 $
function selcodelang() {
    if (document.getElementById("codelang").style.display == "none")
        document.getElementById("codelang").style.display = "inline-block";
    else
        document.getElementById("codelang").style.display = "none";
        document.getElementById("codelang").style.zIndex = "100";

        var openbox = document.getElementsByTagName("div");
        for (var i = 0; i < openbox.length; i++) {
        if (openbox[i].className == "ubboptions" && openbox[i].id != "codelang") {
            openbox[i].style.display = "none";
        }
    }
}

function syntaxlang(lang, optnum) {
    AddSelText("[code"+lang+"]","[/code]");
    document.getElementById("codesyntax").options[optnum].selected = false;
    document.getElementById("codelang").style.display = "none";
}

function bulletset() {
    if (document.getElementById("bullets").style.display == "none")
        document.getElementById("bullets").style.display = "block";
    else
        document.getElementById("bullets").style.display = "none";

    document.getElementById("bullets").style.zIndex = "100";

    var openbox = document.getElementsByTagName("div");
    for (var i = 0; i < openbox.length; i++) {
        if (openbox[i].className == "ubboptions" && openbox[i].id != "bullets") {
            openbox[i].style.display = "none";
        }
    }
}

function showbullets(bullet) {
    AddSelText("[list "+bullet+"][*]", "[/list]");
}

function olist() {
    AddSelText("[olist][*]", "[/olist]");
}

function ulist() {
    AddSelText("[list][*]", "[/list]");
}

// Palette
function tohex(i) {
    a2 = '';
    ihex = hexQuot(i);
    idiff = eval(i + '-(' + ihex + '*16)');
    a2 = itohex(idiff) + a2;
    while( ihex >= 16) {
        itmp = hexQuot(ihex);
        idiff = eval(ihex + '-(' + itmp + '*16)');
        a2 = itohex(idiff) + a2;
        ihex = itmp;
    }
    a1 = itohex(ihex);
    return a1 + a2 ;
}

function hexQuot(i) {
    return Math.floor(eval(i +'/16'));
}

function itohex(i) {
    if( i === 0) { aa = '0' }
    else { if( i == 1 ) { aa = '1' }
    else { if( i == 2 ) { aa = '2' }
    else { if( i == 3 ) { aa = '3' }
    else { if( i == 4 ) { aa = '4' }
    else { if( i == 5 ) { aa = '5' }
    else { if( i == 6 ) { aa = '6' }
    else { if( i == 7 ) { aa = '7' }
    else { if( i == 8 ) { aa = '8' }
    else { if( i == 9 ) { aa = '9' }
    else { if( i == 10) { aa = 'a' }
    else { if( i == 11) { aa = 'b' }
    else { if( i == 12) { aa = 'c' }
    else { if( i == 13) { aa = 'd' }
    else { if( i == 14) { aa = 'e' }
    else { if( i == 15) { aa = 'f' }
    }}}}}}}}}}}}}}}
    return aa;
}
