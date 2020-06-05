###############################################################################
# ViewMembers.pm                                                              #
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
our $VERSION = '2.6.11';

$viewmemberspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('MemberList');

is_admin_or_gmod();

my ( $sortmode, $sortorder, $spages );

$MembersPerPage = $TopAmmount;
$maxbar         = 100;

sub Ml {

    # Decides how to sort memberlist, and gives default sort order
    if ( !$barmaxnumb ) { $barmaxnumb = 500; }
    if ( $barmaxdepend == 1 ) {
        $barmax = 1;
        ManageMemberinfo('load');
        while ( ( $key, $value ) = each %memberinf ) {
            ( undef, undef, undef, $memposts ) = split /\|/xsm, $value;
            if ( $memposts > $barmax ) { $barmax = $memposts; }
        }
        undef %memberinf;
    }
    else {
        $barmax = $barmaxnumb;
    }

    $FORM{'sortform'} ||= $INFO{'sortform'};
    if ( !$INFO{'sort'} && !$FORM{'sortform'} ) {
        $INFO{'sort'}     = $defaultml;
        $FORM{'sortform'} = $defaultml;
    }

    if (   $FORM{'sortform'} eq 'username'
        || $INFO{'sort'} eq 'mlletter'
        || $INFO{'sort'} eq 'username' )
    {
        $page     = 'a';
        $showpage = 'A';
        while ( $page ne 'z' ) {
            $LetterLinks .=
qq(<a href="$adminurl?action=ml;sort=mlletter;letter=$page" class="catbg a"><b>$showpage&nbsp;</b></a> );
            $page++;
            $showpage++;
        }
        $LetterLinks .=
qq(<a href="$adminurl?action=ml;sort=mlletter;letter=z" class="catbg a"><b>Z</b></a>  <a href="$adminurl?action=ml;sort=mlletter;letter=other" class="catbg a"><b>$ml_txt{'800'}</b></a> );
    }

    if ( $INFO{'start'} eq q{} ) { $start = 0; }
    else { $start = $INFO{'start'}; $spages = ";start=$start"; }

    if ( $INFO{'sort'} ne q{} ) { $sortmode = ';sort=' . $INFO{'sort'}; }
    elsif ( $FORM{'sortform'} ne q{} ) {
        $sortmode = ';sort=' . $FORM{'sortform'};
    }
    if ( $INFO{'reversed'} || $FORM{'reversed'} ) {
        $selReversed = q~ checked="checked"~;
        $sortorder   = ';reversed=1';
    }

    $actualnum = 0;
    $numshown  = 0;
    $selPost_a = q~windowbg2~;
    $selReg_a = q~windowbg2~;
    $selPos_a = q~windowbg2~;
    $selLastOn_a = q~windowbg2~;
    $selLastPost_a = q~windowbg2~;
    $selLastIM_a = q~windowbg2~;
    $selUser_a = q~windowbg2~;
    if ( $FORM{'sortform'} eq 'posts' || $INFO{'sort'} eq 'posts' ) {
        $selPost_a = q~windowbg~;
        $selPost .= q~ selected="selected"~;
        MLTop();
    }
    if ( $FORM{'sortform'} eq 'regdate' || $INFO{'sort'} eq 'regdate' ) {
        $selReg .= q~ selected="selected"~;
        $selReg_a = q~windowbg~;
        MLDate();
    }
    if ( $FORM{'sortform'} eq 'position' || $INFO{'sort'} eq 'position' ) {
        $selPos .= q~ selected="selected"~;
        $selPos_a = q~windowbg~;
        MLPosition();
    }
    if ( $FORM{'sortform'} eq 'lastonline' || $INFO{'sort'} eq 'lastonline' ) {
        $selLastOn .= q~ selected="selected"~;
        $selLastOn_a = q~windowbg~;
        MLLastOnline();
    }
    if ( $FORM{'sortform'} eq 'lastpost' || $INFO{'sort'} eq 'lastpost' ) {
        $selLastPost .= q~ selected="selected"~;
        $selLastPost_a = q~windowbg~;
        MLLastPost();
    }
    if ( $FORM{'sortform'} eq 'lastim' || $INFO{'sort'} eq 'lastim' ) {
        $selLastIm .= q~ selected="selected"~;
        $selLastIM_a = q~windowbg~;
        MLLastIm();
    }
    if ( $FORM{'sortform'} eq 'memsearch' || $INFO{'sort'} eq 'memsearch' ) {
        FindMembers();
    }
    if (   $INFO{'sort'} eq q{}
        || $INFO{'sort'} eq 'mlletter'
        || $INFO{'sort'} eq 'username' )
    {
        $selUser .= q~ selected="selected"~;
        $selUser_a = q~windowbg~;
        MLByLetter();
    }
    return;
}

