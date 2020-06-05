###############################################################################
# SpamCheck.pm                                                                #
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
our $VERSION = '2.6.11';

$spamcheckpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub spamcheck {
    my ($rawcontent) = @_;
    $rawcontent =~ s/[\r\n\t]/ /gxsm;        #convert cr/lf/tab to space
    $rawcontent =~ s/\[(.*?){1,2}\]//gxsm;

# rip out all make up yabb tags if it is a non yabbc message which can be used to break and obscure words
    $rawcontent =~ s/\<(.*?){1,2}\>//gxsm;

# rip out all make up html tags if it is a html message which can be used to break and obscure words
    my $testcontent = lc " $rawcontent";

#add a leading space to trace start of the very first word and make it lowercase
    my ( $spamline, $spamcnt, $searchtype );
    if ( -e "$vardir/spamrules.txt" ) {
        fopen( SPAM, "$vardir/spamrules.txt" )
          or fatal_error( 'cannot_open', 'spamrules.txt', 1 );
        while ( $buffer = <SPAM> ) {
            chomp $buffer;
            $spamline = q{};
            if ( $buffer =~ m/\~\;/xsm ) {
                ( $spamcnt, $spamline ) = split /\~\;/xsm, $buffer;
                $searchtype = 'S';
            }
            elsif ( $buffer =~ m/\=\;/xsm ) {
                ( $spamcnt, $spamline ) = split /\=\;/xsm, $buffer;
                $searchtype = 'E';
            }
            else {
                if ( $buffer ne q{} ) {
                    $spamline   = $buffer;
                    $spamcnt    = 0;
                    $searchtype = 'S';
                }
            }
            if ( !$spamcnt ) { $spamcnt = 0; }
            if ( $spamline ne q{} ) {
                push @spamlines, [ $spamline, $spamcnt, $searchtype ];
            }
        }
        fclose(SPAM);
    }

    for my $spamrule (@spamlines) {
        chomp $spamrule;
        $is_spam = 0;
        ( $spamword, $spamlimit, $spamtype ) = @{$spamrule};
        if ( $spamtype eq 'S' ) {
            @spamcount = $testcontent =~ /$spamword/igxsm;
        }
        elsif ( $spamtype eq 'E' ) {
            @spamcount = $testcontent =~ /\b$spamword\b/igxsm;
        }
        $spamcounter = $#spamcount + 1;
        if ( $spamcounter > $spamlimit ) {
            $is_spam = 1;
            last;
        }
    }
    return ( $is_spam, $spamword );
}

1;
