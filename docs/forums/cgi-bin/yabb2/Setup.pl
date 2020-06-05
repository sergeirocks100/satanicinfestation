#!/usr/bin/perl --
# $Id: YaBB Setup $
# $HeadURL: YaBB $
# $Source: /Setup.pl $
###############################################################################
# Setup.pl                                                                    #
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

$setupplver = 'YaBB 2.6.11 $Revision: 1619 $';
$yymycharset  = 'UTF-8';

# conversion will stop after $max_process_time
# in seconds, than the browser will call the script
# again until all is done. Don't put it too high
# or you will run into server or browser timeout
$max_process_time = 20;
$time_to_jump     = time() + $max_process_time;

if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
    $yyIIS = 1;
    $PROGRAM_NAME =~ m{(.*)(\\|/)}xsm;
    $yypath = $1;
    $yypath =~ s/\\/\//gxsm;
    chdir $yypath;
    push @INC, $yypath;
}

### Requirements and Errors ###
my $script_root = $ENV{'SCRIPT_FILENAME'};
if( ! $script_root ) {
        $script_root = $ENV{'PATH_TRANSLATED'};
}
$script_root =~ s/\\/\//gxsm;
$script_root =~ s/\/Setup\.(pl|cgi)//igxsm;

if    ( -e './Paths.pm' )            { require Paths; }
elsif ( -e "$script_root/Paths.pm" ) { require "$script_root/Paths.pm"; }
elsif ( -e "$script_root/Variables/Paths.pm" ) {
    require "$script_root/Variables/Paths.pm";
}

# Check if it's blank Paths.pm or filled in one
if ( !$lastsaved ) {
    $boardsdir = './Boards';
    $sourcedir = './Sources';
    $memberdir = './Members';
    $vardir    = './Variables';
}

if   ( -e 'YaBB.cgi' ) { $yyext = 'cgi'; }
else                   { $yyext = 'pl'; }
if   ($boardurl) { $set_cgi = "$boardurl/Setup.$yyext"; }
else             { $set_cgi = "Setup.$yyext"; }

# Make sure the module path is present
push @INC, './Modules';

require Sources::Subs;
require Sources::System;
require Sources::Load;
require Sources::DateTime;

$windowbg    = '#dee4ec';
$windowbg2   = '#edeff4';
$header      = '#3673b3';
$catbg       = '#195392';
$maintext_23 = 'Unable to open';

$yymenu    = q{};
$yytabmenu = q~&nbsp;~;

if ( -e "$vardir/Setup.lock" ) {
    FoundSetupLock();
        }
#############################################
# Setup starts here                         #
#############################################

if ( !$action ) {
    $rand_integer   = int rand 99_999;
    $rand_cook_user = "Y2User-$rand_integer";
    $rand_cook_pass = "Y2Pass-$rand_integer";
    $rand_cook_sess = "Y2Sess-$rand_integer";
    $rand_cook_sort = "Y2tsort-$rand_integer";
    $rand_cook_view = "Y2view-$rand_integer";

    fopen( COOKFILE, ">$vardir/cook.txt" )
      || setup_fatal_error( "$maintext_23 $vardir/cook.txt: ", 1 );
    print {COOKFILE} "$rand_cook_user\n" or croak 'cannot print cook.txt';
    print {COOKFILE} "$rand_cook_pass\n" or croak 'cannot print cook.txt';
    print {COOKFILE} "$rand_cook_sess\n" or croak 'cannot print cook.txt';
    print {COOKFILE} "$rand_cook_sort\n" or croak 'cannot print cook.txt';
    print {COOKFILE} "$rand_cook_view\n" or croak 'cannot print cook.txt';
    fclose(COOKFILE);

    adminlogin();
}

fopen( COOKFILE, "$vardir/cook.txt" )
  || setup_fatal_error( "$maintext_23 $vardir/cook.txt: ", 1 );
@cookinfo = <COOKFILE>;
fclose(COOKFILE);
chomp @cookinfo;

$cookieusername     = "$cookinfo[0]";
$cookiepassword     = "$cookinfo[1]";
$cookiesession_name = "$cookinfo[2]";
$cookietsort        = "$cookinfo[3]";
$cookieview         = "$cookinfo[4]";
if    ( $action eq 'adminlogin2' ) { adminlogin2(); }
elsif ( $action eq 'setup1' )      { autoconfig(); }
elsif ( $action eq 'setup2' ) {
    BrdInstall();
    MemInstall();
    MesInstall();
    VarInstall();
    save_paths();
}
elsif ( $action eq 'checkmodules' ) { SetInstall2(); checkmodules(); }
elsif ( $action eq 'setinstall' )   { SetInstall(); }
elsif ( $action eq 'setinstall2' )  { SetInstall2(); }
elsif ( $action eq 'setup3' )       { CheckInstall(); }
elsif ( $action eq 'ready' )        { ready(); }

$yymain = qq~End of script reached without action: $action~;
SimpleOutput();

#############################################
# setup subroutines start here              #
#############################################

sub adminlogin {
    open LICENSE, '< license.txt' or croak 'cannot load License.';
    my $license = do { local $/; <LICENSE>; };
    close LICENSE or croak 'cannot close License';

    $yymain .= qq~
    <div id="license" style="width:50em; height:40em; overflow:auto; margin:2em auto 0 auto; border:thin #000 solid; padding:1em; background-color:#fff">$license</div>
    <form action="$set_cgi?action=adminlogin2" method="post" name="loginform">
    <div style="width:25em; border: thin #000 solid; margin:2em auto; padding:1em; text-align:center; background-color:#fff">
        <label for="password">Enter the password for user <b>admin</b> to acknowledge acceptance of the above license and to gain access to the Setup Utility</label>
        <p><input type="password" name="password" id="password" size="30" />
         <input type="hidden" name="username" value="admin" />
         <input type="hidden" name="cookielength" value="1500" /></p>
        <p><input type="submit" value="Submit" /></p>
    </div>
    </form>
    <script type="text/javascript">
        document.loginform.password.focus();
    </script>
      ~;

    return SimpleOutput();
}

sub adminlogin2 {
    if ( $FORM{'password'} eq q{} ) {
        setup_fatal_error('Setup Error: You should fill in your password!');
    }

    # No need to pass a form variable setup is only used by user: admin
    $username = 'admin';

    if ( -e "$memberdir/$username.vars" ) {
        $Group{'Administrator'} =
          'Forum Administrator|5|staradmin.png|red|0|0|0|0|0|0';
        LoadUser($username);
        my $spass = ${ $uid . $username }{'password'};
        $cryptpass = encode_password( $FORM{'password'} );
        if ( $spass ne $cryptpass && $spass ne $FORM{'password'} ) {
            setup_fatal_error('Setup Error: Login Failed!');
        }
    }
    else {
        setup_fatal_error(
qq~Setup Error: Could not find the admin data file in $memberdir! Please check your access rights.~
        );
    }

    if ( $FORM{'cookielength'} < 1 || $FORM{'cookielength'} > 9999 ) {
        $FORM{'cookielength'} = $Cookie_Length;
    }
    if ( !$FORM{'cookieneverexp'} ) { $ck{'len'} = "\+$FORM{'cookielength'}m"; }
    else { $ck{'len'} = 'Sunday, 17-Jan-2038 00:00:00 GMT'; }
    $password = encode_password("$FORM{'password'}");
    ${ $uid . $username }{'session'} = encode_password($user_ip);
    chomp ${ $uid . $username }{'session'};

# check if forum.control can be open (needed in &LoadBoardControl used by &LoadUserSettings)
    fopen( FORUMCONTROL, "$boardsdir/forum.control" )
      || setup_fatal_error( "$maintext_23 $boardsdir/forum.control: ", 1 );
    fclose(FORUMCONTROL);

    UpdateCookie(
        'write',     "$username",
        "$password", "${$uid.$username}{'session'}",
        q{/},        "$ck{'len'}"
    );
    LoadUserSettings();
    $yymain .= qq~
    <form action="$set_cgi?action=setup1" method="post">
    <div style="width:50em; border: thin #000 solid; margin:2em auto; padding:1em; text-align:center; background-color:#fff">
        You are now logged in, <i>${$uid.$username}{'realname'}</i>!<br />Click 'Continue Set Up' to proceed with the Setup.
        <p><input type="submit" value="Continue Set Up" /></p>
    </div>
    </form>
~;

    return SimpleOutput();
}

sub autoconfig {
    LoadCookie();    # Load the user's cookie (or set to guest)
    LoadUserSettings();
    if ( !$iamadmin ) {
        setup_fatal_error(
q~Setup Error: You have no access rights to this function. Only user "admin" has if logged in!~
        );
    }

    # do some fancy auto sensing
    $template = 'default';

    $yabbfiles = 'yabbfiles';

    # find the script url
    # Getting the last known url one way or another
    if ( $ENV{HTTP_REFERER} ) {
        $tempboardurl = $ENV{HTTP_REFERER};
    }
    elsif ( $ENV{HTTP_HOST} && $ENV{REQUEST_URI} ) {
        $tempboardurl = qq~http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}~;
    }
    $lastslash = rindex $tempboardurl, q{/};
    $foundboardurl = substr $tempboardurl, 0, $lastslash;

    ## find the webroot ##
    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
        $this_script = "$ENV{'SCRIPT_NAME'}";
        $_           = $PROGRAM_NAME;
        s/\\/\//gxsm;
        s/$this_script//xsm;
        $searchroot = $_ . q{/};
    }
    else {
        $searchroot = $ENV{'DOCUMENT_ROOT'};
        s/\\/\//gxsm;
    }
    $firstslash = index $tempboardurl, q{/}, 8;
    $html_baseurl = substr $tempboardurl, 0, $firstslash;

    # try to find the yabb html basedir directly
    if ( -d "$searchroot/$yabbfiles" ) {
        $fnd_html_root = "$html_baseurl/$yabbfiles";
        $fnd_htmldir   = "$searchroot/$yabbfiles";
        $fnd_htmldir =~ s/\/\//\//gxsm;
        opendir HTMLDIR, $fnd_htmldir;
        @contents = readdir HTMLDIR;
        closedir HTMLDIR;
        foreach my $name (@contents) {
            if ( lc($name) eq 'avatars' && -d "$fnd_htmldir/$name" ) {
                $fnd_facesdir = "$fnd_htmldir/$name";
                $fnd_facesurl = "$fnd_html_root/$name";
            }

            if ( lc($name) eq 'attachments' && -d "$fnd_htmldir/$name" ) {
                $fnd_uploaddir = "$fnd_htmldir/$name";
                $fnd_uploadurl = "$fnd_html_root/$name";
            }

            if ( lc($name) eq 'pmattachments' && -d "$fnd_htmldir/$name" ) {
                $fnd_pmuploaddir = "$fnd_htmldir/$name";
                $fnd_pmuploadurl = "$fnd_html_root/$name";
            }
            if ( lc($name) eq 'modimages' && -d "$fnd_htmldir/$name" ) {
                $fnd_modimgdir = "$fnd_htmldir/$name";
                $fnd_modimgurl = "$fnd_html_root/$name";
            }
        }
    }
    else {
        opendir HTMLDIR, $searchroot;
        @contents = readdir HTMLDIR;
        closedir HTMLDIR;
        foreach my $name (@contents) {
            if ( -d "$searchroot/$name" ) {
                opendir HTMLDIR, "$searchroot/$name";
                @subcontents = readdir HTMLDIR;
                closedir HTMLDIR;
                foreach my $subname (@subcontents) {
                    if ( lc($subname) eq lc($yabbfiles)
                        && ( -d "$searchroot/$name/$subname" ) )
                    {
                        $fnd_htmldir = "$searchroot/$name/$subname";
                        $fnd_htmldir =~ s/\/\//\//gxsm;
                        $fnd_html_root = "$html_baseurl/$name/$subname";
                    }
                }
            }
        }
        opendir HTMLDIR, $fnd_htmldir;
        @tcontents = readdir HTMLDIR;
        closedir HTMLDIR;
        foreach my $tname (@tcontents) {
            if ( lc($tname) eq 'avatars' && -d "$fnd_htmldir/$tname" ) {
                $fnd_facesdir = "$fnd_htmldir/$tname";
                $fnd_facesurl = "$fnd_html_root/$tname";
            }

            if ( lc($tname) eq 'attachments' && -d "$fnd_htmldir/$tname" ) {
                $fnd_uploaddir = "$fnd_htmldir/$tname";
                $fnd_uploadurl = "$fnd_html_root/$tname";
            }
            if ( lc($tname) eq 'pmattachments' && -d "$fnd_htmldir/$tname" ) {
                $fnd_pmuploaddir = "$fnd_htmldir/$tname";
                $fnd_pmuploadurl = "$fnd_html_root/$tname";
            }
            if ( lc($tname) eq 'modimages' && -d "$fnd_htmldir/$tname" ) {
                $fnd_modimgdir = "$fnd_htmldir/$tname";
                $fnd_modimgurl = "$fnd_html_root/$tname";
            }
        }
    }
    $fnd_boardurl = $foundboardurl;
    $fnd_boarddir = q{.};
    if ( -d "$fnd_boarddir/Boards" ) {
        $fnd_boardsdir = "$fnd_boarddir/Boards";
    }
    if ( -d "$fnd_boarddir/Messages" ) {
        $fnd_datadir = "$fnd_boarddir/Messages";
    }
    if ( -d "$fnd_boarddir/Members" ) {
        $fnd_memberdir = "$fnd_boarddir/Members";
    }
    if ( -d "$fnd_boarddir/Sources" ) {
        $fnd_sourcedir = "$fnd_boarddir/Sources";
    }
    if ( -d "$fnd_boarddir/Admin" ) { $fnd_admindir = "$fnd_boarddir/Admin"; }
    if ( -d "$fnd_boarddir/Variables" ) {
        $fnd_vardir = "$fnd_boarddir/Variables";
    }
    if ( -d "$fnd_boarddir/Languages" ) {
        $fnd_langdir = "$fnd_boarddir/Languages";
    }
    if ( -d "$fnd_boarddir/Help" ) { $fnd_helpfile = "$fnd_boarddir/Help"; }
    if ( -d "$fnd_boarddir/Templates" ) {
        $fnd_templatesdir = "$fnd_boarddir/Templates";
    }

    if ( !$lastsaved ) {
        $boardurl     = $fnd_boardurl;
        $boarddir     = $fnd_boarddir;
        $htmldir      = $fnd_htmldir;
        $uploaddir    = $fnd_uploaddir;
        $uploadurl    = $fnd_uploadurl;
        $pmuploaddir    = $fnd_pmuploaddir;
        $pmuploadurl    = $fnd_pmuploadurl;
        $yyhtml_root  = $fnd_html_root;
        $datadir      = $fnd_datadir;
        $boardsdir    = $fnd_boardsdir;
        $memberdir    = $fnd_memberdir;
        $sourcedir    = $fnd_sourcedir;
        $admindir     = $fnd_admindir;
        $vardir       = $fnd_vardir;
        $langdir      = $fnd_langdir;
        $helpfile     = $fnd_helpfile;
        $templatesdir = $fnd_templatesdir;

        $facesdir = $fnd_facesdir;
        $facesurl = $fnd_facesurl;
        $modimgdir = $fnd_modimgdir;
        $modimgurl = $fnd_modimgurl;
    }

    # Simple output of env variables, for troubleshooting
    if ( $ENV{'SCRIPT_FILENAME'} ne q{} ) {
        $support_env_path = $ENV{'SCRIPT_FILENAME'};
    }
    elsif ( $ENV{'PATH_TRANSLATED'} ne q{} ) {
        $support_env_path = $ENV{'PATH_TRANSLATED'};
    }

    # Remove Setupl.pl and cgi - and also nph- for buggy IIS.
    $support_env_path =~ s/(nph-)?Setup.(pl|cgi)//igsm;
    $support_env_path =~ s/\/\Z//xsm;

    # replace \'s with /'s for Windows Servers
    $support_env_path =~ s/\\/\//gxsm;

    # Generate Screen
    if ( -e "$langdir/$language/Main.lng" ) {
        require "$langdir/$use_lang/Main.lng";
    }
    elsif ( -e "$langdir/$lang/Main.lng" ) {
        require "$langdir/$lang/Main.lng";
    }
    elsif ( -e "$langdir/English/Main.lng" ) {
        require "$langdir/English/Main.lng";
    }

    $mylastdate = timeformat($lastdate);

    $yymain .= qq~
