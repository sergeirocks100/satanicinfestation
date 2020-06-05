###############################################################################
# Attachments.pm                                                              #
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

$attachmentspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub Attachments {
    is_admin_or_gmod();

    fopen( AMS, "$vardir/attachments.txt" );
    my @attachments = <AMS>;
    fclose(AMS);

    my $attachment_space = 0;
    foreach (@attachments) {
        $attachment_space += NumberFormat( ( split /\|/xsm, $_, 7 )[5] );
    }

    my $remaining_space;
    if ( !$dirlimit ) {
        $remaining_space = "$fatxt{'23'}";
    }
    else {
        $remaining_space = NumberFormat( ( $dirlimit - $attachment_space ) ) . ' KB';
    }

    fopen( FILE, "$vardir/oldestattach.txt" );
    $maxdaysattach = <FILE>;
    fclose(FILE);

    fopen( FILE, "$vardir/oldestpmattach.txt" );
    $pmMaxDaysAttach = <FILE>;
    fclose(FILE);

    fopen( FILE, "$vardir/maxattachsize.txt" );
    $maxsizeattach = <FILE>;
    fclose(FILE);

    fopen( FILE, "$vardir/maxpmattachsize.txt" );
    $pmMaxSizeAttach = <FILE>;
    fclose(FILE);

    fopen( PMATTACHLOG, "$vardir/pm.attachments" );
    my @pmAttachments = <PMATTACHLOG>;
    fclose(PMATTACHLOG);

    my $pmAttachmentSpace = 0;
    foreach (@pmAttachments) {
        $pmAttachmentSpace += NumberFormat( ( split /\|/xsm, $_, 4 )[2] );
    }

    my $pmRemainingSpace;
    if ( !$pmDirLimit ) {
        $pmRemainingSpace = "$fatxt{'23a'}";
    }
    else {
        $pmRemainingSpace = NumberFormat( ( $pmDirLimit - $pmAttachmentSpace ) ) . ' KB';
    }

    my $totalattachnum = @attachments;
    my $pmTotalAttachNum = @pmAttachments;
     $yymain .= qq~
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <td class="titlebg">$admin_img{'xx'} <b>$fatxt{'24'}</b></td>
    </tr><tr>
        <td class="windowbg">
            <div class="pad-more small">$fatxt{'25'}</div>
        </td>
    </tr><tr>
        <td class="catbg"><b>$fatxt{'26'}</b></td>
    </tr><tr>
        <td class="windowbg att_h_a">
            <b>$fatxt{'27'}</b>
        </td>
    </tr><tr>
        <td class="windowbg2">
            <table class="left pad-cell" style="margin-bottom:.5em">
                <tr>
                    <td class="small"><b>$fatxt{'28'}</b></td>
                    <td class="small">$totalattachnum</td>
                </tr><tr>
                    <td class="small"><b>$fatxt{'29'}</b></td>
                    <td class="small">$attachment_space KB<br /></td>
                </tr><tr>
                    <td class="small"><b>$fatxt{'30'}</b></td>
                    <td class="small">$remaining_space</td>
                </tr><tr>
                    <td colspan="2"><hr /></td>
                </tr><tr>
                    <td class="small"><b>$fatxt{'28a'}</b></td>
                    <td class="small">$pmTotalAttachNum</td>
                </tr><tr>
                    <td class="small"><b>$fatxt{'29a'}</b></td>
                    <td class="small">$pmAttachmentSpace KB<br /></td>
                </tr><tr>
                    <td class="small"><b>$fatxt{'30a'}</b></td>
                    <td class="small">$pmRemainingSpace</td>
                </tr>
            </table>
        </td>
    </tr><tr>
        <td class="windowbg att_h_a">
            <b>$fatxt{'31'}</b>
        </td>
    </tr><tr>
        <td class="windowbg2">
            <form action="$adminurl?action=removeoldattachments" method="post">
            <table class="pad-cell left" style="min-width:30%">
                <colgroup>
                    <col style="width:60%" />
                    <col style="width:20%" span="2" />
                </colgroup>
                <tr>
                    <td class="small">$fatxt{'32'}</td>
                    <td class="small"><input type="text" name="maxdaysattach" size="2" value="$maxdaysattach" /> $fatxt{'58'}&nbsp;</td>
                    <td><input type="submit" value="$admin_txt{'32'}" class="button" /></td>
                </tr>
            </table>
            </form>
            <form action="$adminurl?action=removebigattachments" method="post">
            <table class="pad-cell left" style="min-width:30%">
                <colgroup>
                    <col style="width:60%" />
                    <col style="width:20%" span="2" />
                </colgroup>
                <tr>
                    <td><span class="small">$fatxt{'33'}</span></td>
                    <td><span class="small"><input type="text" name="maxsizeattach" size="2" value="$maxsizeattach" /> KB&nbsp;</span></td>
                    <td><input type="submit" value="$admin_txt{'32'}" class="button" /></td>
                </tr><tr>
                    <td colspan="3">
                        <span class="small bold"><a href="$adminurl?action=manageattachments2">$fatxt{'31a'}</a></span> | <span class="small bold"><a href="$adminurl?action=rebuildattach">$fatxt{'63'}</a></span>
                    </td>
                </tr>
            </table>
            </form>
        </td>
    </tr><tr>
        <td class="windowbg att_h_a">
            <b>$fatxt{'31b'}</b>
        </td>
    </tr><tr>
        <td class="windowbg2">
            <form action="$adminurl?action=removeoldpmattachments" method="post">
            <table class="pad-cell left" style="min-width:30%">
                <colgroup>
                    <col style="width:60%" />
                    <col style="width:20%" span="2" />
                </colgroup>
                <tr>
                    <td><span class="small">$fatxt{'32a'}</span></td>
                    <td><span class="small"><input type="text" name="pmmaxdaysattach" size="2" value="$pmMaxDaysAttach" /> $fatxt{'58'}&nbsp;</span></td>
                    <td><input type="submit" value="$admin_txt{'32'}" class="button" /></td>
                </tr>
            </table>
            </form>
            <form action="$adminurl?action=removebigpmattachments" method="post">
            <table class="pad-cell left" style="min-width:30%">
                <colgroup>
                    <col style="width:60%" />
                    <col style="width:20%" span="2" />
                </colgroup>
                <tr>
                    <td><span class="small">$fatxt{'33a'}</span></td>
                    <td><span class="small"><input type="text" name="pmmaxsizeattach" size="2" value="$pmMaxSizeAttach" /> KB&nbsp;</span></td>
                    <td><input type="submit" value="$admin_txt{'32'}" class="button" /></td>
                </tr><tr>
                    <td colspan="3">
                        <span class="small bold"><a href="$adminurl?action=managepmattachments2">$fatxt{'31c'}</a></span> | <span class="small bold"><a href="$adminurl?action=rebuildpmattach">$fatxt{'63a'}</a></span>
                    </td>
                </tr>
            </table>
            </form>
        </td>
    </tr>
</table>
</div>~;

    $yytitle     = "$fatxt{'36'}";
    $action_area = 'manageattachments';
    AdminTemplate();
    return;
}

