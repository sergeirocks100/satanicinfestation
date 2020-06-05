###############################################################################
# Backup.pm                                                                   #
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
# Many thanks to AK108 (http://fkp.jkcsi.com/)                                #
# for his contribution to the YaBB community                                  #
###############################################################################
# use strict;
# use warnings;
# no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
use English '-no_match_vars';
our $VERSION = '2.6.11';

$backuppmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

# Add in support for Archive::Tar in the Modules directory and binaries in different places
@ENVpaths = split /\:/xsm, $ENV{'PATH'};

LoadLanguage('Backup');
$yytitle     = $backup_txt{1};
$action_area = 'backupsettings';

my $curtime = CORE::time;    # None of that Time::HiRes stuff

my %dirs = (
    'src'  => "Admin/ $backup_txt{'and'} Sources/",
    'bo'   => 'Boards/',
    'lan'  => "Languages/ $backup_txt{'and'} Help/",
    'mem'  => 'Members/',
    'mes'  => 'Messages/',
    'temp' => "Templates/ $backup_txt{10}",
    'var'  => 'Variables/',
    'html' => 'yabbfiles',
    'upld' => "yabbfiles/Attachments, yabbfiles/PMAttachments, $backup_txt{'and'} yabbfiles/avatars",
);

is_admin_or_gmod();

