###############################################################################
# TabMenu.pm                                                                  #
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
our $VERSION = '2.6.11';

$tabmenupmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('TabMenu');
get_micon();

$tabsep  = q{};
$tabfill = q{};

sub mainMenu {
    my @acting = (
        [
            'search2',            'favorites',
            'shownotify',         'im',
            'imdraft',            'imoutbox',
            'imstorage',          'imsend',
            'imsend2',            'imshow',
            'profileCheck',       'myviewprofile',
            'myprofile',          'myprofileContacts',
            'myprofileOptions',   'myprofileBuddy',
            'myprofileIM',        'myprofileAdmin',
            'myusersrecentposts', 'messagepagetext',
            'messagepagedrop',    'threadpagetext',
            'threadpagedrop',     'post',
            'notify',             'boardnotify',
            'sendtopic',          'modify',
            'guestpm2'
        ],
        [
            'search',   'mycenter', 'mycenter', 'mycenter',
            'mycenter', 'mycenter', 'mycenter', 'mycenter',
            'mycenter', 'mycenter', 'mycenter', 'mycenter',
            'mycenter', 'mycenter', 'mycenter', 'mycenter',
            'mycenter', 'mycenter', 'mycenter', 'home',
            'home',     'home',     'home',     'home',
            'home',     'home',     'home',     'home',
            'guestpm'
        ],
    );
## Mod hook 1 ##

    if ( $action eq 'addtab' && $iamadmin ) {
        require Sources::AdvancedTabs;
        AddNewTab();
    }
    elsif ( $action eq 'edittab' && $iamadmin ) {
        require Sources::AdvancedTabs;
        EditTab();
    }
    elsif ( $INFO{'board'} || $INFO{'num'} ) { $tmpaction = q{}; }
    elsif ( $action ne q{} ) {
        for my $i ( 0 .. $#{ $acting[0] } ) {
            my $img0 = $acting[0]->[$i];
            my $img1 = $acting[1]->[$i];
            if ( $action eq $img0 ) {
                $tmpaction = $img1;
            }
            else { $tmpaction = $action; }
        }
    }
    else {
        $tmpaction = 'home';
    }

    my $tabhtml_l = q~                        <li><span|><a href=~;
    my $tabhtml_r = qq~</span></li>\n~;
    $tab{'home'} = qq~$tabhtml_l"$scripturl" title="$img_txt{'103'}">$img_txt{'103'}</a>$tabhtml_r~;
    $tab{'help'} = qq~$tabhtml_l"$scripturl?action=help" title="$img_txt{'119'}" class="help">$img_txt{'119'}</a>$tabhtml_r~;

    if ( $maxsearchdisplay > -1 && $advsearchaccess eq 'granted' ) {
        $tab{'search'} = qq~$tabhtml_l"$scripturl?action=search" title="$img_txt{'182'}">$img_txt{'182'}</a>$tabhtml_r~;
    }
    if ( $Show_EventButton == 2 || ( !$iamguest && $Show_EventButton == 1 ) ) {
        $tab{'eventcal'} = qq~$tabhtml_l"$scripturl?action=eventcal;calshow=1" title="$img_txt{'eventcal'}">$img_txt{'eventcal'}</a>$tabhtml_r~;
    }
    if ( $Show_BirthdayButton == 2
        || ( !$iamguest && $Show_BirthdayButton == 1 ) )
    {
        $tab{'birthdaylist'} = qq~$tabhtml_l"$scripturl?action=birthdaylist" title="$img_txt{'birthdaylist'}">$img_txt{'birthdaylist'}</a>$tabhtml_r~;
    }
    if (   !$ML_Allowed
        || ( $ML_Allowed == 1 && !$iamguest )
        || ( $ML_Allowed == 2 && $staff )
        || ( $ML_Allowed == 3 && ( $iamadmin || $iamgmod ) )
        || ( $ML_Allowed == 4 && ( $iamadmin || $iamgmod || $iamfmod ) ) )
    {
        $tab{'ml'} = qq~$tabhtml_l"$scripturl?action=ml" title="$img_txt{'331'}">$img_txt{'331'}</a>$tabhtml_r~;
    }
    if ($iamadmin) {
        if   ($do_scramble_id) { $user = cloak($username); }
        else                   { $user = $username; }
        $tab{'admin'} = qq~$tabhtml_l"$boardurl/AdminIndex.$yyaext?action=admincheck;username=$user" title="$img_txt{'2'}">$img_txt{'2'}</a>$tabhtml_r~;
    }
    if ($iamgmod) {
        get_gmod();
        if ($allow_gmod_admin) {
            if   ($do_scramble_id) { $user = cloak($username); }
            else                   { $user = $username; }
            $tab{'admin'} = qq~$tabhtml_l"$boardurl/AdminIndex.$yyaext?action=admincheck;username=$user" title="$img_txt{'2'}">$img_txt{'2'}</a>$tabhtml_r~;
        }
    }
    if ( $sessionvalid == 0 && !$iamguest ) {
        my $sesredir;
        if (   $testenv
            && $action ne 'revalidatesession'
            && $action ne 'revalidatesession2' )
        {
            $sesredir = $testenv;
            $sesredir =~ s/\=/\~/gxsm;
            $sesredir =~ s/;/x3B/gxsm;
            $sesredir = qq~;sesredir=$sesredir~;
        }
        $tab{'revalidatesession'} = qq~$tabhtml_l"$scripturl?action=revalidatesession$sesredir" title="$img_txt{'34a'}">$img_txt{'34a'}</a>$tabhtml_r~;
    }
    if ($iamguest) {
        my $sesredir;
        if ($testenv) {
            $sesredir = $testenv;
            $sesredir =~ s/\=/\~/gxsm;
            $sesredir =~ s/;/x3B/gxsm;
            $sesredir = qq~;sesredir=$sesredir~;
        }
        $tab{'login'} = qq~$tabhtml_l"~
          . (
            $loginform
            ? "javascript:if(jumptologin>1)alert('$maintxt{'35'}');jumptologin++;window.scrollTo(0,10000);document.loginform.username.focus();"
            : "$scripturl?action=login$sesredir"
          ) . qq~" title="$img_txt{'34'}">$img_txt{'34'}</a>$tabhtml_r~;
        if ($regtype) {
            $tab{'register'} = qq~$tabhtml_l"$scripturl?action=register" title="$img_txt{'97'}">$img_txt{'97'}</a>$tabhtml_r~;
        }
        if ( $PMenableGuestButton && $PM_level > 0 && $PMenableBm_level > 0 ) {
            $tab{'guestpm'} = qq~$tabhtml_l"$scripturl?action=guestpm" title="$img_txt{'pmadmin'}">$img_txt{'pmadmin'}</a>$tabhtml_r~;
        }
    }
    else {
        $tab{'mycenter'} = qq~$tabhtml_l"$scripturl?action=mycenter" title="$img_txt{'mycenter'}">$img_txt{'mycenter'}</a>$tabhtml_r~;
        $tab{'logout'} = qq~$tabhtml_l"$scripturl?action=logout" title="$img_txt{'108'}">$img_txt{'108'}</a>$tabhtml_r~;
    }

## Tab Mod Hook ##

    $yytabmenu = qq~<ul>\n~;
    # Advanced Tabs starts here
    for my $i ( 0 .. $#AdvancedTabs ) {
        if ( $AdvancedTabs[$i] =~ /[|]/xsm ) {
            my (
                $tab_key,    $tmptab_url, $isaction, $username_req,
                $tab_access, $tab_newwin, $exttab_url
            ) = split /[|]/xsm, $AdvancedTabs[$i];
            if (   !$tab_access
                || ( $tab_access < 2 && !$iamguest )
                || ( $tab_access < 3 && $iamgmod )
                || $iamadmin )
            {
                if ( $tmptab_url == 1 ) { $tab_url = $scripturl; }
                elsif ( $tmptab_url == 2 ) {
                    $tab_url = qq~$boardurl/AdminIndex.$yyaext~;
                }
                else { $tab_url = $tmptab_url; }
                if ($isaction) { $tab_url .= qq~?action=$tab_key~; }
                if ($username_req) {
                    $tab_url .= qq~;username=$useraccount{$username}~;
                }
                if ($exttab_url) { $tab_url .= qq~;$exttab_url~; }
                my $newwin = $tab_newwin ? q~ target="_blank"~ : q{};
                if ( !$tab_lang ) { GetTabtxt(); }

                $yytabmenu .= q~                        <li><span~
                  . (
                    $AdvancedTabs[$i] eq $tmpaction
                    ? q~ class="selected"~
                    : q{}
                  )
                  . qq~><a href="$tab_url"$newwin title="$tabtxt{$tab_key}">$tabtxt{$tab_key}</a>$tabhtml_r~;
            }
        }
        elsif ( $tab{ $AdvancedTabs[$i] } ) {
            my ( $first, $last ) = split /\|/xsm, $tab{ $AdvancedTabs[$i] };
            $yytabmenu .= $first
              . (
                ( $AdvancedTabs[$i] eq $tmpaction && $last )
                ? q~ class="selected"~
                : q{}
              ) . $last;
        }
    }
    $yytabmenu .= q~                   </ul>~;

    if ( $iamadmin && $addtab_on == 1 ) {
        my ( $seladdtab, $seledittab );
        if    ( $action eq 'addtab' )  { $seladdtab  = q~ class="selected"~; }
        elsif ( $action eq 'edittab' ) { $seledittab = q~ class="selected"~; }
        $yytabadd =
qq~<ul class="advtabs"><li id="addtab"><span$seladdtab><a href="$scripturl?action=addtab" title="$tabmenu_txt{'newtab'}">$micon{'tabadd'}</a>$tabhtml_r~;
        $yytabadd .=
qq~<li id="edittab"><span$seledittab><a href="$scripturl?action=edittab" title="$tabmenu_txt{'edittab'}">$micon{'tabedit'}</a></span></li>\n</ul>~;
    }
    else {
        $yytabadd = q~&nbsp;~;
    }
    return;
}