sub RemoveOldAttachments {
    is_admin_or_gmod();

    my $maxdaysattach = $FORM{'maxdaysattach'} || $INFO{'maxdaysattach'};
    if ( $maxdaysattach !~ /^[0-9]+$/xsm ) {
        fatal_error('only_numbers_allowed');
    }

    # Set up the multi-step action
    $time_to_jump = time() + $max_process_time;

    automaintenance('on');

    opendir ATT, $uploaddir
      || fatal_error( 'cannot_open', "$uploaddir", 1 );
    my @attachments = sort grep { /\w+$/xsm } readdir ATT;
    closedir ATT;

    fopen( AML, "$vardir/attachments.txt" );
    my @attachmentstxt = <AML>;
    fclose(AML);

    my ( %att, @line );
    foreach (@attachmentstxt) {
        @line = split /\|/xsm, $_;
        $att{ $line[7] } = $line[0];
    }

    my $info;
    if ( !@attachments ) {
        fopen( ATT, ">$vardir/attachments.txt" )
          || fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
        print {ATT} q{} or croak "$croak{'print'} ATT";
        fclose(ATT);

        $info = qq~<br /><i>$fatxt{'48'}.</i>~;
    }
    else {
        if ( !exists $INFO{'next'} ) { unlink "$vardir/rem_old_attach.tmp"; }

        my %rem_attachments;
        for my $aa ( ( $INFO{'next'} || 0 ) .. ( @attachments - 1 ) ) {

            # -M => Script start time minus file modification time, in days.
            my $age = sprintf '%.2f', -M "$uploaddir/$attachments[$aa]";
            if ( $age <= $maxdaysattach ) {

                # If the attachment is not too old
                $info .= qq~<br />$attachments[$aa] = $age $admin_txt{'122'}.~;

            }
            elsif ( exists $att{ $attachments[$aa] } ) {
                $rem_attachments{ $att{ $attachments[$aa] } } .=
                  $rem_attachments{ $att{ $attachments[$aa] } }
                  ? "|$attachments[$aa]"
                  : $attachments[$aa];
                $info .=
qq~<br /><i>$attachments[$aa]</i> $fatxt{'1'} = $age $admin_txt{'122'}.~;
            }

            if ( $time_to_jump < time() && ( $aa + 1 ) < @attachments ) {

            # save the $info of this run until the end of 'RemoveOldAttachments'
                fopen( FILE, ">>$vardir/rem_old_attach.tmp" )
                  || fatal_error( 'cannot_open',
                    "$vardir/rem_old_attach.tmp", 1 );
                print $info or croak "$croak{'print'} rem_old_attach";
                fclose(FILE);

                $yySetLocation =
qq~$adminurl?action=removeoldattachments;maxdaysattach=$maxdaysattach;next=~
                  . ( $aa + 1 - RemoveAttachments( \%rem_attachments ) );
                redirectexit();
            }
        }
        RemoveAttachments( \%rem_attachments );
    }

    automaintenance('off');

    $yymain .= qq~<b>$fatxt{'32'} $maxdaysattach $fatxt{'58'}.</b><br />~;

    fopen( FILE, "$vardir/rem_old_attach.tmp" );

    #    $yymain .= join( q{}, <FILE> ) . $info;
    $yymain .= do { local $INPUT_RECORD_SEPARATOR = undef; <FILE> }
      . $info;
    fclose(FILE);
    unlink "$vardir/rem_old_attach.tmp";

    fopen( FILE, ">$vardir/oldestattach.txt" );
    print {FILE} $maxdaysattach or croak "$croak{'print'} oldestattach";
    fclose(FILE);

    $yytitle     = "$fatxt{'34'} $maxdaysattach";
    $action_area = 'removeoldattachments';
    AdminTemplate();
    return;
}

sub RemoveBigAttachments {
    is_admin_or_gmod();

    my $maxsizeattach = $FORM{'maxsizeattach'} || $INFO{'maxsizeattach'};
    if ( $maxsizeattach !~ /^[0-9]+$/xsm ) {
        fatal_error('only_numbers_allowed');
    }

    # Set up the multi-step action
    $time_to_jump = time() + $max_process_time;

    automaintenance('on');

    opendir ATT, $uploaddir
      || fatal_error( 'cannot_open', "$uploaddir", 1 );
    my @attachments = sort grep { /\w+$/xsm } readdir ATT;
    closedir ATT;

    fopen( FILE, "$vardir/attachments.txt" );
    @attachmentstxt = <FILE>;
    fclose(FILE);

    my ( %att, @line );
    foreach (@attachmentstxt) {
        @line = split /\|/xsm, $_;
        $att{ $line[7] } = $line[0];
    }

    my $info;
    if ( !@attachments ) {
        fopen( ATT, ">$vardir/attachments.txt" )
          || fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
        print {ATT} q{} or croak "$croak{'print'} ATT";
        fclose(ATT);

        $info = qq~<br /><i>$fatxt{'48'}.</i>~;
    }
    else {
        if ( !exists $INFO{'next'} ) { unlink "$vardir/rem_big_attach.tmp"; }

        my (%rem_attachments);
        for my $aa ( ( $INFO{'next'} || 0 ) .. ( @attachments - 1 ) ) {
            my $size = sprintf '%.2f',
              ( ( -s "$uploaddir/$attachments[$aa]" ) / 1024 );
            if ( $size <= $maxsizeattach ) {

                # If the attachment is not too big
                $info .= qq~<br />$attachments[$aa] = $size KB~;

            }
            elsif ( exists $att{ $attachments[$aa] } ) {
                $rem_attachments{ $att{ $attachments[$aa] } } .=
                  $rem_attachments{ $att{ $attachments[$aa] } }
                  ? "|$attachments[$aa]"
                  : $attachments[$aa];
                $info .=
                  qq~<br /><i>$attachments[$aa]</i> $fatxt{'1'} = $size KB~;
            }
            if ( $time_to_jump < time() && ( $aa + 1 ) < @attachments ) {

            # save the $info of this run until the end of 'RemoveBigAttachments'
                fopen( FILE, ">>$vardir/rem_big_attach.tmp" )
                  || fatal_error( 'cannot_open',
                    "$vardir/rem_big_attach.tmp", 1 );
                print $info or croak "$croak{'print'} rem_big_attach";
                fclose(FILE);

                $yySetLocation =
qq~$adminurl?action=removebigattachments;maxsizeattach=$maxsizeattach;next=~
                  . ( $aa + 1 - RemoveAttachments( \%rem_attachments ) );
                redirectexit();
            }
        }

        RemoveAttachments( \%rem_attachments );
    }

    $yymain .= qq~<b>$fatxt{'33'} $maxsizeattach KB.</b><br />~;

    fopen( FILE, "$vardir/rem_big_attach.tmp" );

    #    $yymain .= join( q{}, <FILE> ) . $info;
    $yymain .= do { local $INPUT_RECORD_SEPARATOR = undef; <FILE> }
      . $info;
    fclose(FILE);
    unlink "$vardir/rem_big_attach.tmp";

    fopen( FILE, ">$vardir/maxattachsize.txt" );
    print {FILE} $maxsizeattach or croak "$croak{'print'} FILE";
    fclose(FILE);

    automaintenance('off');

    $yytitle     = "$fatxt{'35'} $maxsizeattach KB";
    $action_area = 'removebigattachments';
    AdminTemplate();
    return;
}