sub backupsettings {
    my (
        $module,        $command,         $tarcompress1,
        $tarcompress2,  $allchecked,      $item,
        %pathchecklist, %methodchecklist, $presetjavascriptcode,
        $file,          @backups,         $newcommand,
        $style,         $disabledtext,    $input
    );

    if ( $INFO{'backupspendtime'} ) {
        $yymain .=
qq~<b>$backup_txt{33} $INFO{'backupspendtime'} $backup_txt{34}</b><br /><br />~;
    }
    if ( $INFO{'mailinfo'} == 1 ) {
        $yymain .=
qq~<span class="good"><b>$backup_txt{'mailsuccess'}</b></span><br /><br />~;
    }
    if ( $INFO{'mailinfo'} == -1 ) {
        $yymain .=
qq~<span class="important"><b>$backup_txt{'mailfail'}</b></span><br /><br />~;
    }

    # Yes, my checklists are really hashes. Oh well.
    foreach my $item (@backup_paths) {
        $pathchecklist{$item} = 'checked="checked" ';
    }
    if ( @backup_paths == 9 ) { $allchecked = 'checked="checked" '; }

    $methodchecklist{$backupmethod}   = 'checked="checked" ';
    $methodchecklist{$compressmethod} = 'checked="checked" ';

    # domodulecheck if we have a checked value
    $presetjavascriptcode = qq~ domodulecheck("$backupmethod", 'init');~;

    # Javascript to make the behavior of the form buttons work better
    $yymain .= qq~
<script type="text/javascript">
   function checkYaBB () {
        // See if the check all box should be checked or unchecked.
        // It should be checked only if all the other boxes are checked.
        if (document.backupsettings.YaBB_bo.checked && document.backupsettings.YaBB_mes.checked && document.backupsettings.YaBB_mem.checked && document.backupsettings.YaBB_temp.checked && document.backupsettings.YaBB_lan.checked && document.backupsettings.YaBB_var.checked && document.backupsettings.YaBB_src.checked && document.backupsettings.YaBB_html.checked && document.backupsettings.YaBB_upld.checked) {
            document.backupsettings.YaBB_ALL.checked = 1;
        } else {
            document.backupsettings.YaBB_ALL.checked = 0;
        }
    }

    function masscheckYaBB (toggleboxstate) {
        if(!toggleboxstate) { // Uncheck all
            checkstate = 0;
        } else if(toggleboxstate) { // Check all
            checkstate = 1;
        }
        document.backupsettings.YaBB_bo.checked = checkstate;
        document.backupsettings.YaBB_mes.checked = checkstate;
        document.backupsettings.YaBB_mem.checked = checkstate;
        document.backupsettings.YaBB_temp.checked = checkstate;
        document.backupsettings.YaBB_lan.checked = checkstate;
        document.backupsettings.YaBB_var.checked = checkstate;
        document.backupsettings.YaBB_src.checked = checkstate;
        document.backupsettings.YaBB_html.checked = checkstate;
        document.backupsettings.YaBB_upld.checked = checkstate;
    }

    function domodulecheck (module, initstate) {
        if(module == "Archive::Tar") {
            for(i = 0; document.getElementsByName("tarmodulecompress")[i]; i++) {
                document.getElementsByName("tarmodulecompress")[i].disabled = false;
            }
            if(!initstate) {
                document.getElementsByName("tarmodulecompress")[0].checked = true;
            }
        } else {
            for(i = 0; document.getElementsByName("tarmodulecompress")[i]; i++) {
                document.getElementsByName("tarmodulecompress")[i].disabled = true;
            }
        }

        if(module == "$backupprogusr/tar") {
            for(i = 0; document.getElementsByName("bintarcompress")[i]; i++) {
                document.getElementsByName("bintarcompress")[i].disabled = false;
            }
            if(!initstate) {
                document.getElementsByName("bintarcompress")[0].checked = true;
            }
        } else {
            for(i = 0; document.getElementsByName("bintarcompress")[i]; i++) {
                document.getElementsByName("bintarcompress")[i].disabled = true;
            }
        }
    }
</script>
<form action="$adminurl?action=backupsettings2" method="post" name="backupsettings" onsubmit="savealert()" accept-charset="$yymycharset">
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">$admin_img{'prefimg'} <b>$backup_txt{1}</b></td>
        </tr>~;

    if ( !$backupsettingsloaded ) {
        $yymain .= qq~<tr>
            <td class="catbg"><b>$backup_txt{2}</b></td>
        </tr><tr>
            <td>&nbsp;</td>
        </tr>~;
    }

    $yymain .= qq~<tr>
            <td class="windowbg">$backup_txt{3}</td>
        </tr><tr>
            <td class="catbg"><b>$backup_txt{4}</b></td>
        </tr><tr>
            <td class="windowbg">
                <input type="checkbox" name="YaBB_ALL" id="YaBB_ALL" value="1" onclick="masscheckYaBB(this.checked)" $allchecked /> <label for="YaBB_ALL">$backup_txt{5}<br />
                $backup_txt{6}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_src" id="YaBB_src" value="1" $pathchecklist{'src'}/> <label for="YaBB_src">Admin/ $backup_txt{'and'} Sources/ $backup_txt{13}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_bo" id="YaBB_bo" value="1" $pathchecklist{'bo'}/> <label for="YaBB_bo">Boards/ $backup_txt{7}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_lan" id="YaBB_lan" value="1" $pathchecklist{'lan'}/> <label for="YaBB_lan">Languages/ $backup_txt{'and'} Help/ $backup_txt{11}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_mem" id="YaBB_mem" value="1" $pathchecklist{'mem'}/> <label for="YaBB_mem">Members/ $backup_txt{9}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_mes" id="YaBB_mes" value="1" $pathchecklist{'mes'}/> <label for="YaBB_mes">Messages/ $backup_txt{8}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_temp" id="YaBB_temp" value="1" $pathchecklist{'temp'}/> <label for="YaBB_temp">Templates/ $backup_txt{10} $backup_txt{'10a'}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_var" id="YaBB_var" value="1" $pathchecklist{'var'}/> <label for="YaBB_var">Variables/ $backup_txt{12}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_html" id="YaBB_html" value="1" $pathchecklist{'html'}/> <label for="YaBB_html">yabbfiles $backup_txt{14}</label>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <input type="checkbox" onclick="checkYaBB()" name="YaBB_upld" id="YaBB_upld" value="1" $pathchecklist{'upld'}/> <label for="YaBB_upld">yabbfiles/Attachments, yabbfiles/PMAttachments, $backup_txt{'and'} yabbfiles/avatars $backup_txt{'14a'}</label>
            </td>
        </tr><tr>
            <td class="catbg"><b>$backup_txt{15}</b></td>
        </tr><tr>
            <td class="windowbg">$backup_txt{16}</td>
        </tr>~;

    # Make a list of modules that we can use with Tar::Archive
    $tarcompress1 = qq~<tr>
            <td class="windowbg">
                <input type="radio" name="tarmodulecompress" id="tarmodulecompress" value="none" $methodchecklist{'none'}/> <label for="tarmodulecompress">$backup_txt{17}</label>
            </td>
        </tr>~;

    my $label_id;
    foreach my $module (qw(Compress::Zlib Compress::Bzip2)) {
        $label_id++;
        $input =
qq~name="tarmodulecompress" id="label_$label_id" value="$module" $methodchecklist{$module}~;
        eval "use $module();";
        if ($@) {
            $input        = qq~disabled="disabled" id="label_$label_id"~;
            $style        = q~backup-disabled~;
            $disabledtext = $backup_txt{41};
        }
        else {
            ( $style, $disabledtext ) = ( q{}, q{} );
        }
        $tarcompress1 .= qq~<tr>
            <td class="windowbg $style">
                <input type="radio" $input/> <label for="label_$label_id">$module $backup_txt{18} $disabledtext</label>
            </td>
        </tr>~;
    }

    $tarcompress1 .= q~<tr>
            <td class="windowbg">&nbsp;</td>
        </tr>~;

    # Make a list of compression commands we can use with /usr/bin/tar
    $tarcompress2 = qq~<tr>
            <td class="windowbg">
                <input type="radio" name="bintarcompress" id="bintarcompress" value="none" $methodchecklist{'none'}/> <label for="bintarcompress">$backup_txt{17}</label>
            </td>
        </tr>~;

    foreach my $command ( "$backupprogbin/gzip", "$backupprogbin/bzip2" ) {
        $label_id++;
        $input =
qq~name="bintarcompress" id="label_$label_id" value="$command" $methodchecklist{$command}~;
        $newcommand = CheckPath($command);
        if ( !$newcommand ) {
            $input        = qq~disabled="disabled" id="label_$label_id"~;
            $style        = q~backup-disabled~;
            $disabledtext = $backup_txt{41};
            $newcommand   = $command;
        }
        else {
            ( $style, $disabledtext ) = ( q{}, q{} );
        }
        $tarcompress2 .= qq~<tr>
            <td class="windowbg $style">
                <input type="radio" $input/> <label for="label_$label_id">$newcommand $backup_txt{18} $disabledtext</label>
            </td>
        </tr>~;
    }

    $tarcompress2 .= q~<tr>
            <td class="windowbg">&nbsp;</td>
        </tr>~;

# Display the commands we can use for compression
# Non-translated here, as I doubt there are words to describe "tar" in another language
    $input =
qq~name="backupmethod" id="backupmethod1" value="$backupprogusr/tar" onclick="domodulecheck('$backupprogusr/tar')" $methodchecklist{"$backupprogusr/tar"}~;
    $newcommand = CheckPath("$backupprogusr/tar");
    if ($newcommand) {
        if (
            ak_system(
                "tar -cf $vardir/backuptest.$curtime.tar ./$yyexec.$yyext")
          )
        {
            ( $style, $disabledtext ) = ( q{}, q{} );
            unlink "$vardir/backuptest.$curtime.tar";
        }
        else {
            $input        = qq~disabled="disabled" id="backupmethod1"~;
            $style        = q~backup-disabled~;
            $disabledtext = ": Tar $backup_txt{31}: $!. $backup_txt{32} "
              . ( $CHILD_ERROR >> 8 );
        }
    }
    else {
        $input        = qq~disabled="disabled" id="backupmethod1"~;
        $style        = q~backup-disabled~;
        $disabledtext = $backup_txt{41};
    }
    $yymain .= qq~<tr>
            <td class="windowbg2"><label for="backupprogusr">$backup_txt{'path1'}</label> <input id="backupprogusr" type="text" value="$backupprogusr" size="20" name="backupprogusr" />
                <br /><label for="backupprogbin">$backup_txt{'path2'}</label> <input id="backupprogbin" type="text" value="$backupprogbin" size="20" name="backupprogbin" />
                <br />$backup_txt{'path3'}
            </td>
        </tr><tr>
            <td class="windowbg2 $style">
                <input type="radio" $input/> <label for="backupmethod1">Tar ($newcommand) $disabledtext</label>
            </td>
        </tr>$tarcompress2~;

    $input =
qq~name="backupmethod" id="backupmethod2" value="$backupprogusr/zip" onclick="domodulecheck('$backupprogusr/zip')" $methodchecklist{"$backupprogusr/zip"}~;
    $newcommand = CheckPath("$backupprogusr/zip");
    if ($newcommand) {
        if (
            ak_system(
                "zip -gq $vardir/backuptest.$curtime.zip ./$yyexec.$yyext")
          )
        {
            ( $style, $disabledtext ) = ( q{}, q{} );
            unlink "$vardir/backuptest.$curtime.zip";
        }
        else {
            $input        = qq~disabled="disabled" id="backupmethod2"~;
            $style        = q~backup-disabled~;
            $disabledtext = ": Zip $backup_txt{31}: $!. $backup_txt{32} "
              . ( $CHILD_ERROR >> 8 );
        }
    }
    else {
        $input        = qq~disabled="disabled" id="backupmethod2"~;
        $style        = q~backup-disabled~;
        $disabledtext = $backup_txt{41};
    }
    $yymain .= qq~<tr>
            <td class="windowbg2 $style">
                <input type="radio" $input/> <label for="backupmethod2">Zip ($newcommand) $disabledtext</label>
            </td>
        </tr><tr>
            <td class="windowbg">&nbsp;</td>
        </tr>~;

    # Display the modules that we can use
    foreach my $module (qw(Archive::Tar Archive::Zip)) {
        $i++;
        $input =
qq~name="backupmethod" id="backupmethod3_$i" value="$module" onclick="domodulecheck('$module')" $methodchecklist{$module}~;
        eval "use $module();";
        if ($@) {
            $input        = qq~disabled="disabled" id="backupmethod3_$i"~;
            $style        = q~backup-disabled~;
            $disabledtext = $backup_txt{41};
        }
        else {
            ( $style, $disabledtext ) = ( q{}, q{} );
        }
        $yymain .= qq~<tr>
            <td class="windowbg2 $style">
                <input type="radio" $input/> <label for="backupmethod3_$i">$module $disabledtext</label>
            </td>
        </tr>~;
        if ( $module eq 'Archive::Tar' ) { $yymain .= $tarcompress1; }
    }

    # Last but not least, the submit button and the $backupdir path.
    $backupdir ||= "$boarddir/Backups";
    if ( $backupdir =~ s/^\.\///xsm ) {
        $ENV{'SCRIPT_FILENAME'} =~ /(.*\/)/xsm;
        $backupdir = "$1$backupdir";
    }
    $yymain .= qq~<tr>
            <td class="catbg"><b>$backup_txt{19}</b></td>
        </tr><tr>
            <td class="windowbg2">
                <label for="backupdir">$backup_txt{'19a'}</label>: <input type="text" name="backupdir" id="backupdir" value="$backupdir" size="80" />
            </td>
        </tr><tr>
            <td class="catbg"><b>$backup_txt{'19b'}</b></td>
        </tr><tr>
            <td class="windowbg2">
                <label for="rememberbackup">$backup_txt{'19c'}</label> <input type="text" name="rememberbackup" id="rememberbackup" value="~
      . ( $rememberbackup / 86_400 )
      . qq~" size="3"/> <label for="rememberbackup">$backup_txt{'19d'}</label>
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
                <input type="submit" value="$backup_txt{20}" class="button" />
            </td>
        </tr>
    </table>
    </div>
</form>
<script type="text/javascript">
$presetjavascriptcode

    function BackupNewest(lastbackup) {
        document.getElementsByName("backupnewest")[0].value = lastbackup;
        if (!window.submitted) {
            window.submitted = true;
            document.runbackup.submit();
        }
    }
</script>~;

    # Here we go again with another table. Here is the backup button area
    if ($backupsettingsloaded) {

        # Look for the files.
        opendir BACKUPDIR, $backupdir;
        @backups = readdir BACKUPDIR;
        closedir BACKUPDIR;

        my ( $lastbackupfiletime, $filename );
        foreach my $file (
            map          { $_->[0] }
            reverse sort { $a->[1] <=> $b->[1] }
            map          { [ $_, /(\d+)/xsm, $_ ] } @backups
          )
        {
            if ( $file !~ /\A(backup)(n?)\.(\d+)\.([^\.]+)\.(.+)/xsm ) { next; }
            if ( !$lastbackupfiletime ) { $lastbackupfiletime = $3; }
            my $filesize = -s "$backupdir/$file";
            $filesize = int( $filesize / 1024 );    # Measure it in kilobytes
            if ( $filesize > 1024 * 4 ) {
                $filesize = int( $filesize / 1024 ) . ' MB';
            }                                       # Measure it in megabytes
            else { $filesize .= ' KB'; }            # Label it
            my @dirs;
            foreach ( split /_/xsm, $4 ) {
                push @dirs, $dirs{$_};
            }

            $filename = "$1$2.$3.$4.$5";
            $filelist .= q~            <tr>
                <td>~
              . timeformat($3) . qq~</td>
                <td class="right">$filesize</td>
                <td>- ~
              . join( '<br />- ', @dirs ) . q~</td>
                <td>~
              . (
                $2
                ? "<abbr title='$backup_txt{62}'>$backup_txt{'62a'}</abbr><br />"
                : q{}
              )
              . qq~$5</td>
                <td><a href="$adminurl?action=downloadbackup;backupid=$file">$backup_txt{60}</a></td>
                <td><a href="$adminurl?action=emailbackup;backupid=$file">$backup_txt{52}</a></td>
                <td><a href="$adminurl?action=runbackup;runbackup_again=$1$2.0.$4.$5">$backup_txt{61}</a>
                    <br /><a href="$adminurl?action=runbackup;runbackup_again=$filename">$backup_txt{62}</a></td>
                <td class="center">~
              . (
                ( $5 =~ /^a\.tar/xsm || $5 !~ /tar/xsm )
                ? q{-}
                : qq~<a href="$adminurl?action=recoverbackup1;recoverfile=$filename">$backup_txt{63}</a>~
              )
              . qq~</td>
                <td><a href="$adminurl?action=deletebackup;backupid=$file">$backup_txt{53}</a></td>
            </tr>~;
        }

        $filelist ||= qq~<tr>
                <td colspan="9"><i>$backup_txt{38}</i></td>
            </tr>~;

        $yymain .= qq~
<form action="$adminurl?action=runbackup" method="post" name="runbackup">
<input type="hidden" name="backupnewest" value="0" />
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$backup_txt{21}</b></td>
    </tr><tr>
        <td class="windowbg2" colspan="2">
            $backup_txt{22} <span style="font-family: monospace;">$backupdir</span> $backup_txt{23}
            <br />
            <br />
            $backup_txt{24}
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
            <input type="button" name="submit1" value="$backup_txt{25}" onclick="BackupNewest(0);" class="button" />~;
        if ( $lastbackupfiletime && $lastbackup == $lastbackupfiletime ) {
            $lastbackupfiletime = timeformat( $lastbackup, 1 );
            $lastbackupfiletime =~ s/<.*?>//gxsm;
            if ( $backupmethod eq "$backupprogusr/zip" ) {
                @lbt = split / /sm, $lastbackupfiletime;
                $lastbackupfiletime = join q{ }, $lbt[0], $lbt[1], $lbt[2];
            }
            $yymain .= qq~
            <div style="margin-top: .5em;"><input type="button" name="submit2" value="$backup_txt{'25a'} $lastbackupfiletime" onclick="BackupNewest($lastbackup);" class="button" /></div>~;
        }
        $yymain .= qq~
        </td>
    </tr>
</table>
</div>
</form>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$backup_txt{35}</b></td>
    </tr><tr>
        <td class="windowbg2" colspan="2">
            $backup_txt{37} <i>${$uid.$username}{'email'}</i> $backup_txt{'37a'}<br />
            $backup_txt{36} <span style="font-family: monospace;">$backupdir</span>
            <table class="border-space pad-cell border">
                <tr>
                    <td class="center">$backup_txt{70}</td>
                    <td class="center">$backup_txt{71}</td>
                    <td class="center">$backup_txt{72}</td>
                    <td class="center">$backup_txt{73}</td>
                    <td class="center" colspan="5">$backup_txt{74}</td>
                </tr>
                $filelist
            </table>
        </td>
    </tr>
</table>
</div>~;
    }

    AdminTemplate();
    return;
}

