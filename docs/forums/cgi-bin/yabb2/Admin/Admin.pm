###############################################################################
# Admin.pm                                                                    #
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
use CGI qw(:standard);
use English qw(-no_match_vars);
use Time::Local;
our $VERSION = '2.6.11';

$adminpmver = 'YaBB 2.6.11 $Revision: 1611 $';
LoadLanguage('Credits');

get_template('AdminCentre');

sub Admin {
    is_admin_or_gmod();

    $my_lastlogin = GetLastLogins();

    $yymain .= $front_page;
    $yymain =~ s/{yabb iFrameSupport}/$iFrameSupport/sm;
    $yymain =~ s/{yabb YaBBversion}/$YaBBversion/gsm;
    $yymain =~ s/{yabb lastlogins}/$my_lastlogin/sm;

    if ( -d './Convert' ) {
        $yymain .= $convert_box;
    }

    $yymain .= $last_div;

    require Admin::ModuleChecker;

    $yytitle = "$admin_txt{'208'}";
    AdminTemplate();
    return;
}

sub DeleteConverterFiles {
    my @convertdir = qw~Boards Members Messages Variables~;

    foreach my $cnvdir (@convertdir) {
        $convdir = "./Convert/$cnvdir";
        if ( -d "$convdir" ) {
            opendir 'CNVDIR', $convdir
              || fatal_error( 'cannot_open_dir', "$convdir" );
            @convlist = readdir 'CNVDIR';
            closedir 'CNVDIR';
            foreach my $file (@convlist) {
                unlink "$convdir/$file"
                  || fatal_error( 'cannot_open_dir', "$convdir/$file" );
            }
            rmdir "$convdir";
        }
    }
    $convdir = './Convert';
    if ( -d "$convdir" ) {
        opendir 'CNVDIR', $convdir
          || fatal_error( 'cannot_open_dir', "$convdir" );
        @convlist = readdir 'CNVDIR';
        closedir 'CNVDIR';
        foreach my $file (@convlist) {
            unlink "$convdir/$file";
        }
        rmdir "$convdir";
    }
    if ( -e './Setup.pl' )        { unlink './Setup.pl'; }
    if ( -e './Convert.pl' )      { unlink './Convert.pl'; }
    if ( -e './Convert2x.pl' )    { unlink './Convert2x.pl'; }
    if ( -e './BoardConvert.pl' ) { unlink './BoardConvert.pl'; }
    if ( -e "$htmldir/Templates/Forum/setup.css" ) {
        unlink "$htmldir/Templates/Forum/setup.css";
    }
    if ( -e './Variables/ConvSettings.txt' ) {
        unlink './Variables/ConvSettings.txt';
    }

    $yymain .= qq~<b>$admintxt{'10'}</b>~;
    $yytitle = "$admintxt{'10'}";
    AdminTemplate();
    return;
}

sub GetLastLogins {
    fopen( ADMINLOG, "$vardir/adminlog_new.txt" );
    @adminlog = <ADMINLOG>;
    fclose(ADMINLOG);
    @adminlog = reverse sort @adminlog;

    foreach my $line (@adminlog) {
        chomp $line;
        @element = split /\|/xsm, $line;
        if ( !${ $uid . $element[1] }{'realname'} ) {
            LoadUser( $element[1] );
        }    # If user is not in memory, s/he must be loaded.
        $element[0] = timeformat( $element[0] );
        my $lookupIP =
          ($ipLookup)
          ? qq~<a href="$scripturl?action=iplookup;ip=$element[2]">$element[2]</a>~
          : qq~$element[1]~;
        $loginadmin .= qq~
                <a href="$scripturl?action=viewprofile;username=$useraccount{$element[1]}">${$uid.$element[1]}{'realname'}</a> <span class="small">($lookupIP) - $element[0]</span><br />
                ~;
    }
    return $loginadmin;
}

sub FullStats {
    is_admin_or_gmod();
    my ( $numcats, $numboards, $maxdays, $totalt, $totalm, $avgm );
    my ( $memcount, $latestmember ) = MembershipGet();
    LoadUser($latestmember);
    $thelatestmember =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$latestmember}">${$uid.$latestmember}{'realname'}</a>~;
    $memcount ||= 1;

    $numcats = 0;

    get_forum_master();
    foreach my $catid (@categoryorder) {
        $boardlist = $cat{$catid};
        $numcats++;
        @bdlist = split /\,/xsm, $boardlist;
        my ( $catname, $catperms, $catallowcol ) =
          split /\|/xsm, $catinfo{$catid};

        foreach my $curboard (@bdlist) {
            chomp $curboard;
            $numboards++;
            push @loadboards, $curboard;
        }
    }

    BoardTotals( 'load', @loadboards );
    foreach my $curboard (@loadboards) {
        $totalm += ${ $uid . $curboard }{'messagecount'};
        $totalt += ${ $uid . $curboard }{'threadcount'};
    }

    $avgm = int( $totalm / $memcount );
    LoadAdmins();

    if ($enableclicklog) {
        my (@log);
        fopen( LOG, "$vardir/clicklog.txt" );
        @log = <LOG>;
        fclose(LOG);
        $yyclicks    = @log;
        $yyclicks    = NumberFormat($yyclicks);
        $yyclicktext = $admin_txt{'692'};
        $yyclicklink =
qq~&nbsp;(<a href="$adminurl?action=showclicks">$admin_txt{'693'}</a>)~;
    }
    else {
        $yyclicktext = $admin_txt{'692a'};
        $yyclicklink = q{};
    }
    my (@elog);
    fopen( ELOG, "$vardir/errorlog.txt" );
    @elog = <ELOG>;
    fclose(ELOG);
    $errorslog = @elog;
    $memcount  = NumberFormat($memcount);
    $totalt    = NumberFormat($totalt);
    $totalm    = NumberFormat($totalm);
    $avgm      = NumberFormat($avgm);
    $errorslog = NumberFormat($errorslog);

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'infoimg'} <b>$admintxt{'28'}</b>
            </td>
        </tr><tr>
            <td class="catbg">
                <i>$admin_txt{'94'}</i>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                    <div class="admin-total-left">$admin_txt{'488'}</div>
                    <div class="admin-total-right">$memcount</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'490'}</div>
                    <div class="admin-total-right">$totalt</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'489'}</div>
                    <div class="admin-total-right">$totalm</div>
                    <br />
                    <div class="admin-total-left">$admintxt{'39'}</div>
                    <div class="admin-total-right">$avgm</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'658'}</div>
                    <div class="admin-total-right">$numcats</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'665'}</div>
                    <div class="admin-total-right">$numboards</div>
                    <br />
                    <div class="admin-total-left">$errorlog{'3'}</div>
                    <div class="admin-total-right">$errorslog</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'691'}&nbsp;<span class="small">($yyclicktext)</span></div>
                    <div class="admin-total-right">$yyclicks</div>
                    <div class="admin-total-left" style="width:55%">$yyclicklink</div>
                </div>
            </td>
        </tr><tr>
            <td class="catbg">
                <i>$admin_txt{'657'}</i>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                    <div class="admin-total-left">$admin_txt{'656'}</div>
                    <div class="admin-total-mid">$thelatestmember</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'659'}</div>
                    <div class="admin-total-mid">~;

