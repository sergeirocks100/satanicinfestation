###############################################################################
# ManageTemplates.pm                                                          #
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

$managetemplatespmver = 'YaBB 2.6.11 $Revision: 1615 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Templates');
LoadLanguage('Menu');
$admin_images = "$yyhtml_root/Templates/Admin/default";

sub ModifyTemplate {
    is_admin_or_gmod();
    my @tempnames = qw ( Bdaylist BoardIndex Calendar Display Downloads HelpCentre Loginout Memberlist MessageIndex MyCenter MyMessage MyPosts MyProfile Poll Post Other Register Search );
    my ( $fulltemplate, $line );
    if    ( $FORM{'templatefile'} ) { $templatefile = $FORM{'templatefile'} }
    elsif ( $INFO{'templatefile'} ) { $templatefile = $INFO{'templatefile'} }
    else                            { $templatefile = 'default/default.html'; }
    opendir TMPLDIR, $templatesdir;
    @temptemplates = readdir TMPLDIR;
    closedir TMPLDIR;
    $templs = q{};

    foreach my $file (@temptemplates) {
        if ( -e "$templatesdir/$file/$file.html" ) {
            push @templates, $file;
        }
        else {
            next;
        }
    }

    foreach my $name ( sort @templates ) {
        $selected = q{};
        if ( -e "$templatesdir/$name/$name.html" ) {
            $cmp_templatefile = "$name/$name.html";
            if ( $cmp_templatefile eq $templatefile ) {
                $selected = q~ selected="selected"~;
            }
            $templs .=
qq~<option value="$cmp_templatefile"$selected>$cmp_templatefile</option>\n~;
            $selected = q{};
        }
        elsif ( -e "$templatesdir/$name/$name.htm" ) {
            $cmp_templatefile = "$name/$name.htm";
            if ( $cmp_templatefile eq $templatefile ) {
                $selected = q~ selected="selected"~;
            }
            $templs .=
qq~<option value="$cmp_templatefile"$selected>$cmp_templatefile</option>\n~;
            $selected = q{};
        }

        for my $tmp (@tempnames) {
            $tmpnm = lc $tmp;
            ${ 'cmp_' . $tmpnm } = "$name/$tmp.template";
            if ( -e "$templatesdir/$name/$tmp.template" ) {
                $ext = $tmp;
                if ( ${ 'cmp_' . $tmpnm } eq $templatefile ) {
                    $selected = q~ selected="selected"~;
                }
            $templs .=
qq~<option value="$name/$ext.template"$selected>$name/$ext</option>\n~;
            $selected = q{};
            }
        }
    }

    fopen( TMPL, "$templatesdir/$templatefile" );
    while ( $line = <TMPL> ) {
        $line =~ s/[\r\n]//gxsm;
        $line =~ s/&nbsp;/&#38;nbsp;/gxsm;
        $line =~ s/&amp;/&#38;amp;/gxsm;
        $line =~ s/^\s+//gsm;
        $line =~ s/\s+$//gsm;
        FromHTML($line);
        $fulltemplate .= qq~$line\n~;
    }
    fclose(TMPL);

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg">
                $admin_img{'xx'} <b> $templ_txt{'52'}</b> - $templatefile
                <span class="small">(<a href="$adminurl?action=modskin2"><b>$templ_txt{'configure'}</b></a>)</span>
            </td>
        </tr>
    </table>
    <table class="border-space pad-cell" style="margin-bottom:.5em">
            <td class="windowbg2">
                <div style="float: left; width: 40%; padding: 3px;"><label for="templatefile"><b>$templ_txt{'10'}</b>$templ_txt{'10b'}</label></div>
                <div style="float: left; width: 59%;">
                    <form action="$adminurl?action=modtemp" method="post" style="display: inline;" accept-charset="$yymycharset">
                        <select name="templatefile" id="templatefile" size="1" onchange="submit()">
                    $templs
                        </select>
                    </form>
                </div>
            </td>
        </tr>
    </table>
</div>
<form action="$adminurl?action=modtemp2" method="post" style="display: inline;" accept-charset="$yymycharset">
<div class="bordercolor borderstyle rightboxdiv">
    <table class="border-space pad-cell" style="table-layout: fixed; margin-bottom: .5em;">
        <tr>
            <td class="windowbg2 center">
                <textarea rows="20" cols="95" name="template" style="width:99%; height: 350px; font-family:Courier">$fulltemplate</textarea>
                <input type="hidden" name="filename" value="$templatefile" />
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" value="$admin_txt{'10'} $templatefile" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
~;
    $yytitle     = "$admin_txt{'216'}";
    $action_area = 'modtemp';
    AdminTemplate();
    return;
}

sub ModifyTemplate2 {
    is_admin_or_gmod();
    $FORM{'template'} =~ tr/\r//d;
    $FORM{'template'} =~ s/\A\n//xsm;
    $FORM{'template'} =~ s/\n\Z//xsm;
    if   ( $FORM{'filename'} ) { $templatefile = $FORM{'filename'}; }
    else                       { $templatefile = 'default.html'; }
    fopen( TMPL, ">$templatesdir/$templatefile" );

    print {TMPL} "$FORM{'template'}\n" or croak "$croak{'print'} TMPL";
    fclose(TMPL);
    $yySetLocation = qq~$adminurl?action=modtemp;templatefile=$templatefile~;
    redirectexit();
    return;
}