sub backupsettings2 {
    $backupmethod = $FORM{'backupmethod'};
    $compressmethod =
         $FORM{'bintarcompress'}
      || $FORM{'tarmodulecompress'}
      || 'none';

    # Handle the paths.
    @backup_paths = ();
    if ( $FORM{'YaBB_ALL'} )
    { # handle the magic select all checkbox so Javascript can be disabled and it still work
        @backup_paths = qw(src bo lan mem mes temp var html upld);
    }
    else {
        foreach (qw(src bo lan mem mes temp var html upld)) {
            if ( $FORM{ 'YaBB_' . $_ } ) { push @backup_paths, $_; }
        }
    }

    check_backup_settings();

    # Set $backupdir
    if ( !-w $FORM{'backupdir'} ) {
        fatal_error( q{},
            "$backup_txt{42} '$FORM{'backupdir'}'. $backup_txt{43}" );
    }

    $backupdir     = $FORM{'backupdir'};
    $backupprogusr = $FORM{'backupprogusr'};
    $backupprogbin = $FORM{'backupprogbin'} || '/usr/bin';

    $lastbackup = 0;    # reset when saving settings new
    print_BackupSettings();

    # Set $rememberbackup for alert into Settings.pm
    if ( $rememberbackup != $FORM{'rememberbackup'} ) {
        $rememberbackup = $FORM{'rememberbackup'};
        fopen( SETTINGS, "$vardir/Settings.pm" );
        @settings = <SETTINGS>;
        fclose(SETTINGS);
        for my $i ( 0 .. ( @settings - 1 ) ) {
            if ( $settings[$i] =~ /\$rememberbackup = \d+;/sm ) {
                if ( !$rememberbackup ) { $rememberbackup = 0; }
                $rememberbackup *= 86_400;    # days in seconds
                $settings[$i] =~
s/\$rememberbackup = \d+;/\$rememberbackup = $rememberbackup;/sm;
            }
        }

        # if \$rememberbackup = is not allready in Settings.pm
        if ( $rememberbackup && $rememberbackup == $FORM{'rememberbackup'} ) {
            $rememberbackup *= 86_400;        # days in seconds
            unshift @settings, "\$rememberbackup = $rememberbackup;\n";
        }
        fopen( SETTINGS, ">$vardir/Settings.pm" );
        print {SETTINGS} @settings or croak "$croak{'print'} SETTINGS";
        fclose(SETTINGS);
    }

    $yySetLocation = qq~$adminurl?action=backupsettings~;
    redirectexit();
    return;
}

