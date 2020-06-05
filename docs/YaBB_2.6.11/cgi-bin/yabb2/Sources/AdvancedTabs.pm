###############################################################################
# AdvancedTabs.pm                                                             #
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
our $VERSION = '2.6.11';

$advancedtabspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub AddNewTab {
    GetTexttab();

    $edittabs = qq~<option value="thefront">$tabmenu_txt{'tabfront'}</option>~;
    foreach (@AdvancedTabs) {
        $_ =~ /^([^\|]+)/xsm;
        if ( $texttab{$1} ) {
            $edittabs .= qq~<option value="$1">$texttab{$1}</option>~;
        }
    }

    $yyaddtab = qq~
    <br />
    <script type="text/javascript">
    function submittab() {
        if (window.submitted) return false;
        window.submitted = true;
        return true;
    }

    function checkTab(theForm) {
        var isError = 0;
        var tabError = "$tabmenu_txt{'taberr'}\\n";

        if (theForm.tabtext.value == "") { tabError += "\\n- $tabmenu_txt{'texterr'}"; if(isError == 0) isError = 1; }
        if (theForm.taburl.value == "") { tabError += "\\n- $tabmenu_txt{'urlerr'}"; if(isError == 0) isError = 2; }
        if(isError >= 1) {
            alert(tabError);
            if(isError == 1) theForm.tabtext.focus();
            else if(isError == 2) theForm.taburl.focus();
            else if(isError == 3) theForm.tabtext.focus();
            return false;
        }
        return true
    }
    </script>~
      . $brd_advanced_tabs;
    $yyaddtab =~ s/{yabb tabtext}/$tabmenu_txt{'tabtext'}/sm;
    $yyaddtab =~ s/{yabb taburl}/$tabmenu_txt{'taburl'}/sm;
    $yyaddtab =~ s/{yabb tabwin}/$tabmenu_txt{'tabwin'}/sm;
    $yyaddtab =~ s/{yabb tabview}/$tabmenu_txt{'tabview'}/sm;
    $yyaddtab =~ s/{yabb viewall}/$tabmenu_txt{'viewall'}/sm;
    $yyaddtab =~ s/{yabb viewmem}/$tabmenu_txt{'viewmem'}/sm;
    $yyaddtab =~ s/{yabb viewgm}/$tabmenu_txt{'viewgm'}/sm;
    $yyaddtab =~ s/{yabb viewadm}/$tabmenu_txt{'viewadm'}/sm;
    $yyaddtab =~ s/{yabb tabinsert}/$tabmenu_txt{'tabinsert'}/sm;
    $yyaddtab =~ s/{yabb addtab}/$tabmenu_txt{'addtab'}/sm;
    $yyaddtab =~ s/{yabb edittabs}/$edittabs/sm;

    return $yyaddtab;
}

