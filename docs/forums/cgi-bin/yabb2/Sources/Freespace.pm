###############################################################################
# Freespace.pm                                                                #
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

$freespacepmver = 'YaBB 2.6.11 $Revision: 1611 $';

sub freespace {
    my ( $FreeBytes, $hostchecked );
    if ( $OSNAME =~ /Win/sm ) {
        if ($enable_freespace_check) {
            my @x =
              qx{DIR /-C};  # Do an ordinary DOS dir command and grab the output
            my $lastline = pop @x;

            # should look like: 17 Directory(s), 21305790464 Bytes free
            return -1
              if $lastline !~ m/byte/ism;

           # error trapping if output fails. The word byte should be in the line
            if ( $lastline =~ /^\s+(\d+)\s+(.+?)\s+(\d+)\s+(.+?)\n$/sm ) {
                $FreeBytes = $3 - 100_000;    # 100000 bytes reserve
            }

        }
        else {
            return;
        }

        $yyfreespace = 'Windows';

    }
    else {
        if ($enable_quota) {
            my @quota = qx{quota -u $hostusername -v};

            # Do an ordinary *nix quota command and grab the output
            return -1 if !$quota[2];

            # error trapping if output fails.
            @quota = split / +/sm, $quota[$enable_quota], 5;
            $quota[2] =~ s/\*//xsm;
            $FreeBytes =
              ( ( $quota[3] - $quota[2] ) * 1024 ) -
              100_000;    # 100000 bytes reserve
            $hostchecked = 1;

        }
        elsif ($findfile_maxsize) {
            ( $FreeBytes, $hostchecked ) = split /<>/xsm, $findfile_space;
            if ( $FreeBytes < 1 || $hostchecked < $date ) {

                # fork the process since the *nix find command can take a while
                $child_pid = fork;
                if ( !$child_pid ) {    # child process runs here and exits then
                    $findfile_space = 0;
                    map { $findfile_space += $_ }
                      split /-/xsm,
                      qx(find $findfile_root -noleaf -type f -printf '%s-');
                    $findfile_space =
                      ( ( $findfile_maxsize * 1024 * 1024 ) - $findfile_space )
                      . '<>'
                      . ( $date + ( $findfile_time * 60 ) );

                    # actual free host space <> time for next check

                    require Admin::NewSettings;
                    SaveSettingsTo('Settings.pm');
                    exit 0;
                }
            }
            $hostchecked = 1;

        }
        elsif ($enable_freespace_check) {
            my @x = qx{df -k .};

            # Do an ordinary *nix df -k . command and grab the output
            my $lastline = pop @x;

            # should look like: /dev/path 151694892 5495660 134063644 4% /
            if ( $lastline !~ m/\%/xsm ) { return -1; }

            # error trapping if output fails. The % sign should be in the line
            $FreeBytes =
              ( ( split / +/sm, $lastline, 5 )[3] * 1024 ) -
              100_000;    # 100000 bytes reserve

        }
        else {
            return;
        }

        $yyfreespace = 'Unix/Linux/BSD';
    }
    if ( $FreeBytes < 1 ) { automaintenance( 'on', 'low_disk' ); }

    if ( $FreeBytes >= _1073_741_824 ) {
        $yyfreespace = sprintf '%.2f',
          $FreeBytes / ( 1024 * 1024 * 1024 ) . " GB ($yyfreespace)";
    }
    elsif ( $FreeBytes >= 1_048_576 ) {
        $yyfreespace = sprintf '%.2f',
          $FreeBytes / ( 1024 * 1024 ) . " MB ($yyfreespace)";
    }
    else {
        $yyfreespace =
          sprintf( '%.2f', $FreeBytes / 1024 ) . " KB ($yyfreespace)";
    }
    return $hostchecked;
}

1;