# Sorts the threads to find the most recent post
# No need to check for board access here because only admins have access to this page
    get_forum_master();
    foreach my $catid (@categoryorder) {
        $boardlist = $cat{$catid};
        @bdlist = split /\,/xsm, $boardlist;
        foreach my $curboard (@bdlist) {
            push @goodboards, $curboard;
        }
    }

    BoardTotals( 'load', @goodboards );

    # &getlog; not used here !!?
    foreach my $curboard (@goodboards) {
        chomp $curboard;
        $lastposttime = ${ $uid . $curboard }{'lastposttime'};
        if ( $lastposttime =~ /^[0-9]+$/sm ) {
            $lastposttime{$curboard} =
                timeformat( $lastposttime );
        }
        ${ $uid . $curboard }{'lastposttime'} =
          ${ $uid . $curboard }{'lastposttime'} eq 'N/A'
          || !${ $uid . $curboard }{'lastposttime'}
          ? $boardindex_txt{'470'}
          : ${ $uid . $curboard }{'lastposttime'};
        $lastpostrealtime{$curboard} =
          ${ $uid . $curboard }{'lastposttime'} eq 'N/A'
          || !${ $uid . $curboard }{'lastposttime'}
          ? q{}
          : ${ $uid . $curboard }{'lastposttime'};
        if ( ${ $uid . $curboard }{'lastposter'} =~ m{\AGuest-(.*)}xsm ) {
            ${ $uid . $curboard }{'lastposter'} = $1;
            $lastposterguest{$curboard} = 1;
        }
        ${ $uid . $curboard }{'lastposter'} =
          ${ $uid . $curboard }{'lastposter'} eq 'N/A'
          || !${ $uid . $curboard }{'lastposter'}
          ? $boardindex_txt{'470'}
          : ${ $uid . $curboard }{'lastposter'};
        ${ $uid . $curboard }{'messagecount'} =
          ${ $uid . $curboard }{'messagecount'} || 0;
        ${ $uid . $curboard }{'threadcount'} =
          ${ $uid . $curboard }{'threadcount'} || 0;
        $totalm += ${ $uid . $curboard }{'messagecount'};
        $totalt += ${ $uid . $curboard }{'threadcount'};

        # determine the true last post on all the boards a user has access to
        if ( $lastposttime > $lastthreadtime ) {
            $lsdatetime     = timeformat($lastposttime);
            $lsposter       = ${ $uid . $curboard }{'lastposter'};
            $lssub          = ${ $uid . $curboard }{'lastsubject'};
            $lspostid       = ${ $uid . $curboard }{'lastpostid'};
            $lsreply        = ${ $uid . $curboard }{'lastreply'};
            $lastthreadtime = $lastposttime;
        }
    }
    ( $lssub, undef ) = Split_Splice_Move( $lssub, 0 );
    ToChars($lssub);
    $yymain .=
qq~<a href="$scripturl?num=$lspostid/$lsreply#$lsreply">$lssub</a> ($lsdatetime)</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'684'}</div>
                    <div class="admin-total-mid">$administrators</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'684a'}</div>
                    <div class="admin-total-mid">$gmods</div>
                    <br />
                    <div class="admin-total-left">$admin_txt{'425'}</div>
                    <div class="admin-total-mid">
                        <script src="$versionchk" type="text/javascript"></script>
                        <script type="text/javascript">
                            if (typeof STABLE === "undefined" || STABLE === null ) {
                                document.write("$versiontxt{'4'} <b>$YaBBversion</b> - $versiontxt{'5'} <b>$rna</b> <p>");
                            } else {
                                document.write("$versiontxt{'4'} <b>$YaBBversion</b> - $versiontxt{'5'} <b>"+STABLE+"</b> <p>");
                            }
                        </script>
                    </div>
                </div>
            </td>
        </tr>
    </table>
</div>~;

    $yytitle     = $admintxt{'28'};
    $action_area = 'stats';
    AdminTemplate();
    return;
}

sub LoadAdmins {
    is_admin_or_gmod();
    my ($curentry);
    $administrators = q{};
    $gmods          = q{};
    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        ( $memberrealname, undef, $memposition, $memposts ) =
          split /\|/xsm, $value;
        if   ($do_scramble_id) { $membernameCloaked = cloak($membername); }
        else                   { $membernameCloaked = $membername; }
        if ( $memposition eq 'Administrator' ) {
            $administrators .=
qq~ <a href="$scripturl?action=viewprofile;username=$membernameCloaked">$memberrealname</a><span class="small">,</span> \n~;
        }
        if ( $memposition eq 'Global Moderator' ) {
            $gmods .=
qq~ <a href="$scripturl?action=viewprofile;username=$membernameCloaked">$memberrealname</a><span class="small">,</span> \n~;
        }
    }
    $administrators =~ s/<span class="small">,<\/span> \n\Z//sm;
    $gmods =~ s/<span class="small">,<\/span> \n\Z//sm;
    if ( $gmods eq q{} ) { $gmods = q~&nbsp;~; }
    undef %memberinf;
    return;
}