sub Attachments2 {
    is_admin_or_gmod();

    fopen( AML, "$vardir/attachments.txt" );
    my @attachinput = <AML>;
    fclose(AML);
    my $max = @attachinput;

    my $action   = $INFO{'action'};
    my $sort     = $INFO{'sort'} || 6;
    my $newstart = $INFO{'newstart'} || 0;

    if ( !$max ) {
        $viewattachments .=
qq~<tr><td class="windowbg2 padd-cell center" colspan="8"><b><i>$fatxt{'48'}</i></b></td></tr>~;
    }
    else {
        $yymain .= qq~
        <script type="text/javascript">
            function checkAll() {
                for (var i = 0; i < document.del_attachments.elements.length; i++) {
                    document.del_attachments.elements[i].checked = true;
                }
            }
            function uncheckAll() {
                for (var i = 0; i < document.del_attachments.elements.length; i++) {
                    document.del_attachments.elements[i].checked = false;
                }
            }
        </script>
        <form name="del_attachments" action="$adminurl?action=deleteattachment" method="post" style="display: inline;">~;

        my @attachments;
        if ( $sort > 0 ) {    # sort ascending
            if ( $sort == 5 || $sort == 6 || $sort == 8 ) {
                @attachments = sort {
                    ( split /\|/xsm, $a )[$sort]
                      <=> ( split /\|/xsm, $b )[$sort];
                } @attachinput;    # sort size, date, count numerically
            }
            elsif ( $sort == 100 ) {
                @attachments = sort {
                    lc(   ( split /\./xsm, ( split /\|/xsm, $a )[7] )[1] ) cmp
                      lc( ( split /\./xsm, ( split /\|/xsm, $b )[7] )[1] );
                } @attachinput;    # sort extension lexically
            }
            else {
                @attachments = sort {
                    lc(   ( split /\|/xsm, $a )[$sort] ) cmp
                      lc( ( split /\|/xsm, $b )[$sort] );
                } @attachinput;    # sort lexically
            }
        }
        else {                     # sort descending
            if ( $sort == -5 || $sort == -6 || $sort == -8 ) {
                @attachments = reverse sort {
                    ( split /\|/xsm, $a )[ -$sort ]
                      <=> ( split /\|/xsm, $b )[ -$sort ];
                } @attachinput;    # sort size, date, count numerically
            }
            elsif ( $sort == -100 ) {
                @attachments = reverse sort {
                    lc(   ( split /\./xsm, ( split /\|/xsm, $a )[7] )[1] ) cmp
                      lc( ( split /\./xsm, ( split /\|/xsm, $b )[7] )[1] );
                } @attachinput;    # sort extension lexically
            }
            else {
                @attachments = reverse sort {
                    lc(   ( split /\|/xsm, $a )[ -$sort ] ) cmp
                      lc( ( split /\|/xsm, $b )[ -$sort ] );
                } @attachinput;    # sort lexically
            }
        }

        $postdisplaynum = 8;
        $newstart       = ( int( $newstart / 25 ) ) * 25;
        $tmpa           = 1;
        if ( $newstart >= ( ( $postdisplaynum - 1 ) * 25 ) ) {
            $startpage = $newstart - ( ( $postdisplaynum - 1 ) * 25 );
            $tmpa = int( $startpage / 25 ) + 1;
        }
        if ( $max >= $newstart + ( $postdisplaynum * 25 ) ) {
            $endpage = $newstart + ( $postdisplaynum * 25 );
        }
        else { $endpage = $max; }
        if ( $startpage > 0 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0;sort=$sort" class="norm">1</a>&nbsp;...&nbsp;~;
        }
        if ( $startpage == 25 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0;sort=$sort" class="norm">1</a>&nbsp;~;
        }
        foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
            if ( $counter % 25 == 0 ) {
                $pageindex .=
                  $newstart == $counter
                  ? qq~<b>$tmpa</b>&nbsp;~
                  : qq~<a href="$adminurl?action=$action;newstart=$counter;sort=$sort" class="norm">$tmpa</a>&nbsp;~;
                $tmpa++;
            }
        }
        $lastpn  = int( $max / 25 ) + 1;
        $lastptn = ( $lastpn - 1 ) * 25;
        if ( $endpage < $max - (25) ) { $pageindexadd = q~...&nbsp;~; }
        if ( $endpage != $max ) {
            $pageindexadd .=
qq~<a href="$adminurl?action=$action;newstart=$lastptn;sort=$sort">$lastpn</a>~;
        }
        $pageindex .= $pageindexadd;

        $pageindex =
qq~<div class="small" style="line-height: 2.5em; float: right; text-align: right; vertical-align: middle;">$fatxt{'64'}: $pageindex</div>~;

        $numbegin = ( $newstart + 1 );
        $numend   = ( $newstart + 25 );
        if   ( $numend > $max ) { $numend  = $max; }
        if   ( $max == 0 )      { $numshow = q{}; }
        else                    { $numshow = qq~($numbegin - $numend)~; }

        my ( %attach_gif, $ext );
        foreach my $row ( splice @attachments, $newstart, 25 ) {
            chomp $row;
            my (
                $amthreadid, $amreplies,      $amthreadsub,
                $amposter,   $amcurrentboard, $amkb,
                $amdate,     $amfn,           $amcount
            ) = split /\|/xsm, $row;

            if ( $amfn =~ /\.(.+?)$/xsm ) {
                $ext = $1;
            }
            if ( !exists $attach_gif{$ext} ) {
                $attach_gif{$ext} =
                  ( $ext && -e "$htmldir/Templates/Forum/$useimages/$ext.gif" )
                  ? "$ext.gif"
                  : 'paperclip.gif';
            }

            $amdate = timeformat($amdate);
            $amkb   = NumberFormat($amkb);
            if ( length($amthreadsub) > 30 ) {
                $amthreadsub = substr( $amthreadsub, 0, 30 ) . q{...};
            }
            my $amfna = $amfn;
            if ( length($amfn) > 30 ) {
                $amfna = substr( $amthreadsub, 0, 30 ) . q{...};
            }
            $viewattachments .= qq~<tr>
            <td class="windowbg2 center"><input type="checkbox" name="del_$amthreadid" value="$amfn" /></td>
            <td class="windowbg2"><a href="$uploadurl/$amfn" target="_blank">$amfna</a></td>
            <td class="windowbg2 center"><img src="$imagesdir/$attach_gif{$ext}" class="bottom" alt="" /></td>
            <td class="windowbg2 right">$amkb KB</td>
            <td class="windowbg2 center">$amdate</td>
            <td class="windowbg2 right">$amcount</td>
            <td class="windowbg2"><a href="$scripturl?num=$amthreadid/$amreplies#$amreplies" target="_blank">$amthreadsub</a></td>
            <td class="windowbg2 center">$amposter</td>
        </tr>~;
        }

        $viewattachments .= qq~<tr>
            <td class="catbg center">
                <input type="checkbox" name="checkall" id="checkall" value="" onclick="if(this.checked){checkAll();}else{uncheckAll();}" />
            </td>
            <td class="catbg" colspan="7">
                <div class="small" style="float: left; text-align: left;">
                    &lt;= <label for="checkall">$amv_txt{'38'}</label> &nbsp; <input type="submit" value="$admin_txt{'32'}" class="button" />
                </div>
        $pageindex
            </td>
        </tr>~;

        $yymain .= qq~
        <input type="hidden" name="newstart" value="$newstart" />~;
    }

    my $class_sortattach = $sort =~ /7/sm   ? 'catbg' : 'windowbg';
    my $class_sorttype   = $sort =~ /100/sm ? 'catbg' : 'windowbg';
    my $class_sortsize   = $sort =~ /5/sm   ? 'catbg' : 'windowbg';
    my $class_sortdate   = $sort =~ /6/sm   ? 'catbg' : 'windowbg';
    my $class_sorcount   = $sort =~ /8/sm   ? 'catbg' : 'windowbg';
    my $class_sortsubj   = $sort =~ /2/sm   ? 'catbg' : 'windowbg';
    my $class_sortuser   = $sort =~ /3/sm   ? 'catbg' : 'windowbg';

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <colgroup>
        <col style="width:7%" />
        <col style="width:18%" />
        <col style="width:5%" />
        <col style="width:7%" />
        <col style="width:23%" />
        <col style="width:5%" />
        <col style="width:22%" />
        <col style="width:13%" />
    </colgroup>
    <tr>
        <td class="titlebg" colspan="8">
            $admin_img{'xx'}&nbsp;<b>$fatxt{'39'}</b>
        </td>
    </tr><tr>
        <td class="windowbg" colspan="8">
        <div class="pad-more small">$fatxt{'38'}</div>
        </td>
    </tr><tr>
        <td class="titlebg center" colspan="8"><b>$fatxt{'55'}</b></td>
    </tr><tr>
       <td class="catbg att_h_b" colspan="8">
        <div class="small" style="float: left; text-align: left;">$fatxt{'28'} $max $numshow</div>
        $pageindex
        </td>
    </tr><tr class="att_h_b">
        <td class="windowbg center"><b>$fatxt{'45'}</b></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 7 ? -7 : 7 )
      . qq~';" class="$class_sortattach center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == 7 ? -7 : 7 )
      . qq~"><b>$fatxt{'40'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 100 ? -100 : 100 )
      . qq~';" class="$class_sorttype center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == 100 ? -100 : 100 )
      . qq~"><b>$fatxt{'40a'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 5 ? -5 : 5 )
      . qq~';" class="$class_sortsize center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == -5 ? 5 : -5 )
      . qq~"><b>$fatxt{'41'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 6 ? -6 : 6 )
      . qq~';" class="$class_sortdate center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == -6 ? 6 : -6 )
      . qq~"><b>$fatxt{'43'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 8 ? -8 : 8 )
      . qq~';" class="$class_sorcount center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == -8 ? 8 : -8 )
      . qq~"><b>$fatxt{'41a'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 2 ? -2 : 2 )
      . qq~';" class="$class_sortsubj center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == 2 ? -2 : 2 )
      . qq~"><b>$fatxt{'44'}</b></a></td>
        <td onclick="location.href='$adminurl?action=manageattachments2;sort=~
      . ( $sort == 3 ? -3 : 3 )
      . qq~';" class="$class_sortuser center att"><a href="$adminurl?action=manageattachments2;sort=~
      . ( $sort == 3 ? -3 : 3 )
      . qq~"><b>$fatxt{'42'}</b></a></td>
    </tr>
    $viewattachments
