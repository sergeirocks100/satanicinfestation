//##############################################################################
//# palette.js                                                                 #
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

var op = ( navigator.userAgent.indexOf( 'Opera' ) != -1 );
var konq = ( navigator.userAgent.indexOf( 'Konqueror' ) != -1 );
var saf = ( navigator.userAgent.indexOf( 'Safari' ) != -1 );
var moz = ( navigator.userAgent.indexOf( 'Gecko' ) != -1 && !saf && !konq);
var ns6 = ( document.getElementById && !document.all );
var ie = ( document.all && !op );
var rcol='00';
var gcol='00';
var bcol='00';

document.getElementById("viewcolor").style.backgroundColor = '#'+rcol+gcol+bcol;
document.getElementById("viewcode").value = '#'+rcol+gcol+bcol;

function tohex(i) {
    a2 = ''
    ihex = hexQuot(i);
    idiff = eval(i + '-(' + ihex + '*16)')
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
    if      (i === 0)  { aa = '0'; }
    else if (i == 1)  { aa = '1'; }
    else if (i == 2)  { aa = '2'; }
    else if (i == 3)  { aa = '3'; }
    else if (i == 4)  { aa = '4'; }
    else if (i == 5)  { aa = '5'; }
    else if (i == 6)  { aa = '6'; }
    else if (i == 7)  { aa = '7'; }
    else if (i == 8)  { aa = '8'; }
    else if (i == 9)  { aa = '9'; }
    else if (i == 10) { aa = 'a'; }
    else if (i == 11) { aa = 'b'; }
    else if (i == 12) { aa = 'c'; }
    else if (i == 13) { aa = 'd'; }
    else if (i == 14) { aa = 'e'; }
    else if (i == 15) { aa = 'f'; }

    return aa;
}


function setColor(deleEnh) {
    var ele = tohex(deleEnh);
    if (knapObj.id == "knapImg1") { rcol=ele; }
    if (knapObj.id == "knapImg2") { gcol=ele; }
    if (knapObj.id == "knapImg3") { bcol=ele; }
    document.getElementById("viewcolor").style.backgroundColor = '#'+rcol+gcol+bcol;
    document.getElementById("viewcode").value = '#'+rcol+gcol+bcol;
}


function saveColor() {
    skydNu = false;
}

var skydNu = false;
var x, knapObj, knappos, retning;

function flytKnap(e) {
    if (skydNu) {
        glX = parseInt(knappos);
        if(ns6) knappos = temp2 + e.clientX - x; else knappos = temp2 + event.clientX - x;
        nyX = parseInt(knappos);
        if (nyX > glX) retning = "vn"; else retning = "hj";
        if (nyX < 4 && retning == "hj") { knappos = 4; retning = "vn"; }
        if (nyX > 259 && retning == "vn") { knappos = 259; retning = "hj"; }
        knapObj.style.left = knappos + 'px';
        delEnh = parseInt(knappos)-4;
        setColor(delEnh);
        document.onmouseup = saveColor;
        return false;
    }
}

function skydeKnap(e){
    if (ns6) flytobj = e.target; else flytobj = event.srcElement;
    if (ns6) topelement = "HTML"; else topelement = "BODY";
    while (flytobj.tagName != topelement && flytobj.className != "skyd"){
        if (ns6) flytobj = flytobj.parentNode; else flytobj = flytobj.parentElement;
    }
    if (flytobj.className == "skyd"){
        skydNu = true;
        knapObj = flytobj;
        knappos = knapObj.style.left;
        temp2 = parseInt(knappos);
        if (ns6) x = e.clientX; else x = event.clientX;
        document.onmousemove = flytKnap;
        return false;
    }
}

document.onmousedown=skydeKnap;