sub AddNewTab2 {
    if ($iamadmin) {
        my $tabtext = $FORM{'tabtext'};
        my $taburl  = $FORM{'taburl'};
        $taburl =~ s/"/\%22/gxsm;    #";
        my $tabwin         = $FORM{'tabwin'} ? 1 : 0;
        my $tabview        = $FORM{'showto'};
        my $tabafter       = $FORM{'addafter'};
        my $tmpusernamereq = 0;

        #Carsten's fix - nice and neat/';#
        if ( $taburl !~ /[ht|f]tp[s]{0,1}:\/\//xsm ) {
            $taburl = qq~http://$taburl~;
        }
        if (   $taburl =~ /$boardurl\/$yyexec\.$yyaext/ixsm
            && $taburl =~ /action\=(.*?)(\;|\Z)/ixsm )
        {
            $taburl      = 1;
            $tabaction   = $1;
            $tmpisaction = 1;
        }
        elsif ($taburl =~ /$boardurl\/AdminIndex\.$yyaext/ixsm
            && $taburl =~ /action\=(.*?)(\;|\Z)/ixsm )
        {
            $taburl      = 2;
            $tabaction   = $1;
            $tmpisaction = 1;
        }
        else {
            $tabaction = lc $tabtext;
            $tabaction =~ s/ /\_/gsm;
            $tmpisaction = 0;
        }
        $tabaction =~ s/\W/_/gxsm;
        map {
            if ( $_ =~ /^$tabaction\|?/xsm )
            {
                fatal_error( 'tabext', $tabaction );
            }
        } @AdvancedTabs;

        if ( $taburl == 1 || $taburl == 2 ) {
            if ( $FORM{'taburl'} =~ m/username\=/ixsm ) { $tmpusernamereq = 1; }
            $exttaburl = $FORM{'taburl'};
            $exttaburl =~ s/(.*?)\?(.*?)/$2/gxsm;
            $exttaburl =~ s/action\=(.*?)(\;|\Z)//ixsm;
            $exttaburl =~ s/username\=(.*?)(\;|\Z)//ixsm;
        }
        else {
            $exttaburl = q{};
        }

        ToHTML($tabtext);

        opendir DIR, $langdir;
        my @languages = readdir DIR;
        closedir DIR;
        foreach my $lngdir (@languages) {
            next
              if $lngdir eq q{.} || $lngdir eq q{..} || !-d "$langdir/$lngdir";
            undef %tabtxt;
            if ( fopen( TABTXT, "$langdir/$lngdir/tabtext.txt" ) ) {
                %tabtxt = map { /(.*)\t(.*)/xsm } <TABTXT>;
                fclose(TABTXT);
            }
            $tabtxt{$tabaction} = $tabtext;
            fopen( TABTXT, ">$langdir/$lngdir/tabtext.txt" )
              or fatal_error( 'file_not_open', "$langdir/$lngdir/tabtext.txt",
                1 );
            print {TABTXT} map { "$_\t$tabtxt{$_}\n" } keys %tabtxt
              or croak "$croak{'print'} TABTXT";
            fclose(TABTXT);
        }

        my @new_tabs_order;
        if ( $tabafter eq 'thefront' ) {
            push @new_tabs_order,
qq~$tabaction|$taburl|$tmpisaction|$tmpusernamereq|$tabview|$tabwin|$exttaburl~;
        }
        foreach (@AdvancedTabs) {
            push @new_tabs_order, $_;
            if (/^$tabafter\|?/xsm) {
                push @new_tabs_order,
qq~$tabaction|$taburl|$tmpisaction|$tmpusernamereq|$tabview|$tabwin|$exttaburl~;
            }
        }
        @AdvancedTabs = @new_tabs_order;

        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');
    }

    $yySetLocation = $scripturl;
    redirectexit();
    return;
}