</table>
</div>~;

    if ($max) { $yymain .= '</form>'; }

    $yytitle     = "$fatxt{'37'}";
    $action_area = 'manageattachments';
    AdminTemplate();
    return;
}

sub DeleteAttachments {
    is_admin_or_gmod();

    if ( !$FORM{'formsession'} ) { automaintenance('on'); }

    my %rem_att;
    foreach ( keys %FORM ) {
        if ( $_ =~ /^del_(\d+)$/xsm ) {
            my $thread = $1;
            $rem_att{$thread} = $FORM{$_};
            $rem_att{$thread} =~ s/, /|/gsm;
        }
        else { next; }
    }

    RemoveAttachments( \%rem_att );

    if ( !$FORM{'formsession'} ) { automaintenance('off'); }

    $yySetLocation =
      $FORM{'formsession'}
      ? qq~$scripturl?action=viewdownloads;thread=~
      . ( keys %rem_att )[0]
      . qq~;newstart=$FORM{'newstart'}~
      : qq~$adminurl?action=manageattachments2;newstart=$FORM{'newstart'}~;
    redirectexit();
    return;
}

sub FullRebuildAttachents {
    is_admin_or_gmod();

    if ( !defined $INFO{'boardnum'} ) {
        automaintenance('on');

        unlink "$vardir/newattachments.tmp";
        $yySetLocation =
          qq~$adminurl?action=rebuildattach;topicnum=0;boardnum=0~;
        redirectexit();
    }

    # Set up the multi-step action
    $time_to_jump = time() + $max_process_time;

    # Get the board list from the forum.master file
    require "$boardsdir/forum.master";
    @boardlist = sort keys %board;

    # Find the current board:
    my $curboard = $boardlist[ $INFO{'boardnum'} ];

    # store all downloadcounts in variable
    my %attachments;
    if ( ( -s "$vardir/attachments.txt" ) > 5 ) {
        my ( $atfile, $atcount );
        fopen( ATM, "$vardir/attachments.txt" );
        while (<ATM>) {
            (
                undef, undef, undef,   undef, undef,
                undef, undef, $atfile, $atcount
            ) = split /\|/xsm, $_;
            chomp $atcount;
            $attachments{$atfile} = $atcount;
        }
        fclose(ATM);
    }

    # Get the topic list.
    fopen( BOARD, "$boardsdir/$curboard.txt" );
    my @topiclist = <BOARD>;
    fclose(BOARD);

    my ( $topicnum, @newattachments, $mreplies, $msub, $mname, $mdate, $mfn,
        $nexttopic );
    for my $i ( $INFO{'topicnum'} .. ( @topiclist - 1 ) ) {
        ( $topicnum, undef ) = split /\|/xsm, $topiclist[$i], 2;
        fopen( TOPIC, "$datadir/$topicnum.txt" );
        my @topic = <TOPIC>;
        fclose(TOPIC);
        chomp @topic;

        $mreplies = 0;
        foreach (@topic) {
            (
                $msub, $mname, undef, $mdate, undef, undef, undef,
                undef, undef,  undef, undef,  undef, $mfn
            ) = split /\|/xsm, $_;
            foreach ( split /,/xsm, $mfn ) {
                if ( -e "$uploaddir/$_" ) {
                    my $asize = int( ( -s "$uploaddir/$_" ) / 1024 ) || 1;
                    push @newattachments,
qq~$topicnum|$mreplies|$msub|$mname|$curboard|$asize|$mdate|$_|~
                      . ( $attachments{$_} || 0 ) . qq~\n~;
                }
            }
            $mreplies++;
        }

        if ( time() > $time_to_jump && ( $i + 1 ) < @topiclist ) {
            $nexttopic = $i + 1;
            last;
        }
    }

    if (@newattachments) {
        fopen( NEWATM, ">>$vardir/newattachments.tmp" )
          || fatal_error( 'cannot_open', "$vardir/newattachments.tmp",
            1 );
        print {NEWATM} @newattachments or croak "$croak{'print'} NEWATM";
        fclose(NEWATM);
    }

    # Prepare to continue...
    if ($nexttopic) { $INFO{'topicnum'} = $nexttopic; }
    else            { $INFO{'boardnum'}++; $INFO{'topicnum'} = 0; }

    my $numleft = @boardlist - $INFO{'boardnum'};
    if ( $numleft == 0 ) {
        fopen( NEWATM, "$vardir/newattachments.tmp" );
        @newattachments = <NEWATM>;
        fclose(NEWATM);

        fopen( ATM, ">$vardir/attachments.txt" );
        print {ATM}
          sort { ( split /\|/xsm, $a )[6] <=> ( split /\|/xsm, $b )[6] }
            @newattachments
          or croak "$croak{'print'} ATM";
        fclose(ATM);
        unlink "$vardir/newattachments.tmp";

        automaintenance('off');
        $yySetLocation = qq~$adminurl?action=remghostattach~;
        redirectexit();
    }

    # Continue
    $action_area = 'manageattachments';
    $yytitle     = "$fatxt{'37'}";

    $yymain .= qq~
        <br />
        $rebuild_txt{'1'}<br />
        $rebuild_txt{'5'} $max_process_time $rebuild_txt{'6'}<br />
        $rebuild_txt{'9'} ~
      . ( @boardlist - $INFO{'boardnum'} ) . q{/} . @boardlist . qq~<br />
        <br />
        <div id="attachcontinued">
        $rebuild_txt{'2'} <a href="$adminurl?action=rebuildattach;topicnum=$INFO{'topicnum'};boardnum=$INFO{'boardnum'}" onclick="rebAttach();">$rebuild_txt{'3'}</a>
        </div>
    <script type="text/javascript">
        function rebAttach() {
            document.getElementById("attachcontinued").innerHTML = '$rebuild_txt{'4'}';
        }

        function attachtick() {
            rebAttach();
            location.href="$adminurl?action=rebuildattach;topicnum=$INFO{'topicnum'};boardnum=$INFO{'boardnum'}";
        }

        setTimeout("attachtick()",3000)
    </script>~;

    AdminTemplate();
    return;
}

