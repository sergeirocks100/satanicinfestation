###############################################################################
# RemoveTopic.pm                                                              #
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

$removetopicpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub RemoveThread {
    my $thread = $INFO{'thread'};
    if ( $thread =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }

    if ( !$staff && !$iamposter ) {
        fatal_error('delete_not_allowed');
    }
    if ( !$currentboard ) {
        MessageTotals( 'load', $thread );
        $currentboard = ${$thread}{'board'};
    }
    my $threadline = q{};
    fopen( BOARDFILE, "<$boardsdir/$currentboard.txt", 1 )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    my @buffer = <BOARDFILE>;
    fclose( BOARDFILE );
    for my $aa ( 0 .. ( @buffer - 1 ) ) {
        if ( $buffer[$aa] =~ m{\A$thread\|}xsm ) {
            $threadline = $buffer[$aa];
            $buffer[$aa] = q{};
            last;
        }
    }
    fopen( BOARDFILE, ">$boardsdir/$currentboard.txt", 1 )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    print {BOARDFILE} @buffer or croak "$croak{'print'} BOARDFILE";
    fclose(BOARDFILE);

    if ($threadline) {
        if ( !ref $thread_arrayref{$thread} ) {
            fopen( FILE, "$datadir/$thread.txt" )
              or fatal_error( 'cannot_open', "$datadir/$thread.txt", 1 );
            @{ $thread_arrayref{$thread} } = <FILE>;
            fclose(FILE);
        }

        BoardTotals( 'load', $currentboard );
        if ( ( split /\|/xsm, $threadline )[8] !~ /m/sm ) {
            ${ $uid . $currentboard }{'threadcount'}--;
            ${ $uid . $currentboard }{'messagecount'} -=
              @{ $thread_arrayref{$thread} };

            # &BoardTotals("update", ...) is done in &BoardSetLastInfo
        }
        BoardSetLastInfo( $currentboard, \@buffer );

        # remove thread files
        unlink "$datadir/$thread.txt";
        unlink "$datadir/$thread.ctb";
        unlink "$datadir/$thread.mail";
        unlink "$datadir/$thread.poll";
        unlink "$datadir/$thread.polled";

        # remove attachments
        require Admin::Attachments;
        my %remattach;
        $remattach{$thread} = undef;
        RemoveAttachments( \%remattach );
    }

    # remove from Movedthreads.pm only if it's the final thread
    # then look backwards to delete the other entries in
    # the Moved-Info-row if their files were deleted

    *moved_loop = sub {
        my $th = shift;
        foreach ( keys %moved_file ) {
            if (   exists $moved_file{$_}
                && $moved_file{$_} == $th
                && !-e "$datadir/$th.txt" )
            {
                delete $moved_file{$_};
                $save_moved = 1;
                moved_loop($_);
            }
        }
    };
    if ( eval { require Variables::Movedthreads; 1 } ) {
        if ( !$moved_file{$thread} ) {
            moved_loop($thread);
            if ($save_moved) { save_moved_file(); }
        }
    }

    if ( $INFO{'moveit'} != 1 ) {
        $yySetLocation = qq~$scripturl?board=$currentboard~;
        redirectexit();
    }
    return;
}

sub DeleteThread {
    my @x = @_;
    $delete = $FORM{'thread'} || $INFO{'thread'} || $x[0];

    if ( !$currentboard ) {
        MessageTotals( 'load', $delete );
        $currentboard = ${$delete}{'board'};
    }
    if ( $FORM{'ref'} eq 'favorites' ) {
        $INFO{'ref'} = 'delete';
        require Sources::Favorites;
        RemFav($delete);
    }
    if (   ( !$adminbin || ( !$iamadmin && !$iamgmod && !$iamfmod ) )
        && $binboard ne q{}
        && $currentboard ne $binboard )
    {
        require Sources::MoveSplitSplice;
        $INFO{'moveit'}    = 1;
        $INFO{'board'}     = $currentboard;
        $INFO{'thread'}    = $delete;
        $INFO{'oldposts'}  = 'all';
        $INFO{'leave'}     = 2;
        $INFO{'newinfo'}   = 1;
        $INFO{'newboard'}  = $binboard;
        $INFO{'newthread'} = 'new';
        Split_Splice_2();
    }
    elsif ( $iamadmin || $iamgmod || $iamfmod || $binboard eq q{} ) {
        $INFO{'moveit'} = 1;
        $INFO{'thread'} = $delete;
        RemoveThread();
    }
    $yySetLocation = qq~$scripturl?board=$currentboard~;
    redirectexit();
    return;
}

