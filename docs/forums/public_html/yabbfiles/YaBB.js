//##############################################################################
//# YaBB.js                                                                    #
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

// DocClick object for registering multiple document.onclick events
var DocClick = new Array();

var ev;
var addQuote;

function DocClicked(e) {
    ev = e;
    if(DocClick != null) {
        for (var i = 0; i < DocClick.length; i++) {
            eval(DocClick[i]);
        }
    }
}

document.onclick = DocClicked;

// Resize the pop up box and its iframe
function ResizeIFrame(height) {
    var winheight = window.innerHeight === undefined ? document.documentElement.clientHeight : window.innerHeight;
    var imagealert = document.getElementById("ImageAlert");
    if (height + 28 > winheight - 22) {
        height = winheight - 50;
    }
    document.getElementById("ImageAlertIFrame").height = height + "px";
    document.getElementById("ImageAlertLoad").style.display = "none";
    imagealert.style.marginTop = parseInt(-(height + 20) / 2, 10) + "px";
}

function IFrameShrink() {
    document.getElementById("ImageAlertIFrame").height = "0px";
}

// Caps Lock and Not Allowed Characters detection
function capsLock(eve, ident) {
    var keyCode = eve.keyCode ? eve.keyCode : eve.which;
    var shiftKey = eve.shiftKey ? eve.shiftKey : ((keyCode == 16) ? true : false);

    // check for Caps Lock
    if (((keyCode > 64 && keyCode < 91) && !shiftKey) || ((keyCode > 96 && keyCode < 123) && shiftKey)) {
        document.getElementById(ident + '_char').style.display = 'none';
        document.getElementById(ident).style.display = 'block';
    } else {
        document.getElementById(ident).style.display = 'none';

        // check for Not Allowed Characters
        character = String.fromCharCode(keyCode);
        if (((keyCode > 31 && keyCode < 127) || keyCode > 159) && (/[^\s\w!@#$%\^&\*\(\)\+\|`~\-=\\:;'",\.\/\?\[\]\{\}]/.test)(character)) {
            document.getElementById(ident + '_char').style.display = 'block';
            document.getElementById(ident + '_character').childNodes[0].nodeValue = character;
        } else {
            document.getElementById(ident + '_char').style.display = 'none';
        }
    }
}

// scroll fix for IE
window.onload = function () {
    if (document.all) {
        var codeFix = document.all.tags("div");
        var codeI;
        for (codeI = 0; codeI < codeFix.length; codeI++) {
            if (codeFix[codeI].className == "scroll" && (codeFix[codeI].scrollWidth > codeFix[codeI].clientWidth || codeFix[codeI].clientWidth === 0))
            codeFix[codeI].style.height = (codeFix[codeI].clientHeight + 34) + "px";
        }
    }
}


// for email decoding
function SpamInator(title,v1,v2,adr,subbody) {
    v2 = unescape(v2);
    var v3 = '';
    for (var v4 = 0; v4 < v1.length; v4++) { v3 += String.fromCharCode(v1.charCodeAt(v4)^v2.charCodeAt(v4)); }
    if (!title) title = v3;
    document.write('<a href="javascript:void(0)" onclick="window.location=\'' + adr + v3 + subbody + '\'">' + title + '</a>');
}

var hideTimer = null;
var lastOpen = null;
function quickLinks(num) {
    closeLinks(lastOpen);
    document.getElementById(num).style.display = "inline-block";
    document.getElementById(num).parentNode.style.zIndex = "1000";
    lastOpen = num;
}
function quickLinks2(num) {
    closeLinks(lastOpen);
    document.getElementById("ql"+num).style.display = "inline-block";
    document.getElementById("ql"+num).parentNode.style.zIndex = "1000";
    lastOpen = "ql"+num;
}
function TimeClose(num) {
    hideTimer = setTimeout("closeLinks('"+num+"')", 1000);
}
function keepLinks(num) {
    clearTimeout(hideTimer);
    hideTimer = null;
}
function closeLinks(num) {
    if(lastOpen != null) {
        document.getElementById(num).style.display = "none";
        document.getElementById(num).parentNode.style.zIndex = "0";
    }
    lastOpen = null;
    clearTimeout(hideTimer);
    hideTimer = null;
}

DocClick.push("blurLinks()");

function blurLinks(){
    if(lastOpen != null) {
        var target = (ev && ev.target) || (event && event.srcElement);
        var obj = document.getElementById(lastOpen);
        var obj2 = obj.parentNode;
        if (target != obj && target != obj2) { closeLinks(lastOpen); }
    }
}


// for email
function checkMailaddr(theMailField) {
    if (/^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/i.test(theMailField)) return true;
    return false;
}


// for attachments
function selectNewattach(file_id) {
    document.getElementById("w_file"+file_id).options[1].selected = true;
}


// for quote buttons
var quote_selection = new Array();

function quoteSelection(quote_name, quote_topic_id, quote_msg_id, quote_date, quote_message) {
    if ((quote_selection[quote_msg_id] && quote_selection[quote_msg_id] != '') || (quote_message && quote_message != '')) {
        if (quote_message) quote_selection[quote_msg_id] = unescape(quote_message);
        AddText('[quote author=' + quote_name + ' link=' + quote_topic_id + '/' + quote_msg_id + '#' + quote_msg_id + ' date=' + quote_date + ']' + quote_selection[quote_msg_id] + '[/quote]\r\n');
        quote_selection[quote_msg_id] = '';
        quote_message = '';
    } else {
        alertqq();
    }
}

function contains(node, container) {
    while (node) {
        if (node == container) return true;
        node = node.parentNode;
    }
    return false;
}

function inElement(el) {
    if (typeof window.getSelection != "undefined") {
        var sel = window.getSelection();
        if (sel.rangeCount) {
            for (var i = 0; i < sel.rangeCount; ++i) {
                if (!contains(sel.getRangeAt(i).commonAncestorContainer, el)) return false;
            }
            return true;
        }
    }
    else if (typeof document.selection != "undefined") return contains(sel.createRange().parentElement(), el);
    return false;
}

function get_selection(msg_id, qinfo) {
    var srcObj = document.getElementById ('mq' + msg_id);
    if (!inElement(srcObj)) return false;
    var str = new Array();
    var container = document.createElement("div");
    if (typeof window.getSelection != "undefined") {
        var sel = window.getSelection();
        if (sel.rangeCount) {
            for (var i = 0; i < sel.rangeCount; ++i) {
                container.appendChild(sel.getRangeAt(i).cloneContents());
            }
        }
    }
    else if (typeof document.selection != "undefined") {
        if (document.selection.type == "Text") {
            container.appendChild(document.selection.createRange().htmlText);
        }
    }

    str = container.innerHTML;

    function rgbToHex(r, g, b) {
        var rgb = b | (g << 8) | (r << 16);
        trhex = (0x1000000 | rgb).toString(16).substring(1);
        str = str.replace(/rgb\((\d+), (\d+), (\d+)\)/i, "#" + trhex);
    }

    while(iergb=str.match(/rgb\((\d+), (\d+), (\d+)\);/i)) { rgbToHex(iergb[1],iergb[2],iergb[3]) }

    str = str.replace(/\r/g, "");
    str = str.replace(/\n/g, "[codbr]");
    str = str.replace(/on(load|click|dbclick|mouseover|mousedown|mouseup)="[^"]+"/ig, "");
    str = str.replace(/<script[^>]*?>([\w\W]*?)<\/script>/ig, "");
    str = str.replace(/<i><span style="color: #FF0000;"><b>(.+?)<\/b><\/span> (.*?)\s*<\/i>/ig, "\/me $2");

    qstr = qinfo.split(/\|/);

    function nstsquoteInfo(sqlink, sqmess) {
        var allInfo = '';
        for (var i=0; i < qstr.length; i++) {
            eachinfo = qstr[i].split(/-/);
            if (eachinfo[1] == sqlink) {
                allInfo = ' author=' + eachinfo[0] + ' link=' + eachinfo[1] + ' date=' + eachinfo[2];
                break;
            }
        }
        str = str.replace(/<a class="message" href="http:\/\/(.+?)num=([0-9\/\#]+?)">(.*?)<\/a>\s*(.+?)<br[^>]*><div class="quote" id="(.+?)"[^>]*>(.*?)<\/div><\!--\5-->/i, "[quote" + allInfo + "]" + sqmess + "[/quote]");

        str = str.replace(/<a class="message" href="http:\/\/(.+?)num=([0-9\/\#]+?)">(.*?)<\/a>\s*(.+?)<br[^>]*><div (.*?) id="(.+?)" class="quote"[^>]*>(.*?)<\/div><\!--\6-->/i, "[quote" + allInfo + "]" + sqmess + "[/quote]");

    }
    while ( b=str.match(/<a class="message" href="http:\/\/(.+?)num=([0-9\/\#]+?)">(.*?)<\/a>\s*(.+?)<br[^>]*><div class="quote" id="(.+?)"[^>]*>(.*?)<\/div><\!--\5-->/i) ) {
        nstsquoteInfo(b[2], b[6]);
    }
    while ( b=str.match(/<a class="message" href="http:\/\/(.+?)num=([0-9\/\#]+?)">(.*?)<\/a>\s*(.+?)<br[^>]*><div (.*?) id="(.+?)" class="quote"[^>]*>(.*?)<\/div><\!--\6-->/i) ) {
        nstsquoteInfo(b[2], b[7]);
    }

    function simplequoteInfo(ssqmess) {
        str = str.replace(/<b>(.+?)<\/b><br[^>]*>(<div class="quote"[^>]*>)([^\2]*?)<\/div>/i, "[quote]" + ssqmess + "[/quote]");
    }
    while ( bs=str.match(/<b>(.+?)<\/b><br[^>]*>(<div class="quote"[^>]*>)([^\2]*?)<\/div>/i) ) {
        simplequoteInfo(bs[3]);
    }

    str = str.replace(/<p style="text-align:(.*)">(.*?)<\/p>/ig, "[$1]$2[\/$1]");
    str = str.replace(/<img class="smil"(.*?)data-rel="(\S.+?)"(.*?)>/ig, "$2");
    function imagemsg(ul, s) {
        var wid = '';
        var hig = '';
        var ali = '';
        var alt = '';
        var shd = '';
        if (/width="([\d]+?)"/.test(s)) wid = s.replace(/^(.+?) width="([\d]+?)"(.*?)$/i, " width=$2");
        if (/height="([\d]+?)"/.test(s)) hig = s.replace(/^(.+?) height="([\d]+?)"(.*?)$/i, " height=$2");
        if (/align="([\w]+?)"/.test(s)) ali = s.replace(/^(.+?) align="([\w]+?)"(.*?)$/i, " align=$2");
        if (/alt="(.+?)"/.test(s)) alt = s.replace(/^(.+?) alt="(.+?)"(.*?)$/i, " alt=$2");
        if (/shadow:\s([\d]+?)px/.test(s)) shd = s.replace(/^(.+?)shadow:\s([\d]+?)px(.*?)$/i, " shadow=$2");
        var imgubb = "[img" + wid + hig + ali + alt + shd + "]" + ul + "[/img]";
        str = str.replace(/<img[^>]+src="([^"]+)" (.*?)>/i, imgubb);
    }
    while(pcr=str.match(/<img[^>]+src="([^"]+)" (.*?)>/i)) { imagemsg(pcr[1],pcr[2]) }

    str = str.replace(/<b>(.+?)<\/b>(<pre(.*?)class=)/ig,"$2");
    function codemsg(ct, cm) {
        var ctype = ct;
        var ctext = cm;
        ctext = ctext.replace(/\[codbr\]/g,"\n");
        ctext = ctext.replace(/\n*$/,"");
        ctext = ctext.replace(/<span class="sh_(.+?)">(.+?)<\/span>/ig,"$2");
        ctype = ctype.replace(/ sh_sourceCode/,"");
        ctype = ctype.replace(/sh_(.+)/, " $1");
        if (ctype == 'code') ctype = "";
        var codeubb = "[code" + ctype + "]" + ctext + "[/code]";
        str = str.replace(/<pre(.*?)class="(.+?)"[^>]*?>(.+?)<\/pre>/i, codeubb);
    }
    while(ccr=str.match(/<pre(.*?)class="(.+?)"[^>]*>(.+?)<\/pre>/i)) { codemsg(ccr[2],ccr[3]) }

    str = str.replace(/<span class="sh_(.+?)">(.+?)<\/span>/ig, "$2");
    str = str.replace(/<span style="(.*?)font-size:\s*(\d+)(px|pt);">(.+?)<\/span><\!--size-->/ig, "[size=$2]$4[/size]");
    str = str.replace(/<span style="(.*?)font-family:\s*(.+?);">(.+?)<\/span><\!--font-->/ig, "[font=$2]$3[/font]");
    str = str.replace(/<span style="(.*?)color:\s*(.+?);">(.+?)<\/span><\!--color-->/ig, "[color=$2]$3[/color]");
    str = str.replace(/<div style="text-align: left;">(.+?)<\/div><\!--left-->/ig, "[left]$1[/left]");
    str = str.replace(/<div style="text-align: right;">(.+?)<\/div><\!--right-->/ig, "[right]$1[/right]");
    str = str.replace(/<div style="text-align: justify;">(.+?)<\/div><\!--justify-->/ig, "[justify]$1[/justify]");
    str = str.replace(/<b>(.+?)<\/b><br[^>]*><div(.*?)class="editbg"[^>]*>(.+?)<\/div><\!--edit-->/ig, "[edit]$3[/edit]");
    str = str.replace(/<span class="u">(.+?)<\/span><\!--underline-->/ig, "[u]$1[/u]");
    str = str.replace(/<span style="text-decoration: line-through">(.+?)<\/span><\!--linethrough-->/ig, "[s]$1[/s]");
    str = str.replace(/<span class="highlight">(.+?)<\/span><\!--highlight-->/ig, "[highlight]$1[/highlight]");
    str = str.replace(/&nbsp;/ig, " ");
    str = str.replace(/<\/p>/ig, "\n");
    str = str.replace(/<hr(.*?)class="hr"[^>]*>/ig, "[hr]");
    str = str.replace(/<br[^>]*>/ig, "\n");
    str = str.replace(/<([\/]?)marquee>/ig, "[$1move]");
    str = str.replace(/<ul style="(.+?)(bull-(.+?))\.gif\)">/ig, "[list $2]");
    str = str.replace(/<([\/]?)ul>/ig, "[$1list]");
    str = str.replace(/<([\/]?)ol>/ig, "[$1olist]");
    str = str.replace(/<li>/ig, "[*]");
    str = str.replace(/<\/li>/ig, "\n");
    str = str.replace(/<([\/]?)table>/ig, "[$1table]");
    str = str.replace(/<([\/]?)tr>/ig, "[$1tr]");
    str = str.replace(/<([\/]?)td>/ig, "[$1td]");
    str = str.replace(/<([\/]?)tt>/ig, "[$1tt]");
    str = str.replace(/<([\/]?)sup>/ig, "[$1sup]");
    str = str.replace(/<([\/]?)sub>/ig, "[$1sub]");
    str = str.replace(/<([\/]?)b>/ig, "[$1b]");
    str = str.replace(/<([\/]?)strong>/ig, "[$1b]");
    str = str.replace(/<([\/]?)u>/ig, "[$1u]");
    str = str.replace(/<([\/]?)i>/ig, "[$1i]");
    str = str.replace(/<([\/]?)s>/ig, "[$1s]");
    str = str.replace(/<([\/]?)em>/ig, "[$1i]");
    str = str.replace(/<([\/]?)center>/ig, "[$1center]");
    str = str.replace(/<a[^>]+href="mailto:(\S+?\@\S+?)">\1<\/a>/ig, "[email]$1[/email]");
    str = str.replace(/<a[^>]+href="mailto:(\S+?\@\S+?)">([^\1]*?)<\/a>/ig, "[email=$1]$2[/email]");
    str = str.replace(/<a[^>]+href="(http:\/\/)([^"]+)"[^>]*>\2<\/a>/ig, "[url]$2[/url]");
    str = str.replace(/<a[^>]+href="(http:\/\/[^"]+)"[^>]*>\1<\/a>/ig, "[url]$1[/url]");
    str = str.replace(/<a[^>]+href="(http:\/\/)([^"]+)"[^>]*>([^\2]*?)<\/a>/ig, "[url=$1$2]$3[/url]");
    str = str.replace(/&amp;/g, "&");
    str = str.replace(/\n /g, "\n");
    str = str.replace(/ \n/g, "\n");
    str = str.replace(/&quot;/g, "\"");
    str = str.replace(/<[^>]*?>/g, "");
    str = str.replace(/&lt;/g, "<");
    str = str.replace(/&gt;/g, ">");
    str = str.replace(/\[codbr\]/g, "\n");
    str = str.replace(/; display: inline/g, "");
    str = str.replace(/\[url=([^\]]+)\](\[img(.*?)\]\1\[\/img\])\[\/url\]/g, "$2");
    quote_selection[msg_id] = str;
}