sub RemoveGhostAttach {
    is_admin_or_gmod();

    $yymain .= qq~<b>$fatxt{'62'}</b><br /><br />~;

    fopen( ATM, "$vardir/attachments.txt" );
    my @attachmentstxt = <ATM>;
    fclose(ATM);

    my %att;
    foreach (@attachmentstxt) {
        $att{ ( split /\|/xsm, $_ )[7] } = 1;
    }

    opendir DIR, $uploaddir;
    my @filesDIR = grep { /\w+$/xsm } readdir DIR;
    closedir DIR;

    $yymain .= qq~$fatxt{'61'}:<br />~;

    foreach my $fileinDIR (@filesDIR) {
        if ( !$att{$fileinDIR} && $fileinDIR ne 'index.html' && $fileinDIR ne '.htaccess'  ) {
            unlink "$uploaddir/$fileinDIR";
            $yymain .= qq~<br />$fatxt{'61b'}: $fileinDIR~;
        }
    }

    $yymain .= qq~<br /><br /><b>$fatxt{'61a'}</b>~;
    $yytitle     = $fatxt{'61'};
    $action_area = 'manageattachments';
    AdminTemplate();
    return;
}

sub RemoveAttachments
{    # remove single or multiple attachments stored in a hash-reference
    my $count = 0;
    my $ThreadHashref =
      shift; # usage: ${$ThreadHashref}{'threadnum'} = 'filename1|filename2|...'
        # all attachments of thread are included if filname is undefined (undef)

    if ( !%{$ThreadHashref} ) { return $count; }

    fopen( ATM, "+<$vardir/attachments.txt", 1 )
      || fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
    seek ATM, 0, 0;
    my @attachments = <ATM>;
    truncate ATM, 0;
    seek ATM, 0, 0;
    my ( $athreadnum, $afilename, %del_filename );
    foreach (@attachments) {
        ( undef, undef, undef, undef, undef, undef, undef, $afilename, undef ) =
          split /\|/xsm, $_;
        $del_filename{$afilename}++;
    }
    for my $i ( 0 .. ( @attachments - 1 ) ) {
        (
            $athreadnum, undef, undef,      undef, undef,
            undef,       undef, $afilename, undef
        ) = split /\|/xsm, $attachments[$i];
        my $del = 0;
        if ( exists ${$ThreadHashref}{$athreadnum} ) {
            if ( defined ${$ThreadHashref}{$athreadnum} ) {
                foreach ( split /\|/xsm, ${$ThreadHashref}{$athreadnum} ) {
                    if ( $_ eq $afilename ) { $del = 1; last; }
                }
            }
            else {
                $del = 1;
            }
        }
        if ($del) {

# deletes the file only if NO other entry for the same filename is in the attachments.txt
            if ( $del_filename{$afilename} == 1 ) {
                unlink "$uploaddir/$afilename";
            }
            $del_filename{$afilename}--;
            $count++;
        }
        else {
            print {ATM} $attachments[$i] or croak "$croak{'print'} ATM";
        }
    }
    fclose(ATM);

    return $count;
}
sub PMAttachments2 {
    is_admin_or_gmod();

    fopen( PMATTACHLOG, "$vardir/pm.attachments" );
    my @pmAttachInput = <PMATTACHLOG>;
    fclose(PMATTACHLOG);
    my $max = @pmAttachInput;

    my $action   = $INFO{'action'};
    my $sort     = $INFO{'sort'} || 1;
    my $newstart = $INFO{'newstart'} || 0;

    if ( !$max ) {
        $viewattachments .=
qq~<tr><td class="windowbg2 padd-cell center" colspan="6"><b><i>$fatxt{'48a'}</i></b></td></tr>~;

    }
    else {
        $yymain .= qq~
        <script type="text/javascript">
            function checkAll() {
                for (var i = 0; i < document.del_attachments.elements.length; i++) {
                    document.del_attachments.elements[i].checked = true;
                }
            }
            function uncheckAll() {
                for (var i = 0; i < document.del_attachments.elements.length; i++) {
                    document.del_attachments.elements[i].checked = false;
                }
            }
        </script>

        <form name="del_attachments" action="$adminurl?action=deletepmattachment" method="post" style="display: inline;">~;

        my @pmAttachments;
        if ( $sort > 0 ) {    # sort ascending
            if ( $sort == 2 || $sort == 1 ) {
                @pmAttachments = sort {
                    ( split /\|/xsm, $a )[$sort]
                      <=> ( split /\|/xsm, $b )[$sort];
                } @pmAttachInput;    # sort size, date numerically
            }
            elsif ( $sort == 100 ) {
                @pmAttachments = sort {
                    lc(   ( split /\./xsm, ( split /\|/xsm, $a )[3] )[1] ) cmp
                      lc( ( split /\./xsm, ( split /\|/xsm, $b )[3] )[1] );
                } @pmAttachInput;    # sort extension lexically
            }
            else {
                @pmAttachments = sort {
                    lc(   ( split /\|/xsm, $a )[$sort] ) cmp
                      lc( ( split /\|/xsm, $b )[$sort] );
                } @pmAttachInput;    # sort lexically
            }
        }
        else {                     # sort descending
            if ( $sort == -2 || $sort == -1 ) {
                @pmAttachments = reverse sort {
                    ( split /\|/xsm, $a )[ -$sort ]
                      <=> ( split /\|/xsm, $b )[ -$sort ];
                } @pmAttachInput;    # sort size, date numerically
            }
            elsif ( $sort == -100 ) {
                @pmAttachments = reverse sort {
                    lc(   ( split /\./xsm, ( split /\|/xsm, $a )[3] )[1] ) cmp
                      lc( ( split /\./xsm, ( split /\|/xsm, $b )[3] )[1] );
                } @pmAttachInput;    # sort extension lexically
            }
            else {
                @pmAttachments = reverse sort {
                    lc(   ( split /\|/xsm, $a )[ -$sort ] ) cmp
                      lc( ( split /\|/xsm, $b )[ -$sort ] );
                } @pmAttachInput;    # sort lexically
            }
        }

        $postdisplaynum = 8;
        $newstart       = ( int( $newstart / 25 ) ) * 25;
        $tmpa           = 1;
        if ( $newstart >= ( ( $postdisplaynum - 1 ) * 25 ) ) {
            $startpage = $newstart - ( ( $postdisplaynum - 1 ) * 25 );
            $tmpa = int( $startpage / 25 ) + 1;
        }
        if ( $max >= $newstart + ( $postdisplaynum * 25 ) ) {
            $endpage = $newstart + ( $postdisplaynum * 25 );
        }
        else { $endpage = $max; }
        if ( $startpage > 0 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0;sort=$sort" class="norm">1</a>&nbsp;...&nbsp;~;
        }
        if ( $startpage == 25 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0;sort=$sort" class="norm">1</a>&nbsp;~;
        }
        foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
            if ( $counter % 25 == 0 ) {
                $pageindex .=
                  $newstart == $counter
                  ? qq~<b>$tmpa</b>&nbsp;~
                  : qq~<a href="$adminurl?action=$action;newstart=$counter;sort=$sort" class="norm">$tmpa</a>&nbsp;~;
                $tmpa++;
            }
        }
        $lastpn  = int( $max / 25 ) + 1;
        $lastptn = ( $lastpn - 1 ) * 25;
        if ( $endpage < $max - (25) ) { $pageindexadd = q~...&nbsp;~; }
        if ( $endpage != $max ) {
            $pageindexadd .=
qq~<a href="$adminurl?action=$action;newstart=$lastptn;sort=$sort">$lastpn</a>~;
        }
        $pageindex .= $pageindexadd;

        $pageindex =
qq~<div class="small" style="line-height: 2.5em; float: right; text-align: right; vertical-align: middle;">$fatxt{'64'}: $pageindex</div>~;

        $numbegin = ( $newstart + 1 );
        $numend   = ( $newstart + 25 );
        if   ( $numend > $max ) { $numend  = $max; }
        if   ( $max == 0 )      { $numshow = q{}; }
        else                    { $numshow = qq~($numbegin - $numend)~; }

        my ( %attach_gif, $ext );
        foreach my $row ( splice @pmAttachments, $newstart, 25 ) {
            my ( undef, $pmAttachDate, $pmAttachKB, $pmAttachName, $pmAttachUser, undef ) = split /\|/xsm, $row;
            chomp $pmAttachUser;
            if ( $pmAttachName =~ /\.(.+?)$/xsm ) {
                $ext = $1;
            }
            if ( !exists $attach_gif{$ext} ) {
                $attach_gif{$ext} =
                  ( $ext && -e "$htmldir/Templates/Forum/$useimages/$ext.gif" )
                  ? "$ext.gif"
                  : 'paperclip.gif';
            }

            $pmthreadid   = $pmAttachDate;
            $pmAttachDate = timeformat($pmAttachDate);
            $pmAttachKB   = NumberFormat($pmAttachKB);

            my $pmfna = $pmAttachName;
            if ( length($pmAttachName) > 30 ) {
                $pmfna = substr( $pmAttachName, 0, 30 ) . q{...};
            }
            $viewattachments .= qq~<tr>
            <td class="windowbg2 center"><input type="checkbox" name="del_$pmthreadid" value="$pmAttachName" /></td>
            <td class="windowbg2"><a href="$pmuploadurl/$pmAttachName" target="_blank">$pmfna</a></td>
            <td class="windowbg2 center"><img src="$imagesdir/$attach_gif{$ext}" class="bottom" alt="" /></td>
            <td class="windowbg2 right">$pmAttachKB KB</td>
            <td class="windowbg2 center">$pmAttachDate</td>
            <td class="windowbg2 center">$pmAttachUser</td>
        </tr>~;
        }

        $viewattachments .= qq~<tr>
            <td class="catbg center">
                <input type="checkbox" name="checkall" id="checkall" value="" onclick="if(this.checked){checkAll();}else{uncheckAll();}" />
            </td>
            <td class="catbg" colspan="5">
                <div class="small" style="float: left; text-align: left;">
                    &lt;= <label for="checkall">$amv_txt{'38'}</label> &nbsp; <input type="submit" value="$admin_txt{'32'}" class="button" />
                </div>
        $pageindex
            </td>
        </tr>~;

        $yymain .= qq~
        <input type="hidden" name="newstart" value="$newstart" />~;
    }

    my $class_sortattach = $sort =~ /3/sm   ? 'catbg' : 'windowbg';
    my $class_sorttype   = $sort =~ /100/sm ? 'catbg' : 'windowbg';
    my $class_sortsize   = $sort =~ /2/sm   ? 'catbg' : 'windowbg';
    my $class_sortdate   = $sort =~ /1/sm   ? 'catbg' : 'windowbg';
    my $class_sortuser   = $sort =~ /4/sm   ? 'catbg' : 'windowbg';

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <colgroup>
        <col style="width:8%" />
        <col style="width:30%" />
        <col style="width:10%" />
        <col style="width:12%" />
        <col style="width:30%" />
        <col style="width:15%" />
    </colgroup>
    <tr>
        <td class="titlebg" colspan="6">
            $admin_img{'xx'}&nbsp;<b>$fatxt{'39a'}</b>
        </td>
    </tr><tr>
        <td class="windowbg" colspan="6">
        <div class="pad-more small">$fatxt{'38a'}</div>
        </td>
    </tr><tr>
        <td class="titlebg center" colspan="6"><b>$fatxt{'55a'}</b></td>
    </tr><tr>
         <td class="catbg att_h_b" colspan="6">
        <div class="small" style="float: left; text-align: left;">$fatxt{'28'} $max $numshow</div>
        $pageindex
        </td>
    </tr><tr class="att_h_b">
        <td class="windowbg center"><b>$fatxt{'45'}</b></td>
        <td onclick="location.href='$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 3 ? -3 : 3 )
      . qq~';" class="$class_sortattach center att"><a href="$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 3 ? -3 : 3 )
      . qq~"><b>$fatxt{'40'}</b></a></td>
        <td onclick="location.href='$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 100 ? -100 : 100 )
      . qq~';" class="$class_sorttype center att"><a href="$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 100 ? -100 : 100 )
      . qq~"><b>$fatxt{'40a'}</b></a></td>
        <td onclick="location.href='$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 2 ? -2 : 2 )
      . qq~';" class="$class_sortsize center att"><a href="$adminurl?action=managepmattachments2;sort=~
      . ( $sort == -2 ? 2 : -2 )
      . qq~"><b>$fatxt{'41'}</b></a></td>
        <td onclick="location.href='$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 1 ? -1 : 1 )
      . qq~';" class="$class_sortdate center att"><a href="$adminurl?action=managepmattachments2;sort=~
      . ( $sort == -1 ? 1 : -1 )
      . qq~"><b>$fatxt{'43'}</b></a></td>
        <td onclick="location.href='$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 4 ? -4 : 4 )
      . qq~';" class="$class_sortuser center att"><a href="$adminurl?action=managepmattachments2;sort=~
      . ( $sort == 4 ? -4 : 4 )
      . qq~"><b>$fatxt{'42a'}</b></a></td>
    </tr>
   $viewattachments
