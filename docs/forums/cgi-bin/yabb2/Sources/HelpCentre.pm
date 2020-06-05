###############################################################################
# HelpCentre.pm                                                               #
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

$helpcentrepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('HelpCentre');

require Sources::Menu;
$yytitle = $helptxt{'1'};
undef $guest_media_disallowed;

@my_modimglist =
  qw( admin_rem admin_move_split_splice admin_lock hide admin_sticky admin_del );
$my_moding = q{};
foreach (@my_modimglist) {
    $modimg = SetImage( $_, $UseMenuType );
    $mymoding .= qq~$menusep$modimg~;
}
$mymoding =~ s/\Q$menusep//ism;

sub SectionDecide {

   # This bit decides what section we are in and sets the background accordingly
   # Also sets the variables are used to open up the correct Help Directory

    if ($UseHelp_Perms) {
        $ismod = 0;
        if ( !exists $memberinfo{$username} ) { LoadUser($username); }
        foreach my $catid (@categoryorder) {
            if ($ismod) { last; }
            $boardlist = $cat{$catid};
            (@bdlist) = split /\,/xsm, $boardlist;
            foreach my $curboard (@bdlist) {
                if ($ismod) { last; }
                foreach
                  my $curuser ( split /, ?/sm, ${ $uid . $curboard }{'mods'} )
                {
                    if ( $curuser eq $username ) { $ismod = 1; last; }
                }
                foreach ( split /, /sm, ${ $uid . $curboard }{'modgroups'} ) {
                    if ( $_ eq ${ $uid . $username }{'position'} ) {
                        $ismod = 1;
                        last;
                    }
                }
            }
        }
    }

    if ( $INFO{'section'} eq 'admin' ) {
        if ( $UseHelp_Perms && !$iamadmin ) {
            fatal_error( 'no_access', 'HelpCentre->SectionDecide' );
        }
        ${ $INFO{'section'} . _class } = 'selected-bg';
        $help_area = 'Admin';
    }
    elsif ( $INFO{'section'} eq 'global_mod' ) {
        if ( $UseHelp_Perms && !$iamgmod && !$iamadmin ) {
            fatal_error( 'no_access', 'HelpCentre->SectionDecide' );
        }
        ${ $INFO{'section'} . _class } = 'selected-bg';
        $help_area = 'Gmod';
    }
    elsif ( $INFO{'section'} eq 'moderator' ) {
        if ( $UseHelp_Perms && !$ismod && !$iamgmod && !$iamadmin && !$iamfmod ) {
            fatal_error( 'no_access', 'HelpCentre->SectionDecide' );
        }
        ${ $INFO{'section'} . _class } = 'selected-bg';
        $help_area = 'Moderator';
    }

    else {
        $UserClass = 'selected-bg';
        $help_area = 'User';
    }
    return;
}

sub SectionPrint {

    # Prints the navigation bar for the help section
    $userhlp = qq~<a href="$scripturl?action=help">$helptxt{'3'}</a>~;
    if ($UseHelp_Perms) {
        if ( !$ismod && !$iamgmod && !$iamadmin && !$iamfmod ) { return }
        if ( $ismod || $iamgmod || $iamadmin || $iamfmod ) {
            $modhlp =
qq~<a href="$scripturl?action=help;section=moderator">$helptxt{'4'}</a>~;
        }
        else {
            $modhlp = '&nbsp;';
        }
        if ( $iamgmod || $iamadmin ) {
            $gmodhlp =
qq~<a href="$scripturl?action=help;section=global_mod">$helptxt{'5'}</a>~;
        }
        else {
            $gmodhlp = '&nbsp;';
        }
        if ($iamadmin) {
            $adminhlp =
qq~<a href="$scripturl?action=help;section=admin">$helptxt{'6'}</a>~;
        }
        else {
            $adminhlp = '&nbsp;';
        }
    }
    else {
        $modhlp =
qq~<a href="$scripturl?action=help;section=moderator">$helptxt{'4'}</a>~;
        $gmodhlp =
qq~<a href="$scripturl?action=help;section=global_mod">$helptxt{'5'}</a>~;
        $adminhlp =
qq~<a href="$scripturl?action=help;section=admin">$helptxt{'6'}</a>~;
    }

    $HelpNavBar =~ s/{user menu}/$userhlp/gsm;
    $HelpNavBar =~ s/{moderator menu}/$modhlp/gsm;
    $HelpNavBar =~ s/{global mod menu}/$gmodhlp/gsm;
    $HelpNavBar =~ s/{admin menu}/$adminhlp/gsm;
    $HelpNavBar =~ s/{user class}/$UserClass/gsm;
    $HelpNavBar =~ s/{moderator class}/$moderator_class/gsm;
    $HelpNavBar =~ s/{global mod class}/$global_mod_class/gsm;
    $HelpNavBar =~ s/{admin class}/$admin_class/gsm;
    $yymain .= $HelpNavBar;
    return $yymain;

}

