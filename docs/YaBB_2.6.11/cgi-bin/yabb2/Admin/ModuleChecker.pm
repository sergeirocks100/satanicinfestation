###############################################################################
# ModuleChecker.pm                                                            #
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
use strict;
#use warnings;
use CGI::Carp qw(fatalsToBrowser);
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

our $modulecheckerpmver = 'YaBB 2.6.11 $Revision: 1611 $';
our ( $action, $yymain, %modulecheck );
if ( $action eq 'detailedversion' ) { return 1; }

my $script_root = $ENV{'SCRIPT_FILENAME'};
if ( !$script_root ) {
    $script_root = $ENV{'PATH_TRANSLATED'};
}

my ( $checker_output, $i );

my @modules = qw(Digest::MD5 Time::HiRes Time::Local DateTime DateTime::TimeZone File::Find CGI Net::SMTP Net::SMTP::TLS Net::DNS Mail::CheckUser Compress::Zlib Compress::Bzip2 Archive::Tar Archive::Zip MIME::Lite LWP::UserAgent HTTP::Request::Common Crypt::SSLeay IO::Socket::INET Digest::HMAC_MD5 Carp bytes integer English URI::Escape);

foreach my $module ( @modules ) {
    eval "require $module;";
    my $dont_continue_setup = q{};

    if ($EVAL_ERROR) {
        if ( $module eq 'Digest::MD5' ) { $dont_continue_setup = 1; }
        $i = $modulecheck{'8'};
        my $e = $EVAL_ERROR;

        # IE does display the @INC path it in one line  :-(
        # If you use IE and don't like what you see, remove the
        # comment (#) in next line.
        # $e =~ s/\//\\/g;
        $checker_output .= qq~<tr>
                    <td class="windowbg2"><span class="important">$module</span></td>
                    <td class="windowbg2">
                        $modulecheck{'5'}<br />
                        <br />$e
                    </td>
                    <td class="windowbg2">$modulecheck{"$module"}</td>
                </tr>~;
    }
    else {
        if ( $module eq 'DateTime::TimeZone' ) {
            my $version   = $module->VERSION;
            my $myversion = (
                "%s %s is\n %s\n",
                $module, ( defined $version ? $version : '<NO $VERSION>' ),
            );
            $checker_output .= qq~<tr>
                    <td class="windowbg2"><span class="good">$module</span></td>
                    <td class="windowbg2" colspan="2">$modulecheck{'6'} $modulecheck{'DateTime::TimeZone2'} <b>$myversion</b></td>
                </tr>~;
        }
        else {
            $checker_output .= qq~<tr>
                    <td class="windowbg2"><span class="good">$module</span></td>
                    <td class="windowbg2" colspan="2">$modulecheck{'6'}</td>
                </tr>~;
        }
    }
}
my $perlver = $];

if ( $script_root !~ /ModuleChecker[.]\w+$/xsm ) {
    $yymain .= qq~
        <div class="bordercolor rightboxdiv" style="float: left; margin-top:.5em">
            <table class="border-space pad-cell">
                <tr>
                    <td class="titlebg" colspan="3"><b>$modulecheck{'1'}</b></td>
                </tr><tr>
                    <td class="catbg" colspan="3">
                        <span class="small">$modulecheck{'2'}</span>
                    </td>
                </tr><tr>
                    <td class="catbg" colspan="3">
                        <b>$modulecheck{'perlver'}</b>: $perlver
                    </td>
                </tr>~ . (
        $i
        ? qq~<tr>
                    <td class="windowbg2">
                        <span class="important"><b>$modulecheck{'7'}</b></span>
                    </td>
                    <td class="windowbg2" colspan="2">$i</td>
                </tr>~
        : q{}
      )
      . qq~<tr>
                    <td class="catbg center"><b>$modulecheck{'3'}</b></td>
                    <td class="catbg center" colspan="2"><b>$modulecheck{'4'}</b></td>
                </tr>
            $checker_output
            </table>
        </div>~;

}
1;