sub MLByLetter {
    $letter = lc $INFO{'letter'};
    $i      = 0;
    ManageMemberinfo('load');
    foreach my $membername (
        sort { lc $memberinf{$a} cmp lc $memberinf{$b} }
        keys %memberinf
      )
    {
        ( $memrealname, $mememail, undef, undef ) =
          split /\|/xsm, $memberinf{$membername};
        if ($letter) {
            $SearchName = lc( substr $memrealname, 0, 1 );
            if ( $SearchName eq $letter ) { $ToShow[$i] = $membername; $i++; }
            elsif ( $letter eq 'other'
                && ( ( $SearchName lt 'a' ) || ( $SearchName gt 'z' ) ) )
            {
                $ToShow[$i] = $membername;
                $i++;
            }
        }
        else {
            $ToShow[$i] = $membername;
            $i++;
        }
    }
    undef %memberinf;

    $memcount = @ToShow;
    if ( !$memcount && $letter ) {
        $pageindex1 =
qq~<span class="index-togl small">$admin_img{'index_togl'}</span>~;
        $pageindex2 =
qq~<span class="index-togl small">$admin_img{'index_togl'}</span>~;
    }
    else {
        buildIndex();
    }
    buildPages(1);
    $bb = $start;

    if ($memcount) {
        while ( $numshown < $MembersPerPage ) {
            showRows( $ToShow[$bb] );
            $numshown++;
            $bb++;
        }
    }
    else {
        if ($letter) {
            $yymain .= qq~<tr>
    <td class="windowbg center" colspan="7">
        <div class="pad-more"><b>$ml_txt{'760'}</b></div>
    </td>
</tr>~;
        }
    }

    undef @ToShow;
    buildPages(0);
    $yytitle     = "$ml_txt{'312'} $numshow";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub MLTop {
    %top_list = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        ( $memrealname, undef, undef, $memposts ) = split /\|/xsm, $value;
        $memposts = sprintf '%06d', ( 999_999 - $memposts );
        $top_list{$membername} = qq~$memposts|$memrealname~;
    }
    undef %memberinf;
    my @toplist = sort { lc $top_list{$a} cmp lc $top_list{$b} } keys %top_list;

    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @toplist = reverse @toplist;
    }

    $memcount = @toplist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( $numshown < $MembersPerPage ) {
        showRows( $toplist[$bb] );
        $numshown++;
        $bb++;
    }

    undef @toplist;
    buildPages(0);
    $yytitle     = "$ml_txt{'313'} $ml_txt{'314'} $numshow";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub MLPosition {
    %TopMembers = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        ( $memberrealname, undef, $memposition, $memposts ) =
          split /\|/xsm, $value;
        $pstsort    = 99_999_999 - $memposts;
        $sortgroups = q{};
        foreach my $key ( keys %Group ) {
            if ( $memposition eq $key ) {
                if ( $key eq 'Administrator' ) {
                    $sortgroups = "aaa.$pstsort.$memberrealname";
                }
                elsif ( $key eq 'Global Moderator' ) {
                    $sortgroups = "bbb.$pstsort.$memberrealname";
                }
                elsif ( $key eq 'Mid Moderator' ) {
                    $sortgroups = "bcc.$pstsort.$memberrealname";
                }
            }
        }
        if ( !$sortgroups ) {
            foreach ( sort { $a <=> $b } keys %NoPost ) {
                if ( $memposition eq $_ ) {
                    $sortgroups = "ddd.$memposition.$pstsort.$memberrealname";
                }
            }
        }
        if ( !$sortgroups ) {
            $sortgroups = "eee.$pstsort.$memposition.$memberrealname";
        }
        $TopMembers{$membername} = $sortgroups;
    }
    my @toplist =
      sort { lc $TopMembers{$a} cmp lc $TopMembers{$b} } keys %TopMembers;

    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @toplist = reverse @toplist;
    }

    $memcount = @toplist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( $numshown < $MembersPerPage ) {
        showRows( $toplist[$bb] );
        $numshown++;
        $bb++;
    }

    undef @toplist;
    undef %memberinf;
    buildPages(0);
    $yytitle     = "$ml_txt{'313'} $ml_txt{'4'} $ml_txt{'87'} $numshow";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub MLDate {
    fopen( MEMBERLISTREAD, "$memberdir/memberlist.txt" );
    @tempmemlist = <MEMBERLISTREAD>;
    fclose(MEMBERLISTREAD);
    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @tempmemlist = reverse @tempmemlist;
    }

    $memcount = @tempmemlist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( $numshown < $MembersPerPage ) {
        ( $membername, undef ) = split /\t/xsm, $tempmemlist[$bb], 2;
        showRows($membername);
        $numshown++;
        $bb++;
    }

    $yymain .= $TableFooter;
    buildPages(0);
    $yytitle     = "$ml_txt{'313'} $ml_txt{'4'} $ml_txt{'233'}";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub showRows {
    my ($user) = @_;
    if ( $user ne q{} ) {
        LoadUser($user);
        $date2 = $date;

        my $userlastonline = ${ $uid . $user }{'lastonline'};
        my $userlastpost   = ${ $uid . $user }{'lastpost'};
        my $userlastim     = ${ $uid . $user }{'lastim'};

        $date1 = stringtotime( ${ $uid . $user }{'regdate'} );
        calcdifference();
        $days_reg = $result;

        my ( $tmpa, $tmpb, $tmpc );
        if ( $userlastonline eq q{} ) { $userlastonline = q{-};
             $date1 = stringtotime( ${ $uid . $user }{'regdate'} );
            calcdifference();
            $tmpa = $result;
            }
        else {
            $date1 = $userlastonline;
            calcdifference();
            $userlastonline = $result;
            $tmpa           = $userlastonline;
        }
        if ( $userlastpost eq q{} ) { $userlastpost = q{-};
             $date1 = stringtotime( ${ $uid . $user }{'regdate'} );
            calcdifference();
            $tmpb = $result;
            }
        else {
            $date1 = $userlastpost;
            calcdifference();
            $userlastpost = $result;
             $tmpb         = $userlastpost;
        }
        if ( $userlastim eq q{} ) { $userlastim = q{-};
            $date1 = stringtotime( ${ $uid . $user }{'regdate'} );
            calcdifference();
            $tmpc = $result;
            }
        else {
            $date1 = $userlastim;
            calcdifference();
            $userlastim = $result;
            $tmpc       = $userlastim;
        }
        $userlastonline = NumberFormat($userlastonline);
        $userlastpost   = NumberFormat($userlastpost);
        $userlastim     = NumberFormat($userlastim);
        $userpostcount  = NumberFormat( ${ $uid . $user }{'postcount'} );

        if ( $user ne 'admin' ) {
            $CheckingAll .=
qq~"$days_reg|${$uid.$user}{'postcount'}|$tmpa|$tmpb|$tmpc|$user", ~;
        }

        $barchart = ${ $uid . $user }{'postcount'};
        $bartemp  = ( ${ $uid . $user }{'postcount'} * $maxbar );
        $barwidth = ( $bartemp / $barmax );
        $barwidth = ( $barwidth + 0.5 );
        $barwidth = int $barwidth;
        if ( $barwidth > $maxbar ) { $barwidth = $maxbar }
        if ( $barchart < 1 )       { $Bar      = '&nbsp;'; }
        else {
            $Bar =
qq~<img src="$imagesdir/bar.gif" width="$barwidth" height="10" alt="" />~;
        }

        $dr_regdate = timeformat( ${ $uid . $user }{'regtime'} );
        $dr_regdate =~ s/(.*)(, 1?[0-9]):[0-9][0-9].*/$1/sm;

        my $memberinfo = '&nbsp;';
        if ( ${ $uid . $user }{'realname'} eq q{} ) {
            ${ $uid . $user }{'realname'} = $user;
        }
        if ( ${ $uid . $user }{'position'} eq q{} && $showallgroups ) {
            foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
                if ( ${ $uid . $user }{'postcount'} > $postamount ) {
                    (
                        $memberinfo, $stars,     $starpic,    $color,
                        $noshow,     $viewperms, $topicperms, $replyperms,
                        $pollperms,  $attachperms
                    ) = split /\|/xsm, $Post{$postamount};
                    last;
                }
            }
        }
        elsif ( ${ $uid . $user }{'position'} ne q{} ) {
            $tempgroups = 0;
            foreach ( keys %Group ) {
                if ( ${ $uid . $user }{'position'} eq $_ ) {
                    (
                        $memberinfo, $stars,     $starpic,    $color,
                        $noshow,     $viewperms, $topicperms, $replyperms,
                        $pollperms,  $attachperms
                    ) = split /\|/xsm, $Group{$_};
                    $tempgroups = 1;
                    last;
                }
            }
            if ( !$tempgroups ) {
                foreach ( sort { $a <=> $b } keys %NoPost ) {
                    if ( ${ $uid . $user }{'position'} eq $_ ) {
                        (
                            $memberinfo, $stars,      $starpic,
                            $color,      $noshow,     $viewperms,
                            $topicperms, $replyperms, $pollperms,
                            $attachperms
                        ) = split /\|/xsm, $NoPost{$_};
                        $tempgroups = 1;
                        last;
                    }
                }
            }
            if ( !$tempgroups ) {
                $memberinfo = ${ $uid . $user }{'position'};
            }
        }

        $yymain .= qq~<tr>
        <td class="windowbg">$link{$user}</td>~;

        if ( $user eq 'admin' ) {
            $addel = q~&nbsp;~;
        }
        else {
            $addel =
qq~<input type="checkbox" name="member$numshown" value="$user" class="windowbg" style="border: 0; vertical-align: middle;" />~;
            $actualnum++;
        }

        $yymain .= qq~
        <td class="windowbg">$memberinfo</td>
        <td class="windowbg2 center">$userpostcount</td>
        <td class="windowbg">$Bar</td>
        <td class="windowbg">$dr_regdate &nbsp;</td>
        <td class="windowbg2 center">$userlastonline</td>
        <td class="windowbg2 center">$userlastpost</td>
        <td class="windowbg2 center">$userlastim</td>
        <td class="windowbg center">$addel</td>
    </tr>~;
    }
    return;
}