sub GetHelpFiles {
    if ( !$HelpTemplateLoaded ) {
        get_template('HelpCentre');
    }

    SectionDecide();

    # This determines if the order file is present and if it isn't
    # It creates a new one, in default alphabetical order
    if ( !-e "$vardir/$help_area.helporder" ) { CreateOrderFile(); }

    fopen( HELPORDER, "$vardir/$help_area.helporder" );
    my @helporderlist = <HELPORDER>;
    fclose(HELPORDER);
    chomp @helporderlist;

    foreach (@helporderlist) {
        if ( -e "$helpfile/$language/$help_area/$_.help" ) {
            require "$helpfile/$language/$help_area/$_.help";
        }
        elsif ( -e "$helpfile/English/$help_area/$_.help" ) {
            require "$helpfile/English/$help_area/$_.help";
        }
        else {
            next;
        }

        MainHelp();
        DoContents();
    }

    SectionPrint();
    ContentContainer();

    $yynavigation = qq~&rsaquo; $yytitle~;
    template();
    return;
}

sub MainHelp {

    $TempParse = $BodyHeader;
    $BrdID = $mbname;
    $BrdID =~ s/ /_/gsm;
    $SectionName =~ s/{yabb myboardname}/$BrdID/gsm;
    $SectionName =~ s/ /_/gsm;
    $TempParse =~ s/{yabb section_anchor}/$SectionName/gsm;
    $SectionNam = $SectionName;
    $SectionNam =~ s/_/ /gsm;
    $TempParse  =~ s/{yabb section_name}/$SectionNam/gsm;
    $Body .= qq~$TempParse~;

    $i = 1;
    while ( ${ SectionSub . $i } ) {

        if ( ${ SectionExcl . $i } eq 'yabbc'
            && ( !$enable_ubbc || !$showyabbcbutt ) )
        {
            $i++;
            next;
        }

        $TempParse     = $BodySubHeader;
        $BrdID = $mbname;
        $BrdID =~ s/ /_/gsm;
        $SectionAnchor = ${ SectionSub . $i };
        $SectionSub    = ${ SectionSub . $i };
        $SectionSub =~ s/_/ /gsm;
        $SectionAnchor =~ s/{yabb myboardname}/$BrdID/gsm;
        $SectionAnchor =~ s/ /_/gsm;
        $TempParse  =~ s/{yabb section_anchor}/$SectionAnchor/gsm;
        $TempParse  =~ s/{yabb section_sub}/$SectionSub/gsm;
        $TempParse  =~ s/{yabb myboardname}/$mbname/gsm;
        $Body .= qq~$TempParse~;

        $message     = ${ SectionBody . $i };
        $displayname = ${ $uid . $username }{'realname'};
        enable_yabbc();
        $message =~
s/\[yabbc\](.*?)\[\/yabbc\]/my($text) = $1; ToHTML($text); DoUBBCTo($text);/sgem;
        wrap2();

        if ( $SectionAnchor eq 'YaBBC_Reference' ) {
            $yyinlinestyle .= qq~<style type="text/css">
.yabbc td {width: 75%; text-align: left;}
.yabbc td:first-child {width: 25%; vertical-align: top;}
.yabbc th {width: 100%;}
.yabbc th img {float: left;}
.ubbcbutton {float: left;}
.yabbc table {width: 75%;}
</style>\n~;
        }

        $TempParse = $BodyItem;
        $TempParse =~ s/{yabb item}/$message/gsm;
        $TempParse =~ s/{yabb mymoding}/$mymoding/sm;
        $TempParse  =~ s/{top_img}/$top_img/gsm;
        $Body .= qq~$TempParse~;
        $i++;
    }
    $Body .= qq~$BodyFooter~;
    return $Body;
}

