###############################################################################
# RSS.pm                                                                      #
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

$rsspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

# Change the error routine for here.
local $SIG{__WARN__} = sub { RSS_error(@_) };

# Allow us to be called by a system()-like call
# This lets us send data to any language that supports capturing STDOUT.
# Usage is detailed in POD at the bottom.
if ( scalar @ARGV ) { shellaccess(); }

# Is RSS disabled?
if ($rss_disabled) { RSS_error('not_allowed'); }

LoadCensorList();

# Load YaBBC if it is enabled
if ($enable_ubbc) { require Sources::YaBBC; }

# Read from a single board
sub RSS_board {
    ### Arguments:
    # board: the board to load from. Defaults to all boards.
    # showauthor: show the author or not? Defaults to false.
    # topics: Number of topics to show. Defaults to 5.
    ###

    # Local variables
    my ( $board, $topics );    # Variables for settings

    # Settings
    $board = $INFO{'board'};
    $topics = $INFO{'topics'} || $rss_limit || 10;
    if ( $rss_limit && $topics > $rss_limit ) { $topics = $rss_limit; }

    ### Security check ###
    if ( AccessCheck( $currentboard, q{}, $boardperms ) ne 'granted' ) {
        RSS_error('no_access');
    }
    if ( $annboard eq $board && !$iamadmin && !$iamgmod ) {
        RSS_error('no_access');
    }
    if ( ${ $uid . $currentboard }{'brdpasswr'} ) {
        my $cookiename = "$cookiepassword$currentboard$username";
        my $crypass    = ${ $uid . $currentboard }{'brdpassw'};
        if ( !$staff && $yyCookies{$cookiename} ne $crypass ) {
            RSS_error('no_access');
        }
    }

    # Now, go into the board and look for the last X topics
    fopen( BRDTXT, "$boardsdir/$board.txt" )
      || RSS_error( 'cannot_open', "$boardsdir/$board.txt", 1 );
    my @threadlist = <BRDTXT>;
    fclose(BRDTXT);
    my $threadcount = @threadlist;
    if ( $threadcount < $topics ) { $topics = $threadcount; }

    @threadlist = splice @threadlist, 0, $topics;

    # Sorting mode
    if ( $rss_message == 2 ) {

        # Sort by original post
        @threadlist = sort @threadlist;
    }

    # Otherwise, it's good enough as-is
    chomp @threadlist;

    my $i = 0;
    foreach (@threadlist) {
        (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate, $ns
        ) = split /\|/xsm, $_;
        $curnum = $mnum;

        # See if this is a topic that we don't want displayed.
        if ( $mstate =~ /h/sm && !$iamadmin && !$iamgmod ) { next; }

        # Does it need to be returned as a 304?
        if ( $i == 0 ) {    # Do this for the first request only
            $cachedate = RFC822Date($mdate);
            if (   $ENV{'HTTP_IF_NONE_MATCH'} eq qq~"$cachedate"~
                || $ENV{'HTTP_IF_MODIFIED_SINCE'} eq $cachedate )
            {
                Send304NotModified();
                # Comment this out to test with caching disabled
            }
        }

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        FromHTML($msub);
        ToChars($msub);

        # Censor the subject of the thread.
        $msub = Censor($msub);

        my $postid = "$mreplies#$mreplies";
        if ( $rss_message == 2 ) { $postid = '0#0'; }

        my $category = "$mbname/$boardname";
        FromHTML($category);

        # Show the minimum stuff (topic title, link to it)
        if ($accept_permalink) {
            $permdate = permtimer($curnum);
            $yymain .= q~       <item>
                <title>~ . RSSDescriptionTrim($msub) . q~</title>
                <link>~
              . RSSDescriptionTrim(
                "http://$perm_domain/$symlink$permdate/$currentboard/$curnum")
              . q~</link>
                <category>~ . RSSDescriptionTrim($category) . q~</category>
                <guid isPermaLink="true">~
              . RSSDescriptionTrim(
                "http://$perm_domain/$symlink$permdate/$currentboard/$curnum")
              . q~</guid>
~;
        }
        else {
            $yymain .= q~       <item>
                <title>~ . RSSDescriptionTrim($msub) . q~</title>
                <link>~
              . RSSDescriptionTrim("$scripturl?num=$curnum") . q~</link>
                <category>~ . RSSDescriptionTrim($category) . q~</category>
                <guid>~
              . RSSDescriptionTrim("$scripturl?num=$curnum") . q~</guid>
~;
        }

        my $post;
        fopen( TOPIC, "$datadir/$curnum.txt" )
          || RSS_error( 'cannot_open', "$datadir/$curnum.txt", 1 );
        if ( $rss_message == 1 ) {

            # Open up the thread and read the last post.
            while (<TOPIC>) {
                chomp $_;
                if ($_) { $post = $_; }
            }
        }
        elsif ( $rss_message == 2 ) {

            # Open up the thread and read the first post.
            $post = <TOPIC>;
        }
        fclose(TOPIC);
        if ( $post ne q{} ) {
            (
                undef, undef, undef, undef,    $musername,
                undef, undef, undef, $message, $ns
            ) = split /\|/xsm, $post;
        }
        if ($showauthor) {
            if ( -e "$memberdir/$musername.vars" ) {
                LoadUser($musername);
                if ( !${ $uid . $musername }{'hidemail'} ) {
                    $yymain .=
                      q~<author>~
                      . RSSDescriptionTrim(
"${$uid.$musername}{'email'} (${$uid.$musername}{'realname'})"
                      ) . q~</author>~;
                }
                else {
                    $yymain .=
                        q~           <author>~
                      . RSSDescriptionTrim("$rssemail (${$uid.$musername}{'realname'})")
                      . qq~</author>\n~;
                }
            }
        }
        if ($showdate) {
            if ( $rss_message == 2 ) {
                $mdate = $curnum;
            }    # Sort by topic creation if requested.
                 # Get the date how the user wants it.
            my $realdate = RFC822Date($mdate);
            $yymain .= qq~      <pubDate>$realdate</pubDate>
~;
        }
        if ( $message ne q{} ) {
            ( $message, undef ) = Split_Splice_Move( $message, $curnum );
            if ($enable_ubbc) {
                LoadUser($musername);
                $displayname = ${ $uid . $musername }{'realname'};
                DoUBBC();
            }
            FromHTML($message);
            ToChars($message);
            $message = Censor($message);
            $yymain .=
                q~       <description>~
              . RSSDescriptionTrim($message)
              . q~</description>
~;
        }

        # Finish up the item
        $yymain .= q~       </item>
~;
		$yymain =~ s/data-rel/rel/gsm;
        $i++;    # Increment
    }

    ToChars($boardname);
    $yytitle = $boardname;
    $yydesc  = ${ $uid . $curboard }{'description'};

    RSS_template();
    return;
}

