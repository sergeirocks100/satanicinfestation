#!/usr/bin/perl --

###############################################################################
# BoardConvert.pl                                                             #
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

$boardconvertplver = 'YaBB 2.6.11 $Revision: 1611 $';

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
$script_root =~ s/\/BoardConvert\.(pl|cgi)//igxsm;

if   ( -e 'YaBB.cgi' ) { $yyext = 'cgi'; }
else                   { $yyext = 'pl'; }
if   ($boardurl) { $set_cgi = "$boardurl/BoardConvert.$yyext"; }
else             { $set_cgi = "BoardConvert.$yyext"; }

require "Paths.pl";
require "$sourcedir/Subs.pl";
require "$sourcedir/Load.pl";

if ( !$action ) {
    adminlogin();
}

if    ( $action eq 'adminlogin2' ) { adminlogin2(); }
elsif ( $action eq 'convbrd') {    convcontrol(); }

sub convcontrol {

open(FORUMCONTROL, '<', "$boardsdir/forum.control") or croak 'cannot_open forum.control';
my @boardcontrols = <FORUMCONTROL>;
close(FORUMCONTROL);

foreach my $boardline (@boardcontrols) {
	$boardline =~ s/[\r\n]//g; # Built in chomp
        (undef, $cntboard ) = split /\|/xsm, $boardline;
	## create a global boards array
	push(@allboards, $cntboard);
}

LoadBoardControl();

open (BOARDCONV, '>',"$vardir/boardconv.txt");
foreach my $cntboard (@allboards) {
    print {BOARDCONV} qq~\%$cntboard = (\n~;
    foreach (keys %{ $uid . $cntboard } ) {
        print {BOARDCONV} "'$_' => '${ $uid . $cntboard }{$_}',\n";
    } 
        print {BOARDCONV} qq~);\n~;
}
close(BOARDCONV);

    $yymain .= qq~
    <div style="width:50em; border: thin #000 solid; margin:2em auto; padding:1em; text-align:center; background-color:#fff">
        Export of '$boardsdir/forum.control' settings to '$vardir/boardconv.txt' done.
    </div>
~;

    return SimpleOutput();
}


sub SimpleOutput {
    $gzcomp = 0;
    print_output_header();

    print qq~
<!DOCTYPE html>
<html lang='en-US'>
<head>
    <meta charset="utf-8">
    <title>YaBB 2.6.11 Forum Control Exporter Utility</title>
    <style type="text/css">
        html, body {color:#000; font-family:Verdana, Helvetica, Arial, Sans-Serif; font-size:13px; background-color:#eee}
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

sub adminlogin {
    $yymain .= qq~
    <form action="$set_cgi?action=adminlogin2" method="post" name="loginform">
    <div style="width:25em; border: thin #000 solid; margin:2em auto; padding:1em; text-align:center; background-color:#fff">
        <label for="password">Enter the password for user <b>admin</b> to gain access to the Forum Control Exporter Utility</label>
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

    $yymain .= qq~
    <form action="$set_cgi?action=convbrd" method="post">
    <div style="width:50em; border: thin #000 solid; margin:2em auto; padding:1em; text-align:center; background-color:#fff">
        You are now logged in, <i>${$uid.$username}{'realname'}</i>!<br />Click 'Run Exporter' to run the Forum Control Exporter Utility.
        <p><input type="submit" value="Run Exporter" /></p>
    </div>
    </form>
~;

    return SimpleOutput();
}

1;