function InsertQuote() {
    if (addQuote && addQuote != "") {
        eval(addQuote);
        addQuote = "";
    }
}

// for image resizing
var noimgdir, noimgtitle;
function resize_images() {
    var tmp_array = new Array ();
    for (var i = 0; i < img_resize_names.length; i++) {
        var tmp_image_name = img_resize_names[i];

        var maxwidth  = 0;
        var maxheight = 0;
        var type = (tmp_image_name.split("_", 1))[0];
        if (type == 'avatar') {
            maxwidth  = avatar_img_w;
            maxheight = avatar_img_h;
        } else if (type == 'avatarml') {
            maxwidth  = avatarml_img_w;
            maxheight = avatarml_img_h;
        } else if (type == 'post') {
            maxwidth  = post_img_w;
            maxheight = post_img_h;
        } else if (type == 'attach') {
            maxwidth  = attach_img_w;
            maxheight = attach_img_h;
        } else if (type == 'signat') {
            maxwidth  = signat_img_w;
            maxheight = signat_img_h;
        } else if (type == 'brd') {
            maxwidth  = brd_img_w;
            maxheight = brd_img_h;
        }

        if ((fix_avatar_size && type == 'avatar') || (fix_avatarml_size && type == 'avatarml') || (fix_post_size && type == 'post') || (fix_attach_size && type == 'attach') || (fix_signat_size && type == 'signat')|| (fix_brd_size && type == 'brd')) {
            if (maxwidth)  document.images[tmp_image_name].width  = maxwidth;
            if (maxheight) document.images[tmp_image_name].height = maxheight;
            document.images[tmp_image_name].style.display = 'inline';
            continue;
        }

        if (document.images[tmp_image_name].complete === false) {
            tmp_array[tmp_array.length] = tmp_image_name;
            // The following is needed since Opera does not load/show
            // style.display='none' images if they are not already in cache.
            if (/Opera/i.test(navigator.userAgent)) {
                document.images[tmp_image_name].width  = document.images[tmp_image_name].width  || 0;
                document.images[tmp_image_name].height = document.images[tmp_image_name].height || 0;
                document.images[tmp_image_name].style.display = 'inline';
            }
            continue;
        }

        var tmp_image = new Image;
        tmp_image.src = document.images[tmp_image_name].src;

        var tmpwidth  = document.images[tmp_image_name].width  || tmp_image.width;
        var tmpheight = document.images[tmp_image_name].height || tmp_image.height;

        if (!tmpwidth && !tmpheight) {
            tmp_array[tmp_array.length] = tmp_image_name;
            continue;
        }

        if (maxwidth !== 0 && tmpwidth > maxwidth) {
            tmpheight = tmpheight * maxwidth / tmpwidth;
            tmpwidth  = maxwidth;
        }

        if (maxheight !== 0 && tmpheight > maxheight) {
            tmpwidth  = tmpwidth * maxheight / tmpheight;
            tmpheight = maxheight;
        }

        document.images[tmp_image_name].width  = tmpwidth;
        document.images[tmp_image_name].height = tmpheight;
        document.images[tmp_image_name].style.display = 'inline';
    }

    if (tmp_array.length > 0 && resize_time < 350) {
        img_resize_names = tmp_array;
        if (resize_time == 290) {
            for (var i = 0; i < img_resize_names.length; i++) {
                var tmp_image_name = img_resize_names[i];
                document.images[tmp_image_name].src = noimgdir + "/noimg.gif";
                document.images[tmp_image_name].title = noimgtitle;
            }
        }
        setTimeout("resize_time++; resize_images();", 100);

    // To prevent window from jumping to other place because
    // of image resize after window is set to the ancor this is needed:
//  } else if (location.hash) {
//      location.href = location.hash;
// removed per Carsten's recommendation - code does not prevent jump
    }
}