<form action="$set_cgi?action=setup2" method="post" name="auto_settings" style="display: inline;">
<script type="text/javascript">
function abspathfill(brddir) {
      document.auto_settings.preboarddir.value = brddir;
}
function autofill() {
      var boardurl = document.auto_settings.preboardurl.value || "$boardurl";
      var boarddir = document.auto_settings.preboarddir.value || ".";
      var htmldir = document.auto_settings.prehtmldir.value || "";
      var htmlurl = document.auto_settings.prehtml_root.value || "";
      if(!htmldir) {return 0;}
      if(!htmlurl) {return 0;}
      var confirmvalue = confirm("Do autofill the forms in the right column below (Saved:) with the basic values in here?");
      if(!confirmvalue) {return 0;}
      else {
            // Board URL
            document.auto_settings.boardurl.value = boardurl;

            // cgi Directories
            document.auto_settings.boarddir.value = boarddir;
            document.auto_settings.boardsdir.value = boarddir + "/Boards";
            document.auto_settings.datadir.value = boarddir + "/Messages";
            document.auto_settings.vardir.value = boarddir + "/Variables";
            document.auto_settings.memberdir.value = boarddir + "/Members";
            document.auto_settings.sourcedir.value = boarddir + "/Sources";
            document.auto_settings.admindir.value = boarddir + "/Admin";
            document.auto_settings.langdir.value = boarddir + "/Languages";
            document.auto_settings.templatesdir.value = boarddir + "/Templates";
            document.auto_settings.helpfile.value = boarddir + "/Help";

            // HTML URLs
            document.auto_settings.html_root.value = htmlurl;
            document.auto_settings.uploadurl.value = htmlurl + "/Attachments";
            document.auto_settings.pmuploadurl.value = htmlurl + "/PMAttachments";
            document.auto_settings.facesurl.value = htmlurl + "/avatars";
            document.auto_settings.modimgurl.value = htmlurl + "/ModImages";

            // HTML Directories
            document.auto_settings.htmldir.value = htmldir;
            document.auto_settings.uploaddir.value = htmldir + "/Attachments";
            document.auto_settings.pmuploaddir.value = htmldir + "/PMAttachments";
            document.auto_settings.facesdir.value = htmldir + "/avatars";
            document.auto_settings.modimgdir.value = htmldir + "/ModImages";
      }
}
</script>
<div id="folderfind">
    <table>
        <col style="width:43%" />
        <col style="width:57%" />
      <tr>
            <td class="header" colspan="2">
                <span style="color: #fefefe;">&nbsp;<b>Absolute Path to the main script directory</b></span>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div style="float: left; width: 80%; text-align: left; font-size: 11px;">Only click on the insert button if your server needs the absolute path to the YaBB main script</div>
                  <div style="float: left; width: 20%; text-align: right;"><input type="button" onclick="abspathfill('$support_env_path')" value="Insert" style="font-size: 11px;" /></div>
            </td>
            <td class="windowbg2">$support_env_path</td>
        </tr><tr>
            <td class="header" colspan="2">
                <span style="color: #fefefe;">&nbsp;<b>Change this form if changes are necessary.</b></span>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <label for="preboarddir">
                  Main Script Directory:
                <br />
                <span style="font-size: 11px;">
                    The server path to the board&#39;s folder (usually can be left as '.')
                </span>
                </label>
            </td>
            <td class="windowbg2">
                  <input type="text" size="60" name ="preboarddir" id ="preboarddir" value="$boarddir" />
            </td>
        </tr><tr>
            <td class="windowbg2">
                <label for="preboardurl">Board URL:
                <br />
                <span style="font-size: 11px;">
                URL of your board&#39;s folder (without trailing '/')
                  </span></label>
            </td>
            <td class="windowbg2">
                  <input type="text" size="60" name ="preboardurl" id ="preboardurl" value="$boardurl" />
            </td>
        </tr><tr>
            <td class="windowbg2">
                <label for="prehtmldir">HTML Root Directory:
                <br />
                <span style="font-size: 11px;">
                  Base Path for all /html/css files and folders
                  </span></label>
            </td>
            <td class="windowbg2">
                  <input type="text" size="60" name ="prehtmldir" id ="prehtmldir" value="$htmldir" />
            </td>
        </tr><tr>
            <td class="windowbg2">
                <label for="prehtml_root">
                  HTML Root URL:
                <br />
                <span style="font-size: 11px;">
                  Base URL for all /html/css files and folders
                  </span></label>
            </td>
            <td class="windowbg2">
                  <input type="text" size="60" name ="prehtml_root" id ="prehtml_root" value="$yyhtml_root" />
            </td>
        </tr><tr>
            <td style="background-color:$catbg; text-align:center; padding:15px 3px 30px 3px" colspan="2">
                  <input type="button" onclick="autofill()" value="Autofill the forms below" style="width: 200px;" />
            </td>
      </tr>
</table>
    <table style="margin-top:1em">
        <col style="width:20%" />
        <col style="width:35%" />
        <col style="width:10%" />
        <col style="width:35%" />
      <tr>
            <td class="header" colspan="4">
            <input type="hidden" name="lastsaved" value="${$uid.$username}{'realname'}" />
            <input type="hidden" name="lastdate" value="$date" />
                <span style="color: #fefefe;">&nbsp;<b>These are the settings detected on your server and the last saved settings.</b></span>
            </td>
        </tr><tr>
            <td class="catbg">&nbsp;</td>
            <td class="catbg"><b>Detected Values</b></td>
            <td class="catbg"><b>Transfer</b></td>
            <td class="catbg"><b>Saved: $mylastdate</b></td>
        </tr><tr>
            <td class="header" colspan="4">
            <span style="color: #fefefe;">&nbsp; <b>CGI-BIN Settings</b></span>
            </td>
        </tr><tr>
            <td class="windowbg2">Board URL:</td>
            <td class="windowbg">$fnd_boardurl</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.boardurl.value = '$fnd_boardurl';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="boardurl" value="$boardurl" /></td>
        </tr><tr>
            <td class="windowbg2">Main Script Dir.:</td>
            <td class="windowbg">$fnd_boarddir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.boarddir.value = '$fnd_boarddir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="boarddir" value="$boarddir" /></td>
        </tr><tr>
            <td class="windowbg2">Admin Dir.:</td>
            <td class="windowbg">$fnd_admindir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.admindir.value = '$fnd_admindir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="admindir" value="$admindir" /></td>
        </tr><tr>
            <td class="windowbg2">Boards Dir.:</td>
            <td class="windowbg">$fnd_boardsdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.boardsdir.value = '$fnd_boardsdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="boardsdir" value="$boardsdir" /></td>
        </tr><tr>
            <td class="windowbg2">Help Dir.:</td>
            <td class="windowbg">$fnd_helpfile</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.helpfile.value = '$fnd_helpfile';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="helpfile" value="$helpfile" /></td>
        </tr><tr>
            <td class="windowbg2">Languages Dir.:</td>
            <td class="windowbg">$fnd_langdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.langdir.value = '$fnd_langdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="langdir" value="$langdir" /></td>
        </tr><tr>
            <td class="windowbg2">Member Dir.:</td>
            <td class="windowbg">$fnd_memberdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.memberdir.value = '$fnd_memberdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="memberdir" value="$memberdir" /></td>
        </tr><tr>
            <td class="windowbg2">Message Dir.:</td>
            <td class="windowbg">$fnd_datadir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.datadir.value = '$fnd_datadir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="datadir" value="$datadir" /></td>
        </tr><tr>
            <td class="windowbg2">Sources Dir.:</td>
            <td class="windowbg">$fnd_sourcedir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.sourcedir.value = '$fnd_sourcedir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="sourcedir" value="$sourcedir" /></td>
        </tr><tr>
            <td class="windowbg2">Template Dir.:</td>
            <td class="windowbg">$fnd_templatesdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.templatesdir.value = '$fnd_templatesdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="templatesdir" value="$templatesdir" /></td>
        </tr><tr>
            <td class="windowbg2">Variables Dir.:</td>
            <td class="windowbg">$fnd_vardir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.vardir.value = '$fnd_vardir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="vardir" value="$vardir" /></td>
        </tr><tr>
            <td class="header" style="color: #fefefe;" colspan="4">&nbsp; <b>HTML Settings</b></td>
        </tr><tr>
            <td class="windowbg2">HTML Root Dir.:</td>
            <td class="windowbg">$fnd_htmldir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.htmldir.value = '$fnd_htmldir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="htmldir" value="$htmldir" /></td>
        </tr><tr>
            <td class="windowbg2">HTML Root URL:</td>
            <td class="windowbg">$fnd_html_root</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.html_root.value = '$fnd_html_root';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="html_root" value="$yyhtml_root" /></td>
        </tr><tr>
            <td class="windowbg2">Attachment Dir.:</td>
            <td class="windowbg">$fnd_uploaddir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.uploaddir.value = '$fnd_uploaddir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="uploaddir" value="$uploaddir" /></td>
        </tr><tr>
            <td class="windowbg2">Attachment URL:</td>
            <td class="windowbg">$fnd_uploadurl</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.uploadurl.value = '$fnd_uploadurl';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="uploadurl" value="$uploadurl" /></td>
        </tr><tr>
            <td class="windowbg2">PMAttachment Dir.:</td>
            <td class="windowbg">$fnd_pmuploaddir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.pmuploaddir.value = '$fnd_pmuploaddir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="pmuploaddir" value="$pmuploaddir" /></td>
        </tr><tr>
            <td class="windowbg2">PMAttachment URL:</td>
            <td class="windowbg">$fnd_pmuploadurl</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.pmuploadurl.value = '$fnd_pmuploadurl';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="pmuploadurl" value="$pmuploadurl" /></td>
        </tr><tr>
            <td class="windowbg2">Avatar Dir.:</td>
            <td class="windowbg">$fnd_facesdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.facesdir.value = '$fnd_facesdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="facesdir" value="$facesdir" /></td>
        </tr><tr>
            <td class="windowbg2">Avatar URL:</td>
            <td class="windowbg">$fnd_facesurl</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.facesurl.value = '$fnd_facesurl';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="facesurl" value="$facesurl" /></td>
        </tr><tr>
            <td class="windowbg2">Mod Images Dir.:</td>
            <td class="windowbg">$fnd_modimgdir</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.modimgdir.value = '$fnd_modimgdir';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="modimgdir" value="$modimgdir" /></td>
        </tr><tr>
            <td class="windowbg2">Mod Images URL:</td>
            <td class="windowbg">$fnd_modimgurl</td>
            <td class="catbg"><input type="button" onclick="javascript: document.auto_settings.modimgurl.value = '$fnd_modimgurl';return false;" value="->" /></td>
            <td class="windowbg"><input type="text" size="60" name ="modimgurl" value="$modimgurl" /></td>
        </tr><tr>
            <td class="catbg" style="margin-top:.5em; margin-bottom:1em;" colspan="4"><input type="submit" value="Save Settings" /></td>
        </tr>
    </table>
</div>
</form>
      ~;
    $yytitle = 'Results of Auto-Sensing';
    SimpleOutput();
    return;
}

