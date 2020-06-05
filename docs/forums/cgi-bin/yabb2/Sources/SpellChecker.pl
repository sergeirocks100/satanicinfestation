#!/usr/bin/perl --

###############################################################################
# SpellChecker.pl                                                             #
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

$spellcheckerplver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

use LWP::UserAgent;
use HTTP::Request::Common;

$ua = LWP::UserAgent->new( agent => 'GoogieSpell Client' );
$reqXML = q{};

read STDIN, $reqXML, $ENV{'CONTENT_LENGTH'};

$url = "http://orangoo.com/newnox?lang=$ENV{'QUERY_STRING'}";
$res =
  $ua->request( POST $url, Content_Type => 'text/xml', Content => $reqXML );

croak "$res->{_content}" if $res->{_content} =~ /LWP.+https.+Crypt::SSLeay/sm;

print "Content-Type: text/xml\n\n" or croak "$croak{'print'} content-type";
print $res->{_content} or croak "$croak{'print'} speller";

1;