sub ShowClickLog {
    is_admin_or_gmod();

    if   ($enableclicklog) { $logtimetext = $admin_txt{'698'}; }
    else                   { $logtimetext = $admin_txt{'698a'}; }

    fopen( LOG, "$vardir/clicklog.txt" );
    @log = <LOG>;
    fclose(LOG);

    $i = 0;
    foreach my $curentry (@log) {
        ( $iplist[$i], $date, $to[$i], $from[$i], $info[$i] ) =
          split /\|/xsm, $curentry;
        $i++;
    }
    $i = 0;
    foreach my $curentry (@info) {
        if ( $curentry !~ /\s\(Win/ism || $curentry !~ /\s\(mac/sm ) {
            $curentry =~ s/\s\((compatible;\s)*/ - /igsm;
        }
        else { $curentry =~ s/(\S)*\(/; /gsm; }
        if ( $curentry =~ /\s-\sWin/ism ) {
            $curentry =~ s/\s-\sWin/; win/igsm;
        }
        if ( $curentry =~ /\s-\sMac/ism ) {
            $curentry =~ s/\s-\sMac/; mac/igsm;
        }
        ( $browser[$i], $os[$i] ) = split /\;\s/xsm, $curentry;
        if ( $os[$i] =~ /\)\s\S/sm ) {
            ( $os[$i], $browser[$i] ) = split /\)\s/xsm, $os[$i];
        }
        $os[$i] =~ s/\)//gxsm;
        $i++;
    }

    for my $i ( 0 .. ( @iplist - 1 ) ) { $iplist{ $iplist[$i] }++; }
    $i = 0;
    while ( ( $key, $val ) = each %iplist ) {
        $newiplist[$i] = [ $key, $val ];
        $i++;
    }
    $totalclick = @iplist;
    $totalip    = @newiplist;
    for my $i ( 0 .. ( @newiplist - 1 ) ) {
        my $lookupIP =
          ($ipLookup)
          ? qq~<a href="$scripturl?action=iplookup;ip=$newiplist[$i]->[0]">$newiplist[$i]->[0]</a>~
          : qq~$newiplist[$i]->[0]~;
        if (   $newiplist[$i]->[0] =~ /\S+/sm
            && $newiplist[$i]->[0] =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/sm )
        {
            $guestiplist .=
qq~$lookupIP&nbsp;<span class="important">(<i>$newiplist[$i]->[1]</i>)</span><br />~;
        }
        else {
            LoadUser( $newiplist[$i]->[0] );
            if ($do_scramble_id) {
                $cloakedUserName = cloak( $newiplist[$i]->[0] );
            }
            else { $cloakedUserName = $newiplist[$i]->[0]; }
            my $displayUserName = $newiplist[$i]->[0];
            if (
                ${ $uid . $displayUserName }{'realname'}
                && ( ${ $uid . $displayUserName }{'realname'} ne
                    $newiplist[$i]->[0] )
              )
            {
                $displayUserName = ${ $uid . $displayUserName }{'realname'};
            }
            $useriplist .=
qq~<a href="$scripturl?action=viewprofile;username=$cloakedUserName">$displayUserName</a>&nbsp;<span class="important">(<i>$newiplist[$i]->[1]</i>)</span><br />~;
        }
    }

    for my $i ( 0 .. ( @browser - 1 ) ) { $browser{ $browser[$i] }++; }
    $i = 0;
    while ( ( $key, $val ) = each %browser ) {
        $newbrowser[$i] = [ $key, $val ];
        $i++;
    }
    $totalbrow = @newbrowser;
    for my $i ( 0 .. ( @newbrowser .. 1 ) ) {
        if ( $newbrowser[$i]->[0] =~ /\S+/xsm ) {
            $browserlist .=
qq~$newbrowser[$i]->[0] &nbsp;<span class="important">(<i>$newbrowser[$i]->[1]</i>)</span><br />~;
        }
    }

    for my $i ( 0 .. ( @os - 1 ) ) { $os{ $os[$i] }++; }
    $i = 0;
    while ( ( $key, $val ) = each %os ) {
        $newoslist[$i] = [ $key, $val ];
        $i++;
    }
    $totalos = @newoslist;
    for my $i ( 0 .. ( @newoslist - 1 ) ) {
        if ( $newoslist[$i]->[0] =~ /\S+/xsm ) {
            $oslist .=
qq~$newoslist[$i]->[0] &nbsp;<span class="important">(<i>$newoslist[$i]->[1]</i>)</span><br />~;
        }
    }

    for my $i ( 0 .. ( @to - 1 ) ) { $to{ $to[$i] }++; }
    $i = 0;
    while ( ( $key, $val ) = each %to ) {
        $newtolist[$i] = [ $key, $val ];
        $i++;
    }
    for my $i ( 0 .. ( @newtolist - 1 ) ) {
        if ( $newtolist[$i]->[0] =~ /\S+/xsm ) {
            $scriptcalls .=
qq~<a href="$newtolist[$i]->[0]" target="_blank">$newtolist[$i]->[0]</a>&nbsp;<span class="important">(<i>$newtolist[$i]->[1]</i>)</span><br />~;
        }
    }

    for my $i ( 0 .. ( @from - 1 ) ) { $from{ $from[$i] }++; }
    $i = 0;
    while ( ( $key, $val ) = each %from ) {
        $newfromlist[$i] = [ $key, $val ];
        $i++;
    }
    for my $i ( 0 .. ( @newfromlist - 1 ) ) {
        if (   $newfromlist[$i]->[0] =~ /\S+/xsm
            && $newfromlist[$i]->[0] !~ m{$boardurl}ism )
        {
            $message =
qq~<a href="$newfromlist[$i]->[0]" target="_blank">$newfromlist[$i]->[0]</a>~;

            wrap2();
            $referlist .=
qq~$message&nbsp;<span class="important">(<i>$newfromlist[$i]->[1]</i>)</span><br />~;
        }
    }

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'infoimg'} <b>$admin_txt{'693'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$admin_txt{'697'}$logtimetext</div>
            </td>
        </tr>
    </table>
 </div>~;

    if ($enableclicklog) {
        $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <colgroup>
            <col span="2" style="width: 50%" />
        </colgroup>
        <tr>
            <td class="titlebg" colspan="2">
                $admin_img{'cat_img'} <b>$admin_txt{'694'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2" colspan="2"><br />
                $admin_txt{'691'}: $totalclick<br />
                $admin_txt{'743'}: $totalip<br /><br />
            </td>
        </tr><tr>
            <td class="catbg center">
                <b>$clicklog_txt{'users'}</b>
            </td>
            <td class="catbg center">
                <b>$clicklog_txt{'guests'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2 vtop"><br />
                $useriplist<br />
            </td>
            <td class="windowbg2 vtop"><br />
                $guestiplist<br />
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'cat_img'} <b>$admin_txt{'695'}</b>
            </td>
        </tr><tr>
            <td class="catbg">
                <i>$admin_txt{'744'}: $totalbrow</i>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$browserlist</div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'cat_img'} <b>$admin_txt{'696'}</b>
            </td>
        </tr><tr>
            <td class="catbg">
                <i>$admin_txt{'745'}: $totalos</i>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$oslist</div>
           </td>
       </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'cat_img'} <b>$admin_txt{'696a'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$scriptcalls</div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'cat_img'} <b>$admin_txt{'838'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$referlist</div>
            </td>
        </tr>
    </table>
</div>
~;
    }

    $yytitle     = $admin_txt{'693'};
    $action_area = 'showclicks';
    AdminTemplate();
    return;
}

sub DeleteOldMessages {
    is_admin_or_gmod();

    fopen( DELETEOLDMESSAGE, "$vardir/oldestmes.txt" );
    $maxdays = <DELETEOLDMESSAGE>;
    fclose(DELETEOLDMESSAGE);

    $yytitle = "$aduptxt{'04'}";
    $yymain .= qq~
<form action="$adminurl?action=removeoldthreads" method="post">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'banimg'} <b>$aduptxt{'04'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$aduptxt{'05'}</div>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">
                    <label for="keep_them">$admin_txt{'4'}</label> <input type="checkbox" name="keep_them" id="keep_them" value="1" /><br />
                    <label for="maxdays">$admin_txt{'124'} <input type="text" name="maxdays" id="maxdays" size="4" value="$maxdays" /> $admin_txt{'579'} $admin_txt{'2'}:</label>
                    <div style="margin-left: 25px; margin-right: auto; text-align: left;">~;

    get_forum_master();

    foreach my $catid (@categoryorder) {
        $boardlist = $cat{$catid};
        @bdlist = split /\,/xsm, $boardlist;
        ( $catname, $catperms ) = split /\|/xsm, $catinfo{"$catid"};

        foreach my $curboard (@bdlist) {
            ( $boardname, $boardperms, $boardview ) =
              split /\|/xsm, $board{"$curboard"};
            if ( $boardname !~ m/[ht|f]tp[s]{0,1}:\/\//sm ) {
                $selectname = $curboard . 'check';
                $yymain .= qq~
                    <input type="checkbox" name="$selectname" id="$selectname" value="1" />&nbsp;<label for="$selectname">$boardname</label><br />~;
                if ( $subboard{$curboard} ) {
                    my @childboards = split /\|/xsm, $subboard{$curboard};
                    foreach my $childbd (@childboards) {
                        my ( $chldboardname, $chldboardperms, $chldboardview )
                          = split /\|/xsm, $board{$childbd};
                        if ( $chldboardname !~ m/[ht|f]tp[s]{0,1}:\/\//sm ) {
                            $selectname = $childbd . 'check';
                            $yymain .= qq~
                        &nbsp; &nbsp; &nbsp; &nbsp;<input type="checkbox" name="$selectname" id="$selectname" value="1" />&nbsp;<label for="$selectname">$chldboardname</label><br />~;
                        }
                    }
                }
            }
        }
    }
    $yymain .= qq~
                    </div>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'31'}</th>
    </tr><tr>
        <td class="catbg center">
             <input type="submit" value="$admin_txt{'31'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>~;

    $action_area = 'deleteoldthreads';
    AdminTemplate();
    return;
}

