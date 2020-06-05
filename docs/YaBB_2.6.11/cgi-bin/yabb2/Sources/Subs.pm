###############################################################################
# Subs.pm                                                                     #
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
# use warnings;
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

$subspmver = 'YaBB 2.6.11 $Revision: 1611 $';

use subs 'exit';

$yymain       = q{};
$yyjavascript = q{};
$langopt      = q{};

# set line wrap limit in Display.
$linewrap = 80;
$newswrap = 0;

# get the current date/time

$date = int( time() + $timecorrection );

# check if browser accepts encoded output
$gzaccept = $ENV{'HTTP_ACCEPT_ENCODING'} =~ /\bgzip\b/sm || $gzforce;

# parse the query string
readform();

$uid = substr $date, length($date) - 3, 3;
$session_id = $cookiesession_name;

$randaction = substr $date, 0, length($date) - 2;

$user_ip = $ENV{'REMOTE_ADDR'};
if ( $user_ip eq '127.0.0.1' ) {
    if ( $ENV{'HTTP_CLIENT_IP'} && $ENV{'HTTP_CLIENT_IP'} ne '127.0.0.1' ) {
        $user_ip = $ENV{'HTTP_CLIENT_IP'};
    }
    elsif ( $ENV{'X_CLIENT_IP'} && $ENV{'X_CLIENT_IP'} ne '127.0.0.1' ) {
        $user_ip = $ENV{'X_CLIENT_IP'};
    }
    elsif ($ENV{'HTTP_X_FORWARDED_FOR'}
        && $ENV{'HTTP_X_FORWARDED_FOR'} ne '127.0.0.1' )
    {
        $user_ip = $ENV{'HTTP_X_FORWARDED_FOR'};
    }
}

if   ( -e "$yyexec.cgi" ) { $yyext = 'cgi'; }
else                      { $yyext = 'pl'; }
if   ( -e 'AdminIndex.cgi' ) { $yyaext = 'cgi'; }
else                         { $yyaext = 'pl'; }

sub automaintenance {
    my ( $maction, $mreason ) = @_;
    if ( lc($maction) eq 'on' ) {
        fopen( MAINT, ">$vardir/maintenance.lock" );
        print {MAINT}
          qq~$maintxt{'maint'}\n~
          or croak qq~$maintxt{'maint'}~;
        fclose(MAINT);
        if ( $mreason eq 'low_disk' ) {
            LoadLanguage('Error');
            alertbox( $error_txt{'low_diskspace'} );
        }
        if ( !$maintenance ) { $maintenance = 2; }
    }
    elsif ( lc($maction) eq 'off' ) {
        unlink "$vardir/maintenance.lock"
          or fatal_error( 'cannot_open_dir', "$vardir/maintenance.lock" );
        if ( $maintenance == 2 ) { $maintenance = 0; }
    }
    return;
}

sub getnewid {
    my $newid = $date;
    while ( -e "$datadir/$newid.txt" ) { ++$newid; }
    return $newid;
}

sub undupe {
    my (@indup) = @_;
    my ( @out, $duped, );
    foreach my $check (@indup) {
        $duped = 0;
        foreach (@out) {
            if ( $_ eq $check ) { $duped = 1; last; }
        }
        if ( !$duped ) { push @out, $check; }
    }
    return @out;
}

sub exit {
    my ($inexit)                = @_;
    my $OUTPUT_AUTOFLUSH        = 1;
    my $OUTPUT_RECORD_SEPARATOR = q{};
    print q{};
    if ($child_pid) { wait; }
    CORE::exit( $inexit || 0 );
    return;
}

sub print_output_header {
    if ($header_already_printed) { return; }
    $yyxml_lang = $abbr_lang;
    $header_already_printed = 1;
    $headerstatus ||= '200 OK';
    $contenttype  ||= 'text/html';

    my $ret = $yyIIS ? "HTTP/1.0 $headerstatus\n" : "Status: $headerstatus\n";

    foreach ( $yySetCookies1, $yySetCookies2, $yySetCookies3, @otherCookies ) {
        if ($_) { $ret .= "Set-Cookie: $_\n"; }
    }

    if ( !$no_error_page ) {
        if ($yySetLocation) {
            $ret .= "Location: $yySetLocation";
        }
        else {
            if ( !$cachebehaviour ) {
                $ret .=
"Cache-Control: no-cache, must-revalidate\nPragma: no-cache\n";
            }
            if ($ETag)         { $ret .= "ETag: \"$ETag\"\n"; }
            if ($LastModified) { $ret .= "Last-Modified: $LastModified\n"; }
            if ( $gzcomp && $gzaccept ) { $ret .= "Content-Encoding: gzip\n"; }
            $ret .= "Content-Type: $contenttype";
            if ($yycharset) {$yymycharset = $yycharset;}
            if ($yymycharset) { $ret .= "; charset=$yymycharset"; }
       }
    }
    print $ret . "\r\n\r\n" or croak "$croak{'print'} ret";
    return;
}

sub print_HTML_output_and_finish {
    if ( $gzcomp && $gzaccept ) {
        my $filehandle_exists = fileno GZIP;
        if ( $gzcomp == 1 || $filehandle_exists ) {
            $OUTPUT_AUTOFLUSH = 1;
            if ( !$filehandle_exists ) {
                open GZIP, '| gzip -f' or croak "$croak{'open'} GZIP";
            }
            print {GZIP} $output or croak "$croak{'print'} GZIP";
            close GZIP or croak "$croak{'close'}";
        }
        else {
            require Compress::Zlib;
            binmode STDOUT;
            print Compress::Zlib::memGzip($output)
              or croak "$croak{'print'} ZLib";
        }
    }
    else {
        print $output;    # or croak "$croak{'print'} output";
    }
    exit;
}

sub write_cookie {
    my %params = @_;

    if ( $params{'-expires'} =~ /\+(\d+)m/xsm ) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) =
          gmtime( $date + $1 * 60 );

        $year += 1900;
        my @mos = qw(
          Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
        );
        my @dys = qw( Sun Mon Tue Wed Thu Fri Sat );
        $mon  = $mos[$mon];
        $wday = $dys[$wday];

        $params{'-expires'} = sprintf '%s, %02i-%s-%04i %02i:%02i:%02i GMT',
          $wday, $mday, $mon, $year, $hour, $min, $sec;
    }

    if ( $params{'-path'} ) { $params{'-path'} = " path=$params{'-path'};"; }
    if ( $params{'-expires'} ) {
        $params{'-expires'} = " expires=$params{'-expires'};";
    }

    return
      "$params{'-name'}=$params{'-value'};$params{'-path'}$params{'-expires'}";
}

sub redirectexit {
    $headerstatus = '302 Moved Temporarily';
    print_output_header();
    exit;
}

sub redirectmove {
    require Sources::MessageIndex;
    MessageIndex();
    return;
}

sub redirectinternal {
    if ($currentboard) {
        if   ( $INFO{'num'} ) { require Sources::Display;      Display(); }
        else                  { require Sources::MessageIndex; MessageIndex(); }
    }
    else {
        require Sources::BoardIndex;
        BoardIndex();
    }
    return;
}

sub ImgLoc {
    @img = @_;
    if ( exists $img_locs{ $img[0] } ) {
        $img_locs{ $img[0] } = $img_locs{ $img[0] };
    }
    elsif ( -e "$htmldir/Templates/Forum/$useimages/$img[0]" ) {
        $img_locs{ $img[0] } = qq~$imagesdir/$img[0]~;
    }
    else {
        $img_locs{ $img[0] } = qq~$defaultimagesdir/$img[0]~;
    }
    return $img_locs{ $img[0] };
}