sub check_backup_settings {
    if ( !@backup_paths ) { fatal_error( q{}, "$backup_txt{3}" ); }

    if ( !$backupmethod ) { fatal_error( q{}, "$backup_txt{29}" ); }

    if ( $backupmethod =~ /::/xsm ) {    # It is a module, test-require it
        eval "use $backupmethod();";
        if ($@) {
            fatal_error( q{}, "$backup_txt{39} $backupmethod $backup_txt{41}" );
        }
    }
    else {
        my $newcommand = CheckPath($backupmethod);
        if ( !$newcommand ) {
            fatal_error( q{}, "$backup_txt{40} $backupmethod $backup_txt{41}" );
        }
    }

    # If we are using $backupprogusr/tar, check for the compression method.
    if ( $backupmethod eq "$backupprogusr/tar" && $compressmethod ne 'none' ) {
        my $newcommand = CheckPath($compressmethod);
        if ( !$newcommand ) {
            fatal_error( q{},
                "$backup_txt{40} $compressmethod $backup_txt{41}" );
        }
    }

    # If we are using Archive::Tar, check for the compression method.
    elsif ( $backupmethod eq 'Archive::Tar' && $compressmethod ne 'none' ) {
        eval "use $compressmethod();";
        if ($@) {
            fatal_error( q{},
                "$backup_txt{39} $compressmethod $backup_txt{41}" );
        }
    }
    else {
        $compressmethod = 'none';
    }
    return;
}

sub print_BackupSettings {
    my @newpaths;
    foreach my $path (qw(src bo lan mem mes temp var html upld)) {
        foreach (@backup_paths) {
            if ( $_ eq $path ) { push @newpaths, $path; last; }
        }
    }
    @backup_paths         = @newpaths;
    $backupsettingsloaded = 1;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');
    return;
}