</table>
</div>~;

    if ($max) { $yymain .= '</form>'; }

    $yytitle     = "$fatxt{'37a'}";
    $action_area = 'managepmattachments';
    AdminTemplate();
    return;
}

sub DeletePMAttachments {
    is_admin_or_gmod();

    if ( !$FORM{'formsession'} ) { automaintenance('on'); }

    my %rem_att;
    foreach ( keys %FORM ) {
        if ( $_ =~ /^del_(\d+)$/xsm ) {
            my $thread = $1;
            $rem_att{$thread} = $FORM{$_};
            $rem_att{$thread} =~ s/, /|/gsm;
        }
        else { next; }
    }

    RemovePMAttachments( \%rem_att );

    if ( !$FORM{'formsession'} ) { automaintenance('off'); }

    $yySetLocation = qq~$adminurl?action=managepmattachments2;newstart=$FORM{'newstart'}~;
    redirectexit();
    return;
}

sub RemoveOldPMAttachments {
    is_admin_or_gmod();

    my $pmMaxDaysAttach = $FORM{'pmmaxdaysattach'} || $INFO{'pmmaxdaysattach'};
    if ( $pmMaxDaysAttach !~ /^[0-9]+$/xsm ) {
        fatal_error('only_numbers_allowed');
    }

    # Set up the multi-step action
    $time_to_jump = time() + $max_process_time;

    automaintenance('on');

    opendir PMATTACHDIR, $pmuploaddir
      || fatal_error( 'cannot_open', "$pmuploaddir", 1 );
    my @pmAttachments = sort grep { /\w+$/xsm } readdir PMATTACHDIR;
    closedir PMATTACHDIR;

    fopen( PMATTACHLOG, "$vardir/pm.attachments" );
    my @pmAttachmentstxt = <PMATTACHLOG>;
    fclose(PMATTACHLOG);

    my ( %att, @line );
    foreach (@pmAttachmentstxt) {
        @line = split /\|/xsm, $_;
        $att{ $line[3] } = $line[0];
    }

    my $info;
    if ( !@pmAttachments ) {
        fopen( PMATTACHLOG, ">$vardir/pm.attachments" )
          || fatal_error( 'cannot_open', "$vardir/pm.attachments", 1 );
        print {PMATTACHLOG} q{} or croak "$croak{'print'} ATT";
        fclose(PMATTACHLOG);

        $info = qq~<br /><i>$fatxt{'48a'}.</i>~;
    }
    else {
        if ( !exists $INFO{'next'} ) { unlink "$vardir/rem_old_pm_attach.tmp"; }

        my %rem_attachments;
        for my $aa ( ( $INFO{'next'} || 0 ) .. ( @pmAttachments - 1 ) ) {

            # -M => Script start time minus file modification time, in days.
            my $age = sprintf '%.2f', -M "$pmuploaddir/$pmAttachments[$aa]";
            if ( $age <= $pmMaxDaysAttach ) {

                # If the attachment is not too old
                $info .= qq~<br />$pmAttachments[$aa] = $age $admin_txt{'122'}.~;

            }
            elsif ( exists $att{ $pmAttachments[$aa] } ) {
                $rem_attachments{ $att{ $pmAttachments[$aa] } } .=
                  $rem_attachments{ $att{ $pmAttachments[$aa] } }
                  ? "|$pmAttachments[$aa]"
                  : $pmAttachments[$aa];
                $info .=
qq~<br /><i>$pmAttachments[$aa]</i> $fatxt{'1'} = $age $admin_txt{'122'}.~;
            }

            if ( $time_to_jump < time() && ( $aa + 1 ) < @pmAttachments ) {

            # save the $info of this run until the end of 'RemoveOldPMAttachments'
                fopen( FILE, ">>$vardir/rem_old_pm_attach.tmp" )
                  || fatal_error( 'cannot_open',
                    "$vardir/rem_old_pm_attach.tmp", 1 );
                print $info or croak "$croak{'print'} rem_big_attach";
                fclose(FILE);

                $yySetLocation =
qq~$adminurl?action=removeoldpmattachments;pmmaxdaysattach=$pmMaxDaysAttach;next=~
                  . ( $aa + 1 - RemovePMAttachments( \%rem_attachments ) );
                redirectexit();
            }
        }
        RemovePMAttachments( \%rem_attachments );
    }

    automaintenance('off');

    $yymain .= qq~<b>$fatxt{'32a'} $pmMaxDaysAttach $fatxt{'58'}.</b><br />~;

    fopen( FILE, "$vardir/rem_old_pm_attach.tmp" );

    #    $yymain .= join( q{}, <FILE> ) . $info;
    $yymain .= do { local $INPUT_RECORD_SEPARATOR = undef; <FILE> }
      . $info;
    fclose(FILE);
    unlink "$vardir/rem_old_pm_attach.tmp";

    fopen( FILE, ">$vardir/oldestpmattach.txt" );
    print {FILE} $pmMaxDaysAttach or croak "$croak{'print'} FILE";
    fclose(FILE);

    $yytitle     = "$fatxt{'34a'} $pmMaxDaysAttach";
    $action_area = 'removeoldpmattachments';
    AdminTemplate();
    return;
}