sub DeleteMultiMembers {
    is_admin_or_gmod();

    automaintenance('on');

    my ( $count, $currentmem, @userslist );
    chomp $FORM{'button'};
    chomp $FORM{'emailsubject'};
    chomp $FORM{'emailtext'};
    $tmpemailsubject = $FORM{'emailsubject'};
    $tmpemailtext    = $FORM{'emailtext'};
    if ( $FORM{'button'} != 1 && $FORM{'button'} != 2 ) {
        fatal_error('no_access');
    }

    if ( $FORM{'del_mail'} || $FORM{'emailtext'} ne q{} ) {
        require Sources::Mailer;
    }

    fopen( FILE, "$memberdir/memberlist.txt" );
    @memnum = <FILE>;
    fclose(FILE);
    $count = 0;

    if ( $FORM{'button'} == 1 && $FORM{'emailtext'} ne q{} ) {
        $FORM{'emailsubject'} =~ s/\|/&#124/gsm;
        $FORM{'emailtext'} =~ s/\|/&#124/gsm;
        $FORM{'emailtext'} =~ s/\r(?=\n*)//gxsm;
        $mailline =
          qq~$date|$FORM{'emailsubject'}|$FORM{'emailtext'}|$username~;
        MailList($mailline);
    }

    my $templanguage = $language;

    while ( @memnum >= $count ) {
        $currentmem = $FORM{"member$count"};
        if ( exists $FORM{"member$count"} ) {
            if ( -e "$memberdir/$currentmem.vars" ) {    # Bypass dead entries.
                LoadUser($currentmem);
                if ( $FORM{'emailtext'} ne q{} ) {
                    $emailsubject = $FORM{'emailsubject'};
                    $emailtext    = $FORM{'emailtext'};
                    $emailsubject =~
                      s/\[name\]/${$uid.$currentmem}{'realname'}/igsm;
                    $emailsubject =~ s/\[username\]/$currentmem/igsm;
                    $emailtext =~
                      s/\[name\]/${$uid.$currentmem}{'realname'}/igsm;
                    $emailtext =~ s/\[username\]/$currentmem/igsm;
                    sendmail( ${ $uid . $currentmem }{'email'},
                        $emailsubject, $emailtext );
                }
                elsif ( $FORM{'del_mail'} ) {
                    $language = ${ $uid . $currentmem }{'language'};
                    LoadLanguage('Email');
                    my $message = template_email(
                        $deleteduseremail,
                        {
                            'displayname' => ${ $uid . $currentmem }{'realname'}
                        }
                    );
                    sendmail(
                        ${ $uid . $currentmem }{'email'},
                        "$deletedusersybject $mbname",
                        $message, q{}, $emailcharset
                    );
                }
                if ( $currentmem ne $username ) {
                    undef %{ $uid . $currentmem };
                }
            }
            if ( $FORM{'button'} == 2 ) {
                unlink "$memberdir/$currentmem.dat";
                unlink "$memberdir/$currentmem.vars";
                unlink "$memberdir/$currentmem.ims";
                unlink "$memberdir/$currentmem.msg";
                unlink "$memberdir/$currentmem.log";
                unlink "$memberdir/$currentmem.rlog";
                unlink "$memberdir/$currentmem.outbox";
                unlink "$memberdir/$currentmem.imstore";
                unlink "$memberdir/$currentmem.imdraft";

                # save name up
                push @userslist, $currentmem;

                # For security, remove username from mod position
                KillModerator($currentmem);
            }
        }
        $count++;
    }
    if (@userslist) { MemberIndex( 'remove', join q{,}, @userslist ); }

    automaintenance('off');

    $language = $templanguage;
    if ( $FORM{'button'} == 1 ) {
        $yySetLocation = qq~$adminurl?action=mailing;sort=$INFO{'sort'}~;
    }
    else {
        $yySetLocation =
qq~$adminurl?action=viewmembers;start=$INFO{'start'};sort=$INFO{'sort'};reversed=$INFO{'reversed'}~;
    }
    redirectexit();
    return;
}