function resize_brd_images(img) {
        var maxwidth  = brd_img_idw;
        var maxheight = brd_img_idh;
        if ( fix_brd_size ) {
            if (maxwidth)  img.width  = maxwidth;
            if (maxheight) img.height = maxheight;
            img.style.display = 'inline';
        }

        if (img.complete === false) {
            // The following is needed since Opera does not load/show
            // style.display='none' images if they are not already in cache.
            if (/Opera/i.test(navigator.userAgent)) {
                img.width  = img.width  || 0;
                img.height = img.height || 0;
                img.style.display = 'inline';
            }
        }

        var tmp_image = new Image;
        tmp_image.src = img.src;

        var tmpwidth  = img.width  || tmp_image.width;
        var tmpheight = img.height || tmp_image.height;

        if (maxwidth !== 0 && tmpwidth > maxwidth) {
            tmpheight = tmpheight * maxwidth / tmpwidth;
            tmpwidth  = maxwidth;
        }

        if (maxheight !== 0 && tmpheight > maxheight) {
            tmpwidth  = tmpwidth * maxheight / tmpheight;
            tmpheight = maxheight;
        }

        img.width  = tmpwidth;
        img.height = tmpheight;
        img.style.display = 'inline';
}


/***********************************************
* New_News_Fader 1.0
*
* Fades news bi-directionally between any starting and ending color smoothly
*
* Written for YaBB by Eddy
* 14-Jan-2005
* Original 'fader.js' by NRg (allbrowsers_fader.mod v2.02 01/12/2002)
*
* Based upon uni-directional fading code from:
* Fading Scroller- © Dynamic Drive DHTML code library (www.dynamicdrive.com)
* This notice MUST stay intact for legal use
* Visit Dynamic Drive at http://www.dynamicdrive.com/ for full source code
***********************************************/

