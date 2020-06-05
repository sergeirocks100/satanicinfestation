#!/usr/bin/perl --
# $Id: YaBB Main$
# $HeadURL: YaBB $
# $Revision: 1611 $
# $Source: /YaBB.pl $
###############################################################################
# YaBB.pl                                                                     #
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
#use strict;
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

### Version Info ###
$YaBBversion = 'YaBB 2.6.11';
$yabbplver   = 'YaBB 2.6.11 $Revision: 1611 $';

if ( $action eq 'detailedversion' ) { return 1; }

BEGIN {

    # Make sure the module path is present
    push @INC, './Modules';

    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
        $yyIIS = 1;
        if ( $PROGRAM_NAME =~ m{(.*)(\\|/)}xsm ) {
            $yypath = $1;
        }
        $yypath =~ s/\\/\//gxsm;
        chdir $yypath;
        push @INC, $yypath;
    }

    $yyexec      = 'YaBB';
    $script_root = $ENV{'SCRIPT_FILENAME'};
    if ( !$script_root ) {
        $script_root = $ENV{'PATH_TRANSLATED'};
    }
    $script_root =~ s/\/$yyexec\.(pl|cgi)//igxsm;

    require Paths;
    require Variables::Settings;

    # Check for Time::HiRes if debugmodus is on
    if ($debug) {
        eval { require Time::HiRes; import Time::HiRes qw(time); };
    }
    $START_TIME = time;

    require './Sources/Subs.pm';
    require Sources::System;
    require Sources::DateTime;
    require Sources::Load;

    require Sources::Guardian;
    get_forum_master();
}    # END of BEGIN block

# If enabled: check if hard drive has enough space to safely operate the board
if ($checkspace) {
    require Sources::Freespace;
    $hostchecked = freespace();
}

# Auto Maintenance Hook
if ( !$maintenance && -e "$vardir/maintenance.lock" ) { $maintenance = 2; }

LoadCookie();          # Load the user's cookie (or set to guest)
LoadUserSettings();    # Load user settings
WhatTemplate();        # Figure out which template to be using.
WhatLanguage();        # Figure out which language file we should be using! :D

# Do this now that language is available
$yyfreespace =
    $hostchecked < 0
  ? $error_txt{'module_missing'}
  : (
    (
        $yyfreespace && ( ( $debug == 1 && !$iamguest )
            || ( $debug == 2 && $iamgmod )
            || $iamadmin )
    )
    ? q~<div>~
      . (
        $hostchecked > 0 ? $maintxt{'freeuserspace'} : $maintxt{'freediskspace'}
      )
      . qq~ $yyfreespace</div>~
    : q{}
  );

if ( -e "$vardir/gmodsettings.txt" && $iamgmod ) {
    require "$vardir/gmodsettings.txt";
}
if ( !$masterkey ) {
    if (
        $iamadmin
        || (   $iamgmod
            && $allow_gmod_admin eq 'on'
            && $gmod_access{'newsettings;page=security'} eq 'on' )
      )
    {
        $yyadmin_alert = $reg_txt{'no_masterkey'};
    }
    $masterkey = $mbname;
}

$formsession = cloak("$mbname$username");

# check for valid form sessionid in any POST request
if ( $ENV{REQUEST_METHOD} =~ /post/ism ) {
    if ( $CGI_query && $CGI_query->cgi_error() ) {
        fatal_error( 'denial_of_service', $CGI_query->cgi_error() );
    }
    if ( decloak( $FORM{'formsession'} ) ne "$mbname$username" ) {
        if ( $action eq 'login2' && $username ne 'Guest' ) {
            fatal_error( 'logged_in_already', $username );
        }
        fatal_error( 'form_spoofing', $user_ip );
    }
}

if ( $is_perm && $accept_permalink ) {
    if ( $permtopicfound == 0 ) {
        fatal_error( 'no_topic_found',
            "$permtitle|C:$permachecktime|T:$threadpermatime" );
    }
    if ( $permboardfound == 0 ) {
        fatal_error( 'no_board_found',
            "$permboard|C:$permachecktime|T:$threadpermatime" );
    }
}

guard();

# Check if the action is allowed from an external domain
if ($referersecurity) { referer_check(); }

if ( $regtype == 1 || $regtype == 2 ) {
    $inactive = -s "$memberdir/memberlist.inactive";
    $approve = -s "$memberdir/memberlist.approve";
    if ( $inactive > 2 ) {
        RegApprovalCheck();
        activation_check();
    }
    elsif ( $approve > 2 ) {
        RegApprovalCheck();
    }
}

require Sources::Security;

banning();     # Check for banned people
LoadIMs();     # Load IM's
WriteLog();    # write into the logfile
SearchAccess();

local $SIG{__WARN__} = sub { fatal_error( 'error_occurred', "@_" ); };
eval { yymain(); };
if ($@) { fatal_error( 'untrapped', ":<br />$@" ); }

sub yymain {

    # Choose what to do based on the form action
    if ($maintenance) {

        #admin login issues with sessions and maintenance mode fix.
        if ( $staff && $sessionvalid == 0 ) {
            UpdateCookie('delete');
            require Sources::LogInOut;
            InMaintenance();
        }
        if ( $action eq 'login2' ) {
            require Sources::LogInOut;
            Login2();
        }
        if ( !$iamadmin ) { require Sources::LogInOut; InMaintenance(); }
    }

    # Guest can do the very few following actions
    if (   $iamguest
        && !$guestaccess
        && $action !~
/^(login|register|reminder|validate|activate|resetpass|guestpm|checkavail|$randaction)2?$/xsm
      )
    {
        KickGuest();
    }

    if ( $action ne q{} ) {
        if ( $action eq $randaction ) {
            require Sources::Decoder;
            convert();
        }
        else {
            require Sources::SubList;
            if ( $director{$action} ) {
                my @act = split /&/xsm, $director{$action};
                require "$sourcedir/$act[0]";
                &{ $act[1] };
            }
            else {
                require Sources::BoardIndex;
                BoardIndex();
            }
        }
    }
    elsif ( $INFO{'num'} ne q{} ) {
        require Sources::Display;
        Display();
    }
    elsif ( $currentboard eq q{} ) {
        require Sources::BoardIndex;
        BoardIndex();
    }
    else {
        require Sources::MessageIndex;
        MessageIndex();
    }
    return;
}

1;