sub template {
    print_output_header();

    if ( $yytitle ne $maintxt{'error_description'} ) {
        if ( ( !$iamguest || ( $iamguest && $guestaccess == 1 ) )
            && !$maintenance )
        {
            $yyforumjump = jumpto();
        }
        else { $yyforumjump = '&nbsp;'; }
    }
    $yyposition      = $yytitle;
    $yytitle         = "$mbname - $yytitle";
    $yyimages        = $imagesdir;
    $yydefaultimages = $defaultimagesdir;
    $yysyntax_js     = q{};
    $yygreyboxstyle  = q{};
    $yygrayscript    = q{};

    if (
           $INFO{'num'}
        || $action eq 'post'
        || $action eq 'modify'
        || $action eq 'preview'
        || $action eq 'search2'
        || $action eq 'imshow'
        || $action eq 'imsend'
        || $action eq 'myviewprofile'
        || $action eq 'eventcal'
        || $action eq 'help'
        || $action eq 'recenttopics'
        || $action eq 'recent'
        || $action eq 'usersrecentposts'
        || $action eq 'myusersrecentposts'
       )
    {
        $yysyntax_js = qq~
<script type="text/javascript" src="$yyhtml_root/shjs/sh_main.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_cpp.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_css.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_html.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_java.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_javascript.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_pascal.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_perl.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_php.js"></script>
<script type="text/javascript" src="$yyhtml_root/shjs/sh_sql.js"></script>
~;
        $yyjsstyle =
qq~<link rel="stylesheet" href="$yyhtml_root/shjs/styles/sh_style.css" type="text/css" />\n~;
        $yyhigh = q~<script type="text/javascript">
    sh_highlightDocument();
</script>~;

        if ($img_greybox) {
            $yygreyboxstyle =
qq~<link href="$yyhtml_root/greybox/gb_styles.css" rel="stylesheet" type="text/css" />\n~;

            $yygrayscript = qq~
<script type="text/javascript">
    var GB_ROOT_DIR = "$yyhtml_root/greybox/";
</script>
<script type="text/javascript" src="$yyhtml_root/AJS.js"></script>
<script type="text/javascript" src="$yyhtml_root/AJS_fx.js"></script>
<script type="text/javascript" src="$yyhtml_root/greybox/gb_scripts.js"></script>
~;
        }
    }

    $yystyle =
qq~<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />\n~;
    $yystyle =~ s/$usestyle\///gxsm;
    $yystyle .= $yyjsstyle;
    $yystyle .= $yygreyboxstyle;
    $yystyle .= $yyinlinestyle;

    # Carsten's 'backtotop';
    if ( !$yynavback ) { $yynavback .= q~ ~; }
    $yynavback .=
qq~$tabsep <span onclick="toTop(0)" class="cursor">$img_txt{'102'}</span> &nbsp; $tabsep~;

    if ( !$usehead ) { $usehead = q~default~; }
    $yytemplate = "$templatesdir/$usehead/$usehead.html";
    fopen( TEMPLATE, $yytemplate ) or croak("$maintxt{'23'}: $yytemplate");
    @whole_file = <TEMPLATE>;
    $output = join q{}, @whole_file;
    fclose(TEMPLATE);

    if ( $iamadmin || $iamgmod ) {
        if ($maintenance) {
            if   ($do_scramble_id) { $user = cloak($username); }
            else                   { $user = $username; }
            $yyadmin_alert .=
              qq~<br /><span class="highlight"><b>$load_txt{'616'}</b></span>~;
            $yyadmin_alert =~ s/USER/$user/sm;
        }
        $rememberbackup ||= 0;
        if ( $iamadmin && $rememberbackup > 0 ) {
            if ( $lastbackup && $date > $rememberbackup + $lastbackup ) {
                $yyadmin_alert .=
                    qq~<br /><span class="highlight"><b>$load_txt{'617'} ~
                  . timeformat($lastbackup)
                  . q~</b></span>~;
            }
        }
    }

    # to top button for fixed menu
    $yyfixtop  = qq~$img_txt{'to_top'}~;

    $yyboardname = "$mbname";
    $yyboardlink = qq~<a href="$scripturl">$mbname</a>~;

    # static/dynamic clock
    $yytime = timeformat( $date, 1 );
    my $zone = q{};
    if ( ($iamguest && $default_tz eq 'UTC') || (${ $uid . $username }{'user_tz'} eq 'UTC') || ( !$default_tz  &&  !${ $uid . $username }{'user_tz'} ) ) {
        $zone = qq~ $maintxt{'UTC'}~;
    }
    my $toffs = 0;
    if ( $enabletz ) {
        $toffs = toffs($date);
    }
    if (
        $mytimeselected != 7
        && ( ( $iamguest && $dynamic_clock )
            || ${ $uid . $username }{'dynamic_clock'} )
      )
    {
        if ( $yytime =~ /(.*?)\d+:\d+((\w+)|:\d+)?/xsm ) {
            ( $aa, $bb ) = ( $1, $3 );
        }
        $aa =~ s/<.+?>//gxsm;
        if ( $mytimeselected == 6 ) { $bb = q{ }; }
        $yytime =
qq~&nbsp;<script  type="text/javascript">\nWriteClock('yabbclock','$aa','$bb');\n</script>~;
        $yyjavascripta .=
            qq~
        var OurTime = ~
          . sprintf( '%d', ( $date + $toffs ) )
          . qq~000;\nvar YaBBTime = new Date();\nvar TimeDif = YaBBTime.getTime() - (YaBBTime.getTimezoneOffset() * 60000) - OurTime - 1000; // - 1000 compromise to transmission time~;
    }
    $yytime .= $zone;

    $yyjavascripta .= qq~
    var imagedir = "$imagesdir";
    function toTop(scrpoint) {
        window.scrollTo(0,scrpoint);
    }~;

    $yyjavascript .= q~
    function txtInFields(thefield, defaulttxt) {
        if (thefield.value == defaulttxt) thefield.value = "";
        else { if (thefield.value === "") thefield.value = defaulttxt; }
    }
    function selectAllCode(thefield) {
        var elem = document.getElementById('code' + thefield);
        if (document.selection) {
            document.selection.empty();
            var txt = document.body.createTextRange();
            txt.moveToElementText(elem);
            txt.select();
        }
        else {
            window.getSelection().removeAllRanges();
            txt = document.createRange();
            txt.setStartBefore(elem);
            txt.setEndAfter(elem);
            window.getSelection().addRange(txt);
        }
    }
    ~;
    require Sources::TabMenu;
    mainMenu();


    $yylangChooser = q{};
    if ( ( $iamguest && !$guestLang ) && $enable_guestlanguage && $guestaccess )
    {
        if ( !$langopt ) { guestLangSel(); }
        if ( $morelang > 1 ) {
            $yylangChooser =
qq~$guest_txt{'sellanguage'}: <form action="$scripturl?action=guestlang" method="post" name="sellanguage">
            <select name="guestlang" onchange="submit();">
            $langopt
            </select>
            </form>~;
        }
    }
    elsif (( $iamguest && $guestLang )
        && $enable_guestlanguage
        && $guestaccess )
    {
        if ( !$langopt ) { guestLangSel(); }
        if ( $morelang > 1 ) {
            $yylangChooser =
qq~$guest_txt{'changelanguage'}: <form action="$scripturl?action=guestlang" method="post" name="changelanguage">
            <select name="guestlang" onchange="submit();">
            $langopt
            </select>
            </form>~;
        }
    }

    my $wmessage;
    if ( $hour >= 12 && $hour < 18 ) {
        $wmessage = $maintxt{'247a'};
    }    # Afternoon
    elsif ( $hour < 12 && $hour >= 0 ) {
        $wmessage = $maintxt{'247m'};
    }    # Morning
    else { $wmessage = $maintxt{'247e'}; }    # Evening
    if ($iamguest) {
        $yyuname = qq~$maintxt{'248'} $maintxt{'28'}. $maintxt{'249'} <a href="~
          . (
            $loginform
            ? "javascript:if(jumptologin>1)alert('$maintxt{'35'}');jumptologin++;window.scrollTo(0,10000);document.loginform.username.focus();"
            : "$scripturl?action=login"
          ) . qq~">$maintxt{'34'}</a>~;
        if ($regtype) {
            $yyuname .=
qq~ $maintxt{'377'} <a href="$scripturl?action=register">$maintxt{'97'}</a>~;
        }
        $yyjavascript .= q~        jumptologin = 1;~;
    }
    else {
        if ( ${ $uid . $username }{'bday'} ne q{} ) {
            my ( $usermonth, $userday, $useryear ) =
              split /\//xsm, ${ $uid . $username }{'bday'};
            if ( $usermonth == $mon_num && $userday == $mday ) {
                $wmessage = $maintxt{'247bday'};
            }
        }
        $yyuname =
          (      $PM_level == 0
              || ( $PM_level == 2 && !$staff )
              || ( $PM_level == 3 && !$iamadmin && !$iamgmod )
              || ( $PM_level == 4 && !$iamadmin && !$iamgmod && !$iamfmod ) )
          ? "$wmessage ${$uid.$username}{'realname'}"
          : "$wmessage ${$uid.$username}{'realname'}, ";
    }

    # Add new notifications if allowed
    if ( !$iamguest && $NewNotificationAlert ) {
        if ( !$board_notify && !$thread_notify ) {
            require Sources::Notify;
            ( $board_notify, $thread_notify ) = NotificationAlert();
        }
        my ( $bo_num, $th_num );
        foreach ( keys %{$board_notify} ) {   # boardname, boardnotifytype , new
            if ( ${ $$board_notify{$_} }[2] ) { $bo_num++; }
        }
        foreach ( keys %{$thread_notify} )
        { # mythread, msub, new, username_link, catname_link, boardname_link, lastpostdate
            if ( ${ $$thread_notify{$_} }[2] ) { $th_num++; }
        }
        if ( $bo_num || $th_num ) {
            my $noti_text = (
                $bo_num
                ? "$notify_txt{'201'} $notify_txt{'205'} ($bo_num)"
                : q{}
              )
              . (
                $th_num
                ? ( $bo_num ? " $notify_txt{'202'} " : q{} )
                  . "$notify_txt{'201'}  $notify_txt{'206'} ($th_num)"
                : q{}
              );
            if ( ${ $uid . $username }{'onlinealert'} and $boardindex_template )
            {
                $yyadmin_alert =
qq~<br />$notify_txt{'200'} <a href="$scripturl?action=shownotify">$noti_text</a>.$yyadmin_alert~;
                $yymain .= qq~<script type="text/javascript">
            window.setTimeout("Noti_Popup();", 1000);
            function Noti_Popup() {
                if (confirm('$notify_txt{'200'} $noti_text.\\n$notify_txt{'203'}'))
                    window.location.href='$scripturl?action=shownotify';
            }
             </script>~;
            }
        }
    }

# check for copyright for special error - angle brackets no longer supported for yabb tags
    if ( $output =~ m/{yabb\ copyright}/xsm ) {
        $yycopyin = 1;
    }

    $yysearchbox = q{};
    if ( !$iamguest || $guestaccess != 0 ) {
        if ( $maxsearchdisplay > -1 && $qcksearchaccess eq 'granted' ) {
            my $blurb = qq~$maintxt{'searchimg'} $qckage $maintxt{'searchimg2'}~;
            if ( $qckage == 0 ) {
                $blurb = qq~$maintxt{'searchimg3'}~;
            }
            $yysearchbox = qq~
                    <form action="$scripturl?action=search2" method="post" accept-charset="$yymycharset">
                        <input type="hidden" name="searchtype" value="$qcksearchtype" />
                        <input type="hidden" name="userkind" value="any" />
                        <input type="hidden" name="subfield" value="on" />
                        <input type="hidden" name="msgfield" value="on" />
                        <input type="hidden" name="age" value="$qckage" />
                        <input type="hidden" name="oneperthread" value="1" />
                        <input type="hidden" name="searchboards" value="!all" />
                        <input type="text" name="search" size="16" id="search1" value="$img_txt{'182'}" style="font-size: 11px;" onfocus="txtInFields(this, '$img_txt{'182'}');" onblur="txtInFields(this, '$img_txt{'182'}')" />
                        <input type="image" src="$imagesdir/search.png" alt="$blurb" title="$blurb" style="background-color: transparent; margin-right: 5px; vertical-align: middle;" />
                    </form>
~;
        }
    }
    if ( $enable_news && ( -s "$vardir/news.txt" ) > 5 ) {
        fopen( NEWS, "$vardir/news.txt" );
        my @newsmessages = <NEWS>;
        fclose(NEWS);
        chomp @newsmessages;
        my $startnews = int rand @newsmessages;
        $yynewstitle = qq~<b>$maintxt{'102'}:</b>~;
        $yynewstitle =~ s/'/\\'/gxsm;
        $guest_media_disallowed = 0;
        $newswrap               = 40;

        if ($shownewsfader) {
            $fadedelay = $maxsteps * $stepdelay;
            $yynews .= qq~
            <script type="text/javascript">
                    var index = $startnews;
                    var maxsteps = "$maxsteps";
                    var stepdelay = "$stepdelay";
                    var fadelinks = $fadelinks;
                    var delay = "$fadedelay";
                    function convProp(thecolor) {
                        if(thecolor.charAt(0) == "#") {
                            if(thecolor.length == 4) thecolor=thecolor.replace(/(\\#)([a-f A-F 0-10]{1,1})([a-f A-F 0-10]{1,1})([a-f A-F 0-10]{1,1})\/i, "\$1\$2\$2\$3\$3\$4\$4");
                            var thiscolor = new Array(HexToR(thecolor), HexToG(thecolor), HexToB(thecolor));
                            return thiscolor;
                        }
                        else if(thecolor.charAt(3) == "(") {
                            thecolor=thecolor.replace(/rgb\\((\\d+?\\%*?)\\,(\\s*?)(\\d+?\\%*?)\\,(\\s*?)(\\d+?\\%*?)\\)/i, "\$1|\$3|\$5");
                            thiscolor = thecolor.split("|");
                            return thiscolor;
                        }
                        else {
                            thecolor=thecolor.replace(/\\"/g, "");
                            thecolor=thecolor.replace(/maroon/ig, "128|0|0");
                            thecolor=thecolor.replace(/red/i, "255|0|0");
                            thecolor=thecolor.replace(/orange/i, "255|165|0");
                            thecolor=thecolor.replace(/olive/i, "128|128|0");
                            thecolor=thecolor.replace(/yellow/i, "255|255|0");
                            thecolor=thecolor.replace(/purple/i, "128|0|128");
                            thecolor=thecolor.replace(/fuchsia/i, "255|0|255");
                            thecolor=thecolor.replace(/white/i, "255|255|255");
                            thecolor=thecolor.replace(/lime/i, "00|255|00");
                            thecolor=thecolor.replace(/green/i, "0|128|0");
                            thecolor=thecolor.replace(/navy/i, "0|0|128");
                            thecolor=thecolor.replace(/blue/i, "0|0|255");
                            thecolor=thecolor.replace(/aqua/i, "0|255|255");
                            thecolor=thecolor.replace(/teal/i, "0|128|128");
                            thecolor=thecolor.replace(/black/i, "0|0|0");
                            thecolor=thecolor.replace(/silver/i, "192|192|192");
                            thecolor=thecolor.replace(/gray/i, "128|128|128");
                            thiscolor = thecolor.split("|");
                            return thiscolor;
                        }
                    }
                    if (ie4 || DOM2) var news = ('<span class="windowbg2" id="fadestylebak" style="display: none;"><span class="newsfader" id="fadestyle" style="display: none;"> </span></span>');
                    var div = document.getElementById("newsdiv");
                    div.innerHTML = news;
                    if (document.getElementById('fadestyle').currentStyle) {
                        tcolor = document.getElementById('fadestyle').currentStyle['color'];
                        bcolor = document.getElementById('fadestyle').currentStyle['backgroundColor'];
                        nfntsize = document.getElementById('fadestyle').currentStyle['fontSize'];
                        fntstyle = document.getElementById('fadestyle').currentStyle['fontStyle'];
                        fntweight = document.getElementById('fadestyle').currentStyle['fontWeight'];
                        fntfamily = document.getElementById('fadestyle').currentStyle['fontFamily'];
                        txtdecoration = document.getElementById('fadestyle').currentStyle['textDecoration'];
                    }
                    else if (window.getComputedStyle) {
                        tcolor = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('color');
                        bcolor = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('background-color');
                        nfntsize = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-size');
                        fntstyle = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-style');
                        fntweight = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-weight');
                        fntfamily = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('font-family');
                        txtdecoration = window.getComputedStyle(document.getElementById('fadestyle'), null).getPropertyValue('text-decoration');
                    }
                    if (bcolor == "transparent" || bcolor == "rgba\\(0\\, 0\\, 0\\, 0\\)") {
                        if (document.getElementById('fadestylebak').currentStyle) {
                            tcolor = document.getElementById('fadestylebak').currentStyle['color'];
                            bcolor = document.getElementById('fadestylebak').currentStyle['backgroundColor'];
                        }
                        else if (window.getComputedStyle) {
                            tcolor = window.getComputedStyle(document.getElementById('fadestylebak'), null).getPropertyValue('color');
                            bcolor = window.getComputedStyle(document.getElementById('fadestylebak'), null).getPropertyValue('background-color');
                        }
                    }
                    txtdecoration = txtdecoration.replace(/\'/g, ""); //';
                    var endcolor = convProp(tcolor);
                    var startcolor = convProp(bcolor);~;
            my $greybox = $img_greybox;
            $img_greybox = 0;
            foreach my $j ( 0 .. ( @newsmessages - 1 ) ) {
                $message = $newsmessages[$j];
                wrap();
                if ($enable_ubbc) {
                    enable_yabbc();
                    $ns = q{};
                    DoUBBC();
                    $message =~
                      s/ style="display:none"/ style="display:block"/gsm;
                }
                wrap2();
                $message =~ s/"/\\"/gxsm;
                ToChars($message);
                $message =~ s/\'/&#39;/xsm;
                $yynews .= qq~                  fcontent[$j] = '$message';\n~;
            }
            $img_greybox = $greybox;
            $yynews .= q~
                        document.getElementById("newsdiv").style.fontSize=nfntsize;
                        document.getElementById("newsdiv").style.fontWeight=fntweight;
                        document.getElementById("newsdiv").style.fontStyle=fntstyle;
                        document.getElementById("newsdiv").style.fontFamily=fntfamily;
                        document.getElementById("newsdiv").style.textDecoration=txtdecoration;

                    if (window.addEventListener)
                        window.addEventListener("load", changecontent, false);
                    else if (window.attachEvent)
                        window.attachEvent("onload", changecontent);
                    else if (document.getElementById)
                        window.onload = changecontent;
            </script>
        ~;
        }
        else {
            $message = $newsmessages[$startnews];
            wrap();
            if ($enable_ubbc) {
                enable_yabbc();
                DoUBBC();
                $message =~ s/ style="display:none"/ style="display:block"/gsm;
            }
            wrap2();
            ToChars($message);
            $message =~ s/\'/&#39;/xsm;
            $yynews = qq~
            <script type="text/javascript">
                if (ie4 || DOM2) var news = '$message';
                var div = document.getElementById("newsdiv");
                div.innerHTML = news;
            </script>~;
        }
        $newswrap = 0;
    }
    else {
        $yynews = '&nbsp;';
    }

    if ( $debug == 1 || ( $debug == 2 && $iamadmin ) || $debug == 3 ) {
        require Sources::Debug;
        LoadLanguage('Debug');
        Debug();
    }

    $yyurl = $scripturl;
    my $copyright = $output =~ m/{yabb\ copyright}/xsm ? 1 : 0;

    # new and old tag template style decoding - the (<|{) and (}|>) must remain for it to work.
    while ( $output =~ s/(<|{)yabb\s+(\w+)(}|>)/${"yy$2"}/gxsm ) { }

    # check if image exists, otherwise use the default template image
    if ( $imagesdir ne $defaultimagesdir ) {
        my %img_locs;

        $output =~
s/(src|value|url)(=|\()("|'| )$imagesdir\/([^'" ]+)./ "$1$2$3" . ImgLoc($4) . $3 /eisgm;
    }

    # add formsession to each <form ..>-tag
    $output =~
s/<\/form>/ <input type="hidden" name="formsession" value="$formsession" \/>\n                    <\/form>/gsm;

    image_resize();

    # Start workaround to substitute all ';' by '&' in all URLs
    # This workaround solves problems with servers that use mod_security
    # in a very strict way. (error 406)
    # Take the comments out of the following two lines if you had this problem.
    # $output =~ s/($scripturl\?)([^'"]+)/ $1 . URL_modify($2) /eg;
    # sub URL_modify { my $x = shift; $x =~ s/;/&amp;/g; $x; }
    # End of workaround

    if ( !$copyright ) {
        $output =
q~<h1 class="center"><b>Sorry, the copyright tag &#123;yabb copyright&#125; must be in the template.<br />Please notify this forum&#39;s administrator that this site is using an ILLEGAL copy of YaBB!</b></h1>~;
    }

    print_HTML_output_and_finish();
    return;
}

sub PMlev {
    my $pm_lev = 0;
    if (   $PM_level == 1
        || ( $PM_level == 2 && $staff )
        || ( $PM_level == 3 && ( $iamadmin || $iamgmod ) )
        || ( $PM_level == 4 && ( $iamadmin || $iamgmod || $iamfmod ) ) )
    {
        $pm_lev = 1;
    }
    return $pm_lev;
}

sub image_resize {
    my ( $resize_js, $resize_num );
    my $perl_do_it = 0;

# Hardcoded! Set to 1 for Perl to do the fix...size work here. Set to 0 for the javascript within the browser do this work.

    *check_image_resize = sub {
        my @x  = @_;
        my $px = 'px';
        if ( $fix_avatar_img_size && $perl_do_it == 1 && $x[1] eq 'avatar' ) {
            if ( $max_avatar_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_avatar_width$px;/sm;
            }
            if ( $max_avatar_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_avatar_height$px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/sm;
        }
        elsif ($fix_avatarml_img_size
            && $perl_do_it == 1
            && $x[1] eq 'avatarml' )
        {
            if ( $max_avatarml_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_avatarml_width\px;/sm;
            }
            if ( $max_avatarml_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_avatarml_height\px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/sm;
        }
        elsif ( $fix_post_img_size && $perl_do_it == 1 && $x[1] eq 'post' ) {
            if ( $max_post_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_post_width$px;/sm;
            }
            if ( $max_post_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_post_height$px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/xsm;
        }
        elsif ( $fix_attach_img_size && $perl_do_it == 1 && $x[1] eq 'attach' )
        {
            if ( $max_attach_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_attach_width$px;/sm;
            }
            if ( $max_attach_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_attach_height$px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/xsm;
        }
        elsif ( $fix_signat_img_size && $perl_do_it == 1 && $x[1] eq 'signat' )
        {
            if ( $max_signat_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_signat_width$px;/sm;
            }
            if ( $max_signat_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_signat_height$px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/xsm;
        }
        elsif ( $fix_brd_img_size  && $perl_do_it == 1 && $x[1] eq 'brd' )
        {
            if ( $max_brd_img_width && $x[2] !~ / width=./sm ) {
                $x[2] =~ s/( style=.)/$1width:$max_brd_img_width$px;/sm;
            }
            if ( $max_brd_img_height && $x[2] !~ / height=./sm ) {
                $x[2] =~ s/( style=.)/$1height:$max_brd_img_height$px;/sm;
            }
            $x[2] =~ s/display:none/display:inline/sm;
        }
        else {
            $resize_num++;
            $x[0] .= "_$resize_num";
            $resize_js .= "'$x[0]',";
        }
        return qq~"$x[0]"$x[2]~;
    };
    $output =~
s/"((avatar|avatarml|post|attach|signat|brd)_img_resize)"([^>]*>)/ check_image_resize($1,$2,$3) /gesm;

    if ($resize_num) {
        $avatar_img_w    = isempty( $max_avatar_width, 65 );
        $avatar_img_h    = isempty( $max_avatar_height, 65 );
        $avatarml_img_w  = isempty( $max_avatarml_width, 65 );
        $avatarml_img_h  = isempty( $max_avatarml_height, 65 );
        $post_img_w      = isempty( $max_post_img_width, 0 );
        $post_img_h      = isempty( $max_post_img_height, 0 );
        $attach_img_w    = isempty( $max_attach_img_width, 0 );
        $attach_img_h    = isempty( $max_attach_img_height, 0 );
        $signat_img_w    = isempty( $max_signat_img_width, 0 );
        $signat_img_h    = isempty( $max_signat_img_height, 0 );
        $brd_img_w       = isempty( $max_brd_img_width, 50 );
        $brd_img_h       = isempty( $max_brd_img_height, 50 );
        $fix_brd_img_size = isempty( $fix_brd_img_size, 0 );

        $resize_js =~ s/,$//xsm;
        $resize_js = qq~<script type="text/javascript">
    // resize image start
    var resize_time = 2;
    var img_resize_names = new Array ($resize_js);

    var avatar_img_w    = $avatar_img_w;
    var avatar_img_h    = $avatar_img_h;
    var fix_avatar_size = $fix_avatar_img_size;
    var avatarml_img_w    = $avatarml_img_w;
    var avatarml_img_h    = $avatarml_img_h;
    var fix_avatarml_size = $fix_avatarml_img_size;
    var post_img_w      = $post_img_w;
    var post_img_h      = $post_img_h;
    var fix_post_size   = $fix_post_img_size;
    var attach_img_w    = $attach_img_w;
    var attach_img_h    = $attach_img_h;
    var fix_attach_size = $fix_attach_img_size;
    var signat_img_w    = $signat_img_w;
    var signat_img_h    = $signat_img_h;
    var fix_signat_size = $fix_signat_img_size;
    var brd_img_w       = $brd_img_w;
    var brd_img_h       = $brd_img_h;
    var fix_brd_size    = $fix_brd_img_size;

    noimgdir   = '$imagesdir';
    noimgtitle = '$maintxt{'171'}';

    resize_images();
    // resize image end
</script>~;

        $output =~ s/(<\/body>)/$resize_js\n$1/sm;
    }
    return;
}

sub get_caller {

    # Gets filename and line where fatal_error/debug was called.
    # Need to go further back to get correct subroutine name,
    # otherwise will print fatal_error/debug as current subroutine!
    my ( undef, $filename, $line ) = caller 1;
    my ( undef, undef, undef, $subroutine ) = caller 2;
    return ( $filename, $line, $subroutine );
}

sub fatal_error {
    my @x       = @_;
    my $verbose = $!;

    LoadLanguage('Error');
    get_template('Other');

    my $errormessage = $x[0] ? ( $error_txt{$x[0]} . ( $x[1] ? " $x[1]" : q{} ) ) : isempty( $x[1], q{} );

    my ( $filename, $line, $subroutine ) = get_caller();
    if (   ( $debug == 1 || ( $debug == 2 && $iamadmin ) )
        && ( $filename || $line || $subroutine ) )
    {
        LoadLanguage('Debug');
        $errormessage .=
qq~<br />$maintxt{'error_location'}: $filename<br />$maintxt{'error_line'}: $line<br />$maintxt{'error_subroutine'}: $subroutine~;
    }

    if ( $x[2] ) {
        $errormessage .= "<br />$maintxt{'error_verbose'}: $verbose";
    }

    if ($elenable) { fatal_error_logging($errormessage); }

    # for ajax calls that return errors, so no page is generated
    if ($no_error_page) {
        print "Content-type: text/plain\n\nerror$errormessage"
          or croak "$croak{'print'} error";
        CORE::exit;    # This is here only to avoid server error log entries!
    }

    $yymain .= $my_show_error;
    $yymain =~ s/{yabb errormessage}/$errormessage/sm;
    $yytitle = "$maintxt{'error_description'}";

    if ( $adminscreen && $action ne 'admincheck2' ) {
        AdminTemplate();
    }
    else {
        if ( $x[0] =~ /no_access|members_only|no_perm/xsm ) {
            $headerstatus = '403 Forbidden';
        }
        elsif ( $x[0] =~ /cannot_open|no.+_found/xsm ) {
            $headerstatus = '404 Not Found';
        }
        template();
    }
    return;
}

sub fatal_error_logging {
    my ($tmperror) = @_;

# This flaw was brought to our attention by S M <savy91@msn.com> Italy
# Thanks! We couldn't make YaBB successful without the help from the bug testers.
    ToHTML($action);
    ToHTML( $INFO{'num'} );
    ToHTML($currentboard);

    $tmperror =~ s/\n//igsm;
    fopen( ERRORLOG, "<$vardir/errorlog.txt" );
    my @errorlog = <ERRORLOG>;
    fclose( ERRORLOG );
    chomp @errorlog;
    $errorcount = @errorlog;

    if ($elrotate) {
        while ( $errorcount >= $elmax ) {
            shift @errorlog;
            $errorcount = @errorlog;
        }
    }

    foreach my $formdata ( keys %FORM ) {
        chomp $FORM{$formdata};
        $FORM{$formdata} =~ s/\n//igsm;
    }

    if ($iamguest) {
        push @errorlog,
          int(time)
          . "|$date|$user_ip|$tmperror|$action|$INFO{'num'}|$currentboard|$FORM{'username'}|$FORM{'passwrd'}\n";
    }
    else {
        push @errorlog,
          int(time)
          . "|$date|$user_ip|$tmperror|$action|$INFO{'num'}|$currentboard|$username|$FORM{'passwrd'}\n";
    }
    fopen( ERRORLOG, ">$vardir/errorlog.txt" );
    foreach (@errorlog) {
        chomp;
        if ( $_ ne q{} ) {
            print {ERRORLOG} $_ . "\n" or croak "$croak{'print'} ERRORLOG";
        }
    }
    fclose(ERRORLOG);
    return;
}

sub FindPermalink {
    my ($old_env) = @_;
    $old_env        = substr $old_env, 1, length $old_env;
    $permtopicfound = 0;
    $permboardfound = 0;
    $is_perm        = 1;
    ## strip off symlink for redirectlike e.g. /articles/ ##
    $old_env =~ s/$symlink//gxsm;
    ## get date/time/board/topic from permalink

    ( $permyear, $permmonth, $permday, $permboard, $permnum ) =
      split /\//xsm, $old_env;
    if ( -e "$boardsdir/$permboard.txt" ) {
        $permboardfound = 1;
        if ( $permnum ne q{} && -e "$datadir/$permnum.txt" ) {
            $new_env        = qq~num=$permnum~;
            $permtopicfound = 1;
        }
        else { $new_env = qq~board=$permboard~; }
    }
    return $new_env;
}

sub permtimer {
    my ($thetime) = @_;
    my $mynewtime =  $thetime;

    my ( undef, $pmin, $phour, $pmday, $pmon, $pyear, undef, undef, undef ) =
      gmtime( $mynewtime );
    my $pmon_num = $pmon + 1;
    $phour    = sprintf '%02d', $phour;
    $pmin     = sprintf '%02d', $pmin;
    $pyear    = 1900 + $pyear;
    $pmon_num = sprintf '%02d', $pmon_num;
    $pmday    = sprintf '%02d', $pmday;
    $pyear    = sprintf '%04d', $pyear;
    return "$pyear/$pmon_num/$pmday";
}

sub readform {
    my ( @pairs, $pair, $name, $value );
    if ( substr( $ENV{QUERY_STRING}, 0, 1 ) eq q{/} && $accept_permalink ) {
        $ENV{QUERY_STRING} = FindPermalink( $ENV{QUERY_STRING} );
    }
    if ( $ENV{QUERY_STRING} =~ m/action\=dereferer/xsm ) {
        $INFO{'action'} = 'dereferer';
        $urlstart = index $ENV{QUERY_STRING}, 'url=';
        $INFO{'url'} = substr
          $ENV{QUERY_STRING},
          $urlstart + 4,
          length( $ENV{QUERY_STRING} ) - $urlstart + 3;
        $INFO{'url'} =~ s/\;anch\=/#/gxsm;
        $testenv = q{};
    }
    else {
        $testenv = $ENV{QUERY_STRING};
        $testenv =~ s/\&/\;/gxsm;
        if ( $testenv && $debug ) {
            LoadLanguage('Debug');
            $getpairs =
qq~<br /><span class="underline">$debug_txt{'getpairs'}:</span><br />~;
        }
    }

# URL encoding for web.de http://www.blooberry.com/indexdot/html/topics/urlencoding.htm
    $testenv =~ s/\%3B/;/igxsm;

    # search must be case insensitive for some servers!
    $testenv =~ s/\%26/&/gxsm;

    split_string( \$testenv, \%INFO, 1 );
    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
        ( $dummy,  $IISver )  = split /\//xsm, $ENV{'SERVER_SOFTWARE'};
        ( $IISver, $IISverM ) = split /./xsm,  $IISver;
        if ( int($IISver) < 6 && int($IISverM) < 1 ) {
            eval { use CGI qw(:standard) };
        }
    }
    if ( $ENV{REQUEST_METHOD} eq 'POST' ) {
        if ($debug) {
            LoadLanguage('Debug');
            $getpairs .=
qq~<br /><span class="underline">$debug_txt{'postpairs'}:</span><br />~;
        }
        if ( $ENV{CONTENT_TYPE} =~ /multipart\/form-data/xsm ) {
            require CGI;

           # A possible attack is for the remote user to force CGI.pm to accept
           # a huge file upload. CGI.pm will accept the upload and store it in
           # a temporary directory even if your script doesn't expect to receive
           # an uploaded file. CGI.pm will delete the file automatically when it
           # terminates, but in the meantime the remote user may have filled up
           # the server's disk space, causing problems for other programs.
           # The best way to avoid denial of service attacks is to limit the
           # amount of memory, CPU time and disk space that CGI scripts can use.
           # If $CGI::POST_MAX is set to a non-negative integer, this variable
           # puts a ceiling on the size of POSTings, in bytes. If CGI.pm detects
           # a POST that is greater than the ceiling, it will immediately exit
           # with an error message like this:
           # "413 Request entity too large"
           # This value will affect both ordinary POSTs and multipart POSTs,
           # meaning that it limits the maximum size of file uploads as well.
            $allowattach   ||= 0;
            $allowAttachIM ||= 0;
            $limit         ||= 0;
            $pmFileLimit   ||= 0;
            if (   $allowattach > 0
                && $ENV{'QUERY_STRING'} =~ /action=(post|modify)2\b/xsm )
            {
                $CGI::POST_MAX = int( 1024 * $limit * $allowattach );
                if ($CGI::POST_MAX) { $CGI::POST_MAX += 1048576; }    # *
            }
            elsif ( $allowAttachIM > 0
                && $ENV{'QUERY_STRING'} =~ /action=(imsend|imsend2)\b/xsm )
            {
                $CGI::POST_MAX = int( 1024 * $pmFileLimit * $allowAttachIM );
                if ($CGI::POST_MAX) { $CGI::POST_MAX += 1048576; }    # *
            }
            elsif ( $upload_useravatar
                && $ENV{'QUERY_STRING'} =~ /action=profileOptions2\b/xsm )
            {
                $avatar_limit ||= 0;
                $CGI::POST_MAX = int( 1024 * $avatar_limit );
                if ($CGI::POST_MAX) { $CGI::POST_MAX += 1048576; }    # *
            }
            else {

                # If NO uploads are allowed YaBB sets this default limit
                # to 1 MB. Change this values if you get error messages.
                $CGI::POST_MAX = 1048576;
            }

        # * adds volume, if a upload limit is set, to not get error if the other
        # uploaded data is larger. Change this values if you get error messages.
            $CGI_query = CGI->new;

            # $CGI_query must be a global variable
            my (@value);
            foreach my $name ( $CGI_query->param() ) {
                if ( $name =~ /^file(\d+|_avatar)$/xsm ) { next; }

        # files are directly called in Profile.pm, Post.pm and ModifyMessages.pl
                @value = $CGI_query->param($name);
                if ($debug) {
                    LoadLanguage('Debug');
                    $getpairs .=
qq~[$debug_txt{'name'}-&gt;]$name=@value\[&lt;-$debug_txt{'value'}]<br />~;
                }
                $FORM{$name} = join q{, }, @value;  # multiple values are joined
            }
        }
        else {
            read STDIN, my $input, $ENV{CONTENT_LENGTH};
            split_string( \$input, \%FORM );
        }
    }
    $action = $INFO{'action'} || $FORM{'action'};

    # Formsession checking moved to YaBB.pl to fix a bug.
    if (   $INFO{'username'}
        && $do_scramble_id
        && $action ne 'view_regentry'
        && $action ne 'del_regentry'
        && $action ne 'activate' )
    {
        $INFO{'username'} = decloak( $INFO{'username'} );
    }
    if (   $FORM{'username'}
        && $do_scramble_id
        && $action ne 'login2'
        && $action ne 'reminder2'
        && $action ne 'register2'
        && $action ne 'profile2'
        && $action ne 'admin_descision' )
    {
        $FORM{'username'} = decloak( $FORM{'username'} );
    }
    if ( $INFO{'to'} && $do_scramble_id ) {
        $INFO{'to'} = decloak( $INFO{'to'} );
    }
    if ( $FORM{'to'} && $do_scramble_id ) {
        $FORM{'to'} = decloak( $FORM{'to'} );
    }
    return;
}

sub split_string {
    my ( $string, $hash, $altdelim ) = @_;

    if ( $altdelim && ${$string} =~ m{;}sm ) {
        @pairs = split /;/xsm, ${$string};
    }
    else { @pairs = split /&/xsm, ${$string}; }
    foreach my $pair (@pairs) {
        my ( $name, $value ) = split /=/xsm, $pair;
        $name  =~ tr/+/ /;
        $name  =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/egsm;
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/egsm;
        if ($debug) {
            LoadLanguage('Debug');
            $getpairs .=
qq~[$debug_txt{'name'}-&gt;]$name=$value\[&lt;-$debug_txt{'value'}]<br />~;
        }
        if ( exists( $hash->{$name} ) ) {
            $hash->{$name} .= ", $value";
        }
        else {
            $hash->{$name} = $value;
        }
    }
    return;
}

sub getlog {
    return
      if %yyuserlog
          || $iamguest
          || !$max_log_days_old
          || !-e "$memberdir/$username.log";

    %yyuserlog = ();
    fopen( GETLOG, "$memberdir/$username.log" );
    my @logentries = <GETLOG>;
    fclose(GETLOG);
    chomp @logentries;

    foreach (@logentries) {
        my ( $name, $thistime ) = split /\|/xsm, $_;
        if ( $name && $thistime ) { $yyuserlog{$name} = $thistime; }
    }
    return;
}

sub dumplog {
    my @dum = @_;
    return if $iamguest || !$max_log_days_old;

    if ( $dum[0] ) {
        getlog();
        $yyuserlog{ $dum[0] } = $dum[1] || $date;
    }
    if (%yyuserlog) {
        my $name;
        $date2 = $date;
        fopen( DUMPLOG, ">$memberdir/$username.log" );
        while ( ( $name, $date1 ) = each %yyuserlog ) {
            $result = calcdifference( $date1, $date2 );    # output => $result
            if ( $result <= $max_log_days_old ) {
                print {DUMPLOG} qq~$name|$date1\n~
                  or croak "$croak{'print'} DUMPLOG";
            }
        }
        fclose(DUMPLOG);
    }
    return;
}

## standard jump to menu
sub jumpto {
    ## jump links to messages/favourites/notifications.
    my $action = 'action=jump';
    my $onchange =
qq~ onchange="if(this.options[this.selectedIndex].value) window.location.href='$scripturl?' + this.options[this.selectedIndex].value;"~;
    if ( $templatejump == 1 ) {
        $action   = 'action=';
        $onchange = q{};
    }
    $selecthtml = qq~
            <form method="post" action="$scripturl?$action" style="display: inline;">
                <select name="values"$onchange>
                    <option value="" class="forumjump">$jumpto_txt{'to'}</option>
                    <option value="gohome">$img_txt{'103'}</option>~;

    ## as guests do not have these, why show them?
    if ( !$iamguest ) {
        $pm_lev = PMlev();
        if ( $pm_lev == 1 ) {
            $selecthtml .= qq~
                    <option value="action=im" class="forumjumpcatm">$jumpto_txt{'mess'}</option>~;
        }
        $selecthtml .= qq~
                    <option value="action=shownotify" class="forumjumpcatmf">$jumpto_txt{'note'}</option>
                    <option value="action=favorites" class="forumjumpcatm">$jumpto_txt{'fav'}</option>~;
    }

    # drop in recent topics/posts lists. guests can see if browsing permitted
    $selecthtml .= qq~
                    <option value="action=recent;display=10">$recent_txt{'recentposts'}</option>
                    <option value="action=recenttopics;display=10">$recent_txt{'recenttopic'}</option>\n~;

    get_forum_master();
    foreach my $catid (@categoryorder) {
        my @bdlist = split /,/xsm, $cat{$catid};
        my ( $catname, $catperms ) = split /\|/xsm, $catinfo{"$catid"};

        my $cataccess = CatAccess($catperms);
        if ( !$cataccess ) { next; }
        ToChars($catname);

        $selecthtml .=
          $INFO{'catselect'} eq $catid
          ? qq~    <option selected="selected" value="catselect=$catid" class="forumjumpcat">&raquo;&raquo; $catname</option>\n~
          : qq~    <option value="catselect=$catid" class="forumjumpcat">$catname</option>\n~;

        my $indent = -2;

        *jump_subboards = sub {
            my @x = @_;
            $indent += 2;
            foreach my $board (@x) {
                my $dash;
                if ( $indent > 0 ) { $dash = q{-}; }

                my ( $boardname, $boardperms, $boardview ) =
                  split /\|/xsm, $board{"$board"};
                ToChars($boardname);
                my $access = AccessCheck( $board, q{}, $boardperms );
                if ( !$iamadmin && $access ne 'granted' && $boardview != 1 ) {
                    next;
                }
                if ( ${ $uid . $board }{'brdpasswr'} ) {
                    my $bdmods = ${ $uid . $board }{'mods'};
                    $bdmods =~ s/\, /\,/gsm;
                    $bdmods =~ s/\ /\,/gsm;
                    my %moderators = ();
                    my $pswiammod  = 0;
                    foreach my $curuser ( split /\,/xsm, $bdmods ) {
                        if ( $username eq $curuser ) { $pswiammod = 1; }
                    }
                    my $bdmodgroups = ${ $uid . $board }{'modgroups'};
                    $bdmodgroups =~ s/\, /\,/gsm;
                    my %moderatorgroups = ();

                    foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                        if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                            $pswiammod = 1;
                        }
                        foreach my $memberaddgroups ( split /\, /sm,
                            ${ $uid . $username }{'addgroups'} )
                        {
                            chomp $memberaddgroups;
                            if ( $memberaddgroups eq $curgroup ) {
                                $pswiammod = 1;
                                last;
                            }
                        }
                    }
                    my $cookiename = "$cookiepassword$board$username";
                    my $crypass    = ${ $uid . $board }{'brdpassw'};

                    if (   !$iamadmin
                        && !$iamgmod
                        && !$pswiammod
                        && $yyCookies{$cookiename} ne $crypass )
                    {
                        next;
                    }
                }
                if (   $board eq $annboard
                    && !$iamadmin
                    && !$iamgmod
                    && !$iamfmod )
                {
                    next;
                }

                if ( $board eq $currentboard ) {
                    $selecthtml .=
                      $INFO{'num'}
                      ? qq~    <option value="board=$board" class="forumcurrentboard">&nbsp;~
                      . ( '&nbsp;' x $indent )
                      . ( $dash x ( $indent / 2 ) )
                      . qq~ $boardname &#171;&#171;</option>\n~
                      : qq~    <option selected="selected" value="board=$board" class="forumcurrentboard">&raquo;&raquo; $boardname</option>\n~;
                }
                elsif ( !${ $uid . $board }{'canpost'} && $subboard{$board} ) {
                    $selecthtml .=
                        qq~    <option value="boardselect=$board">&nbsp;~
                      . ( '&nbsp;' x $indent )
                      . ( $dash x ( $indent / 2 ) )
                      . qq~ $boardname</option>\n~;
                }
                else {
                    $selecthtml .=
                        qq~    <option value="board=$board">&nbsp;~
                      . ( '&nbsp;' x $indent )
                      . ( $dash x ( $indent / 2 ) )
                      . qq~ $boardname</option>\n~;
                }

                if ( $subboard{$board} ) {
                    jump_subboards( split /\|/xsm, $subboard{$board} );
                }
            }
            $indent -= 2;
        };
        jump_subboards(@bdlist);
    }
    $selecthtml .= qq~</select>
            </form>~;
    return $selecthtml;
}

sub dojump {
    $yySetLocation = $scripturl . $FORM{'values'};
    redirectexit();
    return;
}

sub spam_protection {
    return if !$timeout || $iamadmin;
    my ( $flood_ip, $flood_time, $flood, @floodcontrol );

    if ( -e "$vardir/flood.txt" ) {
        fopen( FLOOD, "$vardir/flood.txt" );
        push @floodcontrol, "$user_ip|$date\n";
        while (<FLOOD>) {
            chomp $_;
            ( $flood_ip, $flood_time ) = split /\|/xsm, $_;
            if ( $user_ip eq $flood_ip && $date - $flood_time <= $timeout ) {
                $flood = 1;
            }
            elsif ( $date - $flood_time < $timeout ) {
                push @floodcontrol, "$_\n";
            }
        }
        fclose(FLOOD);
    }
    if ( $flood && !$iamadmin ) {
        if ( $action eq 'post2' ) {
            Preview("$maintxt{'409'} $timeout $maintxt{'410'}");
        }
        else {
            fatal_error( 'post_flooding', "$timeout $maintxt{'410'}" );
        }
    }
    fopen( FLOOD, ">$vardir/flood.txt", 1 );
    print {FLOOD} @floodcontrol or croak "$croak{'print'} FLOOD";
    fclose(FLOOD);
    return;
}

sub SpamQuestion {
    srand;
    fopen( SPAMQUESTIONS, "<$langdir/$language/spam.questions" )
      or fatal_error( 'cannot_open', "$langdir/$language/spam.questions", 1 );
    while (<SPAMQUESTIONS>) {
        rand($INPUT_LINE_NUMBER) < 1 && ( $spam_question_rand = $_ );
    }
    fclose(SPAMQUESTIONS);
    chomp $spam_question_rand;
    ( $spam_question_id, $spam_question, undef, $spam_questions_case, $spam_image ) =
      split /\|/xsm, $spam_question_rand;
    $spam_image = $spam_image ? qq~<div style="margin-top: .5em;"><img src="$defaultimagesdir/Spam_Img/$spam_image" alt="" /></div>~ : q{};
    return;
}

sub SpamQuestionCheck {
    my ( $verification_question, $verification_question_id ) = @_;
    fopen( SPAMQUESTIONS, "<$langdir/$language/spam.questions" )
      or fatal_error( 'cannot_open', "$langdir/$language/spam.questions", 1 );
    @spam_questions = <SPAMQUESTIONS>;
    fclose(SPAMQUESTIONS);
    foreach my $verification_question (@spam_questions) {
        chomp $verification_question;
        if ( $verification_question =~ /$verification_question_id/xsm ) {
            ( undef, undef, $verification_answer, $spam_questions_case, undef ) =
              split /\|/xsm, $verification_question;
        }
    }
    $verification_question =~ s/\A\s+//xsm;
    $verification_question =~ s/\s+\Z//xsm;
    if ( !$spam_questions_case ) {
        $verification_answer   = lc $verification_answer;
        $verification_question = lc $verification_question;
    }
    if ( $verification_question eq q{} ) {
        fatal_error('no_verification_question');
    }
    @verificationanswer = split /,/xsm, $verification_answer;
    foreach (@verificationanswer) {
        $_ =~ s/\A\s+//xsm;
        $_ =~ s/\s+\Z//xsm;
    }
    if ( !grep { $verification_question eq $_ } @verificationanswer ) {
        fatal_error('wrong_verification_question');
    }
    return;
}

sub CountChars {
    $convertstr =~ s/&#32;/ /gsm;    # why? where? (deti)

    $cliped = 0;
    my ( $string, $curstring, $stinglength, $teststring );
    foreach my $string ( split /\s+/xsm, $convertstr ) {
      CHECKAGAIN:

        # jump over HTML-tags
        if ( $curstring =~ /<[\/a-z][^>]*$/ixsm ) {
            if ( $string =~ /^([^>]*>)(.*)/xsm ) {
                $curstring .= $1;
                $convertcut += length $1;
                if ($2) { $string = $2; goto CHECKAGAIN; }
            }
            else {
                $curstring .= "$string ";
                $convertcut += length($string) + 1;
            }
            next;
        }

        # jump over YaBBC-tags if YaBBC is allowed
        if ( $enable_ubbc && $curstring =~ /\[[\/a-z][^\]]*$/ixsm ) {
            if ( $string =~ /^([^\]]*\])(.*)/xsm ) {
                $curstring .= $1;
                $convertcut += length $1;
                if ($2) { $string = $2; goto CHECKAGAIN; }
            }
            else {
                $curstring .= "$string ";
                $convertcut += length($string) + 1;
            }
            next;
        }
        $stinglength = length $string;
        $teststring  = $string;

        # correct length for HTML characters
        FromHTML($teststring);
        $convertcut += $stinglength - length $teststring;

        # correct length for special characters, YaBBC and HTML-Tags
        $teststring = $string;
        $teststring =~ s/\[ch\d{3,}?\]/ /igxsm;
        $teststring =~ s/<.*?>|\[.*?\]//gxsm;
        $convertcut += $stinglength - length $teststring;

        $curstring .= "$string ";
        $curstring =~ s/ <br $/<br /ism;

        if ( $curstring =~ /(<[\/a-z][^>]*)$/ism ) {
            $convertcut += length $1;
        }
        if ( $enable_ubbc && $curstring =~ /(\[[\/a-z][^\]]*)$/ism ) {
            $convertcut += length $1;
        }

        if ( length($curstring) > $convertcut ) {
            $cliped = 1;
            last;
        }
    }
    if ( $curstring =~ /( *<[\/a-z][^>]*)$/ism
        || ( $enable_ubbc && $curstring =~ /( *\[[\/a-z][^\]]*)$/ism ) )
    {
        $convertcut -= length $1;
    }
    $convertstr = substr $curstring, 0, $convertcut;

    # eliminate spaces, broken HTML-characters or special characters at the end
    $convertstr =~ s/(\[(ch\d*)?|&[a-z]*| +)$//sm;
    return;
}

sub WrapChars {
    my @x = @_;
    my ( $tmpwrapstr, $length, $char, $curword, $tmpwrapcut );
    my $wrapcut = $x[1];
    foreach my $curword ( split /\s+/xsm, $x[0] ) {
        $char    = $curword;
        $length  = 0;
        $curword = q{};
        while ( $char ne q{} ) {
            if    ( $char =~ s/^(&#?[a-z\d]+;)//ism ) { $curword .= $1; }
            elsif ( $char =~ s/^(.)//sm )             { $curword .= $1; }
            $length++;
            if ( $length >= $wrapcut ) {
                $curword .= '<br />';
                $tmpwrapcut = $length = 0;
            }
        }
        if ( $tmpwrapstr && ( $tmpwrapcut + $length ) >= $wrapcut ) {
            $tmpwrapstr .= " $curword<br />";
            $tmpwrapcut = 0;
        }
        elsif ($tmpwrapstr) {
            $tmpwrapstr .= " $curword";
            $tmpwrapcut += $length + 1;
        }
        else {
            $tmpwrapstr = $curword;
            $tmpwrapcut = $length;
        }
    }
    $tmpwrapstr =~ s/(<br \/>)*$/<br \/>/sm;
    return $tmpwrapstr;
}

# Out of: Escape.pm, v 3.28 2004/11/05 13:58:31
# Original Modul at: http://search.cpan.org/~gaas/URI-1.35/URI/Escape.pm
sub uri_escape {    # usage: $safe = uri_escape( $string )
    my $text = shift;

    #    return undef unless defined $text;
    defined $text || return;
    if ( !%escapes ) {

        # Build a char->hex map
        for ( 0 .. 255 ) { $escapes{ chr $_ } = sprintf '%%%02X', $_ }
    }

    # Default unsafe characters. RFC 2732 ^(uric - reserved)
    $text =~ s/([^A-Za-z0-9\-_.!~*'()])/ $escapes{$1} || $1 /gesm;

    #'; to keep my text editor happy;
    return $text;
}

sub enc_eMail {
    my ($title,$email,$subject,$body,$src) = @_;
    my ($charset_value);
    if ($yymycharset eq 'windows-1251') { $charset_value = 848;} # Cyrillic decoding

    my $email_length = length $email;
    my $code1 = generate_code($email_length);
    my $code2;
    for my $i ( 0 .. ( $email_length - 1 ) ) {
        $code2 .= chr( ord( substr $code1, $i, 1 )^ord( substr $email, $i, 1 ));
    }
    $code2 = uri_escape($code2);

    *enc_eMail_x = sub {
        my ( $x, $y, $z ) = @_;
        if ( !$y ) {
            $x = ord $x;
            if ( $charset_value && $x > 126 ) { $x += $charset_value; }
            $x = "&#$x";
        }
        elsif ($z) {
            $x =~ s/"/\\"/gxsm;
        }

        return $x;
    };
    my $subbody;
    if ($subject or $body) {
        $subject = uri_escape($subject);
        $body = uri_escape($body);
        $subbody = "?subject=$subject&body=$body";
        $subbody =~ s/(((<.+?>)|&#\d+;)|.)/ enc_eMail_x($1,$2,$3) /egsm;
    }
    $titlesp = $title;
    $titlesp =~ s/(((<.+?>)|&#\d+;)|.)/ enc_eMail_x($1,$2,$3) /egsm;
    if ($src || $yymycharset eq 'UTF-8') {$titlesp = $title;}

    return qq~<script type='text/javascript'>\nSpamInator('$titlesp',"$code1","$code2","&#109;&#97;&#105;&#108;&#92;&#117;&#48;&#48;&#55;&#52;&#111;&#92;&#117;&#48;&#48;&#51;&#97;",'$subbody');\n</script>~;

}

sub generate_code {
    my ($arrey_in) = @_;
    my ( $arrey_pos, $code );
    my @arrey = (
        'a' .. 'q', 'C' .. 'O', '1' .. '9', 'g' .. 'u',
        'l' .. 'z', '9' .. '1', 'H' .. 'W',
    );

    foreach my $i ( 0 .. ( $arrey_in - 1 ) ) {
        $arrey_pos = int rand $#arrey;
        $code .= $arrey[$arrey_pos];
    }
    return $code;
}

sub FromChars {
    ( $_[0] ) = @_;
    ## This cannot be localized or unpacked ##
    $_[0] =~ s/&#(\d{3,});/ $1>127 ? "[ch$1]" : $& /egism;

    return $_[0];
}

sub ToChars {
    ( $_[0] ) = @_;
    ## This cannot be localized or unpacked ##
    $_[0] =~ s/\[ch(\d{3,})\]/ $1>127 ? "\&#$1;" : q{} /egism;
    return $_[0];
}

sub ToHTML {
    ( $_[0] ) = @_;
    ## This cannot be localized or unpacked - damages smilies ##
    $_[0] =~ s/&/&amp;/gsm;
    $_[0] =~ s/\}/\&#125;/gsm;
    $_[0] =~ s/\{/\&#123;/gsm;
    $_[0] =~ s/\|/&#124;/gsm;
    $_[0] =~ s/>/&gt;/gsm;
    $_[0] =~ s/</&lt;/gsm;
    $_[0] =~ s/   /&nbsp; &nbsp;/gsm;
    $_[0] =~ s/  /&nbsp; /gsm;
    $_[0] =~ s/"/&quot;/gsm;            #" make my syntax checker happy;
    return $_[0];
}

sub FromHTML {
    ( $_[0] ) = @_;
    ## This cannot be localized or unpacked ##
    $_[0] =~ s/&quot;/"/gsm;            #" make my syntax checker happy;
    $_[0] =~ s/&nbsp;/ /gsm;
    $_[0] =~ s/&lt;/</gsm;
    $_[0] =~ s/&gt;/>/gsm;
    $_[0] =~ s/&#124;/\|/gsm;
    $_[0] =~ s/&#123;/\{/gsm;
    $_[0] =~ s/&#125;/\}/gsm;
    $_[0] =~ s/&amp;/&/gsm;
    return $_[0];
}

sub dopre {
    my ($inp) = @_;
    $inp =~ s/<br \/>/\n/gxsm;
    $inp =~ s/<br>/\n/gxsm;
    return $inp;
}

sub Split_Splice_Move {
    my ( $s_s_m, $s_s_n ) = @_;
    my $ssm = 0;
    if ( !$s_s_n ) {    # Just for the subject of a message
        $s_s_m =~ s/^(Re: )?\[m.*?\]/$maintxt{'758'}/sm;
        return $s_s_m;
    }
    elsif ( $s_s_m =~ /\[m by=(.+?) destboard=(.+?) dest=(.+?)\]/sm )
    {                   # 'This Topic has been moved to' a different board
        my ( $mover, $destboard, $dest ) = ( $1, $2, $3 );

        # Who moved the topic; destination board; destination id number
        $mover = decloak($mover);
        LoadUser($mover);
        $board{$destboard} =~ /^(.+?)\|/xsm;
        return (
qq~<b>$maintxt{'160'} <a href="$scripturl?num=$dest"><b>$maintxt{'160a'}</b></a> $maintxt{'160b'}</b> <a href="$scripturl?board=$destboard"><i><b>$1</b></i></a><b> $maintxt{'525'} <i>${$uid.$mover}{'realname'}</i></b>~,
            $dest
        );
    }
    elsif ( $s_s_m =~ /\[m by=(.+?) dest=(.+?)\]/sm )
    {    # 'The contents of this Topic have been moved to''this Topic'
        my ( $mover, $dest ) =
          ( $1, $2 );    # Who moved the topic; destination id number
        $mover = decloak($mover);
        LoadUser($mover);
        return (
qq~<b>$maintxt{'160c'}</b> <a href="$scripturl?num=$dest"><i><b>$maintxt{'160d'}</b></i></a><b> $maintxt{'525'} <i>${$uid.$mover}{'realname'}</i></b>~,
            $dest
        );
    }
    elsif ( $s_s_m =~ /^\[m\]/sm )
    {    # Old style topic that was moved/spliced before this code
        fopen( MOVEDFILE, "$datadir/$_[1].txt" );
        (
            undef, undef, undef, undef,  undef,
            undef, undef, undef, $s_s_m, undef
        ) = split /\|/xsm, <MOVEDFILE>, 10;
        fclose(MOVEDFILE);
        ToChars($s_s_m);
        $ssm = 1;
    }

    $ssm += $s_s_m =~ s/\[spliced\]/$maintxt{'160c'}/gxsm;

    # The contents of this Topic have been moved to
    $ssm += $s_s_m =~
      s/\[splicedhere\]|\[splithere\]/$maintxt{'160d'}/gxsm;    # this Topic
    $ssm += $s_s_m =~
      s/\[split\]/$maintxt{'160e'}/gxsm;  # Off-Topic replies have been moved to
    $ssm += $s_s_m =~ s/\[splithere_end\]/$maintxt{'160f'}/gxsm;    # .
    $ssm +=
      $s_s_m =~ s/\[moved\]/$maintxt{'160'}/gxsm; # This Topic has been moved to
    $ssm += $s_s_m =~
      s/\[movedhere\]/$maintxt{'161'}/gxsm;    # This Topic was moved here from
    $ssm += $s_s_m =~ s/\[postsmovedhere1\]/$maintxt{'161a'}/gxsm;    # The last
    $ssm += $s_s_m =~
      s/\[postsmovedhere2\]/$maintxt{'161b'}/gxsm;  # Posts were moved here from
    $ssm += $s_s_m =~ s/\[move by\]/$maintxt{'525'}/gxsm;    # by

    if ($ssm) {    # only if it was an internal s_s_m info
        $s_s_m =~
s/\[link=\s*(\S\w+\:\/\/\S+?)\s*\](.+?)\[\/link\]/<a href="$1">$2<\/a>/gxsm;
        $s_s_m =~
s/\[link=\s*(\S+?)\](.+?)\s*\[\/link\]/<a href="http:\/\/$1">$2<\/a>/gxsm;
        $s_s_m =~ s/\[b\](.*?)\[\/b\]/<b>$1<\/b>/gxsm;
        $s_s_m =~ s/\[i\](.*?)\[\/i\]/<i>$1<\/i>/gxsm;
    }
    return ( $s_s_m, $ssm );
}

sub elimnests {
    my ($inp) = @_;
    $inp =~ s/\[\/*shadow([^\]]*)\]//igxsm;    #*/;
    $inp =~ s/\[\/*glow([^\]]*)\]//igxsm;      #*/;
    return $inp;
}

sub unwrap {
    my ( $codelang, $unwrapped ) = @_;
    $unwrapped =~ s/<yabbwrap>//gxsm;
    $unwrapped = qq~\[code$codelang\]$unwrapped\[\/code\]~;
    return $unwrapped;
}

sub wrap {
    if ($newswrap) { $linewrap = $newswrap; }
    $message =~ s/ &nbsp; &nbsp; &nbsp;/\[tab\]/igsm;
    $message =~ s/<br \/>/\n/gsm;
    $message =~ s/<br>/\n/gxsm;
    $message =~ s/((\[ch\d{3,}?\]){$linewrap})/$1\n/igsm;

    FromHTML($message);
    $message =~ s/[\n\r]/ <yabbbr> /gsm;
    my @words = split /\s/xsm, $message;
    $message = q{};
    foreach my $cur (@words) {
        if (   $cur !~ m{www\.(\S+?)\.}xsm
            && $cur !~ m{[ht|f]tp://}xsm
            && $cur !~ m{\[\S*\]}xsm
            && $cur !~ m{\[\S*\s?\S*?\]}xsm
            && $cur !~ m{\[\/\S*\]}xsm )
        {
            $cur =~ s/(\S{$linewrap})/$1\n/gism;
        }
        if (   $cur !~ m{\[table(\S*)\](\S*)\[\/table\]}xsm
            && $cur !~ m{\[url(\S*)\](\S*)\[\/url\]}xsm
            && $cur !~ m{\[flash(\S*)\](\S*)\[\/flash\]}xsm
            && $cur !~ m{\[img(\S*)\](\S*)\[\/img\]}xsm )
        {
            $cur =~ s/(\[\S*?\])/ $1 /gxsm;
            @splitword = split /\s/xsm, $cur;
            $cur = q{};
            foreach my $splitcur (@splitword) {
                if (   $splitcur !~ m{www\.(\S+?)\.}xsm
                    && $splitcur !~ m{[ht|f]tp://}xsm
                    && $splitcur !~ m{\[\S*\]}xsm )
                {
                    $splitcur =~ s/(\S{$linewrap})/$1<yabbwrap>/gism;
                }
                $cur .= $splitcur;
            }
        }
        $message .= "$cur ";
    }
    $message =~ s/\[code((?:\s*).*?)\](.*?)\[\/code\]/unwrap($1,$2)/eisgm;
    $message =~ s/ <yabbbr> /\n/gsm;
    $message =~ s/<yabbwrap>/\n/gsm;

    ToHTML($message);
    $message =~ s/\[tab\]/ &nbsp; &nbsp; &nbsp;/igsm;
    $message =~ s/\n/<br \/>/gsm;
    return;
}

sub wrap2 {
    $message =~
s/<a href=(\S*?)(\s[^>]*)?>(\S*?)<\/a>/ my ($mes,$out,$i) = ($3,q{},1); { while ($mes ne q{}) { if ($mes =~ s\/^(<.+?>)\/\/) { $out .= $1; } elsif ($mes =~ s\/^(&.+?;|\[ch\d{3,}\]|.)\/\/) { last if $i > $linewrap; $i++; $out .= $1; if ($mes eq q{}) { $i--; last; } } } } "<a href=$1$2>$out" . ($i > $linewrap ? q{...} : q{}) . '<\/a>' /eigsm;
    return;
}

sub MembershipGet {
    if ( fopen( FILEMEMGET, "$memberdir/members.ttl" ) ) {
        $_ = <FILEMEMGET>;
        chomp;
        fclose(FILEMEMGET);
        return split /\|/xsm, $_;
    }
    else {
        my @ttlatest = MembershipCountTotal();
        return @ttlatest;
    }
}

{
    my %yyOpenMode = (
        '+>>' => 5,
        '+>'  => 4,
        '+<'  => 3,
        '>>'  => 2,
        '>'   => 1,
        '<'   => 0,
        q{}   => 0,
    );

    # fopen: opens a file. Allows for file locking and better error-handling.
    sub fopen ($$;$) {
        my ( $filehandle, $filename, $usetmp ) = @_;
        my ( $pack,       $file,     $line )   = caller;
        $file_open++;
        ## make life easier - spot a file that is not closed!
        if ($debug) {
            LoadLanguage('Debug');
            $openfiles .=
                qq~$filehandle (~
              . sprintf( '%.4f', ( time - $START_TIME ) )
              . qq~)     $filename~;
        }
        my ( $flockCorrected, $cmdResult, $openMode, $openSig );

        $serveros = $OSNAME;    #"$^O";
                                #magic punctuation variable BAD #
        if ( $serveros =~ m/Win/sm && substr( $filename, 1, 1 ) eq q{:} ) {
            $filename =~ s/\\/\\\\/gxsm;

        # Translate windows-style \ slashes to windows-style \\ escaped slashes.
            $filename =~ s/\//\\\\/gxsm;

           # Translate unix-style / slashes to windows-style \\ escaped slashes.
        }
        else {
            $filename =~ tr~\\~/~;

            # Translate windows-style \ slashes to unix-style / slashes.
        }
        $LOCK_EX     = 2; # You can probably keep this as it is set now.
        $LOCK_UN     = 8; # You can probably keep this as it is set now.
        $LOCK_SH     = 1; # You can probably keep this as it is set now.
        $usetempfile = 0; # Write to a temporary file when updating large files.

        # Check whether we want write, append, or read.
        if ( $filename =~ m/\A([<>+]*)(.+)/sm ) {
            $openSig  = $1 || q{};
            $filename = $2 || $filename;
        }
        $openMode = $yyOpenMode{$openSig} || 0;

        $filename =~ s/[^\/\\0-9A-Za-z#%+\,\-\ \.\:@^_]//gxsm;

        # Remove all inappropriate characters.

        if ( $filename =~ m{/\.\./}sm ) {
            fatal_error( 'cannot_open', "$filename. $maintxt{'609'}" );
        }

# If the file doesn't exist, but a backup does, rename the backup to the filename
        if ( !-e $filename && -e "$filename.bak" ) {
            rename "$filename.bak", "$filename";
        }
        if ( -z $filename && -e "$filename.bak" ) {
            rename "$filename.bak", "$filename";
        }

        $testfile = $filename;
        if ( $use_flock == 2 && $openMode ) {
            my $count;
            while ( $count < 15 ) {
                if   ( -e $filehandle ) { sleep 2; }
                else                    { last; }
                ++$count;
            }
            if ( $count == 15 ) { unlink $filehandle; }
            *LFH = undef;
            CORE::open( LFH, ">$filehandle" );
            $yyLckFile{$filehandle} = *LFH;
        }

        if (   $use_flock
            && $openMode == 1
            && $usetmp
            && $usetempfile
            && -e $filename )
        {
            $yyTmpFile{$filehandle} = $filename;
            $filename .= '.tmp';
        }

        if ( $openMode > 2 ) {
            if ( $openMode == 5 ) {
                $cmdResult = CORE::open( $filehandle, "+>>$filename" );
            }
            elsif ( $use_flock == 1 ) {
                if ( $openMode == 4 ) {
                    if ( -e $filename ) {

                     # We are opening for output and file locking is enabled...
                     # read-open() the file rather than write-open()ing it.
                     # This is to prevent open() from clobbering the file before
                     # checking if it is locked.
                        $flockCorrected = 1;
                        $cmdResult = CORE::open( $filehandle, "+<$filename" );
                    }
                    else {
                        $cmdResult = CORE::open( $filehandle, "+>$filename" );
                    }
                }
                else {
                    $cmdResult = CORE::open( $filehandle, "+<$filename" );
                }
            }
            elsif ( $openMode == 4 ) {
                $cmdResult = CORE::open( $filehandle, "+>$filename" );
            }
            else {
                $cmdResult = CORE::open( $filehandle, "+<$filename" );
            }
        }
        elsif ( $openMode == 1 && $use_flock == 1 ) {
            if ( -e $filename ) {

                # We are opening for output and file locking is enabled...
                # read-open() the file rather than write-open()ing it.
                # This is to prevent open() from clobbering the file before
                # checking if it is locked.
                $flockCorrected = 1;
                $cmdResult = CORE::open( $filehandle, "+<$filename" );
            }
            else {
                $cmdResult = CORE::open( $filehandle, ">$filename" );
            }
        }
        elsif ( $openMode == 1 ) {
            $cmdResult = CORE::open( $filehandle, ">$filename" );

            # Open the file for writing
        }
        elsif ( $openMode == 2 ) {
            $cmdResult = CORE::open( $filehandle, ">>$filename" );

            # Open the file for append
        }
        elsif ( $openMode == 0 ) {
            $cmdResult =
              CORE::open( $filehandle, $filename );    # Open the file for input
        }
        if ( !$cmdResult ) { return 0; }
        if ($flockCorrected) {

# The file was read-open()ed earlier, and we have now verified an exclusive lock.
# We shall now clobber it.
            flock $filehandle, $LOCK_EX;
            if ($faketruncation) {
                CORE::open( OFH, ">$filename" );
                if ( !$cmdResult ) { return 0; }
                print {OFH} q{} or croak "$croak{'print'} OFH";
                CORE::close(OFH);
            }
            else {
                truncate( *{$filehandle}, 0 )
                  or fatal_error( 'truncation_error', "$filename" );
            }
            seek $filehandle, 0, 0;
        }
        elsif ( $use_flock == 1 ) {
            if   ($openMode) { flock $filehandle, $LOCK_EX; }
            else             { flock $filehandle, $LOCK_SH; }
        }
        return 1;
    }

# fclose: closes a file, using Windows 95/98/ME-style file locking if necessary.
    sub fclose ($) {
        my ($filehandle) = @_;
        my ( $pack, $file, $line ) = caller;
        $file_close++;
        if ($debug) {
            LoadLanguage('Debug');
            $openfiles .=
                qq~     $filehandle (~
              . sprintf( '%.4f', ( time - $START_TIME ) )
              . qq~)\n[$pack, $file, $line]\n\n~;
        }
        CORE::close($filehandle);
        if ( $use_flock == 2 ) {
            if ( exists $yyLckFile{$filehandle} && -e $filehandle ) {
                CORE::close( $yyLckFile{$filehandle} );
                unlink $filehandle;
                delete $yyLckFile{$filehandle};
            }
        }
        if ( $yyTmpFile{$filehandle} ) {
            my $bakfile = $yyTmpFile{$filehandle};
            if ( $use_flock == 1 ) {

                # Obtain an exclusive lock on the file.
                # ie: wait for other processes to finish...
                *FH = undef;
                CORE::open( FH, $bakfile );
                flock FH, $LOCK_EX;
                CORE::close(FH);
            }

            # Switch the temporary file with the original.
            if ( -e "$bakfile.bak" ) { unlink "$bakfile.bak"; }
            rename $bakfile, "$bakfile.bak";
            rename "$bakfile.tmp", $bakfile;
            delete $yyTmpFile{$filehandle};
            if ( -e $bakfile ) {
                unlink "$bakfile.bak";

                # Delete the original file to save space.
            }
        }
        return 1;
    }

}    # / my %yyOpenMode

sub KickGuest {
    require Sources::LogInOut;
    $sharedLogin_title = "$maintxt{'633'}";
    $sharedLogin_text =
qq~<br />$maintxt{'634'}<br />$maintxt{'635'} <a href="$scripturl?action=register">$maintxt{'636'}</a> $maintxt{'637'}<br /><br />~;
    $yymain .= sharedLogin();
    $yytitle = "$maintxt{'34'}";
    template();
    return;
}

sub WriteLog {
    if (   $action eq 'ajxmessage'
        || $action eq 'ajximmessage'
        || $action eq 'ajxcal' )
    {
        return;
    }

    # comment out (#) the next line if you have problems with
    # 'Reverse DNS lookup timeout causes slow page loads'
    # (http://www.yabbforum.com/community/YaBB.pl?num=1199991357)
    # Search Engine identification and display will be turned off
    my $user_host =
      ( gethostbyaddr pack( 'C4', split /\./xsm, $user_ip ), 2 )[0];

    my ( $name, $logtime, @new_log );
    my $onlinetime = $date - ( $OnlineLogTime * 60 );
    my $field = $username;
    if ( $field eq 'Guest' ) {
        if ($guestaccess) { $field = $user_ip; }
        else              { return; }
    }

    fopen( LOG, "<$vardir/log.txt" );
    @logentries = <LOG>;    # Global variable
    fclose( LOG );
    foreach (@logentries) {
        ( $name, $logtime, undef ) = split /\|/xsm, $_, 3;
        if ( $name ne $user_ip && $name ne $field && $logtime >= $onlinetime ) {
            push @new_log, $_;
        }
    }
   fopen( LOG, ">$vardir/log.txt" );
    print {LOG} (
"$field|$date|$user_ip|$user_host#$ENV{'HTTP_USER_AGENT'}|$username|$currentboard|"
          . (
            ( !$action && $INFO{'num'} && $currentboard )
            ? 'display'
            : (
                (
                        !$action
                      && $ENV{'SCRIPT_FILENAME'} =~ /\/AdminIndex\.(pl|cgi)/sm
                ) ? 'admincenter' : $action
            )
          )
          . "|$INFO{'username'}|$curnum\n",
        @new_log
    ) or croak qq~$croak{'print'} log.txt~;
    fclose(LOG);

    if ( !$action && $enableclicklog == 1 ) {
        $onlinetime = $date - ( $ClickLogTime * 60 );
        fopen( LOG, "<$vardir/clicklog.txt", 1 );
        @new_log = <LOG>;
        fclose( LOG );
        fopen( LOG, ">$vardir/clicklog.txt", 1 );
        print {LOG} "$field|$date|$ENV{'REQUEST_URI'}|"
          . (
            $ENV{'HTTP_REFERER'} =~ m/$boardurl/ism
            ? q{}
            : $ENV{'HTTP_REFERER'}
          )
          . "|$ENV{'HTTP_USER_AGENT'}\n"
          or croak "$croak{'print'} LOG";
        foreach (@new_log) {
            if ( ( split /\|/xsm, $_, 3 )[1] >= $onlinetime ) {
                print {LOG} $_ or croak "$croak{'print'} LOG";
            }
        }
        fclose(LOG);
    }
    return;
}

sub RemoveUserOnline {
    my $user = shift;
    fopen( LOG, "<$vardir/log.txt", 1 );
    @logentries = <LOG>;    # Global variable
    fclose( LOG );
    fopen( LOG, ">$vardir/log.txt", 1 );
    if ($user) {
        my $x = -1;
        for my $i ( 0 .. ( @logentries - 1 ) ) {
            if ( ( split /\|/xsm, $logentries[$i], 2 )[0] ne $user ) {
                print {LOG} $logentries[$i] or croak "$croak{'print'} LOG";
            }
            elsif ( $user eq $username ) {
                $logentries[$i] =~ s/^$user\|/$user_ip\|/xsm;
                print {LOG} $logentries[$i] or croak "$croak{'print'} LOG";
            }
            else { $x = $i; }
        }
        if ( $x > -1 ) { splice @logentries, $x, 1; }
    }
    else {
        print {LOG} q{} or croak "$croak{'print'} LOG";
        @logentries = ();
    }
    fclose(LOG);
    return;
}

sub encode_password {
    my ($eol) = @_;
    chomp $eol;
    require Digest::MD5;
    import Digest::MD5 qw(md5_base64);
    return md5_base64($eol);
}

sub Censor {
    my ($string) = @_;
    foreach my $censor (@censored) {
        my ( $tmpa, $tmpb, $tmpc ) = @{$censor};
        if ($tmpc) {
            $string =~
              s/(^|\W|_)\Q$tmpa\E(?=$|\W|_)/$1$tmpb/gism;
        }
        else {
            $string =~ s/\Q$tmpa\E/$tmpb/gism;
        }
    }
    return $string;
}

sub CheckCensor {
    my ($string) = @_;
    foreach my $censor (@censored) {
        my ( $tmpa, $tmpb, $tmpc ) = @{$censor};
        if ( $string =~ m/(\Q$tmpa\E)/ixsm ) {
            $found_word .= "$1 ";
        }
    }
    return $found_word;
}

sub referer_check {
    return if !$action;
    my $referencedomain = substr $boardurl, 7, ( index $boardurl, q{/}, 7 ) - 7;
    my $refererdomain = substr $ENV{HTTP_REFERER}, 7,
      ( index $ENV{HTTP_REFERER}, q{/}, 7 ) - 7;
    if (   $refererdomain !~ /$referencedomain/sm
        && $ENV{QUERY_STRING} ne q{}
        && length($refererdomain) > 0 )
    {
        my $goodaction = 0;
        fopen( ALLOWED, "$vardir/allowed.txt" );
        my @allowed = <ALLOWED>;
        fclose(ALLOWED);
        foreach my $allow (@allowed) {
            chomp $allow;
            if ( $action eq $allow ) { $goodaction = 1; last; }
        }
        if ( !$goodaction ) {
            fatal_error( 'referer_violation',
"$action<br />$reftxt{'7'} $referencedomain<br />$reftxt{'6'} $refererdomain"
            );
        }
    }
    return;
}

sub Dereferer {
    if ( !$stealthurl ) { fatal_error('no_access'); }
    if ($yycharset) {$yymycharset = $yycharset;}
    print "Content-Type: text/html\n\n" or croak "$croak{'print'} content-type";
    print
qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$abbr_lang" lang="$abbr_lang">\n<head>\n<meta http-equiv="Content-Type" content="text/html; charset=$yymycharset" />\n<title>-----</title>\n</head>\n<body onload="window.location.href='$INFO{'url'}';">\n<span style="font-family:Arial; font-size:medium">$dereftxt{'1'}</span>\n</body></html>\n~
      or croak "$croak{'print'}";
    exit;
}

sub LoadLanguage {
    my ($what_to_load) = @_;
    my $use_lang = $language ? $language : $lang;
    if ( -e "$langdir/$use_lang/$what_to_load.lng" ) {
        require "$langdir/$use_lang/$what_to_load.lng";
    }
    elsif ( -e "$langdir/$lang/$what_to_load.lng" ) {
        require "$langdir/$lang/$what_to_load.lng";
    }
    elsif ( -e "$langdir/English/$what_to_load.lng" ) {
        require "$langdir/English/$what_to_load.lng";
    }
    else {

       # Catches deep recursion problems
       # We can simply return to the error routine once we add the needed string
        if ( $what_to_load eq 'Error' ) {
            %error_txt = (
                'cannot_open_language' =>
'Cannot find required language file. Please inform the administrator about this problem.',
                'error_description' => 'An Error Has Occurred!',
            );
            return;
        }

        fatal_error( 'cannot_open_language', "$use_lang/$what_to_load.lng" );
    }
    return;
}

sub Recent_Load {
    my ($who_to_load) = @_;
    undef %recent;
    if ( -e "$memberdir/$who_to_load.rlog" ) {
        fopen( RLOG, "$memberdir/$who_to_load.rlog" );
        my %r = map { /(.*)\t(.*)/xsm } <RLOG>;
        fclose(RLOG);
        map { @{ $recent{$_} } = split /,/xsm, $r{$_} } keys %r;
    }
    elsif ( -e "$memberdir/$who_to_load.wlog" ) {
        require "$memberdir/$who_to_load.wlog";
        fopen( RLOG, ">$memberdir/$who_to_load.rlog" );
        print {RLOG} map { "$_\t$recent{$_}\n" } keys %recent
          or croak "$croak{'print'} RLOG";
        fclose(RLOG);
        unlink "$memberdir/$who_to_load.wlog";
        Recent_Load($who_to_load);
    }
    return;
}

sub Recent_Write {
    my ( $todo, $recentthread, $recentuser, $recenttime ) = @_;
    Recent_Load($recentuser);
    if ( $todo eq 'incr' ) {
        ${ $recent{$recentthread} }[0]++;
        ${ $recent{$recentthread} }[1] = $recenttime;
    }
    elsif ( $todo eq 'decr' ) {
        ${ $recent{$recentthread} }[0]--;
        if ( ${ $recent{$recentthread} }[0] < 1 ) {
            delete $recent{$recentthread};
        }
        else { ${ $recent{$recentthread} }[1] = $recenttime; }
    }
    Recent_Save($recentuser);
    return;
}

sub Recent_Save {
    my ($who_to_save) = @_;
    if ( !%recent ) {
        unlink "$memberdir/$who_to_save.rlog";
        return;
    }
    fopen( RLOG, ">$memberdir/$who_to_save.rlog" );
    print {RLOG} map { "$_\t" . join( q{,}, @{ $recent{$_} } ) . "\n" }
      keys %recent
      or croak "$croak{'print'} RLOG";
    fclose(RLOG);
    return;
}

sub save_moved_file {

   # This sub saves the hash for the moved files: key == old id, value == new id
    fopen( MOVEDFILE, ">$vardir/Movedthreads.pm" )
      or fatal_error( 'cannot_open', "$vardir/Movedthreads.pm", 1 );
    print {MOVEDFILE} '%moved_file = ('
      . join( q{,},
        map { qq~"$_","$moved_file{$_}"~ }
          grep { ( $_ > 0 && $moved_file{$_} > 0 && $_ != $moved_file{$_} ) }
          keys %moved_file )
      . ");\n1;"
      or croak "$croak{'print'} MOVEDFILE";
    fclose(MOVEDFILE);
    return;
}

sub Write_ForumMaster {
    fopen( FORUMMASTER, ">$boardsdir/forum.master", 1 );
    print {FORUMMASTER} qq~\$mloaded = 1;\n~
      or croak "$croak{'print'} FORUMMASTER";
    @catorder = undupe(@categoryorder);
    print {FORUMMASTER} qq~\@categoryorder = qw(@catorder);\n~
      or croak "$croak{'print'} FORUMMASTER";
    my ( $key, $value );
    while ( ( $key, $value ) = each %cat ) {
        %seen = ();
        @catval = split /\,/xsm, $value;
        @unique = grep { !$seen{$_} ++ } @catval;
        $val2 = join ',', @unique;

        print {FORUMMASTER} qq~\$cat{'$key'} = qq\~$val2\~;\n~
          or croak "$croak{'print'} FORUMMASTER";
    }
    while ( ( $key, $value ) = each %catinfo ) {
        my ( $catname, $therest ) = split /\|/xsm, $value, 2;

        #$catname =~ s/\&(?!amp;)/\&amp;$1/g;
        # We can rely on the admin scripts to properly encode when needed.
        $value = "$catname|$therest";

        # Escape membergroups with a $ in them
        $value =~ s/\$/\\\$/gxsm;

        # Strip membergroups with a ~ from them
        $value =~ s/\~//gxsm;
        print {FORUMMASTER} qq~\$catinfo{'$key'} = qq\~$value\~;\n~
          or croak "$croak{'print'} FORUMMASTER";
    }
    while ( ( $key, $value ) = each %board ) {
        my ( $boardname, $therest ) = split /\|/xsm, $value, 2;

        #$boardname =~ s/\&(?!amp;)/\&amp;$1/g;
        # We can rely on the admin scripts to properly encode when needed.
        $value = "$boardname|$therest";

        # Escape membergroups with a $ in them
        $value =~ s/\$/\\\$/gxsm;

        # Strip membergroups with a ~ from them
        $value =~ s/\~//gxsm;
        print {FORUMMASTER} qq~\$board{'$key'} = qq\~$value\~;\n~
          or croak "$croak{'print'} FORUMMASTER";
    }
    while ( ( $key, $value ) = each %subboard ) {
        if ( $value ne q{} ) {
            print {FORUMMASTER} qq~\$subboard{'$key'} = qq\~$value\~;\n~
              or croak "$croak{'print'} FORUMMASTER";
        }
    }
    print {FORUMMASTER} qq~\n1;~ or croak "$croak{'print'} FORUMMASTER";
    fclose(FORUMMASTER);
    return;
}

sub dirsize {
    my ($drsz) = @_;
    my $dirsize;
    require File::Find;
    import File::Find;
    find( sub { $dirsize += -s }, $drsz );
    return $dirsize;
}

sub MemberPageindex {
    my ( $msindx, $trindx, $mbindx, $pmindx ) =
      split /\|/xsm, ${ $uid . $username }{'pageindex'};
    if ( $INFO{'action'} eq 'memberpagedrop' ) {
        ${ $uid . $username }{'pageindex'} = qq~$msindx|$trindx|0|$pmindx~;
    }
    if ( $INFO{'action'} eq 'memberpagetext' ) {
        ${ $uid . $username }{'pageindex'} = qq~$msindx|$trindx|1|$pmindx~;
    }
    UserAccount( $username, 'update' );
    my $SearchStr = $FORM{'member'} || $INFO{'member'};
    if ( $SearchStr ne q{} ) { $findmember = qq~;member=$SearchStr~; }
    if ( !$INFO{'from'} ) {
        $yySetLocation =
qq~$scripturl?action=ml;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}$findmember~;
    }
    elsif ( $INFO{'from'} eq 'imlist' ) {
        $yySetLocation =
qq~$scripturl?action=imlist;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'};field=$INFO{'field'}~;
    }
    elsif ( $INFO{'from'} eq 'admin' ) {
        $yySetLocation =
qq~$adminurl?action=ml;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}~;
    }

    redirectexit();
    return;
}

#changed sub for improved performance, code from Zoo
sub check_existence {
    my ( $dir, $filename ) = @_;
    my ( $origname, $filext );

    if ( $filename =~ /(\S+?)(\.\S+$)/sm ) {
        $origname = $1;
        $filext   = $2;
    }
    my $numdelim = '_';
    my $filenumb = 0;
    while ( -e "$dir/$filename" ) {
        $filenumb = sprintf '%03d', ++$filenumb;
        $filename = qq~$origname$numdelim$filenumb$filext~;
    }
    return ($filename);
}

sub ManageMemberlist {
    my ( $todo, $user, $userreg ) = @_;
    if (   $todo eq 'load'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        fopen( MEMBLIST, "$memberdir/memberlist.txt" );
        %memberlist = map { /(.*)\t(.*)/m } <MEMBLIST>;
        fclose(MEMBLIST);
    }
    if ( $todo eq 'add' ) {
        $memberlist{$user} = "$userreg";

    }
    elsif ( $todo eq 'update' ) {
        $memberlist{$user} = $userreg ? $userreg : $memberlist{$user};

    }
    elsif ( $todo eq 'delete' ) {
        if ( $user =~ /,/sm ) {    # been sent a list to kill, not a single
            my @oldusers = split /,/xsm, $user;
            foreach my $user (@oldusers) {
                delete $memberlist{$user};
            }
        }
        else { delete $memberlist{$user}; }
    }
    if (   $todo eq 'save'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        fopen( MEMBLIST, ">$memberdir/memberlist.txt" );
        print {MEMBLIST} map { "$_\t$memberlist{$_}\n" }
          sort { $memberlist{$a} <=> $memberlist{$b} } keys %memberlist
          or croak "$croak{'print'} MEMBLIST";
        fclose(MEMBLIST);
        undef %memberlist;
    }
    return;
}

## deal with basic member data in memberinfo.txt
sub ManageMemberinfo {
    my ( $todo, $user, $userdisp, $usermail, $usergrp, $usercnt, $useraddgrp ) =
      @_;
    ## pull hash of member name + other data
    if (   $todo eq 'load'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        fopen( MEMBINFO, "$memberdir/memberinfo.txt" );
        @membinfo = <MEMBINFO>;
        chomp @membinfo;
        %memberinf = map { /(.*)\t(.*)/xsm } @membinfo;
        fclose(MEMBINFO);
    }
    if ( $todo eq 'add' ) {
        $memberinf{$user} = "$userdisp|$usermail|$usergrp|$usercnt|$useraddgrp";
    }
    elsif ( $todo eq 'update' ) {
        ( $memrealname, $mememail, $memposition, $memposts, $memaddgrp ) =
          split /\|/xsm, $memberinf{$user};
        if ($userreg)  { $regdate     = $userreg; }
        if ($userdisp) { $memrealname = $userdisp; }
        if ($usermail) { $mememail    = $usermail; }
        if ($usergrp)  { $memposition = $usergrp; }
        if ($usercnt)  { $memposts    = $usercnt; }
        if ($useraddgrp) {
            if ( $useraddgrp =~ /###blank###/sm ) { $useraddgrp = q{}; }
            $memaddgrp = $useraddgrp;
        }
        $memberinf{$user} =
          "$memrealname|$mememail|$memposition|$memposts|$memaddgrp";
    }
    elsif ( $todo eq 'delete' ) {
        if ( $user =~ /,/xsm ) {    # been sent a list to kill, not a single
            my @oldusers = split /,/xsm, $user;
            foreach my $user (@oldusers) {
                delete $memberinf{$user};
            }
        }
        delete $memberinf{$user};
    }
    if (   $todo eq 'save'
        || $todo eq 'update'
        || $todo eq 'delete'
        || $todo eq 'add' )
    {
        fopen( MEMBINFO, ">$memberdir/memberinfo.txt" );
        print {MEMBINFO} map { "$_\t$memberinf{$_}\n" } keys %memberinf
          or croak "$croak{'print'} MEMBINFO";
        fclose(MEMBINFO);
        undef %memberinf;
    }
    return;
}

sub Collapse_Load {
    my ( %userhide, $catperms, $catallowcol, $access );
    my $i = 0;
    map { $userhide{$_} = 1; } split /,/xsm, ${ $uid . $username }{'cathide'};
    foreach my $key (@categoryorder) {
        ( undef, $catperms, $catallowcol ) = split /\|/xsm, $catinfo{$key};
        $access = CatAccess($catperms);
        if ( $catallowcol == 1 && $access ) { $i++; }
        $catcol{$key} = 1;
        if ( $catallowcol == 1 && $userhide{$key} ) { $catcol{$key} = 0; }
    }
    $colbutton = ( $i == keys %userhide ) ? 0 : 1;
    $colloaded = 1;
    return;
}

sub MailList {
    my ($m_line) = @_;
    is_admin_or_gmod();
    my $delmailline = q{};
    if ( !$INFO{'delmail'} ) {
        $mailline = $m_line;
        $mailline =~ s/\r//gxsm;
        $mailline =~ s/\n/<br \/>/gsm;
    }
    else {
        $delmailline = $INFO{'delmail'};
    }
    if ( -e ("$vardir/maillist.dat") ) {
        fopen( FILE, "$vardir/maillist.dat" );
        @maillist = <FILE>;
        fclose(FILE);
        fopen( FILE, ">$vardir/maillist.dat" );
        if ( !$INFO{'delmail'} ) {
            print {FILE} "$mailline\n" or croak "$croak{'print'} FILE";
        }
        foreach my $curmail (@maillist) {
            chomp $curmail;
            $otime = ( split /\|/xsm, $curmail )[0];
            if ( $otime ne $delmailline ) {
                print {FILE} "$curmail\n" or croak "$croak{'print'} FILE";
            }
        }
        fclose(FILE);
    }
    else {
        fopen( FILE, ">$vardir/maillist.dat" );
        print {FILE} "$mailline\n" or croak "$croak{'print'} FILE";
        fclose(FILE);
    }
    if ( $INFO{'delmail'} ) {
        $yySetLocation = qq~$adminurl?action=mailing~;
        redirectexit();
    }
    return;
}

sub cloak {
    my ($input) = @_;
    my ( $user, $ascii, $key, $hex, $hexkey );
    $key = substr $date, length($date) - 2, 2;
    $hexkey = uc( unpack 'H2', pack 'V', $key );
    for my $n ( 0 .. ( length($input) - 1 ) ) {
        $ascii = substr $input, $n, 1;
        $ascii = ord($ascii) ^ $key;

        # xor it instead of adding to prevent wide characters
        $hex = uc( unpack 'H2', pack 'V', $ascii );
        $user .= $hex;
    }
    $user .= $hexkey;
    $user .= '0';
    return $user;
}

sub decloak {
    my ($input) = @_;
    my ( $user, $ascii, $key, $dec, $hexkey );
    if ( $input !~ /\A[0-9A-F]+\Z/xsm ) {
        return $input;
    }    # probably a non cloaked ID as it contains non hex code
    else { $input =~ s/0$//xsm; }
    $hexkey = substr $input, length($input) - 2, 2;
    $key = hex $hexkey;
    foreach my $n ( 0 .. ( length($input) - 3 ) ) {
        if ( $n % 2 == 0 ) {
            $dec = substr $input, $n, 2;
            $ascii = hex($dec) ^ $key;

            # xor it to reverse it
            $ascii = chr $ascii;
            $user .= $ascii;
        }
    }
    return $user;
}

# run through the log.txt and return the online/offline/away string near by the username
my %users_online;

sub userOnLineStatus {
    my ($userToCheck) = @_;

    if ( $userToCheck eq 'Guest' ) { return; }
    if ( exists $users_online{$userToCheck} ) {
        if ( $users_online{$userToCheck} ) {
            return $users_online{$userToCheck};
        }
    }
    else {
        map { $users_online{ ( split /\|/xsm, $_, 2 )[0] } = 0 } @logentries;
    }

    LoadUser($userToCheck);

    if ( exists $users_online{$userToCheck}
        && ( !${ $uid . $userToCheck }{'stealth'} || $iamadmin || $iamgmod ) )
    {
        ${ $uid . $userToCheck }{'offlinestatus'} = 'online';
        $users_online{$userToCheck} =
          qq~<span class="useronline">$maintxt{'60'}</span>~
          . ( ${ $uid . $userToCheck }{'stealth'} ? q{*} : q{} );
    }
    else {
        $users_online{$userToCheck} =
          qq~<span class="useroffline">$maintxt{'61'}</span>~;
    }

# enable 'away' indicator $enable_MCaway: 0=Off; 1=Staff to Staff; 2=Staff to all; 3=Members
    if (  !$iamguest
        && $enable_MCstatusStealth
        && ( ( $enable_MCaway == 1 && $staff ) || $enable_MCaway > 1 )
        && ${ $uid . $userToCheck }{'offlinestatus'} eq 'away' )
    {
        $users_online{$userToCheck} =
          qq~<span class="useraway">$maintxt{'away'}</span>~;
    }
    return $users_online{$userToCheck};
}

## moved from Register.pm so we can use for guest browsing
sub guestLangSel {
    opendir DIR, $langdir;
    $morelang = 0;
    my @langDir = readdir DIR;
    closedir DIR;
    foreach my $langitems ( sort { lc($a) cmp lc $b } @langDir ) {
        chomp $langitems;
        if (   ( $langitems ne q{.} )
            && ( $langitems ne q{..} )
            && ( $langitems ne q{.htaccess} )
            && ( $langitems ne q{index.html} ) )
        {
            $lngsel = q{};
            if ( $langitems eq $language ) {
                $lngsel = q~ selected="selected"~;
            }
            my $displang = $langitems;
            $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
            $langopt .=
              qq~<option value="$langitems"$lngsel>$displang</option>~;
            $morelang++;
        }
    }
    return $langopt;
}

##  control guest language selection.

sub setGuestLang {
    ## if either 'no guest access' or 'no guest lan sel', throw the user back to the login screen
    if ( !$guestaccess || !$enable_guestlanguage ) {
        $yySetLocation = qq~$scripturl?action=login~;
        redirectexit();
    }

  # otherwise, grab the selected language from the form and redirect to load it.
    $guestLang     = $FORM{'guestlang'};
    $language      = $guestLang;
    $yySetLocation = qq~$scripturl~;
    redirectexit();
    return;
}

##  check for locked post bypass status - user must be at least mod and bypass lock must be set right.
sub checkUserLockBypass {
    if (
        $staff
        && (
               ( $bypass_lock_perm eq 'fa' && $iamadmin )
            || ( $bypass_lock_perm eq 'gmod' && ( $iamadmin || $iamgmod ) )
            || ( $bypass_lock_perm eq 'fmod'
                && ( $iamadmin || $iamgmod || $iamfmod ) )
            || $bypass_lock_perm eq 'mod'
        )
      )
    {
        return 1;
    }
}

sub alertbox {
    my ($alert) = @_;
    $yymain .= qq~
<script type="text/javascript">
        alert("$alert");
</script>~;
    return;
}

## load buddy list for user, new version from sub isUserBuddy
sub loadMyBuddy {
    %mybuddie = ();
    if ( ${ $uid . $username }{'buddylist'} ) {
        my @buddies = split /\|/xsm, ${ $uid . $username }{'buddylist'};
        chomp @buddies;
        foreach my $buddy (@buddies) {
            $buddy =~ s/^ //sm;
            $mybuddie{$buddy} = 1;
        }
    }
    return;
}

## add user to buddy list
## this is only for the
sub addBuddy {
    my $newBuddy;
    if ( $INFO{'name'} ) {
        if   ($do_scramble_id) { $newBuddy = decloak( $INFO{'name'} ); }
        else                   { $newBuddy = $INFO{'name'}; }
        chomp $newBuddy;
        if ( $newBuddy eq $username ) { fatal_error('self_buddy'); }
        ToHTML($newBuddy);
        if ( !${ $uid . $username }{'buddylist'} ) {
            ${ $uid . $username }{'buddylist'} = "$newBuddy";
        }
        else {
            my @currentBuddies =
              split /\|/xsm, ${ $uid . $username }{'buddylist'};
            push @currentBuddies, $newBuddy;
            @currentBuddies = sort @currentBuddies;
            @newBuddies     = undupe(@currentBuddies);
            $newBuddyList   = join q{|}, @newBuddies;
            ${ $uid . $username }{'buddylist'} = $newBuddyList;
        }
        UserAccount( $username, 'update' );
    }
    $yySetLocation =
      qq~$scripturl?num=$INFO{'num'}/$INFO{'vpost'}#$INFO{'vpost'}~;
    if ( $INFO{'vpost'} eq q{} ) {
        $yySetLocation =
          qq~$scripturl?action=viewprofile;username=$INFO{'name'}~;
    }
    redirectexit();
    return;
}

## check to see if user can view a broadcast message based on group
sub BroadMessageView {
    my ($imp) = @_;
    if ($iamadmin) { return 1; }
    if ($imp) {
        foreach my $checkgroup ( split /\,/xsm, $imp ) {
            if ( $checkgroup eq 'all' ) { return 1; }
            if (
                (
                       $checkgroup eq 'gmods'
                    || $checkgroup eq 'fmods'
                    || $checkgroup eq 'mods'
                )
                && $iamgmod
              )
            {
                return 1;
            }
            if ( ( $checkgroup eq 'fmods' || $checkgroup eq 'mods' )
                && $iamfmod )
            {
                return 1;
            }
            if ( $checkgroup eq 'mods' && $iammod ) { return 1; }
            if ( $checkgroup eq ${ $uid . $username }{'position'} ) {
                return 1;
            }
            foreach ( split /,/xsm, ${ $uid . $username }{'addgroups'} ) {
                if ( $checkgroup eq $_ ) { return 1; }
            }
        }
    }
    return 0;
}

sub CheckUserPM_Level {
    my ($checkuser) = @_;
    return if $PM_level <= 1 || $UserPM_Level{$checkuser};
    $UserPM_Level{$checkuser} = 1;
    if ( !${ $uid . $checkuser }{'password'} ) { LoadUser($checkuser); }
    if ( ${ $uid . $checkuser }{'position'} eq 'Mid Moderator' ) {
        $UserPM_Level{$checkuser} = 4;
    }
    elsif (${ $uid . $checkuser }{'position'} eq 'Administrator'
        || ${ $uid . $checkuser }{'position'} eq 'Global Moderator' )
    {
        $UserPM_Level{$checkuser} = 3;
    }
    else {
      USERCHECK: foreach my $catid (@categoryorder) {
            foreach my $checkboard ( split /,/xsm, $cat{$catid} ) {
                foreach
                  my $curuser ( split /, ?/sm, ${ $uid . $checkboard }{'mods'} )
                {
                    if ( $checkuser eq $curuser ) {
                        $UserPM_Level{$checkuser} = 2;
                        last USERCHECK;
                    }
                }
                foreach my $curgroup ( split /, /sm,
                    ${ $uid . $checkboard }{'modgroups'} )
                {
                    if ( ${ $uid . $checkuser }{'position'} eq $curgroup ) {
                        $UserPM_Level{$checkuser} = 2;
                        last USERCHECK;
                    }
                    foreach ( split /,/xsm,
                        ${ $uid . $checkuser }{'addgroups'} )
                    {
                        if ( $_ eq $curgroup ) {
                            $UserPM_Level{$checkuser} = 2;
                            last USERCHECK;
                        }
                    }
                }
            }
        }
    }
    return;
}

sub get_forum_master {
    if ( $mloaded != 1 ) {
        require "$boardsdir/forum.master";
    }
    return;
}

sub get_micon {
    if ( -e ("$templatesdir/$usestyle/Micon.def") ) {
        $Micon_def = qq~$templatesdir/$usestyle/Micon.def~;
    }
    else { $Micon_def = qq~$templatesdir/default/Micon.def~; }
    require "$Micon_def";
    return;
}

sub get_template {
    my ($templt) = @_;
    my @templ_list = ( $useboard, $usemessage, $usedisplay, $usemycenter );
    my @ld_list    = qw(BoardIndex MessageIndex Display MyCenter);
    my $ld_cn      = 0;
    for my $x ( 0 .. ( @ld_list - 1 ) ) {
        if ( $templt eq $ld_list[$x] ) {
            require qq~$templatesdir/$templ_list[$x]/$ld_list[$x].template~;
            $ld_cn = 1;
        }
    }
    if ( $ld_cn == 0 ) {
        if ( -e ("$templatesdir/$usestyle/$templt.template") ) {
            require "$templatesdir/$usestyle/$templt.template";
        }
        else {
            require "$templatesdir/default/$templt.template";
        }
    }
    return;
}

sub get_gmod {
    if ( $iamgmod && -e "$vardir/gmodsettings.txt" ) {
        require "$vardir/gmodsettings.txt";
    }
    return;
}

sub enable_yabbc {
    if ( $yyYaBBCloaded != 1 ) {
        require Sources::YaBBC;
    }
    return;
}
## moved from YaBBC.pm and Printpage.pl DAR 2/7/2012 ##
sub format_url {
    my ( $txtfirst, $txturl ) = @_;
    my $lasttxt = q{};
    if ( $txturl =~
m{(.*?)(\.|\.\)|\)\.|\!|\!\)|\)\!|\,|\)\,|\)|\;|\&quot\;|\&quot\;\.|\.\&quot\;|\&quot\;\,|\,\&quot\;|\&quot\;\;|\<\/)\Z}sm
      )
    {
        $txturl  = $1;
        $lasttxt = $2;
    }
    my $realurl = $txturl;
    $txturl =~ s/(\[highlight\]|\[\/highlight\]|\[edit\]|\[\/edit\])//igsm;
    $txturl =~ s/\[/&#91;/gsm;
    $txturl =~ s/\]/&#93;/gsm;
    $txturl =~ s/\<.+?\>//igsm;
    my $formaturl = qq~$txtfirst\[url\=$txturl\]$realurl\[\/url\]$lasttxt~;
    return $formaturl;
}

sub format_url2 {
    my ( $txturl, $txtlink ) = @_;
    $txturl =~ s/(\[highlight\]|\[\/highlight\]|\[edit\]|\[\/edit\])//igsm;
    $txturl =~ s/\<.+?\>//igsm;
    my $formaturl = qq~[url=$txturl]$txtlink\[/url]~;
    return $formaturl;
}

sub format_url3 {
    my ($txturl) = @_;
    my $txtlink = $txturl;
    $txturl =~ s/(\[highlight\]|\[\/highlight\]|\[edit\]|\[\/edit\])//igsm;
    $txturl =~ s/\[/&#91;/gsm;
    $txturl =~ s/\]/&#93;/gsm;
    $txturl =~ s/\<.+?\>//igsm;
    my $formaturl = qq~\[url\=$txturl\]$txtlink\[\/url\]~;
    return $formaturl;
}

sub sizefont {
    ## limit minimum and maximum font pitch as CSS does not restrict it at all. ##
    my ( $tsize, $ttext ) = @_;
    if    ( !$fontsizemax )         { $fontsizemax = 72; }
    if    ( !$fontsizemin )         { $fontsizemin = 6; }
    if    ( $tsize < $fontsizemin ) { $tsize       = $fontsizemin; }
    elsif ( $tsize > $fontsizemax ) { $tsize       = $fontsizemax; }
    return qq~<span style="font-size: $tsize\pt;">$ttext</span><!--size-->~;
}

sub regex_1 {
    my ($message) = @_;
    $message =~ s/[\r\n\ ]//gsm;
    $message =~ s/\&nbsp;//gxsm;
    $message =~ s/\[table\].*?\[tr\].*?\[td\]//gxsm;
    $message =~ s/\[\/td\].*?\[\/tr\].*?\[\/table\]//gxsm;
    $message =~ s/\[.*?\]//gxsm;

    return $message;
}

sub regex_2 {
    my ($message) = @_;
    $message =~ s/\cM//gsm;
    $message =~ s/\[([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[$1$2\]/gsm;
    $message =~ s/\[\/([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[\/$1$2\]/gsm;
    return $message;
}

sub regex_3 {
    my ($message) = @_;
    $message =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
    $message =~ s/\n/<br \/>/gsm;
    $message =~ s/([\000-\x09\x0b\x0c\x0e-\x1f\x7f])/\x0d/gxsm;
    return $message;
}

sub regex_4 {
    my ($message) = @_;
    $message =~ s/\[b\](.*?)\[\/b\]/*$1*/igxsm;
    $message =~ s/\[i\](.*?)\[\/i\]/\/$1\//igxsm;
    $message =~ s/\[u\](.*?)\[\/u\]/_$1_/igxsm;
    $message =~ s/\[.*?\]//gxsm;
    $message =~ s/<br.*?>/\n/igxsm;
    return $message;
}

sub password_check {
    LoadLanguage('Register');

    if ( $action eq 'myprofile' ) {
        get_template('MyProfile');
    }
    else { $class = 'windowbg2'; }
    $check_js = qq~    <script type="text/javascript">
                // Password_strength_meter start
                var verdects = new Array("$pwstrengthmeter_txt{'1'}","$pwstrengthmeter_txt{'2'}","$pwstrengthmeter_txt{'3'}","$pwstrengthmeter_txt{'4'}","$pwstrengthmeter_txt{'5'}","$pwstrengthmeter_txt{'6'}","$pwstrengthmeter_txt{'7'}","$pwstrengthmeter_txt{'8'}");
                var colors = new Array("#8F8F8F","#BF0000","#FF0000","#00A0FF","#33EE00","#339900");
                var scores = new Array($pwstrengthmeter_scores);
                var common = new Array($pwstrengthmeter_common);
                var minchar = $pwstrengthmeter_minchar;

                function runPassword(D) {
                    var nPerc = checkPassword(D);
                    if (nPerc > -199 && nPerc < 0) {
                        strColor = colors[0];
                        strText = verdects[1];
                        strWidth = "5%";
                    } else if (nPerc == -200) {
                        strColor = colors[1];
                        strText = verdects[0];
                        strWidth = "0%";
                    } else if (scores[0] == -1 && scores[1] == -1 && scores[2] == -1 && scores[3] == -1) {
                        strColor = colors[4];
                        strText = verdects[7];
                        strWidth = "100%";
                    } else if (nPerc <= scores[0]) {
                        strColor = colors[1];
                        strText = verdects[2];
                        strWidth = "10%";
                    } else if (nPerc > scores[0] && nPerc <= scores[1]) {
                        strColor = colors[2];
                        strText = verdects[3];
                        strWidth = "25%";
                    } else if (nPerc > scores[1] && nPerc <= scores[2]) {
                        strColor = colors[3];
                        strText = verdects[4];
                        strWidth = "50%";
                    } else if (nPerc > scores[2] && nPerc <= scores[3]) {
                        strColor = colors[4];
                        strText = verdects[5];
                        strWidth = "75%";
                    } else {
                        strColor = colors[5];
                        strText = verdects[6];
                        strWidth = "100%";
                    }
                    document.getElementById("passwrd1_bar").style.width = strWidth;
                    document.getElementById("passwrd1_bar").style.backgroundColor = strColor;
                    document.getElementById("passwrd1_text").style.color = strColor;
                    document.getElementById("passwrd1_text").childNodes[0].nodeValue = strText;
                }

                function checkPassword(C) {
                    if (C.length === 0 || C.length < minchar) return -100;

                    for (var D = 0; D < common.length; D++) {
                        if (C.toLowerCase() == common[D]) return -200;
                    }

                    var F = 0;
                    if (C.length >= minchar && C.length <= (minchar+2)) {
                        F = (F + 6);
                    } else if (C.length >= (minchar + 3) && C.length <= (minchar + 4)) {
                        F = (F + 12);
                    } else if (C.length >= (minchar + 5)) {
                        F = (F + 18);
                    }

                    if (C.match(/[a-z]/)) {
                        F = (F + 1);
                    }
                    if (C.match(/[A-Z]/)) {
                        F = (F + 5);
                    }
                    if (C.match(/d+/)) {
                        F = (F + 5);
                    }
                    if (C.match(/(.*[0-9].*[0-9].*[0-9])/)) {
                        F = (F + 7);
                    }
                    if (C.match(/.[!,\@,#,\$,\%,^,&,*,?,_,\~]/)) {
                        F = (F + 5);
                    }
                    if (C.match(/(.*[!,\@,#,\$,\%,^,&,*,?,_,\~].*[!,\@,#,\$,\%,^,&,*,?,_,\~])/)) {
                        F = (F + 7);
                    }
                    if (C.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/)){
                        F = (F + 2);
                    }
                    if (C.match(/([a-zA-Z])/) && C.match(/([0-9])/)) {
                        F = (F + 3);
                    }
                    if (C.match(/([a-zA-Z0-9].*[!,\@,#,\$,\%,^,&,*,?,_,\~])|([!,\@,#,\$,\%,^,&,*,?,_,\~].*[a-zA-Z0-9])/)) {
                        F = (F + 3);
                    }
                    return F;
                }
                // Password_strength_meter end
                        </script>~;
    $check = $show_check;
    $check .= $show_check_bot;
    $check =~ s/{yabb check_js}/$check_js/sm;
    $check =~ s/{yabb tmpregpasswrd1}/$tmpregpasswrd1/sm;
    $check =~ s/{yabb tmpregpasswrd2}/$tmpregpasswrd2/sm;

    return $check;
}

sub BoardPassw {
#    my ($boardname,$viewnum,$currentboard) = @_;
    #template in MessageIndex.template
    $yymain .= $boardpassw;

    $yytitle = qq~$maintxt{'900pw'}: $boardname~;
    template();
    exit;
}

sub BoardPassw_g {
    #template in MessageIndex.template
    $yymain .= $boardpassw_g;

    $yytitle = qq~$maintxt{'900pw'}: $boardname~;
    template();
    exit;
}
sub BoardPasswCheck {

    my $returnnum   = $FORM{'pswviewnum'};
    my $returnboard = $FORM{'pswcurboard'};
    my $spass       = ${ $uid . $returnboard }{'brdpassw'};
    my $cryptpass   = encode_password("$FORM{'boardpw'}");
    if ( $FORM{'boardpw'} eq q{} ) { fatal_error('', "$maintxt{'900pe'}"); }
    if ( $spass ne $cryptpass ) { fatal_error('wrong_pass'); }
    $ck{'len'} = 'Sunday, 17-Jan-2030 00:00:00 GMT';
    my $cookiename = "$cookiepassword$returnboard$username";
    push @otherCookies,
      write_cookie(
        -name    => "$cookiename",
        -value   => "$cryptpass",
        -path    => q{/},
        -expires => "$ck{'len'}"
      );
    WriteLog();
    undef $FORM{'boardpw'};

    if ( $returnnum ne q{} ) {
        $yySetLocation = qq~$scripturl?num=$returnnum~;
    }
    else {
        $yySetLocation = qq~$scripturl?board=$returnboard~;
    }
    redirectexit();
    return;
}

sub UploadFile {
    my ( $file_upload, $file_directory, $file_extensions, $file_size, $directory_limit ) = @_;
    $file_directory = qq~$htmldir/$file_directory~;

    LoadLanguage('FA');
    require Sources::SpamCheck;

    if ($CGI_query) { $file = $CGI_query->upload("$file_upload"); }
    if ($file) {
        $fixfile = $file;
        $fixfile =~ s/.+\\([^\\]+)$|.+\/([^\/]+)$/$1/xsm;
        if ( $fixfile =~ /[^0-9A-Za-z\+\-\.:_]/xsm )
       {    # replace all inappropriate characters
            # Transliteration
            my @ISO_8859_1 =
              qw(A B V G D E JO ZH Z I J K L M N O P R S T U F H C CH SH SHH _ Y _ JE JU JA a b v g d e jo zh z i j k l m n o p r s t u f h c ch sh shh _ y _ je ju ja);
            my $x = 0;
            foreach (
              qw(À Á Â Ã Ä Å ¨ Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å ¸ æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ)
            )
            {
            $fixfile =~ s/$_/$ISO_8859_1[$x]/igxsm;
            $x++;
            }

            # END Transliteration. Thanks to "Velocity" for this contribution.
            $fixfile =~ s/[^0-9A-Za-z\+\-\.:_]/_/gxsm;
        }

        # replace . with _ in the filename except for the extension
        my $fixname = $fixfile;
        if ( $fixname =~ s/(.+)(\..+?)$/$1/xsm ) {
            $fixext = $2;
        }

        $spamdetected = spamcheck("$fixname");
        if ( !$staff ) {
            if ( $spamdetected == 1 ) {
                ${ $uid . $username }{'spamcount'}++;
                ${ $uid . $username }{'spamtime'} = $date;
                UserAccount( $username, 'update' );
                $spam_hits_left_count = $post_speed_count -
                  ${ $uid . $username }{'spamcount'};
                unlink "$file_directory/$fixfile";
                fatal_error('tsc_alert');
            }
        }
        if ( $use_guardian && $string_on ) {
            @bannedstrings = split /\|/xsm, $banned_strings;
            foreach (@bannedstrings) {
                chomp $_;
                if ( $fixname =~ m/$_/ism ) {
                    fatal_error( 'attach_name_blocked', "($_)" );
                }
            }
        }

        $fixext  =~ s/\.(pl|pm|cgi|php)/._$1/ixsm;
        $fixname =~ s/\.(?!tar$)/_/gxsm;
        $fixfile = qq~$fixname$fixext~;
        if ( $fixfile eq 'index.html' || $fixfile eq '.htaccess' ) { fatal_error('attach_file_blocked') };

        $fixfile = check_existence( $file_directory, $fixfile );

        my $match = 0;
        foreach my $ext ( split / /, $file_extensions ) {
            if ( grep { /$ext$/ixsm } $fixfile ) {
                $match = 1;
                last;
            }
        }

        if (!$match) {
            unlink "$file_directory/$fixfile";
            fatal_error( q{}, "$fixfile $fatxt{'20'} $file_extensions" );
        }

        my ( $size, $buffer, $filesize, $file_buffer );
        while ( $size = read $file, $buffer, 512 ) {
            $filesize += $size;
            $file_buffer .= $buffer;
        }
        if ( $file_size && $filesize > ( 1024 * $file_size ) ) {
            unlink "$file_directory/$fixfile";
            fatal_error( q{},
                    "$fatxt{'21'} $fixfile ("
                  . int( $filesize / 1024 )
                  . " KB) $fatxt{'21b'} "
                  . $file_size );
        }
        if ($directory_limit) {
            my $dirsize = dirsize($file_directory);
            if ( $file_size > ( ( 1024 * $directory_limit ) - $dirsize ) ) {
                unlink "$file_directory/$fixfile";
                fatal_error(
                    q{},
                    "$fatxt{'22'} $fixfile ("
                      . (
                        int( $file_size / 1024 ) -
                          $directory_limit +
                          int( $dirsize / 1024 )
                       )
                       . " KB) $fatxt{'22b'}"
                );
            }
        }

        # create a new file on the server using the formatted ( new instance ) filename
        if ( fopen( NEWFILE, ">$file_directory/$fixfile" ) ) {
            binmode NEWFILE;

            # needed for operating systems (OS) Windows, ignored by Linux
            print {NEWFILE} $file_buffer
              or croak "$croak{'print'} NEWFILE"; # write new file on HD
            fclose(NEWFILE);
        }
        else
        { # return the server's error message if the new file could not be created
                unlink "$file_directory/$fixfile";
                fatal_error( 'file_not_open', "$file_directory" );
        }

        # check if file has actually been uploaded, by checking the file has a size
        $filesizekb{$fixfile} = -s "$file_directory/$fixfile";
        if ( !$filesizekb{$fixfile} ) {
            unlink "$file_directory/$fixfile";
            fatal_error( 'file_not_uploaded', $fixfile );
        }
        $filesizekb{$fixfile} = int( $filesizekb{$fixfile} / 1024 );

        if ( $fixfile =~ /\.(jpg|gif|png|jpeg)$/ism ) {
            my $okatt = 1;
            if ( $fixfile =~ /gif$/ism ) {
                my $header;
                fopen( ATTFILE, "$file_directory/$fixfile" );
                read ATTFILE, $header, 10;
                my $giftest;
                ( $giftest, undef, undef, undef, undef, undef ) =
                  unpack 'a3a3C4', $header;
                fclose(ATTFILE);
                if ( $giftest ne 'GIF' ) { $okatt = 0; }
            }
            fopen( ATTFILE, "$file_directory/$fixfile" );
            while ( read ATTFILE, $buffer, 1024 ) {
                if ( $buffer =~ /<(html|script|body)/igxsm ) {
                    $okatt = 0;
                    last;
                }
            }
            fclose(ATTFILE);
            if ( !$okatt )
            {    # delete the file as it contains illegal code
                unlink "$file_directory/$fixfile";
                fatal_error( 'file_not_uploaded', "$fixfile $fatxt{'20a'}" );
             }
        }

    }
    return ($fixfile);
}

sub isempty {
    my ($x, $y) = @_;
    if ( defined $x && $x ne q{} ) {
        $y = $x;
    }
    return $y;
}

1;