var DOM2 = document.getElementById;
var ie4 = document.all && !DOM2;
var fadecounter;
var fcontent = new Array();
var begintag = '';
var closetag = '';

function HexToR(h) { return parseInt((cutHex(h)).substring(0,2),16) }
function HexToG(h) { return parseInt((cutHex(h)).substring(2,4),16) }
function HexToB(h) { return parseInt((cutHex(h)).substring(4,6),16) }
function cutHex(h) { return (h.charAt(0)=="#") ? h.substring(1,7) : h }

function changecontent() {
    if (index >= fcontent.length) index = 0;

    if (DOM2) {
        document.getElementById("newsdiv").style.color="rgb("+startcolor[0]+", "+startcolor[1]+", "+startcolor[2]+")";
        document.getElementById("newsdiv").innerHTML=begintag+fcontent[index]+closetag;
        if (fadelinks) linkcolorchange(1);
        colorfadeup(1);
    } else if (ie4) {
        document.all.news.innerHTML=begintag+fcontent[index]+closetag;
    }
    index++;
}

function linkcolorchange(step) {
    var obj = document.getElementById("newsdiv").getElementsByTagName("A");
    if (obj.length > 0) {
        for (i = 0; i < obj.length; i++) {
            obj[i].style.color=getstepcolor(step);
        }
    }
}