# This routine actually does the backup.
sub runbackup {
    my ( @settings, %pathconvert );

    if ( $INFO{'runbackup_again'} ) {
        fatal_error( q{},
            "$backup_txt{32} \$INFO{'runbackup_again'}=$INFO{'runbackup_again'}"
        ) if $INFO{'runbackup_again'} !~ /^backup/xsm;

        my @again = split /\./xsm, $INFO{'runbackup_again'};
        $FORM{'backupnewest'} = $again[1];
        @backup_paths = split /_/xsm, $again[2];
        if ( $again[3] eq 'a' ) {
            $backupmethod =
              $again[4] eq 'tar' ? 'Archive::Tar' : 'Archive::Zip';
            $compressmethod =
              $again[5]
              ? ( $again[5] eq 'gz' ? 'Compress::Zlib' : 'Compress::Bzip2' )
              : 'none';
        }
        else {
            $backupmethod =
              $again[3] eq 'tar' ? "$backupprogusr/tar" : "$backupprogusr/zip";
            $compressmethod =
              $again[4]
              ? (
                $again[4] eq 'gz'
                ? "$backupprogbin/gzip"
                : "$backupprogbin/bzip2"
              )
              : 'none';
        }
        check_backup_settings();
    }

    my $backuptime = $INFO{'backuptime'} || time;

    my $time_to_jump = time + $max_process_time;

    $curtime = $INFO{'curtime'} || $curtime;
    $FORM{'backupnewest'} ||= $INFO{'backupnewest'};
    if ( $FORM{'backupnewest'} ) { $backuptype = 'n'; }
    if ( $FORM{'backupnewest'} && $backupmethod eq "$backupprogusr/zip" ) {
        my ( undef, undef, undef, $day, $mon, $year, undef, undef, undef ) =
          gmtime $FORM{'backupnewest'};
        $FORM{'backupnewest'} =
            sprintf( '%02d', ( $mon + 1 ) )
          . sprintf( '%02d', $day )
          . ( 1900 + $year );
    }
    elsif ( $FORM{'backupnewest'} && $backupmethod =~ /::/xsm ) {
        $FORM{'backupnewest'} = ( $curtime - $FORM{'backupnewest'} ) / 86_400;
    }
    my $filedirs = join q{_}, @backup_paths;

    # Verify that our method is possible, and load it if it is a module
    BackupMethodInit($filedirs);

# Handle the conversion of the informal backup_paths stored in the settings file to the real ones
# We will build a hash to quickly match them.
# A pipe separates them in the case of needing multiple real paths to handle one informal path

    $boarddir = $support_env_path;

    %pathconvert = (
        'src'  => "!$boarddir|$boarddir/Admin|$boarddir/Sources|$boarddir/Modules",
        'bo'   => $boardsdir,
        'lan'  => "$langdir|$helpfile",
        'mem'  => $memberdir,
        'mes'  => $datadir,
        'temp' => "$boarddir/Templates|$htmldir/Templates",
        'var'  => $vardir,
        'html' => "!$htmldir|$htmldir/Bookmarks|$htmldir/Buttons|$htmldir/EventIcons|$htmldir/googiespell|$htmldir/greybox|$htmldir/ModImages|$htmldir/shjs|$htmldir/Smilies",
        'upld' => "$htmldir/Attachments|$htmldir/PMAttachments|$htmldir/avatars",
    );

    # Set the forum to maintenance mode.
    automaintenance('on');

    # Looping to prevent running into browser/server timeout
    my ( $i, $j, $key, $path );
    foreach my $key (@backup_paths) {
        $i++;
        if ( $i >= $INFO{'loop1'} ) {
            $j = 0;
            foreach my $path ( split /\|/xsm, $pathconvert{$key} ) {
                $j++;
                if ( $j > $INFO{'loop2'} ) {
                    $INFO{'loop2'} = 0;

# To keep this simple, I will just point to a generic subroutine that takes care of
# handling the differences in backup methods.
                    if ( $path =~ s/^\.\///xsm ) {
                        $ENV{'SCRIPT_FILENAME'} =~ /(.*\/)/xsm;
                        $path = "$1$path";
                    }
                    BackupDirectory( $path, $filedirs );

                    if ( time() > $time_to_jump ) {
                        BackupMethodFinalize( $filedirs, 1 );
                        runbackup_loop( $i, $j, $curtime, $FORM{'backupnewest'},
                            $backuptime );
                    }
                }
            }
            $INFO{'loop2'} = 0;
        }
    }

 # Last, we will finalize the archive. If it is a tar, we compress them,
 # if requested. This can NOT be done with the forum out of maintenance mode
 # due to the maintenance.lock file that is removed with &automaintenance('off')
    BackupMethodFinalize( $filedirs, 0 );

    # Undo maintenance mode.
    automaintenance('off');

    $lastbackup = $curtime; # save the last backup time with the actual settings
    print_BackupSettings();

    # Display the amount of time it took to be nice ;)
    $yySetLocation =
      qq~$adminurl?action=backupsettings;backupspendtime=~ . sprintf '%.4f',
      ( time() - $backuptime );
    redirectexit();
    return;
}

# Checks once more that we can use the command or module given. If we can, we load module(s) here.
sub BackupMethodInit {
    my $filedirs = shift;

    # Check module types and load them at runtime (not compilation)
    if ( $backupmethod eq 'Archive::Tar' ) {
        eval 'use Archive::Tar;';    # Everything is exported at once
        if ($@) {
            fatal_error( q{}, "$backup_txt{28} Archive::Tar: $@" );
        }
        if ( $compressmethod eq 'Compress::Zlib' ) {    # Also using Zlib
            eval 'use Compress::Zlib;';    # Zlib exports everything at once
            if ($@) {
                fatal_error( q{}, "$backup_txt{28} Compres::Zlib: $@" );
            }
        }
        elsif ( $compressmethod eq 'Compress::Bzip2' ) {
            eval 'use Compress::Bzip2 qw(:utilities);'
              ;    # Finally, something I can export just some code with
            if ($@) {
                fatal_error( q{}, "$backup_txt{28} Compress::Bzip2: $@" );
            }
        }
        else { $compressmethod = 'none'; }

        $tarball = Archive::Tar->new;

# We need this for the loops to keep from running into browser/server timeout.
        if ( -e "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar" ) {
            $tarball->read(
                "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar", 0 );
            unlink "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar";
        }
    }
    elsif ( $backupmethod eq 'Archive::Zip' ) {
        eval 'use Archive::Zip;';    # Everything is exported by default here too
        if ($@) {
            fatal_error( q{}, "$backup_txt{28} Archive::Zip: $@" );
        }
        $zipfile = Archive::Zip->new;

# We need this for the loops, when preventing to run into browser/server timeout.
        if ( -e "$backupdir/backup$backuptype.$curtime.$filedirs.a.zip" ) {
            $zipfile->read(
                "$backupdir/backup$backuptype.$curtime.$filedirs.a.zip");
        }
    }
    else {
        if ( !CheckPath($backupmethod) ) {
            fatal_error( q{}, "$backup_txt{29} $backupmethod." );
        }
        if ( $compressmethod ne 'none' && !CheckPath($compressmethod) ) {
            fatal_error( q{}, "$backup_txt{30} $compressmethod." );
        }
    }
    return;
}