sub buildIndex {
    if ( $memcount != 0 ) {

        ( undef, undef, $usermemberpage ) =
          split /\|/xsm, ${ $uid . $username }{'pageindex'};

        # Build the page links list.
        my ( $pagetxtindex, $pagedropindex1, $pagedropindex2, $all,
            $allselected );
        $indexdisplaynum = 3;
        $dropdisplaynum  = 10;
        if ( $FORM{'sortform'} eq q{} ) { $FORM{'sortform'} = $INFO{'sort'}; }
        $postdisplaynum = 3;
        $startpage      = 0;
        $max            = $memcount;
        if ( $INFO{'start'} eq 'all' ) {
            $MembersPerPage = $max;
            $all            = 1;
            $allselected    = q~ selected="selected"~;
            $start          = 0;
        }
        else { $start = $INFO{'start'} || 0; }
        $start    = $start > $memcount - 1 ? $memcount - 1 : $start;
        $start    = ( int( $start / $MembersPerPage ) ) * $MembersPerPage;
        $tmpa     = 1;
        $pagenumb = int( ( $memcount - 1 ) / $MembersPerPage ) + 1;

        if ( $start >= ( ( $postdisplaynum - 1 ) * $MembersPerPage ) ) {
            $startpage = $start - ( ( $postdisplaynum - 1 ) * $MembersPerPage );
            $tmpa = int( $startpage / $MembersPerPage ) + 1;
        }
        if ( $memcount >= $start + ( $postdisplaynum * $MembersPerPage ) ) {
            $endpage = $start + ( $postdisplaynum * $MembersPerPage );
        }
        else { $endpage = $memcount }
        $lastpn = int( ( $memcount - 1 ) / $MembersPerPage ) + 1;
        $lastptn = ( $lastpn - 1 ) * $MembersPerPage;
        $pageindex1 =
qq~<span class="index-togl small">$admin_img{'index_togl'} $ml_txt{'139'}: $pagenumb</span>~;
        $pageindex2 =
qq~<span class="index-togl small">$admin_img{'index_togl'} $ml_txt{'139'}: $pagenumb</span>~;
        if ( $pagenumb > 1 || $all ) {

            if ( $usermemberpage == 1 ) {
                $pagetxtindexst =
qq~<span class="index-togl small"><a href="$scripturl?action=memberpagedrop;from=admin;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}$sortorder"><img src="$imagesdir/index_togl.png" alt="$ml_txt{'19'}" title="$ml_txt{'19'}" /></a> $ml_txt{'139'}: ~;
                if ( $startpage > 0 ) {
                    $pagetxtindex =
qq~<a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter$sortorder" class="norm">1</a>&nbsp;...&nbsp;~;
                }
                if ( $startpage == $MembersPerPage ) {
                    $pagetxtindex =
qq~<a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter$sortorder" class="norm">1</a>&nbsp;~;
                }
                foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
                    if ( $counter % $MembersPerPage == 0 ) {
                        $pagetxtindex .=
                          $start == $counter
                          ? qq~<b>[$tmpa]</b>&nbsp;~
                          : qq~<a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=$counter$sortorder" class="norm">$tmpa</a>&nbsp;~;
                        $tmpa++;
                    }
                }
                if ( $endpage < $memcount - $MembersPerPage ) {
                    $pageindexadd = q~...&nbsp;~;
                }
                if ( $endpage != $memcount ) {
                    $pageindexadd .=
qq~<a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=$lastptn$sortorder" class="norm">$lastpn</a>~;
                }
                $pagetxtindex .= qq~$pageindexadd~;
                $pageindex1 = qq~$pagetxtindexst$pagetxtindex</span>~;
                $pageindex2 = qq~$pagetxtindexst$pagetxtindex</span>~;
            }
            else {
                $pagedropindex1 =
q~<span style="float: left; width: 350px; margin: 2px 0 0 0; border: 0;">~;
                $pagedropindex1 .=
qq~<span style="float: left; height: 21px; margin: 0 4px 0 0;"><a href="$scripturl?action=memberpagetext;from=admin;sort=$INFO{'sort'};letter=$INFO{'letter'};start=$INFO{'start'}$sortorder"><img src="$imagesdir/index_togl.png" alt="$ml_txt{'19'}" title="$ml_txt{'19'}" /></a></span>~;
                $pagedropindex2 = $pagedropindex1;
                $tstart         = $start;
                if ( substr( $INFO{'start'}, 0, 3 ) eq 'all' ) {
                    ( $tstart, $start ) = split /\-/xsm, $INFO{'start'};
                }
                $d_indexpages = $pagenumb / $dropdisplaynum;
                $i_indexpages = int( $pagenumb / $dropdisplaynum );
                if ( $d_indexpages > $i_indexpages ) {
                    $indexpages = int( $pagenumb / $dropdisplaynum ) + 1;
                }
                else { $indexpages = int( $pagenumb / $dropdisplaynum ) }
                $selectedindex =
                  int( ( $start / $MembersPerPage ) / $dropdisplaynum );

                if ( $pagenumb > $dropdisplaynum ) {
                    $pagedropindex1 .=
qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector1" id="decselector1" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
                    $pagedropindex2 .=
qq~<span style="float: left; height: 21px; margin: 0;"><select size="1" name="decselector2" id="decselector2" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
                }
                for my $i ( 0 .. ( $indexpages - 1 ) ) {
                    $indexpage  = ( $i * $dropdisplaynum ) * $MembersPerPage;
                    $indexstart = ( $i * $dropdisplaynum ) + 1;
                    $indexend   = $indexstart + ( $dropdisplaynum - 1 );
                    if ( $indexend > $pagenumb ) { $indexend = $pagenumb; }
                    if ( $indexstart == $indexend ) {
                        $indxoption = qq~$indexstart~;
                    }
                    else { $indxoption = qq~$indexstart-$indexend~; }
                    $selected = q{};
                    if ( $i == $selectedindex ) {
                        $selected = q~ selected="selected"~;
                        $pagejsindex =
                          qq~$indexstart|$indexend|$MembersPerPage|$indexpage~;
                    }
                    if ( $pagenumb > $dropdisplaynum ) {
                        $pagedropindex1 .=
qq~<option value="$indexstart|$indexend|$MembersPerPage|$indexpage"$selected>$indxoption</option>\n~;
                        $pagedropindex2 .=
qq~<option value="$indexstart|$indexend|$MembersPerPage|$indexpage"$selected>$indxoption</option>\n~;
                    }
                }
                if ( $pagenumb > $dropdisplaynum ) {
                    $pagedropindex1 .= qq~</select>\n</span>~;
                    $pagedropindex2 .= qq~</select>\n</span>~;
                }
                $pagedropindex1 .=
q~<span id="ViewIndex1" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
                $pagedropindex2 .=
q~<span id="ViewIndex2" class="droppageindex" style="height: 14px; visibility: hidden">&nbsp;</span>~;
                $tmpMembersPerPage = $MembersPerPage;
                if ( substr( $INFO{'start'}, 0, 3 ) eq 'all' ) {
                    $MembersPerPage = $MembersPerPage * $dropdisplaynum;
                }
                $prevpage = $start - $tmpMembersPerPage;
                $nextpage = $start + $MembersPerPage;
                $pagedropindexpvbl =
qq~<img src="$imagesdir/index_left0.png" height="14" width="13" alt="" style="vertical-align: top; margin-top:-1px" />~;
                $pagedropindexnxbl =
qq~<img src="$imagesdir/index_right0.png" height="14" width="13" alt="" style="vertical-align: top; margin-top:-1px;" />~;
                if ( $start < $MembersPerPage ) {
                    $pagedropindexpv .=
qq~<img src="$imagesdir/index_left0.png" height="14" width="13" alt="" style="vertical-align: top; margin-top:-1px" />~;
                }
                else {
                    $pagedropindexpv .=
qq~<img src="$imagesdir/index_left.png" height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" style="vertical-align: top; cursor: pointer; margin-top:-1px;" onclick="location.href=\\'$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=$prevpage$sortorder\\'" ondblclick="location.href=\\'$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=0$sortorder\\'" />~;
                }
                if ( $nextpage > $lastptn ) {
                    $pagedropindexnx .=
qq~<img src="$imagesdir/index_right0.png" height="14" width="13" alt="" style="vertical-align: top; margin-top:-1px;" />~;
                }
                else {
                    $pagedropindexnx .=
qq~<img src="$imagesdir/index_right.png" height="14" width="13" alt="$pidtxt{'03'}" title="$pidtxt{'03'}" style="display: inline; vertical-align: top; margin-top:-1px; cursor: pointer;" onclick="location.href=\\'$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=$nextpage$sortorder\\'" ondblclick="location.href=\\'$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=$lastptn$sortorder\\'" />~;
                }
                $pageindex1 = qq~$pagedropindex1</span>~;
                $pageindex2 = qq~$pagedropindex2</span>~;

                $pageindexjs = qq~
<script type="text/javascript">
    function SelDec(decparam, visel) {
        splitparam = decparam.split("|");
        var vistart = parseInt(splitparam[0]);
        var viend = parseInt(splitparam[1]);
        var maxpag = parseInt(splitparam[2]);
        var pagstart = parseInt(splitparam[3]);
        var allpagstart = parseInt(splitparam[3]);
        if(visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
        var pagedropindex = '<table><tr>';
        for(i=vistart; i<=viend; i++) {
            if(visel == pagstart) pagedropindex += '<td class="titlebg" style="height: 14px; padding:0 1px; font-size: 9px; font-weight: bold">' + i + '</td>';
            else pagedropindex += '<td class="droppages" style="line-height:14px; padding:0 1px"><a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=' + pagstart + '$sortorder">' + i + '</a></td>';
            pagstart += maxpag;
        }
        ~;
                if ($showpageall) {
                    $pageindexjs .= qq~
            if (vistart != viend) {
                if(visel == 'all') pagedropindex += '<td class="titlebg" style="line-height: 14px; padding:0 1px; font-size: 9px; font-weight: normal;"><b>$pidtxt{"01"}</b></td>';
                else pagedropindex += '<td class="droppages" style="line-height:14px; padding:0 1px"><a href="$adminurl?action=ml;sort=$FORM{'sortform'};letter=$letter;start=all-' + allpagstart + '$sortorder">$pidtxt{"01"}</a></td>';
            }
            ~;
                }
                $pageindexjs .= qq~
        if(visel != 'xx') pagedropindex += '<td class="small" style="line-height: 14px; padding:0 0 0 4px;">$pagedropindexpv$pagedropindexnx</td>';
        else pagedropindex += '<td class="small" style="line-height: 14px; padding:0 0 0 4px;">$pagedropindexpvbl$pagedropindexnxbl</td>';
        pagedropindex += '</tr></table>';
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
    document.onload = SelDec('$pagejsindex', '$tstart');
</script>
~;
            }
        }
    }

    return;
}

sub buildPages {
    my ($inp) = @_;

    $FindForm .= qq~
        <script type="text/javascript">
            function txtInFields(thefield, defaulttxt) {
            if (thefield.value == defaulttxt) thefield.value = "";
            else { if (thefield.value === "") thefield.value = defaulttxt; }
            }
        </script>
            <form action="$adminurl?action=ml;sort=memsearch" method="post" id="form1" name="form1" enctype="application/x-www-form-urlencoded" style="display: inline;">
            <input type="text" name="member" id="member" value="$ml_txt{'801'}" style="font-size: 11px; width: 180px;" onfocus="txtInFields(this, '$ml_txt{'801'}');" onblur="txtInFields(this, '$ml_txt{'801'}')" />
            <input name="submit" type="submit" class="button" style="font-size: 10px;" value="$ml_txt{'2'}" />
            </form>
        ~;

    $TableHeader .= qq~
        <table class="bordercolor borderstyle border-space pad-cell">
            <tr>
                <td class="titlebg right" style="font-size: 11px; text-shadow: none;">
                    $FindForm
                    <form action="$adminurl?action=ml" method="post" name="selsort" style="display: inline">
                        <label for="sortform"><b>$ml_txt{'1'}</b></label>
                        <select name="sortform" id="sortform" style="font-size: 9pt;" onchange="submit()">
                        <option value="username"$selUser>$ml_txt{'35'}</option>
                        <option value="position"$selPos>$ml_txt{'87'}</option>
                        <option value="posts"$selPost>$ml_txt{'21'}</option>
                        <option value="regdate"$selReg>$ml_txt{'233'}</option>
                        <option value="lastonline"$selLastOn>$amv_txt{'9'}</option>
                        <option value="lastpost"$selLastPost>$amv_txt{'10'}</option>
                        <option value="lastim"$selLastIm>$amv_txt{'11'}</option>
                    </select>
                    <label for="reversed"><b>$admintxt{'37'}</b></label>
                    <input type="checkbox" onclick="submit()" name="reversed" id="reversed" class="titlebg" style="border: 0;"$selReversed />
                    <input type="submit" style="display:none" />
                    </form>
                </td>
            </tr>
        </table>
        </div>
        <script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
        <script type="text/javascript">
            if (document.selsort.sortform.options[document.selsort.sortform.selectedIndex].value == 'username') {
                document.selsort.reversed.disabled = true;
            }
        </script>
        <form name="adv_memberview" action="$adminurl?action=deletemultimembers$sortmode$sortorder$spages" method="post" style="display: inline" onsubmit="return submitproc()">
        <input type="hidden" name="button" value="0" />
        <div class="rightboxdiv">
        <table class="bordercolor borderstyle border-space pad-cell">
            <colgroup>
                <col span="2" style="width:19%" />
                <col style="width:5%" />
                <col style="width:14%" />
                <col style="width:19%" />
                <col style="width:7%" />
                <col span="2" style="width:6%" />
            </colgroup>
            <tr>
                <td class="$selUser_a center"><a href="$adminurl?action=ml;sortform=username"><b>$ml_txt{'35'}</b></a></td>
                <td class="$selPos_a center"><a href="$adminurl?action=ml;sortform=position"><b>$ml_txt{'87'}</b></a></td>
                <td class="$selPost_a center" colspan="2"><a href="$adminurl?action=ml;sortform=posts"><b>$ml_txt{'21'}</b></a></td>
                <td class="$selReg_a center"><a href="$adminurl?action=ml;sortform=regdate"><b>$ml_txt{'234'}</b></a></td>
                <td class="windowbg2 center" colspan="3"><b>$amv_txt{'4'}</b>
                    <br /><span class="small $selLastOn_a" style="float: left; text-align: center; width: 34%;"><a href="$adminurl?action=ml;sortform=lastonline">$amv_txt{'5'}</a></span>
                    <span class="small $selLastPost_a" style="float: left; text-align: center; width: 33%;"><a href="$adminurl?action=ml;sortform=lastpost">$amv_txt{'6'}</a></span>
                    <span class="small $selLastIM_a" style="float: left; text-align: center; width: 33%;"><a href="$adminurl?action=ml;sortform=lastim">$amv_txt{'7'}</a></span></td>
                <td class="windowbg2 center"><b>$admintxt{'38'}</b></td>
            </tr>
        ~;

    if ( $LetterLinks ne q{} ) {
        $TableHeader .= qq(<tr>
                <td class="catbg" colspan="9"><span class="small">$LetterLinks</span></td>
            </tr>);
    }

    $sel_box = qq~
            <table class="bordercolor borderstyle border-space pad-cell" style="margin-bottom: .5em;">
                <colgroup>
                    <col style="width: 95%" />
                    <col style="width: 5%" />
                </colgroup>
                <tr>
                    <td class="titlebg right" style="font-size: 11px; text-shadow: none;">
                    <label for="check_all"><b>$amv_txt{'38'}</b></label>
                    <select name="field2" id="field2" onchange="document.adv_memberview.check_all.checked=true;checkAll(1);">
                        <option value="0">$amv_txt{'35'}</option>
                        <option value="1">$amv_txt{'36'}</option>
                        <option value="2" selected="selected">$amv_txt{'37'}</option>
                    </select>
                    <input type="text" size="5" name="number" value="30" maxlength="5" onkeyup="document.adv_memberview.check_all.checked=true;checkAll(1);" />
                    <select name="field1" onchange="document.adv_memberview.check_all.checked=true;checkAll(1);">
                        <option value="0">$amv_txt{'30'}</option>
                        <option value="1">$amv_txt{'31'}</option>
                        <option value="2" selected="selected">$amv_txt{'32'}</option>
                        <option value="3">$amv_txt{'33'}</option>
                        <option value="4">$amv_txt{'34'}</option>
                    </select>
                    </td>
                    <td class="titlebg center">
                        <input type="checkbox" name="check_all" id="check_all" value="1" class="titlebg" style="border: 0;" onclick="javascript:if(this.checked)checkAll(1);else checkAll(0);" />
                    </td>
                </tr>
            </table>
        <script type="text/javascript">
        mem_data = new Array ( "", $CheckingAll"" );
        function checkAll(ticked) {
            if(navigator.appName == "Microsoft Internet Explorer") {var alt_pressed = self.event.altKey; var ctrl_pressed = self.event.ctrlKey;}
            else {alt_pressed = false; ctrl_pressed = false;}

            var limit = document.adv_memberview.number.value;
            var field1 = document.adv_memberview.field1.value;
            var field2 = document.adv_memberview.field2.value;
            for (var i = 1; i <= $actualnum; i++) {
                if (!ticked) {
                    document.adv_memberview.elements[i].checked = false;
                } else {
                    var value1 = eval(mem_data[i].split("|")[field1]);
                    if (value1 != undefined) {
                        var check = 0;
                        if (field2 === 0 && value1 <  limit) { check = 1; }
                        if (field2 == 1 && value1 == limit) { check = 1; }
                        if (field2 == 2 && value1 >  limit) { check = 1; }
                        if (ctrl_pressed === true) { check = 0; }
                        if (alt_pressed  === true) { check = 1; }
                        if (check == 1) document.adv_memberview.elements[i].checked = true;
                        else            document.adv_memberview.elements[i].checked = false;
                    }
                }
            }
        }
        </script>~;

    $numbegin = ( $start + 1 );
    $numend   = ( $start + $MembersPerPage );
    if ( $numend > $memcount ) { $numend  = $memcount; }
    if ( $memcount == 0 )      { $numshow = q{}; }
    else { $numshow = qq~($numbegin - $numend $ml_txt{'309'} $memcount)~; }
    if ($inp) {
        $yymain .= qq~
    <div class="rightboxdiv">
    <table class="bordercolor border-space pad-cell">
        <tr>
            <td class="titlebg">
                <span style="float: left;">$admin_img{'register'} <b>$admintxt{'17'}</b></span>
            </td>
        </tr><tr>
            <td class="catbg">
                <div style="float: left; width: 50%; text-align: left;">$pageindex1</div>
            </td>
        </tr>
    </table>
    $TableHeader~;
    }
    else {
        $yymain .= qq~<tr>
        <td class="catbg" colspan="9">
            <div style="float: left; width: 50%; text-align: left;">$pageindex2</div>
            $pageindexjs
            </td>
        </tr>
       </table>
       $sel_box
    </div>
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'delete'}</th>
        </tr><tr>
            <td class="catbg center">
                <div class="small"><label for="del_mail">$amv_txt{'45'}:</label> <input type="checkbox" name="del_mail" id="del_mail" value="1" /></div>
                <input type="submit" value="$amv_txt{'15'}" onclick="javascript:window.document.adv_memberview.button.value = '2'; return confirm('$amv_txt{'20'}')" class="button" />
            </td>
         </tr>
    </table>
    </div>
    </form>~;
    }
    return;
}