sub GetTabtxt2 {
    $tab_lang = $language ? $language : $lang;
    if ( -e "$langdir/$tab_lang/tabtext.txt" ) {
        fopen( TABTXT, "$langdir/$tab_lang/tabtext.txt" );
        @tabtext = <TABTXT>;
        fclose(TABTXT);
        chomp @tabtext;
        for ( @tabtext ) {
            if ( $_ ne q{} ) {
                ($key, $val ) = split /\t/xsm, $_;
                $tabtxt{$key} = $val;
            }
        }
    }
    elsif ( -e "$langdir/English/tabtext.txt" ) {
        fopen( TABTXT, "$langdir/English/tabtext.txt" );
        @tabtext = <TABTXT>;
        fclose(TABTXT);
        chomp @tabtext;
        for ( @tabtext ) {
            if ( $_ ne q{} ) {
                ($key, $val ) = split /\t/xsm, $_;
                $tabtxt{$key} = $val;
            }
        }
        if ( -e "$langdir/$tab_lang/Main.lng" ) {
            fopen( TABTXT, ">$langdir/$tab_lang/tabtext.txt" );
            print {TABTXT} map { "$_\t$tabtxt{$_}\n" } keys %tabtxt
              or croak "$croak{'print'} TABTXT";
            fclose(TABTXT);
        }
    }
    return;
}

sub GetTabtxt {
    $tab_lang = $language ? $language : $lang;
    if ( -e "$langdir/$tab_lang/tabtext.txt" ) {
        fopen( TABTXT, "$langdir/$tab_lang/tabtext.txt" );
        %tabtxt = map { /(.*)\t(.*)/xsm } <TABTXT>;
        fclose(TABTXT);
        for (keys %tabtxt) {
			chomp $tabtxt{$_}
		}
    }
    elsif ( -e "$langdir/English/tabtext.txt" ) {
        fopen( TABTXT, "$langdir/English/tabtext.txt" );
        %tabtxt = map { /(.*)\t(.*)/xsm } <TABTXT>;
        fclose(TABTXT);
        if ( -e "$langdir/$tab_lang/Main.lng" ) {
            fopen( TABTXT, ">$langdir/$tab_lang/tabtext.txt" );
            print {TABTXT} map { "$_\t$tabtxt{$_}\n" } keys %tabtxt
              or croak "$croak{'print'} TABTXT";
            fclose(TABTXT);
        }
    }
    return;
}

1;
