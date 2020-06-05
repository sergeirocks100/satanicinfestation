###############################################################################
# SetStatus.pm                                                                #
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

$setstatuspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub SetStatus {
    if ( !$staff ) { fatal_error('no_access'); }

    my $start = $INFO{'start'} || 0;
    my $status = substr( $INFO{'action'}, 0, 1 )
      || substr $FORM{'action'}, 0, 1;
    my $threadid   = $INFO{'thread'};
    my $thisstatus = q{};

    if ( !$currentboard ) {
        MessageTotals( 'load', $threadid );
        $currentboard = ${$threadid}{'board'};
    }

    fopen( BOARDFILE, "<$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    my @boardfile = <BOARDFILE>;
	fclose( BOARDFILE );
    for my $line ( 0 .. ( @boardfile - 1 ) ) {
        if ( $boardfile[$line] =~ m/\A$threadid\|/xsm ) {
            my (
                $mnum,     $msub,      $mname, $memail, $mdate,
                $mreplies, $musername, $micon, $mstate
            ) = split /\|/xsm, $boardfile[$line];
            chomp $mstate;

            if ( $mstate !~ /0/sm ) { $mstate .= '0'; }

            if ( $mstate =~ /$status/xsm ) {
                $mstate =~ s/$status//igxsm;

                # Sticky-ing redirects to messageindex always
                # Also handle message index
                if ( $status eq 's' || $INFO{'tomessageindex'} ) {
                    $yySetLocation = qq~$scripturl?board=$currentboard~;
                }
                else {
                    $yySetLocation = qq~$scripturl?num=$threadid/$start~;
                }
            }
            else {
                $mstate .= $status;
                $yySetLocation = qq~$scripturl?board=$currentboard~;
            }
            $thisstatus = $mstate;

            $boardfile[$line] =
"$mnum|$msub|$mname|$memail|$mdate|$mreplies|$musername|$micon|$mstate\n";
        }
    }
    fopen( BOARDFILE, ">$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    print {BOARDFILE} @boardfile or croak "$croak{'print'} BOARDFILE";
    fclose(BOARDFILE);

    MessageTotals( 'load', $threadid );
    ${$threadid}{'threadstatus'} = $thisstatus;
    MessageTotals( 'update', $threadid );

    BoardSetLastInfo( $currentboard, \@boardfile );
    if ( !$INFO{'moveit'} ) {
        redirectexit();
    }
    return;
}

1;