# Similar to Recent.pl&RecentList but uses original code
# RSS feed from multiple boards (a category or the whole forum)
sub RSS_recent {
    ### Arguments:
    # catselect: use a specific category instead of the whole forum (optional)
    # topics: Number of topics to show. Defaults to 5.
    ###

    # Local variables
    my ($topics);    # Variables for settings
    my ( @threadlist, $i );    # Variables for the messages

    # Settings
    $topics = $INFO{'topics'} || $rss_limit || 10;
    if ( $rss_limit && $topics > $rss_limit ) { $topics = $rss_limit; }

    $yytitle = "$topics $maintxt{'214b'}";

    # If this is just a single category, handle it.
    if ( $INFO{'catselect'} ) {
        @categoryorder = ( $INFO{'catselect'} );
    }

    # Find the latest $topics post times in all boards that we have access to
    # and add them to a giant array
    foreach my $catid (@categoryorder) {
        my $boardlist = $cat{$catid};

        my @bdlist = split /\,/xsm, $boardlist;
        my ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};
        my $cataccess = CatAccess($catperms);
        if ( !$cataccess ) { next; }

        if ( $INFO{'catselect'} ) {
            $yytitle = $catname;
            $mydesc = $catname;
        }

        foreach my $curboard (@bdlist) {
            ( $boardname{$curboard}, $boardperms, $boardview ) = split /\|/xsm,
              $board{$curboard};

            my $access = AccessCheck( $curboard, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' ) { next; }
            if ( ${ $uid . $curboard }{'brdpasswr'} ) {
                my $cookiename = "$cookiepassword$curboard$username";
                my $crypass    = ${ $uid . $curboard }{'brdpassw'};
                if ( !$staff && $yyCookies{$cookiename} ne $crypass ) { next; }
            }

            fopen( BOARD, "$boardsdir/$curboard.txt" )
              || RSS_error( 'cannot_open', "$boardsdir/$curboard.txt", 1 );
            for my $i ( 0 .. ( $topics - 1 ) ) {
                my ( $buffer, $mnum, $mdate, $mstate );

                $buffer = <BOARD>;
                if ( !$buffer ) { last; }
                chomp $buffer;

                (
                    $mnum, undef, undef, undef, $mdate,
                    undef, undef, undef, $mstate
                ) = split /\|/xsm, $buffer;
                $mdate = sprintf '%010d', $mdate;
                if ( $rss_message == 2 ) {
                    $mdate = $mnum;
                }    # Sort by topic creation if requested.

                # Check if it's hidden. If so, don't show it
                if ( $mstate =~ /h/sm && !$iamadmin && !$iamgmod ) { next; }

     # Add it to an array, using $mdate as the first value so we can easily sort
                push @threadlist, "$mdate|$curboard|$buffer";
            }
            fclose(BOARD);

            # Clean out the extra entries in the threadlist
            @threadlist = reverse sort @threadlist;
            $threadcount = @threadlist;
            if ( $threadcount < $topics ) { $topics = $threadcount; }
            @threadlist = @threadlist[ 0 .. $topics - 1 ];
        }
    }

    for my $i ( 0 .. ( @threadlist - 1 ) ) {

        # Opening item stuff
        (
            $mdate,     $board,  $mnum,   $msub,
            $mname,     $memail, $modate, $mreplies,
            $musername, $micon,  $mstate
        ) = split /\|/xsm, $threadlist[$i];
        $curnum = $mnum;

        ( $msub, undef ) = Split_Splice_Move( $msub, 0 );
        FromHTML($msub);
        ToChars($msub);

        # Censor the subject of the thread.
        $msub = Censor($msub);

        # Does it need to be returned as a 304?
        if ( $i == 0 ) {    # Do this for the first request only
            $cachedate = RFC822Date($mdate);
            if (   $ENV{'HTTP_IF_NONE_MATCH'} eq qq~"$cachedate"~
                || $ENV{'HTTP_IF_MODIFIED_SINCE'} eq $cachedate )
            {
                Send304NotModified();
                # Comment this out to test with caching disabled
            }
        }

        my $postid = "$mreplies#$mreplies";
        if ( $rss_message == 2 ) { $postid = '0#0'; }

        my $category = "$mbname/$boardname{$board}";
        FromHTML($category);
        my $bn = $boardname{$board};
        FromHTML($bn);
        if ($accept_permalink) {
            my $permsub = $msub;
            $permdate = permtimer($curnum);
            $permsub =~ s/ /$perm_spacer/gsm;
            $yymain .= q~           <item>
            <title>~ . RSSDescriptionTrim("$bn - $msub") . q~</title>
            <link>~
              . RSSDescriptionTrim(
                "http://$perm_domain/$symlink$permdate/$board/$curnum")
              . q~</link>
            <category>~ . RSSDescriptionTrim($category) . q~</category>
            <guid isPermaLink="true">~
              . RSSDescriptionTrim(
                "http://$perm_domain/$symlink$permdate/$board/$curnum")
              . qq~</guid>\n~;
        }
        else {
            $yymain .= q~       <item>
            <title>~ . RSSDescriptionTrim("$bn - $msub") . q~</title>
            <link>~
              . RSSDescriptionTrim("$scripturl?num=$curnum/$postid") . q~</link>
            <category>~ . RSSDescriptionTrim($category) . q~</category>
            <guid>~
              . RSSDescriptionTrim("$scripturl?num=$curnum/$postid")
              . qq~</guid>\n~;
        }

        my $post;
        fopen( TOPIC, "$datadir/$curnum.txt" )
          || RSS_error( 'cannot_open', "$datadir/$curnum.txt", 1 );
        if ( $rss_message == 1 ) {

            # Open up the thread and read the last post.
            while (<TOPIC>) {
                chomp $_;
                if ($_) { $post = $_; }
            }
        }
        elsif ( $rss_message == 2 ) {

            # Open up the thread and read the first post.
            $post = <TOPIC>;
        }
        fclose(TOPIC);

        if ( $post ne q{} ) {
            (
                undef, undef, undef, undef,    $musername,
                undef, undef, undef, $message, $ns
            ) = split /\|/xsm, $post;
        }

        if ($showauthor) {

# The spec really wants us to include their email.
# That's not advisable for us (spambots anyone?). So we skip author if the email hidden flag is on for that user.
            if ( -e "$memberdir/$musername.vars" ) {
                LoadUser($musername);
                if ( !${ $uid . $musername }{'hidemail'} ) {
                    $yymain .=
                      q~           <author>~
                      . RSSDescriptionTrim(
"${$uid.$musername}{'email'} (${$uid.$musername}{'realname'})"
                      ) . qq~</author>\n~;
                }
                else {
                    $yymain .=
                        q~           <author>~
                      . RSSDescriptionTrim("$rssemail (${$uid.$musername}{'realname'})")
                      . qq~</author>\n~;
                }
            }
        }

        if ($showdate) {
            if ( $rss_message == 2 ) {
                $mdate = $curnum;
            }    # Sort by topic creation if requested.
                 # Get the date how the user wants it.
            my $realdate = RFC822Date($mdate);
            $yymain .= qq~          <pubDate>$realdate</pubDate>\n~;
        }

        if ( $message ne q{} ) {
            ( $message, undef ) = Split_Splice_Move( $message, $curnum );
            if ($enable_ubbc) {
                LoadUser($musername);
                $displayname = ${ $uid . $musername }{'realname'};
                DoUBBC();
            }
            FromHTML($message);
            ToChars($message);
            $message = Censor($message);
            $yymain .=
                q~           <description>~
              . RSSDescriptionTrim($message)
              . qq~</description>\n~;
        }

        $yymain .= qq~      </item>\n
~;
		$yymain =~ s/data-rel/rel/gsm;
    }

    ToChars($boardname);
    $yydesc  = ${ $uid . $curboard }{'description'};

    RSS_template();
    return;
}

