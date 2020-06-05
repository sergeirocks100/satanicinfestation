###############################################################################
# ContextHelp.pm                                                              #
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
# Many thanks to Carsten Dalgaard (http://www.carsten-dalgaard.dk/)           #
# for his contribution to the YaBB community                                  #
###############################################################################
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$contexthelppmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub ContextScript {
    my ($inp) = @_;
    LoadLanguage('ContextHelp');

    $contextlst = q{};
    while( ($key, $value) = each %contextxt ) {
        if ( $key eq 'clicktip' ) {
            $contextlst .= qq~'contexttip', '$contextxt{'clicktip'}',\n~;
            }
        else {
            $contextlst .= qq~'$key', '$value',\n~;
        }
    }
    $contextlst =~ s/\,\n\Z//xsm;

    my $contextmain = qq~
var contexthash = new Hash($contextlst);
~;

    $ctmain .= qq~
    <script type="text/javascript">
    $contextmain
    </script>
    <div id="contexthlp" class="windowbg contexthlp" style="display: none;">
        <div id="contexttitle" class="titlebg contexttitle">context_title</div>
        <div id="contexttext" class="windowbg contexttext">context_text</div>
    </div>
    <div id="ctxtip" class="ctxtip" style="display: none;"></div>
    <script type="text/javascript">
    DocClick.push("hidecontexthelp()");

    function sizecontexthelp() {
        if (!document.all) {
            var wtop = window.pageYOffset;
            var wleft = window.pageXOffset;
            var wsize = parseInt(window.innerWidth / 2);
        }
        else {
            wtop = document.documentElement.scrollTop;
            wleft = document.documentElement.scrollLeft;
            wsize = parseInt(document.documentElement.clientWidth / 2);
        }
        document.getElementById("contexthlp").style.width = wsize + 'px';
        document.getElementById("contexthlp").style.left = wleft + (wsize / 2) + 'px';
        document.getElementById("contexthlp").style.top = wtop + 50 + 'px';
        document.getElementById("contexthlp").style.display = 'inline';
    }

    function showcontexthelp(conimage, contitle) {
        var conkey, contextimage, contexthelp = '';
        conkey = conimage.replace(/(.*)\\/(.*?)\\.(gif|png)/, "\$2");
        if(conkey) contextimage = '<img src=' + conimage + ' alt=" ' + contitle + '" \/>';
        else conkey = conimage;
        contexthelp = contexthash.getItem(conkey);
        if(contexthelp === '') return true;
        sizecontexthelp();
        contexthelp = contexthelp.replace(/\\[TITLE\\]/g, contitle);
        contexthelp = contexthelp.replace(/\\[BUTTON\\]/g, contextimage);
        contexthelp = contexthelp.replace(/\\[SELECT\\](.*?)\\[\\/SELECT\\]/g, '<span style=\"color: white\; background-color: darkblue\">\$1</span>');
        contexthelp = contexthelp.replace(/\\[CODE\\](.*?)\\[\\/CODE\\]/g, '<pre class=\"code\" style=\"margin: 0px\; width: 90%\; overflow: scroll\;\">\$1</pre>');
        contexthelp = contexthelp.replace(/\\[QUOTE\\](.*?)\\[\\/QUOTE\\]/g, '<div class=\"quote\" style=\"width: 90%\">\$1</div>');
        contexthelp = contexthelp.replace(/\\[EDIT\\](.*?)\\[\\/EDIT\\]/g, '<div class=\"editbg\" style=\"overflow: auto\">\$1</div>');
        contexthelp = contexthelp.replace(/\\[ME\\]\\s(.*)/g, '<span style=\"color: #FF0000\"><i>\\* $displayname \$1</i></span>');
        contexthelp = contexthelp.replace(/\\[MOVE\\](.*?)\\[\\/MOVE\\]/g, '<marquee>\$1</marquee>');
        contexthelp = contexthelp.replace(/\\[HIGHLIGHT\\](.*?)\\[\\/HIGHLIGHT\\]/g, '<span class=\"highlight\">\$1</span>');
        contexthelp = contexthelp.replace(/\\[PRE\\](.*?)\\[\\/PRE\\]/g, '<pre>\$1</pre>');
        contexthelp = contexthelp.replace(/\\[LEFT\\](.*?)\\[\\/LEFT\\]/g, '<div style=\"text-align: left\">\$1</div>');
        contexthelp = contexthelp.replace(/\\[CENTER\\](.*?)\\[\\/CENTER\\]/g, '<center>\$1</center>');
        contexthelp = contexthelp.replace(/\\[RIGHT\\](.*?)\\[\\/RIGHT\\]/g, '<div style=\"text-align: right\">\$1</div>');
        contexthelp = contexthelp.replace(/\\[RED\\](.*?)\\[\\/RED\\]/g, '<span style=\"color: #FF0000\">\$1</span>');
        document.getElementById("contexttitle").innerHTML = contextimage + ' ' + contitle;
        document.getElementById("contexttext").innerHTML = contexthelp;
        return false;
    }

    function hidecontexthelp() {
        document.getElementById("contexthlp").style.display = 'none';
    }

    var images = document.getElementsByTagName('img');
    var thetitle, tmpi;

    function tmpTitle(txtitle) {
        for(var i=0; i<images.length;i++) {
            thetitle = txtitle;
            var titlevalue = images[i].alt;
            if(titlevalue == txtitle) {
                images[i].title = '';
                tmpi = i;
            }
        }
    }

    function orgTitle() {
        images[tmpi].title = thetitle;
    }

    function contextTip(e, ctxtitle) {
        if (/Opera[\\/\\s](\\d+\\.\\d+)/.test(navigator.userAgent)) {
            var oprversion=new Number(RegExp.\$1);
            if (oprversion < 9.8) return;
        }

        var dsize = document.getElementById('ctxtip').offsetWidth;
        if (!document.all) {
            wsize = window.innerWidth;
            wleft = e.pageX - parseInt(dsize/4);
            wtop = e.pageY + 20;
        }
        else {
            var wsize = document.documentElement.clientWidth;
            var wleft = (e.clientX + document.documentElement.scrollLeft) - parseInt(dsize/4);
            var wtop = e.clientY + document.documentElement.scrollTop + 20;
        }
        if (document.getElementById('ctxtip').style.display == 'inline') {
            orgTitle();
            document.getElementById('ctxtip').style.display = 'none';
        }
        else {
            if (wleft < 2) wleft = 2;
            else if (wleft + dsize > wsize) wleft -= dsize/2;
            document.getElementById('ctxtip').style.left = wleft + 'px';
            document.getElementById('ctxtip').style.top = wtop + 'px';
            document.getElementById('ctxtip').style.display = 'inline';
            document.getElementById('ctxtip').innerHTML = ctxtitle + ' | ' + contexthash.getItem('contexttip');
            tmpTitle(ctxtitle);
        }
    }
    </script>
~;
    return;
}

1;