sub BackupDirectory {

    # Handles all the fun of directly archiving a directory.
    my ( $dir, $filedirs ) = @_;
    my ( $recursemode, $cr, $Nt );
    $recursemode = 1;
    if ( $dir =~ s/^!//xsm ) { $recursemode = 0; }

    if ( $backupmethod eq "$backupprogusr/tar" ) {
        $cr = ( $tarcreated || $INFO{'curtime'} ) ? '-r' : '-c';
        $tarcreated = 1;
        if ( !$recursemode ) { $dir .= '/*.*'; }
        if ( $FORM{'backupnewest'} ) { $Nt = "-N \@$FORM{'backupnewest'}"; }
        $dir =~ s/^\///xsm;

    # needed not to get server log messages like "Removing leading `/' from ..."
        ak_system(
"tar $cr -C / -f $backupdir/backup$backuptype.$curtime.$filedirs.tar $Nt $dir"
          )
          || fatal_error(
            q{},
"'tar $cr -C / -f $backupdir/backup$backuptype.$curtime.$filedirs.tar $Nt $dir' $backup_txt{31}: $!. $backup_txt{32} "
              . ( $CHILD_ERROR >> 8 )
          );
    }
    elsif ( $backupmethod eq "$backupprogusr/zip" ) {
        my $recurseoption;
        if ( !$recursemode ) { $dir .= '/*.*'; }
        else                 { $recurseoption = 'r'; }
        if ( $FORM{'backupnewest'} ) { $Nt = "-t $FORM{'backupnewest'}"; }
        ak_system(
"zip -gq$recurseoption $Nt $backupdir/backup$backuptype.$curtime.$filedirs.zip $dir"
          )
          || fatal_error(
            q{},
"'zip -gq$recurseoption $Nt $backupdir/backup$backuptype.$curtime.$filedirs.zip $dir' $backup_txt{31}: $!. $backup_txt{32} "
              . ( $CHILD_ERROR >> 8 )
          );
    }
    elsif ( $backupmethod eq 'Archive::Tar' ) {
        $tarball->add_files( RecurseDirectory( $dir, $recursemode ) );
    }
    elsif ( $backupmethod eq 'Archive::Zip' ) {
        map { $zipfile->addFile($_) } RecurseDirectory( $dir, $recursemode );
    }
    return;
}

sub RecurseDirectory {

# Simple subroutine to run through every entry in a directory and return a giant list of the files/subdirs.
    my ( $dir, $recursemode ) = @_;
    my ( $item, @dirlist, @newcontents );

    opendir RECURSEDIR, $dir;
    @dirlist = readdir RECURSEDIR;
    closedir RECURSEDIR;

    foreach my $item (@dirlist) {
        if (   $recursemode
            && $item ne q{.}
            && $item ne q{..}
            && -d "$dir/$item" )
        {
            push @newcontents, RecurseDirectory( "$dir/$item", $recursemode );
        }
        elsif (
            -f "$dir/$item"
            && (  !$FORM{'backupnewest'}
                || $FORM{'backupnewest'} > -M "$dir/$item" )
          )
        {
            push @newcontents, "$dir/$item";
        }
    }
    return @newcontents;
}

# Compresses the tar
sub BackupMethodFinalize {
    my ( $filedirs, $loop ) = @_;
    if ( !$loop && $backupmethod eq "$backupprogusr/tar" ) {
        if ( $compressmethod eq "$backupprogbin/bzip2" ) {
            ak_system(
                "bzip2 -z $backupdir/backup$backuptype.$curtime.$filedirs.tar")
              || fatal_error(
                q{},
"'bzip2 -z $backupdir/backup$backuptype.$curtime.$filedirs.tar.bz2' $backup_txt{31}: $!. $backup_txt{32} "
                  . ( $CHILD_ERROR >> 8 )
              );

        }
        elsif ( $compressmethod eq "$backupprogbin/gzip" ) {
            ak_system(
                "gzip $backupdir/backup$backuptype.$curtime.$filedirs.tar")
              || fatal_error(
                q{},
"'gzip $backupdir/backup$backuptype.$curtime.$filedirs.tar.gz' $backup_txt{31}: $!. $backup_txt{32} "
                  . ( $CHILD_ERROR >> 8 )
              );
        }
    }
    elsif ( $backupmethod eq 'Archive::Tar' ) {
        if ( $loop || $compressmethod eq 'none' ) {
            $tarball->write(
                "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar", 0 );
        }
        elsif ( $compressmethod eq 'Compress::Zlib' ) {    # Gzip as a module
            my ($gzip) = gzopen(
                "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar.gz",
                'wb' );
            $gzip->gzwrite( $tarball->write );
            $gzip->gzclose();
            unlink "$backupdir/backup$backuptype.$curtime.$filedirs.tar";
        }
        elsif ( $compressmethod eq 'Compress::Bzip2' ) {    # Bzip2 as a module
            my ($bzip2) = bzopen(
                "$backupdir/backup$backuptype.$curtime.$filedirs.a.tar.bz2",
                'wb' );
            $bzip2->bzwrite( $tarball->write );
            $bzip2->bzclose();
            unlink "$backupdir/backup$backuptype.$curtime.$filedirs.tar";
        }
    }
    elsif ( $backupmethod eq 'Archive::Zip' ) {
        $zipfile->overwriteAs(
            "$backupdir/backup$backuptype.$curtime.$filedirs.a.zip");
    }
    return;
}

sub ak_system
{    # Returns a success code. The system's code returned is $CHILD_ERROR >> 8
    @x = @_;
    CORE::system(@x);
    if ( $CHILD_ERROR == -1 ) {
        return q{};
    }    # Failed to execute; return a null string.
    elsif ( $CHILD_ERROR & 127 ) { return 0; }    # Died, return 0.
    return 1;                                     # Success; return 1.
}

sub runbackup_loop {
    my ( $i, $j, $curtime, $backupnewest, $backuptime ) = @_;

    $yymain .= qq~</b>
    <p id="memcontinued">
        $admin_txt{'542'} <a href="$adminurl?action=runbackup;loop1=$i;loop2=$j;curtime=$curtime;backupnewest=$backupnewest;backuptime=$backuptime;runbackup_again=$INFO{'runbackup_again'}" onclick="PleaseWait();">$admin_txt{'543'}</a>.<br />
        $backup_txt{'90'}
    </p>

    <script type="text/javascript">
        function PleaseWait() {
            document.getElementById("memcontinued").innerHTML = '<span style="color:important"><b>$backup_txt{'91'}</b></span><br />&nbsp;<br />&nbsp;';
        }

        function stoptick() { stop = 1; }

        stop = 0;
        function membtick() {
            if (stop != 1) {
                PleaseWait();
                location.href="$adminurl?action=runbackup;loop1=$i;loop2=$j;curtime=$curtime;backupnewest=$backupnewest;backuptime=$backuptime;runbackup_again=$INFO{'runbackup_again'}";
            }
        }

        setTimeout("membtick()",2000);
    </script>~;

    AdminTemplate();
    return;
}

sub CheckPath {
    my ($file) = @_;

    if ( -e $file ) { return $file; }

    $file =~ s/\A.*\///xsm;

    foreach my $path (@ENVpaths) {
        $path =~ s/\/\Z//xsm;
        if ( -e "$path/$file" ) { return "$path/$file"; }
    }
    return;
}

# Thanks to BBQ at PerlMonks for the basis of this routine: http://www.perlmonks.org/?node_id=9277
sub downloadbackup {
    chdir($backupdir)
      || fatal_error( q{}, "$backup_txt{44} $backupdir", 1 );
    my $filename = $INFO{'backupid'};
    if ( $filename !~ /\Abackup/xsm || $filename !~ /\d{9,10}/xsm ) {
        fatal_error( q{}, $backup_txt{'45'} );
    }
    my $filesize = -s $filename;

    # print full header
    print "Content-disposition: inline; filename=$filename\n"
      or croak "$croak{'print'} Content-disposition";
    print "Content-Length: $filesize\n"
      or croak "$croak{'print'} Content-Length";
    print "Content-Type: application/octet-stream\n\n"
      or croak "$croak{'print'} Content-Type";

    # open in binmode
    fopen( READ, $filename )
      || fatal_error( q{}, "$backup_txt{46} $filename", 1 );
    binmode READ;

    # stream it out
    binmode STDOUT;
    while (<READ>) { print; }
    fclose(READ);
    return;
}

sub deletebackup {
    my $filename = $INFO{'backupid'};
    if ( $filename !~ /\Abackup/xsm || $filename !~ /\d{9,10}/xsm ) {
        fatal_error( q{}, $backup_txt{'45'} );
    }

    $yymain = qq~
$backup_txt{47} $filename $backup_txt{48}
<br />
<br /><a href="$adminurl?action=deletebackup2;backupid=$filename">$backup_txt{49}</a> | <a href="$adminurl?action=backupsettings">$backup_txt{50}</a>
~;

    AdminTemplate();
    return;
}

sub deletebackup2 {
    my $filename = $INFO{'backupid'};
    if ( $filename !~ /\Abackup/xsm || $filename !~ /\d{9,10}/xsm ) {
        fatal_error( q{}, $backup_txt{'45'} );
    }

    # Just remove it!
    unlink "$backupdir/$filename"
      || fatal_error( q{}, "$backup_txt{51} $backupdir/$filename", 1 );

    $yySetLocation = "$adminurl?action=backupsettings";
    redirectexit();
    return;
}

sub emailbackup {

    # Unfortunately, we cannot use &sendmail() for this.
    # So, we will load MIME::Lite and try that, as it should work.
    # If not, we will email out a download link.
    my ( $mainmessage, $filename );

    $filename = $INFO{'backupid'};
    if ( $filename !~ /\Abackup/xsm || $filename !~ /\d{9,10}/xsm ) {
        fatal_error( q{}, $backup_txt{'45'} );
    }

    # Try to safely load MIME::Lite
    eval 'use MIME::Lite;';
    if ( !$@ && !$INFO{'linkmail'} ) {    # We can use MIME::Lite.
        my $filesize = -s "$backupdir/$filename";
        $filesize = int( $filesize / 1024 );    # Measure it in kilobytes
        if ( !$INFO{'passwarning'} && $filesize > 1024 * 4 )
        {    # Warn if the file-size is to big for email (> 4 MB)
            if ( $filesize > 1024 * 4 ) {
                $filesize = int( $filesize / 1024 ) . ' MB';
            }    # Measure it in megabytes
            else { $filesize .= ' KB'; }    # Label it

            $yymain = qq~
$backup_txt{54}?<br />
$backup_txt{55} <b>$filesize</b>!<br />
<br />
<a href="$adminurl?action=emailbackup;backupid=$INFO{'backupid'};passwarning=1">$backup_txt{56} <i>${$uid.$username}{'email'}</i></a><br />
<a href="$adminurl?action=emailbackup;backupid=$INFO{'backupid'};linkmail=1">$backup_txt{57}</a><br />
<a href="$adminurl?action=downloadbackup;backupid=$INFO{'backupid'}">$backup_txt{58}</a><br />
<a href="$adminurl?action=backupsettings">$backup_txt{59}</a>
~;
            AdminTemplate();
        }

        $mainmessage = $backup_txt{'mailmessage1'};
        $mainmessage =~ s/USERNAME/${$uid.$username}{'realname'}/gsm;
        $mainmessage =~
          s/LINK/$adminurl?action=downloadbackup;backupid=$filename/gsm;
        $mainmessage =~ s/FILENAME/$filename/gsm;

        eval q^
            my $msg = MIME::Lite->new(
                To      => ${$uid.$username}{'email'},
                From    => $backup_txt{'mailfrom'},
                Subject => $backup_txt{'mailsubject'},
                Type    => 'multipart/mixed'
                );
            $msg->attach(
                Type => 'TEXT',
                Data => $mainmessage
            );
            $msg->attach(
                Type     => 'AUTO', # Let it be auto-detected.
                Filename => $filename,
                Path     => "$backupdir/$filename",
            );
            if (!$mailtype) {
                $msg->send();
            } else {
                my @arg = ("$smtp_server", Hello => "$smtp_server", Timeout => 30);
                push(@arg, AuthUser => "$authuser") if $authuser;
                push(@arg, AuthPass => "$authpass") if $authpass;
                $msg->send('smtp', @arg);
            }
        ^;
    }

    if ( $@ || $INFO{'linkmail'} ) {
        $mainmessage =
          ( $INFO{'linkmail'} && !$@ )
          ? $backup_txt{'mailmessage2'}
          : $backup_txt{'mailmessage3'};
        $mainmessage =~ s/USERNAME/${$uid.$username}{'realname'}/sm;
        $mainmessage =~
          s/LINK/$adminurl?action=downloadbackup;backupid=$filename/sm;
        $mainmessage =~ s/FILENAME/$filename/sm;
        $mainmessage =~ s/SYSTEMINFO/$@/sm;

        require Sources::Mailer;
        sendmail(
            ${ $uid . $username }{'email'},
            $backup_txt{'mailsubject'},
            $mainmessage, $backup_txt{'mailfrom'}
        );

        $yySetLocation = "$adminurl?action=backupsettings&mailinfo=-1";
    }
    else {
        $yySetLocation = "$adminurl?action=backupsettings&mailinfo=1";
    }

    redirectexit();
    return;
}

sub recoverbackup1 {
    $INFO{'recoverfile'} =~ /\A(backup)(n?)\.(\d+)\.([^\.]+)\.(.+)/xsm;

    my @dirs;
    foreach ( split /_/xsm, $4 ) {
        push @dirs, $dirs{$_};
    }

    $yymain .= qq~
 <script type="text/javascript">
    function CheckCHMOD (v,min,t) {
        if (v == '') {
            return;
        } else if (/\\D/.test(v)) {
            alert('$backup_txt{112}');
            t.value = '';
        } else if (v < min) {
            alert('$backup_txt{110} ' + min);
            t.value = min;
        } else if (v > 7) {
            alert('$backup_txt{111}');
            t.value = 7;
        }
    }
 </script>
<form action="$adminurl?action=recoverbackup2" method="post" name="recover">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad_10px" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$backup_txt{100}</b></td>
        </tr><tr>
            <td class="windowbg2" colspan="2">
                $backup_txt{101}<br />
                <br />
                - ~ . join( '<br />- ', @dirs ) . qq~<br />
                <br />
                $backup_txt{102}<br />
                <br />
                <i>$INFO{'recoverfile'}</i>~
      . ( $2 ? " (<b>$backup_txt{62}</b>)" : q{} )
      . qq~ $backup_txt{103} ~
      . timeformat($3)
      . qq~     <br />
                <br />
                <input type="button" onclick="window.location.href='$adminurl?action=backupsettings'" value="$backup_txt{125}" /><br />
                <br />
                $backup_txt{104},<br />
                <br />
                <input type="checkbox" name="originalrestore" value="1" /> $backup_txt{105}<br />
                <br />
                $backup_txt{106}<br />
                <table class="pad-cell">
                    <tr>
                        <td class="center"><b>$backup_txt{107}</b></td>
                        <td class="center"><b>$backup_txt{108}</b></td>
                    </tr>~;

    $INFO{'recoverfile'} =~ /\.tar(.*)$/xsm;
    my $recovertype =
      $1 eq '.gz'
      ? "tar -tzf $backupdir/$INFO{'recoverfile'} -C $backupdir/"
      : "tar -tf $backupdir/$INFO{'recoverfile'} -C $backupdir/";

    my %checkdir;
    foreach ( split /\n/xsm, qx($recovertype) ) {
        next if -d "/$_/";
        $_ =~ /(.*\/)(.*)/xsm;
        if ( !$checkdir{$1} && $2 ) {
            $checkdir{$1} = 1;
            $yymain .= qq~<tr>
                    <td>/$1 *$backup_txt{114}</td>
                    <td class="center"><input type="text" name="u-$1" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="g-$1" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="a-$1" value="" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,0,this);" /></td>
                </tr>~;
        }
    }

    $yymain .= qq~<tr>
             <td colspan="2">&nbsp;</td>
           </tr><tr>
             <td>$backup_txt{115} index.html $backup_txt{116}</td><td class="center"><input type="text" name="u-index" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="g-index" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="a-index" value="4" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,0,this);" /></td>
           </tr><tr>
             <td>$backup_txt{115} .htaccess $backup_txt{116}</td><td class="center"><input type="text" name="u-htaccess" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="g-htaccess" value="6" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="a-htaccess" value="4" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,0,this);" /></td>
           </tr><tr>
             <td colspan="2">&nbsp;</td>
           </tr> <tr>
             <td>$backup_txt{120}</td><td class="center"><input type="text" name="u-newdir" value="7" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,6,this);" /> <input type="text" name="g-newdir" value="5" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,5,this);" /> <input type="text" name="a-newdir" value="5" size="1" maxlength="1" onkeyup="CheckCHMOD(this.value,0,this);" /></td>
           </tr>
         </table>
      </tr>
   </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $backup_txt{'100'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="hidden" name="recoverfile" value="$INFO{'recoverfile'}" />
            <input type="submit" value="$backup_txt{'126'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>~;

    AdminTemplate();
    return;
}