sub RSS_template {    # print RSS output
                      # Generate the lastBuildDate
    my $rssdate = RFC822Date($date);

# Send out the "Last-Modified" and "ETag" headers so nice readers will ask before downloading.
    $LastModified = $ETag = $cachedate || $rssdate;
    $contenttype = 'text/xml';
    print_output_header();

    # Make the generator look better
    my $RSSplver = $rssplver;
    $RSSplver =~ s/\$//gxsm;

# Removed per Corey's suggestion: http://www.yabbforum.com/community/YaBB.pl?num=1142571424/20#20
#my $docs = "       <docs>http://$perm_domain</docs>\n" if $perm_domain;

    my $mainlink = $scripturl;
    my $tit = "$yytitle - $mbname";
    if ( $INFO{'board'} )     { $mainlink .= "?board=$INFO{'board'}";
        $descr = ( $boardname ? "$boardname - " : q{} ) . $mbname;
    }
    elsif ( $INFO{'catselect'} ) { $mainlink .= "?catselect=$INFO{'catselect'}";
        $descr =  qq{$mydesc - $mbname};
    }


    FromHTML($tit);
    FromHTML($descr);
    my $mn = $mbname;
    FromHTML($mn);
    $output = qq~<?xml version="1.0" encoding="$yymycharset" ?>
<!-- IF YOU'RE SEEING THIS AND ARE USING CHROME GO TO https://chrome.google.com/webstore/detail/rss-subscription-extensio/nlbjncdgjeocebhnmkbbbdekmmmcbfjd AND GET THE ADD-IN -->
<!-- IF YOU'RE SEEING THIS AND ARE USING OPERA GO TO https://addons.opera.com/en/extensions/ and search for 'RSS' to get an add-in -->
<!-- Generated by YaBB on $rssdate -->
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
        <atom:link href="$scripturl?action=$INFO{'action'}~
      . ( $INFO{'board'} ? ";board=$INFO{'board'}" : q{} ) . ( $INFO{'catselect'} ? ";catselect=$INFO{'catselect'}" : q{} )
      . q~" rel="self" type="application/rss+xml" />
        <title>~ . RSSDescriptionTrim($tit) . q~</title>
        <link>~ . RSSDescriptionTrim($mainlink) . q~</link>
        <description>~ . RSSDescriptionTrim($descr) . q~</description>
        <language>~
      . RSSDescriptionTrim("$maintxt{'w3c_lngcode'}") . q~</language>

        <copyright>~ . RSSDescriptionTrim($mn) . qq~</copyright>
        <lastBuildDate>$rssdate</lastBuildDate>
        <docs>http://blogs.law.harvard.edu/tech/rss</docs>
        <generator>$RSSplver</generator>
        <ttl>30</ttl>
$yymain
    </channel>
</rss>~;

    print_HTML_output_and_finish();
    return;
}