sub save_paths {
    LoadCookie();    # Load the user's cookie (or set to guest)
    LoadUserSettings();
    if ( !$iamadmin ) {
        setup_fatal_error(
q~Setup Error: You have no access rights to this function. Only user "admin" has if logged in!~
        );
    }

    $lastsaved    = $FORM{'lastsaved'};
    $lastdate     = $FORM{'lastdate'};
    $boardurl     = $FORM{'boardurl'};
    $boarddir     = $FORM{'boarddir'};
    $htmldir      = $FORM{'htmldir'};
    $uploaddir    = $FORM{'uploaddir'};
    $uploadurl    = $FORM{'uploadurl'};
    $pmuploaddir    = $FORM{'pmuploaddir'};
    $pmuploadurl    = $FORM{'pmuploadurl'};
    $yyhtml_root  = $FORM{'html_root'};
    $datadir      = $FORM{'datadir'};
    $boardsdir    = $FORM{'boardsdir'};
    $memberdir    = $FORM{'memberdir'};
    $sourcedir    = $FORM{'sourcedir'};
    $admindir     = $FORM{'admindir'};
    $vardir       = $FORM{'vardir'};
    $langdir      = $FORM{'langdir'};
    $helpfile     = $FORM{'helpfile'};
    $templatesdir = $FORM{'templatesdir'};

    $facesdir = $FORM{'facesdir'};
    $facesurl = $FORM{'facesurl'};
    $modimgdir    = $FORM{'modimgdir'};
    $modimgurl    = $FORM{'modimgurl'};

    my $setfile = << "EOF";
###############################################################################
# Paths.pm                                                                    #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Open-Source Community Software for Webmasters                               #
# Version:        YaBB 2.6.11                                                 #
# Packaged:       December 2, 2014                                            #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2014  YaBB (www.yabbforum.com) - All Rights Reserved.    #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
###############################################################################

\$lastsaved = "$lastsaved";
\$lastdate = "$lastdate";

########## Directories ##########

\$boardurl = "$boardurl";                                         # URL of your board's folder (without trailing '/')
\$boarddir = "$boarddir";                                         # The server path to the board's folder (usually can be left as '.')
\$boardsdir = "$boardsdir";                                       # Directory with board data files
\$datadir = "$datadir";                                           # Directory with messages
\$memberdir = "$memberdir";                                       # Directory with member files
\$sourcedir = "$sourcedir";                                       # Directory with YaBB source files
\$admindir = "$admindir";                                         # Directory with YaBB admin source files
\$vardir = "$vardir";                                             # Directory with variable files
\$langdir = "$langdir";                                           # Directory with Language files and folders
\$helpfile = "$helpfile";                                         # Directory with Help files and folders
\$templatesdir = "$templatesdir";                                 # Directory with template files and folders
\$htmldir = "$htmldir";                                           # Base Path for all public-html files and folders
\$facesdir = "$facesdir";                                         # Base Path for all avatar files
\$uploaddir = "$uploaddir";                                       # Base Path for all attachment files
\$pmuploaddir = "$pmuploaddir";                                   # Base Path for all PM attachment files
\$modimgdir = "$modimgdir";                                       # Base Path for all mod images

########## URLs ##########

\$yyhtml_root = "$yyhtml_root";                                   # Base URL for all html/css files and folders
\$facesurl = "$facesurl";                                         # Base URL for all avatar files
\$uploadurl = "$uploadurl";                                       # Base URL for all attachment files
\$pmuploadurl = "$pmuploadurl";                                   # Base URL for all PM attachment files
\$modimgurl = "$modimgurl";                                       # Base URL for all mod images

1;
EOF

    fopen( FILE, '>./Paths.pm' )
      || setup_fatal_error( "$maintext_23 ./Paths.pm: ", 1 );
    print {FILE} nicely_aligned_file($setfile)
      or croak 'cannot print nicely aligned Paths.pm';
    fclose(FILE);

    if ( -e "$vardir/Paths.pm" ) { unlink "$vardir/Paths.pm"; }

    $yySetLocation = qq~$set_cgi?action=checkmodules~;
    redirectexit();
    return;
}

sub BrdInstall {
    $no_brddir = 0;
    if ( !-d "$boardsdir" ) { $no_brddir = 1; return 1; }
}

sub MesInstall {
    $no_mesdir = 0;
    if ( !-d "$datadir" ) { $no_mesdir = 1; return 1; }
}

sub MemInstall {
    $no_memdir = 0;
    if ( !-d "$memberdir" ) { $no_memdir = 1; return 1; }
}

sub VarInstall {
    my $varsdir = "$vardir";
    $no_vardir = 0;

    if ( !-d "$varsdir" ) { $no_vardir = 1; return 1; }

    if ( !-e "$varsdir/adminlog.txt" ) {
        fopen( ADMLOGFILE, ">$varsdir/adminlog.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/adminlog.txt: ", 1 );
        print {ADMLOGFILE} q{} or croak 'cannot print ADMLOGFILE';
        fclose(ADMLOGFILE);
    }

    if ( !-e "$varsdir/allowed.txt" ) {
        fopen( ALLOWFILE, ">$varsdir/allowed.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/allowed.txt: ", 1 );
        print {ALLOWFILE} "login\n"        or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "logout\n"       or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "display\n"      or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "messageindex\n" or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "pages\n"        or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "profile\n"      or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "register\n"     or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} "resetpass\n"    or croak 'cannot print ALLOWFILE';
        print {ALLOWFILE} 'viewprofile'    or croak 'cannot print ALLOWFILE';
        fclose(ALLOWFILE);
    }

    if ( !-e "$varsdir/attachments.txt" ) {
        fopen( ATTFILE, ">$varsdir/attachments.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/attachments.txt: ", 1 );
        print {ATTFILE} q{} or croak 'cannot print ATTFILE';
        fclose(ATTFILE);
    }
    if ( !-e "$varsdir/pm.attachments" ) {
        fopen( PMATTFILE, ">$varsdir/pm.attachments" )
          || setup_fatal_error( "$maintext_23 $varsdir/pm.attachments: ", 1 );
        print {PMATTFILE} q{} or croak 'cannot print PMATTFILE';
        fclose(PMATTFILE);
    }

    if ( !-e "$varsdir/ban_log.txt" ) {
        fopen( BANFILE, ">$varsdir/ban_log.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/ban_log.txt: ", 1 );
        print {BANFILE} q{} or croak 'cannot print ban_log.txt';
        fclose(BANFILE);
    }

    if ( !-e "$varsdir/banlist.txt" ) {
        fopen( BANLIST, ">$varsdir/banlist.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/banlist.txt: ", 1 );
        print {BANLIST} q{} or croak 'cannot print banlist.txt';
        fclose(BANLIST);
    }
    if ( !-e "$varsdir/clicklog.txt" ) {
        fopen( CLICKFILE, ">$varsdir/clicklog.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/clicklog.txt: ", 1 );
        print {CLICKFILE} q{} or croak 'cannot print clicklog.txt';
        fclose(CLICKFILE);
    }

    if ( !-e "$varsdir/errorlog.txt" ) {
        fopen( ERRORFILE, ">$varsdir/errorlog.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/errorlog.txt: ", 1 );
        print {ERRORFILE} q{} or croak 'cannot print errorlog.txt';
        fclose(ERRORFILE);
    }

    if ( !-e "$varsdir/flood.txt" ) {
        fopen( FLOODFILE, ">$varsdir/flood.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/flood.txt: ", 1 );
        print {FLOODFILE} '255.255.255.255|1119313741'
          or croak 'cannot print flood.txt';
        fclose(FLOODFILE);
    }

    if ( !-e "$varsdir/gmodsettings.txt" ) {
        my $setfile = << "EOF";
### Gmod Related Setttings ###

\$allow_gmod_admin = "on"; #
\$gmod_newfile = "on"; #

### Areas Gmods can Access ###

\%gmod_access = (
'ext_admin',"",

'newsettings;page=main',"",
'newsettings;page=advanced',"on",
'editbots', "",

'newsettings;page=news',"on",
'smilies',"on",
'setcensor',"on",
'modagreement',"on",
'eventcal_set',"",
'bookmarks',"",

'referer_control',"",
'newsettings;page=security',"",
'setup_guardian',"",
'newsettings;page=antispam',"",
'spam_questions',"",
'honeypot',"",

'managecats',"",
'manageboards',"",
'helpadmin',"on",
'editemailtemplates',"",

'addmember',"",
'viewmembers',"on",
'modmemgr',"",
'mailing',"on",
'ipban',"on",
'setreserve',"on",

'modskin',"",
'modcss',"",
'modtemp',"",

'clean_log',"on",
'boardrecount',"",
'rebuildmesindex',"",
'membershiprecount',"",
'rebuildmemlist',"",
'rebuildmemhist',"",
'deleteoldthreads',"",
'manageattachments',"on",
'backupsettings',"",

'detailedversion',"on",
'stats',"on",
'showclicks',"on",
'errorlog',"on",
'view_reglog',"on",

'modlist',"",
);

\%gmod_access2 = (
admin => "on",

newsettings => "on",
newsettings2 => "on",

eventcal_set2 => "",
eventcal_set3 => "",
bookmarks2 => "",
bookmarks_add => "",
bookmarks_add2 => "",
bookmarks_edit => "",
bookmarks_edit2 => "",
bookmarks_delete => "",
bookmarks_delete2 => "",
spam_questions2 => "",
spam_questions_add => "",
spam_questions_add2 => "",
spam_questions_edit => "",
spam_questions_edit2 => "",
spam_questions_delete => "",
spam_questions_delete2 => "",
honeypot2 => "",
honeypot_add => "",
honeypot_add2 => "",
honeypot_edit => "",
honeypot_edit2 => "",
honeypot_delete => "",
honeypot_delete2 => "",

deleteattachment => "on",
manageattachments2 => "on",
removeoldattachments => "on",
removebigattachments => "on",
rebuildattach => "on",
remghostattach => "on",

profile => "",
profile2 => "",
profileAdmin => "",
profileAdmin2 => "",
profileContacts => "",
profileContacts2 => "",
profileIM => "",
profileIM2 => "",
profileOptions => "",
profileOptions2 => "",

ext_edit => "",
ext_edit2 => "",
ext_create => "",
ext_reorder => "",
ext_convert => "",

myprofileAdmin => "",
myprofileAdmin2 => "",

delgroup => "",
editgroup => "",
editAddGroup2 => "",
modmemgr2 => "",
assigned => "",
assigned2 => "",

reordercats => "",
modifycatorder => "",
modifycat => "",
createcat => "",
catscreen => "",
reordercats2 => "",
addcat => "",
addcat2 => "",

modtemplate2 => "",
modtemp2 => "",
modstyle => "",
modstyle2 => "",
modcss => "",
modcss2 => "",

modifyboard => "",
addboard => "",
addboard2 => "",
reorderboards2 => "",
boardscreen => "",

smilieput => "on",
smilieindex => "on",
smiliemove => "on",
addsmilies => "on",

addmember => "on",
addmember2 => "on",
deletemultimembers => "on",
ml => "on",

mailmultimembers => "on",
mailing2 => "on",

activate => "on",
admin_descision => "on",
apr_regentry => "on",
del_regentry => "on",
rej_regentry => "on",
view_regentry => "on",
clean_reglog => "on",

cleanerrorlog => "on",
deleteerror => "on",

modagreement2 => "on",
modsettings2 => "on",
advsettings2 => "on",
referer_control2 => "",
removeoldthreads => "",
ipban2 => "on",
ipban3 => "on",
setcensor2 => "on",
setreserve2 => "on",

editbots2 => "",
);

1;
EOF

        fopen( SETTING, ">$varsdir/gmodsettings.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/gmodsettings.txt: ", 1 );
        print {SETTING} nicely_aligned_file($setfile)
          or croak 'cannot print gmodsetting.txt';
        fclose(SETTING);
    }

    if ( !-e "$varsdir/log.txt" ) {
        fopen( LOGFILE, ">$varsdir/log.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/log.txt: ", 1 );
        print {LOGFILE} 'admin|1105634411|127.0.0.1|'
          or croak 'cannot print log.txt';
        fclose(LOGFILE);
    }

    if ( !-e "$varsdir/modlist.txt" ) {
        fopen( MODSFILE, ">$varsdir/modlist.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/modlist.txt: ", 1 );
        print {MODSFILE} "admin\n" or croak 'cannot print modlist.txt';
        fclose(MODSFILE);
    }

    if ( !-e "$varsdir/news.txt" ) {
        fopen( NEWSFILE, ">$varsdir/news.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/news.txt: ", 1 );
        print {NEWSFILE} "Welcome to our forum.\n"
          or croak 'cannot print news.txt';
        print {NEWSFILE} "We've upgraded to YaBB 2.6.11!\n"
          or croak 'cannot print news.txt';
        print {NEWSFILE}
          "Visit [url=http://www.yabbforum.com]YaBB[/url] today \;\)\n"
          or croak 'cannot print news.txt';
        print {NEWSFILE}
          "Signup for free on our forum and benefit from new features!\n"
          or croak 'cannot print news.txt';
        print {NEWSFILE}
"Latest info can be found on the [url=http://www.yabbforum.com/community/]YaBB Chat and Support Community[/url].\n"
          or croak 'cannot print news.txt';
        fclose(NEWSFILE);
    }

    if ( !-e "$varsdir/oldestmes.txt" ) {
        fopen( OLDFILE, ">$varsdir/oldestmes.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/oldestmes.txt: ", 1 );
        print {OLDFILE} "1\n" or croak 'cannot print oldestmes.txt';
        fclose(OLDFILE);
    }

    if ( !-e "$varsdir/registration.log" ) {
        fopen( REGLOG, ">$varsdir/registration.log" )
          || setup_fatal_error( "$maintext_23 $varsdir/registration.log: ", 1 );
        print {REGLOG} q{} or croak 'cannot print registration.log';
        fclose(REGLOG);
    }

    if ( !-e "$varsdir/reserve.txt" ) {
        fopen( RESERVEFILE, ">$varsdir/reserve.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/reserve.txt: ", 1 );
        print {RESERVEFILE} "yabb\n"      or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "YaBBadmin\n" or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "administrator\n"
          or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "admin\n"     or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "y2\n"        or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "yabb2\n"     or croak 'cannot print reserve.txt';
        print {RESERVEFILE} "yabbforum\n" or croak 'cannot print reserve.txt';
        fclose(RESERVEFILE);
    }

    if ( !-e "$varsdir/reservecfg.txt" ) {
        fopen( RESERVEFILE, ">$varsdir/reservecfg.txt" )
          || setup_fatal_error( "$maintext_23 $varsdir/reservecfg.txt: ", 1 );
        print {RESERVEFILE} "checked\n" or croak 'cannot print reservecfg.txt';
        print {RESERVEFILE} "\n"        or croak 'cannot print reservecfg.txt';
        print {RESERVEFILE} "checked\n" or croak 'cannot print reservecfg.txt';
        print {RESERVEFILE} "checked\n" or croak 'cannot print reservecfg.txt';
        fclose(RESERVEFILE);
    }
    return;
}