function colorfadeup(step) {
    if (step <= maxsteps) {
        document.getElementById("newsdiv").style.color = getstepcolor(step);
        if (fadelinks) linkcolorchange(step);
        step++;
        fadecounter = setTimeout("colorfadeup("+step+")", stepdelay);
    } else {
        clearTimeout(fadecounter);
        document.getElementById("newsdiv").style.color = "rgb("+endcolor[0]+", "+endcolor[1]+", "+endcolor[2]+")";
        setTimeout("colorfadedown("+maxsteps+")", delay);
    }
}

function colorfadedown(step) {
    if (step > 1) {
        step--;
        document.getElementById("newsdiv").style.color = getstepcolor(step);
        if (fadelinks) linkcolorchange(step);
        fadecounter = setTimeout("colorfadedown("+step+")", stepdelay);
    } else {
        clearTimeout(fadecounter);
        document.getElementById("newsdiv").style.color = "rgb("+startcolor[0]+", "+startcolor[1]+", "+startcolor[2]+")";
        setTimeout("changecontent()", delay / 2);
    }
}

function getstepcolor(step) {
    var diff;
    var newcolor = new Array(3);
    for (var i = 0; i < 3; i++) {
        diff = (startcolor[i] - endcolor[i]);
        if (diff > 0) newcolor[i] = startcolor[i] - (Math.round((diff/maxsteps))*step);
        else newcolor[i] = startcolor[i] + (Math.round((Math.abs(diff)/maxsteps))*step);
    }
    return ("rgb(" + newcolor[0] + ", " + newcolor[1] + ", " + newcolor[2] + ")");
}