{
    my %hpkillhash = (
        q{;}  => '&#059;',
        q{!}  => '&#33;',
        q{(}  => '&#40;',
        q{)}  => '&#41;',
        q{-}  => '&#45;',
        q{.}  => '&#46;',
        q{/}  => '&#47;',
        q{:}  => '&#58;',
        q{?}  => '&#63;',
        q{[}  => '&#91;',
        q{\\} => '&#92;',
        q{]}  => '&#93;',
        q{^}  => '&#94;',
    );

    sub codehlp {
        my ($hcode) = @_;
        if ( $hcode !~ /&\S*;/xsm ) { $hcode =~ s/;/&#059;/gxsm; }
        $hcode =~ s/([\(\)\-\:\\\/\?\!\]\[\.\^])/$hpkillhash{$1}/gxsm;
        $hcode =~
          s/(&#91\;.+?&#93\;)/<span style="color: #ff0000;">$1<\/span>/isgm;
        $hcode =~
s/(&#91\;&#47\;.+?&#93\;)/<span style="color: #ff0000;">$1<\/span>/isgm;
        return $hcode;
    }
}

sub ContentContainer {
    $MainLayout =~ s/{yabb contents}/$Contents/gsm;
    $MainLayout =~ s/{yabb body}/$Body/gsm;

    $yymain .= qq~$MainLayout~;
    return $yymain;
}

sub DoContents {
    $TempParse = $ContentHeader;

    $BrdID = $mbname;
    $BrdID =~ s/ /_/gsm;
    $SectionName =~ s/{yabb myboardname}/$BrdID/gsm;
    $TempParse =~ s/{yabb section_anchor}/$SectionName/gsm;
    $SectionNam = $SectionName;
    $SectionNam =~ s/_/ /gsm;
    $TempParse  =~ s/{yabb section_name}/$SectionNam/gsm;
    $TempParse  =~ s/{top_img}/$top_img/gsm;
    $Contents .= qq~$TempParse~;

    $Contents .= q~<ul class="help_ul">~;
    $i = 1;
    while ( ${ SectionSub . $i } ) {

        if ( ${ SectionExcl . $i } eq 'yabbc'
            && ( !$enable_ubbc || !$showyabbcbutt ) )
        {
            $i++;
            next;
        }

        $SectionAnchor = ${ SectionSub . $i };
        ${ SectionSub . $i } =~ s/_/ /gxsm;

        $TempParse = $ContentItem;
        $TempParse =~ s/{yabb anchor}/$SectionAnchor/gsm;
        $TempParse =~ s/{yabb myboardname}/$BrdID/gsm;
        $TempParse =~ s/{yabb content}/${SectionSub.$i}/gsm;

        $Contents .= qq~$TempParse~;
        ${ SectionSub . $i } = q{};
        $i++;
    }
    $Contents .= q~</ul>~;
    return $Contents;
}

sub CreateOrderFile {
    opendir HELPDIR, "$helpfile/$language/$help_area";
    @contents = readdir HELPDIR;
    closedir HELPDIR;

    foreach ( sort { uc($a) cmp uc $b } @contents ) {
        ( $name, $extension ) = split /\./xsm, $_;
        next if $extension !~ /help/ism;
        $order_list .= "$name\n";
    }

    fopen( HELPORDER, ">$vardir/$help_area.helporder" )
      or croak(
"couldn't write order file - check permissions on $vardir and $vardir/$help_area.helporder"
      );
    print {HELPORDER} qq~$order_list~ or croak "$croak{'print'} HELPORDER";
    fclose(HELPORDER);
    return;
}

1;