sub RemoveBigPMAttachments {
    is_admin_or_gmod();

    my $pmmaxsizeattach = $FORM{'pmmaxsizeattach'} || $INFO{'pmmaxsizeattach'};
    if ( $pmmaxsizeattach !~ /^[0-9]+$/xsm ) {
        fatal_error('only_numbers_allowed');
    }

    # Set up the multi-step action
    $time_to_jump = time() + $max_process_time;

    automaintenance('on');

    opendir ATT, $pmuploaddir
      || fatal_error( 'cannot_open', "$pmuploaddir", 1 );
    my @attachments = sort grep { /\w+$/xsm } readdir ATT;
    closedir ATT;

    fopen( FILE, "$vardir/pm.attachments" );
    @pmAttachmentstxt = <FILE>;
    fclose(FILE);

    my ( %att, @line );
    foreach (@pmAttachmentstxt) {
        @line = split /\|/xsm, $_;
        $att{ $line[3] } = $line[0];
    }

    my $info;
    if ( !@attachments ) {
        fopen( ATT, ">$vardir/pm.attachments" )
          || fatal_error( 'cannot_open', "$vardir/pm.attachments", 1 );
        print {ATT} q{} or croak "$croak{'print'} ATT";
        fclose(ATT);

        $info = qq~<br /><i>$fatxt{'48a'}.</i>~;
    }
    else {
        if ( !exists $INFO{'next'} ) { unlink "$vardir/rem_big_pm_attach.tmp"; }

        my (%rem_attachments);
        for my $aa ( ( $INFO{'next'} || 0 ) .. ( @attachments - 1 ) ) {
            my $size = sprintf '%.2f',
              ( ( -s "$pmuploaddir/$attachments[$aa]" ) / 1024 );
            if ( $size <= $pmmaxsizeattach ) {

                # If the attachment is not too big
                $info .= qq~<br />$attachments[$aa] = $size KB~;

            }
            elsif ( exists $att{ $attachments[$aa] } ) {
                $rem_attachments{ $att{ $attachments[$aa] } } .=
                  $rem_attachments{ $att{ $attachments[$aa] } }
                  ? "|$attachments[$aa]"
                  : $attachments[$aa];
                $info .=
                  qq~<br /><i>$attachments[$aa]</i> $fatxt{'1'} = $size KB~;
            }
            if ( $time_to_jump < time() && ( $aa + 1 ) < @attachments ) {

            # save the $info of this run until the end of 'RemoveBigPMAttachments'
                fopen( FILE, ">>$vardir/rem_big_pm_attach.tmp" )
                  || fatal_error( 'cannot_open',
                    "$vardir/rem_big_pm_attach.tmp", 1 );
                print $info or croak "$croak{'print'} rem_big_pm_attach";
                fclose(FILE);

                $yySetLocation =
qq~$adminurl?action=removebigpmattachments;pmmaxsizeattach=$pmmaxsizeattach;next=~
                  . ( $aa + 1 - RemovePMAttachments( \%rem_attachments ) );
                redirectexit();
            }
        }

        RemovePMAttachments( \%rem_attachments );
    }

    $yymain .= qq~<b>$fatxt{'33a'} $pmmaxsizeattach KB.</b><br />~;

    fopen( FILE, "$vardir/rem_big_pm_attach.tmp" );

    #    $yymain .= join( q{}, <FILE> ) . $info;
    $yymain .= do { local $INPUT_RECORD_SEPARATOR = undef; <FILE> }
      . $info;
    fclose(FILE);
    unlink "$vardir/rem_big_pm_attach.tmp";

    fopen( FILE, ">$vardir/maxpmattachsize.txt" );
    print {FILE} $pmmaxsizeattach or croak "$croak{'print'} FILE";
    fclose(FILE);

    automaintenance('off');

    $yytitle     = "$fatxt{'33a'} $pmmaxsizeattach KB";
    $action_area = 'removebigpmattachments';
    AdminTemplate();
    return;
}