sub ver_detail {
    is_admin_or_gmod();
    if ($maintenance) {
        $yyadmin_alert .=
qq~<br /><span style="font-size: 12px; background-color: #FFFF33;"><b>$load_txt{'616a'}</b></span><br /><br />~;
    }
    if ( $iamadmin && $rememberbackup ) {
        if ( $lastbackup && $date > $rememberbackup + $lastbackup ) {
            require Sources::DateTime;
            $yyadmin_alert .=
qq~<br /><span style="font-size: 12px; background-color: #FFFF33;"><b>$load_txt{'617'} ~
              . timeformat($lastbackup)
              . q~</b></span>~;
        }
    }

    require "$boarddir/$yyexec.$yyext";
    $adminindexplver =~ s/\$Revision\: (.*?) \$/Build $1/igsm;
    $yabbplver =~ s/\$Revision\: (.*?) \$/Build $1/igsm;

    $yymain .= qq~
        <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <colgroup>
                <col span="2" style="width: 50%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="2">$admin_img{'infoimg'} <b>$admin_txt{'429'}</b></td>
            </tr><tr>
                <td class="windowbg2" colspan="2">
                    <script src="$versionchk" type="text/javascript"></script>
                    $versiontxt{'4'} <b>$YaBBversion</b><br />
                    <script type="text/javascript">
                        if (typeof STABLE === "undefined" || STABLE === null) {
                            document.write("$versiontxt{'5'} <b>$rna</b><br />$versiontxt{'7'} <b>$rna</b>");
                        } else {
                            document.write("$versiontxt{'5'} <b>"+STABLE+"</b><br />$versiontxt{'7'} <b>"+BETA+"</b>");
                        }
                    </script>
                </td>
            </tr><tr>
                <td class="catbg center"><b>$admin_txt{'495'}</b><br /></td>
                <td class="catbg center"><b>$admin_txt{'494'}</b><br /></td>
            </tr><tr>
                <td class="windowbg2">$admin_txt{'496'}</td>
                <td class="windowbg2"><i>$YaBBversion</i></td>
            </tr><tr>
                <td class="windowbg2">$yyexec.$yyext</td>
                <td class="windowbg2"><i>$yabbplver</i></td>
            </tr><tr>
                <td class="windowbg2">AdminIndex.pl</td>
                <td class="windowbg2"><i>$adminindexplver</i></td>
            </tr>~;

    opendir LNGDIR, $langdir;
    my @lfilesanddirs = readdir LNGDIR;
    closedir LNGDIR;
    foreach my $fld (@lfilesanddirs) {
        if (   -d "$langdir/$fld"
            && $fld =~ m{\A[0-9a-zA-Z_\#\%\-\:\+\?\$\&\~\,\@/]+\Z}sm
            && -e "$langdir/$fld/Main.lng" )
        {
            fopen( FILE, "$langdir/$fld/version.txt" );
            my @ver = <FILE>;
            fclose(FILE);
            $yymain .= qq~<tr>
                <td class="windowbg2">$fld Language Pack</td>
                <td class="windowbg2"><i>$ver[0]</i></td>
            </tr>~;
        }
    }
    $yymain .= qq~<tr>
                <td class="titlebg" colspan="2"><b>$admin_txt{'430'}</b></td>
            </tr>~;

    opendir DIR, $admindir;
    my @adminDIR = readdir DIR;
    closedir DIR;
    @adminDIR = sort @adminDIR;
    foreach my $fileinDIR (@adminDIR) {
        chomp $fileinDIR;
        if ( $fileinDIR =~ m/\.pl\Z/xsm ) {
            require "$admindir/$fileinDIR";
            my $txtrevision = lc $fileinDIR;
            $txtrevision =~ s/\.pl/plver/igsm;
            ${$txtrevision} =~ s/\$Revision\: (.*?) \$/Build $1/igsm;
            $yymain .= qq~<tr>
                <td class="windowbg2">$fileinDIR</td>
                <td class="windowbg2"><i>${$txtrevision}</i></td>
            </tr>~;
        }
        elsif ( $fileinDIR =~ m/\.pm\Z/xsm ) {
            require "$admindir/$fileinDIR";
            my $txtrevision = lc $fileinDIR;
            $txtrevision =~ s/\.pm/pmver/igsm;
            ${$txtrevision} =~ s/\$Revision\: (.*?) \$/Build $1/igsm;
            $yymain .= qq~<tr>
                <td class="windowbg2">$fileinDIR</td>
                <td class="windowbg2"><i>${$txtrevision}</i></td>
            </tr>~;
        }
    }
    $yymain .= qq~<tr>
                <td class="titlebg" colspan="2"><b>$admin_txt{'431'}</b></td>
        </tr>~;

    opendir DIR, $sourcedir;
    my @sourceDIR = readdir DIR;
    closedir DIR;
    @sourceDIR = sort @sourceDIR;
    foreach my $fileinDIR (@sourceDIR) {
        chomp $fileinDIR;
        if ( $fileinDIR =~ m/\.pl\Z/sm ) {
            require "$sourcedir/$fileinDIR";
            my $txtrevision = lc $fileinDIR;
            $txtrevision =~ s/\.pl/plver/igsm;
            ${$txtrevision} =~ s/\$Revision\: (.*?) \$/Build $1/igsm;
            $yymain .= qq~<tr>
                    <td class="windowbg2">$fileinDIR</td>
                    <td class="windowbg2"><i>$$txtrevision</i></td>
                </tr>~;
        }
        elsif ( $fileinDIR =~ m/\.pm\Z/xsm ) {
            require "$sourcedir/$fileinDIR";
            my $txtrevision = lc $fileinDIR;
            $txtrevision =~ s/\.pm/pmver/igsm;
            ${$txtrevision} =~ s/\$Revision\: (.*?) \$/Build $1/igsm;
            $yymain .= qq~<tr>
                <td class="windowbg2">$fileinDIR</td>
                <td class="windowbg2"><i>${$txtrevision}</i></td>
            </tr>~;
        }
    }

    $yymain .= q~
        </table>
        </div>~;

    $yytitle     = $admin_txt{'429'};
    $action_area = 'detailedversion';
    AdminTemplate();
    return;
}

sub Refcontrol {
    is_admin_or_gmod();
    LoadLanguage('RefControl');

    fopen( FILE, "$sourcedir/SubList.pm" );
    @scriptlines = <FILE>;
    fclose(FILE);

    fopen( FILE, "$vardir/allowed.txt" );
    @allowed = <FILE>;
    fclose(FILE);

    $startread = 0;
    $counter   = 0;

    foreach my $scriptline (@scriptlines) {
        chomp $scriptline;
        if ( substr( $scriptline, 0, 1 ) eq q{'} ) {    #';
            if ( $scriptline =~ /\'(.*?)\'/xsm ) {
                $actionfound = $1;
                push @actfound, $actionfound;
                $counter++;
            }
        }
    }
    $column  = int( $counter / 3 );
    $counter = 0;
    foreach my $actfound (@actfound) {
        $selected = q{};
        foreach my $allow (@allowed) {
            chomp $allow;
            if ( $actfound eq $allow ) {
                $selected = ' checked="checked"';
                last;
            }
        }
        $refexpl_txt{$actfound} =~ s/"/'/gxsm;    # '" XHTML Validation
        $dismenu .=
qq~<input type="checkbox" name="$actfound" id="$actfound"$selected />&nbsp;<label for="$actfound"><img src="$admin_img{'question'}" alt="$reftxt{'1a'} $refexpl_txt{$actfound}" title="$reftxt{'1a'} $refexpl_txt{$actfound}" /> $actfound</label><br />\n~;
        $counter++;
        if ( $counter > $column + 1 ) {
            $dismenu .= q~</td><td class="windowbg2 vtop">~;
            $counter = 0;
        }
    }
    $yymain .= qq~
<form action="$adminurl?action=referer_control2" method="post">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <colgroup>
                <col style="width: 33%" />
                <col style="width: 34%" />
                <col style="width: 33%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="3">
                    $admin_img{'prefimg'} <b>$reftxt{'1'}</b>
                </td>
            </tr><tr>
                <td class="windowbg2" colspan="3"><br />
                $reftxt{'2'}<br />
                <span class="small">$reftxt{'3'}<br /><br /></span>
                </td>
            </tr><tr>
                <td class="windowbg2 vtop">
                $dismenu
                </td>
            </tr>
        </table>
    </div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
             <input type="submit" value="$reftxt{'4'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>~;

    $yytitle     = "$reftxt{'1'}";
    $action_area = 'referer_control';
    AdminTemplate();
    return;
}

sub Refcontrol2 {
    is_admin_or_gmod();

    fopen( FILE, "$sourcedir/SubList.pm" );
    @scriptlines = <FILE>;
    fclose(FILE);

    $startread = 0;
    $counter   = 0;
    foreach my $scriptline (@scriptlines) {
        chomp $scriptline;
        if ( substr( $scriptline, 0, 1 ) eq q{'} ) {    #';
            if ( $scriptline =~ /\'(.*?)\'/xsm ) {
                $actionfound = $1;
                push @actfound, $actionfound;
                $counter++;
            }
        }
    }

    foreach my $actfound (@actfound) {
        if ( $FORM{$actfound} ) { push @outfile, "$actfound\n"; }
    }

    fopen( FILE, ">$vardir/allowed.txt" );
    print {FILE} @outfile or croak "$croak{'print'} FILE";
    fclose(FILE);

    $yySetLocation = qq~$adminurl?action=referer_control~;
    redirectexit();
    return;
}

sub AddMember {
    is_admin_or_gmod();
    LoadLanguage('Register');

    $yymain .= qq~
<script type="text/javascript" src="$yyhtml_root/YaBB.js"></script>
<script type="text/javascript" src="$yyhtml_root/ajax.js"></script>
<form action="$adminurl?action=addmember2" method="post" name="creator" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width: 30%" />
        <col style="width: 70%" />
    </colgroup>
    <tr>
        <td colspan="2" class="titlebg">
            $admin_img{'register'}<b> $admintxt{'17a'}</b>
        </td>
    </tr><tr>
        <td class="windowbg"><label for="regusername"><b>$register_txt{'98'}:</b></label></td>
        <td class="windowbg2"><input type="text" name="regusername" id="regusername" onchange="checkAvail('$scripturl',this.value,'user')" size="30" maxlength="18" /><input type="hidden" name="_session_id_" id="_session_id_" value="$sessionid" /><input type="hidden" name="regdate" id="regdate" value="$regdate" /><div id="useravailability"></div></td>
    </tr><tr>
        <td class="windowbg"><label for="regrealname"><b>$register_txt{'98a'}:</b></label></td>
        <td class="windowbg2"><input type="text" name="regrealname" id="regrealname" onchange="checkAvail('$scripturl',this.value,'display')" size="30" maxlength="30" /><div id="displayavailability"></div></td>
    </tr><tr>
        <td class="windowbg"><label for="email"><b>$register_txt{'69'}:</b></label></td>
        <td class="windowbg2"><input type="text" maxlength="100" name="email" id="email" onchange="checkAvail('$scripturl',this.value,'email')" size="50" /><div id="emailavailability"></div></td>
    </tr>~;
    if ( $allow_hide_email == 1 ) {
        $yymain .= qq~<tr>
        <td class="windowbg"><label for="hideemail"><b>$register_txt{'721'}</b></label></td>
        <td class="windowbg2"><input type="checkbox" name="hideemail" id="hideemail" value="1" checked="checked" /></td>
    </tr>~;
    }

    # Language selector
    $yymain .= qq~<tr>
        <td class="windowbg"><label for="userlang"><b>$register_txt{'101'}</b></label></td>
        <td class="windowbg2"><select name="userlang" id="userlang">~;
    opendir LNGDIR, $langdir;
    foreach ( sort { lc($a) cmp lc $b } readdir LNGDIR ) {
        if ( -e "$langdir/$_/Main.lng" ) {
            $yymain .=
                qq~<option value="$_"~
              . ( $_ eq $language ? ' selected="selected"' : q{} )
              . qq~>$_</option>~;
        }
    }
    closedir LNGDIR;
    $yymain .= q~</select></td>
    </tr>~;

    if ( !$emailpassword ) {
        $yymain .= password_check();
        $yymain =~ s/{yabb reg_1}/$register_txt{'81'}/sm;
        $yymain =~ s/{yabb reg_2}/$register_txt{'82'}/sm;
        $yymain =~ s/{yabb reg_caplock}/$register_txt{'capslock'}/gsm;
        $yymain =~ s/{yabb reg_wrongchar}/$register_txt{'wrong_char'}/gsm;
    }

    $yymain .= qq~</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
             <input type="submit" value="$register_txt{'97'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
<script type="text/javascript">
        document.creator.regusername.focus();
        //function
</script>~;

    $yytitle     = "$register_txt{'97'}";
    $action_area = 'addmember';
    AdminTemplate();
    return;
}

sub AddMember2 {
    is_admin_or_gmod();
    LoadLanguage('Register');
    LoadLanguage('Main');
    my %member;
    while ( ( $key, $value ) = each %FORM ) {
        $value =~ s/\A\s+//xsm;
        $value =~ s/\s+\Z//xsm;
        $value =~ s/[\n\r]//gxsm;
        $member{$key} = $value;
    }

    #    $member{'regusername'} =~ s/\s/_/gsm;

    # Make sure users can't register with banned details
    banning( $member{'regusername'}, $member{'email'}, 1 );

# check if there is a system hash named like this by checking existence through size
    my $hsize = keys %{ $member{'regusername'} };
    if ( $hsize > 0 ) { fatal_error('system_prohibited_id'); }
    if ( length( $member{'regusername'} ) > 25 ) {
        $member{'regusername'} = substr $member{'regusername'}, 0, 25;
    }
    if ( $member{'regusername'} eq q{} ) {
        fatal_error( 'no_username', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} eq q{_} || $member{'regusername'} eq q{|} ) {
        fatal_error( 'id_alfa_only', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} =~ /guest/ism ) {
        fatal_error( 'id_reserved', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} =~ /[^\w\+\-\.\@]/sm ) {
        fatal_error( 'invalid_character',
            "$register_txt{'35'} $register_txt{'241e'}" );
    }
    if ( $member{'regusername'} =~ /^[0-9]+$/sm ) {
        fatal_error( 'all_numbers',
            "$register_txt{'35'} $register_txt{'241n'}" );
    }
    if ( $member{'email'} eq q{} ) {
        fatal_error( 'no_email', "($member{'regusername'})" );
    }
    if ( -e "$memberdir/$member{'regusername'}.vars" ) {
        fatal_error( 'id_taken', "($member{'regusername'})" );
    }
    if ( $member{'regusername'} eq $member{'passwrd1'} ) {
        fatal_error('password_is_userid');
    }

    FromChars( $member{'regrealname'} );
    $convertstr = $member{'regrealname'};
    $convertcut = 30;
    CountChars();
    $member{'regrealname'} = $convertstr;
    if ($cliped) {
        fatal_error( 'realname_to_long',
            "($member{'regrealname'} => $convertstr)" );
    }
    if ( $member{'regrealname'} =~
        /[^ \w\x80-\xFF\[\]\(\)#\%\+,\-\|\.:=\?\@\^]/sm )
    {
        fatal_error( 'invalid_character',
            "$register_txt{'38'} $register_txt{'241re'}" );
    }

    if ($emailpassword) {
        srand;
        $member{'passwrd1'} = int rand 100;
        $member{'passwrd1'} =~ tr/0123456789/ymifxupbck/;
        $_ = int rand 77;
        $_ =~ tr/0123456789/q8dv7w4jm3/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 89;
        $_ =~ tr/0123456789/y6uivpkcxw/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 188;
        $_ =~ tr/0123456789/poiuytrewq/;
        $member{'passwrd1'} .= $_;
        $_ = int rand 65;
        $_ =~ tr/0123456789/lkjhgfdaut/;
        $member{'passwrd1'} .= $_;

    }
    else {
        if ( $member{'passwrd1'} ne $member{'passwrd2'} ) {
            fatal_error( 'password_mismatch', "($member{'regusername'})" );
        }
        if ( $member{'passwrd1'} eq q{} ) {
            fatal_error( 'no_password', "($member{'regusername'})" );
        }
        if ( $member{'passwrd1'} =~
            /[^\s\w!\@#\$\%\^&\*\(\)\+\|`~\-=\\:;'",\.\/\?\[\]\{\}]/sm )
        {
            fatal_error( 'invalid_character',
                "$register_txt{'36'} $register_txt{'241'}" );
        }
    }

    if ( $member{'email'} !~ /^[\w\-\.\+]+\@[\w\-\.\+]+\.\w{2,4}$/sm ) {
        fatal_error( 'invalid_character',
            "$register_txt{'69'} $register_txt{'241e'}" );
    }
    if (
        ( $member{'email'} =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)|(\.$)/sm )
        || ( $member{'email'} !~
            /\A.+@\[?(\w|[-.])+\.[a-zA-Z]{2,4}|[0-9]{1,4}\]?\Z/sm )
      )
    {
        fatal_error('invalid_email');
    }

    if (
        lc $member{'regusername'} eq
        lc MemberIndex( 'check_exist', $member{'regusername'}, 0 ) )
    {
        fatal_error( 'id_taken', "($member{'regusername'})" );
    }
    if (
        lc $member{'email'} eq
        lc MemberIndex( 'check_exist', $member{'email'}, 2 ) )
    {
        fatal_error( 'email_taken', "($member{'email'})" );
    }
    if (
        lc $member{'regrealname'} eq
        lc MemberIndex( 'check_exist', $member{'regrealname'}, 1 ) )
    {
        fatal_error( 'name_taken', "($member{'regrealname'})" );
    }

    if ( $name_cannot_be_userid
        && lc $member{'regusername'} eq lc $member{'regrealname'} )
    {
        fatal_error('name_is_userid');
    }

    fopen( RESERVE, "$vardir/reserve.txt" )
      || fatal_error( 'cannot_open', "$vardir/reserve.txt", 1 );
    @reserve = <RESERVE>;
    fclose(RESERVE);
    fopen( RESERVECFG, "$vardir/reservecfg.txt" )
      || fatal_error( 'cannot_open', "$vardir/reservecfg.txt", 1 );
    @reservecfg = <RESERVECFG>;
    fclose(RESERVECFG);
    for my $aa ( 0 .. ( @reservecfg - 1 ) ) {
        chomp $reservecfg[$aa];
    }
    $matchword = $reservecfg[0] eq 'checked';
    $matchcase = $reservecfg[1] eq 'checked';
    $matchuser = $reservecfg[2] eq 'checked';
    $matchname = $reservecfg[3] eq 'checked';
    $namecheck =
        $matchcase eq 'checked'
      ? $member{'regusername'}
      : lc $member{'regusername'};
    $realnamecheck =
        $matchcase eq 'checked'
      ? $member{'regrealname'}
      : lc $member{'regrealname'};

    foreach my $reserved (@reserve) {
        chomp $reserved;
        $reservecheck = $matchcase ? $reserved : lc $reserved;
        if ($matchuser) {
            if ($matchword) {
                if ( $namecheck eq $reservecheck ) {
                    fatal_error( 'id_reserved', "$reserved" );
                }
            }
            else {
                if ( $namecheck =~ $reservecheck ) {
                    fatal_error( 'id_reserved', "$reserved" );
                }
            }
        }
        if ($matchname) {
            if ($matchword) {
                if ( $realnamecheck eq $reservecheck ) {
                    fatal_error( 'name_reserved', "$reserved" );
                }
            }
            else {
                if ( $realnamecheck =~ $reservecheck ) {
                    fatal_error( 'name_reserved', "$reserved" );
                }
            }
        }
    }

    if ( -e ("$memberdir/$member{'username'}.vars") ) {
        fatal_error('id_taken');
    }

    if ( $send_welcomeim == 1 ) {

        $messageid = $BASETIME . $PROCESS_ID;
        fopen( IM, ">$memberdir/$member{'regusername'}.msg", 1 );
        print {IM}
"$messageid|$sendname|$member{'regusername'}|||$imsubject|$date|$imtext|$messageid|0|$ENV{'REMOTE_ADDR'}|s|u||\n"
          or croak "$croak{'print'} IM";
        fclose(IM);
    }
    $encryptopass = encode_password( $member{'passwrd1'} );
    $reguser      = $member{'regusername'};
    $registerdate = timetostring($date);

    if   ($default_template) { $new_template = $default_template; }
    else                     { $new_template = 'default'; }

    ToHTML( $member{'regrealname'} );

    ${ $uid . $reguser }{'password'}      = $encryptopass;
    ${ $uid . $reguser }{'realname'}      = $member{'regrealname'};
    ${ $uid . $reguser }{'email'}         = lc $member{'email'};
    ${ $uid . $reguser }{'postcount'}     = 0;
    ${ $uid . $reguser }{'usertext'}      = $defaultusertxt;
    ${ $uid . $reguser }{'userpic'}       = 'blank.gif';
    ${ $uid . $reguser }{'regdate'}       = $registerdate;
    ${ $uid . $reguser }{'regtime'}       = $date;
    ${ $uid . $reguser }{'timeselect'}    = $timeselected;
    ${ $uid . $reguser }{'timeoffset'}    = $timeoffset;
    ${ $uid . $reguser }{'dsttimeoffset'} = $dstoffset;
    ${ $uid . $reguser }{'hidemail'}      = $FORM{'hideemail'} ? 1 : 0;
    ${ $uid . $reguser }{'timeformat'}    = q~MM D+ YYYY @ HH:mm:ss*~;
    ${ $uid . $reguser }{'template'}      = $new_template;
    ${ $uid . $reguser }{'language'}      = $member{'userlang'};
    ${ $uid . $reguser }{'pageindex'}     = q~1|1|1~;

    UserAccount( $reguser, 'register' ) & MemberIndex( 'add', $reguser ) &
      FormatUserName($reguser);

    if ($emailpassword) {
        my $templanguage = $language;
        $language = $member{'userlang'};
        LoadLanguage('Email');
        require Sources::Mailer;
        my $message = template_email(
            $passwordregemail,
            {
                'displayname' => $member{'regrealname'},
                'username'    => $reguser,
                'password'    => $member{'passwrd1'}
            }
        );
        sendmail( $member{'email'}, "$mailreg_txt{'apr_result_info'} $mbname",
            $message, q{}, $emailcharset );
        $language = $templanguage;

    }
    elsif ($emailwelcome) {
        my $templanguage = $language;
        $language = $member{'userlang'};
        LoadLanguage('Email');
        require Sources::Mailer;
        my $message = template_email(
            $welcomeregemail,
            {
                'displayname' => $member{'regrealname'},
                'username'    => $reguser,
                'password'    => $member{'passwrd1'}
            }
        );
        sendmail( $member{'email'}, "$mailreg_txt{'apr_result_info'} $mbname",
            $message, q{}, $emailcharset );
        $language = $templanguage;
    }

    $yytitle = "$register_txt{'245'}";
    $yymain  = "$register_txt{'245'}";
    $yySetLocation =
      qq~$adminurl?action=viewmembers;sort=regdate;reversed=on;start=0~;
    redirectexit();
    $action_area = 'addmember';
    AdminTemplate();
    return;
}

sub AdminCheck {
    $yymain .= $my_admin_login;
    $formsession = cloak("$mbname$username");
    if   ($do_scramble_id) { $user = cloak($username); }
    else                   { $user = $username; }

    my $adminpass  = 'adminpass';
    my $cookiename = "$cookieusername$adminpass";
    if ( $yyCookies{$cookiename} ) {
        if ( $INFO{'action2'} ) {
            $my_action = qq~action=$INFO{'action2'};~;
        }
        if ( $INFO{'page'} ) {
            $my_page = qq~page=$INFO{'page'};~;
        }
        if ( $my_action || $my_page ) { $my_query = q{?}; }
        $yySetLocation = qq~$adminurl$my_query$my_action$my_page~;
        redirectexit();
    }
    else {
        $yymain =~
          s/{yabb adminchk}/$adminurl?action=admincheck2;username=$user/sm;
        if ( $INFO{'action2'} ) {
            $yymain =~ s/{yabb act}/$INFO{'action2'}/sm;
        }
        if ( $INFO{'page'} ) {
            $yymain =~ s/{yabb page}/$INFO{'page'}/sm;
        }

        $yynavigation = qq~&rsaquo; $admin_txt{'900'}~;
        $yytitle      = $admin_txt{'900'};
        $yyuname      = qq~${$uid.$username}{'realname'}~;
        template();
    }
    return;
}

sub AdminCheck2 {

    my $password = encode_password( $FORM{'passwrd'} || $INFO{'passwrd'} );

    if ( $FORM{'action'} ) { $my_action = qq~action=$FORM{'action'};~; }
    if ( $FORM{'page'} )   { $my_page   = qq~page=$FORM{'page'};~; }
    if ( $my_action || $my_page ) { $my_query = q{?}; }

    if   ( $do_scramble_id ) { $user = decloak($username); }
    else                   { $user = $username; }
    if ( ( $iamadmin || $iamgmod )
        && $password ne ${ $uid . $user }{'password'} )
    {
        fatal_error('no_admin_passwrd');
    }
    elsif ( $iamadmin
        && encode_password('admin') eq ${ $uid . $user }{'password'} )
    {
        fatal_error('default_password');
    }

    my $adminpass  = 'adminpass';
    my $cookiename = "$cookieusername$adminpass";
    push @otherCookies,
      write_cookie(
        -name    => "$cookiename",
        -value   => 'on',
        -path    => q{/},
        -expires => '0'
      );

    $yySetLocation = qq~$adminurl$my_query$my_action$my_page~;
    redirectexit();
    return;
}

1;
