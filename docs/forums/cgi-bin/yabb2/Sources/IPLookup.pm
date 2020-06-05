###############################################################################
# IPLookup.pm                                                                 #
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

$iplookuppmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

if ( !$ipLookup || !$INFO{'ip'} || ( !$iamadmin && !$iamgmod && !$iamfmod ) ) {
    fatal_error('not_allowed');
}

LoadCensorList();
get_micon();
get_template('Other');

sub IPLookup {
    $ip = $INFO{'ip'};
    my $lookuplink = q{};
    fopen( IPLOOKUP, "<$vardir/iplookup.urls" )
      or fatal_error( 'cannot_open', "$vardir/iplookup.urls", 1 );
    @iplookup_urls = <IPLOOKUP>;
    fclose(IPLOOKUP);
    chomp @iplookup_urls;

    foreach my $i (@iplookup_urls) {
        my ( $iplookup_name, $iplookup_url ) = split /\|/xsm, $i;
        $iplookup_name = Censor($iplookup_name);
        $iplookup_url =~ s/{ip}/$ip/gxsm;
        $iplookup_url =~ s/^\s+//gsm;
        $iplookup_url =~ s/\s+$//gsm;
        $iplookup_url =~ s/\r//gxsm;
        $iplookup_url =~ s/\n//gxsm;
        $iplookup_url =~ s/\t//gsm;
        if ( $iplookup_url !~ /&(.*amp;)/gsm ) {
            $iplookup_url =~ s/&/&amp;/gxsm;
        }
        if ( $iplookup_url !~ /http(s|):\/\//xsm ) {
            $iplookup_url = qq~http://$iplookup_url~;
        }

        $lookuplink .=
          qq~<a href="$iplookup_url" target="_blank">$iplookup_name</a><br />~;
    }

    $yymain .= $my_ipdiv;
    $yymain =~ s/{yabb lookuplink}/$lookuplink/gsm;
    $yymain =~ s/{yabb ip}/$ip/gsm;

    $yytitle      = qq~$lookup_txt{'iplookup'}~;
    $yynavigation = qq~&rsaquo; $lookup_txt{'iplookup'}~;
    template();
    return;
}

1;