sub checkmodules {
    LoadLanguage('Admin');
    tempstarter();

    $yymain .= qq~
<form action="$set_cgi?action=setinstall" method="post">~;

    require Admin::ModuleChecker;
    $yymain =~ s/float: left; |<\/div>$//gsm;

    if ($dont_continue_setup) {
        $yymain .= q~
    <table class="border-space pad-cell">
        <tr>
            <td class="windowbg2 center" style="margin-top:.5em; margin-bottom:1em; color:red; font-size:large;">
                Sorry, you cannot continue until you have installed at least the "Digest::MD5" module.
            </td>
      </tr>
      </table>~;
    }
    else {
        $yymain .= q~
    <table class="border-space pad-cell">
        <tr >
            <td class="catbg center" style="margin-top:.5em; margin-bottom:1em">
                  You can always see the above information on the start page of your AdminCenter.<br />
                  Therefore you can continue now and install missing modules later if you really need them.<br />
                  <br />
                <input type="submit" value="Continue" />
            </td>
      </tr>
      </table>~;
    }

    $yymain .= q~
</div>
</form>
~;

    $yyim    = 'You are running YaBB 2.6.11 Setup.';
    $yytitle = 'YaBB 2.6.11 Setup';
    SetupTemplate();
    return;
}

sub SetInstall {
    LoadLanguage('Admin');
    tempstarter();

    # show available languages
    opendir DIR, $langdir
      || setup_fatal_error( "Directory: $langdir: ", 1 );
    my @lfilesanddirs = readdir DIR;
    closedir DIR;
    my $drawnldirs;
    foreach my $fld ( sort { lc($a) cmp lc $b } @lfilesanddirs ) {
        if (   -d "$langdir/$fld"
            && -e "$langdir/$fld/Main.lng"
            && $fld =~ m{\A[0-9a-zA-Z_\#\%\-\:\+\?\$\&\~\,\@/]+\Z}sm )
        {
            if ( 'English' eq $fld ) {
                $drawnldirs .=
                  qq~<option value="$fld" selected="selected">$fld</option>\n~;
            }
            else { $drawnldirs .= qq~<option value="$fld">$fld</option>\n~; }
        }
    }

    $yymain .= qq~
<form action="$set_cgi?action=setinstall2" method="post">
<div class="bordercolor borderbox">
    <table class="tabtitle">
        <tr>
            <td style="padding-left:1%">System Setup</td>
        </tr>
    </table>
    <table class="border-space pad-cell">
        <tr>
            <td class="windowbg">
                Here you can set some of the default settings for your new YaBB 2.6.11 forum.<br />
                After finishing the setup procedure, you should login to your forum and go to your 'Admin Center' -&gt; 'Forum Settings' where you can modify this and other settings.
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="div45">
                    <label for="mbname">Message Board Name</label>
                </div>
                <div class="div55">
                    <input type="text" name="mbname" id="mbname" size="35" value="My Perl YaBB Forum" />
                </div>
                <br style="clear:both" />
                <div class="div45">
                    <label for="webmaster_email">Webmaster E-mail Address</label>
                </div>
                <div class="div55">
                    <input type="text" name="webmaster_email" id="webmaster_email" size="35" value="webmaster\@mysite.com" />
                </div>
                <br style="clear:both" />
                <div class="div45">
                    <label for="defaultlanguage">Admin Language / Forum Default Language</label>
                </div>
                <div class="div55">
                    <select name="defaultlanguage" id="defaultlanguage">$drawnldirs</select>
                </div>
                <br style="clear:both" />
                <div class="div45">
                    <label for="defaultencoding">Default Forum Character Encoding
                    <br /><span class="small"><b>Note</b>: If you are going to import an older English Language forum choose 'ISO-8859-1'.</span></label>
                </div>
                <div class="div55">
                    <select name="defaultencoding" id="defaultencoding" size="1">
                        <option value="UTF-8">UTF-8</option>
                        <option value="ISO-8859-1">ISO-8859-1</option>
                    </select>
                </div>
                <br style="clear:both" />
                <div class="div45">
                    <label for="timeselect">Default Time Format</label>
                </div>
                <div class="div55">
                    <select name="timeselect" id="timeselect" size="1">
                        <option value="1">01/31/01 at 13:15:17</option>
                        <option value="5">01/31/01 at 1:15pm</option>
                        <option value="4" selected="selected">Jan 12th, 2001 at 1:15pm</option>
                        <option value="8"> 12th Jan, 2001 at 1:15pm</option>
                        <option value="2">31.01.01 at 13:15:17</option>
                        <option value="3">31.01.2001 at 13:15:17</option>
                        <option value="6">31. Jan at 13:15</option>
                    </select>
                </div>
                <br style="clear:both" />
                <div class="div45">
                    Forum Time: (Your actual displayed UTC time). The Forum Time Zone can be changed in the Admin Center.
                </div>
                <div class="div55">
                    <b>~
      . timeformat( $date, 4 ) . q~</b>
            </div>
            </td>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" value="Continue" />
            </td>
      </tr>
      </table>
</div>
</form>
~;

    $yyim    = 'You are running YaBB 2.6.11 Setup.';
    $yytitle = 'YaBB 2.6.11 Setup';
    SetupTemplate();
    return;
}

sub SetInstall2 {
    if ( $action eq 'checkmodules' || $action eq 'setinstall2' ) {
        $settings_file_version = 'YaBB 2.6.11';
        $yymycharset             = $FORM{'defaultencoding'} || 'UTF-8' ;
        $maintenance           = 1;
        $rememberbackup        = 0;
        $guestaccess           = 1;
        $mbname                = $FORM{'mbname'} || 'My Perl YaBB Forum';
        $mbname =~ s/\"/\'/gxsm;
        $forumstart            = timetostring( int time );
        $Cookie_Length         = 1;
        $regtype               = 3;
        $RegAgree              = 1;
        $RegReasonSymbols      = 500;
        $preregspan            = 24;
        $emailpassword         = 0;
        $emailnewpass          = 0;
        $emailwelcome          = 0;
        $name_cannot_be_userid = 1;
        $gender_on_reg         = 0;
        $lang                  = $FORM{'defaultlanguage'} || 'English';
        $default_template      = 'Forum default';
        $mailprog              = '/usr/sbin/sendmail';
        $smtp_server           = '127.0.0.1';
        $smtp_auth_required    = 1;
        $authuser              = q~admin~;
        $authpass              = q~admin~;
        $webmaster_email = $FORM{'webmaster_email'} || 'webmaster@mysite.com';
        $mailtype        = 0;
        $maintenancetext =
'We are currently upgrading our forum again. Please check back shortly!';
        $MenuType               = 2;
        $profilebutton          = 1;
        $allow_hide_email       = 1;
        $showlatestmember       = 1;
        $shownewsfader          = 0;
        $Show_RecentBar         = 1;
        $showmodify             = 1;
        $ShowBDescrip           = 1;
        $showuserpic            = 1;
        $showusertext           = 1;
        $showtopicviewers       = 1;
        $showtopicrepliers      = 1;
        $showgenderimage        = 1;
        $showyabbcbutt          = 1;
        $nestedquotes           = 1;
        $parseflash             = 0;
        $enableclicklog         = 0;
        $showimageinquote       = 0;
        $enable_ubbc            = 1;
        $enable_news            = 1;
        $allowpics              = 1;
        $upload_useravatar      = 0;
        $upload_avatargroup     = q{};
        $avatar_limit           = 100;
        $avatar_dirlimit        = 10_000;
        $enable_guestposting    = 0;
        $ML_Allowed             = 1;
        $enable_quickpost       = 0;
        $enable_quickreply      = 0;
        $enable_quickjump       = 0;
        $enable_markquote       = 0;
        $quick_quotelength      = 1000;
        $enable_quoteuser       = 0;
        $quoteuser_color        = '#0033cc';
        $guest_media_disallowed = 0;
        $enable_guestlanguage   = 1;
        $enable_notifications   = 0;
        $NewNotificationAlert   = 0;
        $autolinkurls           = 1;
        $forumnumberformat      = $FORM{'forumnumberformat'} || 1;
        $timeselected           = $FORM{'timeselect'} || 0;
        $timecorrection         = 0;
        $enabletz               = 0;
        $default_tz             = 'UTC';
        $dynamic_clock          = 1;
        $TopAmmount             = 15;
        $maxdisplay             = 20;
        $maxfavs                = 20;
        $maxrecentdisplay       = 25;
        $maxrecentdisplay_t     = 25;
        $maxsearchdisplay       = 15;
        $maxmessagedisplay      = 15;
        $MaxMessLen             = 5000;
        $AdMaxMessLen           = 5000;
        $MaxIMMessLen           = 2000;
        $AdMaxIMMessLen         = 3000;
        $MaxCalMessLen          = 200;
        $AdMaxCalMessLen        = 300;
        $fontsizemin            = 6;
        $fontsizemax            = 32;
        $MaxSigLen              = 200;
        $MaxAwayLen             = 200;
        $ClickLogTime           = 100;
        $max_log_days_old       = 90;
        $fadertime              = 1000;
        $defaultusertxt         = 'I Love YaBB 2.6.11!';
        $timeout                = 5;
        $HotTopic               = 10;
        $VeryHotTopic           = 25;
        $barmaxdepend           = 0;
        $barmaxnumb             = 500;
        $defaultml              = 'regdate';
        $max_avatar_width       = 65;
        $max_avatar_height      = 65;
        $fix_avatar_img_size    = 0;
        $max_avatarml_width     = 65;
        $max_avatarml_height    = 65;
        $fix_avatarml_img_size  = 0;
        $max_post_img_width     = 400;
        $max_post_img_height    = 0;
        $fix_post_img_size      = 0;
        $max_signat_img_width   = 300;
        $max_signat_img_height  = 0;
        $fix_signat_img_size    = 0;
        $max_attach_img_width   = 200;
        $max_attach_img_height  = 0;
        $fix_attach_img_size    = 0;
        $max_brd_img_width   = 50;
        $max_brd_img_height  = 50;
        $fix_brd_img_size    = 0;
        $img_greybox            = 1;
        $extendedprofiles       = 0;
        $enable_freespace_check = 0;
        $enableguestsearch      = 1;
        $enableguestquicksearch = 1;
        $showregdate            = 1;
        $addtab_on              = 1;
        $bm_subcut              = 50;
        $maxadminlog            = 5;

        if ( -e '/bin/gzip' && open GZIP, '|, gzip -f' ) {
            $gzcomp = 1;
        }
        else {
            eval { require Compress::Zlib; Compress::Zlib::memGzip('test'); };
            $gzcomp = $@ ? 0 : 2;
        }
        $gzforce        = 0;
        $cachebehaviour = 0;
        $use_flock      = 0;
        $faketruncation = 0;
        $debug          = 0;

        $checkallcaps         = 0;
        $set_subjectMaxLength = 50;
        $honeypot             = 1;
        $speedpostdetection   = 1;
        $spd_detention_time   = 300;
        $min_post_speed       = 2;
        $post_speed_count     = 3;
        $minlinkpost          = 0;
        $minlinksig           = 0;
        $minlinkweb           = 0;
        $showsearchboxnum     = 31;
        $showregdate          = 1;
        $enableguestsearch    = 1;
        $enableguestquicksearch = 1;
        $maxsteps             = 40;
        $stepdelay            = 75;
        $fadelinks            = 0;
        $cookieviewtime = 525_600;

        # Let's generate a masterkey at setup time.
        my @chars = ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9 );
        for ( 1 .. 24 ) { $masterkey .= $chars[ rand @chars ]; }

    }
    else {
        $forumstart = timetostring( $INFO{'firstforum'} );
        $MaxSigLen  = $siglength || 200;
        $fadertime  = 1000;
    }

    my $setfile = << "EOF";
###############################################################################
# Settings.pm                                                                 #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Open-Source Community Software for Webmasters                               #
# Version:        YaBB 2.6.11                                                 #
# Packaged:       December 2, 2014                                            #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2014  YaBB (www.yabbforum.com) - All Rights Reserved.    #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
###############################################################################

########## Board Info ##########
# Note: these settings must be properly changed for YaBB to work

\$settings_file_version = "$settings_file_version"; # If not equal actual YaBBversion then the updating process is run through
\$yymycharset = "$yymycharset";                        # character encoding (usually ISO-8859-1 for older forums)
                                            # or 'UTF-8';
\%templateset = (
'Forum default' => "default|default|default|default|default|default|default|",
);                                                  # Forum templates settings

\$maintenance = $maintenance;                       # Set to 1 to enable Maintenance mode
\$rememberbackup = $rememberbackup;                 # seconds past since last backup until alert is displayed
\$guestaccess = $guestaccess;                       # Set to 0 to disallow guests from doing anything but login or register

\$mbname = q^$mbname^;                              # The name of your YaBB forum
\$forumstart = "$forumstart";                       # The start date of your YaBB Forum
\$Cookie_Length = $Cookie_Length;                   # Default to set login cookies to stay for
\$cookieusername = "$cookieusername";               # Name of the username cookie
\$cookiepassword = "$cookiepassword";               # Name of the password cookie
\$cookiesession_name = "$cookiesession_name";       # Name of the Session cookie
\$cookietsort = "$cookietsort";                     # Name of the Topic Sort
\$cookieview = "$cookieview";                       # Name of the Guest Message Limit cookie
\$cookieviewtime = "$cookieviewtime";
\$screenlogin = $screenlogin;                # allow members to login using their screen name.

\$regtype = $regtype;                               # 0 = registration closed (only admin can register),
                                                    # 1 = pre registration with admin approval,
                                                    # 2 = pre registration and email activation, 3 = open registration

\$RegAgree = $RegAgree;                             # Set to 1 to display the registration agreement when registering
\$RegReasonSymbols = $RegReasonSymbols;             # Maximum allowed symbols in User reason(s) for registering
\$preregspan = $preregspan;                         # Time span in hours for users to account activation before cleanup.
\$pwstrengthmeter_scores = "10,15,30,40";           # Password-Strength-Meter Scores
\$pwstrengthmeter_common = qq~"123","123456"~;      # Password-Strength-Meter common words
\$pwstrengthmeter_minchar = 5;                      # Password-Strength-Meter minimum characters
\$emailpassword = $emailpassword;                   # 0 - instant registration. 1 - password emailed to new members
\$emailnewpass = $emailnewpass;                     # Set to 1 to email a new password to members if
                                                    # they change their email address
\$emailwelcome = $emailwelcome;                     # Set to 1 to email a welcome message to users even
                                                    # when you have mail password turned off
\$name_cannot_be_userid = $name_cannot_be_userid;   # Set to 1 to require users to have different usernames and display names

\$gender_on_reg = $gender_on_reg;                   # 0: do not ask for gender on registration
                                                    # 1: ask for gender, no input required
                                                    # 2: ask for gender, input required
\$lang = "$lang";                                   # Default Forum Language
\$default_template = "$default_template";           # Default Forum Template

\$mailprog = "$mailprog";                           # Location of your sendmail program
\$smtp_server = "$smtp_server";                     # Address of your SMTP-Server (for Net::SMTP::TLS, specify the port number with a ":<portnumber>" at the end)
\$smtp_auth_required = $smtp_auth_required;         # Set to 1 if the SMTP server requires Authorisation
\$authuser = q^$authuser^;                          # Username for SMTP authorisation
\$authpass = q^$authpass^;                          # Password for SMTP authorisation
\$webmaster_email = q^$webmaster_email^;            # Your email address. (eg: \$webmaster_email = q^admin\@host.com^;)
\$mailtype = $mailtype;                             # Mail program to use: 0 = sendmail, 1 = SMTP, 2 = Net::SMTP, 3 = Net::SMTP::TLS

\$UseHelp_Perms = 1;                                # Help Center: 1 == use permissions, 0 == do not use permissions

########## MemberGroups ##########

\$Group{'Administrator'} = 'Forum Administrator|5|staradmin.png|#FF0000|0|0|0|0|0|0|0';
\$Group{'Global Moderator'} = 'Global Moderator|5|stargmod.png|#0000FF|0|0|0|0|0|0|0';
\$Group{'Mid Moderator'} = 'Forum Moderator|5|starfmod.png|#008080|0|0|0|0|0|0|0';
\$Group{'Moderator'} = 'Board Moderator|5|starmod.png|#008000|0|0|0|0|0|0|0';
\$Post{'500'} = "God Member|5|starsilver.png||0|0|0|0|0|0";
\$Post{'250'} = "Senior Member|4|stargold.png||0|0|0|0|0|0";
\$Post{'100'} = "Full Member|3|starblue.png||0|0|0|0|0|0";
\$Post{'50'} = "Junior Member|2|stargold.png||0|0|0|0|0|0";
\$Post{'-1'} = "New Member|1|stargold.png||0|0|0|0|0|0";

########## Layout ##########

\$maintenancetext = "$maintenancetext";             # User-defined text for Maintenance mode (leave blank for default text)
\$MenuType = $MenuType;                             # 1 for text menu or anything else for images menu
\$profilebutton = $profilebutton;                   # 1 to show view profile button under post, or 0 for blank
\$allow_hide_email = $allow_hide_email;             # Allow users to hide their email from public. Set 0 to disable
\$showlatestmember = $showlatestmember;             # Set to 1 to display "Welcome Newest Member" on the Board Index
\$shownewsfader = $shownewsfader;                   # 1 to allow or 0 to disallow NewsFader javascript on the Board Index
                                                    # If 0, you'll have no news at all unless you put in a {yabb news} tag
                                                    # back into template.html!!!
\$Show_RecentBar = $Show_RecentBar;                 # Set to 1 to display the Recent Post on Board Index
\$showmodify = $showmodify;                         # Set to 1 to display "Last modified: Realname - Date" under each message
\$ShowBDescrip = $ShowBDescrip;                     # Set to 1 to display board descriptions on the topic (message) index for each board
\$showuserpic = $showuserpic;                       # Set to 1 to display each member's picture in the
                                                    # message view (by the ICQ.. etc.)
\$showusertext = $showusertext;                     # Set to 1 to display each member's personal text
                                                    # in the message view (by the ICQ.. etc.)
\$showtopicviewers = $showtopicviewers;             # Set to 1 to display members viewing a topic
\$showtopicrepliers = $showtopicrepliers;           # Set to 1 to display members replying to a topic
\$showgenderimage = $showgenderimage;               # Set to 1 to display each member's gender in the
                                                    # message view (by the ICQ.. etc.)
\$showyabbcbutt = $showyabbcbutt;                   # Set to 1 to display the yabbc buttons on Posting and IM Send Pages
\$nestedquotes = $nestedquotes;                     # Set to 1 to allow quotes within quotes
                                                    # (0 will filter out quotes within a quoted message)
\$parseflash = $parseflash;                         # Set to 1 to parse the flash tag
\$enableclicklog = $enableclicklog;                 # Set to 1 to track stats in Clicklog (this may slow your board down)
\$showimageinquote = $showimageinquote;             # Set to 1 to shows images in quotes, 0 displays a link to the image
\$showregdate = $showregdate;                       # Set to 1 to show date of registration.
\@pallist = ("#ff0000","#00ff00","#0000ff","#00ffff","#ff00ff","#ffff00"); # color settings of the palette

########## Feature Settings ##########

\$enable_ubbc = $enable_ubbc;                       # Set to 1 if you want to enable UBBC (Uniform Bulletin Board Code)
\$enable_news = $enable_news;                       # Set to 1 to turn news on, or 0 to set news off
\$allowpics = $allowpics;                           # set to 1 to allow members to choose avatars in their profile
\$upload_useravatar = $upload_useravatar;           # set to 1 to allow members to upload avatars for their profile
\$upload_avatargroup = '$upload_avatargroup';       # membergroups allowed to upload avatars for their profile, '' == all members
\$avatar_limit = $avatar_limit;                     # set to the maximum size of the uploaded avatar, 0 == no limit
\$avatar_dirlimit = $avatar_dirlimit;               # set to the maximum size of the upload avatar directory, 0 == no limit
\$default_avatar = $default_avatar;                 # Set to 1 to show a default avatar if the member hasn't added a picture
\$default_userpic = "\Q$default_userpic\E";         # Set the file name for the default avatar

\$enable_guestposting = $enable_guestposting;       # Set to 0 if do not allow 1 is allow.
\$guest_media_disallowed = $guest_media_disallowed; # disallow browsing guests to see media files or
                                                    # have clickable auto linked urls in messages.
\$enable_guestlanguage = $enable_guestlanguage;     # allow browsing guests to select their language
                                                    # - requires more than one language pack!
                                                    # - Set to 0 if do not allow 1 is allow.

\$enable_notifications = $enable_notifications;     # - Allow e-mail notification for boards/threads
                                                    #   listed in "My Notifications" => value == 1
                                                    # - Allow e-mail notification when new PM comes in
                                                    #   => value == 2
                                                    # - value == 0 => both disabled | value == 3 => both enabled

\$NewNotificationAlert = $NewNotificationAlert;     # enable notification alerts (popup) for new notifications
\$autolinkurls = $autolinkurls;                     # Set to 1 to turn URLs into links, or 0 for no auto-linking.

\$forumnumberformat = $forumnumberformat;           # Select your preferred output Format for Numbers
\$timeselected = $timeselected;                     # Select your preferred output Format of Time and Date
\$timecorrection = $timecorrection;                 # Set time correction for server time in seconds
\$enabletz = $enabletz;                             # Allow for timezone selection
\$default_tz = "$default_tz";                       # default forum timezone
\$dynamic_clock = $dynamic_clock;                   # Set to a value enables the dynamic clock at the top of the page
\$TopAmmount = $TopAmmount;                         # No. of top posters to display on the top members list
\$maxdisplay = $maxdisplay;                         # Maximum of topics to display
\$maxfavs = $maxfavs;                               # Maximum of favorite topics to save in a profile
\$maxrecentdisplay = $maxrecentdisplay;             # Maximum of topics to display on recent posts by a user (-1 to disable)
\$maxrecentdisplay_t = $maxrecentdisplay_t;         # Maximum of topics to display on recent topics (-1 to disable)
\$maxsearchdisplay = $maxsearchdisplay;             # Maximum of messages to display in a search query  (-1 to disable search)
\$maxmessagedisplay = $maxmessagedisplay;           # Maximum of messages to display
\$MaxMessLen = $MaxMessLen;                         # Maximum Allowed Characters in a Posts
\$AdMaxMessLen = $AdMaxMessLen;                     # Maximum Allowed Characters in a Posts for Admins
\$MaxIMMessLen = $MaxIMMessLen;                     # Maximum Allowed Characters in a PM
\$AdMaxIMMessLen = $AdMaxIMMessLen;                 # Maximum Allowed Characters in a PM for Admins
\$MaxCalMessLen = $MaxCalMessLen;                   # Maximum Allowed Characters in a Cal event
\$AdMaxCalMessLen = $AdMaxCalMessLen;               # Maximum Allowed Characters in a Cal Event for Admins
\$fontsizemin = $fontsizemin;                       # Minimum Allowed Font height in pixels
\$fontsizemax = $fontsizemax;                       # Maximum Allowed Font height in pixels
\$checkallcaps = $checkallcaps;                     # Set to 0 to allow ALL CAPS in posts (subject and message) or set to a value > 0 to open a JS-alert if more characters in ALL CAPS were there.
\$set_subjectMaxLength = $set_subjectMaxLength;     # Maximum Allowed Characters in a Posts Subject
\$honeypot = $honeypot;                                            # Set to 1 to activate Honeypot spam deterrent
\$speedpostdetection = $speedpostdetection;         # Set to 1 to detect speedposters and delay their spam actions
\$spd_detention_time = $spd_detention_time;         # Time in seconds before a speedposting ban is lifted again
\$min_post_speed = $min_post_speed;                 # Minimum time in seconds between entering a post form and submitting a post
\$minlinkpost = $minlinkpost;                       # Minimum amount of posts a member needs to post links and images
\$minlinksig = $minlinksig;                         # Minimum amount of posts a member needs to create links and images in signature
\$minlinkweb = $minlinkweb;
\$post_speed_count = $post_speed_count;             # Maximum amount of abuses befor a user gets banned
\$MaxSigLen = $MaxSigLen;                           # Maximum Allowed Characters in Signatures
\$MaxAwayLen = $MaxAwayLen;                         # Maximum Allowed Characters in Away message
\$ClickLogTime = $ClickLogTime;                     # Time in minutes to log every click to your forum
                                                    # (longer time means larger log file size)
\$max_log_days_old = $max_log_days_old;             # If an entry in the user's log is older than ... days remove it

\$maxsteps = $maxsteps;                             # Number of steps to take to change from start color to endcolor
\$stepdelay = $stepdelay;                           # Time in miliseconds of a single step
\$fadelinks = $fadelinks;                           # Fade links as well as text?

\$defaultusertxt = qq~$defaultusertxt~;             # The dafault usertext visible in users posts
\$timeout = $timeout;                               # Minimum time between 2 postings from the same IP
\$HotTopic = $HotTopic;                             # Number of posts needed in a topic for it to be classed as "Hot"
\$VeryHotTopic = $VeryHotTopic;                     # Number of posts needed in a topic for it to be classed as "Very Hot"
\$barmaxdepend = $barmaxdepend;                     # Set to 1 to let bar-max-length depend on top poster
                                                    # or 0 to depend on a number of your choise
\$barmaxnumb = $barmaxnumb;                         # Select number of post for max. bar-length in memberlist
\$defaultml = "$defaultml";

\$ML_Allowed = $ML_Allowed;                         # allow browse MemberList

########## Quick Reply configuration ##########
\$enable_quickpost = $enable_quickpost;             # Set to 1 if you want to enable the quick post box
\$enable_quickreply = $enable_quickreply;           # Set to 1 if you want to enable the quick reply box
\$enable_quickjump = $enable_quickjump;             # Set to 1 if you want to enable the jump to quick reply box
\$enable_markquote = $enable_markquote;             # Set to 1 if you want to enable the mark&quote feature
\$quick_quotelength = $quick_quotelength;           # Set the max length for Quick Quotes
\$enable_quoteuser = $enable_quoteuser;             # Set to 1 if you want to enable userquote
\$quoteuser_color = "$quoteuser_color";             # Set the default color of @ in userquote

########## MemberPic Settings ##########

\$max_avatar_width = $max_avatar_width;             # Set maximum pixel width to which the selfselected userpics are resized,
                                                    # 0 disables this limit
\$max_avatar_height = $max_avatar_height;           # Set maximum pixel height to which the selfselected userpics are resized,
                                                    # 0 disables this limit
\$fix_avatar_img_size = $fix_avatar_img_size;       # Set to 1 disable the image resize feature and sets the image size to the
                                                    # max_... values. If one of the max_... values is 0 the image is shown in its
                                                    # proportions to the other value. If both are 0 the image is shown at its original size.
\$max_avatarml_width = $max_avatarml_width;         # Set maximum pixel width to which the selfselected userpics in member list are resized, 0 disables
                                                    #  this limit
\$max_avatarml_height = $max_avatarml_height;       #Set maximum pixel height to which the selfselected userpics in member list are resized, 0 disables
                                                    #  this limit
\$fix_avatarml_img_size = $fix_avatarml_img_size;                       # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of
                                                    #  the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_post_img_width = $max_post_img_width;         # Set maximum pixel width for images, 0 disables this limit
\$max_post_img_height = $max_post_img_height;       # Set maximum pixel height for images, 0 disables this limit
\$fix_post_img_size = $fix_post_img_size;           # Set to 1 disable the image resize feature and sets the image size to the
                                                    # max_... values. If one of the max_... values is 0 the image is shown in its
                                                    # proportions to the other value. If both are 0 the image is shown at its original size.
\$max_signat_img_width = $max_signat_img_width;     # Set maximum pixel width for images in the signature, 0 disables this limit
\$max_signat_img_height = $max_signat_img_height;   # Set maximum pixel height for images in the signature, 0 disables this limit
\$fix_signat_img_size = $fix_signat_img_size;       # Set to 1 disable the image resize feature and sets the image size to the
                                                    # max_... values. If one of the max_... values is 0 the image is shown in its
                                                    # proportions to the other value. If both are 0 the image is shown at its original size.
\$max_attach_img_width = $max_attach_img_width;     # Set maximum pixel width for attached images, 0 disables this limit
\$max_attach_img_height = $max_attach_img_height;   # Set maximum pixel height for attached images, 0 disables this limit
\$fix_attach_img_size = $fix_attach_img_size;       # Set to 1 disable the image resize feature and sets the image size to the
                                                    # max_... values. If one of the max_... values is 0 the image is shown in its
                                                    # proportions to the other value. If both are 0 the image is shown at its original size.
\$max_brd_img_width = $max_brd_img_width;                           # Set maximum pixel width to which the Board Images are resized, 0 disables this limit
\$max_brd_img_height = $max_brd_img_height;                          # Set maximum pixel height to which the Board Images are resized, 0 disables this limit
\$fix_brd_img_size = $max_brd_img_size;
\$img_greybox = $img_greybox;                       # Set to 0 to disable "greybox" (each image is shown in a new window)
                                                    # Set to 1 to enable the attachment and post image "greybox" (one image/page)
                                                    # Set to 2 to enable the attachment and post image "greybox" =>
                                                    # attachment images: (all images/page), post images: (one image/page)

########## Extended Profiles ##########
\$extendedprofiles = $extendedprofiles;             # Set to 1 to enabled 'Extended Profiles'. Turn it off (0) to save server load.

########## Event Calendar ##########

# Standard Calendar Setting
\$Show_EventCal = 0;
\$Event_TodayColor = '#ff0000';
\$DisplayEvents = 0;
\$CalShortEvent = 0;
\$bm_subcut = $bm_subcut;
########## File Locking ##########
\$checkspace = 0;                                                # Set to 1 to enable any freespace checking (should remain disabled on Windows/IIS servers)
\$enable_freespace_check = $enable_freespace_check; # Enable the free disk space check on every pageview?
\$gzcomp = $gzcomp;                                 # GZip compression: 0 = No Compression,
                                                    # 1 = External gzip, 2 = Zlib::Compress
\$gzforce = $gzforce;                               # Do not try to check whether browser supports GZip
\$cachebehaviour = $cachebehaviour;                 # Browser Cache Control: 0 = No Cache must revalidate, 1 = Allow Caching
\$use_flock = $use_flock;                           # Set to 0 if your server doesn't support file locking,
                                                    # 1 for Unix/Linux and WinNT, and 2 for Windows 95/98/ME
\$faketruncation = $faketruncation;                 # Enable this option only if YaBB fails with the error:
                                                    # "truncate() function not supported on this platform."
                                                    # 0 to disable, 1 to enable.
\$debug = $debug;                                   # If set to 1 debug info is added to the template
                                                    # tags are <yabb fileactions> and <yabb filenames>

########## Search Settings ##########
\$enableguestsearch = $enableguestsearch;       # Set to 1 to enable guests access to advanced search.
\$enableguestquicksearch = $enableguestquicksearch; # Set to 1 to enable guests access to quick search.
\$mgqcksearch = "\Q$mgqcksearch\E";
\$mgadvsearch = "\Q$mgadvsearch\E";
\$qcksearchtype = "\Q$qcksearchtype\E";
\$qckage = "\Q$qckage\E";

###############################################################################
# Advanced Settings                                                           #
###############################################################################

########## RSS Settings ##########

\$rss_disabled = $rss_disabled;         # Set to 1 to disable the RSS feed
\$rss_limit = $rss_limit;           # Maximum number of topics in the feed
\$rss_message = $rss_message;           # Message to display in the feed
                            # 0: None
                            # 1: Latest Post
                            # 2: Original Post in the topic
\$showauthor = $showauthor;         # Show author name
\$rssemail = '$rssemail';             # default email if author email not shown
\$showdate = $showdate;             # Show post date

########## New Member Notification Settings ##########
\$new_member_notification = 0;                    # Set to 1 to enable the new member notification
\$new_member_notification_mail = "\Q$new_member_notification_mail\E";   # Your "New Member Notification"-email address.

\$sendtopicmail = 2;                              # Set to 0 for send NO topic email to friend
                                                  # Set to 1 to send topic email to friend via YaBB
                                                  # Set to 2 to send topic email to friend via user program
                                                  # Set to 3 to let user decide between 1 and 2

########## In-Thread Multi Delete ##########

\$mdadmin = 1;
\$mdglobal = 1;
\$mdfmod = 1;
\$mdmod = 1;
\$adminbin = 0;                                   # Skip recycle bin step for admins and delete directly

########## Moderation Update ##########

\$adminview = 2;                                  # Multi-admin settings for Administrators:
                                                  # 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$gmodview = 2;                                   # Multi-admin settings for Global Moderators:
                                                  # 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$fmodview = 2;                                   # Multi-admin settings for Forum Moderators:
                                                  # 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$modview = 2;                                    # Multi-admin settings for Board Moderators:
                                                  # 0=none, 1=icons 2=single checkbox 3=multiple checkboxes

\$maxadminlog = $maxadminlog;                                #Maximum number of entries stored in adminlog.txt (oldest entries are deleted).
########## Memberview ##########

\$showallgroups = 1;
\$OnlineLogTime = 15;                             # Time in minutes before Users are removed from the Online Log
\$lastonlineinlink = 0;                           # Show "Last online X days and XX:XX:XX hours ago." to all members == 1

########## Polls ##########

\$numpolloptions = 8;                             # Number of poll options
\$maxpq = 60;                                     # Maximum Allowed Characters in a Poll Qestion?
\$maxpo = 50;                                     # Maximum Allowed Characters in a Poll Option?
\$maxpc = 0;                                      # Maximum Allowed Characters in a Poll Comment?
\$useraddpoll = 1;                                # Allow users to add polls to existing threads? (1 = yes)
\$ubbcpolls = 1;                                  # Allow UBBC tags and smilies in polls? (1 = yes)

########## Instant Message ##########

\$PM_level = 1;
\$numposts = 1;                                   # Number of posts required to send Instant Messages
\$imspam = 0;                                     # Percent of Users a user is a allowed to send a message at once
\$numibox = 20;                                   # Number of maximum Messages in the IM-Inbox
\$numobox = 20;                                   # Number of maximum Messages in the IM-Outbox
\$numstore = 20;                                  # Number of maximum Messages in the Storage box
\$numdraft = 20;                                  # Number of maximum Messages in the Draft box
\$enable_imlimit = 0;                             # Set to 1 to enable limitation of incoming and outgoing im messages
\$enable_storefolders = 0;                        # enable additonal store folders - in/out are default for all
                                                  # 0=no > 1 = number, max 25
\$imtext = qq~Welcome to my boards~;
\$sendname = admin;
\$imsubject = "Hey Hey :)";
\$send_welcomeim = 1;
\$PMenableBm_level = 3;                            # minimum level to send? 0 = off, 1 = mods, 2 = gmod, 3 = admin

########## Topic Summary Cutter ##########

\$cutamount  = "15";                              # Number of posts to list in topic summary
\$ttsreverse = 0;                                 # Reverse Topic Summaries in Topic (most recent becomes first)
\$ttsureverse = 0;                                # Reverse Topic Summaries in Topic (most recent becomes first) allowed as user wishes? Yes == 1
\$tsreverse = 1;                                  # Reverse Topic Summaries (So most recent is first

########## Time Lock ##########

\$tlnomodflag = 1;                                # Set to 1 limit time users may modify posts
\$tlnomodtime = 1;                                # Time limit on modifying posts (days)
\$tlnodelflag = 1;                                # Set to 1 limit time users may delete posts
\$tlnodeltime = 5;                                # Time limit on deleting posts (days)
\$tllastmodflag = 1;                              # Set to 1 allow users to modify posts up to
                                                  # the specified time limit w/o showing "last Edit" message
\$tllastmodtime = 60;                             # Time limit to modify posts w/o triggering "last Edit" message (in minutes)

########## File Attachment Settings ##########

\$limit = 250;                                    # Set to the maximum number of kilobytes an attachment can be.
                                                  # Set to 0 to disable the file size check.
\$dirlimit = 10000;                               # Set to the maximum number of kilobytes the attachment directory can hold.
                                                  # Set to 0 to disable the directory size check.
\$overwrite = 0;                                  # Set to 0 to auto rename attachments if they exist,
                                                  # 1 to overwrite them or 2 to generate an error if the file exists already.
\@ext = qw(txt doc docx psd pdf bmp jpe jpg jpeg gif png swf zip rar tar); # The allowed file extensions for file attachements.
                                                  # The variable should be set in the form of "jpg bmp gif" and so on.
\$checkext = 1;                                   # Set to 1 to enable file extension checking,
                                                  # set to 0 to allow all file types to be uploaded
\$amdisplaypics = 1;                              # Set to 1 to display attached pictures in posts,
                                                  # set to 0 to only show a link to them.
\$allowattach = 1;                                # Set to the number of maximum files attaching a post,
                                                  # set to 0 to disable file attaching.
\$allowguestattach = 0;                           # Set to 1 to allow guests to upload attachments, 0 to disable guest attachment uploading.

\$allowAttachIM = 0;                            # Set the maximum number of file attachments allowed in personal messages, set to 0 to disable file attachments in personal messages.

\@pmAttachExt = qw(txt doc docx psd pdf bmp jpe jpg jpeg gif png swf zip rar tar); # The allowed file extensions for pm file attachments. Variable should be set in the form of "jpg bmp gif" and so on.
\$pmFileLimit = 250;                # Set to the maximum number of kilobytes a pm attachment can be. Set to 0 to disable the file size check.
\$pmDirLimit = 10000;               # Set to the maximum number of kilobytes the pm attachment directory can hold. Set to 0 to disable the directory size check.
\$pmFileOverwrite = 0;              # Set to 0 to auto rename pm attachments if they exist, 1 to overwrite them or 2 to generate an error if the file exists already.

########## Error Logger ##########

\$elmax  = "50";                                  # Max number of log entries before rotation
\$elenable = 1;                                   # allow for error logging
\$elrotate = 1;                                   # Allow for log rotation

########## Advanced Tabs ##########

\$addtab_on = $addtab_on;                         # show advanced tabs on Forum (For admin only.)
\@AdvancedTabs = qw(home help search ml admin revalidatesession login register guestpm mycenter logout eventcal birthdaylist ); # Advanced Tabs order and infos

########## Smilies ##########

\@SmilieURL = ("exclamation.png","question.png"); # Additional Smilies URL
\@SmilieCode = (":exclamation",":question");      # Additional Smilies Code
\@SmilieDescription = ("Exclaim","Questioning");  # Additional Smilies Description
\@SmilieLinebreak = ("","");                      # Additional Smilies Linebreak

\$smiliestyle = "2";                              # smiliestyle
\$showadded = "2";                                # showadded
\$showsmdir = "2";                                # showsmdir
\$detachblock = "1";                              # detachblock
\$winwidth = "400";                               # winwidth
\$winheight = "400";                              # winheight
\$popback = "FFFFFF";                             # popback
\$poptext = "000000";                             # poptext



###############################################################################
# Security Settings (old SecSettings.txt)                                     #
###############################################################################

\$regcheck = 0;                             # Set to 1 if you want to enable automatic flood protection enabled
\$codemaxchars = 6;                         # Set max length of validation code (15 is max)
\$rgb_foreground = "\#0000EE";              # Set hex RGB value for validation image foreground color
\$rgb_shade = "\#999999";                   # Set hex RGB value for validation image shade color
\$rgb_background = "\#FFFFFF";              # Set hex RGB value for validation image background color
\$translayer = 0;                           # Set to 1 background for validation image should be transparent
\$randomizer = 0;                           # Set 0 to 3 to create background random noise
                                            # based on foreground or shade color or both
\$stealthurl = 0;                           # Set to 1 to mask referer url to hosts if a hyperlink is clicked.
\$referersecurity = 0;                      # Set to 1 to activate referer security checking.
\$do_scramble_id = 1;                       # Set to 1 scambles all visible links containing user ID's
\$sessions = 1;                             # Set to 1 to activate session id protection.
\$show_online_ip_admin = 1;                 # Set to 1 to show online IP's to admins.
\$show_online_ip_gmod = 1;                  # Set to 1 to show online IP's to global moderators.
\$show_online_ip_fmod = 1;                  # Set to 1 to show online IP's to forum moderators.
\$masterkey = '$masterkey';                 # Seed for encryption of captcha's
\$ipLookup = 1;                             # Set to 1 to enable IP Lookup.


###############################################################################
# Guardian Settings (old Guardian.banned and Guardian.settings)               #
###############################################################################

\$banned_harvesters = qq~alexibot|asterias|backdoorbot|black.hole|blackwidow|blowfish|botalot|builtbottough|bullseye|bunnyslippers|cegbfeieh|cheesebot|cherrypicker|chinaclaw|copyrightcheck|cosmos |crescent|custo|disco|dittospyder|download demon|ecatch|eirgrabber|emailcollector|emailsiphon|emailwolf|erocrawler|eseek-larbin|express webpictures|extractorpro|eyenetie|fast|flashget|foobot|frontpage|fscrawler|getright|getweb|go!zilla|go-ahead-got-it|grabnet|grafula|gsa-crawler|harvest|hloader|hmview|httplib|httrack|humanlinks|ia_archiver|image stripper|image sucker|indy library|infonavirobot|interget|internet ninja|jennybot|jetcar|joc web spider|kenjin.spider|keyword.density|larbin|leechftp|lexibot|libweb/clshttp|linkextractorpro|linkscan/8.1a.unix|linkwalker|lwp-trivial|mass downloader|mata.hari|microsoft.url|midown tool|miixpc|mister pix|moget|mozilla.*newt|mozilla/3.mozilla/2.01|navroad|nearsite|net vampire|netants|netmechanic|netspider|netzip|nicerspro|npbot|octopus|offline explorer|offline navigator|openfind|pagegrabber|papa foto|pavuk|pcbrowser|propowerbot/2.14|prowebwalker|queryn.metasearch|realdownload|reget|repomonkey|sitesnagger|slysearch|smartdownload|spankbot|spanner |spiderzilla|steeler|superbot|superhttp|surfbot|suzuran|szukacz|takeout|teleport pro|telesoft|the.intraformant|thenomad|tighttwatbot|titan|tocrawl/urldispatcher|true_robot|turingos|turnitinbot|urly.warning|vci|voideye|web image collector|web sucker|web.image.collector|webauto|webbandit|webbandit|webcopier|webemailextrac.*|webenhancer|webfetch|webgo is|webleacher|webmasterworldforumbot|webreaper|websauger|website extractor|website quester|webster.pro|webstripper|webwhacker|webzip|wget|widow|www-collector-e|wwwoffle|xaldon webspider|xenu link sleuth|zeus~;
\$banned_referers = qq~hotsex.com|porn.com~;
\$banned_requests = qq~~;
\$banned_strings = qq~pussy|cunt~;
\$whitelist = qq~~;

\$use_guardian = 1;
\$use_htaccess = 0;

\$disallow_proxy_on = 0;
\$referer_on = 1;
\$harvester_on = 0;
\$request_on = 0;
\$string_on = 1;
\$union_on = 1;
\$clike_on = 1;
\$script_on = 1;

\$disallow_proxy_notify = 1;
\$referer_notify = 0;
\$harvester_notify = 1;
\$request_notify = 0;
\$string_notify = 1;
\$union_notify = 1;
\$clike_notify = 1;
\$script_notify = 1;

###############################################################################
# Banning Settings  Moved to banlist.txt New timed ban settings              #
###############################################################################
\@timeban = qw( d w m p );
\@bandays = ( 1, 7, 30,  365 );
###############################################################################
# Backup Settings                                                             #
###############################################################################

\@backup_paths = qw();
\$backupmethod = '';
\$compressmethod = '';
\$backupprogusr = '';
\$backupprogbin = '';
\$backupdir = '';
\$lastbackup = 0;
\$backupsettingsloaded = 0;

1;
EOF

    fopen( SETTING, ">$vardir/Settings.pm" )
      || setup_fatal_error( "$maintext_23 $vardir/Settings.pm: ", 1 );
    print {SETTING} nicely_aligned_file($setfile)
      or croak 'cannot print Settings.pm';
    fclose(SETTING);
    if ( $action eq 'setinstall2' ) {
        LoadUser('admin');
        ${ $uid . 'admin' }{'email'} = $webmaster_email;
        ${ $uid . 'admin' }{'regdate'}    = timetostring($date);
        ${ $uid . 'admin' }{'regtime'}    = $date;
        ${ $uid . 'admin' }{'timeselect'} = $timeselected;
        ${ $uid . 'admin' }{'language'}   = $lang;
        UserAccount( 'admin', 'update' );
        ManageMemberinfo( 'update', 'admin', 'Administrator', $webmaster_email,'Forum Administrator' );
        $yySetLocation = qq~$set_cgi?action=setup3~;
        redirectexit();
    }
    return;
}

sub tempstarter {
    return if !-e "$vardir/Settings.pm";

    $YaBBversion = 'YaBB 2.6.11';

    # Make sure the module path is present
    push @INC, './Modules';

    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
        $yyIIS = 1;
        $PROGRAM_NAME =~ m{(.*)(\\|/)}sm;
        $yypath = $1;
        $yypath =~ s/\\/\//gxsm;
        chdir $yypath;
        push @INC, $yypath;
    }

    # Requirements and Errors
    require Variables::Settings;
    LoadCookie();    # Load the user's cookie (or set to guest)
    LoadUserSettings();
    WhatTemplate();
    WhatLanguage();
    require Sources::Security;
    WriteLog();
    return;
}

sub CheckInstall {
    tempstarter();
    my $install_error;
    my $firstmstime = time();
    $windowbg = '#fafafa';
    $header   = '#5488ba';
    $catbg    = '#ddd';

    $set_missing = q{};
    $set_created = q{};
    if   ( !-e "$vardir/Settings.pm" ) { $set_missing = q~Settings.pm~; }
    else                               { $set_created = q~Settings.pm~; }

    $brd_missing = q{};
    $brd_created = q{};
    if ( !-e "$boardsdir/forum.control" ) {
        $brd_missing .= q~forum.control, ~;
    }
    else { $brd_created .= q~forum.control, ~; }
    if ( !-e "$boardsdir/forum.master" ) { $brd_missing .= q~forum.master, ~; }
    else                                 { $brd_created .= q~forum.master, ~; }
    if ( !-e "$boardsdir/forum.totals" ) { $brd_missing .= q~forum.totals, ~; }
    else {
        $brd_created .= q~forum.totals, ~;
        fopen( FORUMTOT, "$boardsdir/forum.totals" )
          || setup_fatal_error( "$maintext_23 $boardsdir/forum.totals: ", 1 );
        @totboards = <FORUMTOT>;
        fclose(FORUMTOT);
    }
    foreach my $boardstot (@totboards) {
        chomp $boardstot;
        ( $brdname, undef, undef, undef, undef, $msgname, undef ) =
          split /\|/xsm, $boardstot, 7;
        if ( !-e "$boardsdir/$brdname.txt" ) {
            $brd_missing .= qq~$brdname.txt, ~;
        }
        else { $brd_created .= qq~$brdname.txt, ~; }

    }
    $brd_missing =~ s/, $//sm;
    $brd_created =~ s/, $//sm;
    fopen( FORUMTOTALS, ">$boardsdir/forum.totals" ) || setup_fatal_error( "$maintext_23 $boardsdir/forum.totals: ", 1 );
    for my $boardstot (@totboards) {
        chomp $boardstot;
        ( $brdname, undef, undef, undef, undef, $msgname, undef ) =
          split /\|/xsm, $boardstot;
        if ( $brdname eq 'general') {
            print {FORUMTOTALS} "general|1|1|$firstmstime|admin|$firstmstime|0|Welcome to your new YaBB 2.6.11 forum!|xx|0|\n" or croak 'cannot print FORUMTOTALS';
        }
        else { print {FORUMTOTALS} qq~$boardstot\n~; }
    }
    fclose(FORUMTOTALS);
    fopen ( FIRSTMS, ">$datadir/$firstmstime.txt");
    print {FIRSTMS} qq~Welcome to your New YaBB 2.6.11 Forum!|Administrator|webmaster@mysite.com|$firstmstime|admin|xx|0|127.0.0.1|Welcome to your new YaBB 2.6.11 forum.<br /><br />The YaBB team would like to thank you for choosing Yet another Bulletin Board for your forum needs. We pride ourselves on the cost (FREE), the features, and the security. Visit http://www.yabbforum.com to view the latest development information, read YaBB news, and participate in community discussions.<br /><br />Make sure you login to your new forum as an administrator and visit the Admin Center. From there, you can maintain your forum. You'll want to look at all of the settings, membergroups, categories/boards, and security options to make sure they are set properly according to your needs.||||\n~; 
    fclose(FIRSTMS);
    require Sources::DateTime;
    fopen (FIRSTMSC, ">$datadir/$firstmstime.ctb");
    $msgdat = timeformat( $firstmstime, 1, 'rfc' );
    print {FIRSTMSC} qq~### ThreadID: $firstmstime, LastModified: $msgdat  ###

'board',"general"
'replies',"0"
'views',"1"
'lastposter',"admin"
'lastpostdate',"$firstmstime"
'threadstatus',"0"
'repliers',"$firstmstime|admin|0"~;
    fclose (FIRSTMSC);
    fopen ( FIRSTBRD, ">>$boardsdir/general.txt");
    print {FIRSTBRD} qq~$firstmstime|Welcome to your New YaBB 2.6 Forum!|Administrator|$webmaster_email|$firstmstime|0|admin|xx|0\n~;
    fclose (FIRSTBRD);

    $mem_missing = q{};
    $mem_created = q{};
    if ( !-e "$memberdir/admin.outbox" ) { $mem_missing .= q~admin.outbox, ~; }
    else                                 { $mem_created .= q~admin.outbox, ~; }
    if   ( !-e "$memberdir/admin.vars" ) { $mem_missing .= q~admin.vars, ~; }
    else                                 { $mem_created .= q~admin.vars, ~; }
    if ( !-e "$memberdir/memberlist.txt" ) {
        $mem_missing .= q~memberlist.txt, ~;
    }
    else { $mem_created .= q~memberlist.txt, ~; }
    if ( !-e "$memberdir/memberinfo.txt" ) {
        $mem_missing .= q~memberinfo.txt, ~;
    }
    else { $mem_created .= q~memberinfo.txt, ~; }
    if   ( !-e "$memberdir/members.ttl" ) { $mem_missing .= q~members.ttl~; }
    else                                  { $mem_created .= q~members.ttl~; }
    $mem_missing =~ s/, $//sm;
    $mem_created =~ s/, $//sm;

    $msg_missing = q{};
    $msg_created = q{};

    if ( -e "$boardsdir/forum.totals" ) {
        fopen( FORUMTOT, "$boardsdir/forum.totals" )
          || setup_fatal_error( "$maintext_23 $boardsdir/forum.totals: ", 1 );
        @totboards = <FORUMTOT>;
        fclose(FORUMTOT);
    }
    foreach my $boardstot (@totboards) {
        chomp $boardstot;
        ( $brdname, undef, undef, undef, undef, $msgname, undef ) =
          split /\|/xsm, $boardstot, 7;
        next if !$msgname;
        if ( !-e "$datadir/$msgname.ctb" ) {
            $msg_missing .= qq~$msgname.ctb, ~;
        }
        else { $msg_created .= qq~$msgname.ctb, ~; }
        if ( !-e "$datadir/$msgname.txt" ) {
            $msg_missing .= qq~$msgname.txt, ~;
        }
        else { $msg_created .= qq~$msgname.txt~; }
    }
    $msg_missing =~ s/, $//sm;
    $msg_created =~ s/, $//sm;

    $var_missing = q{};
    $var_created = q{};
    if   ( !-e "$vardir/adminlog.txt" ) { $var_missing .= q~adminlog.txt, ~; }
    else                                { $var_created .= q~adminlog.txt, ~; }
    if   ( !-e "$vardir/allowed.txt" ) { $var_missing .= q~allowed.txt, ~; }
    else                               { $var_created .= q~allowed.txt, ~; }
    if   ( !-e "$vardir/attachments.txt" ) { $var_missing .= q~attachments.txt, ~; }
    else                                   { $var_created .= q~attachments.txt, ~; }
    if   ( !-e "$vardir/pm.attachments" ) { $var_missing .= q~pm.attachments, ~; }
    else                                  { $var_created .= q~attachments.txt, ~; }
    if   ( !-e "$vardir/ban_log.txt" ) { $var_missing .= q~ban_log.txt, ~; }
    else                               { $var_created .= q~ban_log.txt, ~; }
    if   ( !-e "$vardir/banlist.txt" ) { $var_missing .= q~banlist.txt, ~; }
    else                               { $var_created .= q~banlist.txt, ~; }
    if   ( !-e "$vardir/clicklog.txt" ) { $var_missing .= q~clicklog.txt, ~; }
    else                                { $var_created .= q~clicklog.txt, ~; }
    if   ( !-e "$vardir/errorlog.txt" ) { $var_missing .= q~errorlog.txt, ~; }
    else                                { $var_created .= q~errorlog.txt, ~; }
    if   ( !-e "$vardir/flood.txt" ) { $var_missing .= q~flood.txt, ~; }
    else                             { $var_created .= q~flood.txt, ~; }

    if ( !-e "$vardir/gmodsettings.txt" ) {
        $var_missing .= q~gmodsettings.txt, ~;
    }
    else { $var_created .= q~gmodsettings.txt, ~; }
    if   ( !-e "$vardir/log.txt" ) { $var_missing .= q~log.txt, ~; }
    else                           { $var_created .= q~log.txt, ~; }
    if   ( !-e "$vardir/modlist.txt" ) { $var_missing .= q~modlist.txt, ~; }
    else                               { $var_created .= q~modlist.txt, ~; }
    if   ( !-e "$vardir/news.txt" ) { $var_missing .= q~news.txt, ~; }
    else                            { $var_created .= q~news.txt, ~; }
    if   ( !-e "$vardir/oldestmes.txt" ) { $var_missing .= q~oldestmes.txt, ~; }
    else                                 { $var_created .= q~oldestmes.txt, ~; }

    if ( !-e "$vardir/registration.log" ) {
        $var_missing .= q~registration.log, ~;
    }
    else { $var_created .= q~registration.log, ~; }
    if   ( !-e "$vardir/reserve.txt" ) { $var_missing .= q~reserve.txt, ~; }
    else                               { $var_created .= q~reserve.txt, ~; }
    if ( !-e "$vardir/reservecfg.txt" ) {
        $var_missing .= q~reservecfg.txt, ~;
    }
    else { $var_created .= q~reservecfg.txt, ~; }
    $var_missing =~ s/, $//sm;
    $var_created =~ s/, $//sm;

    $yymain .= q~
    <table class="tabtitle">
        <tr>
             <td class="shadow" style="padding-left:1%">Checking System Files</td>
        </tr>
    </table>
<div class="boardcontainer">
    <table class="border-space pad-cell">
        <col style="width:6%" />
        <col style="width:94%" />
        <tr>
            <td class="catbg" colspan="2">
      ~;
    if ($no_brddir) {
        $install_error = 1;
        $yymain .= qq~
      A problem has occurred in the /Boards folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">No /Boards folder available!</td>
        </tr>~;
    }
    else {
        if ($brd_missing) {
            $install_error = 1;
            $yymain .= qq~
      A problem has occurred in the /Boards folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
                <b>Missing: </b>
                <br />$brd_missing
            </td>
        </tr>~;
        }
        if ($brd_created) {
            if ( !$brd_missing ) {
                $yymain .= q~
      Successfully checked the /Boards folder!
            </td>
        </tr>~;
            }
            $yymain .= qq~<tr>
            <td class="windowbg center">
      <img src="$imagesdir/check.png" alt="" />
            </td>
            <td class="windowbg2">
                <b>Installed: </b>
                <br />$brd_created
            </td>
        </tr>~;
        }
    }
    $yymain .= q~<tr>
            <td class="catbg" colspan="2">
      ~;

    if ($no_memdir) {
        $install_error = 1;
        $yymain .= qq~
      A Problem has occurred in the /Members folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
      No /Members folder available!
            </td>
        </tr>~;
    }
    else {
        if ($mem_missing) {
            $install_error = 1;
            $yymain .= qq~
      A problem has occurred in the /Members folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
                <b>Missing: </b>
                <br />$mem_missing
            </td>
        </tr>~;
        }
        if ($mem_created) {
            if ( !$mem_missing ) {
                $yymain .= q~
      Successfully checked the /Members folder!
            </td>
        </tr>~;
            }
            $yymain .= qq~<tr>
            <td class="windowbg center"><img src="$imagesdir/check.png" alt="" /></td>
            <td class="windowbg2">
                <b>Installed: </b>
                <br />$mem_created
            </td>
        </tr>~;
        }
    }
    $yymain .= q~<tr>
            <td class="catbg" colspan="2">~;

    if ($no_mesdir) {
        $install_error = 1;
        $yymain .= qq~
      A problem has occurred in the /Messages folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
      No /Messages folder available!
            </td>
        </tr>~;
    }
    else {
        if ($msg_missing) {
            $install_error = 1;
            $yymain .= qq~
      A problem has occurred in the /Messages folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
                <b>Missing: </b>
                <br />$msg_missing
            </td>
        </tr>~;
        }
        if ($msg_created) {
            if ( !$msg_missing ) {
                $yymain .= q~
      Successfully checked the /Messages folder!
            </td>
        </tr>~;
            }
            $yymain .= qq~<tr>
            <td class="windowbg center"><img src="$imagesdir/check.png" alt="" /></td>
            <td class="windowbg2">
                <b>Installed: </b>
                <br />$msg_created
            </td>
        </tr>~;
        }
    }
    $yymain .= q~<tr>
            <td class="catbg" colspan="2">
      ~;
    if ($no_vardir) {
        $install_error = 1;
        $yymain .= qq~
      A problem has occurred in the /Variables folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
      No /Variables folder available!
           </td>
        </tr>~;
    }
    else {
        if ($var_missing) {
            $install_error = 1;
            $yymain .= qq~
      A problem has occurred in the /Variables folder!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/cross.png" alt="" /></td>
            <td class="windowbg2">
                <b>Missing: </b>
                <br />$var_missing
            </td>
        </tr>~;
        }
        if ($var_created) {
            if ( !$var_missing ) {
                $yymain .= q~
      Successfully checked the /Variables folder!
            </td>
        </tr>~;
            }
            $yymain .= qq~<tr>
            <td class="windowbg center"><img src="$imagesdir/check.png" alt="" /></td>
            <td class="windowbg2">
                <b>Installed: </b>
                <br />$var_created
            </td>
        </tr>~;
        }
    }

    $yymain .= q~<tr>
            <td class="catbg" colspan="2">
                ~;

    if ($set_missing) {
        $install_error = 1;
        $yymain .= q~A problem has occurred while creating Settings.pm!
            </td>
        </tr>~;
    }
    if ($set_created) {
        $yymain .= qq~Successfully checked Settings.pm!
            </td>
        </tr><tr>
            <td class="windowbg center"><img src="$imagesdir/check.png" alt="" /></td>
            <td class="windowbg2">
      Click on 'Continue' and go to your <i>Admin Center - Forum Settings</i> to set the options for your YaBB 2.6.11 forum.<br />Or to convert a 1x or 2x Forum to 2.6.11
            </td>
        </tr>~;
    }

    if ( !$install_error ) {

        $yymain .= qq~<tr>
            <td class="catbg center" colspan="2">
      <form action="$set_cgi?action=ready;nextstep=YaBB" method="post" style="display: inline;">
            <input type="submit" value="Continue" />
      </form>
            <p class="center">You can access the 1x and 2x Conversion Utilities through the Admin Center</p>
            </td>
        </tr>~;
    }
    else {
        $yymain .= q~<tr>
            <td class="titlebg" colspan="2">
                <div class="div98"><b>One or more errors occurred while checking the system files. The problems must be solved before you may continue.</b></div>
            </td>
        </tr>~;
    }
    $yymain .= q~
      </table>
</div>
      ~;
    $yyim    = 'You are running YaBB 2.6.11 Setup.';
    $yytitle = 'YaBB 2.6.11 Setup';
    SetupTemplate();
    return;
}

sub ready {
    if ( -e "$INFO{'nextstep'}.$yyext" ) {
        UpdateCookie('delete');
        $yySetLocation = qq~$INFO{'nextstep'}.$yyext?action=revalidatesession~;
    }

    CreateSetupLock();
    unlink "$vardir/cook.txt";
    redirectexit();
    return;
}

sub CreateSetupLock {
    fopen( 'LOCKFILE', ">$vardir/Setup.lock" )
      || setup_fatal_error( "$maintext_23 $vardir/Setup.lock: ", 1 );
    print {LOCKFILE} qq~This is a lockfile for the Setup Utility.\n~
      or croak 'cannot print to Setup.lock';
    print {LOCKFILE}
      qq~It prevents it being run again after it has been run once.\n~
      or croak 'cannot print to Setup.lock';
    print {LOCKFILE}
      q~Delete this file if you want to run the Setup Utility again.~
      or croak 'cannot print to Setup.lock';
    fclose('LOCKFILE');
    return;
}

sub SetupImgLoc {
    if ( !-e "$htmldir/Templates/Forum/$useimages/$_[0]" ) {
        $thisimgloc = qq~img src="$yyhtml_root/Templates/Forum/default/$_[0]"~;
    }
    else { $thisimgloc = qq~img src="$imagesdir/$_[0]"~; }
    return $thisimgloc;
}

sub setup_fatal_error {
      my $e = $_[0];
      my $v = $_[1];
      $e .= "\n";
      if ($v) { $e .= $! . "\n"; }

      $yymenu = qq~Boards & Categories | ~;
      $yymenu .= qq~Members | ~;
      $yymenu .= qq~Messages | ~;
      $yymenu .= qq~Date & Time | ~;
      $yymenu .= qq~Clean Up | ~;
      $yymenu .= qq~Login~;

      $yymain .= qq~
<table class="bordercolor center border-space pad-cell" width="80%" >
    <tr>
        <td class="titlebg text1"><b>An Error Has Occurred!</b></td>
  </tr><tr>
        <td class="windowbg text1" style="padding:1em 1em 2em 1em">$e</td>
    </tr>
</table>
<p style="text-align:center"><a href="javascript:history.go(-1)">Back</a></p>
~;
      $yyim    = "YaBB 2.6.11 Setup Error.";
      $yytitle = "YaBB 2.6.11 Setup Error.";

      if (!-e "$vardir/Settings.pm") { SimpleOutput(); }

      tempstarter();
      SetupTemplate();
}

sub SimpleOutput {
    $gzcomp = 0;
    print_output_header();

    print qq~
<!DOCTYPE html>
<html lang='en-US'>
<head>
    <meta charset="utf-8">
    <title>YaBB 2.6.11 Setup</title>
    <style type="text/css">
        html, body {color:#000; font-family:Verdana, Helvetica, Arial, Sans-Serif; font-size:13px; background-color:#eee}
        div#folderfind { margin:1em auto; padding:0 1em}
        #folderfind table {width:100%; background-color:#DDE3EB; margin:0 auto; border-collapse:collapse;}
        #folderfind td {text-align:left; padding:3px; border:thin #000 solid;}
        #folderfind .txt_a {font-size:11px;}
        #folderfind .windowbg {background-color: $windowbg;}
        #folderfind .windowbg2 {background-color: $windowbg2;}
        #folderfind .header {background-color:$header;}
        #folderfind .catbg {background-color:$catbg; text-align:center; color:#fff; }
    </style>
</head>
<body>
<!-- Main Content -->
$yymain
</body>
</html>
    ~ or croak 'cannot print page to screen';
    exit;
}

sub SetupTemplate {
    $gzcomp = fileno GZIP ? 1 : 0;
    print_output_header();

    $yyposition = $yytitle;
    $yytitle    = "$mbname - $yytitle";

    $yyimages        = $imagesdir;
    $yydefaultimages = $defaultimagesdir;
    $yystyle =
qq~<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />\n<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/setup.css" type="text/css" />\n~;
    $yystyle =~ s/$usestyle\///gxsm;

    $yytemplate = "$templatesdir/$usehead/$usehead.html";
    fopen( TEMPLATE, "$yytemplate" )
      || setup_fatal_error( "$maintext_23 $yytemplate: ", 1 );
    @yytemplate = <TEMPLATE>;
    fclose(TEMPLATE);

    my $output = q{};
    $yyboardname = $mbname;
    $yytime = timeformat( $date, 1 );
    $yyuname =
      $iamguest ? q{} : qq~$maintxt{'247'} ${$uid.$username}{'realname'}, ~;

    if ($enable_news) {
        fopen( NEWS, "$vardir/news.txt" );
        @newsmessages = <NEWS>;
        fclose(NEWS);
    }
    for my $i ( 0 .. ( @yytemplate - 1 ) ) {
        $curline = $yytemplate[$i];
        if ( !$yycopyin && $curline =~ m/{yabb copyright}/sm )
        {
            $yycopyin = 1;
        }
        if ( $curline =~ m/{yabb newstitle}/sm && $enable_news ) {
            $yynewstitle = qq~<b>$maintxt{'102'}:</b> ~;
        }
        if ( $curline =~ m/{yabb news}/sm && $enable_news ) {
            srand;
            if ( $shownewsfader == 1 ) {

                $fadedelay = ( $maxsteps * $stepdelay );
                $yynews .= qq~
                        <script type="text/javascript">
                                    var maxsteps = "$maxsteps";
                                    var stepdelay = "$stepdelay";
                                    var fadelinks = $fadelinks;
                                    var delay = "$fadedelay";
                                    var bcolor = "$color{'faderbg'}";
                                    var tcolor = "$color{'fadertext'}";
                                    var fcontent = new Array();
                                    var begintag = "";
                        ~;
                fopen( NEWS, "$vardir/news.txt" );
                @newsmessages = <NEWS>;
                fclose(NEWS);
                for my $j ( 0 .. ( @newsmessages - 1 ) ) {
                    $newsmessages[$j] =~ s/\n|\r//gsm;
                    if ( $newsmessages[$j] eq q{} ) { next; }
                    if ( $i != 0 ) { $yymain .= qq~\n~; }
                    $message = $newsmessages[$j];
                    if ($enable_ubbc) {
                        enable_yabbc();
                        DoUBBC();
                        }
                    $message =~ s/"/\\"/gsm;
                    $yynews .= qq~
                                    fcontent[$j] = "$message";\n
                              ~;
                }
                $yynews .= q~
                                    var closetag = '';
                        </script>
                        ~;
            }
            else {
                $message = $newsmessages[ int rand @newsmessages ];
                if ($enable_ubbc) {
                    enable_yabbc();
                    DoUBBC();
                }
                $message =~ s/\'/&#39;/xsm;
                $yynews = qq~
            <script type="text/javascript">
                if (ie4 || DOM2) var news = '$message';
                var div = document.getElementById("newsdiv");
                div.innerHTML = news;
            </script>~;
           }
        }
        $yyurl = $scripturl;
        $curline =~ s/{yabb\s+(\w+)}/${"yy$1"}/gxsm;
        $curline =~ s/<yabb\s+(\w+)>/${"yy$1"}/gxsm;
        $curline =~ s/img src\=\"$imagesdir\/(.+?)\"/SetupImgLoc($1)/eigxsm;
        $output .= $curline;
    }
    if ( $yycopyin == 0 ) {
        $output =
q~<h1 style="text-align:center"><b>Sorry, the copyright tag &#123;yabb copyright&#125; must be in the template.<br />Please notify this forum&#39;s administrator that this site is using an ILLEGAL copy of YaBB!</b></h1>~;
    }
    if ( fileno GZIP ) {
        $OUTPUT_AUTOFLUSH = 1;
        print {GZIP} $output or croak 'cannot print gzip';
        close GZIP or croak 'cannot close GZIP';
    }
    else {
        print $output or croak 'cannot print output';
    }
    exit;
}

sub nicely_aligned_file {
    $filler = q{ } x 50;

    # Make files look nicely aligned. The comment starts after 50 Col

    my $setfile = shift;
    $setfile =~ s/=\s+;/= 0;/gsm;
    $setfile =~
s/(.+;)[ \t]+(#.+$)/ $1 . substr($filler,(length $1 < 50 ? length $1 : 49)) . $2 /gem;
    $setfile =~ s/\t+(#.+$)/$filler$1/gsm;


    *cut_comment = sub {    # line break of too long comments
        my @x = @_;
        my ( $comment, $length ) =
          ( q{}, 120 );    # 120 Col is the max width of page
        my $var_length = length $x[0];
        while ( $length < $var_length ) { $length += 120; }
        foreach ( split / +/sm, $x[1] ) {
            if ( ( $var_length + length($comment) + length $_ ) > $length ) {
                $comment =~ s/ $//sm;
                $comment .= "\n$filler#  $_ ";
                $length += 120;
            }
            else { $comment .= "$_ "; }
        }
        $comment =~ s/ $//sm;
        return $comment;
    };
    $setfile =~ s/(.+)(#.+$)/ $1 . cut_comment($1,$2) /gem;
    return $setfile;
}

sub FoundSetupLock {
    tempstarter();
    $scripturl = "$boardurl/YaBB.$yyext";
    require Sources::TabMenu;

    #    $formsession = cloak("$mbname$username");
    if ( -e "$vardir/Converter.lock" ) {
        $conv = q{};
        $conv2 =
qq~The 1x to 2.6.11 Converter has already been run.<br />To run the Converter again, remove the file "$vardir/Converter.lock," then re-visit this page.~;

    }
    else {
        $conv =
          qq~&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <form action="Convert.$yyext" method="post" style="display: inline;">
                    <input type="submit" value="Convert 1x files" />
                </form>~;
    }
    if ( -e "$vardir/FixFile.lock" ) {
        $fixa = q{};
        $fixa2 =
qq~The 2x Conversion Utility has already been run.<br />To run Utility again, remove the file "$vardir/Convert2x.lock," then re-visit this page.~;

    }
    else {
        $fixa =
          qq~&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                <form action="Convert2x.$yyext" method="post" style="display: inline;">
                    <input type="submit" value="Convert 2x files" />
                </form>~;
}

    $yymain = qq~
<div class="bordercolor borderbox">
    <table class="tabtitle">
        <tr>
            <td style="padding-left:1%; text-shadow: 1px 1px 1px #2d2d2d;">
                YaBB 2.6.11 Setup
            </td>
        </tr>
    </table>
    <table>
        <col style="width:5%" />
        <col style="width:95%" />
        <tr>
            <td class="windowbg2 center" style="padding: 4px">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 center" style="padding: 4px">
                Setup has already been run.
                <br />
                To run Setup again, remove the file "$vardir/Setup.lock" then re-visit this page.<br />
                $conv2
                $fixa2
            </td>
        </tr><tr>
            <td class="catbg center"  style="padding: 4px" colspan="2">
                <form action="$boardurl/YaBB.$yyext" method="post" style="display: inline;">
                    <input type="submit" value="Go to your Forum" />
<!--                  <input type="hidden" name="formsession" value="$formsession" />-->
                </form>
                $conv
                $fixa
            </td>
        </tr>
    </table>
</div>
      ~;

    $yyim    = 'YaBB 2.6.11 Setup has already been run.';
    $yytitle = 'YaBB 2.6.11 Setup';
    template();
    return;
}
1;