sub Multi {
    if ( !$staff ) { fatal_error('not_allowed'); }

    require Sources::SetStatus;
    require Sources::MoveSplitSplice;

    my $mess_loop;
    if ( $FORM{'allpost'} =~ m/all/ism ) {
        BoardTotals( 'load', $currentboard );
        $mess_loop = ${ $uid . $currentboard }{'threadcount'};
    }
    else {
        $mess_loop = $maxdisplay;
    }

    my $count = 1;
    while ( $mess_loop >= $count ) {
        my ( $lock, $stick, $move, $delete, $ref, $hide );

        if ( $FORM{'multiaction'} eq q{} ) {
            $lock   = $FORM{"lockadmin$count"};
            $stick  = $FORM{"stickadmin$count"};
            $move   = $FORM{"moveadmin$count"};
            $delete = $FORM{"deleteadmin$count"};
            $hide   = $FORM{"hideadmin$count"};
        }
        elsif ( $FORM{'multiaction'} eq 'lock' ) {
            $lock = $FORM{"admin$count"};
        }
        elsif ( $FORM{'multiaction'} eq 'stick' ) {
            $stick = $FORM{"admin$count"};
        }
        elsif ( $FORM{'multiaction'} eq 'move' ) {
            $move = $FORM{"admin$count"};
        }
        elsif ( $FORM{'multiaction'} eq 'delete' ) {
            $delete = $FORM{"admin$count"};
        }
        elsif ( $FORM{'multiaction'} eq 'hide' ) {
            $hide = $FORM{"admin$count"};
        }

        if ( $FORM{'ref'} eq 'favorites' ) {
            $ref = qq~$scripturl?action=favorites~;
        }
        else {
            $ref = qq~$scripturl?board=$currentboard~;
        }

        if ($lock) {
            $INFO{'moveit'} = 1;
            $INFO{'thread'} = $lock;
            $INFO{'action'} = 'lock';
            $INFO{'ref'}    = $ref;
            SetStatus();
        }
        if ($stick) {
            $INFO{'moveit'} = 1;
            $INFO{'thread'} = $stick;
            $INFO{'action'} = 'sticky';
            $INFO{'ref'}    = $ref;
            SetStatus();
        }
        if ($move) {
            $INFO{'moveit'}   = 1;
            $INFO{'board'}    = $currentboard;
            $INFO{'thread'}   = $move;
            $INFO{'oldposts'} = 'all';
            $INFO{'leave'}    = 0;
            $INFO{'newinfo'} ||= $FORM{'newinfo'};
            $INFO{'newboard'}  = $FORM{'toboard'};
            $INFO{'newthread'} = 'new';
            if ( !$INFO{'newboard'} ) { redirectmove($currentboard); }
            else {
                Split_Splice_2();
            }
        }
        if ($hide) {
            $INFO{'moveit'} = 1;
            $INFO{'action'} = 'hide';
            $INFO{'thread'} = $hide;
            SetStatus();
        }
        if ($delete) {
            if ( !$currentboard ) {
                MessageTotals( 'load', $delete );
                $currentboard = ${$delete}{'board'};
            }
            if ( $FORM{'ref'} eq 'favorites' ) {
                $INFO{'ref'} = 'delete';
                require Sources::Favorites;
                RemFav($delete);
            }
            if (   ( !$adminbin || ( !$iamadmin && !$iamgmod && !$iamfmod ) )
                && $binboard ne q{}
                && $currentboard ne $binboard )
            {
                $INFO{'moveit'}    = 1;
                $INFO{'board'}     = $currentboard;
                $INFO{'thread'}    = $delete;
                $INFO{'oldposts'}  = 'all';
                $INFO{'leave'}     = 2;
                $INFO{'newinfo'}   = 1;
                $INFO{'newboard'}  = $binboard;
                $INFO{'newthread'} = 'new';
                Split_Splice_2();
            }
            elsif ( $iamadmin || $iamgmod || $iamfmod || $binboard eq q{} ) {
                $INFO{'moveit'} = 1;
                $INFO{'thread'} = $delete;
                RemoveThread();
            }
        }
        $count++;
    }
    $yySetLocation = qq~$scripturl?board=$currentboard~;
    redirectexit();
    return;
}

1;