sub RSS_error {

    # This routine is mostly a copy of fatal_error except it uses RSS templating
    my ( $e, $t, $v ) = @_;
    LoadLanguage('Error');
    my ( $e_filename, $e_line, $e_subroutine, $l, $ot );

    # Gets filename and line where fatal_error was called.
    # Need to go further back to get correct subroutine name,
    # otherwise will print fatal_error as current subroutine!
    ( undef, $e_filename, $e_line ) = caller 0;
    ( undef, undef, undef, $e_subroutine ) = caller 1;
    ( undef, $e_subroutine ) = split /::/xsm, $e_subroutine;
    if ( $t || $e ) {
        $ot = "<b>$maintxt{'error_description'}</b>: $error_txt{$e} $t";
    }
    if (   ( $debug == 1 or ( $debug == 2 && $iamadmin ) )
        && ( $e_filename || $e_line || $e_subroutine ) )
    {
        $l =
"<br />$maintxt{'error_location'}: $e_filename<br />$maintxt{'error_line'}: $e_line<br />$maintxt{'error_subroutine'}: $e_subroutine";
    }
    if ($v) { $v = "<br />$maintxt{'error_verbose'}: $!"; }

    if ($elenable) {
        fatal_error_logging("$ot$l$v");
    }

    my $tit = $error_txt{'error_occurred'};
    FromHTML($tit);
    my $ed = "$ot$l$v";
    FromHTML($ed);
    my $mn = $mbname;
    FromHTML($mn);
    $yymain = q~
    <item>
        <title>~ . RSSDescriptionTrim($tit) . q~</title>
        <description>~ . RSSDescriptionTrim($ed) . q~</description>
        <category>~ . RSSDescriptionTrim($mn) . q~</category>
    </item>~;

    RSS_template();
    return;
}