sub EditTab {
    get_micon();
    GetTexttab();
    $tabsave  = $micon{'tabsave'};
    $tabdel   = $micon{'tabdel'};
    %edittab= ();
    my @tablist = qw(home help search ml eventcal birthdaylist admin revalidatesession login register guestpm mycenter logout);
## Mod hook tablist ##
## End Mod hook tablist ##
    for (@tablist) {
        $edittab{$_} = qq~<span class="tabstyle">$tabfill$texttab{$_}$tabfill</span>~;
    }

    my $selsize   = 0;
    my $isexttabs = 0;
    for my $i ( 0 .. ( @AdvancedTabs - 1 ) ) {
        if ( $AdvancedTabs[$i] =~ /\|/xsm ) {
            my ( $tab_key, $tmptab_url, $isaction, $username_req, $tab_access,
                $dummy )
              = split /\|/xsm, $AdvancedTabs[$i], 6;
            my $enc_key = $tab_key;
            $enc_key =~ s/\&/%26/gxsm;
            $isexttabs++;
            if (   !$tab_access
                || ( $tab_access < 2 && !$iamguest )
                || ( $tab_access < 3 && $iamgmod )
                || $iamadmin )
            {
                if ( $tmptab_url == 1 ) { $tab_url = qq~$scripturl~; }
                elsif ( $tmptab_url == 2 ) {
                    $tab_url = qq~$boardurl/AdminIndex.$yyaext~;
                }
                else { $tab_url = qq~$tmptab_url~; }
                if ($isaction) { $tab_url .= qq~?action=$tab_key~; }
                if ($username_req) {
                    $tab_url .= qq~;username=$useraccount{$username}~;
                }
                $inputlength = length $tabtxt{$tab_key};
                $edittab{$tab_key} =
qq~<form action="$scripturl?action=edittab2;savetab=$enc_key" method="post" name="$tab_key$isexttabs" style="display: inline; white-space: nowrap;" accept-charset="$yymycharset">~;
                $edittab{$tab_key} .=
qq~<input type="text" name="$tab_key" id="$tab_key" value="$tabtxt{$tab_key}" size="$inputlength" class="edittab" />~;
                $edittab{$tab_key} .=
qq~<input type="image" src="$micon_bg{'tabsave'}" alt="$tabmenu_txt{'savetab'}" title="$tabmenu_txt{'savetab'}" class="editttab_img" />~;
                $edittab{$tab_key} .=
qq~ <a href="$scripturl?action=deletetab;deltab=$enc_key" style="padding:0; margin:0">$tabdel</a>~;
                $edittab{$tab_key} .= q~</form>~;
                $edittabs .=
                  qq~<option value="$tab_key"~
                  . (
                    $tab_key eq $INFO{'thetab'} ? ' selected="selected"' : q{} )
                  . qq~>$texttab{$tab_key}</option>~;
                $edittabmenu .= qq~<li>$edittab{$tab_key}</li>~;
                $selsize++;
            }
        }
        elsif ( $edittab{ $AdvancedTabs[$i] } ) {
            $edittabs .= qq~<option value="$AdvancedTabs[$i]"~
              . (
                $AdvancedTabs[$i] eq $INFO{'thetab'}
                ? ' selected="selected"'
                : q{}
              ) . qq~>$texttab{$AdvancedTabs[$i]}</option>~;
            $edittabmenu .= qq~<li>$edittab{ $AdvancedTabs[$i] }</li>~;
            $selsize++;
        }
    }
    if ( $selsize > 11 ) { $selsize = 11; }

    $yyaddtab = $brd_advanced_tabs_edit;
    $yyaddtab =~ s/{yabb edittabmenu}/$edittabmenu/sm;
    $yyaddtab =~ s/{yabb reordertab}/$tabmenu_txt{'reordertab'}/sm;
    $yyaddtab =~ s/{yabb selsize}/$selsize/sm;
    $yyaddtab =~ s/{yabb edittabs}/$edittabs/sm;
    $yyaddtab =~ s/{yabb edittabs}/$edittabs/sm;
    $yyaddtab =~ s/{yabb tableft}/$tabmenu_txt{'tableft'}/sm;
    $yyaddtab =~ s/{yabb tabright}/$tabmenu_txt{'tabright'}/sm;
    $yyaddtab =~ s/{yabb edittext1}/$tabmenu_txt{'edittext1'}/sm;
    $yyaddtab =~ s/{yabb tabsave}/$tabsave/sm;
    $yyaddtab =~ s/{yabb edittext2}/$tabmenu_txt{'edittext2'}/sm;
    $yyaddtab =~ s/{yabb tabdel}/$tabdel/sm;
    $yyaddtab =~ s/{yabb edittext3}/$tabmenu_txt{'edittext3'}/sm;
    $yyaddtab =~ s/{yabb reordertext}/$tabmenu_txt{'reordertext'}/sm;

    undef %edittab;
    return;
}

sub EditTab2 {
    if ($iamadmin) {
        $tosave = $INFO{'savetab'};
        $tosave =~ s/%26/&/gxsm;
        $tosavetxt = $FORM{$tosave};
        ToHTML($tosavetxt);
        $tab_lang = $language ? $language : $lang;
        fopen( TABTXT, "$langdir/$tab_lang/tabtext.txt" )
          or fatal_error( 'file_not_open', "$langdir/$tab_lang/tabtext.txt" );
        %tabtxt = map { /(.*)\t(.*)/xsm } <TABTXT>;
        fclose(TABTXT);
        $tabtxt{$tosave} = $tosavetxt;
        fopen( TABTXT, ">$langdir/$tab_lang/tabtext.txt" )
          or fatal_error( 'file_not_open', "$langdir/$tab_lang/tabtext.txt" );
        print {TABTXT} map { "$_\t$tabtxt{$_}\n" } keys %tabtxt
          or croak "$croak{'print'} TABTXT";
        fclose(TABTXT);
    }

    $yySetLocation = $scripturl;
    redirectexit();
    return;
}