// Dynamic clock
function WriteClock(Element_Id,s1,s2) {
    if (OurTime === 0) return;

    returnTime = Clock(s2);

    if (document.getElementById(Element_Id) && document.getElementById(Element_Id).childNodes) {
        document.getElementById(Element_Id).childNodes[0].nodeValue = s1 + returnTime;
    } else if (document.all) {
        document.all[Element_Id].innerHTML = s1 + returnTime;
    } else if (document.Element_Id && window.netscape && window.screen) {
        document.Element_Id.document.open();
        document.Element_Id.document.write(s1 + returnTime);
        document.Element_Id.document.close();
    } else {
        document.write(s1 + returnTime);
        return;
    }

    setTimeout("WriteClock('" + Element_Id + "','" + s1 + "','" + s2 + "')", 1000);
}

function Clock(ampm) {
    OurTime = new Date();
    OurTime = OurTime.getTime() - TimeDif;
    YaBBTime.setTime(OurTime);
    var sec  = YaBBTime.getSeconds();
    var min  = YaBBTime.getMinutes();
    var hour = YaBBTime.getHours();
    if (sec  < 10) sec  = "0" + sec;
    if (min  < 10) min  = "0" + min;
    if (hour < 10) hour = "0" + hour;
    if (ampm) {
        if (ampm == ' ') return (hour + ":" + min);
        hour = hour % 12 || 12;
        return (hour + ":" + min + ampm);
    }
    return (hour + ":" + min + ":" + sec);
}