sub Send304NotModified {
    print "Status: 304 Not Modified\n\n" or croak "$croak{'print'} 304";
    exit;
}

sub RFC822Date {

    # Takes a Unix timestamp and returns the RFC-822 date format
    # of it: Sat, 07 Sep 2002 9:42:31 GMT
    my @GMTime = split / +/sm, gmtime shift;
    return "$GMTime[0], $GMTime[2] $GMTime[1] $GMTime[4] $GMTime[3] GMT";
}

sub RSSDescriptionTrim {    # This formats the RSS
    my @x = @_;

    $x[0] =~ s/ (class|style)\s*=\s*["'].+?['"]//gsm;

    $x[0] =~ s/&/&#38;/gsm;
    $x[0] =~ s/"/&#34;/gsm;      #";
    $x[0] =~ s/'/&#39;/gsm;      #';
    $x[0] =~ s/  / &#160;/gsm;
    $x[0] =~ s/</&#60;/gsm;
    $x[0] =~ s/>/&#62;/gsm;
    $x[0] =~ s/\|/&#124;/gsm;
    $x[0] =~ s/\{/&#123;/gsm;
    $x[0] =~ s/\}/&#125;/gsm;

    return $x[0];
}

sub shellaccess {

    # Parse the arguments
    my ( $i, %arguments );

    for my $i ( 0 .. ( @ARGV - 1 ) ) {
        if ( $ARGV[$i] =~ /\A\-/sm ) {
            my ( $option, $value );
            $option = $ARGV[$i];
            $option =~ s/\A\-\-?//xsm;
            ( $option, $value ) = split /\=/xsm, $option;
            $arguments{$option} = $value || q{};
            if ( !defined $arguments{$option} ) { $arguments{$option} = 1; }
        }
    }

    ### Requirements and Errors ###
    $script_root = $arguments{'script-root'};

    if ( -e 'Paths.pm' ) { require Paths; }
    elsif ( -e "$script_root/Paths.pm" ) { require "$script_root/Paths.pm"; }

    require Variables::Settings;
    require Sources::Subs;
    require Sources::DateTime;
    require Sources::Load;

    LoadCookie();        # Load the user's cookie (or set to guest)
    LoadUserSettings();  # Load user settings
    WhatLanguage();      # Figure out which language file we should be using! :D

    get_forum_master();
    require Sources::Security;

    # Is RSS disabled?
    if ($rss_disabled) { RSS_error('rss_disabled'); }

    $gzcomp = 0;         # Disable gzip so we can talk clearly

    # Map %arguments to %INFO
    foreach my $var (qw(action board catselect topics)) {
        $INFO{$var} = $arguments{$var};
    }

    # Run the subroutine
    require Sources::SubList;
    my $action = $INFO{'action'};
    my ( $file, $sub ) = split /&/xsm, $director{$action};
    if ( $file eq 'RSS.pm' ) { &{$sub}(); }
    exit;
}

1;