sub ReorderTab {
    my $moveitem = $FORM{'ordertabs'};
    if ($iamadmin) {
        if ($moveitem) {
            if ( $FORM{'moveleft'} ) {
                for my $i ( 0 .. ( @AdvancedTabs - 1 ) ) {
                    if ( $AdvancedTabs[$i] =~ /^$moveitem\|?/xsm && $i > 0 ) {
                        my $j = $i - 1;
                        my $x = $AdvancedTabs[$i];
                        $AdvancedTabs[$i] = $AdvancedTabs[$j];
                        $AdvancedTabs[$j] = $x;
                        last;
                    }
                }
            }
            elsif ( $FORM{'moveright'} ) {
                for my $i ( 0 .. ( @AdvancedTabs - 1 ) ) {
                    if (   $AdvancedTabs[$i] =~ /^$moveitem\|?/xsm
                        && $i < $#AdvancedTabs )
                    {
                        my $j = $i + 1;
                        my $x = $AdvancedTabs[$i];
                        $AdvancedTabs[$i] = $AdvancedTabs[$j];
                        $AdvancedTabs[$j] = $x;
                        last;
                    }
                }
            }
        }

        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');
    }

    $yySetLocation = qq~$scripturl?action=edittab;thetab=$moveitem~;
    redirectexit();
    return;
}

sub DeleteTab {
    if ($iamadmin) {
        my $todelete = $INFO{'deltab'};
        $todelete =~ s/%26/&/gxsm;

        opendir DIR, $langdir;
        @languages = readdir DIR;
        closedir DIR;
        foreach my $lngdir (@languages) {
            if (   $lngdir eq q{.}
                || $lngdir eq q{..}
                || !-d "$langdir/$lngdir"
                || !-e "$langdir/$lngdir/tabtext.txt" )
            {
                next;
            }
            fopen( TABTXT, "$langdir/$lngdir/tabtext.txt" )
              or fatal_error( 'file_not_open', "$langdir/$lngdir/tabtext.txt" );
            %tabtxt = map { /(.*)\t(.*)/xsm } <TABTXT>;
            fclose(TABTXT);
            delete $tabtxt{$todelete};
            if ( !%tabtxt ) {
                unlink "$langdir/$lngdir/tabtext.txt";
            }
            else {
                fopen( TABTXT, ">$langdir/$lngdir/tabtext.txt" );
                print {TABTXT} map { "$_\t$tabtxt{$_}\n" } keys %tabtxt
                  or croak "$croak{'print'} TABTXT";
                fclose(TABTXT);
            }
        }

        my @new_tabs_order;
        foreach (@AdvancedTabs) {
            if ( $_ !~ /^$todelete\|?/xsm ) { push @new_tabs_order, $_; }
        }
        @AdvancedTabs = @new_tabs_order;
        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');
    }

    $yySetLocation = $scripturl;
    redirectexit();
    return;
}

sub GetTexttab {
    $texttab{'home'}              = $img_txt{'103'};
    $texttab{'help'}              = $img_txt{'119'};
    $texttab{'search'}            = $img_txt{'182'};
    $texttab{'ml'}                = $img_txt{'331'};
    $texttab{'eventcal'}          = $img_txt{'eventcal'};
    $texttab{'birthdaylist'}      = $img_txt{'birthdaylist'};
    $texttab{'admin'}             = $img_txt{'2'};
    $texttab{'revalidatesession'} = $img_txt{'34a'};
    $texttab{'login'}             = $img_txt{'34'};
    $texttab{'register'}          = $img_txt{'97'};
    $texttab{'guestpm'}           = $img_txt{'pmadmin'};
    $texttab{'mycenter'}          = $img_txt{'mycenter'};
    $texttab{'logout'}            = $img_txt{'108'};
## Mod Hook GetTextTab ##
## End Mod Hook GetTextTab ##
    if ( !$tab_lang ) { GetTabtxt(); }
    foreach ( keys %tabtxt ) { $texttab{$_} = $tabtxt{$_}; }
    return;
}

1;