sub RemovePMAttachments {
    # remove single or multiple attachments stored in a hash-reference
    my $count = 0;
    my $ThreadHashref =
      shift; # usage: ${$ThreadHashref}{'threadnum'} = 'filename1|filename2|...'
        # all attachments of thread are included if filname is undefined (undef)

    if ( !%{$ThreadHashref} ) { return $count; }

    fopen( ATM, "+<$vardir/pm.attachments", 1 )
      || fatal_error( 'cannot_open', "$vardir/pm.attachments", 1 );
    seek ATM, 0, 0;
    my @pmAttachments = <ATM>;
    truncate ATM, 0;
    seek ATM, 0, 0;
    my ( $athreadnum, $afilename, %del_filename );
    foreach (@pmAttachments) {
        ( undef, undef, undef, $afilename, undef, undef ) =
          split /\|/xsm, $_;
        $del_filename{$afilename}++;
    }
    for my $i ( 0 .. ( @pmAttachments - 1 ) ) {
        (
            $athreadnum, undef, undef, $afilename, undef, undef
        ) = split /\|/xsm, $pmAttachments[$i];
        my $del = 0;
        if ( exists ${$ThreadHashref}{$athreadnum} ) {
            if ( defined ${$ThreadHashref}{$athreadnum} ) {
                foreach ( split /\|/xsm, ${$ThreadHashref}{$athreadnum} ) {
                    if ( $_ eq $afilename ) { $del = 1; last; }
                }
            }
            else {
                $del = 1;
            }
        }
        if ($del) {

# deletes the file only if NO other entry for the same filename is in the attachments.txt
            if ( $del_filename{$afilename} == 1 ) {
                unlink "$pmuploaddir/$afilename";
            }
            $del_filename{$afilename}--;
            $count++;
        }
        else {
            print {ATM} $pmAttachments[$i] or croak "$croak{'print'} ATM";
        }
    }
    fclose(ATM);

    return $count;
}

sub FullRebuildPMAttachments {
    is_admin_or_gmod();

    automaintenance('on');

    fopen( ATM, "$vardir/pm.attachments" );
    @pm_attach = <ATM>;
    fclose(ATM);
    foreach my $pmattach ( @pm_attach ) {
        chomp $pmattach;
        ( $atid, $atdate, $atsize, $atfile, $atuser, $atusername ) = split /\|/xsm, $pmattach;
        if ( -e "$pmuploaddir/$atfile" ) {
            push @newattachments, qq~$atid|$atdate|$atsize|$atfile|$atuser|$atusername\n~;
        }
    }

    if (@newattachments) {
        fopen( NEWATM, ">>$vardir/newpmattachments.tmp" )
          || fatal_error( 'cannot_open', "$vardir/newpmattachments.tmp",
            1 );
        print {NEWATM} @newattachments or croak "$croak{'print'} NEWATM";
        fclose(NEWATM);
    }

    fopen( NEWATM, "$vardir/newpmattachments.tmp" );
    @newattachments = <NEWATM>;
    fclose(NEWATM);

    fopen( ATM, ">$vardir/pm.attachments" );
    print {ATM}  @newattachments  or croak "$croak{'print'} ATM";
    fclose(ATM);
    unlink "$vardir/newpmattachments.tmp";

    automaintenance('off');
    $yySetLocation = qq~$adminurl?action=remghostpmattach~;
    redirectexit();

    return;
}

sub RemoveGhostPMAttach {
    is_admin_or_gmod();

    $yymain .= qq~<b>$fatxt{'62a'}</b><br /><br />~;

    fopen( ATM, "$vardir/pm.attachments" );
    my @attachmentstxt = <ATM>;
    fclose(ATM);

    my %att;
    foreach (@attachmentstxt) {
        $att{ ( split /\|/xsm, $_ )[3] } = 1;
    }

    opendir DIR, $pmuploaddir;
    my @filesDIR = grep { /\w+$/xsm } readdir DIR;
    closedir DIR;

    $yymain .= qq~$fatxt{'61c'}:<br />~;

    foreach my $fileinDIR (@filesDIR) {
        if ( !$att{$fileinDIR} && $fileinDIR ne 'index.html' && $fileinDIR ne '.htaccess'  ) {
            unlink "$pmuploaddir/$fileinDIR";
            $yymain .= qq~<br />$fatxt{'61b'}: $fileinDIR~;
        }
    }

    $yymain .= qq~<br /><br /><b>$fatxt{'61a'}</b>~;
    $yytitle     = $fatxt{'61c'};
    $action_area = 'manageattachments';
    AdminTemplate();
    return;
}
1;