sub MLLastPost {
    %TopMembers = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        LoadUser($membername);
        $TopMembers{$membername} = ${ $uid . $membername }{'lastpost'};
        undef %{ $uid . $membername };
    }
    undef %memberinf;

    my @toplist =
      reverse sort { $TopMembers{$a} <=> $TopMembers{$b} } keys %TopMembers;
    undef %TopMembers;

    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @toplist = reverse @toplist;
    }

    $memcount = @toplist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( ( $numshown < $MembersPerPage ) ) {
        showRows( $toplist[$bb] );
        $numshown++;
        $bb++;
    }

    undef @toplist;
    buildPages(0);

    $yymain .= $TableFooter;
    $yytitle     = "$ml_txt{'313'} $TopAmmount $ml_txt{'314'}";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub MLLastIm {
    %TopMembers = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        LoadUser($membername);
        $TopMembers{$membername} = ${ $uid . $membername }{'lastim'};
        undef %{ $uid . $membername };
    }
    undef %memberinf;

    my @toplist =
      reverse sort { $TopMembers{$a} <=> $TopMembers{$b} } keys %TopMembers;
    undef %TopMembers;

    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @toplist = reverse @toplist;
    }

    $memcount = @toplist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( ( $numshown < $MembersPerPage ) ) {
        showRows( $toplist[$bb] );
        $numshown++;
        $bb++;
    }

    undef @toplist;
    buildPages(0);

    $yymain .= $TableFooter;
    $yytitle     = "$ml_txt{'313'} $TopAmmount $ml_txt{'314'}";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub MLLastOnline {
    %TopMembers = ();

    ManageMemberinfo('load');
    while ( ( $membername, $value ) = each %memberinf ) {
        LoadUser($membername);
        $TopMembers{$membername} = ${ $uid . $membername }{'lastonline'};
        undef %{ $uid . $membername };
    }
    undef %memberinf;

    my @toplist =
      reverse sort { $TopMembers{$a} <=> $TopMembers{$b} } keys %TopMembers;
    undef %TopMembers;

    if ( $FORM{'reversed'} || $INFO{'reversed'} ) {
        @toplist = reverse @toplist;
    }

    $memcount = @toplist;
    buildIndex();
    buildPages(1);
    $bb = $start;

    while ( $numshown < $MembersPerPage ) {
        showRows( $toplist[$bb] );
        $numshown++;
        $bb++;
    }

    undef @toplist;
    buildPages(0);

    $yymain .= $TableFooter;
    $yytitle     = "$ml_txt{'313'} $TopAmmount $ml_txt{'314'}";
    $action_area = 'viewmembers';
    AdminTemplate();
    return;
}