sub recoverbackup2 {
    my ( $output, $o, $CHMOD, %checkdirexists, %checkdir, $path );

    my $restore_root;
    if ( $FORM{'originalrestore'} ) {
        $restore_root = q{/};
    }
    else {
        $restore_root = "$backupdir/$date/";
        mkdir $restore_root,
          oct "0$FORM{'u-newdir'}$FORM{'g-newdir'}$FORM{'a-newdir'}";
        chmod
          oct("0$FORM{'u-newdir'}$FORM{'g-newdir'}$FORM{'a-newdir'}"),
          $restore_root;    # mkdir somtimes does not set the CHMOD as expected
    }

    $FORM{'recoverfile'} =~ /\.tar(.*)$/xsm;
    my $recovertype =
      $1 eq '.gz'
      ? "tar -tzf $backupdir/$FORM{'recoverfile'} -C $restore_root"
      : "tar -tf $backupdir/$FORM{'recoverfile'} -C $restore_root";
    $output = qx($recovertype);
    $recovertype =
      $1 eq '.gz'
      ? "tar -xzf $backupdir/$FORM{'recoverfile'} -C $restore_root"
      : "tar -xf $backupdir/$FORM{'recoverfile'} -C $restore_root";

    # Check what directories do/do not exist
    foreach my $o ( split /\n/xsm, $output ) {
        next if -d "/$o/";
        $o =~ /(.*\/)(.*)/xsm;
        $path = q{};
        foreach ( split /\//xsm, $1 ) {
            $path .= "$_/";
            if ( !$checkdirexists{$path} ) {
                $checkdirexists{$path} =
                  -d (
                    $FORM{'originalrestore'} ? "/$path"
                    : "$backupdir/$date/$path"
                  ) ? 1
                  : -1;
            }
        }
    }

    qx($recovertype);    # must be done AFTER directory check!

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad_more" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$backup_txt{100}</b></td>
        </tr><tr>
            <td class="windowbg2" colspan="2">
                $backup_txt{130}<br />
                <br />
                <pre>\n~;

    foreach my $o ( split /\n/xsm, $output ) {
        next if -d "/$o/";
        $CHMOD = q{};
        $o =~ /(.*\/)(.*)/xsm;
        if ( $2 eq 'index.html' ) {
            $CHMOD .= $FORM{'u-index'} < 6 ? 6 : $FORM{'u-index'};
            $CHMOD .= $FORM{'g-index'} < 6 ? 6 : $FORM{'g-index'};
            $CHMOD .= $FORM{'a-index'} < 1 ? 0 : $FORM{'a-index'};

        }
        elsif ( $2 eq '.htaccess' ) {
            $CHMOD .= $FORM{'u-htaccess'} < 6 ? 6 : $FORM{'u-htaccess'};
            $CHMOD .= $FORM{'g-htaccess'} < 6 ? 6 : $FORM{'g-htaccess'};
            $CHMOD .= $FORM{'a-htaccess'} < 1 ? 0 : $FORM{'a-htaccess'};

        }
        elsif ($2) {
            $CHMOD .= $FORM{ 'u-' . $1 } < 6 ? 6 : $FORM{ 'u-' . $1 };
            $CHMOD .= $FORM{ 'g-' . $1 } < 6 ? 6 : $FORM{ 'g-' . $1 };
            $CHMOD .= $FORM{ 'a-' . $1 } < 1 ? 0 : $FORM{ 'a-' . $1 };
        }

        $path = q{};
        foreach ( split /\//xsm, $1 ) {
            $path .= "$_/";
            if ( !$checkdir{$path} ) {
                $checkdir{$path} = 1;
                if ( $checkdirexists{$path} == -1 ) {    # set directories CHMOD
                    my $od =
                      $FORM{'originalrestore'}
                      ? "/$path"
                      : "$backupdir/$date/$path";
                    $yymain .= chmod(
                        oct(
"0$FORM{'u-newdir'}$FORM{'g-newdir'}$FORM{'a-newdir'}"
                        ),
                        $od
                      )
                      . " - CHMOD 0$FORM{'u-newdir'}$FORM{'g-newdir'}$FORM{'a-newdir'} - $od\n";
                }
            }
        }

        if ($CHMOD) {
            $o = $FORM{'originalrestore'} ? "/$o" : "$backupdir/$date/$o";
            $yymain .= chmod( oct("0$CHMOD"), $o ) . " - CHMOD 0$CHMOD - $o\n";
        }
    }

    $yymain .= qq~         </pre>
                $backup_txt{131}<br />
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'193'}</th>
    </tr><tr>
        <td class="catbg center">
             <input type="button" onclick="window.location.href='$adminurl?action=backupsettings'" value="$backup_txt{'132'}" />
        </td>
    </tr>
</table>
</div>~;

    AdminTemplate();
    return;
}

1;
