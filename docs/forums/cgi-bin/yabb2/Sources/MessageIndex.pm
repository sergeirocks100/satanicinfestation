###############################################################################
# MessageIndex.pm                                                             #
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
no warnings qw(uninitialized once);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$messageindexpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
get_micon();
LoadLanguage('MessageIndex');

if ( $INFO{'tsort'} eq q{} ) {
    $tsortcookie = "$cookietsort$currentboard$username";
    $tsort       = $yyCookies{$tsortcookie};
    $tsort =~ s/\D//gsm;
}
else {
    $tsort = $INFO{'tsort'};
    $tsort =~ s/\D//gsm;
    my $cookiename = "$cookietsort$currentboard$username";
    my $expiration = 'Sunday, 17-Jan-2038 00:00:00 GMT';
    push @otherCookies,
      write_cookie(
        -name    => "$cookiename",
        -value   => "$tsort",
        -path    => q{/},
        -expires => "$expiration"
      );
}

sub MessageIndex {

    # Check if board was 'shown to all' - and whether they can view the board
    if ( AccessCheck( $currentboard, q{}, $boardperms ) ne 'granted' ) {
        fatal_error('no_access');
    }
    if ( $annboard eq $currentboard && !$iamadmin && !$iamgmod && !$iamfmod ) {
        fatal_error('no_access');
    }

    my (
        $counter, $mcount, $showmods, $mnum,     $msub,
        $mname,   $memail, $mdate,    $mreplies, $musername,
        $micon,   $mstate, $dlp,
    );
    my (
        $numanns,            $threadcount, $countsticky,
        $stkynum,            @tmpanns,     @threadlist,
        @nostickythreadlist, @threads,     $usermessagepage
    );
    BoardTotals( 'load', $currentboard );

    # See if we just want a message list from ajax
    if ( $INFO{'messagelist'} ) { $messagelist = $INFO{'messagelist'}; }

# Load template here for conditionals based on whether we're ajax loading or not.
    get_template('MessageIndex');

    # Build a list of the board's moderators. We don't need this if it's ajax.
    if ( !$messagelist ) {
        if ( keys %moderators > 0 ) {
            if ( keys %moderators == 1 ) {
                $showmods = qq~($messageindex_txt{'298'}: ~;
            }
            else { $showmods = qq~($messageindex_txt{'63'}: ~; }

            while ( $_ = each %moderators ) {
                FormatUserName($_);
                $showmods .= QuickLinks( $_, 1 ) . q{, };
            }
            $showmods =~ s/, \Z/)/sm;
        }
        if ( keys %moderatorgroups > 0 ) {
            if ( keys %moderatorgroups == 1 ) {
                $showmodgroups = qq~($messageindex_txt{'298a'}: ~;
            }
            else { $showmodgroups = qq~($messageindex_txt{'63a'}: ~; }

            my ( $tmpmodgrp, $thismodgrp );
            while ( $_ = each %moderatorgroups ) {
                $tmpmodgrp = $moderatorgroups{$_};
                ( $thismodgrp, undef ) = split /\|/xsm, $NoPost{$tmpmodgrp}, 2;
                $showmodgroups .= qq~$thismodgrp, ~;
            }
            $showmodgroups =~ s/, \Z/)/sm;
        }
        if ( $showmodgroups ne q{} && $showmods ne q{} ) {
            $showmods .= q~ - ~;
        }
        if ( ${ $uid . $currentboard }{'brdpasswr'} ) {
            my $cookiename = "$cookiepassword$currentboard$username";
            my $crypass    = ${ $uid . $currentboard }{'brdpassw'};
            if ( $iamguest ) {
                BoardPassw_g();
            }
            elsif ( !$staff && $yyCookies{$cookiename} ne $crypass ) {
                BoardPassw();
            }
        }
    }

    # Thread Tools
    if ($useThreadtools) {
        LoadTools( 0, 'newthread', 'createpoll', 'notify', 'markboardread' );
    }

    # Load announcements, if they exist.
    if (   $annboard
        && $annboard ne $currentboard
        && ${ $uid . $currentboard }{'rbin'} != 1 )
    {
        chomp $annboard;
        fopen( ANN, "$boardsdir/$annboard.txt" );
        @tmpanns = <ANN>;
        fclose(ANN);
        foreach my $realanns (@tmpanns) {
            my $threadstatus = ( split /\|/xsm, $realanns )[8];
            if ( $threadstatus =~ /h/ism && !$staff ) { next; }
            push @threads, $realanns;
            $numanns++;
        }
        undef @tmpanns;
    }

    # Determine what category we are in.
    $catid = ${ $uid . $currentboard }{'cat'};
    ( $cat, undef ) = split /\|/xsm, $catinfo{$catid};
    ToChars($cat);

    fopen( BRDTXT, "$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    @threadlist = <BRDTXT>;
    fclose(BRDTXT);
    $sort_subject =
qq~<a href="$scripturl?board=$currentboard;tsort=3" rel="nofollow">$messageindex_txt{'70'}</a>~;
    $sort_starter =
qq~<a href="$scripturl?board=$currentboard;tsort=5" rel="nofollow">$messageindex_txt{'109'}</a>~;
    $sort_answer =
qq~<a href="$scripturl?board=$currentboard;tsort=7" rel="nofollow">$messageindex_txt{'110'}</a>~;
    $sort_lastpostim =
qq~<a href="$scripturl?board=$currentboard;tsort=0" rel="nofollow">$messageindex_txt{'22'}</a>~;

    my %starter;
    @temp_list = @threadlist;

    *starter = sub {
        if ( exists $user_info{ $_[0] } ) { return $user_info{ $_[0] }; }
        if ( !exists $memberinf{ $_[0] } ) {
            return lc( ( split /\|/xsm, $_[1], 4 )[2] );
        }
        $user_info{ $_[0] } =
          lc( ( split /\|/xsm, $memberinf{ $_[0] }, 2 )[0] );
    };

    if ( $tsort == 1 ) {
        $sort_lastpostim =
qq~<a href="$scripturl?board=$currentboard;tsort=0" rel="nofollow">$messageindex_txt{'22'}</a> $micon{'sort_first'}~;
        @threadlist = reverse @temp_list;
    }
    elsif ( $tsort == 2 ) {
        $sort_subject =
qq~<a href="$scripturl?board=$currentboard;tsort=3" rel="nofollow">$messageindex_txt{'70'}</a> $micon{'sort_up'}~;
        @threadlist = reverse sort {
            lc(   ( split /\|/xsm, $a, 3 )[1] ) cmp
              lc( ( split /\|/xsm, $b, 3 )[1] )
        } @temp_list;
    }
    elsif ( $tsort == 3 ) {
        $sort_subject =
qq~<a href="$scripturl?board=$currentboard;tsort=2" rel="nofollow">$messageindex_txt{'70'}</a> $micon{'sort_down'}~;
        @threadlist = sort {
            lc(   ( split /\|/xsm, $a, 3 )[1] ) cmp
              lc( ( split /\|/xsm, $b, 3 )[1] )
        } @temp_list;
    }
    elsif ( $tsort == 4 ) {
        ManageMemberinfo('load');
        $sort_starter =
qq~<a href="$scripturl?board=$currentboard;tsort=5" rel="nofollow">$messageindex_txt{'109'}</a> $micon{'sort_up'}~;
        @threadlist = reverse sort {
            starter( ( split /\|/xsm, $a, 8 )[6], $a )
              cmp starter( ( split /\|/xsm, $b, 8 )[6], $b )
        } @temp_list;
        undef %memberinf;
    }
    elsif ( $tsort == 5 ) {
        ManageMemberinfo('load');
        $sort_starter =
qq~<a href="$scripturl?board=$currentboard;tsort=4" rel="nofollow">$messageindex_txt{'109'}</a> $micon{'sort_down'}~;
        @threadlist = sort {
            starter( ( split /\|/xsm, $a, 8 )[6], $a )
              cmp starter( ( split /\|/xsm, $b, 8 )[6], $b )
        } @temp_list;
        undef %memberinf;
    }
    elsif ( $tsort == 6 ) {
        $sort_answer =
qq~<a href="$scripturl?board=$currentboard;tsort=7" rel="nofollow">$messageindex_txt{'110'}</a> $micon{'sort_up'}~;
        @threadlist =
          reverse
          sort { ( split /\|/xsm, $a, 7 )[5] <=> ( split /\|/xsm, $b, 7 )[5] }
          @temp_list;
    }
    elsif ( $tsort == 7 ) {
        $sort_answer =
qq~<a href="$scripturl?board=$currentboard;tsort=6" rel="nofollow">$messageindex_txt{'110'}</a> $micon{'sort_down'}~;
        @threadlist =
          sort { ( split /\|/xsm, $a, 7 )[5] <=> ( split /\|/xsm, $b, 7 )[5] }
          @temp_list;
    }
    else {
        $sort_lastpostim =
qq~<a href="$scripturl?board=$currentboard;tsort=1" rel="nofollow">$messageindex_txt{'22'}</a> $micon{'sort_up'}~;
    }

    undef @temp_list;
    undef %starter;

    foreach my $threadlist (@threadlist) {
        my $threadstatus = ( split /\|/xsm, $threadlist )[8];
        if ( $threadstatus =~ /h/ism && !$staff ) {
            next;
        }
        if ( $threadstatus =~ /s/ism ) {
            push @threads, $threadlist;
            $countsticky++;
        }
        else {
            $nostickythreadlist[$threadcount] = $threadlist;
            $threadcount++;
        }
    }
    undef @threadlist;

    $threadcount = $threadcount + $countsticky + $numanns;
    my $maxindex = $INFO{'view'} eq 'all' ? $threadcount : $maxdisplay;

    # Construct the page links for this board.
    if ( !$iamguest ) {
        ( $usermessagepage, undef, undef, undef ) =
          split /\|/xsm, ${ $uid . $username }{'pageindex'};
    }
    my ( $pagetxtindex, $pagedropindex1, $pagedropindex2, $all, $allselected );
    $indexdisplaynum = 3;              # max number of pages to display
    $dropdisplaynum  = 10;
    $startpage       = 0;
    $max             = $threadcount;
    if ( substr( $INFO{'start'}, 0, 3 ) eq 'all' && $showpageall != 0 ) {
        $maxindex    = $max;
        $all         = 1;
        $allselected = q~ selected="selected"~;
        $start       = 0;
    }
    else { $start = $INFO{'start'} || 0; }
    if ( $start > $threadcount - 1 ) { $start = $threadcount - 1; }
    elsif ( $start < 0 ) { $start = 0; }
    $start    = int( $start / $maxindex ) * $maxindex;
    $tmpa     = 1;
    $pagenumb = int( ( $threadcount - 1 ) / $maxindex ) + 1;

    if ( $start >= ( ( $indexdisplaynum - 1 ) * $maxindex ) ) {
        $startpage = $start - ( ( $indexdisplaynum - 1 ) * $maxindex );
        $tmpa = int( $startpage / $maxindex ) + 1;
    }
    if ( $threadcount >= $start + ( $indexdisplaynum * $maxindex ) ) {
        $endpage = $start + ( $indexdisplaynum * $maxindex );
    }
    else { $endpage = $threadcount }
    $lastpn = int( ( $threadcount - 1 ) / $maxindex ) + 1;
    $lastptn = ( $lastpn - 1 ) * $maxindex;
    $pageindex1 =
qq~<span class="small pgindex"><img src="$index_togl{'index_togl'}" alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" /> $messageindex_txt{'139'}: $pagenumb</span>~;
    $pageindex2 = $pageindex1;

    if ( $pagenumb > 1 || $all ) {

        if ( $usermessagepage == 1 || $iamguest ) {
            $pagetxtindexst = q~<span class="small pgindex">~;
            if ( !$iamguest ) {
                $pagetxtindexst .=
qq~<a href="$scripturl?board=$INFO{'board'};start=$start;action=messagepagedrop"><img src="$index_togl{'index_togl'}"  alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" /></a> $messageindex_txt{'139'}: ~;
            }
            else {
                $pagetxtindexst .=
qq~<img src="$index_togl{'index_togl'}"  alt="$messageindex_txt{'139'}" title="$messageindex_txt{'139'}" /> $messageindex_txt{'139'}: ~;
            }
            if ( $startpage > 0 ) {
                if ($messagelist) {
                    $pagetxtindex =
qq~<a href="$scripturl?board=$currentboard/0">1</a>&nbsp;<a href='javascript: void(0);' onclick='ListPages2("$currentboard","$threadcount");'>...</a>&nbsp;~;
                }
                if ( $startpage == $maxindex ) {
                    $pagetxtindex =
qq~<a href="$scripturl?board=$currentboard/0"><span class="small">1</span></a>&nbsp;~;
                }
            }
            foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
                if ( $counter % $maxindex == 0 ) {
                    if ($messagelist) {
                        $pagetxtindex .=
                          $start == $counter
                          ? qq~<b>[$tmpa]</b>&nbsp;~
                          : qq~<a href="javascript:MessageList('$scripturl?board=$currentboard/$counter;messagelist=1','$yyhtml_root','$currentboard', 1)"><span class="small">$tmpa</span></a>&nbsp;~;
                    }
                    else {
                        $pagetxtindex .=
                          $start == $counter
                          ? qq~<b>[$tmpa]</b>&nbsp;~
                          : qq~<a href="$scripturl?board=$currentboard/$counter"><span class="small">$tmpa</span></a>&nbsp;~;
                    }
                    $tmpa++;
                }
            }
            if ( $endpage < $threadcount - $maxindex ) {
                $pageindexadd =
qq~<a href='javascript: void(0);' onclick='ListPages2("$currentboard","$threadcount");'>...</a>&nbsp;~;
            }
            if ( $endpage != $threadcount ) {
                $pageindexadd .=
qq~<a href="$scripturl?board=$currentboard/$lastptn"><span class="small">$lastpn</span></a>~;
            }

            $pagetxtindex .= $pageindexadd;
            $pageindex1 = qq~$pagetxtindexst $pagetxtindex</span>~;
            $pageindex2 = $pageindex1;
        }
        else {
            $pagedropindex1 = q~<span class="pagedropindex">~;
            $pagedropindex1 .=
qq~<span class="pagedropindex_inner"><a href="$scripturl?board=$INFO{'board'};start=$start;action=messagepagetext"><img src="$index_togl{'index_togl'}"  alt="$messageindex_txt{'19'}" title="$messageindex_txt{'19'}" /></a></span>~;
            $pagedropindex2 = $pagedropindex1;
            $tstart         = $start;

#if (substr($INFO{'start'}, 0, 3) eq 'all') { ($tstart, $start) = split(/\-/, $INFO{'start'}); }
            $d_indexpages = $pagenumb / $dropdisplaynum;
            $i_indexpages = int( $pagenumb / $dropdisplaynum );
            if ( $d_indexpages > $i_indexpages ) {
                $indexpages = int( $pagenumb / $dropdisplaynum ) + 1;
            }
            else { $indexpages = int( $pagenumb / $dropdisplaynum ) }
            $selectedindex = int( ( $start / $maxindex ) / $dropdisplaynum );

            if ( $pagenumb > $dropdisplaynum ) {
                $pagedropindex1 .=
qq~<span class="decselector"><select size="1" name="decselector1" id="decselector1" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
                $pagedropindex2 .=
qq~<span class="decselector"><select size="1" name="decselector2" id="decselector2" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
            }
            for my $i ( 0 .. ( $indexpages - 1 ) ) {
                $indexpage = ( $i * $dropdisplaynum ) * $maxindex;

                $indexstart = ( $i * $dropdisplaynum ) + 1;
                $indexend = $indexstart + ( $dropdisplaynum - 1 );
                if ( $indexend > $pagenumb ) { $indexend = $pagenumb; }
                if ( $indexstart == $indexend ) {
                    $indxoption = qq~$indexstart~;
                }
                else { $indxoption = qq~$indexstart-$indexend~; }
                $selected = q{};
                if ( $i == $selectedindex ) {
                    $selected = q~ selected="selected"~;
                    $pagejsindex =
                      qq~$indexstart|$indexend|$maxindex|$indexpage~;
                }
                if ( $pagenumb > $dropdisplaynum ) {
                    $pagedropindex1 .=
qq~<option value="$indexstart|$indexend|$maxindex|$indexpage"$selected>$indxoption</option>\n~;
                    $pagedropindex2 .=
qq~<option value="$indexstart|$indexend|$maxindex|$indexpage"$selected>$indxoption</option>\n~;
                }
            }
            if ( $pagenumb > $dropdisplaynum ) {
                $pagedropindex1 .= qq~</select>\n</span>~;
                $pagedropindex2 .= qq~</select>\n</span>~;
            }
            $pagedropindex1 .=
q~<span id="ViewIndex1" class="droppageindex viewindex_hid">&nbsp;</span>~;
            $pagedropindex2 .=
q~<span id="ViewIndex2" class="droppageindex viewindex_hid">&nbsp;</span>~;
            $tmpmaxindex = $maxindex;

#if (substr($INFO{'start'}, 0, 3) eq 'all') { $maxindex = $maxindex * $dropdisplaynum; }
            $prevpage = $start - $tmpmaxindex;
            $nextpage = $start + $maxindex;
            $pagedropindexpvbl =
qq~<img src="$index_togl{'index_left0'}" height="14" width="13"  alt="" />~;
            $pagedropindexnxbl =
qq~<img src="$index_togl{'index_right0'}" height="14" width="13"  alt="" />~;
            if ( $start < $maxindex ) {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left0'}" height="14" width="13"  alt="" />~;
            }
            else {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left'}"  height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" class="cursor" ~;
                if ($messagelist) {
                    $pagedropindexpv .=
qq~onclick="MessageList(\\'$scripturl?board=$currentboard/$prevpage;messagelist=1\\',\\'$yyhtml_root\\', \\'$currentboard\\', 1)" ondblclick="MessageList(\\'$scripturl?board=$currentboard/0;messagelist=1\\', \\'$yyhtml_root\\',\\'$currentboard\\', 1)" />~;
                }
                else {
                    $pagedropindexpv .=
qq~onclick="location.href=\\'$scripturl?board=$currentboard/$prevpage\\'" ondblclick="location.href=\\'$scripturl?board=$currentboard/0\\'" />~;
                }
            }
            if ( $nextpage > $lastptn ) {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right0'}"  height="14" width="13" alt="" />~;
            }
            else {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right'}" height="14" width="13"  alt="$pidtxt{'03'}" title="$pidtxt{'03'}" class="cursor" ~;
                if ($messagelist) {
                    $pagedropindexnx .=
qq~onclick="MessageList(\\'$scripturl?board=$currentboard/$nextpage;messagelist=1\\', \\'$yyhtml_root\\',\\'$currentboard\\', 1)" ondblclick="MessageList(\\'$scripturl?board=$currentboard/$lastptn;messagelist=1\\', \\'$yyhtml_root\\',\\'$currentboard\\', 1)" />~;
                }
                else {
                    $pagedropindexnx .=
qq~onclick="location.href=\\'$scripturl?board=$currentboard/$nextpage\\'" ondblclick="location.href=\\'$scripturl?board=$currentboard/$lastptn\\'" />~;
                }
            }

            # make select box have links for ajax vs default url
            if ($messagelist) {
                $default_or_ajax =
qq~javascript:MessageList(\\'$scripturl?board=$currentboard/' + pagstart + ';messagelist=1\\', \\'$yyhtml_root\\',\\'$currentboard\\', 1)~;
            }
            else {
                $default_or_ajax =
                  qq~$scripturl?board=$currentboard/' + pagstart + '~;
            }
            $pageindex1 = qq~$pagedropindex1</span>~;
            $pageindex2 = qq~$pagedropindex2</span>~;

            $pageindexjs = qq~
<script id="RunSelDec" type="text/javascript">
    function SelDec(decparam, visel) {
        splitparam = decparam.split("|");
        var vistart = parseInt(splitparam[0]);
        var viend = parseInt(splitparam[1]);
        var maxpag = parseInt(splitparam[2]);
        var pagstart = parseInt(splitparam[3]);
        //var allpagstart = parseInt(splitparam[3]);
        if (visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
        var pagedropindex = '$visel_0';
        for(i=vistart; i<=viend; i++) {
            if (visel == pagstart) pagedropindex += '$visel_1a<b>' + i + '</b>$visel_1b';
            else pagedropindex += '$visel_2a<a href="$scripturl?board=$currentboard/' + pagstart + '">' + i + '</a>$visel_1b';
            pagstart += maxpag;
        }
        ~;
            if ($showpageall) {
                $pageindexjs .= qq~
            if (vistart != viend) {
                if(visel == 'all') pagedropindex += '$visel_1a<b>$pidtxt{'01'}</b></td>';
                else pagedropindex += '$visel_2a<a href="$scripturl?board=$currentboard/all">$pidtxt{'01'}</a>$visel_1b';
            }
            ~;
            }
            $pageindexjs .= qq~
        if(visel != 'xx') pagedropindex += '$visel_3a$pagedropindexpv$pagedropindexnx$visel_1b';
        else pagedropindex += '$visel_3a$pagedropindexpvbl$pagedropindexnxbl$visel_1b';
        pagedropindex += '$visel_4';
        document.getElementById("ViewIndex1").innerHTML=pagedropindex;
        document.getElementById("ViewIndex1").style.visibility = "visible";
        document.getElementById("ViewIndex2").innerHTML=pagedropindex;
        document.getElementById("ViewIndex2").style.visibility = "visible";
        ~;
            if ( $pagenumb > $dropdisplaynum ) {
                $pageindexjs .= q~
        document.getElementById("decselector1").value = decparam;
        document.getElementById("decselector2").value = decparam;
        ~;
            }
            $pageindexjs .= qq~
    }
    var pagejsindex = "$pagejsindex";
    var tstart = "$tstart";
    document.onload = SelDec(pagejsindex, tstart);
</script>
~;
        }
    }

    if ( $start <= $#threads ) { $stkynum = scalar @threads; }
    push @threads, @nostickythreadlist;
    undef @nostickythreadlist;
    @threads = splice @threads, $start, $maxindex;
    chomp @threads;

    my %attachments;
    if ( ( -s "$vardir/attachments.txt" ) > 5 ) {
        fopen( ATM, "$vardir/attachments.txt" );
        while (<ATM>) {
            $attachments{ ( split /\|/xsm, $_, 2 )[0] }++;
        }
        fclose(ATM);
    }

    LoadCensorList();

    # check the Multi-admin setting
    my $multiview = 0;
    if ($staff) {
        if (   ( $iamadmin && $adminview == 3 )
            || ( $iamgmod && $gmodview == 3 )
            || ( $iamfmod && $fmodview == 3 )
            || ( $iammod  && $modview == 3 ) )
        {
            $multiview = 3;
        }
        elsif (( $iamadmin && $adminview == 2 )
            || ( $iamgmod && $gmodview == 2 )
            || ( $iamfmod && $fmodview == 2 )
            || ( $iammod  && $modview == 2 ) )
        {
            $multiview = 2;
        }
        elsif (( $iamadmin && $adminview == 1 )
            || ( $iamgmod && $gmodview == 1 )
            || ( $iamfmod && $fmodview == 1 )
            || ( $iammod  && $modview == 1 ) )
        {
            $multiview = 1;
        }
    }

    # Print the header and board info.
    ( $boardname, undef ) = split /\|/xsm, $board{$currentboard};
    my $curboardname = $boardname;
    ToChars($curboardname);
    if ( $multiview == 1 ) {
        $yymain .=
          qq~<script type="text/javascript">
function NoPost(op) {
    if (document.getElementById("toboard").options[op].className == "nopost") {
        alert("$messageindex_txt{'nopost'}");
        document.getElementById("toboard").selectedIndex = 0;
    }
}
</script>
\n~;
    }

    if ( $multiview >= 2 ) {
        my $modul = $currentboard eq $annboard ? 4 : 5;
        $yymain .=
qq~<script src="$yyhtml_root/MessageIndex.js" type="text/javascript"></script>
<script type="text/javascript">
function NoPost(op) {
    if (document.getElementById("toboard").options[op].className == "nopost") {
        alert("$messageindex_txt{'nopost'}");
        document.getElementById("toboard").selectedIndex = 0;
    }
}
</script>
\n~;
    }

    my $homelink = qq~<a href="$scripturl">$mbname</a>~;
    my $catlink  = qq~<a href="$scripturl?catselect=$catid">$cat</a>~;
    my $boardlink =
qq~<a href="$scripturl?board=$currentboard" class="a"><b>$curboardname</b></a>~;
    my $modslink = qq~$showmods~;

    $boardtree   = q{};
    $parentboard = $currentboard;
    while ($parentboard) {
        my ( $pboardname, undef, undef ) =
          split /\|/xsm, $board{"$parentboard"};
        ToChars($pboardname);

        if ( ${ $uid . $parentboard }{'canpost'} || !$subboard{$parentboard} ) {
            $pboardname =
qq~<a href="$scripturl?board=$parentboard" class="a"><b>$pboardname</b></a>~;
        }
        else {
            $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard;subboards=1" class="a"><b>$pboardname</b></a>~;
        }
        $boardtree   = qq~ &rsaquo; $pboardname$boardtree~;
        $parentboard = ${ $uid . $parentboard }{'parent'};
    }

    # check how many col's must be spanned
    if ( $multiview > 0 ) {
        $colspan = 7;
    }
    else {
        $colspan = 6;
    }

    if ( !$iamguest ) {
        my $brdid = q{};
        if ( $messagelist ) {
            $mthreadslang = 1;
            $brdid = q{new_} . $INFO{'board'};
        }
        $markalllink =
qq~$menusep<a href="javascript:MarkAllAsRead('$scripturl?board=$INFO{'board'};action=markasread','$imagesdir','$mthreadslang','$brdid')">$img{'markboardread'}</a>~;

        $notify_board =
qq~$menusep<a href="$scripturl?action=boardnotify;board=$INFO{'board'}">$img{'notify'}</a>~;
    }

    if ( AccessCheck( $currentboard, 1 ) eq 'granted' ) {

# when Quick-Post and Quick-Jump: focus message first, then the subject to have a better display
        if ($messagelist) {
            if ($mdrop_postpopup) {
                $postlink =
qq~$menusep<a href="javascript:void(0)" onclick="PostPage('$scripturl?board=$INFO{'board'};action=post;title=StartNewTopic','$INFO{'board'}')">$img{'newthread'}</a>~;
            }
            else {
                $postlink =
qq~$menusep<a href="$scripturl?board=$INFO{'board'};action=post;title=StartNewTopic">$img{'newthread'}</a>~;
            }
        }
        else {
            if ($mindex_postpopup) {
                $postlink =
qq~$menusep<a href="javascript:void(0)" onclick="PostPage('$scripturl?board=$INFO{'board'};action=post;title=StartNewTopic','$INFO{'board'}')">$img{'newthread'}</a>~;
            }
            else {
                $postlink = qq~$menusep<a href="~
                  . (
                    $enable_quickpost && $enable_quickjump
                    ? 'javascript:document.postmodify.message.focus();document.postmodify.subject.focus();'
                    : qq~$scripturl?board=$INFO{'board'};action=post;title=StartNewTopic~
                  ) . qq~">$img{'newthread'}</a>~;
            }
        }
    }
    if ( AccessCheck( $currentboard, 3 ) eq 'granted' ) {
        $polllink =
qq~$menusep<a href="$scripturl?board=$INFO{'board'};action=post;title=CreatePoll">$img{'createpoll'}</a>~;
    }

    if ( $multiview == 3 ) {
        my $adminlink;
        if ( $currentboard eq $annboard ) {
            $adminlink =
qq~<img src="$micon_bg{'announcementlock'}" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" /><img src="$micon_bg{'hide'}" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" /><img src="$micon_bg{'admin_move'}" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" /><img src="$micon_bg{'admin_rem'}" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" />~;
        }
        else {
            $adminlink =
qq~<img src="$micon_bg{'locked'}" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}" /><img src="$micon_bg{'sticky'}" alt="$messageindex_txt{'781'}" title="$messageindex_txt{'781'}" /><img src="$micon_bg{'hide'}" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}" /><img src="$micon_bg{'admin_move'}" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}" /><img src="$micon_bg{'admin_rem'}" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}" />~;
        }
        $adminheader =~ s/{yabb admin}/$adminlink/gsm;
    }
    elsif (
        (
               ( $iamadmin && $adminview != 0 )
            || ( $iamgmod && $gmodview != 0 )
            || ( $iamfmod && $fmodview != 0 )
            || (   $iammod
                && $modview != 0
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        $adminlink = qq~$messageindex_txt{'2'}~;
        $adminheader =~ s/{yabb admin}/$adminlink/gsm;
    }

    # check to display moderator column
    my $tmpstickyheader;
    if ($stkynum) {
        $stickyheader =~ s/{yabb colspan}/$colspan/gsm;
        $tmpstickyheader = $stickyheader;
    }

    # load Favorites in a hash
    if ( ${ $uid . $username }{'favorites'} ) {
        foreach ( split /,/xsm, ${ $uid . $username }{'favorites'} ) {
            $favicon{$_} = 1;
        }
    }

    # Count threads to alternate colors
    my $alternatethreadcolor = 0;

    # Begin printing the message index for current board.
    $counter = $start;
    dumplog($currentboard);    # Mark current board as seen
    my $dmax = $date - ( $max_log_days_old * 86400 );
    foreach (@threads) {
        (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate
        ) = split /\|/xsm, $_;

        my ( $movedSubject, $movedFlag ) = Split_Splice_Move( $msub, $mnum );

        MessageTotals( 'load', $mnum );

        my $altthdcolor =
          ( ( $alternatethreadcolor % 2 ) == 1 ) ? 'windowbg' : 'windowbg2';
        $alternatethreadcolor++;

        my $goodboard = $mstate =~ /a/ism ? $annboard : $currentboard;
        if ( ${$mnum}{'board'} ne $goodboard ) {
            if ($goodboard) { ${$mnum}{'board'} = $goodboard; }
            MessageTotals( 'recover', $mnum );
        }

        $permlinkboard =
          ${$mnum}{'board'} eq $annboard ? $annboard : $currentboard;
        my $permdate = permtimer($mnum);
        my $message_permalink =
qq~<a href="http://$perm_domain/$symlink$permdate/$permlinkboard/$mnum">$messageindex_txt{'10'}</a>~;

        $threadclass = 'thread';
        if    ( $mstate =~ /h/ism ) { $threadclass = 'hide'; }
        elsif ( $mstate =~ /l/ism ) { $threadclass = 'locked'; }
        elsif ( $mreplies >= $VeryHotTopic ) { $threadclass = 'veryhotthread'; }
        elsif ( $mreplies >= $HotTopic )     { $threadclass = 'hotthread'; }
        elsif ( $mstate eq q{} ) { $threadclass = 'thread'; }
        if ( $threadclass eq 'hide' && $mstate =~ /s/ism && $mstate !~ /l/ism )
        {
            $threadclass = 'hidesticky';
        }
        elsif ($threadclass eq 'hide'
            && $mstate =~ /l/ism
            && $mstate !~ /s/ism )
        {
            $threadclass = 'hidelock';
        }
        elsif ($threadclass eq 'hide'
            && $mstate =~ /s/ism
            && $mstate =~ /l/ism )
        {
            $threadclass = 'hidestickylock';
        }
        elsif ($threadclass eq 'locked'
            && $mstate =~ /s/ism
            && $mstate !~ /h/ism )
        {
            $threadclass = 'stickylock';
        }
        elsif ( $mstate =~ /s/ism && $mstate !~ /h/ism ) {
            $threadclass = 'sticky';
        }
        elsif ( ${$mnum}{'board'} eq $annboard && $mstate !~ /h/ism ) {
            $threadclass =
              $threadclass eq 'locked' ? 'announcementlock' : 'announcement';
        }
        ### Start Sticky Shimmy Shuffle mod
        my $stickdir;
        if ($staff) {
            if ( $threadclass eq 'sticky' || $threadclass eq 'stickylock'  || $threadclass eq 'hidesticky' || $threadclass eq 'hidestickylock') {
                $stickdir =
qq~&nbsp;&nbsp;<a href="$scripturl?action=rearrsticky;board=$currentboard;num=$mnum;direction=up" title="$messageindex_txt{'move_up'}"><span class="sticky_stick"><b>&uarr;</b></span></a><a href="$scripturl?action=rearrsticky;board=$currentboard;num=$mnum;direction=down" title="$messageindex_txt{'move_down'}"><span class="sticky_stick"><b>&darr;</b></span> </a>~;
            }
elsif (( $threadclass eq 'announcement' || $threadclass eq 'announcementlock' || ${$mnum}{'board'} eq $annboard && $mstate =~ /h/ism )
                && ( $iamadmin || $iamgmod ) )
            {
                $stickdir =
qq~&nbsp;&nbsp;<a href="$scripturl?action=rearrsticky;board=$annboard;num=$mnum;direction=up;oldboard=$currentboard;" title="$messageindex_txt{'move_up'}"><span class="sticky_stick"><b>&uarr;</b></span></a><a href="$scripturl?action=rearrsticky;board=$annboard;num=$mnum;direction=down;oldboard=$currentboard;" title="$messageindex_txt{'move_down'}"><span class="sticky_stick"><b>&darr;</b></span> </a>~;
            }
        }
        ### End Sticky Shimmy Shuffle Mod

        if ($movedFlag) { $threadclass = 'locked_moved'; }

        if ( !$iamguest && $max_log_days_old ) {

            # Decide if thread should have the "NEW" indicator next to it.
            # Do this by reading the user's log for last read time on thread,
            # and compare to the last post time on the thread.
            $dlp =
              int( $yyuserlog{$mnum} ) >
              int( $yyuserlog{"$currentboard--mark"} )
              ? int( $yyuserlog{$mnum} )
              : int $yyuserlog{"$currentboard--mark"};
            if (
                !$movedFlag
                && (   $yyuserlog{"$mnum--unread"}
                    || ( !$dlp && $mdate > $dmax )
                    || ( $dlp > $dmax && $dlp < $mdate ) )
              )
            {
                if ( ${$mnum}{'board'} eq $annboard ) {
                    $new =
qq~<a href="$scripturl?virboard=$currentboard;num=$mnum/new#new">$newload{'new_mess'}</a>~;
                }
                else {
                    $new =
qq~<a href="$scripturl?num=$mnum/new#new">$newload{'new_mess'}</a>~;
                }
            }
            else {
                $new = q{};
            }
        }

        $micon = qq~$micon{$micon}~;
        $mpoll = q{};
        if ( -e "$datadir/$mnum.poll" ) {
            $mpoll = qq~<b>$messageindex_txt{'15'}: </b>~;
            fopen( POLL, "$datadir/$mnum.poll" );
            my @poll = <POLL>;
            fclose(POLL);
            my (
                $poll_question, $poll_locked, $poll_uname,   $poll_name,
                $poll_email,    $poll_date,   $guest_vote,   $hide_results,
                $multi_vote,    $poll_mod,    $poll_modname, $poll_comment,
                $vote_limit,    $pie_radius,  $pie_legends,  $poll_end
            ) = split /\|/xsm, $poll[0];
            chomp $poll_end;
            if ( $poll_end && !$poll_locked && $poll_end < $date ) {
                $poll_locked = 1;
                $poll_end    = q{};
                $poll[0] =
"$poll_question|$poll_locked|$poll_uname|$poll_name|$poll_email|$poll_date|$guest_vote|$hide_results|$multi_vote|$poll_mod|$poll_modname|$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n";
                fopen( POLL, ">$datadir/$mnum.poll" );
                print {POLL} @poll or croak "$croak{'print'} POLL";
                fclose(POLL);
            }

            $micon = qq~$micon{'pollicon'}~;
            if ($poll_locked) { $micon = $micon{'polliconclosed'}; }
            elsif ( !$iamguest
                && $max_log_days_old
                && $mdate > $date - ( $max_log_days_old * 86400 ) )
            {
                if ( $dlp < $createpoll_date ) {
                    $micon = qq~$micon{'polliconnew'}~;
                }
                else {
                    fopen( POLLED, "$datadir/$mnum.polled" );
                    $polled = <POLLED>;
                    fclose(POLLED);
                    ( undef, undef, undef, $vote_date, undef ) =
                      split /\|/xsm, $polled;
                    if ( $dlp < $vote_date ) {
                        $micon = qq~$micon{'polliconnew'}~;
                    }
                }
            }
        }

        # Load the current nickname of the account name of the thread starter.
        if ( $musername ne 'Guest' ) {
            LoadUser($musername);

            # See if they are an ex-member.
            if (
                (
                    ${ $uid . $musername }{'regdate'}
                    && $mdate > ${ $uid . $musername }{'regtime'}
                )
                || ${ $uid . $musername }{'position'} eq 'Administrator'
                || ${ $uid . $musername }{'position'} eq 'Global Moderator'
              )
            {
                if ( $iamguest) {
                    $mname = $format_unbold{$musername};
                }
                else {
                    $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$musername}">$format_unbold{$musername}</a>~;
                }
            }
            else {
                $mname .= qq~ ($messageindex_txt{'470a'})~;
            }
        }
        else {
            $mname .= " ($maintxt{'28'})";
        }

        # Build the page links list.
        my $pagesall = q{};
        my $pages    = q{};
        if ($showpageall) {
            $pagesall =
              qq~<a href="$scripturl?num=$mnum/all">$pidtxt{'01'}</a>~;
        }
        $maxmessagedisplay ||= 10;
        if ( int( ( $mreplies + 1 ) / $maxmessagedisplay ) > 6 ) {
            $pages =
                qq~ <a href="$scripturl?num=$mnum/~
              . ( !$ttsreverse ? '0#0' : "$mreplies#$mreplies" )
              . q~"><span class="small">1</span></a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$maxmessagedisplay#$maxmessagedisplay"
                : ( $mreplies - $maxmessagedisplay ) . q{#}
                  . ( $mreplies - $maxmessagedisplay )
              ) . q~">2</a>~;

            $endpage = int( $mreplies / $maxmessagedisplay ) + 1;
            $i       = ( $endpage - 1 ) * $maxmessagedisplay;
            $j       = $i - $maxmessagedisplay;
            $k       = $endpage - 1;
            $tmpa    = $endpage - 2;
            $tmpb    = $j - $maxmessagedisplay;
            $pages .=
qq~ <a href="javascript:void(0);" onclick="ListPages($mnum);">...</a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$tmpb#$tmpb"
                : ( $mreplies - $tmpb ) . q{#} . ( $mreplies - $tmpb )
              ) . qq~"><span class="small">$tmpa</span></a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$j#$j"
                : ( $mreplies - $j ) . q{#} . ( $mreplies - $j )
              ) . qq~"><span class="small">$k</span></a>~;
            $pages .= qq~ <a href="$scripturl?num=$mnum/~
              . (
                !$ttsreverse
                ? "$i#$i"
                : ( $mreplies - $i ) . q{#} . ( $mreplies - $i )
              ) . qq~"><span class="small">$endpage</span></a>~;
            $pages =
qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages $pagesall &#187;</span>~;
        }
        elsif ( $mreplies + 1 > $maxmessagedisplay ) {
            $tmpa = 1;
            foreach my $tmpb ( 0 .. $mreplies ) {
                if ( $tmpb % $maxmessagedisplay == 0 ) {
                    $pages .= qq~<a href="$scripturl?num=$mnum/~
                      . (
                        !$ttsreverse
                        ? "$tmpb#$tmpb"
                        : ( $mreplies - $tmpb ) . q{#} . ( $mreplies - $tmpb )
                      ) . qq~"><span class="small">$tmpa</span></a>\n~;
                    ++$tmpa;
                }
            }
            $pages =~ s/\n\Z//xsm;
            $pages =
qq~<br /><span class="small">&#171; $messageindex_txt{'139'} $pages $pagesall &#187;</span>~;
        }

        # build number of views
        my $views = ${$mnum}{'views'} ? ${$mnum}{'views'} - 1 : 0;
        $lastposter = ${$mnum}{'lastposter'};
        if ( $lastposter =~ m{\AGuest-(.*)}xsm ) {
            $lastposter = $1 . " ($maintxt{'28'})";
        }
        else {
            LoadUser($lastposter);
            if (
                (
                       ${ $uid . $lastposter }{'regdate'}
                    && ${$mnum}{'lastpostdate'} >
                    ${ $uid . $lastposter }{'regtime'}
                )
                || ${ $uid . $lastposter }{'position'} eq 'Administrator'
                || ${ $uid . $lastposter }{'position'} eq 'Global Moderator'
              )
            {
                if ( $iamguest) {
                    $lastposter = $format_unbold{$lastposter};
                }
                else {
                    $lastposter =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$lastposter}">$format_unbold{$lastposter}</a>~;
                }
            }
            else {

            # Need to load thread to see lastposters DISPLAYname if is Ex-Member
                fopen( EXMEMBERTHREAD, "$datadir/$mnum.txt" )
                  or fatal_error( 'cannot_open', "$datadir/$mnum.txt", 1 );
                my @x = <EXMEMBERTHREAD>;
                fclose(EXMEMBERTHREAD);
                $lastposter =
                  ( split /\|/xsm, $x[-1], 3 )[1]
                  . " - $messageindex_txt{'470a'}";
            }
        }
        $lastpostername = $lastposter || $messageindex_txt{'470'};

        if ( ( $stkynum && ( $counter >= $stkynum ) ) && ( $stkyshowed < 1 ) ) {
            $nonstickyheader =~ s/{yabb colspan}/$colspan/gsm;
            $tmptempbar .= $nonstickyheader;
            $stkyshowed = 1;
        }

# Check if the thread contains attachments and create a paper-clip icon if it does
        my $alt =
            $attachments{$mnum} == 1
          ? $messageindex_txt{'5'}
          : $messageindex_txt{'4'};
        $temp_attachment =
          $attachments{$mnum}
          ? (
            ( $guest_media_disallowed && $iamguest )
            ? qq~<img src="$micon_bg{'paperclip'}" alt="$messageindex_txt{'3'} $attachments{$mnum} $alt" title="$messageindex_txt{'3'} $attachments{$mnum} $alt" />~
            : $msg_attach_win
              . qq~<img src="$micon_bg{'paperclip'}" alt="$messageindex_txt{'3'} $attachments{$mnum} $alt" title="$messageindex_txt{'3'} $attachments{$mnum} $alt" /></a>~
          )
          : q{};
        $temp_attachment =~ s/{yabb mnum}/$mnum/sm;

        $mcount++;

        # Print the thread info.
        $mydate = timeformat($mdate);
        if (
            (
                   ( $iamadmin && $adminview == 3 )
                || ( $iamgmod && $gmodview == 3 )
                || ( $iamfmod && $fmodview == 3 )
                || (   $iammod
                    && $modview == 3
                    && !$iamadmin
                    && !$iamgmod
                    && !$iamfmod )
            )
            && $sessionvalid == 1
          )
        {
            if ( $currentboard eq $annboard ) {
                $adminbar = qq~
        <input type="checkbox" name="lockadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="hideadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="moveadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="deleteadmin$mcount" class="windowbg" value="$mnum" />
        ~;
            }
            elsif ( $counter < $numanns ) {
                $adminbar = q~&nbsp;~;
            }
            else {
                $adminbar = qq~
        <input type="checkbox" name="lockadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="stickadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="hideadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="moveadmin$mcount" class="windowbg" value="$mnum" />
        <input type="checkbox" name="deleteadmin$mcount" class="windowbg" value="$mnum" />
        ~;
            }
            $admincol = $admincolumn;
            $admincol =~ s/{yabb admin}/$adminbar/gsm;
        }
        elsif (
            (
                   ( $iamadmin && $adminview == 2 )
                || ( $iamgmod && $gmodview == 2 )
                || ( $iamfmod && $fmodview == 2 )
                || (   $iammod
                    && $modview == 2
                    && !$iamadmin
                    && !$iamgmod
                    && !$iamfmod )
            )
            && $sessionvalid == 1
          )
        {
            if ( $currentboard ne $annboard && $counter < $numanns ) {
                $adminbar = q~&nbsp;~;
            }
            else {
                $adminbar =
qq~<input type="checkbox" name="admin$mcount" class="windowbg" value="$mnum" />~;
            }
            $admincol = $admincolumn;
            $admincol =~ s/{yabb admin}/$adminbar/gsm;
        }
        elsif (
            (
                   ( $iamadmin && $adminview == 1 )
                || ( $iamgmod && $gmodview == 1 )
                || ( $iamfmod && $fmodview == 1 )
                || (   $iammod
                    && $modview == 1
                    && !$iamadmin
                    && !$iamgmod
                    && !$iamfmod )
            )
            && $sessionvalid == 1
          )
        {
            if ( $currentboard eq $annboard ) {
                $adminbar = qq~
        <a href="$scripturl?action=lock;thread=$mnum;tomessageindex=1"><img src="$micon_bg{'announcementlock'}" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}"  /></a>&nbsp;
        <a href="$scripturl?action=hide;thread=$mnum;tomessageindex=1"><img src="$micon_bg{'hide'}" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}"  /></a>&nbsp;
        <a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$mnum;oldposts=all;leave=0;newcat=${$uid.$currentboard}{'cat'};newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))"><img src="$micon_bg{'admin_move'}" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}"  /></a>&nbsp;
        <a href="$scripturl?action=removethread;thread=$mnum" onclick="return confirm('$messageindex_txt{'162'}')"><img src="$micon_bg{'admin_rem'}" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}"  /></a>
        ~;
            }
            elsif ( $counter < $numanns ) {
                $adminbar = q~&nbsp;~;
            }
            else {
                $adminbar = qq~
        <a href="$scripturl?action=lock;thread=$mnum;tomessageindex=1"><img src="$micon_bg{'locked'}" alt="$messageindex_txt{'104'}" title="$messageindex_txt{'104'}"  /></a>&nbsp;
        <a href="$scripturl?action=sticky;thread=$mnum"><img src="$micon_bg{'sticky'}" alt="$messageindex_txt{'781'}" title="$messageindex_txt{'781'}"  /></a>&nbsp;
        <a href="$scripturl?action=hide;thread=$mnum;tomessageindex=1"><img src="$micon_bg{'hide'}" alt="$messageindex_txt{'844'}" title="$messageindex_txt{'844'}"  /></a>&nbsp;
        <a href="javascript:void(window.open('$scripturl?action=split_splice;board=$currentboard;thread=$mnum;oldposts=all;leave=0;newcat=${$uid.$currentboard}{'cat'};newboard=$currentboard;position=end','_blank','width=800,height=650,scrollbars=yes,resizable=yes,menubar=no,toolbar=no,top=150,left=150'))"><img src="$micon_bg{'admin_move'}" alt="$messageindex_txt{'132'}" title="$messageindex_txt{'132'}"  /></a>&nbsp;
        <a href="$scripturl?action=removethread;thread=$mnum" onclick="return confirm('$messageindex_txt{'162'}')"><img src="$micon_bg{'admin_rem'}" alt="$messageindex_txt{'54'}" title="$messageindex_txt{'54'}"  /></a>
        ~;
            }
            $admincol = $admincolumn;
            $admincol =~ s/{yabb admin}/$adminbar/gsm;
        }

        $msub = Censor($msub);
        ToChars($msub);
        if ( !$movedFlag ) {
            if ( $enabletopichover && !$messagelist && ( ${ $uid . $username }{'topicpreview'} || $iamguest ) ) {
                fopen( MNUM, "$datadir/$mnum.txt" );
                my $thetopic = <MNUM>;
                fclose(MNUM);
                my $themessage = ( split /\|/xsm, $thetopic )[8];
                $clip          = 0;
                $msglength     = 200;
                $testlength    = 0;
                $pretextlength = 0;
                FromHTML($themessage);
                $themessage =~ s~\[img\].*?\[\/img\]~[b][$messageindex_tp{'image_tp'}][/b]~igsm;
                $themessage =~ s~\[media].*?\[/media]~[b][$messageindex_tp{'media_tp'}][/b]~igsm;
                $themessage =~ s~\[code(.*?)].*?\[/code]~[b][XCODE$1][/b]~igsm;
                $themessage =~ s/<br>/<br \/>/igsm;
                $themessage =~ s/(<br \/>){2,}/<br \/>/igsm;
                $themessage =~ s/^<br \/>//igsm;

                *fixtags = sub {
                    ( $tmpmessage, $pretext, $pretag, $tagtext, $posttag ) = @_;
                    $testmessage = $tmpmessage;
                    $testmessage =~ s/\[.*?\]//gsm;
                    $testmessage =~ s/\<.*?\>//gsm;
                    $testlength    = length $testmessage;
                    $pretextlength = length $pretext;
                    $pretext =~ s/\[(.*?\])/|$1/gsm;
                    $pretag  =~ s/\[/|/sm;
                    $tagtext =~ s/\[(.*?\])/|$1/gsm;
                    $posttag =~ s/\[/|/sm;

                    if ( $pretextlength > $msglength ) {
                        return $pretext;
                    }
                    if ( $testlength > $msglength ) {
                        $clip        = 1;
                        $lgtagtxtrem = ( $msglength - $pretextlength ) - 3;
                        $tagtextrem  = substr $tagtext, 0, $lgtagtxtrem;
                        $msglength += ( length($tmpmessage) - $testlength );
                        return
                            $pretext
                          . $pretag
                          . $tagtextrem . '...'
                          . $posttag;
                    }
                    $msglength += ( length($tmpmessage) - $testlength );
                    return $pretext . $pretag . $tagtext . $posttag;
                };

                while ($testlength < $msglength
                    && $themessage =~
s/^((.*?)(\[(\w+?)[\s|\=]*(.*?)\])(.*?)(\[\/\4\]))/ fixtags($1,$2,$3,$6,$7) /eisgm
                  )
                {
                }
                $themessage =~ s/\|(.*?\])/[$1/gsm;
                $themessage = substr $themessage, 0, $msglength;
                if ( length($themessage) > ( $msglength - 1 ) && !$clip ) {
                    $themessage .= '...';
                }
                $message     = $themessage;
                $displayname = ${ $uid . $musername }{'realname'};
                wrap();
                if ($enable_ubbc) {
                    if ( !$yyYaBBCloaded ) { require Sources::YaBBC; }
                    DoUBBC();
                }
                wrap2();
                $themessage = $message;
                $message    = q{};
                ToChars($themessage);
                $themessage =~ s/XCODE/$messageindex_tp{'code_tp'}/gsm;

                $themessage = Censor($themessage);
                my $topicsum =
qq~<div class="windowbg2 topic-hover" id="$mnum">$themessage</div>~;

                if ( ${$mnum}{'board'} eq $annboard ) {
                    $msublink =
qq~<a href="$scripturl?virboard=$currentboard;num=$mnum" onmouseover="topicSum(event, '$mnum')" onmouseout="hidetopicSum('$mnum')" onclick="hidetopicSum('$mnum')">$msub</a>$topicsum<div style="float: right; font-size: xx-small;">$stickdir</div>~;
                }
                else {
                    $msublink =
qq~<a href="$scripturl?num=$mnum" onmouseover="topicSum(event, '$mnum')" onmouseout="hidetopicSum('$mnum')" onclick="hidetopicSum('$mnum')">$msub</a>$topicsum<div style="float:right; font-size:xx-small">$stickdir</div>~;
                }
            }
            else {
                if ( ${$mnum}{'board'} eq $annboard ) {
                    $msublink =
qq~<a href="$scripturl?virboard=$currentboard;num=$mnum">$msub</a><div style="float:right; font-size:xx-small">$stickdir</div>~;
                }
                else {
                     $msublink = qq~<a href="$scripturl?num=$mnum">$msub</a><div style="float:right; font-size:xx-small">$stickdir</div>~;
                }
            }
        }
        elsif ( $movedFlag < 100 ) {
            Split_Splice_Move( $msub, 0 );
            $msublink = qq~$msub<br /><span class="small">$movedSubject</span>~;
        }
        else {
            $msub =~ /^(Re: )?\[m.*?\]: '(.*)'/sm;

            $msublink =
qq~$maintxt{'758'}: '<a href="$scripturl?num=$movedFlag">$2</a>'<br /><span class="small">$movedSubject</span>~;
        }

        my $mydate  = timeformat($mdate);
        my $thicon  = $micon{$threadclass};
        my $tempbar = $movedFlag ? $threadbarMoved : $threadbar;
        $tempbar =~ s/{yabb admin column}/$admincol/gsm;
        $tempbar =~ s/{yabb threadpic}/$thicon/gsm;
        $tempbar =~ s/{yabb icon}/$micon/gsm;
        $tempbar =~ s/{yabb new}/$new/gsm;
        $tempbar =~ s/{yabb poll}/$mpoll/gsm;
        $tempbar =~ s/{yabb favorite}/ ($favicon{$mnum} ? qq~$micon{'addfav'}~ : q{}) /egsm;
        $tempbar =~ s/{yabb subjectlink}/$msublink/gsm;
        $tempbar =~ s/{yabb attachmenticon}/$temp_attachment/gsm;
        $tempbar =~ s/{yabb pages}/$pages/gsm;
        $tempbar =~ s/{yabb starter}/$mname/gsm;
        $tempbar =~ s/{yabb starttime}/ timeformat($mnum,0,0,0,1)/egsm;
        $tempbar =~ s/{yabb replies}/ NumberFormat($mreplies) /egsm;
        $tempbar =~ s/{yabb views}/ NumberFormat($views) /egsm;
        $tempbar =~ s/{yabb lastpostlink}/<a href="$scripturl?num=$mnum\/$mreplies#$mreplies">$img{'lastpost'} $mydate<\/a>/gsm;
        $tempbar =~ s/{yabb lastposter}/$lastpostername/gsm;
        $tempbar =~ s/{yabb altthdcolor}/$altthdcolor/gsm;

        if ( $accept_permalink == 1 ) {
            $tempbar =~ s/{yabb permalink}/$message_permalink/gsm;
        }
        else {
            $tempbar =~ s/{yabb permalink}//gsm;
        }
        $tmptempbar .= $tempbar;
        $counter++;
    }

# Put a "no messages" message if no threads exist - just a  bit more friendly...
    if ( !$tmptempbar ) {
        $tmptempbar = $brd_tmptempbar;
        $tmptempbar =~ s/{yabb colspan}/$colspan/sm;
    }

    $multiview = 0;
    my $tmptempfooter;
    if (
        (
               ( $iamadmin && $adminview == 3 )
            || ( $iamgmod && $gmodview == 3 )
            || ( $iamfmod && $fmodview == 3 )
            || (   $iammod
                && $modview == 3
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        $multiview = 3;
    }
    elsif (
        (
               ( $iamadmin && $adminview == 2 )
            || ( $iamgmod && $gmodview == 2 )
            || ( $iamfmod && $fmodview == 2 )
            || (   $iammod
                && $modview == 2
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        $multiview = 2;
    }

    if ( $multiview >= 2 ) {
        my $boardlist = moveto();
        if ( $multiview eq '3' ) {
            $tempfooter    = $subfooterbar;
            $adminselector = qq~
                <label for="toboard">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" ondblclick="alert('$messageindex_txt{200}')" /> <select name="toboard" id="toboard" onchange="NoPost(this.selectedIndex)">$boardlist</select><input type="submit" value="$messageindex_txt{'462'}" class="button" />
            ~;
            if ( $currentboard eq $annboard ) {
                $admincheckboxes = qq~
                <input type="checkbox" name="lockall" value="" class="titlebg" onclick="if (this.checked) checkAll(1); else uncheckAll(1);" />
                <input type="checkbox" name="hideall" value="" class="titlebg" onclick="if (this.checked) checkAll(2); else uncheckAll(2);" />
                <input type="checkbox" name="moveall" value="" class="titlebg" onclick="if (this.checked) checkAll(3); else uncheckAll(3);" />
                <input type="checkbox" name="deleteall" value="" class="titlebg" onclick="if (this.checked) checkAll(4); else uncheckAll(4);" />
                <input type="hidden" name="fromboard" value="$currentboard" />
            ~;
            }
            else {
                $admincheckboxes = qq~
                <input type="checkbox" name="lockall" value="" class="titlebg" onclick="if (this.checked) checkAll(1); else uncheckAll(1);" />
                <input type="checkbox" name="stickall" value="" class="titlebg" onclick="if (this.checked) checkAll(2); else uncheckAll(2);" />
                <input type="checkbox" name="hideall" value="" class="titlebg" onclick="if (this.checked) checkAll(3); else uncheckAll(3);" />
                <input type="checkbox" name="moveall" value="" class="titlebg" onclick="if (this.checked) checkAll(4); else uncheckAll(4);" />
                <input type="checkbox" name="deleteall" value="" class="titlebg" onclick="if (this.checked) checkAll(5); else uncheckAll(5);" />
                <input type="hidden" name="fromboard" value="$currentboard" />
            ~;
            }
            $tempfooter =~ s/{yabb admin selector}/$adminselector/gsm;
            $tempfooter =~
              s/{yabb admin checkboxes}/$admincheckboxes/gsm;
        }
        elsif ( $multiview eq '2' ) {
            $tempfooter = $subfooterbar;
            if ( $currentboard eq $annboard ) {
                $adminselector = qq~
                <input type="radio" name="multiaction" id="multiactionlock" value="lock" class="titlebg" /> <label for="multiactionlock">$messageindex_txt{'104'}</label>
                <input type="radio" name="multiaction" id="multiactionhide" value="hide" class="titlebg" /> <label for="multiactionhide">$messageindex_txt{'844'}</label>
                <input type="radio" name="multiaction" id="multiactiondelete" value="delete" class="titlebg" /> <label for="multiactiondelete">$messageindex_txt{'31'}</label>
                <input type="radio" name="multiaction" id="multiactionmove" value="move" class="titlebg" /> <label for="multiactionmove">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" ondblclick="alert('$messageindex_txt{200}')" />
                <select name="toboard" id="toboard" onchange="NoPost(this.selectedIndex); document.multiadmin.multiaction[3].checked=true;">$boardlist</select>
                <input type="hidden" name="fromboard" value="$currentboard" />
                <input type="submit" value="$messageindex_txt{'462'}" class="button" />
            ~;
            }
            else {
                $adminselector = qq~
                <input type="radio" name="multiaction" id="multiactionlock" value="lock" class="titlebg" /> <label for="multiactionlock">$messageindex_txt{'104'}</label>
                <input type="radio" name="multiaction" id="multiactionstick" value="stick" class="titlebg" /> <label for="multiactionstick">$messageindex_txt{'781'}</label>
                <input type="radio" name="multiaction" id="multiactionhide" value="hide" class="titlebg" /> <label for="multiactionhide">$messageindex_txt{'844'}</label>
                <input type="radio" name="multiaction" id="multiactiondelete" value="delete" class="titlebg" /> <label for="multiactiondelete">$messageindex_txt{'31'}</label>
                <input type="radio" name="multiaction" id="multiactionmove" value="move" class="titlebg" /> <label for="multiactionmove">$messageindex_txt{'133'}</label>: <input type="checkbox" name="newinfo" value="1" title="$messageindex_txt{199}" class="titlebg" ondblclick="alert('$messageindex_txt{200}')" />
                <select name="toboard" id="toboard" onchange="NoPost(this.selectedIndex); document.multiadmin.multiaction[4].checked=true;">$boardlist</select>
                <input type="hidden" name="fromboard" value="$currentboard" />
                <input type="submit" value="$messageindex_txt{'462'}" class="button" />
            ~;
            }
            $admincheckboxes = q~
                <input type="checkbox" name="checkall" id="checkall" value="" class="titlebg" onclick="if (this.checked) checkAll(0); else uncheckAll(0);" />
            ~;
            $tempfooter =~ s/{yabb admin selector}/$adminselector/gsm;
            $tempfooter =~
              s/{yabb admin checkboxes}/$admincheckboxes/gsm;
        }
        $tmptempfooter = $subfooterbar;
        $tmptempfooter =~ s/{yabb admin selector}/$adminselector/gsm;
        $tmptempfooter =~
          s/{yabb admin checkboxes}/$admincheckboxes/gsm;
    }

    if ( !$messagelist ) {
        $yabbicons = qq~
    $micon{'thread'} $messageindex_txt{'457'}<br />
    $micon{'sticky'} $messageindex_txt{'779'}<br />
    $micon{'locked'} $messageindex_txt{'456'}<br />
    $micon{'stickylock'} $messageindex_txt{'780'}<br />
    $micon{'locked_moved'} $messageindex_txt{'845'}<br />
~;
        if ( ($staff)
            && $sessionvalid == 1 )
        {
            $yabbadminicons = qq~
    $micon{'hide'} $messageindex_txt{'458'}<br />
    $micon{'hidesticky'} $messageindex_txt{'459'}<br />
    $micon{'hidelock'} $messageindex_txt{'460'}<br />
    $micon{'hidestickylock'} $messageindex_txt{'461'}<br />~;
        }
        $yabbadminicons .= qq~
    $micon{'announcement'} $messageindex_txt{'779a'}<br />
    $micon{'announcementlock'} $messageindex_txt{'779b'}<br />
    $micon{'hotthread'} $messageindex_txt{'454'} $HotTopic $messageindex_txt{'454a'}<br />
    $micon{'veryhotthread'} $messageindex_txt{'455'} $VeryHotTopic $messageindex_txt{'454a'}<br />
~;

        LoadAccess();
    }

    #template it
    $messageindex_template =~ s/{yabb board}/$boardlink/gsm;
    $template_mods = qq~$modslink$showmodgroups~;
    if ($iamadmin) {
        require Sources::AddModerators;
        ModSearch();
        $template_mods .=
qq~<br /><a href="javascript:void(0);" onclick="ModSettings()"><span class="small">$addmod_txt{'modsearch'}</span></a>~;
    }

    my ( $rss_link, $rss_text );
    if ( !$rss_disabled ) {
        $rss_link =
qq~<a href="$scripturl?action=RSSboard;board=$currentboard" target="_blank"><img src="$micon_bg{'rss'}"  alt="$maintxt{'rssfeed'}" title="$maintxt{'rssfeed'}" /></a>~;
        $rss_text =
qq~<a href="$scripturl?action=RSSboard;board=$INFO{'board'}" target="_blank">$messageindex_txt{843}</a>~;
    }
    $yyrssfeed = $rss_text;
    $yyrss     = $rss_link;
    $messageindex_template =~ s/{yabb rssfeed}/$rss_text/gsm;
    $messageindex_template =~ s/{yabb rss}/$rss_link/gsm;

    $messageindex_template =~ s/{yabb home}/$homelink/gsm;
    $messageindex_template =~ s/{yabb category}/$catlink/gsm;
    $messageindex_template =~ s/{yabb board}/$boardlink/gsm;
    $messageindex_template =~ s/{yabb moderators}/$template_mods/gsm;
    if ($enabletopichover) {
        if ( !$iamguest && !$INFO{'messagelist'} ) {
            if ( ${ $uid . $username }{'topicpreview'} ) {
                $enab_topicprev =
qq~<a href="$scripturl?board=$INFO{'board'};start=$start;action=topicpreview;todo=disable"><img src="$imagesdir/$hoveroff" alt="$messageindex_tp{'disabletp'}" title="$messageindex_tp{'disabletp'}" /><br /></a>~;
            }
            else {
                $enab_topicprev =
qq~<a href="$scripturl?board=$INFO{'board'};start=$start;action=topicpreview;todo=enable"><img src="$imagesdir/$hoveron" alt="$messageindex_tp{'enabletp'}" title="$messageindex_tp{'enabletp'}" /><br /></a>~;
            }
        }
    }
    else {
        $enab_topicprev = q{};
    }
    $messageindex_template =~ s/{yabb topicpreview}/$enab_topicprev/gsm;
    $messageindex_template =~ s/{yabb sortsubject}/$sort_subject/gsm;
    $messageindex_template =~ s/{yabb sortstarter}/$sort_starter/gsm;
    $messageindex_template =~ s/{yabb sortanswer}/$sort_answer/gsm;
    $messageindex_template =~
      s/{yabb sortlastpostim}/$sort_lastpostim/gsm;

    if ($ShowBDescrip) {
        if ( $bdescrip ne q{} ) {
            ToChars($bdescrip);
            $boarddescription =~
              s/{yabb boarddescription}/$bdescrip/gsm;
            $messageindex_template =~
              s/{yabb description}/$boarddescription/gsm;
        }
        else {
            $messageindex_template =~ s/{yabb description}//gsm;
        }
    }
    $bdpic = qq~$imagesdir/boards.$bdpicExt~;
    fopen( BRDPIC, "<$boardsdir/brdpics.db" );
    my @brdpics = <BRDPIC>;
    fclose( BRDPIC);
    chomp @brdpics;
    for (@brdpics) {
        my ( $brdnm, $style, $brdpic ) = split /[|]/xsm, $_;
        if ( $brdnm eq $currentboard && $usestyle eq $style) {
            if ( $brdpic =~ /\//ism ) {
                $bdpic = $brdpic;
            }
            elsif ( -e "$htmldir/Templates/Forum/$useimages/Boards/$brdpic" ) {
                $bdpic = qq~$imagesdir/Boards/$brdpic~;
            }
        }
    }
    if ( ${ $uid . $currentboard }{'ann'} == 1 ) {
        $bdpic = qq~$imagesdir/ann.$bdpicExt~;
    }
    if ( ${ $uid . $currentboard }{'rbin'} == 1 ) {
        $bdpic = qq~$imagesdir/recycle.$bdpicExt~;
    }

    $bdpic =
qq~ <img src="$bdpic" alt="$curboardname" title="$curboardname" id="brd_img_resize" /> ~;

    $messageindex_template =~ s/{yabb bdpicture}/$bdpic/gsm;
    my $tmpthreadcount = NumberFormat( ${ $uid . $currentboard }{'threadcount'} );
    my $tmpmessagecount = NumberFormat( ${ $uid . $currentboard }{'messagecount'} );
    $messageindex_template =~ s/{yabb threadcount}/$tmpthreadcount/gsm;
    $messageindex_template =~ s/{yabb messagecount}/$tmpmessagecount/gsm;
    $messageindex_template =~ s/{yabb new_load}/$newload/gsm;

    $messageindex_template =~ s/{yabb colspan}/$colspan/gsm;
    ### Board Rules Start ###
    if ( ${ $uid . $currentboard }{'rules'} == 1 ) {
        ToChars( ${ $uid . $currentboard }{'rulestitle'} );
        ToChars( ${ $uid . $currentboard }{'rulesdesc'} );
        $tmpruletxt = qq~${$uid.$currentboard}{'rulesdesc'}~;

        if ( !$iamguest && ${ $uid . $currentboard }{'rulescollapse'} == 1 ) {
            $tmprulelgt = length( ${ $uid . $currentboard }{'rulesdesc'} );
            $rulestitle =
qq~<img src="$imagesdir/$newload{'brd_col'}" id="bdrulecollapse" alt="$boardindex_exptxt{'2'}" title="$boardindex_exptxt{'2'}" class="cursor" onclick="collapseBDrule($tmprulelgt);" />~;
            my @collbdrules =
              split /\|/xsm, ${ $uid . $username }{'collapsebdrules'};
            for my $i ( 0 .. ( @collbdrules - 1 ) ) {
                ( $rulebd, $rulelgt ) = split /,/xsm, $collbdrules[$i];
                if ( $rulebd eq $currentboard && $rulelgt == $tmprulelgt ) {
                    $tmpruletxt = qq~$messageindex_txt{'collruletext'}~;
                    $rulestitle =
qq~<img src="$imagesdir/$newload{'brd_exp'}" id="bdrulecollapse" alt="$boardindex_exptxt{'1'}" title="$boardindex_exptxt{'1'}" class="cursor" onclick="collapseBDrule($tmprulelgt);" />~;
                }
            }
        }

        $rulestitle .= qq~&nbsp;${$uid.$currentboard}{'rulestitle'}~;
        $rulesdesc = qq~<div id="bdruledesc">$tmpruletxt</div>~;

        if ( !$iamguest && ${ $uid . $currentboard }{'rulescollapse'} == 1 ) {
            $mycat_col = $newload{'brd_col'};
            $mycat_exp = $newload{'brd_exp'};
            $rulesdesc .= qq~
            <textarea id="actruletxt" name="actruletxt" rows="1" cols="1" style="display: none;">${$uid.$currentboard}{'rulesdesc'}</textarea>
            <input type="hidden" id="tmpruletxt" value="$messageindex_txt{'collruletext'}" />
            <script type="text/javascript">
            function collapseBDrule(rulelgt) {
                var tmpruletxt = document.getElementById('tmpruletxt').value;
                var actruletxt = document.getElementById('actruletxt').value;
                if (document.getElementById("bdruledesc").innerHTML == tmpruletxt) linkdesclg = 1;
                else linkdesclg = rulelgt;
                var thisboard = "$currentboard";
                var doexpand = "$boardindex_exptxt{'1'}";
                var docollaps = "$boardindex_exptxt{'2'}";
                if (document.getElementById("bdruledesc").innerHTML == tmpruletxt) {
                    document.getElementById("bdruledesc").innerHTML = actruletxt;
                    document.getElementById('bdrulecollapse').src = "$imagesdir/$mycat_col";
                    document.getElementById('bdrulecollapse').alt = docollaps;
                    document.getElementById('bdrulecollapse').title = docollaps;
                }
                else {
                    document.getElementById("bdruledesc").innerHTML = tmpruletxt;
                    document.getElementById('bdrulecollapse').src="$imagesdir/$mycat_exp";
                    document.getElementById('bdrulecollapse').alt = doexpand;
                    document.getElementById('bdrulecollapse').title = doexpand;
                }
                var url = '$scripturl?action=bdrulecoll&rulebd=' + thisboard + '&rulelg=' + linkdesclg;
                GetXmlHttpObject();
                if (xmlHttp === null) return;
                xmlHttp.open("GET",url,true);
                xmlHttp.send(null);
            }
            </script>
            ~;
        }

        $messageindex_template =~ s/{yabb rulestitle}/$rulestitle/gsm;
        $messageindex_template =~
          s/{yabb rulesdescription}/$rulesdesc/gsm;
    }
    ### Board Rules End ###

    $tool_sep = $useThreadtools ? q{|||} : q{};

    $topichandellist =~
      s/{yabb notify button}/$notify_board$tool_sep/gsm;
    $topichandellist =~
      s/{yabb markall button}/$markalllink$tool_sep/gsm;
    $topichandellist =~ s/{yabb new post button}/$postlink$tool_sep/gsm;
    $topichandellist =~ s/{yabb new poll button}/$polllink$tool_sep/gsm;
    $topichandellist =~ s/\Q$menusep//ixsm;

    @threadin = ( "$notify_board","$markalllink","$postlink","$polllink",);
    @threadout = ();
    my $sepcn = 0;
    for (@threadin) {
        if ($_ ) {
           if ( !$useThreadtools ) { $threadout[$sepcn] = "$_$my_ttsep";}
           else  { $threadout[$sepcn] = "$my_ttsep$_"; }
        }
        else  { $threadout[$sepcn] = q{}; }
        $sepcn++;
    }

    $outside_threadtools =~
      s/{yabb notify button}/$threadout[0]/gsm;
    $outside_threadtools =~
      s/{yabb markall button}/$threadout[1]/gsm;
    $outside_threadtools =~
      s/{yabb new post button}/$threadout[2]/gsm;
    $outside_threadtools =~
      s/{yabb new poll button}/$threadout[3]/gsm;
## Mod Hook outside_threadtools ##
    if ( $my_ttsep ne q{ } ) {
        $outside_threadtools =~ s/\Q$my_ttsep//ixsm;
    }

    if ( !$useThreadtools ) {
        if ( $menusep ne q{ } ) {
            $outside_threadtools =~ s/\Q$menusep//ixsm;
        }
        $topichandellist     = $outside_threadtools . $topichandellist;
        $outside_threadtools = q{};
    }
    else {
        $outside_threadtools =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$tmpimg{$1}/gsm;
        $topichandellist     =~ s/\[tool=(.+?)\](.+?)\[\/tool\]/$2/gsm;
    }

    $topichandellist2 = $topichandellist;

    # Thread Tools #
    if ($useThreadtools) {
        $dropid = q{};
        if ($messagelist) { $dropid = $INFO{'board'}; }
        $topichandellist2 = MakeTools( "bottom$dropid", $maintxt{'62'}, $topichandellist2 );
        $topichandellist = MakeTools( "top$dropid", $maintxt{'62'}, $topichandellist );
    }

    $messageindex_template =~
      s/{yabb outsidethreadtools}/$outside_threadtools/gsm;
    $messageindex_template =~
      s/{yabb topichandellist}/$topichandellist/gsm;
    $messageindex_template =~
      s/{yabb topichandellist2}/$topichandellist2/gsm;
    $messageindex_template =~ s/{yabb pageindex top}/$pageindex1/gsm;
    $messageindex_template =~ s/{yabb pageindex bottom}/$pageindex2/gsm;

    if (
        (
               ( $iamadmin && $adminview == 3 )
            || ( $iamgmod && $gmodview == 3 )
            || ( $iamfmod && $fmodview == 3 )
            || (   $iammod
                && $modview == 3
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        $messageindex_template =~
          s/{yabb admin column}/$adminheader/gsm;
    }
    elsif (
        (
               ( $iamadmin && $adminview != 0 )
            || ( $iamgmod && $gmodview != 0 )
            || ( $iamfmod && $fmodview != 0 )
            || (   $iammod
                && $modview != 0
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        $messageindex_template =~
          s/{yabb admin column}/$adminheader/gsm;
    }
    else {
        $messageindex_template =~ s/{yabb admin column}//gsm;
    }

    if (
        (
               ( $iamadmin && $adminview >= 2 )
            || ( $iamgmod && $gmodview >= 2 )
            || ( $iamfmod && $fmodview >= 2 )
            || (   $iammod
                && $modview >= 2
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        if ( !$messagelist ) {
            $formstart =
qq~<form name="multiadmin" action="$scripturl?board=$currentboard;action=multiadmin" method="post" style="display: inline">~;
        }
        else {
            $formstart = qq~
            <form name="multiadmin$currentboard" id="multiadmin$currentboard" action="$scripturl?board=$currentboard;action=multiadmin" method="post" style="display: inline">
            <input type="hidden" name="formsession" value="$formsession" />
            ~;
        }
        $formend =
qq~<input type="hidden" name="allpost" value="$INFO{'start'}" /></form>~;
        $messageindex_template =~ s/{yabb modupdate}/$formstart/gsm;
        $messageindex_template =~ s/{yabb modupdateend}/$formend/gsm;
    }
    else {
        $messageindex_template =~ s/{yabb modupdate}//gsm;
        $messageindex_template =~ s/{yabb modupdateend}//gsm;
    }
    if ($tmpstickyheader) {
        $messageindex_template =~
          s/{yabb stickyblock}/$tmpstickyheader/gsm;
    }
    else {
        $messageindex_template =~ s/{yabb stickyblock}//gsm;
    }
    $messageindex_template =~ s/{yabb threadblock}/$tmptempbar/gsm;
    if ($tmptempfooter) {
        $messageindex_template =~
          s/{yabb adminfooter}/$tmptempfooter/gsm;
    }
    else {
        $messageindex_template =~ s/{yabb adminfooter}//gsm;
    }
    $messageindex_template =~ s/{yabb icons}/$yabbicons/gsm;
    $messageindex_template =~ s/{yabb admin icons}/$yabbadminicons/gsm;
    $messageindex_template =~
      s/{yabb access}/ $messagelist ? q{} : LoadAccess() /esm;

    # Show subboards
    if ( $subboard{$currentboard} ) {
        $show_subboards = 1;
        $subboard_sel   = $currentboard;
        require Sources::BoardIndex;
        $boardindex_template = BoardIndex();
    }

    $yymain .= qq~
    $boardindex_template
    $messageindex_template
    $pageindexjs
    <script type="text/javascript">
    function topicSum(e, topicsumm) {
        document.getElementById(topicsumm).style.display = 'block';
        var dheight = document.getElementById(topicsumm).offsetHeight;
        var dtop = document.all ? e.clientY + document.documentElement.scrollTop - (dheight + 30) : e.pageY - (dheight + 30);
        document.getElementById(topicsumm).style.top = dtop + 'px';
    }

    function hidetopicSum(topicsumm) {
        document.getElementById(topicsumm).style.display = 'none';
    }

    </script>
    ~;

    if (
        (
               ( $iamadmin && $adminview >= 2 )
            || ( $iamgmod && $gmodview >= 2 )
            || ( $iamfmod && $fmodview >= 2 )
            || (   $iammod
                && $modview >= 2
                && !$iamadmin
                && !$iamgmod
                && !$iamfmod )
        )
        && $sessionvalid == 1
      )
    {
        my $modul = $currentboard eq $annboard ? 4 : 5;

        if ( $sessionvalid == 1 ) {
            $yymain .= qq~
<script type="text/javascript">
    function checkAll(j) {
        for (var i = 0; i < document.multiadmin.elements.length; i++) {
            if (document.multiadmin.elements[i].type == "checkbox" && !(/all\$/).test(document.multiadmin.elements[i].name) && (j === 0 || (j !== 0 && (i % $modul) == (j - 1))))
                document.multiadmin.elements[i].checked = true;
        }
    }
    function uncheckAll(j) {
        for (var i = 0; i < document.multiadmin.elements.length; i++) {
            if (document.multiadmin.elements[i].type == "checkbox" && !(/all\$/).test(document.multiadmin.elements[i].name) && (j === 0 || (j !== 0 && (i % $modul) == (j - 1))))
                document.multiadmin.elements[i].checked = false;
        }
    }
</script>\n~;
        }
    }

    $yyjavascript .=
qq~\nvar markallreadlang = '$messageindex_txt{'500'}';\nvar markfinishedlang = '$messageindex_txt{'500a'}';~;
    $yymain .= qq~
<script type="text/javascript">
    function ListPages(tid) { window.open('$scripturl?action=pages;num='+tid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
    function ListPages2(bid,cid) { window.open('$scripturl?action=pages;board='+bid+';count='+cid, '', 'menubar=no,toolbar=no,top=50,left=50,scrollbars=yes,resizable=no,width=400,height=300'); }
</script>
    ~;

    # Make browsers aware of our RSS
    if ( !$rss_disabled && $INFO{'board'} )
    {    # Check to see if we're on a real board, not announcements
        $yyinlinestyle .=
qq~    <link rel="alternate" type="application/rss+xml" title="$messageindex_txt{'843'}" href="$scripturl?action=RSSboard;board=$INFO{'board'}" />~;
    }

    if ( !$messagelist ) {
        $yynavback =
          qq~$tabsep <a href="$scripturl">&lsaquo; $img_txt{'103'}</a> &nbsp; ~;
        $yynavigation = qq~&rsaquo; $catlink$boardtree~;
        $yytitle      = $curboardname;

        if ( $postlink && $enable_quickpost && !$mindex_postpopup ) {
            $yymain =~
s/(<!-- Icon and access info end -->)/$1\n<div class="q_post_space">{yabb forumjump}<\/div>/sm;
            require Sources::Post;
            $action        = 'post';
            $INFO{'title'} = 'StartNewTopic';
            $Quick_Post    = 1;
            Post();
        }
        template();
    }
    else {
        print "Content-type: text/html; charset=$yymycharset\n\n"
          or croak "$croak{'print'} content-type";
        print qq~
        $messageindex_template
        $pageindexjs
        ~ or croak "$croak{'print'} content";
        CORE::exit;    # This is here only to avoid server error log entries!
    }
    return;
}

sub collapse_bdrule {
    $tmpboardrules = q{};
    my @tmpbdrule = split /\|/xsm, ${ $uid . $username }{'collapsebdrules'};
    for my $i ( 0 .. ( @tmpbdrule - 1 ) ) {
        my ( $tmrulebd, $tmrulelgt ) = split /,/xsm, $tmpbdrule[$i];
        if ( $tmrulebd ne $INFO{'rulebd'} ) {
            $tmpboardrules .= qq~$tmpbdrule[$i]|~;
        }
    }
    if ( $INFO{'rulelg'} > 1 ) {
        $tmpboardrules .= qq~$INFO{'rulebd'},$INFO{'rulelg'}~;
    }
    $tmpboardrules =~ s/\|\Z//xsm;
    ${ $uid . $username }{'collapsebdrules'} = $tmpboardrules;
    UserAccount( $username, 'update' );
    $elenable = 0;
    croak q{};
    return;
}

sub MarkRead {    # Mark all threads in this board as read.
                  # Load the log file
    getlog();

    # Look for any threads marked unread in the current board and remove them
    fopen( BRDTXT, "$boardsdir/$currentboard.txt" )
      or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
    my @threadlist = map { /^(\d+)\|/xsm } <BRDTXT>;
    fclose(BRDTXT);

    # Loop through @threadlist and delete the corresponding item from %yyuserlog
    foreach (@threadlist) { delete $yyuserlog{"$_--unread"}; }

    # Write it out
    dumplog("$currentboard--mark");

    if ( $INFO{'oldmarkread'} ) {
        redirectinternal();
    }
    $elenable = 0;
    croak q{};    # This is here only to avoid server error log entries!
}

sub ListPages {
    my ( $pcount, $maxvalue, $tlink );
    if ( $INFO{'num'} ne q{} ) {
        $tlink    = $INFO{'num'};
        $pcount   = ${ $INFO{'num'} }{'replies'} + 1;
        $maxvalue = $maxmessagedisplay;
        $jcode    = 'num=';
    }
    if ( $INFO{'board'} ne q{} ) {
        $tlink    = $INFO{'board'};
        $pcount   = $INFO{'count'};
        $maxvalue = $maxdisplay;
        $jcode    = 'board=';
    }

    $tmpa = 1;
    foreach my $tmpb ( 0 .. ( $pcount - 1 ) ) {
        if ( $tmpb % $maxvalue == 0 ) {
            $pages .= qq~<a href='javascript: opp_page("$tlink","~
              . (
                ( !$ttsreverse || $INFO{'board'} )
                ? $tmpb
                : ( ${ $INFO{'num'} }{'replies'} - $tmpb )
              ) . qq~");'>$tmpa</a>\n~;
            ++$tmpa;
        }
    }
    $pages =~ s/\n\Z//xsm;

    print_output_header();
    get_template('MessageIndex');

    $output = $msg_listpages;
    $output =~ s/{yabb jcode}/$jcode/sm;
    $output =~ s/{yabb pages}/$pages/sm;

    print_HTML_output_and_finish();
    return;
}

sub MessagePageindex {
    my ( $msindx, $trindx, $mbindx, $pmindx ) =
      split /\|/xsm, ${ $uid . $username }{'pageindex'};
    if ( $INFO{'action'} eq 'messagepagedrop' ) {
        ${ $uid . $username }{'pageindex'} = qq~0|$trindx|$mbindx|$pmindx~;
    }
    elsif ( $INFO{'action'} eq 'messagepagetext' ) {
        ${ $uid . $username }{'pageindex'} = qq~1|$trindx|$mbindx|$pmindx~;
    }
    UserAccount( $username, 'update' );
    redirectinternal();
    return;
}

sub moveto {
    my (
        $boardlist,  $catid,     $board,   $boardname,
        $boardperms, $boardview, $brdlist, @bdlist,
        $catname,    $catperms,  $access
    );
    get_forum_master();

    *move_subboards = sub {
        my @x = @_;
        $indent += 2;
        foreach my $board (@x) {
            my $dash;
            if ( $indent > 0 ) { $dash = q{-}; }

            ( $boardname, $boardperms, $boardview ) =
              split /\|/xsm, $board{"$board"};
            ToChars($boardname);
            $access = AccessCheck( $board, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' ) { next; }
            my $bdnopost = q{};
            if ( $board ne $currentboard ) {
                $my_board = $board;
                if ( !${ $uid . $board }{'canpost'} && $subboard{$board} ) {
                    $alert    = qq~$messageindex_txt{'nopost'}~;
                    $bdnopost = qq~ class="nopost" onclick="alert('$alert')"~;
                    $my_board = q{};
                }
                $boardlist .=
                    qq~<option$bdnopost value="$my_board">~
                  . ( '&nbsp;' x $indent )
                  . ( $dash x ( $indent / 2 ) )
                  . qq~$boardname</option>\n~;
            }
            if ( $subboard{$board} ) {
                move_subboards( split /\|/xsm, $subboard{$board} );
            }
        }
        $indent -= 2;
    };

    foreach my $catid (@categoryorder) {
        $brdlist = $cat{$catid};
        if ( !$brdlist ) { next; }
        (@bdlist) = split /\,/xsm, $cat{$catid};

        #@bdlist = split(/\,/, $brdlist);
        ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};

        $access = CatAccess($catperms);
        if ( !$access ) { next; }
        ToChars($catname);
        $boardlist .= qq~<optgroup label="$catname">~;
        my $indent = -2;
        move_subboards(@bdlist);
        $boardlist .= q~</optgroup>~;
    }
    return $boardlist;
}

sub LoadAccess {
    my $yesaccesses .=
      "$load_txt{'805'} $load_txt{'806'} $load_txt{'808'}<br />";
    my $noaccesses = q{};

    # Reply Check
    my $rcaccess = AccessCheck( $currentboard, 2 ) || 0;
    if ( $rcaccess eq 'granted' ) {
        $yesaccesses .=
          "$load_txt{'805'} $load_txt{'806'} $load_txt{'809'}<br />";
    }
    else {
        $noaccesses .=
          "$load_txt{'805'} $load_txt{'807'} $load_txt{'809'}<br />";
    }

    # start new Topic Check
    if ( AccessCheck( $currentboard, 1 ) eq 'granted' ) {
        $yesaccesses .=
          "$load_txt{'805'} $load_txt{'806'} $load_txt{'810'}<br />";
    }
    else {
        $noaccesses .=
          "$load_txt{'805'} $load_txt{'807'} $load_txt{'810'}<br />";
    }

    # Attachments Check
    $allowattach ||= 0;
    if (
           AccessCheck( $currentboard, 4 ) eq 'granted'
        && $allowattach > 0
        && ${ $uid . $currentboard }{'attperms'} == 1
        && ( ( $allowguestattach == 0 && !$iamguest )
            || $allowguestattach == 1 )
      )
    {
        $yesaccesses .=
          "$load_txt{'805'} $load_txt{'806'} $load_txt{'813'}<br />";
    }
    else {
        $noaccesses .=
          "$load_txt{'805'} $load_txt{'807'} $load_txt{'813'}<br />";
    }

    # Poll Check
    if ( AccessCheck( $currentboard, 3 ) eq 'granted' ) {
        $yesaccesses .=
          "$load_txt{'805'} $load_txt{'806'} $load_txt{'811'}<br />";
    }
    else {
        $noaccesses .=
          "$load_txt{'805'} $load_txt{'807'} $load_txt{'811'}<br />";
    }

    # Zero Post Check
    if ( $username ne 'Guest' ) {
        if ( $INFO{'zeropost'} != 1 && $rcaccess eq 'granted' ) {
            $yesaccesses .=
              "$load_txt{'805'} $load_txt{'806'} $load_txt{'812'}<br />";
        }
        else {
            $noaccesses .=
              "$load_txt{'805'} $load_txt{'807'} $load_txt{'812'}<br />";
        }
    }

    return qq~$yesaccesses<br />$noaccesses~;
}

sub SetTopicPreview {
    if ( $INFO{'todo'} eq 'disable' ) {
        ${ $uid . $username }{'topicpreview'} = '0';
    }
    else {
        ${ $uid . $username }{'topicpreview'} = '1';
    }
    UserAccount( $username, 'update' );
    redirectinternal();
    return;
}

1;