// Size of messagebox and text START
var skydobject = {
    x: 0, y: 0, temp2 : null, temp3 : null, targetobj : null, skydNu : 0, delEnh : 0,

    initialize:function() {
        document.onmousedown = this.skydeKnap
        document.onmouseup = function(){
            this.skydNu = 0;
            document.getElementById('messagewidth').value = parseInt(document.getElementById('message').style.width, 10);
            document.getElementById('messageheight').value = parseInt(document.getElementById('message').style.height, 10);
        }
    },
    changeSize:function(deleEnh, knapId) {
        if (knapId == "dragImg1") {
            newwidth = oldwidth+parseInt(deleEnh, 10);
            newdragwidth = olddragwidth+parseInt(deleEnh);
            document.getElementById('message').style.width = newwidth+'px';
            document.getElementById('dragbgh').style.width = newdragwidth+'px';
            document.getElementById('dragImg2').style.width = newdragwidth+'px';
        }
        if (knapId == "dragImg2") {
            newheight = oldheight+parseInt(deleEnh, 10);
            newdragheight = olddragheight+parseInt(deleEnh, 10);
            document.getElementById('message').style.height = newheight+'px';
            document.getElementById('dragbgw').style.height = newdragheight+'px';
            document.getElementById('dragImg1').style.height = newdragheight+'px';
            document.getElementById('dragcanvas').style.height = newdragheight+'px';
        }
    },

    flytKnap:function(e) {
        var evtobj = window.event ? window.event : e;
        if (this.skydNu == 1) {
            sizestop = f_clientWidth()
            maxstop = parseInt(((sizestop*66)/100)-427, 10);
            if (maxstop > 413) maxstop = 413;
            if (maxstop < 60) maxstop = 60;

            glX = parseInt(this.targetobj.style.left, 10);
            this.targetobj.style.left = this.temp2 + evtobj.clientX - this.x + "px";
            nyX = parseInt(this.temp2 + evtobj.clientX - this.x, 10);
            if (nyX > glX) retning = "vn"; else retning = "hj";
            if (nyX < 1 && retning == "hj") { this.targetobj.style.left = 0 + "px"; nyX = 0; retning = "vn"; }
            if (nyX > maxstop && retning == "vn") { this.targetobj.style.left = maxstop + "px"; nyX = maxstop; retning = "hj"; }
            delEnh = parseInt(nyX, 10);
            var knapObj = this.targetobj.id;
            skydobject.changeSize(delEnh, knapObj);
            return false;
        }
        if (this.skydNu == 2) {
            glY = parseInt(this.targetobj.style.top);
            this.targetobj.style.top = this.temp3 + evtobj.clientY - this.y + "px";
            nyY = parseInt(this.temp3 + evtobj.clientY - this.y, 10);
            if (nyY > glY) retning = "vn"; else retning = "hj";
            if (nyY < 1 && retning == "hj") { this.targetobj.style.top = 0 + "px"; nyY = 0; retning = "vn"; }
            if (nyY > 270 && retning == "vn") { this.targetobj.style.top = 270 + "px"; nyY = 270; retning = "hj"; }
            delEnh = parseInt(nyY, 10);
            var knapObj = this.targetobj.id;
            skydobject.changeSize(delEnh, knapObj);
            return false;
        }
    },
    skydeKnap:function(e) {
        var evtobj = window.event ? window.event : e;
        this.targetobj = window.event ? event.srcElement : e.target;
        if (this.targetobj.className == "drag") {
            if (this.targetobj.id == "dragImg1") this.skydNu = 1;
            if (this.targetobj.id == "dragImg2") this.skydNu = 2;
            this.knapObj = this.targetobj;
            if (isNaN(parseInt(this.targetobj.style.left, 10))) this.targetobj.style.left = 0;
            if (isNaN(parseInt(this.targetobj.style.top, 10))) this.targetobj.style.top = 0;
            this.temp2 = parseInt(this.targetobj.style.left, 10);
            this.temp3 = parseInt(this.targetobj.style.top);
            this.x = evtobj.clientX;
            this.y = evtobj.clientY;
            if (evtobj.preventDefault) evtobj.preventDefault();
            document.onmousemove = skydobject.flytKnap;
        }
    }
} // End of: var skydobject={

function f_clientWidth() {
    return f_filterResults (
        window.innerWidth ? window.innerWidth : 0,
        document.documentElement ? document.documentElement.clientWidth : 0,
        document.body ? document.body.clientWidth : 0
    );
}

function f_filterResults(n_win, n_docel, n_body) {
    var n_result = n_win ? n_win : 0;
    if (n_docel && (!n_result || n_result > n_docel)) n_result = n_docel;
    return n_body && (!n_result || n_result > n_body) ? n_body : n_result;
}

function sizetext(sizefact) {
    orgsize = orgsize + sizefact;
    if (orgsize < 6) orgsize = 6;
    if (orgsize > 16) orgsize = 16;
    document.getElementById('message').style.fontSize = orgsize+'pt';
    document.getElementById('txtsize').value = orgsize;
}
// Size of message box, characters in message box END

function Hash() {
    this.length = 0;
    this.items = new Array();
    for (var i = 0; i < arguments.length; i += 2) {
        if (typeof(arguments[i + 1]) != 'undefined') {
            this.items[arguments[i]] = arguments[i + 1];
            this.length++;
        }
    }

    this.getItem = function(in_key) {
        return this.items[in_key];
    };
}