sub ModifySkin {
    is_admin_or_gmod();

    if   ( $INFO{'templateset'} ) { $thistemplate = $INFO{'templateset'}; }
    else                          { $thistemplate = "$template"; }

    foreach my $curtemplate (
        sort { $templateset{$a} cmp $templateset{$b} }
        keys %templateset
      )
    {
        $selected = q{};
        if ( $curtemplate eq $thistemplate ) {
            $selected    = q~ selected="selected"~;
            $akttemplate = $curtemplate;
        }
        $templatesel .=
          qq~<option value="$curtemplate"$selected>$curtemplate</option>\n~;
    }

    (
        $aktstyle,   $aktimages,  $akthead,     $aktboard,
        $aktmessage, $aktdisplay, $aktmycenter, $aktmenutype, $aktthreadtools, $aktposttools
    ) = split /\|/xsm, $templateset{$akttemplate};
    $thisimagesdir = "$yyhtml_root/Templates/Forum/$aktimages";

    $ttoolschecked = q{};
    if ( $INFO{'threadtools'} ne q{} ) {
        if ($INFO{'threadtools'} == 1 ) {
            $ttoolschecked = ' checked="checked"';
        }
    }
    elsif ( $aktthreadtools == 1 ) {
        $ttoolschecked = ' checked="checked"';
    }
    elsif ( $threadtools == 1 ) {
        $ttoolschecked = ' checked="checked"';
    }

    if ( $aktposttools == 1 || $INFO{'posttools'} == 1 ) {
        $ptoolschecked = ' checked="checked"';
    }

    my ( $fullcss, $line );
    if   ( $INFO{'cssfile'} ) { $cssfile = $INFO{'cssfile'}; }
    else                      { $cssfile = "$aktstyle.css"; }
    if   ( $INFO{'imgfolder'} ) { $imgfolder = $INFO{'imgfolder'}; }
    else                        { $imgfolder = "$aktimages"; }
    if   ( $INFO{'headfile'} ) { $headfile = $INFO{'headfile'}; }
    else                       { $headfile = "$akthead.html"; }
    if ( $INFO{'boardfile'} ) { $boardfile = $INFO{'boardfile'}; }
    else                      { $boardfile = "$aktboard/BoardIndex.template"; }
    if ( $INFO{'messagefile'} ) { $messagefile = $INFO{'messagefile'}; }
    else { $messagefile = "$aktmessage/MessageIndex.template"; }
    if ( $INFO{'displayfile'} ) { $displayfile = $INFO{'displayfile'}; }
    else { $displayfile = "$aktdisplay/Display.template"; }

    if ( $INFO{'mycenterfile'} ) { $mycenterfile = $INFO{'mycenterfile'}; }
    else { $mycenterfile = "$aktmycenter/MyCenter.template"; }

    if ( $INFO{'menutype'} ne q{} ) { $UseMenuType = $INFO{'menutype'}; }
    else {
        $UseMenuType = $MenuType;
        if ( $aktmenutype ne q{} ) { $UseMenuType = $aktmenutype; }
    }

    if ( $INFO{'threadtools'} ne q{} ) { $useThreadtools = $INFO{'threadtools'}; }
    else {
        if ( $thistemplate ne 'Forum default' ) { $useThreadtools = $aktthreadtools; }
        else { $useThreadtools = $threadtools; }
    }

    if ( $INFO{'posttools'} ne q{} ) { $usePosttools = $INFO{'posttools'}; }
    else {
        $usePosttools = $posttools;
        if ( $thistemplate ne 'Forum default' ) { $usePosttools = $aktposttools; }
    }

    if   ( $INFO{'selsection'} ) { $selectedsection = $INFO{'selsection'}; }
    else                         { $selectedsection = 'vboard'; }
    my ( $boardsel, $messagesel, $displaysel );
    if ( $selectedsection eq 'vboard' ) { $boardsel = q~ checked="checked"~; }
    elsif ( $selectedsection eq 'vmessage' ) {
        $messagesel = q~ checked="checked"~;
    }
    elsif ( $selectedsection eq 'vdisplay' ) {
        $displaysel = q~ checked="checked"~;
    }
    else { $mycentersel = q~ checked="checked"~; }

    opendir TMPLDIR, "$htmldir/Templates/Forum";
    @styles = readdir TMPLDIR;
    closedir TMPLDIR;
    $forumcss = q{};
    $imgdirs  = q{};
    foreach my $file ( sort @styles ) {
        ( $name, $ext ) = split /\./xsm, $file;
        $selected = q{};
        if ( $ext eq 'css' ) {
            if ( $file eq $cssfile ) {
                $selected = q~ selected="selected"~;
                $viewcss  = $name;
            }
            $forumcss .= qq~<option value="$file"$selected>$name</option>\n~;
        }
        if ( -d "$htmldir/Templates/Forum/$file"
            && $file =~ m{\A[0-9a-zA-Z_\#\%\-\:\+\?\$\&\~\,\@/]+\Z}xsm )
        {
            if ( $imgfolder eq $file ) {
                $imgdirs .=
                  qq~<option value="$file" selected="selected">$file</option>~;
                $viewimg = $file;
            }
            else { $imgdirs .= qq~<option value="$file">$file</option>~; }
        }
    }

    fopen( CSS, "$htmldir/Templates/Forum/$cssfile" )
      or fatal_error( 'cannot_open', "$htmldir/Templates/Forum/$cssfile" );
    while ( $line = <CSS> ) {
        $line =~ s/[\r\n]//gxsm;
        FromHTML($line);
        $fullcss .= qq~$line\n~;
    }
    fclose(CSS);

    opendir TMPLDIR, "$templatesdir";
    @temptemplates = readdir TMPLDIR;
    closedir TMPLDIR;

    foreach my $tmpfile (@temptemplates) {
        if ( -d "$templatesdir/$tmpfile" ) {
            push @templates, $tmpfile;
        }
        else {
            next;
        }
    }

    if    ( $UseMenuType == 0 ) { $menutype0 = ' selected="selected" '; }
    elsif ( $UseMenuType == 1 ) { $menutype1 = ' selected="selected" '; }
    elsif ( $UseMenuType == 2 ) { $menutype2 = ' selected="selected" '; }

    $fullcss =~ s/\s{2,}/ /gsm;
    $boardtemplates   = q{};
    $messagetemplates = q{};
    $displaytemplates = q{};
    $headtemplates    = q{};

    foreach my $name ( sort @templates ) {
        opendir TMPLSDIR, "$templatesdir/$name";
        @templatefiles = readdir TMPLSDIR;
        closedir TMPLSDIR;

        foreach my $file (@templatefiles) {
            if ( $file eq 'index.html' ) { next; }
            $thefile = qq~$name/$file~;
            ( $section, $ext ) = split /\./xsm, $file;
            $hselected = q{};
            if ( $ext eq 'html' && $section eq $name ) {
                $viewhead  = $name;
                if ( $file eq $headfile ) {
                    $hselected = q~ selected="selected"~;
                }
                $headtemplates .=
                  qq~<option value="$file"$hselected>$name</option>\n~;
            }
            $bselected  = q{};
            $mselected  = q{};
            $dselected  = q{};
            $myselected = q{};
            if ( $section eq 'BoardIndex' ) {
                if ( $thefile eq $boardfile ) {
                    $bselected = q~ selected="selected"~;
                    $viewboard = $name;
                }
                $boardtemplates .=
                  qq~<option value="$thefile"$bselected>$name</option>\n~;
            }
            elsif ( $section eq 'MessageIndex' ) {
                if ( $thefile eq $messagefile ) {
                    $mselected   = q~ selected="selected"~;
                    $viewmessage = $name;
                }
                $messagetemplates .=
                  qq~<option value="$thefile"$mselected>$name</option>\n~;
            }
            elsif ( $section eq 'Display' ) {
                if ( $thefile eq $displayfile ) {
                    $dselected   = q~ selected="selected"~;
                    $viewdisplay = $name;
                }
                $displaytemplates .=
                  qq~<option value="$thefile"$dselected>$name</option>\n~;
            }
            elsif ( $section eq 'MyCenter' ) {
                if ( $thefile eq $mycenterfile ) {
                    $myselected   = q~ selected="selected"~;
                    $viewmycenter = $name;
                }
                $mycentertemplates .=
                  qq~<option value="$thefile"$myselected>$name</option>\n~;
            }
        }
    }

    fopen( TMPL, "$templatesdir/$viewhead/$viewhead.html" );
    while ( $line = <TMPL> ) {
        $line =~ s/^\s+//gsm;
        $line =~ s/\s+$//gsm;
        $line =~ s/[\r\n]//gxsm;
        $fulltemplate .= qq~$line\n~;
    }
    fclose(TMPL);

    $tabsep = q{};
    $tabfill = q{};

    $tempforumurl  = $mbname;
    $temptitle     = q~Template Config~;
    $tempnewstitle = qq~<b>$templ_txt{'68'}:</b> ~;
    $tempnews      = qq~$templ_txt{'84'}~;
    $tempstyles =
qq~<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$viewcss.css" type="text/css" />~;
    $tempimages    = qq~$yyhtml_root/Templates/Forum/$viewimg~;
    $tempimagesdir = qq~$htmldir/Templates/Forum/$viewimg~;
    $tempmenu =
qq~<ul><li><span class="tabstyle selected" title="$img_txt{'103'}">$tabfill$img_txt{'103'}$tabfill</span></li>~;
    $tempmenu .=
qq~<li><span class="tabstyle" title="$img_txt{'119'}" style="cursor:help;">$tabfill$img_txt{'119'}$tabfill</span></li>~;
    $tempmenu .=
qq~<li><span class="tabstyle" title="$img_txt{'331'}">$tabfill$img_txt{'331'}$tabfill</span></li>~;
    $tempmenu .=
qq~<li><span class="tabstyle" title="$img_txt{'mycenter'}">$tabfill$img_txt{'mycenter'}$tabfill</span></li>~;
    $tempmenu .=
qq~<li><span class="tabstyle" title="$img_txt{'108'}">$tabfill$img_txt{'108'}$tabfill</span>$tabsep</li></ul>~;
    $tempmenu =~
s/img src\=\"$imagesdir\/(.+?)\"/TmpImgLoc($1, $tempimages, $tempimagesdir)/eisgm;
    $rssbutton = qq~<img src="$imagesdir/rss.png" alt="" />~;
    $tempuname = qq~$templ_txt{'69'} ${$uid.$username}{'realname'}, ~;
    $tempuim   = qq~$templ_txt{'70'} <a id="ims">0 $templ_txt{'71'}</a>.~;
    $temptime  = timeformat( $date, 1 );
    my $tempsearchbox =
qq~<form><input type="text" name="search" size="16" id="search1" value="$img_txt{'182'}" style="font-size: 11px;" onfocus="txtInFields(this, '$img_txt{'182'}');" onblur="txtInFields(this, '$img_txt{'182'}')" /><input type="image" src="$imagesdir/search.png" alt="$maintxt{'searchimg'} $showsearchboxnum $maintxt{'searchimg2'}" style="background-color: transparent; margin-right: 5px; vertical-align: middle;" /></form>
~;
    $altbrdcolor = q~windowbg2~;
    $boardtable = q~id="General"~;
    $templatejump  = 1;
    $tempforumjump = jumpto();

    $fulltemplate =~ s/({|<)yabb bottom(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb fixtop(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb javascripta(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb javascript(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb xml_lang(}|>)/$abbr_lang/gsm;
    $fulltemplate =~ s/({|<)yabb mycharset(}|>)/$yymycharset/gsm;
    $fulltemplate =~ s/({|<)yabb title(}|>)/$temptitle/gsm;
    $fulltemplate =~ s/({|<)yabb style(}|>)/$tempstyles/gsm;
    $fulltemplate =~ s/({|<)yabb html_root(}|>)/$yyhtml_root/gsm;
    $fulltemplate =~ s/({|<)yabb images(}|>)/$tempimages/gsm;
    $fulltemplate =~ s/({|<)yabb uname(}|>)/$tempuname/gsm;
    $fulltemplate =~ s/({|<)yabb boardlink(}|>)/$tempforumurl/gsm;
    $fulltemplate =~ s/({|<)yabb navigation(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb searchbox(}|>)/$tempsearchbox/gsm;
    $fulltemplate =~ s/({|<)yabb im(}|>)/$tempuim/gsm;
    $fulltemplate =~ s/({|<)yabb time(}|>)/$temptime/gsm;
    $fulltemplate =~ s/({|<)yabb langChooser(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb menu(}|>)/$temp21menu/gsm;
    $fulltemplate =~ s/({|<)yabb tabmenu(}|>)/$tempmenu/gsm;
    $fulltemplate =~ s/({|<)yabb rss(}|>)/$rssbutton/gsm;
    $fulltemplate =~ s/<span id="newsdiv"><\/span>/<span id="newsdiv">$tempnews<\/span>/gsm;
    $fulltemplate =~ s/({|<)yabb newstitle(}|>)/$tempnewstitle/gsm;
    $fulltemplate =~ s/({|<)yabb copyright(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb debug(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb forumjump(}|>)/$tempforumjump/gsm;
    $fulltemplate =~ s/({|<)yabb freespace(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb navback(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb admin_alert(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb tabadd(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb addtab(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb syntax_js(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb grayscript(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb high(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb ubbc(}|>)//gsm;
    $fulltemplate =~ s/({|<)yabb news(}|>)//gsm;
## Mod Hook fulltemplate
## End Mod Hook fulltemplate

    if ( $selectedsection eq 'vboard' ) {
        $boardtempl = BoardTempl( $viewboard, $tempimages, $tempimagesdir );
        $fulltemplate =~ s/({|<)yabb main(}|>)/$boardtempl/gsm;
        $fulltemplate =~ s/({|<)yabb colboardtable(}|>)//gsm;
        $fulltemplate =~ s/({|<)yabb boardtable(}|>)/$boardtable/gsm;
        $fulltemplate =~ s/({|<)yabb altbrdcolor(}|>)/$altbrdcolor/gsm;
    }
    elsif ( $selectedsection eq 'vmessage' ) {
        $messagetempl =
          MessageTempl( $viewmessage, $tempimages, $tempimagesdir );
        $fulltemplate =~ s/({|<)yabb main(}|>)/$messagetempl/gsm;
    }
    elsif ( $selectedsection eq 'vdisplay' ) {
        $displaytempl =
          DisplayTempl( $viewdisplay, $tempimages, $tempimagesdir );
        $fulltemplate =~ s/({|<)yabb main(}|>)/$displaytempl/gsm;
    }
    elsif ( $selectedsection eq 'vmycenter' ) {
        $mycentertempl =
          MyCenterTempl( $viewmycenter, $tempimages, $tempimagesdir );
        $fulltemplate =~ s/({|<)yabb main(}|>)/$mycentertempl/gsm;
    }
    $fulltemplate =~
s/img src\=\"$tempimages\/(.+?)\"/TmpImgLoc($1, $tempimages, $tempimagesdir)/eisgm;
    $fulltemplate =~
      s/<a href="http:\/\/validator.w3.org\/check\/referer">.+?<\/a>//gsm;
    $fulltemplate =~
s/<a href="http:\/\/jigsaw.w3.org\/css\-validator\/validator\?uri\={yabb url}">.+?<\/a>//gsm;
    $fulltemplate =~ s/[\n\r]//gxsm;
    ToHTML($fulltemplate);

    $yymain .= qq~
<form action="$adminurl?action=modskin2" name="selskin" method="post" style="display: inline;" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg">
                $admin_img{'xx'} <b> $templ_txt{'6'}</b>
                <span class="small">(<a href="$adminurl?action=modtemp;"><b>$templ_txt{'edit_files'}</b></a>)</span>
            </td>
        </tr>
    </table>
    <table class="border-space" style="margin-bottom: -1px;">
        <tr>
            <td class="windowbg2 center">
                <iframe id="TempManager" name="TempManager" style="border:0" scrolling="yes"></iframe>
            </td>
        </tr>
    </table>
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="windowbg2">
                <div style="float: left; width: 30%; padding: 3px;"><label for="templateset"><b>$templ_txt{'10'}</b>$templ_txt{'10b'}</label></div>
                <div style="float: left; width: 69%;">
                    <input type="hidden" name="button" value="0" />
                    <select name="templateset" id="templateset" size="1" onchange="submit();">
                        $templatesel
                    </select>
~;
    if ( $akttemplate ne 'Forum default' ) {
        $yymain .=
qq~                        <input type="submit" value="$templ_txt{'14'}" onclick="document.selskin.button.value = '3'; return confirm('$templ_txt{'15'} $thistemplate?')" class="button" />~;
    }
    $yymain .= qq~
                </div>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div style="float: left; width: 30%; padding: 3px;">
                        <b>$templ_txt{'11'}</b><br /><span class="small">$templ_txt{'7'}</span>
                </div>
                <div style="float: left; width: 69%;">
                    <div style="float: left; width: 32%; text-align: left;">
                        <label for="menutype"><span class="small">$templ_txt{'521'}</span></label><br />
                            <select name="menutype" id="menutype" size="1" style="width: 90%;">
                                <option value="0"$menutype0>$admin_txt{'521a'}</option>
                                <option value="1"$menutype1>$admin_txt{'521b'}</option>
                                <option value="2"$menutype2>$admin_txt{'521c'}</option>
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <label for="threadtools"><span class="small">$templ_txt{'528'}</span></label><br />
                            <input type="checkbox" name="threadtools" id="threadtools" value="1"$ttoolschecked />
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <label for="headfile" class="small">$templ_txt{'527'}</label><br />
                            <input type="checkbox" name="posttools" id="posttools" value="1"$ptoolschecked />
                        </div>
                        <br style="clear:left" />
                        <div style="float: left; width: 32%; text-align: left;">
                            <label for="cssfile"><span class="small">$templ_txt{'1'}</span></label><br />
                            <select name="cssfile" id="cssfile" size="1" style="width: 90%;">
                                $forumcss
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <label for="imgfolder"><span class="small">$templ_txt{'8'}</span></label><br />
                            <select name="imgfolder" id="imgfolder" size="1" style="width: 90%;">
                                $imgdirs
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <label for="headfile" class="small">$templ_txt{'2'}</label><br />
                            <select name="headfile" id="headfile" size="1" style="width: 90%;">
                                $headtemplates
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <input type="radio" name="selsection" id="bradio" value="vboard" class="windowbg2" style="border: 0; vertical-align: middle;"$boardsel /><label for="bradio" class="small">$templ_txt{'3'}</label><br />
                            <select name="boardfile" id="boardfile" size="1" style="width: 90%;">
                                $boardtemplates
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <input type="radio" name="selsection" id="mradio" value="vmessage" class="windowbg2" style="border: 0; vertical-align: middle;"$messagesel /><label for="mradio" class="small">$templ_txt{'4'}</label><br />
                            <select name="messagefile" id="messagefile" size="1" style="width: 90%;">
                                $messagetemplates
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <input type="radio" name="selsection" id="dradio" value="vdisplay" class="windowbg2" style="border: 0; vertical-align: middle;"$displaysel /><label for="dradio" class="small">$templ_txt{'5'}</label><br />
                            <select name="displayfile" id="displayfile" size="1" style="width: 90%;">
                                $displaytemplates
                            </select>
                        </div>
                        <div style="float: left; width: 32%; text-align: left;">
                            <input type="radio" name="selsection" id="myradio" value="vmycenter" class="windowbg2" style="border: 0; vertical-align: middle;"$mycentersel /><label for="myradio" class="small">$templ_txt{'67'}</label><br />
                            <select name="mycenterfile" id="mycenterfile" size="1" style="width: 90%;">
                                $mycentertemplates
                            </select>
                        </div>
                    </div>
                </td>
            </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
           <label for="saveas"><b>$templ_txt{'12'}</b></label>
            <input type="hidden" name="tempname" value="$fulltemplate" />
            <input type="text" name="saveas" id="saveas" value="$thistemplate" size="30" maxlength="50" />
            <input type="submit" value="$templ_txt{'13'}" onclick="document.selskin.button.value = '2';" class="button" />
            <input type="submit" value="$templ_txt{'9'}" onclick="document.selskin.button.value = '1';" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
<script type="text/javascript">
function updateTemplate() {
        var thetemplate = document.selskin.tempname.value;
        thetemplate=thetemplate.replace(/\\&amp\\;/g, "&");
        thetemplate=thetemplate.replace(/\\&quot\\;/g, '"');
        thetemplate=thetemplate.replace(/\\&nbsp\\;/g, " ");
        thetemplate=thetemplate.replace(/\\&\\#124\\;/g, "|");
        thetemplate=thetemplate.replace(/\\&lt\\;/g, "<");
        thetemplate=thetemplate.replace(/\\&gt\\;/g, ">");
        TempManager.document.open("text/html");
        TempManager.document.write(thetemplate);
        TempManager.document.close();
}
document.onload = updateTemplate();
</script>
~;
    $yytitle     = $templ_txt{'6'};
    $action_area = 'modskin';
    AdminTemplate();
    return;
}

sub ModifySkin2 {
    is_admin_or_gmod();
    $formattemp = $FORM{'templateset'};
    formatTempname();
    if ( $FORM{'button'} == 1 ) {
        $mythreads = 1;
        if ( $FORM{'threadtools'} eq q{} ) {
            $mythreads = 0;
        }
        $yySetLocation =
qq~$adminurl?action=modskin;templateset=$formattemp;cssfile=$FORM{'cssfile'};imgfolder=$FORM{'imgfolder'};headfile=$FORM{'headfile'};boardfile=$FORM{'boardfile'};messagefile=$FORM{'messagefile'};displayfile=$FORM{'displayfile'};mycenterfile=$FORM{'mycenterfile'};menutype=$FORM{'menutype'};selsection=$FORM{'selsection'};threadtools=$mythreads;posttools=$FORM{'posttools'}~;

    }
    elsif ( $FORM{'button'} == 2 ) {
        $template_name = $FORM{'saveas'};
        if ( $template_name eq 'default' ) {
            fatal_error('no_delete_default');
        }
        if ( $template_name !~
            m{\A[0-9a-zA-Z_\ \.\#\%\-\:\+\?\$\&\~\.\,\@/]+\Z}sm
            || $template_name eq q{} )
        {
            fatal_error('invalid_template');
        }
        ( $template_css, undef, undef ) = split /\./xsm, $FORM{'cssfile'};
        $template_images = $FORM{'imgfolder'};
        ( $template_head,     undef ) = split /\./xsm, $FORM{'headfile'};
        ( $template_board,    undef ) = split /\//xsm, $FORM{'boardfile'};
        ( $template_message,  undef ) = split /\//xsm, $FORM{'messagefile'};
        ( $template_display,  undef ) = split /\//xsm, $FORM{'displayfile'};
        ( $template_mycenter, undef ) = split /\//xsm, $FORM{'mycenterfile'};
        ( $template_menutype, undef ) = split /\//xsm, $FORM{'menutype'};
        $template_threadtools = $FORM{'threadtools'} || 0;
        $template_posttools = $FORM{'posttools'} || 0;
        $formattemp = $FORM{'saveas'};
        formatTempname();
        UpdateTemplates( $template_name, 'save' );
        $yySetLocation =
qq~$adminurl?action=modskin;templateset=$formattemp;cssfile=$FORM{'cssfile'};imgfolder=$FORM{'imgfolder'};headfile=$FORM{'headfile'};boardfile=$FORM{'boardfile'};messagefile=$FORM{'messagefile'};displayfile=$FORM{'displayfile'};mycenterfile=$FORM{'mycenterfile'};menutype=$FORM{'menutype'};selsection=$FORM{'selsection'};threadtools=$mythreads;posttools=$FORM{'posttools'}~;

    }
    elsif ( $FORM{'button'} == 3 ) {
        $template_name = $FORM{'templateset'};
        if ( $template_name eq 'default' ) {
            fatal_error('no_delete_default');
        }
        if ( $template_name eq 'Forum default' ) {
            fatal_error('no_delete_default');
        }
        UpdateTemplates( $template_name, 'delete' );
        $yySetLocation = qq~$adminurl?action=modskin~;
    }
    else {
        $yySetLocation = qq~$adminurl?action=modskin;templateset=$formattemp~;
    }
    redirectexit();
    return;
}

sub formatTempname {
    my ($formattemp) = @_;
    $formattemp =~ s/\%/%25/gsm;
    $formattemp =~ s/\#/%23/gsm;
    $formattemp =~ s/\+/%2B/gsm;
    $formattemp =~ s/\,/%2C/gsm;
    $formattemp =~ s/\-/%2D/gsm;
    $formattemp =~ s/\./%2E/gsm;
    $formattemp =~ s/\@/%40/gsm;
    $formattemp =~ s/\^/%5E/gsm;
    return;
}

sub TmpImgLoc {
    my @x = @_;
    if ( !-e "$x[2]/$x[0]" ) {
        $thisimgloc = qq~img src="$yyhtml_root/Templates/Forum/default/$x[0]"~;
    }
    else { $thisimgloc = qq~img src="$x[1]/$x[0]"~; }
    return $thisimgloc;
}

sub BoardTempl {
    my @x = @_;
    LoadLanguage('BoardIndex');
    my $tmpimagesdir = $imagesdir;
    $imagesdir = qq~$x[1]~;
    require "$templatesdir/$x[0]/BoardIndex.template";

    if ( -e ("$vardir/mostlog.txt") ) {
        fopen( MOSTUSERS, "$vardir/mostlog.txt" );
        @mostentries = <MOSTUSERS>;
        fclose(MOSTUSERS);
        ( $mostmemb,  $datememb )  = split /\|/xsm, $mostentries[0];
        ( $mostguest, $dateguest ) = split /\|/xsm, $mostentries[1];
        ( $mostusers, $dateusers ) = split /\|/xsm, $mostentries[2];
        ( $mostbots,  $datebots )  = split /\|/xsm, $mostentries[3];
        chomp $datememb;
        chomp $dateguest;
        chomp $dateusers;
        chomp $datebots;
        $themostmembdate  = timeformat($datememb);
        $themostguestdate = timeformat($dateguest);
        $themostuserdate  = timeformat($dateusers);
        $themostbotsdate  = timeformat($datebots);
        $themostuser      = $mostusers;
        $themostmemb      = $mostmemb;
        $themostguest     = $mostguest;
        $themostbots      = $mostbots;
    }
    else {
        $themostmembdate  = timeformat($date);
        $themostguestdate = timeformat($date);
        $themostuserdate  = timeformat($date);
        $themostbotsdate  = timeformat($date);
        $themostuser      = 23;
        $themostmemb      = 12;
        $themostguest     = 19;
        $themostbots      = 4;
    }

    $grpcolors = q{};
    ( $title, undef, undef, $color, $noshow ) = split /\|/xsm,
      $Group{'Administrator'}, 5;
    my $admcolor = qq~$color~;
    if ( $color && $noshow != 1 ) {
        $grpcolors .=
qq~<div class="small" style="float: left; width: 49%;"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
    }
    ( $title, undef, undef, $color, $noshow ) =
      split /\|/xsm, $Group{'Global Moderator'}, 5;
    if ( $color && $noshow != 1 ) {
        $grpcolors .=
qq~<div class="small" style="float: left; width: 49%;"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
    }
    ( $title, undef, undef, $color, $noshow ) =
      split /\|/xsm, $Group{'Mid Moderator'}, 5;
    if ( $color && $noshow != 1 ) {
        $grpcolors .=
qq~<div class="small" style="float: left; width: 49%;"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
    }
    foreach my $nopostamount ( sort { $a <=> $b } keys %NoPost ) {
        ( $title, undef, undef, $color, $noshow ) = split /\|/xsm,
          $NoPost{$nopostamount}, 5;
        if ( $color && $noshow != 1 ) {
            $grpcolors .=
qq~<div class="small" style="float: left; width: 49%;"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
        }
    }
    foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
        ( $title, undef, undef, $color, $noshow ) = split /\|/xsm,
          $Post{$postamount}, 5;
        if ( $color && $noshow != 1 ) {
            $grpcolors .=
qq~<div class="small" style="float: left; width: 49%;"><span style="color: $color;"><b>lllll</b></span> $title</div>~;
        }
    }

    my $latestmemberlink =
qq~$boardindex_txt{'201'} <a href="javascript:;"><b>${$uid.$username}{'realname'}</b></a>.<br />~;
    my $tempims =
qq~$boardindex_txt{'795'} <a href="javascript:;"><b>2</b></a> $boardindex_txt{'796'} $boardindex_imtxt{'24'} <a href="javascript:;"><b>2</b></a> $boardindex_imtxt{'26'}.~;
    my $tempforumurl    = $mbname;
    my $tempnew         = qq~$admin_img{'off'}~;
    my $tempcurboard    = $templ_txt{'77'};
    my $tempcurboardurl = q~javascript:;~;
    my $tempboardanchor = $templ_txt{'78'};
    my $tempbddescr     = $templ_txt{'79'};
    my $tempshowmods =
qq~$boardindex_txt{'63'}: $templ_txt{'74'}<br />$boardindex_txt{'63a'}: $templ_txt{'74a'}~;
    my $templastposttme = timeformat($date);
    my $templastpostlink =
      qq~<a href="javascript:;">$img{'lastpost'}</a> $templastposttme~;
    my $templastposter =
      qq~<a href="javascript:;">${$uid.$username}{'realname'}</a>~;
    my $tmplasttopiclink = qq~<a href="javascript:;">$templ_txt{'80'}</a>~;
    $tempcatlink =
qq~<img src="$x[1]/cat_collapse.png" alt="" /> <a href="javascript:;">$templ_txt{'81'}</a>~;
    my $templatecat = $catheader;
    $templatecat =~ s/({|<)yabb catlink(}|>)/$tempcatlink/gsm;
    my $tmptemplateblock = $templatecat;
    my $templastpostdate = timeformat($date);
    $templastpostdate = qq~($templastpostdate).<br />~;
    my $temprecentposts =
qq~$boardindex_txt{'791'} <select style="font-size: 7pt;"><option>--</option><option>5</option></select> $boardindex_txt{'792'} $boardindex_txt{'793'}~;
    my $tempguestson =
      qq~<span class="small">$boardindex_txt{'141'}: <b>2</b></span>~;
    my $tempbotson =
      qq~<span class="small">$boardindex_txt{'143'}: <b>3</b></span>~;
    my $tempbotlist =
      q~<span class="small">Googlebot (1), MSN Search (2)</span>~;
    my $tempuserson =
      qq~<span class="small">$boardindex_txt{'142'}: <b>1</b></span>~;
    my $tempusers =
qq~<span class="small" style="color: $admcolor;"><b>${$uid.$username}{'realname'}</b></span><br />~;
    my $tempmembercount = q~<b>2</b>~;
    my $tempboardpic =
      qq~ <img src="$imagesdir/boards.png" alt="$tempcurboard" />~;

    for my $i ( 1 .. 2 ) {
        my $templateblock = $boardblock;
        $templateblock =~ s/({|<)yabb new(}|>)/$tempnew/gsm;
        $templateblock =~ s/({|<)yabb boardrss(}|>)//gsm; ### RSS on Board Index ###
        $templateblock =~ s/({|<)yabb boardanchor(}|>)/$tempboardanchor_$i/gsm;
        $templateblock =~ s/({|<)yabb boardurl(}|>)/$tempcurboardurl/gsm;
        $templateblock =~ s/({|<)yabb boardpic(}|>)/$tempboardpic/gsm;
        $templateblock =~ s/({|<)yabb boardname(}|>)/$tempcurboard $i/gsm;
        $templateblock =~ s/({|<)yabb boardviewers(}|>)/$boardviewers/gsm;
        $templateblock =~ s/({|<)yabb boarddesc(}|>)/$tempbddescr/gsm;
        $templateblock =~ s/({|<)yabb moderators(}|>)/$tempshowmods/gsm;
        $templateblock =~ s/({|<)yabb threadcount(}|>)/$i/gsm;
        $templateblock =~ s/({|<)yabb messagecount(}|>)/$i/gsm;
        $templateblock =~ s/({|<)yabb lastpostlink(}|>)/$templastpostlink/gsm;
        $templateblock =~ s/({|<)yabb lastposter(}|>)/$templastposter/gsm;
        $templateblock =~ s/({|<)yabb lasttopiclink(}|>)/$tmplasttopiclink/gsm;
        $tmptemplateblock .= $templateblock;
    }
    $tmptemplateblock .= $catfooter;
    $boardindex_template =~ s/({|<)yabb pollshowcase(}|>)//sm;
    $boardindex_template =~ s/({|<)yabb catsblock(}|>)/$tmptemplateblock/gsm;
    require Sources::Menu;
    $collapselink = SetImage('collapse', $UseMenuType);
    $markalllink  = SetImage('markallread', $UseMenuType);
    $menusep = q{&nbsp;};
    if ( $UseMenuType == 1 ) {
        $menusep = q{ | };
    }
    my $templasttopiclink =
qq~$boardindex_txt{'236'} <a href="javascript:;"><b>$templ_txt{'80'}</b></a>~;

    $boardhandellist =~ s/({|<)yabb collapse(}|>)/$menusep$collapselink/gsm;
    $boardhandellist =~ s/({|<)yabb expand(}|>)//gsm;
    $boardhandellist =~ s/({|<)yabb markallread(}|>)/$menusep$markalllink/gsm;
    $boardhandellist =~ s/\Q$menusep//ism;
    $boardindex_template =~
      s/({|<)yabb boardhandellist(}|>)/$boardhandellist/gsm;
    $boardindex_template =~ s/({|<)yabb catimage(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb catrss(}|>)//gsm; ### RSS on Board Index ###
    $boardindex_template =~
      s/img src\=\"$tmpimagesdir\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;

    $boardindex_template =~ s/({|<)yabb newmsg start(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb newmsg icon(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb newmsg(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb newmsg end(}|>)//gsm;

    $boardindex_template =~ s/({|<)yabb totaltopics(}|>)/3/gsm;
    $boardindex_template =~ s/({|<)yabb totalmessages(}|>)/3/gsm;
    $boardindex_template =~
      s/({|<)yabb lastpostlink(}|>)/$templasttopiclink/gsm;
    $boardindex_template =~ s/({|<)yabb lastpostdate(}|>)/$templastpostdate/gsm;
    $boardindex_template =~ s/({|<)yabb recentposts(}|>)/$temprecentposts/gsm;
    $boardindex_template =~ s/({|<){yabb recenttopics(}|>)//gsm;

    $boardindex_template =~ s/({|<)yabb mostusers(}|>)/$themostuser/gsm;
    $boardindex_template =~ s/({|<)yabb mostmembers(}|>)/$themostmemb/gsm;
    $boardindex_template =~ s/({|<)yabb mostguests(}|>)/$themostguest/gsm;
    $boardindex_template =~ s/({|<)yabb mostbots(}|>)/$themostbots/gsm;
    $boardindex_template =~ s/({|<)yabb mostusersdate(}|>)/$themostuserdate/gsm;
    $boardindex_template =~
      s/({|<)yabb mostmembersdate(}|>)/$themostmembdate/gsm;
    $boardindex_template =~
      s/({|<)yabb mostguestsdate(}|>)/$themostguestdate/gsm;
    $boardindex_template =~ s/({|<)yabb mostbotsdate(}|>)/$themostbotsdate/gsm;
    $boardindex_template =~ s/({|<)yabb groupcolors(}|>)/$grpcolors/gsm;

    $boardindex_template =~ s/({|<)yabb membercount(}|>)/$tempmembercount/gsm;
    $boardindex_template =~ s/({|<)yabb expandmessages(}|>)/$temp_expandmessages/gsm;
    $boardindex_template =~ s/({|<)yabb latestmember(}|>)/$latestmemberlink/gsm;
    $boardindex_template =~ s/({|<)yabb ims(}|>)/$tempims/gsm;
    $boardindex_template =~ s/({|<)yabb users(}|>)/$tempuserson/gsm;
    $boardindex_template =~ s/({|<)yabb spc(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb onlineusers(}|>)/$tempusers/gsm;
    $boardindex_template =~ s/({|<)yabb guests(}|>)/$tempguestson/gsm;
    $boardindex_template =~ s/({|<)yabb onlineguests(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb bots(}|>)/$tempbotson/gsm;
    $boardindex_template =~ s/({|<)yabb onlinebots(}|>)/$tempbotlist/gsm;
    $boardindex_template =~ s/({|<)yabb caldisplay(}|>)/$cal_display/gsm;
    $boardindex_template =~ s/({|<)yabb sharedlogin(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb selecthtml(}|>)//gsm;
    $boardindex_template =~ s/({|<)yabb new_load(}|>)//gsm;
    $boardindex_template =~
                  s/({|<)yabb subboardlist(}|>)//gsm;
    $boardindex_template =~
                  s/({|<)yabb messagedropdown(}|>)//gsm;
## Mod Hook BoardIndex ##
## End Mod Hook BoardIndex ##
    $boardindex_template =~
      s/img src\=\"$x[1]\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $boardindex_template =~ s/^\s+//gsm;
    $boardindex_template =~ s/\s+$//gsm;
    $imagesdir = $tmpimagesdir;
    return $boardindex_template;
}

sub MessageTempl {
    my @x = @_;
    LoadLanguage('MessageIndex');
    my $tmpimagesdir = $imagesdir;
    $imagesdir = "$x[1]";
    require "$templatesdir/$x[0]/MessageIndex.template";
    my $tempcatnm   = $templ_txt{'72'};
    my $tempboardnm = $templ_txt{'73'};
    my $tempmodslink =
qq~($messageindex_txt{'298'}: $templ_txt{'74'} - $messageindex_txt{'298a'}: $templ_txt{'74a'})~;
    my $tempbdescrip     = $templ_txt{'79'};
    my $temppageindextgl = qq~<img src="$x[1]/xx.gif" alt="" />~;
    my $temppageindex =
qq~<span class="small" style="vertical-align: middle;"> <b>$messageindex_txt{'139'}:</b> 1</span>~;
    my $tempthreadpic = qq~<img src="$x[1]/thread.gif" alt="" />~;
    my $tempmicon     = qq~<img src="$x[1]/xx.gif" alt="" />~;
    my $tempnew       = qq~<img src="$x[1]/new.gif" alt="" />~;
    my $tempmsublink  = $templ_txt{'83'};
    my $tempmname     = ${ $uid . $username }{'realname'};
    my $templastpostlink =
      qq~<img src="$x[1]/lastpost.gif" alt="" /> $templ_txt{'82'}~;
    my $templastposter = $tempmname;
    my $tempyabbicons  = qq~<img src="$x[1]/thread.gif" alt="" /> $messageindex_txt{'457'}<br /><img src="$x[1]/hotthread.gif" alt="" /> $messageindex_txt{'454'} x $messageindex_txt{'454a'}<br /><img src="$x[1]/veryhotthread.gif" alt="" /> $messageindex_txt{'455'} x $messageindex_txt{'454a'}<br /><img src="$x[1]/locked.gif" alt="" /> $messageindex_txt{'456'}<br /><img src="$x[1]/locked_moved.gif" alt="" /> $messageindex_txt{'845'}
~;
    my $tempyabbadminicons .= qq~<img src="$x[1]/hide.gif" alt="" /> $messageindex_txt{'458'}<br /><img src="$x[1]/hidesticky.gif" alt="" /> $messageindex_txt{'459'}<br /><img src="$x[1]/hidelock.gif" alt="" /> $messageindex_txt{'460'}<br /><img src="$x[1]/hidestickylock.gif" alt="" /> $messageindex_txt{'461'}<br /><img src="$x[1]/announcement.gif" alt="" /> $messageindex_txt{'779a'}<br /><img src="$x[1]/announcementlock.gif" alt="" /> $messageindex_txt{'779b'}<br /><img src="$x[1]/sticky.gif" alt="" /> $messageindex_txt{'779'}<br /><img src="$x[1]/stickylock.gif" alt="" /> $messageindex_txt{'780'}
~;

    $bdpic = qq~ <img src="$x[1]/boards.png" alt="$templ_txt{'72'}" /> ~;
    $message_permalink = $messageindex_txt{'10'};
    $temp_attachment =
      qq~<img src="$x[1]/paperclip.gif" alt="$messageindex_txt{'5'}" />~;

    $messageindex_template =~ s/({|<)yabb home(}|>)/$mbname/gsm;
    $messageindex_template =~ s/({|<)yabb category(}|>)/$tempcatnm/gsm;
    $messageindex_template =~ s/({|<)yabb board(}|>)/$tempboardnm/gsm;
    $messageindex_template =~ s/({|<)yabb moderators(}|>)/$tempmodslink/gsm;
    $messageindex_template =~ s/({|<)yabb sortsubject(}|>)/$messageindex_txt{'70'}/gsm;
    $messageindex_template =~ s/({|<)yabb sortstarter(}|>)/$messageindex_txt{'109'}/gsm;
    $messageindex_template =~ s/({|<)yabb sortanswer(}|>)/$messageindex_txt{'110'}/gsm;
    $messageindex_template =~ s/({|<)yabb sortlastpostim(}|>)/$messageindex_txt{'22'}/gsm;
    $messageindex_template =~ s/({|<)yabb bdpicture(}|>)/$bdpic/gsm;
    $messageindex_template =~ s/({|<)yabb threadcount(}|>)/1/gsm;
    $messageindex_template =~ s/({|<)yabb messagecount(}|>)/2/gsm;
    $boarddescription =~ s/({|<)yabb boarddescription(}|>)/$tempbdescrip/gsm;
    $messageindex_template =~ s/({|<)yabb description(}|>)/$boarddescription/gsm;
    $messageindex_template =~ s/({|<)yabb colspan(}|>)/7/gsm;

    $messageindex_template =~
      s/({|<)yabb pageindex top(}|>)/$temppageindex1/gsm;
    $messageindex_template =~
      s/({|<)yabb pageindex bottom(}|>)/$temppageindex1/gsm;
    $messageindex_template =~ s/({|<)yabb new_load(}|>)//gsm;

    require Sources::Menu;
    $notify_board = SetImage('notify', $UseMenuType);
    $markalllink  = SetImage('markboardread', $UseMenuType);
    $postlink     = SetImage('newthread', $UseMenuType);
    $polllink     = SetImage('createpoll', $UseMenuType);
    $menusep = q{&nbsp;};
    if ( $UseMenuType == 1 ) {
        $menusep = q{ | };
    }
    $topichandellist = q~{yabb notify button}{yabb markall button}~;
    if ( $useThreadtools == 1 ) {
        $notify_board = SetImage('notify', 3);
        ($notify_board_img, $notify_board_txt ) = split /[|]/xsm, $notify_board;
        $markall_board = SetImage('markboardread', 3);
        ($markall_board_img, $markall_board_txt ) = split /[|]/xsm, $markall_board;
        $topichandellist = qq~<td class="post_tools center template" style="width:10em"><div class="post_tools_a">
        <a href="javascript:quickLinks('threadtools1')">$maintxt{'62'}</a>
    </div>
    </td>
    <td class="center bottom" style="padding:0px; width:0">
    <div class="right cursor toolbutton_b">
        <ul class="post_tools_menu" id="threadtools" onmouseover="keepLinks('threadtools')" onmouseout="TimeClose('threadtools')">
            <li><div class="toolbutton_a" style="background-image: url($notify_board_img)">$notify_board_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($markall_board_img)">$markall_board_txt</div></li>
        </ul>
    </div>~;
    }
    $outside_threadtools = q~{yabb new post button}{yabb new poll button}~;
    $outside_threadtools =~ s/{yabb new post button}/$menusep$postlink/gsm;
    $outside_threadtools =~ s/{yabb new poll button}/$menusep$polllink/gsm;
    $topichandellist =~ s/{yabb notify button}/$menusep$notify_board/gsm;
    $topichandellist =~ s/{yabb markall button}/$menusep$markalllink/gsm;
    $topichandellist     = $outside_threadtools . $topichandellist;

    $topichandellist =~ s/\Q$menusep//ism;

    $messageindex_template =~
      s/({|<)yabb topichandellist(}|>)/$topichandellist/gsm;
    $messageindex_template =~
      s/({|<)yabb topichandellist2(}|>)/$topichandellist/gsm;
    $messageindex_template =~
      s/class="post_tools center" style="width:10em"/class="right"/gsm;

    $messageindex_template =~ s/({|<)yabb pageindex(}|>)/$temppageindex/gsm;
    $messageindex_template =~
      s/({|<)yabb pageindex toggle(}|>)/$temppageindextgl/gsm;
    $messageindex_template =~ s/({|<)yabb admin column(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb outsidethreadtools(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb topicpreview(}|>)//gsm;

    my $tempbar = $threadbar;
    $tempbar =~ s/({|<)yabb admin column(}|>)//gsm;
    $tempbar =~ s/({|<)yabb threadpic(}|>)/$tempthreadpic/gsm;
    $tempbar =~ s/({|<)yabb icon(}|>)/$tempmicon/gsm;
    $tempbar =~ s/({|<)yabb new(}|>)/$tempnew/gsm;
    $tempbar =~ s/({|<)yabb poll(}|>)//gsm;
    $tempbar =~ s/({|<)yabb favorite(}|>)//gsm;
    $tempbar =~ s/({|<)yabb subjectlink(}|>)/$tempmsublink/gsm;
    $tempbar =~ s/({|<)yabb pages(}|>)//gsm;
    $tempbar =~ s/({|<)yabb attachmenticon(}|>)/$temp_attachment/gsm;
    $tempbar =~ s/({|<)yabb starter(}|>)/$tempmname/gsm;
    $tempbar =~ s/({|<)yabb starttime(}|>)/ timeformat($date)/egsm;
    $tempbar =~ s/({|<)yabb replies(}|>)/2/gsm;
    $tempbar =~ s/({|<)yabb views(}|>)/12/gsm;
    $tempbar =~ s/({|<)yabb lastpostlink(}|>)/$templastpostlink/gsm;
    $tempbar =~ s/({|<)yabb lastposter(}|>)/$templastposter/gsm;

    if ( $accept_permalink == 1 ) {
        $tempbar =~ s/({|<)yabb permalink(}|>)/$message_permalink/gsm;
    }
    else {
        $tempbar =~ s/({|<)yabb permalink(}|>)//gsm;
    }

    $tmptempbar .= $tempbar;

    $messageindex_template =~ s/({|<)yabb threadblock(}|>)/$tmptempbar/gsm;
    $messageindex_template =~ s/({|<)yabb modupdate(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb modupdateend(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb stickyblock(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb adminfooter(}|>)//gsm;
    $messageindex_template =~ s/({|<)yabb icons(}|>)/$tempyabbicons/gsm;
    $messageindex_template =~
      s/({|<)yabb admin icons(}|>)/$tempyabbadminicons/gsm;
    $messageindex_template =~ s/({|<)yabb access(}|>)//gsm;
    $messageindex_template =~
      s/img src\=\"$tmpimagesdir\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $messageindex_template =~
      s/img src\=\"$x[1]\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $messageindex_template =~ s/^\s+//gsm;
    $messageindex_template =~ s/\s+$//gsm;
    $imagesdir = $tmpimagesdir;
    return $messageindex_template;
}

sub DisplayTempl {
    my @x = @_;
    LoadLanguage('Display');
    my $tmpimagesdir = $imagesdir;
    $imagesdir = $x[1];
    require "$templatesdir/$x[0]/Display.template";
    (
        $title,     $stars,      $starpic,    $color,     $noshow,
        $viewperms, $topicperms, $replyperms, $pollperms, $attachperms
    ) = split /\|/xsm, $Group{'Administrator'};

    my $template_home = qq~<span class="nav">$mbname</span>~;
    my $tempcatnm     = $templ_txt{'72'};
    my $tempboardnm   = $templ_txt{'73'};
    my $tempmodslink =
qq~($display_txt{'298'}: $templ_txt{'74'} - $display_txt{'298a'}: $templ_txt{'74a'})~;
    my $template_prev    = $display_txt{'768'};
    my $template_next    = $display_txt{'767'};
    my $temppageindextgl = qq~<img src="$x[1]/xx.gif" alt="" />~;
    my $temppageindex1 =
qq~<span class="small" style="vertical-align: middle;"> <b>$display_txt{'139'}:</b> 1</span>~;

## Make Buttons ##
    require Sources::Menu;
    $replybutton          = SetImage('reply', $UseMenuType);
    $pollbutton           = SetImage('addpoll', $UseMenuType);
    $notify               = SetImage('notify', $UseMenuType);
    $favorite             = SetImage('favorites', $UseMenuType);
    $template_sendtopic   = SetImage('sendtopic', $UseMenuType);
    $template_print       = SetImage('print', $UseMenuType);
    $template_alertmod    = SetImage('alertmod', $UseMenuType);
    $template_quote       = SetImage('quote', $UseMenuType);
    $template_modify      = SetImage('modify', $UseMenuType);
    $template_split       = SetImage('admin_split', $UseMenuType);
    $template_delete      = SetImage('delete', $UseMenuType);
    $template_print_post  = SetImage('printp', $UseMenuType);
    $template_email  = SetImage('email_sm', $UseMenuType);
    $template_pm     = SetImage('message_sm', $UseMenuType);
    $template_remove = SetImage('admin_rem', $UseMenuType);
    $template_splice = SetImage('admin_move_split_splice', $UseMenuType);
    $template_lock   = SetImage('admin_lock', $UseMenuType);
    $template_hide   = SetImage('hide', $UseMenuType);
    $template_sticky = SetImage('admin_sticky', $UseMenuType);
    $replybutton          = qq~$menusep$replybutton~;
    $pollbutton           = qq~$menusep$pollbutton~;
    $notify               = qq~$menusep$notify~;
    $favorite             = qq~$menusep$favorite~;
    $template_sendtopic   = qq~$menusep$template_sendtopic~;
    $template_print       = qq~$menusep$template_print~;
    $menusep = q{&nbsp;};
    if ( $UseMenuType == 1 ) {
        $menusep = q{ | };
    }
    $outside_threadtools = q~{yabb reply}{yabb poll}~;
    $threadhandellist = q~{yabb notify}{yabb favorite}{yabb sendtopic}{yabb print}{yabb markunread}~;
    if ( $useThreadtools == 1 ) {
        $notify               = SetImage('notify', 3);
        ($notify_board_img, $notify_board_txt ) = split /[|]/xsm, $notify;
        $favorite             = SetImage('favorites', 3);
        ($fav_board_img, $fav_board_txt ) = split /[|]/xsm, $favorite;
        $template_sendtopic   = SetImage('sendtopic', 3);
        ($send_board_img, $send_board_txt ) = split /[|]/xsm, $template_sendtopic;
        $template_print       = SetImage('print', 3);
        ($print_board_img, $print_board_txt ) = split /[|]/xsm, $template_print;
        $threadhandellist = qq~<td class="post_tools center template" style="width:10em"><div class="post_tools_a">
        <a href="javascript:quickLinks('threadtools')">$maintxt{'62'}</a>
    </div>
    </td>
    <td class="center bottom" style="padding:0px; width:0">
    <div class="right cursor toolbutton_b">
        <ul class="post_tools_menu" id="threadtools" onmouseover="keepLinks('threadtools')" onmouseout="TimeClose('threadtools')">
            <li><div class="toolbutton_a" style="background-image: url($notify_board_img)">$notify_board_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($fav_board_img)">$fav_board_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($send_board_img)">$send_board_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($print_board_img)">$print_board_txt</div></li>
        </ul>
    </div>~;
    }

    $outside_threadtools =~ s/{yabb reply}/$menusep$replybutton/gsm;
    $outside_threadtools =~ s/{yabb poll}/$menusep$pollbutton/gsm;
    my $template_threadimage = qq~<img src="$x[1]/thread.gif" alt="" />~;
    my $threadurl            = $templ_txt{'75'};
    $template_alertmod    = qq~$menusep$template_alertmod~;
    $template_quote       = qq~$menusep$template_quote~;
    $template_modify      = qq~$menusep$template_modify~;
    $template_split       = qq~$menusep$template_split~;
    $template_delete      = qq~$menusep$template_delete~;
    $template_print_post  = qq~$menusep$template_print_post~;
    my $memberinfo        = qq~<span class="small"><b>$title</b></span>~;
    my $usernamelink =
qq~<span style="color: $color;"><b>${$uid.$username}{'realname'}</b></span><br />~;

    for ( 1 .. 5 ) {
        $star .= qq(<img src="$x[1]/$starpic" alt="*" />);
    }
    my $msub     = $templ_txt{'76'};
    my $msgimg   = qq~<img src="$x[1]/xx.gif" alt="" />~;
    my $messdate = timeformat($date);
    my $template_postinfo =
      qq~$display_txt{'21'}: ${$uid.$username}{'postcount'}<br />~;
    my $template_usertext = qq~${$uid.$username}{'usertext'}<br />~;
    my $px = 'px';
    my $avatar =
qq~<img src="$facesurl/elmerfudd.gif" alt="" style="max-width: 50px; max-height: 50px" />~;
    my $message =
      qq~$templ_txt{'65'}<br /><a href="javascript:;">$templ_txt{'66'}</a>~;
    $template_email  = qq~$menusep$template_email~;
    $template_pm     = qq~$menusep$template_pm~;
    my $ipimg           = qq~<img src="$imagesdir/ip.gif" alt="" />~;
    $template_remove = qq~$menusep$template_remove~;
    $template_splice = qq~$menusep$template_splice~;
    $template_lock   = qq~$menusep$template_lock~;
    $template_hide   = qq~$menusep$template_hide~;
    $template_sticky = qq~$menusep$template_sticky~;

    $online = qq~<span class="useronline">$maintxt{'60'}</span>~;
    for my $i ( 0 .. 1 ) {
        my $outblock        = $messageblock;
        my $posthandelblock = $posthandellist;
        my $contactblock    = $contactlist;

        if ( $i == 0 ) {
            $css          = q~windowbg~;
            $counterwords = q{};
        }
        else {
            $css          = q~windowbg2~;
            $counterwords = "$display_txt{'146'} #$i";
        }
        $posthandelblock =~ s/({|<)yabb modalert(}|>)/$template_alertmod/gsm;
        $posthandelblock =~ s/({|<)yabb quote(}|>)/$template_quote/gsm;
        $posthandelblock =~ s/({|<)yabb modify(}|>)/$template_modify/gsm;
        $posthandelblock =~ s/({|<)yabb split(}|>)/$template_split/gsm;
        $posthandelblock =~ s/({|<)yabb delete(}|>)/$template_delete/gsm;
        $posthandelblock =~ s/({|<)yabb admin(}|>)/$template_admin/gsm;
        $posthandelblock =~ s/({|<)yabb print_post(}|>)/$template_print_post/gsm;
        $posthandelblock =~ s/\Q$menusep//ism;
        $outside_posttools = qq~{yabb quote}{yabb markquote}~;
        $posthandellist = qq~{yabb modalert}{yabb print_post}{yabb modify}{yabb split}{yabb delete}~;
        if ( $usePosttools == 1 ) {
            $template_alertmod    = SetImage('alertmod', 3);
            ($template_alertmod_img, $template_alertmod_txt ) = split /[|]/xsm, $template_alertmod;
            $template_modify      = SetImage('modify', 3);
            ($template_modify_img, $template_modify_txt ) = split /[|]/xsm, $template_modify;
            $template_split       = SetImage('admin_split', 3);
            ($template_split_img, $template_split_txt ) = split /[|]/xsm, $template_split;
            $template_delete      = SetImage('delete', 3);
            ($template_delete_img, $template_delete_txt ) = split /[|]/xsm, $template_delete;
            $template_print_post  = SetImage('printp', 3);
            ($template_print_post_img, $template_print_post_txt ) = split /[|]/xsm, $template_print_post;
            $posthandelblock = qq~<td class="post_tools center dividerbot template" style="width:100px; height: 2em; vertical-align:middle"><div class="post_tools_a">
        <a href="javascript:quickLinks('threadtools')">$maintxt{'63'}</a>
    </div>
    </td>
    <td class="center bottom" style="padding:0px; width:0">
    <div class="right cursor toolbutton_b">
        <ul class="post_tools_menu" id="threadtools" onmouseover="keepLinks('threadtools')" onmouseout="TimeClose('threadtools')">
            <li><div class="toolbutton_a" style="background-image: url($template_modify_img)">$template_modify_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($template_split_img)">$template_split_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($template_delete_img)">$template_delete_txt</div></li>
            <li><div class="toolbutton_a" style="background-image: url($template_print_post_img)">$template_print_post_txt</div></li>
        </ul>
    </div>~;
        }
        $contactblock =~ s/({|<)yabb email(}|>)/$template_email/gsm;
        $contactblock =~ s/({|<)yabb profile(}|>)//gsm;
        $contactblock =~ s/({|<)yabb pm(}|>)/$template_pm/gsm;
        $contactblock =~ s/({|<)yabb www(}|>)//gsm;
        $contactblock =~ s/({|<)yabb aim(}|>)//gsm;
        $contactblock =~ s/({|<)yabb yim(}|>)//gsm;
        $contactblock =~ s/({|<)yabb icq(}|>)//gsm;
        $contactblock =~ s/({|<)yabb gtalk(}|>)//gsm;
        $contactblock =~ s/({|<)yabb skype(}|>)//gsm;
        $contactblock =~ s/({|<)yabb myspace(}|>)//gsm;
        $contactblock =~ s/({|<)yabb facebook(}|>)//gsm;
        $contactblock =~ s/({|<)yabb twitter(}|>)//gsm;
        $contactblock =~ s/({|<)yabb youtube(}|>)//gsm;
        $contactblock =~ s/({|<)yabb addbuddy(}|>)//gsm;
        $contactblock =~ s/\Q$menusep//ism;

        $outblock =~ s/({|<)yabb images(}|>)/$tmpimagesdir/gsm;
        $outblock =~ s/({|<)yabb messageoptions(}|>)//gsm;
        $outblock =~ s/({|<)yabb memberinfo(}|>)/$memberinfo/gsm;
        $outblock =~ s/({|<)yabb userlink(}|>)/$usernamelink/gsm;
        $outblock =~ s/({|<)yabb stars(}|>)/$star/gsm;
        $outblock =~ s/({|<)yabb subject(}|>)/$msub/gsm;
        $outblock =~ s/({|<)yabb msgimg(}|>)/$msgimg/gsm;
        $outblock =~ s/({|<)yabb msgdate(}|>)/$messdate/gsm;
        $outblock =~ s/({|<)yabb replycount(}|>)/$counterwords/gsm;
        $outblock =~ s/({|<)yabb count(}|>)//gsm;
        $outblock =~ s/({|<)yabb att(}|>)//gsm;
        $outblock =~ s/({|<)yabb css(}|>)/$css/gsm;
        $outblock =~ s/({|<)yabb gender(}|>)//gsm;
        $outblock =~ s/({|<)yabb zodiac(}|>)//gsm;
        $outblock =~ s/({|<)yabb age(}|>)//gsm;
        $outblock =~ s/({|<)yabb regdate(}|>)//gsm;
        $outblock =~ s/({|<)yabb ext_prof(}|>)/$template_ext_prof/gsm;
        $outblock =~ s/({|<)yabb location(}|>)//gsm;
        $outblock =~ s/({|<)yabb isbuddy(}|>)//gsm;
        $outblock =~ s/({|<)yabb useronline(}|>)/$online/gsm;
        $outblock =~ s/({|<)yabb postinfo(}|>)/$template_postinfo/gsm;
        $outblock =~ s/({|<)yabb usertext(}|>)/$template_usertext/gsm;
        $outblock =~ s/({|<)yabb userpic(}|>)/$avatar/gsm;
        $outblock =~ s/({|<)yabb message(}|>)/$message/gsm;
        $outblock =~ s/({|<)yabb showatt(}|>)//gsm;
        $outblock =~ s/({|<)yabb showatthr(}|>)//gsm;
        $outblock =~ s/({|<)yabb modified(}|>)//gsm;
        $outblock =~ s/({|<)yabb signature(}|>)//gsm;
        $outblock =~ s/({|<)yabb signaturehr(}|>)//gsm;
        $outblock =~ s/({|<)yabb ipimg(}|>)/$ipimg/gsm;
        $outblock =~ s/({|<)yabb ip(}|>)//gsm;
        $outblock =~ s/({|<)yabb permalink(}|>)//gsm;
        $outblock =~ s/({|<)yabb posthandellist(}|>)/$posthandelblock/gsm;
        $outblock =~ s/({|<)yabb outsideposttools(}|>)//gsm;
        $outblock =~ s/({|<)yabb admin(}|>)//gsm;
        $outblock =~ s/({|<)yabb contactlist(}|>)/$contactblock/gsm;
## Mod Hook Outblock ##
## End Mod Hook Outblock ##
        $tempoutblock .= $outblock;
    }
    $threadhandellist     = $outside_threadtools . $threadhandellist;
    $threadhandellist =~ s/({|<)yabb notify(}|>)/$notify/gsm;
    $threadhandellist =~ s/({|<)yabb favorite(}|>)/$favorite/gsm;
    $threadhandellist =~ s/({|<)yabb sendtopic(}|>)/$template_sendtopic/gsm;
    $threadhandellist =~ s/({|<)yabb print(}|>)/$template_print/gsm;
    $threadhandellist =~ s/({|<)yabb markunread(}|>)//gsm;
    $threadhandellist =~ s/<td class="dividerbot" colspan="3" style="vertical-align:middle;">/<td class="dividerbot" colspan="2" style="vertical-align:middle;">/gsm;
    $threadhandellist =~ s/<td class="post_tools center dividerbot" style="width:100px; height: 2em; vertical-align:middle">/<td class="center dividerbot" style="height: 2em; vertical-align:middle">/gsm;
    $threadhandellist =~ s/\Q$menusep//ism;

    $adminhandellist =~ s/({|<)yabb remove(}|>)/$template_remove/gsm;
    $adminhandellist =~ s/({|<)yabb splice(}|>)/$template_splice/gsm;
    $adminhandellist =~ s/({|<)yabb lock(}|>)/$template_lock/gsm;
    $adminhandellist =~ s/({|<)yabb hide(}|>)/$template_hide/gsm;
    $adminhandellist =~ s/({|<)yabb sticky(}|>)/$template_sticky/gsm;
    $adminhandellist =~ s/({|<)yabb multidelete(}|>)/$template_multidelete/gsm;
    $adminhandellist =~ s/\Q$menusep//ism;

    $display_template =~ s/({|<)yabb pollmain(}|>)//gsm;
    $display_template =~ s/({|<)yabb topicviewers(}|>)//gsm;

    $display_template =~ s/({|<)yabb home(}|>)/$template_home/gsm;
    $display_template =~ s/({|<)yabb category(}|>)/$tempcatnm/gsm;
    $display_template =~ s/({|<)yabb board(}|>)/$tempboardnm/gsm;
    $display_template =~ s/({|<)yabb moderators(}|>)/$tempmodslink/gsm;
    $display_template =~ s/({|<)yabb prev(}|>)/$template_prev/gsm;
    $display_template =~ s/({|<)yabb next(}|>)/$template_next/gsm;
    $display_template =~
      s/({|<)yabb pageindex toggle(}|>)/$temppageindextgl/gsm;
    $display_template =~ s/({|<)yabb pageindex top(}|>)/$temppageindex1/gsm;
    $display_template =~ s/({|<)yabb pageindex bottom(}|>)/$temppageindex1/gsm;
    $display_template =~ s/({|<)yabb bookmarks(}|>)//gsm; # Social Bookmarks
    $display_template =~
      s/({|<)yabb threadhandellist(}|>)/$threadhandellist/gsm;
    $display_template =~
      s/({|<)yabb threadhandellist2(}|>)/$threadhandellist/gsm;
    $display_template =~ s/({|<)yabb outsidethreadtools(}|>)//gsm;
    $display_template =~ s/({|<)yabb threadimage(}|>)/$template_threadimage/gsm;
    $display_template =~ s/({|<)yabb threadurl(}|>)/$threadurl/gsm;
    $display_template =~ s/({|<)yabb views(}|>)/12/gsm;
    $display_template =~ s/({|<)yabb multistart(}|>)//gsm;
    $display_template =~ s/({|<)yabb multiend(}|>)//gsm;
    $display_template =~ s/({|<)yabb postsblock(}|>)/$tempoutblock/gsm;
    $display_template =~ s/({|<)yabb adminhandellist(}|>)/$adminhandellist/gsm;
    $display_template =~ s/({|<)yabb forumselect(}|>)//gsm;
    $display_template =~ s/({|<)yabb guestview(}|>)//gsm;
    $display_template =~ s/({|<)yabb reason(}|>)//gsm;
    $display_template =~ s/<td class="dividerbot" style="vertical-align:middle;">/<td class="dividerbot" style="vertical-align:middle;" colspan="2">/gsm;
    $display_template =~ s/<td class="post_tools center dividerbot" style="width:100px; height: 2em; vertical-align:middle">/<td class="center dividerbot" style="height: 2em; vertical-align:middle">/gsm;
    $display_template =~ s/class="post_tools center" style="width:100px"/class="right"/gsm;
    $display_template =~ s/class="post_tools center" style="width:10em"/class="right"/gsm;
    $display_template =~ s/class="windowbg2 vtop" style="height:10em" colspan="3"/class="windowbg2 vtop" colspan="4" style="height:10em"/gsm;
    $display_template =~ s/class="windowbg vtop" style="height:10em" colspan="3"/class="windowbg vtop" colspan="4" style="height:10em"/gsm;
    $display_template =~ s/class="windowbg2 bottom" style="height:12px" colspan="3"/class="windowbg2 bottom" colspan="4" style="height:12px"/gsm;
    $display_template =~ s/class="windowbg bottom" style="height:12px" colspan="3"/class="windowbg bottom" colspan="4" style="height:12px"/gsm;
    $display_template =~ s/class="windowbg2 bottom" colspan="3"/class="windowbg2 bottom" colspan="4"/gsm;
    $display_template =~ s/class="windowbg bottom" colspan="3"/class="windowbg bottom" colspan="4"/gsm;
    $display_template =~ s/class="windowbg2 bottom dividertop" colspan="3"/class="windowbg2 bottom dividertop" colspan="4"/gsm;
    $display_template =~ s/class="windowbg bottom dividertop" colspan="3"/class="windowbg bottom dividertop" colspan="4"/gsm;
    $display_template =~
      s/img src\=\"$tmpimagesdir\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $display_template =~
      s/img src\=\"$x[1]\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $display_template =~ s/^\s+//gsm;
    $display_template =~ s/\s+$//gsm;
    $imagesdir = $tmpimagesdir;
    return $display_template;
}

sub MyCenterTempl {
    my @x = @_;
    LoadLanguage('InstantMessage');
    LoadLanguage('MyCenter');
    my $tmpimagesdir = $imagesdir;
    $imagesdir = $x[1];
    require "$templatesdir/$x[0]/MyCenter.template";

    $tabsep = q{};
    $tabfill = qq~<img src="$imagesdir/tabfill.gif" alt="" />~;

    if (   $PM_level == 1
        || ( $PM_level == 2 && ( $iamadmin || $iamgmod || $iammod ) )
        || ( $PM_level == 3 && ( $iamadmin || $iamgmod ) ) )
    {
        $yymcmenu .=
qq~<span title="$mc_menus{'messages'}" class="selected">$tabsep$tabfill$mc_menus{'messages'}$tabfill</span>
                ~;
    }

    $yymcmenu .=
qq~$tabsep<span title="$mc_menus{'profile'}">$tabfill$mc_menus{'profile'}$tabfill</span>~;
    $yymcmenu .=
qq~$tabsep<span title="$mc_menus{'posts'}">$tabfill$mc_menus{'posts'}$tabfill</span>~;
    $yymcmenu .= qq~$tabsep~;

    $mycenter_template =~ s/{yabb mcviewmenu}/$MCViewMenu/gsm;
    $mycenter_template =~ s/{yabb mcmenu}/$yymcmenu/gsm;
    $mycenter_template =~ s/{yabb mcpmmenu}/$MCPmMenu/gsm;
    $mycenter_template =~ s/{yabb mcprofmenu}/$MCProfMenu/gsm;
    $mycenter_template =~ s/{yabb mcpostsmenu}/$MCPostsMenu/gsm;
    $mycenter_template =~ s/{yabb mcglobformstart}/$MCGlobalFormStart/gsm;
    $mycenter_template =~
      s/{yabb mcglobformend}/ ($MCGlobalFormStart ? "<\/form>" : q{}) /esm;
    $mycenter_template =~ s/{yabb mccontent}/$MCContent/gsm;
    $mycenter_template =~ s/{yabb mctitle}/$mctitle/gsm;
    $mycenter_template =~ s/{yabb selecthtml}/$selecthtml/gsm;

    $mycenter_template =~
      s/img src\=\"$tmpimagesdir\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $mycenter_template =~
      s/img src\=\"$x[1]\/(.+?)\"/TmpImgLoc($1, $x[1], $x[2])/eisgm;
    $mycenter_template =~ s/^\s+//gsm;
    $mycenter_template =~ s/\s+$//gsm;
    $imagesdir = $tmpimagesdir;
    return $mycenter_template;
}

sub UpdateTemplates {
    my ( $tempelement, $tempjob ) = @_;
    if ( $tempjob eq 'save' ) {
        $templateset{"$tempelement"} = "$template_css";
        $templateset{"$tempelement"} .= "|$template_images";
        $templateset{"$tempelement"} .= "|$template_head";
        $templateset{"$tempelement"} .= "|$template_board";
        $templateset{"$tempelement"} .= "|$template_message";
        $templateset{"$tempelement"} .= "|$template_display";
        $templateset{"$tempelement"} .= "|$template_mycenter";
        $templateset{"$tempelement"} .= "|$template_menutype";
        $templateset{"$tempelement"} .= "|$template_threadtools";
        $templateset{"$tempelement"} .= "|$template_posttools";
    }
    elsif ( $tempjob eq 'delete' ) {
        delete $templateset{$tempelement};
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');
    return;
}

sub ModifyStyle {
    is_admin_or_gmod();
    my ( $fullcss, $line, $csstype );
    $admincs = 0;
    if ( $FORM{'cssfile'} ) {
        $cssfile = $FORM{'cssfile'};
        $csstype = qq~$htmldir/Templates/Forum/$cssfile~;
    }
    elsif ( $FORM{'admcssfile'} ) {
        $cssfile = $FORM{'admcssfile'};
        $csstype = qq~$htmldir/Templates/Admin/$cssfile~;
        $admincs = 1;
    }
    else { $cssfile = 'default.css';
        $csstype = qq~$htmldir/Templates/Forum/$cssfile~;
    }
    opendir TMPLDIR, "$htmldir/Templates/Forum";
    @styles = readdir TMPLDIR;
    closedir TMPLDIR;

    $forumcss = qq~<option value="" disabled="disabled">--</option>\n~;
    foreach my $file ( sort @styles ) {
        ( $name, $ext ) = split /\./xsm, $file;
        $selected = q{};
        if ( $ext eq 'css' ) {
            if ( $file eq $cssfile && !$admincs ) {
                $selected = q~ selected="selected"~;
            }
            $forumcss .= qq~<option value="$file"$selected>$name</option>\n~;
        }
    }

    opendir TMPLDIR, "$htmldir/Templates/Admin";
    @astyles = readdir TMPLDIR;
    closedir TMPLDIR;
    $admincss = qq~<option value="" disabled="disabled">--</option>\n~;
    foreach my $file ( sort @astyles ) {
        ( $name, $ext ) = split /\./xsm, $file;
        $selected = q{};
        if ( $ext eq 'css' ) {
            if ( $file eq $cssfile && $admincs ) {
                $selected = q~ selected="selected"~;
            }
            $admincss .= qq~<option value="$file"$selected>$name</option>\n~;
        }
    }

    fopen( CSS, "$csstype" ) or fatal_error( 'cannot_open', "$csstype" );
    while ( $line = <CSS> ) {
        $line =~ s/[\r\n]//gxsm;
        $line =~ s/&nbsp;/&#38;nbsp;/gsm;
        $line =~ s/&amp;/&#38;amp;/gsm;
        FromHTML($line);
        $fullcss .= qq~$line\n~;
    }
    fclose(CSS);

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <form action="$adminurl?action=modcss;cssfile=$cssfile" name="modcss" method="post" style="display: inline;" accept-charset="$yymycharset">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg">
                $admin_img{'xx'} <b> $templ_txt{'51'}</b> - $cssfile &nbsp;
                <input type="submit" name="wysiwyg" id="wysiwyg" value=" wysiwyg " class="button" />
                <input type="button" name="source" id="source" value=" source " disabled="disabled" />
            </td>
        </tr>
    </table>
    </form>
    <table class="border-space pad-cell" style="margin-bottom:.5em">
        <tr>
            <td class="windowbg2">
                <div style="float: left; width: 30%; padding: 3px;"><b>$templ_txt{'1'}</b></div>
                <div style="float: left; width: 69%;">
                    <form action="$adminurl?action=modstyle" name="selcss" method="post" style="display: inline;" accept-charset="$yymycharset">
                    <div class="small" style="float: left; width: 25%;"><label for="cssfile" style="font-weight:bold">$templ_txt{'forum'}:</label><br />
                    <select name="cssfile" id="cssfile" size="1" style="width: 90%;" onchange="if(this.options[this.selectedIndex].value) { document.aselcss.admcssfile.selectedIndex = '0'; submit(); }">
                        $forumcss
                    </select>
                    <br />
                    </div>
                    </form>
                    <form action="$adminurl?action=modstyle" name="aselcss" method="post" style="display: inline;" accept-charset="$yymycharset">
                    <div class="small" style="float: left; width: 25%;"><label for="admcssfile" style="font-weight:bold">$templ_txt{'admincenter'}:</label><br />
                    <select name="admcssfile" id="admcssfile" size="1" style="width: 90%;" onchange="if(this.options[this.selectedIndex].value) { document.selcss.cssfile.selectedIndex = '0'; submit(); }">
                        $admincss
                    </select>
                    <br />
                    </div>
                    </form>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor borderstyle rightboxdiv">
    <form action="$adminurl?action=modstyle2" method="post" accept-charset="$yymycharset">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="windowbg2 center">
                <input type="hidden" name="filename" value="$cssfile" />
                <input type="hidden" name="type" value="$admincs" />
                <textarea rows="20" cols="95" name="css" style="width: 99%; height: 350px;; font-family:Courier">$fullcss</textarea>
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
                <input type="submit" value="$admin_txt{'10'} $cssfile" class="button" />
            </td>
        </tr>
    </table>
    </form>
</div>

~;
    $yytitle     = $templ_txt{'1'};
    $action_area = 'modcss';
    AdminTemplate();
    return;
}

sub ModifyStyle2 {
    is_admin_or_gmod();
    $FORM{'css'} =~ tr/\r//d;
    $FORM{'css'} =~ s/\A\n//xsm;
    $FORM{'css'} =~ s/\n\Z//xsm;

    if   ( $FORM{'filename'} ) { $cssfile = $FORM{'filename'}; }
    else                       { $cssfile = 'default.css'; }
    if ( $FORM{'type'} ) {
        fopen( CSS, ">$htmldir/Templates/Admin/$cssfile" )
          || fatal_error( 'cannot_open', "$htmldir/Templates/Admin/$cssfile", 1 );
    }
    else {
        fopen( CSS, ">$htmldir/Templates/Forum/$cssfile" )
          || fatal_error( 'cannot_open', "$htmldir/Templates/Forum/$cssfile", 1 );
    }
    print {CSS} "$FORM{'css'}\n" or croak "$croak{'print'} CSS";
    fclose(CSS);
    $yySetLocation = qq~$adminurl?action=modcss;cssfile=$cssfile~;
    redirectexit();
    return;
}

sub ModifyCSS {
    is_admin_or_gmod();

    if   ( $INFO{'templateset'} ) { $thistemplate = $INFO{'templateset'}; }
    else                          { $thistemplate = "$template"; }

    while ( ( $curtemplate, $value ) = each %templateset ) {
        if ( $curtemplate eq $thistemplate ) { $akttemplate = $curtemplate; }
    }

    ( $aktstyle, $aktimages, $akthead, $aktboard, $aktmessage, $aktdisplay, $aktmenutype, $aktthreadtools, $aktposttools ) =
      split /\|/xsm, $templateset{$akttemplate};

    my ( $fullcss, $line );
    if   ( $INFO{'cssfile'} ) { $cssfile = $INFO{'cssfile'}; }
    else                      { $cssfile = "$aktstyle.css"; }

    $tempimages = qq~$yyhtml_root/Templates/Forum/$aktimages~;
    my $istabbed = 0;

    $cssbuttons = 0;
    $stylestr = q{};

    opendir TMPLDIR, "$htmldir/Templates/Forum";
    @styles = readdir TMPLDIR;
    closedir TMPLDIR;
    $forumcss = q{};
    $imgdirs  = q{};
    foreach my $file ( sort @styles ) {
        if ( $file ne 'calscroller.css' && $file ne 'setup.css' ) {
        ( $name, $ext ) = split /\./xsm, $file;
        $selected = q{};
            if ( $ext eq 'css' ) {
                if ( $file eq $cssfile ) {
                    $selected = q~ selected="selected"~;
                    $viewcss  = $name;
                }
                $forumcss .= qq~<option value="$file"$selected>$name</option>\n~;
            }
        }
    }

    fopen( CSS, "$htmldir/Templates/Forum/$cssfile" )
      or fatal_error( 'cannot_open', "$htmldir/Templates/Forum/$cssfile" );
    @thecss = <CSS>;
    fclose(CSS);
    foreach my $style_sgl (@thecss) {
        $style_sgl =~ s/[\n\r]//gxsm;
        $style_sgl =~ s/\A\s*//xsm;
        $style_sgl =~ s/\s*\Z//xsm;
        $style_sgl =~ s/\t//gsm;
        $style_sgl =~ s/^\s+//gsm;
        $style_sgl =~ s/\s+$//gsm;
        $style_sgl =~ s/\.\/default/$yyhtml_root\/Templates\/Forum\/default/gsm;
        $style_sgl =~ s/\.\/$viewcss/$yyhtml_root\/Templates\/Forum\/$viewcss/gsm;
        $style_sgl =~ s/\.\.\/\.\.\/Buttons/$yyhtml_root\/Buttons/gsm;
        $stylestr .= qq~$style_sgl ~;
    }
    $stylestr =~ s/\s{2,}/ /gsm;
    my (
        $selstyl,            $postsstyle,    $seperatorstyle,
        $bodycontainerstyle, $bodystyle,     $containerstyle,
        $titlestyle,         $titlestyle_a,  $categorystyle,
        $categorystyle_a,    $window1style,  $window2style,
        $inputstyle,         $textareastyle, $selectstyle,
        $quotestyle,         $codestyle,     $editbgstyle,
        $highlightstyle,     $gen_fontsize,  $userinfostyle
    );

    $gen_fontsize =
q~              <select name="cssfntsize" id="cssfntsize" style="vertical-align: middle;" onchange="previewFont()">~;
    for my $i ( 7 .. 20 ) {
        $gen_fontsize .= qq~                <option value="$i">$i</option>~;
    }
    $gen_fontsize .= q~
                </select>~;
    $gen_fontface =
q~              <select name="cssfntface" id="cssfntface" style="vertical-align: middle;" onchange="previewFontface()">
                    <option value="verdana">Verdana</option>
                    <option value="helvetica">Helvetica</option>
                    <option value="arial">Arial</option>
                    <option value="courier">Courier</option>
                    <option value="courier new">Courier New</option>
                </select>~;
    $gen_borderweigth =
q~              <select name="borderweigth" id="borderweigth" style="vertical-align: middle;" onchange="previewBorder()">~;
    for my $i ( 0 .. 5 ) {
        $gen_borderweigth .= qq~<option value="$i">$i</option>~;
    }
    $gen_borderweigth .= q~
                </select>~;
    $gen_borderstyle =
qq~             <select name="borderstyle" id="borderstyle" style="vertical-align: middle;" onchange="previewBorder()">
                    <option value="solid">$templ_txt{'43'}</option>
                    <option value="dashed">$templ_txt{'44'}</option>
                    <option value="dotted">$templ_txt{'45'}</option>
                    <option value="double">$templ_txt{'46'}</option>
                    <option value="groove">$templ_txt{'47'}</option>
                    <option value="ridge">$templ_txt{'48'}</option>
                    <option value="inset">$templ_txt{'49'}</option>
                    <option value="outset">$templ_txt{'50'}</option>
                </select>~;

    if ( $stylestr =~ /body/sm ) {
        $bodystyle = $stylestr;
        $bodystyle =~ s/.*?(body\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
qq~                 <option value="$bodystyle" selected="selected">$templ_txt{'25'}</option>\n~;
    }
    if ( $stylestr =~ /\#container/sm ) {
        $containerstyle = $stylestr;
        $containerstyle =~ s/.*?(\#container.*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$containerstyle'>$templ_txt{'26'}</option>\n~;
    }
    if ( $stylestr =~ /\#header/sm ) {
        $headerstyle = $stylestr;
        $headerstyle =~ s/.*?(\#header.*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$headerstyle'>$templ_txt{'26b'}</option>\n~;
    }
    if ( $stylestr =~ /\#header a/sm ) {
        $headerastyle = $stylestr;
        $headerastyle =~ s/.*?(\#header a.*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$headerastyle'>$templ_txt{'26c'}</option>\n~;
    }
    if ( $stylestr =~ /\.tabmenu/sm ) {
        $istabbed = 1;
        $tabmenustyle = $stylestr;
        $tabmenustyle =~ s/.*?(\.tabmenu\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$tabmenustyle'>$templ_txt{'tabmenu'}</option>\n~;
    }
    if ( $stylestr =~ /\.tabtitle/sm && $istabbed ) {
        $tabtitlestyle = $stylestr;
        $tabtitlestyle =~ s/.*?(\.tabtitle\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$tabtitlestyle'>$templ_txt{'tabtitle'}</option>\n~;
        if ( $stylestr =~ /\.tabtitle a, .tabtitle-bottom a/ ) {
            $tabtitlestyle_a = $stylestr;
            $tabtitlestyle_a =~ s/.*?(\.tabtitle a, \.tabtitle-bottom a\s*?\{.+?\}).*/$1/igsm;
            $selstyl .=
qq~                 <option value='$tabtitlestyle_a'>$templ_txt{'tabtitlea'}</option>\n~;
        }
    }
    if ( $stylestr =~ /\.buttonleft/sm && $stylestr =~ /\.buttonright/sm && $stylestr =~ /\.buttonimage/sm && $stylestr =~ /\.buttontext/sm ) {
        $cssbuttons = 1;
        $buttonstyle = $stylestr;
        $buttonstyle =~ s/.*?(\.buttontext\s*?\{.+?\}).*/$1/igsm;
        $selstyl .= qq~<option value='$buttonstyle'>$templ_txt{'buttontext'}</option>\n~;
        $prevtext = $buttonstyle;
        $prevtext =~ s/\.buttontext\s*?\{(.+?)\}/$1/igsm;
        $drawtxtpos = $prevtext;
        $drawtxtpos =~ m/.*?top\s*?\:\s*?(\d{1,2})px.*/ism;
        $viewtxty = $1;
        $viewtxty .= 'px';
        $drawpos4 = ($1 * 5) + 213;
        $drawpos4 .= 'px';
        $buttonleftstyle = $stylestr;
        $buttonleftstyle =~ s/.*?(\.buttonleft\s*?\{.+?\}).*/$1/igsm;
        $buttonleftbg = qq~<input type="hidden" id="buttonleftbg" name="buttonleftbg" value="$buttonleftstyle" />\n~;
        $buttonbg = $buttonleftstyle;
        $buttonbg =~ s~.*?($yyhtml_root/Buttons/)(.*?)\.(.*)~$2~gsm;
        $prevleft = $buttonleftstyle;
        $prevleft =~ s/\.buttonleft\s*?\{(.+?)\}/$1/igsm;
        $buttonrightstyle = $stylestr;
        $buttonrightstyle =~ s/.*?(\.buttonright\s*?\{.+?\}).*/$1/igsm;
        $buttonrightbg = qq~<input type="hidden" id="buttonrightbg" name="buttonrightbg" value="$buttonrightstyle" />\n~;
        $prevright = $buttonrightstyle;
        $prevright =~ s/\.buttonright\s*?\{(.+?)\}/$1/igsm;
        $buttonimagestyle = $stylestr;
        $buttonimagestyle =~ s/.*?(\.buttonimage\s*?\{.+?\}).*/$1/igsm;
        $buttonimagebg = qq~<input type="hidden" id="buttonimagebg" name="buttonimagebg" value="$buttonimagestyle" />\n~;
        $previmage = $buttonimagestyle;
        $previmage =~ s/\.buttonimage\s*?\{(.+?)\}/$1/igsm;
        $drawimgpos = $previmage;
        $drawimgpos =~ m/.*?background\-position\s*?\:\s*?(\d{1,2})px\s*?(\d{1,2})px.*/ism;
        $viewimgy = $2;
        $viewimgy .= 'px';
        $drawpos1 = ($2 * 5) + 213;
        $drawpos1 .= 'px';
        $viewimgx = $1;
        $viewimgx .= 'px';
        $drawpos2 = $1 + 213;
        $drawpos2 .= 'px';
        $drawimgwd = $previmage;
        $drawimgwd =~ m/.*?padding\s*?\:\s*?\d{1,2}px\s*?\d{1,2}px\s*?\d{1,2}px\s*?(\d{1,2})px.*/ism;
        $viewimgpad = $1;
        $viewimgpad .= 'px';
        $drawpos3 = $1 + 213;
        $drawpos3 .= 'px';
    }
    if ( $stylestr =~ /\.seperator/sm ) {
        $seperatorstyle = $stylestr;
        $seperatorstyle =~ s/.*?(\.seperator\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$seperatorstyle'>$templ_txt{'27'}</option>\n~;
    }
    if ( $stylestr =~ /\.bordercolor/sm ) {
        $bordercolorstyle = $stylestr;
        $bordercolorstyle =~ s/.*?(\.bordercolor\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$bordercolorstyle'>$templ_txt{'28'}</option>\n~;
    }
    if ( $stylestr =~ /\.hr/sm ) {
        $hrstyle = $stylestr;
        $hrstyle =~ s/.*?(\.hr\s*?\{.+?\}).*/$1/igsm;
        $selstyl .= qq~                 <option value='$hrstyle'>$templ_txt{'29'}</option>\n~;
    }
    if ( $stylestr =~ /\.titlebg/sm ) {
        $titlestyle = $stylestr;
        $titlestyle =~ s/.*?(\.titlebg\s*?\{.+?\}).*/$1/igsm;
        $titlestyle = $titlestyle;
        $selstyl .= qq~                 <option value='$titlestyle'>$templ_txt{'30'}</option>\n~;
        if ( $stylestr =~ /\.titlebg a/sm ) {
            $titlestyle_a = $stylestr;
            $titlestyle_a =~ s/.*?(\.titlebg a\s*?\{.+?\}).*/$1/igsm;
            $selstyl .=
              qq~                   <option value='$titlestyle_a'>$templ_txt{'30a'}</option>\n~;
        }
    }
    if ( $stylestr =~ /\.catbg/sm ) {
        $categorystyle = $stylestr;
        $categorystyle =~ s/.*?(\.catbg\s*?\{.+?\}).*/$1/igsm;
        $categorystyle = $categorystyle;
        $selstyl .=
          qq~                   <option value='$categorystyle'>$templ_txt{'31'}</option>\n~;
        if ( $stylestr =~ /\.catbg a/sm ) {
            $categorystyle_a = $stylestr;
            $categorystyle_a =~ s/.*?(\.catbg a\s*?\{.+?\}).*/$1/igsm;
            $selstyl .=
              qq~                   <option value='$categorystyle_a'>$templ_txt{'31a'}</option>\n~;
        }
    }
    if ( $stylestr =~ /\.windowbg/sm ) {
        $window1style = $stylestr;
        $window1style =~ s/.*?(\.windowbg\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$window1style'>$templ_txt{'32'}</option>\n~;
    }
    if ( $stylestr =~ /\.windowbg2/sm ) {
        $window2style = $stylestr;
        $window2style =~ s/.*?(\.windowbg2.*?\{.+?\}).*/$1/igsm;
        $windowcol2 = $window2style;
        $windowcol2 =~ s/.*?(\#[a-f0-9]{3,6}).*/$1/ism;
        $selstyl .=
          qq~                   <option value='$window2style'>$templ_txt{'33'}</option>\n~;
    }
    if ( $stylestr =~ /\.post-userinfo/sm ) {
        $userinfostyle = $stylestr;
        $userinfostyle =~ s/.*?(\.post-userinfo.*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$userinfostyle'>$templ_txt{'userinfo'}</option>\n~;
    }
    if ( $stylestr =~ /\.message/sm ) {
        $postsstyle = $stylestr;
        $postsstyle =~ s/.*?(\.message\s*?\{.+?\}).*/$1/igsm;
        $selstyl .= qq~                 <option value='$postsstyle'>$templ_txt{'65'}</option>\n~;

        if ( $stylestr =~ /\.message a/sm ) {
            $postsstyle_a = $stylestr;
            $postsstyle_a =~ s/.*?(\.message a\s*?\{.+?\}).*/$1/igsm;
            $selstyl .=
              qq~                   <option value='$postsstyle_a'>$templ_txt{'66'}</option>\n~;
        }
    }
    if ( $stylestr =~ /input/sm ) {
        $inputstyle = $stylestr;
        $inputstyle =~ s/.*?(input\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$inputstyle'>$templ_txt{'34a'}</option>\n~;
    }
    if ( $stylestr =~ /button/sm ) {
        $buttonstyle = $stylestr;
        $buttonstyle =~ s/.*?(button\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$buttonstyle'>$templ_txt{'34b'}</option>\n~;
    }
    if ( $stylestr =~ /textarea/sm ) {
        $textareastyle = $stylestr;
        $textareastyle =~ s/.*?(textarea\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$textareastyle'>$templ_txt{'35'}</option>\n~;
    }
    if ( $stylestr =~ /select/sm ) {
        $selectstyle = $stylestr;
        $selectstyle =~ s/.*?(select\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$selectstyle'>$templ_txt{'36'}</option>\n~;
    }
    if ( $stylestr =~ /.quote/sm ) {
        $quotestyle = $stylestr;
        $quotestyle =~ s/.*?(\.quote\s*?\{.+?\}).*/$1/igsm;
        $selstyl .= qq~                 <option value='$quotestyle'>$templ_txt{'37'}</option>\n~;
        $message = qq~\[quote\]$templ_txt{'53'}\[/quote\]~;
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        $aquote = $message;
    }
    if ( $stylestr =~ /.code/sm ) {
        $codestyle = $stylestr;
        $codestyle =~ s/.*?(\.code\s*?\{.+?\}).*/$1/igsm;
        $selstyl .= qq~                 <option value='$codestyle'>$templ_txt{'38'}</option>\n~;
        $message = qq~\[code\]$templ_txt{'54'}\[/code\]~;
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        $acode = $message;
    }
    if ( $stylestr =~ /.editbg/sm ) {
        $editbgstyle = $stylestr;
        $editbgstyle =~ s/.*?(\.editbg\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$editbgstyle'>$templ_txt{'24'}</option>\n~;
        $message = qq~\[edit\]$templ_txt{'55'}\[/edit\]~;
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        $aedit = $message;
    }
    if ( $stylestr =~ /.highlight/sm ) {
        $highlightstyle = $stylestr;
        $highlightstyle =~ s/.*?(\.highlight\s*?\{.+?\}).*/$1/igsm;
        $selstyl .=
          qq~                   <option value='$highlightstyle'>$templ_txt{'39'}</option>\n~;
        $message = qq~\[highlight\]$templ_txt{'56'}\[/highlight\]~;
        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC();
        }
        $ahighlight = $message;
    }
    if ( $stylestr =~ /\.bodycontainer/sm ) {
        $bodycontainerstyle = 1;
    }

    $yymain .= qq~
<form action="$adminurl?action=modstyle" name="modstyles" id="modstyles" method="post" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg">
                    $admin_img{'xx'} <b>$templ_txt{'51'}</b> - $viewcss &nbsp;
                    <input type="hidden" name="cssfile" value="$cssfile" />
                    <input type="button" name="wysiwyg" id="wysiwyg" value="wysiwyg" disabled="disabled" />
                    <input type="submit" name="source" id="source" value="source" class="button" />
            </td>
        </tr>
    </table>
</div>
</form>
<form action="$adminurl?action=modcss2" name="allstyles" id="allstyles" method="post" accept-charset="$yymycharset">
<div class="bordercolor borderstyle rightboxdiv">
    <table class="border-space" style="margin-bottom: -1px;">
        <tr>
            <td class="windowbg2 center">
                <iframe id="StyleManager" name="StyleManager" style="border:0" scrolling="yes"></iframe>
            </td>
        </tr>
    </table>
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="windowbg2">
                <div style="float: left; width: 30%; padding: 3px;"><label for="cssfile"><b>$templ_txt{'1'}</b>$templ_txt{'1b'}</label></div>
                <div style="float: left; width: 69%;">
                    <input type="hidden" name="button" value="0" />
                    <select name="cssfile" id="cssfile" size="1" onchange="document.allstyles.button.value = '1'; submit();">
                        $forumcss
                    </select>
                    <input type="button" value="$templ_txt{'14'}" onclick="document.allstyles.button.value = '3'; if (confirm('$templ_txt{'15'} $cssfile?')) submit();" />
                </div>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div style="float: left; width: 30%; padding: 3px;">
                    <label for="csselement"><b>$templ_txt{'18'}</b><br /><span class="small">$templ_txt{'19'}<br /><br /></span></label>
                </div>
                <div style="float: left; width: 69%;">
                    <div style="float: left; text-align: center; margin-left: 0; margin-right: 6px; vertical-align: middle;">
                        <select name="csselement" id="csselement" size="5" onchange="setElement()">
                            $selstyl
                        </select>
                    </div>
                    <div style="float: left;">
                        <div class="small" style="float: left; vertical-align: middle;">
                            <span style="width: 70px;">
                                <input type="radio" name="selopt" id="selopt1" value="color" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="manSelect();" /> <label for="selopt1"><span class="small" style="vertical-align: middle;"><b>$templ_txt{'22'}</b></span></label>
                            </span>
                            <span>
                                <input type="text" size="9" name="textcol" id="textcol" value="$textcol" class="windowbg2" style="font-size: 10px; border: 1px #eef7ff solid; vertical-align: middle;" onchange="previewColor(this.value)" />
                                $gen_fontface $gen_fontsize
                                <img src="$imagesdir/cssbold.gif" alt="bold" name="cssbold" id="cssbold" style="border: 2px #eeeeee outset; vertical-align: middle;" onclick="previewFontweight()" />
                                <img src="$imagesdir/cssitalic.gif" alt="italic" name="cssitalic" id="cssitalic" style="border: 2px #eeeeee outset; vertical-align: middle;" onclick="previewFontstyle()" />
                            </span>
                            <br />
                            <span style="width: 70px;">
                                <input type="radio" name="selopt" id="selopt2" value="background-color" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="manSelect();" /> <label for="selopt2"><span class="small" style="vertical-align: middle;"><b>$templ_txt{'21'}</b></span></label>
                            </span>
                            <span>
                                <input type="text" size="9" name="backcol" id="backcol" value="$backcol" class="windowbg2" style="font-size: 10px; border: 1px #eef7ff solid; vertical-align: middle;" onchange="previewColor(this.value)" />
                            </span>
                            <br />
                            <span style="width: 70px;">
                                <input type="radio" name="selopt" id="selopt3" value="border" class="windowbg2" style="border: 0; vertical-align: middle;" onclick="manSelect();" /> <label for="selopt3"><span class="small" style="vertical-align: middle;"><b>$templ_txt{'23'}</b></span></label>
                            </span>
                            <span>
                                <input type="text" size="9" name="bordcol" id="bordcol" value="$bordcol" class="windowbg2" style="font-size: 10px; border: 1px #eef7ff solid; vertical-align: middle;" onchange="previewBorder()" />
                                $gen_borderstyle $gen_borderweigth
                            </span>
                            <br />
                        </div>
                        <div style="float: left; height: 68px; width: 93px; overflow: auto; border: 0; margin-left: 8px;">
                            <div style="float: left; height: 22px; width: 92px;">
                                <div class="palettebox" style="width:68px">
                                    <span class="deftpal" style="background-color: #000000;" onclick="ConvShowcolor('#000000')">&nbsp;</span>
                                    <span class="deftpal" style="background-color: #333333;" onclick="ConvShowcolor('#333333')">&nbsp;</span>
                                    <span class="deftpal" style="background-color: #666666;" onclick="ConvShowcolor('#666666')">&nbsp;</span>
                                    <span class="deftpal" style="background-color: #999999;" onclick="ConvShowcolor('#999999')">&nbsp;</span>
                                    <span class="deftpal" style="background-color: #cccccc;" onclick="ConvShowcolor('#cccccc')">&nbsp;</span>
                                    <span class="deftpal" style="background-color: #ffffff;" onclick="ConvShowcolor('#ffffff')">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal1" style="background-color: $pallist[0];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal2" style="background-color: $pallist[1];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal3" style="background-color: $pallist[2];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal4" style="background-color: $pallist[3];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal5" style="background-color: $pallist[4];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                    <span class="deftpal" id="defaultpal6" style="background-color: $pallist[5];" onclick="ConvShowcolor(this.style.backgroundColor)">&nbsp;</span>
                                </div>
                                <div style="float:left; height:22px; padding-left: 1px; padding-right: 1px; width:23px; margin-top:-11px">
                                    <img src="$admin_images/palette1.gif" style="cursor: pointer" onclick="window.open('$scripturl?action=palette;task=templ', '', 'height=308,width=302,menubar=no,toolbar=no,scrollbars=no')" alt="" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </td>
        </tr>
        ~;

    $thisbutton = q{};
    opendir DIR, "$htmldir/Buttons";
    @contents = readdir DIR;
    closedir DIR;
    $optbuttons = q{};
    $x = 1;
    foreach my $line (sort @contents){
        ($name, $extension) = split /\./xsm, $line;
        ($tmpname, $tmpside) = split /\_/xsm, $name;
        $checked = q{};
        if ($name eq $buttonbg) { $checked = q~ checked = "checked"~; }
        if (($extension =~ /gif/ism || $extension =~ /png/ism) && $tmpside eq 'left') {
            $bleft = qq~_left.$extension~;
            $bright = qq~_right.$extension~;
            $thisbutton .= qq~<div style="float: left; width: 99%; margin: 2px; vertical-align: bottom;"><div style="float: left; height: 20px; width: 112px; padding: 0 0 0 6px; background-image: url($yyhtml_root/Buttons/$tmpname$bleft); background-repeat: no-repeat; vertical-align: bottom; cursor: pointer;" onclick="updateButtons('$line');">~;
            $thisbutton .= qq~<div style="float: left; height: 20px; padding: 0 80px 0 0; background-image: url($yyhtml_root/Buttons/$tmpname$bright); background-position: right; background-repeat: no-repeat; vertical-align: bottom;"><div style="float: left; height: 20px; padding: 0 0 0 25px;"></div></div></div>~;
            $thisbutton .= qq~<div style="float: left; height: 20px;"><input type="radio" name="selbutton" id="selbutton$x" value="$line" class="windowbg2" style="border: 0; vertical-align: middle;"$checked onclick="updateButtons(this.value);" /> <label for="selbutton$x" style="vertical-align: middle;"><b>$tmpname</b></label></div></div>\n~;
            $x++;
        }
    }

$yymain .= qq~<tr>
        <td align="left" class="windowbg2">
        <div style="float: left; width: 99%; padding: 3px;">
            <b>$templ_txt{'buttontext'}</b><br /><span class="small">$templ_txt{'buttondescription'}<br /><br /></span>
        </div>
        <div style="float: left; width: 330px; height: 136px; padding: 3px;">
        <div class="catbg" style="position: relative; top: 0; left: 5px; width: 280px; text-align: center; border-width: 1px; border-style: outset; padding: 3px 0;">
        <img src="$defaultimagesdir/buttonsep.png" style="height: 20px; width: 1px; margin: 0; padding: 0; vertical-align: top; display: inline-block;" alt="" />
        <span id="butleft" style="height: 20px; border: 0; margin: 1px 1px; background-position: top left; background-repeat: no-repeat; text-decoration: none; font-size: 18px; vertical-align: top; display: inline-block; $prevleft">
        <span id="butright" style="height: 20px; border: 0; margin: 0; background-position: top right; background-repeat: no-repeat; text-decoration: none; font-size: 18px; vertical-align: top; display: inline-block; $prevright">
        <span id="butimage" style="$previmage background-image: url($defaultimagesdir/home.gif); height: 20px; border: 0; margin: 0; background-repeat: no-repeat; vertical-align: top; text-decoration: none; font-size: 18px; display: inline-block;">
        <span id="buttext" style="height: 20px; border: 0; margin: 0; padding: 0; text-align: left; text-decoration: none; vertical-align: top; white-space: nowrap; display: inline-block; $prevtext">$img_txt{'103'}</span>
        </span></span></span>
        <img src="$defaultimagesdir/buttonsep.png" style="height: 20px; width: 1px; margin: 0; padding: 0; vertical-align: top; display: inline-block;" alt="" />
        </div>
        <div class="catbg" style="position: relative; top: 4px; left: 5px; width: 280px; height: 18px; border-width: 1px; border-style: outset;">
        <span class="small" style="position: absolute; top: 3px; left: 6px;"><b>$templ_txt{'moveicon1'}</b>
        <input class="catbg" name="viewimgy" id="viewimgy" type="text" value="$viewimgy" style="position: absolute; top: 0; left: 165px; text-align: right; width: 30px; margin: 0; padding: 0; border: 0; font-size: 10px; font-weight: bold; display: inline;" readonly="readonly" /></span>
        <img src="$defaultimagesdir/knapbagrms02.gif" style="position: absolute; top: 0; left: 209px; z-index: 1; width: 69px; height: 16px;" alt="" />
        <img id="knapImg1" src="$defaultimagesdir/knapyellow.gif" class="skyd" style="position: absolute; left: $drawpos1; top: 2px; cursor: pointer; z-index: 2; width: 13px; height: 15px;" alt=""  />
        </div>
        <div class="catbg" style="position: relative; top: 8px; left: 5px; width: 280px; height: 18px; border-width: 1px; border-style: outset;">
        <span class="small" style="position: absolute; top: 3px; left: 6px;"><b>$templ_txt{'moveicon2'}</b>
        <input class="catbg" name="viewimgx" id="viewimgx" type="text" value="$viewimgx" style="position: absolute; top: 0; left: 165px; text-align: right; width: 30px; margin: 0; padding: 0; border: 0; font-size: 10px; font-weight: bold; display: inline;" readonly="readonly" /></span>
        <img src="$defaultimagesdir/knapbagrms02.gif" style="position: absolute; top: 0; left: 209px; z-index: 1; width: 69px; height: 16px;" alt="" />
        <img id="knapImg2" src="$defaultimagesdir/knapyellow.gif" class="skyd" style="position: absolute; left: $drawpos2; top: 2px; cursor: pointer; z-index: 2; width: 13px; height: 15px;" alt="" />
        </div>
        <div class="catbg" style="position: relative; top: 12px; left: 5px; width: 280px; height: 18px; border-width: 1px; border-style: outset;">
        <span class="small" style="position: absolute; top: 3px; left: 6px;"><b>$templ_txt{'iconspace'}</b>
        <input class="catbg" name="viewimgpad" id="viewimgpad" type="text" value="$viewimgpad" style="position: absolute; top: 0; left: 165px; text-align: right; width: 30px; margin: 0; padding: 0; border: 0; font-size: 10px; font-weight: bold; display: inline;" readonly="readonly" /></span>
        <img src="$defaultimagesdir/knapbagrms02.gif" style="position: absolute; top: 0; left: 209px; z-index: 1; width: 69px; height: 16px;" alt="" />
        <img id="knapImg3" src="$defaultimagesdir/knapyellow.gif" class="skyd" style="position: absolute; left: $drawpos3; top: 2px; cursor: pointer; z-index: 2; width: 13px; height: 15px;" alt="" />
        </div>
        <div class="catbg" style="position: relative; top: 16px; left: 5px; width: 280px; height: 18px; border-width: 1px; border-style: outset;">
        <span class="small" style="position: absolute; top: 3px; left: 6px;"><b>$templ_txt{'movetext'}</b>
        <input class="catbg" name="viewtxty" id="viewtxty" type="text" value="$viewtxty" style="position: absolute; top: 0; left: 165px; text-align: right; width: 30px; margin: 0; padding: 0; border: 0; font-size: 10px; font-weight: bold; display: inline;" readonly="readonly" /></span>
        <img src="$defaultimagesdir/knapbagrms02.gif" style="position: absolute; top: 0; left: 209px; z-index: 1; width: 69px; height: 16px;" alt="" />
        <img id="knapImg4" src="$defaultimagesdir/knapyellow.gif" class="skyd" style="position: absolute; left: $drawpos4; top: 2px; cursor: pointer; z-index: 2; width: 13px; height: 15px;" alt="" />
        </div>
        </div>
        <div style="float: left; width: 300px; padding: 3px; padding-left: 13px;">
            $thisbutton
        </div>
        $buttonleftbg
        $buttonrightbg
        $buttonimagebg

<script type="text/javascript">

var skydobject={
x: 0, temp2 : null, targetobj : null, skydNu : 0, delEnh : 0,
initialize:function() {
    document.onmousedown = this.skydeKnap
    document.onmouseup=function(){
        if(this.skydNu) updateStyles();
        this.skydNu = 0;
    }
},
changeStyle:function(deleEnh, knapId) {
    if (knapId == "knapImg1") {
        newypos = parseInt(deleEnh/5);
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.buttonimagebg.value;
        oldxpos=cssoption.replace(/\.*?background\\-position\\s*?\\:\\s*?(\\d{1,2})\.*/i, "\$1");
        newcssoption=cssoption.replace(/(background\\-position\\s*?\\:\.*?\\d{1,2}px\\s*?)\\d{1,2}(px\\;)/i, "\$1" + newypos + "\$2");
        document.allstyles.buttonimagebg.value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        document.getElementById('butimage').style.backgroundPosition = oldxpos+'px '+newypos+'px';
        document.getElementById('viewimgy').value = newypos+'px';
    }
    if (knapId == "knapImg2") {
        newxpos = parseInt(deleEnh);
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.buttonimagebg.value;
        oldypos=cssoption.replace(/\.*?background\\-position\\s*?\\:\\s*?\\d{1,2}px\\s*?(\\d{1,2})\.*/i, "\$1");
        newcssoption=cssoption.replace(/(background\\-position\\s*?\\:\.*?)\\d{1,2}(px\\s*?\\d{1,2}px\\;)/i, "\$1" + newxpos + "\$2");
        document.allstyles.buttonimagebg.value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        document.getElementById('butimage').style.backgroundPosition = newxpos+'px '+oldypos+'px';
        document.getElementById('viewimgx').value = newxpos+'px';
    }
    if (knapId == "knapImg3") {
        newimgpad = parseInt(deleEnh);
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.buttonimagebg.value;
        newcssoption=cssoption.replace(/(padding\\s*?\\:\.*?\\d{1,2}px\\s*?\\d{1,2}px\\s*?\\d{1,2}px\\s*?)\\d{1,2}(px\\;)/i, "\$1" + newimgpad + "\$2");
        document.allstyles.buttonimagebg.value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        document.getElementById('butimage').style.padding = '0 0 0 '+newimgpad+'px';
        document.getElementById('viewimgpad').value = newimgpad+'px';
    }
    if (knapId == "knapImg4") {
        newtxtpad = parseInt(deleEnh/5);
        thenewstyle = document.allstyles.stylelink.value;
        allstyleslen = document.allstyles.csselement.length;
        for (i = 0; i < allstyleslen; i++) {
            tmpselelement = document.allstyles.csselement[i].value;
            if (tmpselelement.match(/\\.buttontext/)) {
                cssoption = document.allstyles.csselement.options[i].value;
                newcssoption=cssoption.replace(/(top\\s*?\\:\.*?)\\d{1,2}(px\\s*?\\;)/i, "\$1" + newtxtpad + "\$2");
                document.allstyles.csselement.options[i].value = newcssoption;
            }
        }
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        document.getElementById('buttext').style.top = newtxtpad+'px';
        document.getElementById('viewtxty').value = newtxtpad+'px';
    }
},
flytKnap:function(e) {
    var evtobj = window.event ? window.event : e
    if (this.skydNu == 1) {
        glX = parseInt(this.targetobj.style.left)
        this.targetobj.style.left = this.temp2 + evtobj.clientX - this.x + "px"
        nyX = parseInt(this.temp2 + evtobj.clientX - this.x)
        if (nyX > glX) retning = "vn"; else retning = "hj";
        if (nyX < 213 && retning == "hj") { this.targetobj.style.left = 213 + "px"; nyX = 213; retning = "vn"; }
        if (nyX > 263 && retning == "vn") { this.targetobj.style.left = 263 + "px"; nyX = 263; retning = "hj"; }
        delEnh = parseInt(nyX)-213
        var knapObj = this.targetobj.id
        skydobject.changeStyle(delEnh, knapObj)
        return false
    }
},
skydeKnap:function(e) {
    var evtobj = window.event ? window.event : e
    this.targetobj = window.event ? event.srcElement : e.target
    if (this.targetobj.className == "skyd") {
        this.skydNu = 1
        this.knapObj = this.targetobj
        if (isNaN(parseInt(this.targetobj.style.left))) this.targetobj.style.left = 0
        this.temp2 = parseInt(this.targetobj.style.left)
        this.x = evtobj.clientX
        if (evtobj.preventDefault) evtobj.preventDefault()
        document.onmousemove = skydobject.flytKnap
    }
}
}

skydobject.initialize()
</script>
        </td>
    </tr>~;

    $viewstylestart =
q~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{yabb xml_lang}" lang="{yabb xml_lang}">
<head>
<title>Test Styles</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
~;
    $viewstyle = q~
<body>
<div id="maincontainer">
~;
    if ($containerstyle) {
        $viewstyle .= q~
<div id="container">
~;
    }
    if ($istabbed) {
        $tabsep = q{};
        $tabfill = q{};
        $tabtime = timeformat( $date, 1 );

        $viewstyle .= qq~
    <table class="menutop">
        <tr>
            <td class="small h_23px" style="padding-left:1%">$tabtime</td>
            <td class="right vtop"><div class="yabb_searchbox">
                <input id="search1" type="text" onblur="txtInFields(this, 'Search')" onfocus="txtInFields(this, 'Search');" style="font-size: 11px;" value="Search" size="16" name="search"><input type="image" style="background-color: transparent; margin-right: 5px; vertical-align: middle;" title="Posts no more than 31 days old" alt="Posts no more than 31 days old" src="$imagesdir/search.png"></div>
            </td>
        </tr>
    </table>
    <table id="header" class="pad_4px">
        <tr>
            <td class="vtop" style="height:50px">Header (#header) <a href="javascript:;">Header Link (#header a)</a></td>
        </tr>
    </table>
    <table>
        <tr>
            <td id="tabmenu" class="tabmenu">
                <span class="selected"><a href="javascript:;">$tabfill$img_txt{'103'}$tabfill</a></span>
                $tabsep<span style="cursor:help;"><a href="javascript:;" style="cursor:help;">$tabfill$img_txt{'119'}$tabfill</a></span>
                $tabsep<span><a href="javascript:;">$tabfill$img_txt{'182'}$tabfill</a></span>
                $tabsep<span><a href="javascript:;">$tabfill$img_txt{'331'}$tabfill</a></span>
                $tabsep<span><a href="javascript:;">$tabfill$img_txt{'mycenter'}$tabfill</a></span>
                $tabsep<span><a href="javascript:;">$tabfill$img_txt{'108'}$tabfill</a></span>
            </td>
        </tr>
    </table>
~;
    }
    if ($containerstyle) {
        $viewstyle .= qq~
  $templ_txt{'64'}
<br /><br />
~;
    }
    if ($bodycontainerstyle) {
        $viewstyle .= q~<div class="bodycontainer">~;
    }
    if ($seperatorstyle) {
        $viewstyle .= q~<div class="seperator">~;
    }
    if ($istabbed) {
        $viewstyle .= qq~
<table style="border-spacing:0" class="bordercolor">
    <colgroup>
        <col style="width:1%;  height:25px" />
        <col style="width:49%;  height:25px" />
        <col style="width:50%;  height:25px" />
    </colgroup>
    <tr>
        <td class="tabtitle" colspan="3">
            $templ_txt{'tabtitle'} <a href="javascript:;">$templ_txt{'tabtitlea'}</a>
        </td>
    </tr>
</table>
<br />
~;
    }
    $viewstyle .= qq~
<table class="bordercolor border-space pad-cell">
    <colgroup>
        <col span="2" style="width: 50%" />
    </colgroup>
    <tr>
        <td id="title" class="titlebg">
            $templ_txt{'30'}
        </td>
        <td id="titlea" class="titlebg">
            <a href="javascript:;">$templ_txt{'30a'}</a>
        </td>
    </tr>
</table>
~;
    if ($seperatorstyle) {
        $viewstyle .= q~</div>~;
    }
    $viewstyle .= q~
<br />
~;
    if ($seperatorstyle) {
        $viewstyle .= q~<div class="seperator">~;
    }
    $viewstyle .= qq~
<table class="bordercolor border-space pad-cell">
    <colgroup>
        <col span="2" style="width: 50%" />
    </colgroup>
    <tr>
        <td id="category" class="catbg">
            $templ_txt{'31'}
        </td>
        <td id="categorya" class="catbg">
            <a href="javascript:;">$templ_txt{'31a'}</a>
        </td>
    </tr>
</table>
~;

$menusep = qq~<img src="$defaultimagesdir/buttonsep.png" style="height: 20px; width: 1px; margin: 0; padding: 0; vertical-align: top; display: inline-block;" alt="" />~;
$viewstyleleft = q~style="height: 20px; border: 0; margin: 1px 1px; background-position: top left; background-repeat: no-repeat; text-decoration: none; font-size: 18px; vertical-align: top; display: inline-block;"~;
$viewstyleright = q~style="height: 20px; border: 0; margin: 0; background-position: top right; background-repeat: no-repeat; text-decoration: none; font-size: 18px; vertical-align: top; display: inline-block;"~;
$viewstyleimage = q~height: 20px; border: 0; margin: 0; background-repeat: no-repeat; vertical-align: top; text-decoration: none; font-size: 18px; display: inline-block;~;
$viewstyletext = q~style="height: 20px; border: 0; margin: 0; padding: 0; text-align: left; text-decoration: none; vertical-align: top; white-space: nowrap; display: inline-block;"~;

$viewstyle .= qq~
<table class="bordercolor border-space pad-cell">
    <tr>
        <td id="cssbuttons" class="windowbg2 vtop">
            <div style="float: left; padding: 4px 0 0 0;">$templ_txt{'buttontext'}</div>
            <div style="float: right;">
                <a href="javascript:;"><span id="button1l" class="buttonleft" $viewstyleleft title="$img_txt{'145'}"><span id="button1r" class="buttonright" $viewstyleright><span class="buttonimage" style="background-image: url($defaultimagesdir/maq1.png); $viewstyleimage"><span class="buttontext" $viewstyletext>$img_txt{'145'}</span></span></span></span></a>$menusep
                <a href="javascript:;"><span id="button2l" class="buttonleft" $viewstyleleft title="$img_txt{'66'}"><span id="button2r" class="buttonright" $viewstyleright><span class="buttonimage" style="background-image: url($defaultimagesdir/modify.png); $viewstyleimage"><span class="buttontext" $viewstyletext>$img_txt{'66'}</span></span></span></span></a>$menusep
                <a href="javascript:;"><span id="button3l" class="buttonleft" $viewstyleleft title="$img_txt{'620'}"><span id="button3r" class="buttonright" $viewstyleright><span class="buttonimage" style="background-image: url($defaultimagesdir/admin_split.png); $viewstyleimage"><span class="buttontext" $viewstyletext>$img_txt{'620'}</span></span></span></span></a>$menusep
                <a href="javascript:;"><span id="button4l" class="buttonleft" $viewstyleleft title="$img_txt{'121'}"><span id="button4r" class="buttonright" $viewstyleright><span class="buttonimage" style="background-image: url($defaultimagesdir/delete.gif); $viewstyleimage"><span class="buttontext" $viewstyletext>$img_txt{'121'}</span></span></span></span></a>
            </div>
        </td>
    </tr>
</table>
~;

$viewstyle .= qq~
<table class="bordercolor border-space pad-cell">
    <tr>
        <td id="window1" class="windowbg vtop">
            $templ_txt{'32'}
        </td>
        <td id="window2" class="windowbg2 vtop">
            $templ_txt{'33'}<br />
            <hr class="hr">
            <div id="messages" class="message">$templ_txt{'65'}</div>
            <div id="messagesa" class="message"><a href="javascript:;">$templ_txt{'66'}</a><br /><br /></div>
            <textarea rows="4" cols="19">$templ_txt{'35'}</textarea><br />
            <input type="text" size="19" value="$templ_txt{'34a'}" />&nbsp;
            <select value="test">
                <option>$templ_txt{'36'} $templ_txt{'61'}</option>
                <option>$templ_txt{'36'} 2</option>
            </select>&nbsp;
            <input type="button" value="$templ_txt{'34b'}" class="button" />
        </td>
    </tr><tr>
        <td id="window3" class="post-userinfo vtop">$templ_txt{'userinfo'} (.post-userinfo)</td>
        <td id="window4" class="windowbg2 vtop">
            $aquote
            $acode
            $aedit<br />
            $ahighlight
        </td>
    </tr>
</table>
~;
    if ($seperatorstyle) {
        $viewstyle .= q~</div>~;
    }
    if ($bodycontainerstyle) {
        $viewstyle .= q~</div>~;
    }
    if ($istabbed) {
        $viewstyle .= q~
    <br />
    <div class="mainbottom">
        <table>
            <tr>
                <td class="nav" style="height:22px">&nbsp;</td>
            </tr>
        </table>
    </div>
~;
    }
    if ($containerstyle) {
        $viewstyle .= q~</div>~;
    }
    $viewstyle .= q~
<br /><br />
</div>
</body>
</html>~;
    $viewstylestart =~ s/^\s+//gsm;
    $viewstylestart =~ s/\s+$//gsm;
    $viewstylestart =~ s/[\n\r]//gxsm;
    $viewstylestart =~ s/({|<)yabb xml_lang(}|>)/$abbr_lang/gsm;
    ToHTML($viewstylestart);
    $stylestr =~ s/^\s+//gsm;
    $stylestr =~ s/\s+$//gsm;
    $stylestr =~ s/[\n\r]//gxsm;
    $stylestr =~ s/({|<)yabb xml_lang(}|>)/$abbr_lang/gsm;
    ToHTML($stylestr);
    $viewstyle =~ s/^\s+//gsm;
    $viewstyle =~ s/\s+$//gsm;
    $viewstyle =~ s/[\n\r]//gxsm;
    $viewstyle =~ s/({|<)yabb xml_lang(}|>)/$abbr_lang/gsm;
    ToHTML($viewstyle);

    if($viewcss eq 'default') {
        $savecss = q{};
    }
    else {
        $savecss = $viewcss;
    }

    $yymain .= qq~
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="hidden" name="stylestart" value="$viewstylestart" />
            <input type="hidden" name="stylelink" value="$stylestr" />
            <input type="hidden" name="stylebody" value="$viewstyle" />
            <label for="savecssas"><b>$templ_txt{'12'}</b></label>
            <input type="text" name="savecssas" id="savecssas" value="~
            . ( split /\./xsm, $cssfile )[0] . qq~" size="30" maxlength="30" />
            <input type="submit" value="$templ_txt{'13'}" onclick="document.allstyles.button.value = '2';" class="button" />
            <div class="small" style="font-weight: normal;">$templ_txt{'noedit'}</div>
        </td>
    </tr>
</table>
</div>
</form>
<script type="text/javascript">
var cssbold;
var cssitalic;
var stylesurl = '$yyhtml_root/Templates/Forum';

function initStyles() {
        var thestylestart = document.allstyles.stylestart.value;
        var thestyles = document.allstyles.stylelink.value;
        var thestylebody = document.allstyles.stylebody.value;
        var thestyle = thestylestart + '\\<style type="text/css"\\>\\<\\!\\-\\-' + thestyles + '\\-\\-\\>\\<\\/style\\>' + thestylebody;
        thestyle=thestyle.replace(/\\&quot\\;/g, '"');
        thestyle=thestyle.replace(/\\&nbsp\\;/g, " ");
        thestyle=thestyle.replace(/\\&\\#124\\;/g, "|");
        thestyle=thestyle.replace(/\\&lt\\;/g, "<");
        thestyle=thestyle.replace(/\\&gt\\;/g, ">");
        thestyle=thestyle.replace(/\\&amp\\;/g, "&");
        thestyle=thestyle.replace(/(url\\(\\")(.*?\\/.*?\\"\\))/gi, "\$1" + stylesurl + "\/\$2");
        StyleManager.document.open("text/html");
        StyleManager.document.write(thestyle);
        StyleManager.document.close();
}

function updateStyles() {
        var currentTop = document.getElementById('StyleManager').contentWindow.document.documentElement.scrollTop;
        initStyles();
        document.getElementById('StyleManager').contentWindow.document.documentElement.scrollTop = currentTop;
}
var buttonurl = '$yyhtml_root/Buttons/';

function updateButtons(thebg) {
    len = document.allstyles.selbutton.length;
    for (i = 0; i <len; i++) {
        document.allstyles.selbutton[i].checked = false;
        if (document.allstyles.selbutton[i].value == thebg) document.allstyles.selbutton[i].checked = true;
    }
    thenewstyle = document.allstyles.stylelink.value;
    cssoption = document.allstyles.buttonleftbg.value;
    newcssoption=cssoption.replace(/(background\\-image\\s*?\\:\.*?\\/Buttons\\/).*?(\\)\\;)/i, "\$1" + thebg + "\$2");
    document.getElementById('butleft').style.backgroundImage = 'url(' + buttonurl + thebg + ')';
    document.allstyles.buttonleftbg.value = newcssoption;
    re=cssoption.replace(/(.*)/, "\$1");
    thenewstyle=thenewstyle.replace(re, newcssoption);
    document.allstyles.stylelink.value = thenewstyle;
    updateStyles();
    btside = '_right';
    cssoption = document.allstyles.buttonrightbg.value;
    newthebg = thebg.replace(/(.*?)\\_left(.*)/i, "\$1" + btside + "\$2");
    newcssoption=cssoption.replace(/(background\\-image\\s*?\\:\.*?\\/Buttons\\/).*?(\\)\\;)/i, "\$1" + newthebg + "\$2");
    document.getElementById('butright').style.backgroundImage = 'url(' + buttonurl + newthebg + ')';
    document.allstyles.buttonrightbg.value = newcssoption;
    re=cssoption.replace(/(.*)/, "\$1");
    thenewstyle=thenewstyle.replace(re, newcssoption);
    document.allstyles.stylelink.value = thenewstyle;
    updateStyles();
}

function previewColor(thecolor) {
    thenewstyle = document.allstyles.stylelink.value;
    cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
    var cssfont = document.allstyles.selopt1;
    var cssback = document.allstyles.selopt2;
    var cssborder = document.allstyles.selopt3;
    if(cssfont.checked) {
        newcssoption=cssoption.replace(/( color\\s*?\\:).+?(\\;)/i, "\$1 " + thecolor + "\$2");
        document.allstyles.textcol.value = thecolor;
        if(cssoption.match(/\\#container\\s*?\\{/)) {
            thenewstyle=thenewstyle.replace(/(\\.tabmenu span a\\s*?\\{.*?color\\s*?\\:).+?(\\;)/ig, "\$1 " + thecolor + "\$2");
        }
        if(cssoption.match(/\\.buttontext/)) document.getElementById('buttext').style.color = thecolor;
    }
    if(cssback.checked) {
        newcssoption=cssoption.replace(/(background-color\\s*?\\:).+?(\\;)/i, "\$1 " + thecolor + "\$2");
        document.allstyles.backcol.value = thecolor;
        if(cssoption.match(/\\.tabmenu\\s*?\\{/)) {
            thenewstyle=thenewstyle.replace(/(\\.tabmenu.*?\\{.*?background-color\\s*?\\:).+?(\\;)/ig, "\$1 " + thecolor + "\$2");
            thenewstyle=thenewstyle.replace(/(\\.rightbox.*?\\{.*?background-color\\s*?\\:).+?(\\;)/ig, "\$1 " + thecolor + "\$2");
        }
    }
    if(cssborder.checked) {
        tempnewcolor=cssoption;
        if(tempnewcolor.match(/border\\s*?\\:/)) {
            bordercol=tempnewcolor.replace(/.*?border\\s*?\\:(.+?)\\;.*/, "\$1");
            if(bordercol.match(/\\#[0-9a-f]{3,6}/i)) {
                tempnewcolor=tempnewcolor.replace(/(border\\s*?\\:.*?)\\#[0-9a-f]{3,6}(.*?\\;)/i, "\$1 " + thecolor + "\$2");
                viewnewcolor=tempnewcolor.replace(/.*?border\\s*?\\:(.*?)\\;.*/i, "\$1");
            }
        }
        if(tempnewcolor.match(/border\\-top\\s*?\\:/)) {
            bordertopcol=tempnewcolor.replace(/.*?border\\-top\\s*?\\:(.+?)\\;.*/, "\$1");
            if(bordertopcol.match(/\\#[0-9a-f]{3,6}/i)) {
                tempnewcolor=tempnewcolor.replace(/(border\\-top\\s*?\\:.*?)\\#[0-9a-f]{3,6}(.*?\\;)/i, "\$1 " + thecolor + "\$2");
                viewnewcolor=tempnewcolor.replace(/.*?border\\-top\\s*?\\:(.*?)\\;.*/i, "\$1");
            }
        }
        if(tempnewcolor.match(/border\\-bottom\\s*?\\:/)) {
            borderbottomcol=tempnewcolor.replace(/.*?border\\-bottom\\s*?\\:(.+?)\\;.*/, "\$1");
            if(borderbottomcol.match(/\\#[0-9a-f]{3,6}/i)) {
                tempnewcolor=tempnewcolor.replace(/(border\\-bottom\\s*?\\:.*?)\\#[0-9a-f]{3,6}(.*?\\;)/i, "\$1 " + thecolor + "\$2");
                viewnewcolor=tempnewcolor.replace(/.*?border\\-bottom\\s*?\\:(.*?)\\;.*/i, "\$1");
            }
        }
        if(tempnewcolor.match(/border\\-left\\s*?\\:/)) {
            borderleftcol=tempnewcolor.replace(/.*?border\\-left\\s*?\\:(.+?)\\;.*/, "\$1");
            if(borderleftcol.match(/\\#[0-9a-f]{3,6}/i)) {
                tempnewcolor=tempnewcolor.replace(/(border\\-left\\s*?\\:.*?)\\#[0-9a-f]{3,6}(.*?\\;)/i, "\$1 " + thecolor + "\$2");
                viewnewcolor=tempnewcolor.replace(/.*?border\\-left\\s*?\\:(.*?)\\;.*/i, "\$1");
            }
        }
        if(tempnewcolor.match(/border\\-right\\s*?\\:/)) {
            borderrightcol=tempnewcolor.replace(/.*?border\\-right\\s*?\\:(.+?)\\;.*/, "\$1");
            if(borderrightcol.match(/\\#[0-9a-f]{3,6}/i)) {
                tempnewcolor=tempnewcolor.replace(/(border\\-right\\s*?\\:.*?)\\#[0-9a-f]{3,6}(.*?\\;)/i, "\$1 " + thecolor + "\$2");
                viewnewcolor=tempnewcolor.replace(/.*?border\\-right\\s*?\\:(.*?)\\;.*/i, "\$1");
            }
        }
        newcssoption=tempnewcolor;
        nocolor=viewnewcolor.replace(/(.*?)\\#[0-9a-f]{3,6}(.*)/i, "\$1\$2");
        theborderstyle=viewnewcolor.replace(/(.*?)(solid|dashed|dotted|double|groove|ridge|inset|outset)(.*)/i, "\$2");
        thebordersize=nocolor.replace(/.*?([\\d]{1,2}).*/i, "\$1");
        document.allstyles.bordcol.value = thecolor;
    }
    document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
    re=cssoption.replace(/(.*)/, "\$1");
    thenewstyle=thenewstyle.replace(re, newcssoption);
    document.allstyles.stylelink.value = thenewstyle;
    updateStyles();
}

function previewBorder() {
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        var cssborder = document.allstyles.selopt3;
        var thebweigth = document.allstyles.borderweigth.value;
        var thebcolor = document.allstyles.bordcol.value;
        var thebstyle = document.allstyles.borderstyle.value;
        var thecolor = thebweigth + 'px ' + thebcolor + ' ' + thebstyle;
        if(cssborder.checked) {
                tempnewcolor=cssoption;
                if(tempnewcolor.match(/border\\s*?\\:/)) {
                        bordercol=tempnewcolor.replace(/.*?border\\s*?\\:(.+?)\\;.*/, "\$1");
                        if(bordercol.match(/\\#[0-9a-f]{3,6}/i)) {
                                tempnewcolor=tempnewcolor.replace(/(border\\s*?\\:).*?\\#[0-9a-f]{3,6}.*?(\\;)/i, "\$1 " + thecolor + "\$2");
                                viewnewcolor=tempnewcolor.replace(/.*?border\\s*?\\:(.*?)\\;.*/i, "\$1");
                        }
                }
                if(tempnewcolor.match(/border\\-top\\s*?\\:/)) {
                        bordertopcol=tempnewcolor.replace(/.*?border\\-top\\s*?\\:(.+?)\\;.*/, "\$1");
                        if(bordertopcol.match(/\\#[0-9a-f]{3,6}/i)) {
                                tempnewcolor=tempnewcolor.replace(/(border\\-top\\s*?\\:).*?\\#[0-9a-f]{3,6}.*?(\\;)/i, "\$1 " + thecolor + "\$2");
                                viewnewcolor=tempnewcolor.replace(/.*?border\\-top\\s*?\\:(.*?)\\;.*/i, "\$1");
                        }
                }
                if(tempnewcolor.match(/border\\-bottom\\s*?\\:/)) {
                        borderbottomcol=tempnewcolor.replace(/.*?border\\-bottom\\s*?\\:(.+?)\\;.*/, "\$1");
                        if(borderbottomcol.match(/\\#[0-9a-f]{3,6}/i)) {
                                tempnewcolor=tempnewcolor.replace(/(border\\-bottom\\s*?\\:).*?\\#[0-9a-f]{3,6}.*?(\\;)/i, "\$1 " + thecolor + "\$2");
                                viewnewcolor=tempnewcolor.replace(/.*?border\\-bottom\\s*?\\:(.*?)\\;.*/i, "\$1");
                        }
                }
                if(tempnewcolor.match(/border\\-left\\s*?\\:/)) {
                        borderleftcol=tempnewcolor.replace(/.*?border\\-left\\s*?\\:(.+?)\\;.*/, "\$1");
                        if(borderleftcol.match(/\\#[0-9a-f]{3,6}/i)) {
                                tempnewcolor=tempnewcolor.replace(/(border\\-left\\s*?\\:).*?\\#[0-9a-f]{3,6}.*?(\\;)/i, "\$1 " + thecolor + "\$2");
                                viewnewcolor=tempnewcolor.replace(/.*?border\\-left\\s*?\\:(.*?)\\;.*/i, "\$1");
                        }
                }
                if(tempnewcolor.match(/border\\-right\\s*?\\:/)) {
                        borderrightcol=tempnewcolor.replace(/.*?border\\-right\\s*?\\:(.+?)\\;.*/, "\$1");
                        if(borderrightcol.match(/\\#[0-9a-f]{3,6}/i)) {
                                tempnewcolor=tempnewcolor.replace(/(border\\-right\\s*?\\:).*?\\#[0-9a-f]{3,6}.*?(\\;)/i, "\$1 " + thecolor + "\$2");
                                viewnewcolor=tempnewcolor.replace(/.*?border\\-right\\s*?\\:(.*?)\\;.*/i, "\$1");
                        }
                }
                newcssoption=tempnewcolor;

                nocolor=viewnewcolor.replace(/(.*?)\\#[0-9a-f]{3,6}(.*)/i, "\$1\$2");
                theborderstyle=viewnewcolor.replace(/(.*?)(solid|dashed|dotted|double|groove|ridge|inset|outset)(.*)/i, "\$2");
                thebordersize=nocolor.replace(/.*?([\\d]{1,2}).*/i, "\$1");
                document.allstyles.bordcol.value = thebcolor;
        }
        document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        updateStyles();
}

function previewFont() {
        thesize = document.allstyles.cssfntsize.options[document.allstyles.cssfntsize.selectedIndex].value;
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        newcssoption=cssoption.replace(/(font\\-size\\s*?\\:\\s*?)[\\d]{1,2}(\\w+?\;)/i, "\$1" + thesize + "\$2");
        document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        if(cssoption.match(/\\.buttontext/)) document.getElementById('buttext').style.fontSize = thesize;
        updateStyles();
}

function previewFontface() {
        theface = document.allstyles.cssfntface.options[document.allstyles.cssfntface.selectedIndex].value;
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        thetmpfontface=cssoption.replace(/.*?font\\-family\\s*?\\:\\s*?([\\D]+?)\\;.*?\\}/i, "\$1");
        thearrfontface=thetmpfontface.split(",");
        optnumb=thearrfontface.length;
        newfontarr = theface;
        for(i = 0; i < optnumb; i++) {
                thefontface = thearrfontface[i].toLowerCase();
                thefontface=thefontface.replace(/^\\s/g, "");
                thefontface=thefontface.replace(/\\s\$/g, "");
                if(thefontface != theface) newfontarr += ', ' + thefontface;
        }
        newcssoption=cssoption.replace(/(font\\-family\\s*?\\:).*?(\;)/i, "\$1 " + newfontarr + "\$2");
        document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        if(cssoption.match(/\\.buttontext/)) document.getElementById('buttext').style.fontFamily = theface;
        updateStyles();
}

function previewFontweight() {
        if(cssbold == false) return;
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        thetmpfontweight=cssoption.replace(/.*?font\\-weight\\s*?\\:\\s*?([\\D]+?)\\;.*/i, "\$1");
        thetmpfontweight=thetmpfontweight.replace(/\\s/g, "");
        if(thetmpfontweight == 'normal') {
                thefontweight = 'bold';
                document.getElementById('cssbold').style.borderStyle = 'inset';
        }
        else {
                thefontweight = 'normal';
                document.getElementById('cssbold').style.borderStyle = 'outset';
        }
        newcssoption=cssoption.replace(/(font\\-weight\\s*?\\:).*?(\;)/ig, "\$1 " + thefontweight + "\$2");
        document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        if(cssoption.match(/\\.buttontext/)) document.getElementById('buttext').style.fontWeight = thefontweight;
        updateStyles();
}

function previewFontstyle() {
        if(cssitalic == false) return;
        thenewstyle = document.allstyles.stylelink.value;
        cssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        thetmpfontstyle=cssoption.replace(/.*?font\\-style\\s*?\\:\\s*?([\\D]+?)\\;.*/i, "\$1");
        thetmpfontstyle=thetmpfontstyle.replace(/\\s/g, "");
        if(thetmpfontstyle == 'normal') {
                thefontstyle = 'italic';
                document.getElementById('cssitalic').style.borderStyle = 'inset';
        }
        else {
                thefontstyle = 'normal';
                document.getElementById('cssitalic').style.borderStyle = 'outset';
        }
        newcssoption=cssoption.replace(/(font\\-style\\s*?\\:).*?(\;)/ig, "\$1 " + thefontstyle + "\$2");
        document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value = newcssoption;
        re=cssoption.replace(/(.*)/, "\$1");
        thenewstyle=thenewstyle.replace(re, newcssoption);
        document.allstyles.stylelink.value = thenewstyle;
        if(cssoption.match(/\\.buttontext/)) document.getElementById('buttext').style.fontStyle = thefontstyle;
        updateStyles();
}

function manSelect() {
        var cssfont = document.allstyles.selopt1;
        var cssback = document.allstyles.selopt2;
        var cssborder = document.allstyles.selopt3;
        document.allstyles.textcol.disabled = true;
        document.allstyles.backcol.disabled = true;
        document.allstyles.bordcol.disabled = true;
        document.allstyles.borderweigth.disabled = true;
        document.allstyles.borderstyle.disabled = true;
        if(cssfont.checked == true) {
                document.allstyles.textcol.disabled = false;
        }
        if(cssback.checked == true) {
                document.allstyles.backcol.disabled = false;
        }
        if(cssborder.checked == true) {
                document.allstyles.bordcol.disabled = false;
                document.allstyles.borderweigth.disabled = false;
                document.allstyles.borderstyle.disabled = false;
        }
}

function setElement() {
        cssbold = false;
        cssitalic = false;

        tempcssoption = document.allstyles.csselement.options[document.allstyles.csselement.selectedIndex].value;
        tmpcssoption = tempcssoption.split("{");

        document.modstyles.wysiwyg.disabled = true;

        document.allstyles.cssfntsize.disabled = true;
        document.allstyles.cssfntface.disabled = true;
        document.getElementById('cssbold').style.backgroundColor = '#cccccc';
        document.getElementById('cssbold').style.borderStyle = 'outset';
        document.getElementById('cssitalic').style.backgroundColor = '#cccccc';
        document.getElementById('cssitalic').style.borderStyle = 'outset';

        var cssfont = document.allstyles.selopt1;
        var cssback = document.allstyles.selopt2;
        var cssborder = document.allstyles.selopt3;
        cssfont.checked = false;
        cssback.checked = false;
        cssborder.checked = false;
        cssfont.disabled = true;
        cssback.disabled = true;
        cssborder.disabled = true;

        if(tmpcssoption[1].match(/font\-size/g)) {
                cssfont.disabled = false;
                document.allstyles.cssfntsize.disabled = false;
                thefontsize=tmpcssoption[1].replace(/.*?font\\-size\\s*?\\:\\s*?([\\d]{1,2})\\w+?\\;.*/, "\$1");
                if(!thefontsize) thesel=0;
                else thesel=thefontsize-7;
                document.allstyles.cssfntsize.value = document.allstyles.cssfntsize.options[thesel].value;
        }
        if(tmpcssoption[1].match(/font\-family/g)) {
                cssfont.disabled = false;
                document.allstyles.cssfntface.disabled = false;
                optnumb=document.allstyles.cssfntface.options.length;
                thetmpfontface=tmpcssoption[1].replace(/.*?font\\-family\\s*?\\:\\s*?([\\D]+?)\\;.*/i, "\$1");
                thearrfontface=thetmpfontface.split(",", 1);
                thefontface = thearrfontface[0].toLowerCase();
                thefontface=thefontface.replace(/^\\s/g, "");
                thefontface=thefontface.replace(/\\s\$/g, "");
                for(i = 0; i < optnumb; i++) {
                        selfontface = document.allstyles.cssfntface.options[i].value;
                        if(selfontface == thefontface) document.allstyles.cssfntface.value = selfontface;
                }
        }

        if(tmpcssoption[1].match(/font\-weight/g)) {
                cssbold = true;
                document.getElementById('cssbold').style.backgroundColor = '#ffffff';
                thetmpfontweight=tmpcssoption[1].replace(/.*?font\\-weight\\s*?\\:\\s*?([\\D]+?)\\;.*/i, "\$1");
                if(thetmpfontweight.match(/bold/)) document.getElementById('cssbold').style.borderStyle = 'inset';
        }

        if(tmpcssoption[1].match(/font\-style/g)) {
                cssitalic = true;
                document.getElementById('cssitalic').style.backgroundColor = '#ffffff';
                thetmpfontstyle=tmpcssoption[1].replace(/.*?font\\-style\\s*?\\:\\s*?([\\D]+?)\\;.*/i, "\$1");
                if(thetmpfontstyle.match(/italic/)) document.getElementById('cssitalic').style.borderStyle = 'inset';
        }

        if(tmpcssoption[1].match(/background\-color/g)) {
                cssback.disabled = false;
                thebackcolor=tmpcssoption[1].replace(/(.*?)background\\-color\\s*?\\:(.+?)\\;(.*)/i, "\$2");
                thebackcolor=thebackcolor.replace(/\\s/g, "");
                document.allstyles.backcol.value = thebackcolor;
        }
        else {
                document.allstyles.backcol.value = '';
        }
        if(tmpcssoption[1].match(/ color/g)) {
                cssfont.disabled = false;
                thefontcolor=tmpcssoption[1].replace(/(.*?) color\\s*?\\:(.+?)\\;(.*)/i, "\$2");
                thefontcolor=thefontcolor.replace(/\\s/g, "");
                document.allstyles.textcol.value = thefontcolor;
        }
        else {
                document.allstyles.textcol.value = '';
        }

        if(tmpcssoption[1].match(/border/)) {
                cssborder.disabled = false;
                document.allstyles.borderweigth.disabled = false;
                document.allstyles.borderstyle.disabled = false;
        }
        else {
                document.allstyles.borderweigth.disabled = true;
                document.allstyles.borderstyle.disabled = true;
        }
        viewnewcolor = '';

        if(tmpcssoption[1].match(/border\\s*?\\:/)) {
                bordercol=tmpcssoption[1].replace(/.*?border\\s*?\\:(.+?)\\;.*/, "\$1");
                if(bordercol.match(/\\#[0-9a-f]{3,6}/i)) {
                        viewnewcolor=bordercol;
                }
        }
        if(tmpcssoption[1].match(/border\\-top\\s*?\\:/)) {
                bordertopcol=tmpcssoption[1].replace(/.*?border\\-top\\s*?\\:(.+?)\\;.*/, "\$1");
                if(bordertopcol.match(/\\#[0-9a-f]{3,6}/i)) {
                        viewnewcolor=bordertopcol;
                }
        }
        if(tmpcssoption[1].match(/border\\-bottom\\s*?\\:/)) {
                borderbottomcol=tmpcssoption[1].replace(/.*?border\\-bottom\\s*?\\:(.+?)\\;.*/, "\$1");
                if(borderbottomcol.match(/\\#[0-9a-f]{3,6}/i)) {
                        viewnewcolor=borderbottomcol;
                }
        }
        if(tmpcssoption[1].match(/border\\-left\\s*?\\:/)) {
                borderleftcol=tmpcssoption[1].replace(/.*?border\\-left\\s*?\\:(.+?)\\;.*/, "\$1");
                if(borderleftcol.match(/\\#[0-9a-f]{3,6}/i)) {
                        viewnewcolor=borderleftcol;
                }
        }
        if(tmpcssoption[1].match(/border\\-right\\s*?\\:/)) {
                borderrightcol=tmpcssoption[1].replace(/.*?border\\-right\\s*?\\:(.+?)\\;.*/, "\$1");
                if(borderrightcol.match(/\\#[0-9a-f]{3,6}/i)) {
                        viewnewcolor=borderrightcol;
                }
        }
        thebordercolor=viewnewcolor.replace(/.*?(\\#[0-9a-f]{3,6}).*/i, "\$1");
        nocolor=viewnewcolor.replace(/(.*?)(\\#[0-9a-f]{3,6})(.*)/i, "\$1\$3");
        optnumb=document.allstyles.borderstyle.options.length;
        theborderstyle=viewnewcolor.replace(/.*?(solid|dashed|dotted|double|groove|ridge|inset|outset).*/i, "\$1");
        theborderstyle = theborderstyle.toLowerCase();
        theborderstyle=theborderstyle.replace(/^\\s/g, "");
        theborderstyle=theborderstyle.replace(/\\s\$/g, "");
        for(i = 0; i < optnumb; i++) {
                selborderstyle = document.allstyles.borderstyle.options[i].value;
                if(selborderstyle == theborderstyle) document.allstyles.borderstyle.value = selborderstyle;
        }

        thebordersize=nocolor.replace(/.*?([\\d]{1,2}).*/i, "\$1");
        if(!thebordersize) thebordersize=0;
        document.allstyles.bordcol.value = thebordercolor;
        document.allstyles.borderweigth.value = document.allstyles.borderweigth.options[thebordersize].value;

        if (cssfont.disabled == false) {
                cssfont.checked = true;
        }
        else if (cssback.disabled == false) {
                cssback.checked = true;
        }
        else if (cssborder.disabled == false) {
                cssborder.checked = true;
        }
        manSelect();
}

initStyles();
setElement();

// Palette
var thistask = 'templ';
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

function ConvShowcolor(color) {
        if ( c=color.match(/rgb\\((\\d+?)\\, (\\d+?)\\, (\\d+?)\\)/i) ) {
                var rhex = tohex(c[1]);
                var ghex = tohex(c[2]);
                var bhex = tohex(c[3]);
                var newcolor = '#'+rhex+ghex+bhex;
        }
        else {
                var newcolor = color;
        }
        if(thistask == "post") showcolor(newcolor);
        if(thistask == "templ") previewColor(newcolor);
}
</script>
~;
    $yytitle     = $templ_txt{'1'};
    $action_area = 'modcss';
    AdminTemplate();
    return;
}

sub ModifyCSS2 {
    is_admin_or_gmod();
    if ( $FORM{'button'} == 1 ) {
        $yySetLocation = qq~$adminurl?action=modcss;cssfile=$FORM{'cssfile'}~;
        redirectexit();

    }
    elsif ( $FORM{'button'} == 2 ) {
        $style_name = $FORM{'savecssas'};
        if ( $style_name eq 'default' ) {
            fatal_error('no_delete_default');
        }
        if (   $style_name !~ m{\A[0-9a-zA-Z_\.\#\%\-\:\+\?\$\&\~\.\,\@/]+\Z}sm
            || $style_name eq q{} )
        {
            fatal_error('invalid_template');
        }
        $style_cnt = $FORM{'stylelink'};
        FromHTML($style_cnt);
        $style_cnt =~ s/(\*\/)/$1\n\n/gsm;
        $style_cnt =~ s/(\/\*)/\n$1/gsm;
        $style_cnt =~ s/(\{)/$1\n/gsm;
        $style_cnt =~ s/(\})/$1\n/gsm;
        $style_cnt =~ s/(\;)/$1\n/gsm;
        @style_arr = split /\n/xsm, $style_cnt;

        fopen( TMPCSS, ">$htmldir/Templates/Forum/$style_name.css" )
          || fatal_error( 'cannot_open',
            "$htmldir/Templates/Forum/$style_name.css", 1 );
        foreach my $style_sgl (@style_arr) {
            $style_sgl =~ s/\A\s+?//gxsm;
            if ( $style_sgl =~ m{\;+\Z}sm ) { $style_sgl = qq~\t$style_sgl~; }
            $style_sgl =~ s/$yyhtml_root\/Templates\/Forum/\./gsm;
            $style_sgl =~ s/$yyhtml_root/\.\.\/\.\./gsm;
            print {TMPCSS} "$style_sgl\n" or croak "$croak{'print'} TMPCSS";
        }
        fclose(TMPCSS);

        $yySetLocation = qq~$adminurl?action=modcss;cssfile=$style_name.css~;
        redirectexit();

    }
    elsif ( $FORM{'button'} == 3 ) {
        $style_name = $FORM{'cssfile'};
        if ( $style_name eq 'default.css' ) {
            fatal_error('no_delete_default');
        }
        unlink "$htmldir/Templates/Forum/$style_name";
        $yySetLocation = qq~$adminurl?action=modcss;cssfile=default.css~;
        redirectexit();
    }
    return;
}

1;