sub FindMembers {
    $SearchStr = $FORM{'member'} || $INFO{'member'};
    $LookFor = qq~^$SearchStr\$~;
    $LookFor =~ s/\*+/.*?/gsm;

    ManageMemberinfo('load');
    my %memberfind = ();
    while ( ( $membername, $value ) = each %memberinf ) {
        ( $memrealname, $mememail, undef ) = split /\|/xsm, $value, 3;
        if ( $memrealname =~ /$LookFor/ism ) {
            $memberfind{$membername} = $memrealname;
        }
        elsif ( $mememail =~ /$LookFor/ism ) {
            if ( $iamadmin || $iamgmod )
            {
                $memberfind{$membername} = $memrealname;
            }
        }
    }
    @findmemlist =
      sort { lc $memberfind{$a} cmp lc $memberfind{$b} } keys %memberfind;
    undef %memberfind;
    $memcount = @findmemlist;
    buildIndex();
    buildPages(1);
    if ( $memcount > 0 ) {
        my $i = $start;
        $numshown = 0;
        while ( $numshown < $MembersPerPage ) {
            chomp $findmemlist[$i];
            showRows( $findmemlist[$i] );
            $numshown++;
            $i++;
        }
    }
    else {
        $yymain .= qq~
            <tr>
                  <td class="windowbg2" colspan="7"><br />$ml_txt{'802'} <i>$FORM{'member'}</i><br /><br /></td>
            </tr>~;
    }
    undef @findmemlist;
    undef %memberinf;
    buildPages(0);
    $yytitle = "$ml_txt{'313'} $ml_txt{'4'} $ml_txt{'87'} $numshow";
    AdminTemplate();
    return;
}

1;
