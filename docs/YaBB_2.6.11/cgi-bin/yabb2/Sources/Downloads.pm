###############################################################################
# Downloads.pm                                                                #
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

$downloadspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

get_template('Downloads');
get_micon();

sub DownloadView {
    if ( $guest_media_disallowed && $iamguest ) { fatal_error('members_only'); }
    LoadLanguage('FA');
    print_output_header();

    $output = $downloads_top;
    $output =~ s/{yabb fatxt39}/$fatxt{'39'}/sm;

    my $thread = $INFO{'thread'};
    if ( !ref $thread_arrayref{$thread} ) {
        fopen( MSGTXT, "$datadir/$thread.txt" )
          or fatal_error( 'cannot_open', "$datadir/$thread.txt", 1 );
        @{ $thread_arrayref{$thread} } = <MSGTXT>;
        fclose(MSGTXT);
    }
    my $threadname = ( split /\|/xsm, ${ $thread_arrayref{$thread} }[0], 2 )[0];
    my @attachinput =
      map { split /,/xsm, ( split /\|/xsm, $_ )[12] }
      @{ $thread_arrayref{$thread} };
    chomp @attachinput;

    my ( %attachinput, $viewattachments );
    map { $attachinput{$_} = 1; } @attachinput;

    fopen( AML, "$vardir/attachments.txt" )
      or fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
    @attachinput =
      grep { $_ =~ /$thread\|.+\|(.+)\|\d+\s+/xsm && exists $attachinput{$1} }
      <AML>;
    fclose(AML);

    my $max = @attachinput;

    my $sort = $INFO{'sort'}
      || (
        (
            ( $ttsureverse && ${ $uid . $username }{'reversetopic'} )
            || $ttsreverse
        ) ? -1 : 1
      );
    my $newstart = $INFO{'newstart'} || 0;

    my $colspan = ( $iamadmin || $iamgmod ) ? 8 : 7;
    if ( !$max ) {
        $viewattachments .= $downloads_att;
        $viewattachments =~ s/{yabb colspan}/$colspan/gsm;
        $viewattachments =~ s/{yabb colspan}/$colspan/gsm;
        $viewattachments =~ s/{yabb threadname}/$threadname/gsm;
        $viewattachments =~ s/{yabb fatxt48}/$fatxt{'38'}/gsm;
        $viewattachments =~ s/{yabb fatxt70}/$fatxt{'70'}/gsm;
        $viewattachments =~ s/{yabb fatxt71}/$fatxt{'71'}/gsm;
    }
    else {
        if ( $iamadmin || $iamgmod ) {
            LoadLanguage('Admin');

            $output .= qq~
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
            function verify_delete() {
                for (var i = 0; i < document.del_attachments.elements.length; i++) {
                    if (document.del_attachments.elements[i].checked === true) {
                        Check = confirm('$fatxt{'46a'}');
                        if (Check==true) document.del_attachments.action = '$adminurl?action=deleteattachment';
                        break;
                    }
                }
            }
        </script>
        <form name="del_attachments" action="$scripturl?action=viewdownloads;thread=$thread" method="post" style="display: inline;" onsubmit="verify_delete();">~;
        }
        else {
            $output .= qq~
        <form action="$scripturl?action=viewdownloads;thread=$thread" method="post" style="display: inline;">~;
        }
        $output .= qq~
        <input type="hidden" name="oldsort" value="$sort" />
        <input type="hidden" name="formsession" value="$formsession" />~;

        my @attachments;
        if ( $sort > 0 ) {    # sort ascending
            if ( $sort == 1 || $sort == 5 || $sort == 6 || $sort == 8 ) {
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
            if ( $sort == -1 || $sort == -5 || $sort == -6 || $sort == -8 ) {
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
qq~<a href="$scripturl?action=viewdownloads;thread=$thread;newstart=0;sort=$sort" class="norm">1</a>&nbsp;...&nbsp;~;
        }
        if ( $startpage == 25 ) {
            $pageindex =
qq~<a href="$scripturl?action=viewdownloads;thread=$thread;newstart=0;sort=$sort" class="norm">1</a>&nbsp;~;
        }
        foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
            if ( $counter % 25 == 0 ) {
                $pageindex .=
                  $newstart == $counter
                  ? qq~<b>$tmpa</b>&nbsp;~
                  : qq~<a href="$scripturl?action=viewdownloads;thread=$thread;newstart=$counter;sort=$sort" class="norm">$tmpa</a>&nbsp;~;
                $tmpa++;
            }
        }
        $lastpn  = int( $max / 25 ) + 1;
        $lastptn = ( $lastpn - 1 ) * 25;
        if ( $endpage < $max - (25) ) { $pageindexadd = q~...&nbsp;~; }
        if ( $endpage != $max ) {
            $pageindexadd .=
qq~<a href="$scripturl?action=viewdownloads;thread=$thread;newstart=$lastptn;sort=$sort">$lastpn</a>~;
        }
        $pageindex .= $pageindexadd;

        $pageindex = qq~$fatxt{'64'}: $pageindex~;

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
                  ( $ext
                      && -e "$htmldir/Templates/Forum/$useimages/$att_img{$ext}"
                  )
                  ? "$imagesdir/$att_img{$ext}"
                  : "$micon_bg{'paperclip'}";
            }

            $amdate = timeformat($amdate);
            if ( length($amthreadsub) > 20 ) {
                $amthreadsub = substr( $amthreadsub, 0, 20 ) . q{...};
            }

            if ( $iamadmin || $iamgmod ) {
                $att_admin = $my_att_admin;
            }
            else {
                $att_admin = q{};
            }
            $viewattachments .= $downloads_att_b;
            $viewattachments =~ s/{yabb att_admin}/$att_admin/gsm;
            $viewattachments =~ s/{yabb amfn}/$amfn/gsm;
            $viewattachments =~ s/{yabb attach_gif}/$attach_gif{$ext}/gsm;
            $viewattachments =~ s/{yabb thread}/$thread/gsm;
            $viewattachments =~ s/{yabb amkb}/$amkb/gsm;
            $viewattachments =~ s/{yabb amdate}/$amdate/gsm;
            $viewattachments =~ s/{yabb amcount}/$amcount/gsm;
            $viewattachments =~ s/{yabb amreplies}/$amreplies/gsm;
            $viewattachments =~ s/{yabb amthreadsub}/$amthreadsub/gsm;
            $viewattachments =~ s/{yabb amposter}/$amposter/gsm;
        }

        if ( $iamadmin || $iamgmod ) {
            $att_admin_b = $my_att_admin_b;
            $att_admin_c = $my_att_admin_c;
        }
        else {
            $att_admin_b = q{};
            $att_admin_c = '&nbsp;';
        }
        $viewattachments .= $downloads_att_c;
        $viewattachments =~ s/{yabb att_admin_b}/$att_admin_b/gsm;
        $viewattachments =~ s/{yabb att_admin_c}/$att_admin_c/gsm;
        $viewattachments =~ s/{yabb amv_txt38a}/$amv_txt{'38a'}/gsm;
        $viewattachments =~ s/{yabb admin_txt32}/$admin_txt{'32'}/gsm;
        $viewattachments =~ s/{yabb thread}/$thread/gsm;
        $viewattachments =~ s/{yabb threadname}/$threadname/gsm;
        $viewattachments =~ s/{yabb fatxt70}/$fatxt{'70'}/gsm;
        $viewattachments =~ s/{yabb fatxt71}/$fatxt{'71'}/gsm;
        $viewattachments =~ s/{yabb pageindex}/$pageindex/gsm;

        $output .= qq~
        <input type="hidden" name="newstart" value="$newstart" />~;
    }

    my $class_sortattach = $sort =~ /7/sm   ? 'windowbg2' : 'windowbg';
    my $class_sorttype   = $sort =~ /100/sm ? 'windowbg2' : 'windowbg';
    my $class_sortsize   = $sort =~ /5/sm   ? 'windowbg2' : 'windowbg';
    my $class_sortdate   = $sort =~ /6/sm   ? 'windowbg2' : 'windowbg';
    my $class_sorcount   = $sort =~ /8/sm   ? 'windowbg2' : 'windowbg';
    my $class_sortsubj   = $sort =~ /1$/sm  ? 'windowbg2' : 'windowbg';
    my $class_sortuser   = $sort =~ /3/sm   ? 'windowbg2' : 'windowbg';

    if ( $iamadmin || $iamgmod ) {
        $att_out_admin_a = $my_out_att_admin_a;
    }
    else {
        $att_out_admin_a = q{};
    }

    $output .= $downloads_att_out_a;
    $output =~ s/{yabb colspan}/$colspan/gsm;
    $output =~ s/{yabb threadname}/$threadname/gsm;
    $output =~ s/{yabb pageindex}/$pageindex/gsm;
    $output =~ s/{yabb max}/$max/gsm;
    $output =~ s/{yabb numshow}/$numshow/gsm;
    $output =~ s/{yabb fatxt39}/$fatxt{'39'}/gsm;
    $output =~ s/{yabb fatxt76}/$fatxt{'76'}/gsm;
    $output =~ s/{yabb fatxt75}/$fatxt{'75'}/gsm;
    $output =~ s/{yabb fatxt28}/$fatxt{'28'}/gsm;

    $output .= $att_out_admin_a;
    $output =~ s/{yabb fatxt45}/$fatxt{'45'}/gsm;
    $output .=
        $my_att_sort_a
      . ( $sort == 7 ? -7 : 7 )
      . qq~';" class="$class_sortattach" ~
      . $my_att_sort_c
      . ( $sort == 7 ? -7 : 7 )
      . qq~"><b>$fatxt{'40'}</b></a>~
      . $my_att_sort_b
      . ( $sort == 100 ? -100 : 100 )
      . qq~';" class="$class_sorttype" ~
      . $my_att_sort_c
      . ( $sort == 100 ? -100 : 100 )
      . qq~"><b>$fatxt{'40a'}</b></a>~
      . $my_att_sort_b
      . ( $sort == -5 ? 5 : -5 )
      . qq~';" class="$class_sortsize" ~
      . $my_att_sort_c
      . ( $sort == -5 ? 5 : -5 )
      . qq~"><b>$fatxt{'41'}</b></a>~
      . $my_att_sort_b
      . ( $sort == -6 ? 6 : -6 )
      . qq~';" class="$class_sortdate" ~
      . $my_att_sort_c
      . ( $sort == -6 ? 6 : -6 )
      . qq~"><b>$fatxt{'43'}</b></a>~
      . $my_att_sort_b
      . ( $sort == -8 ? 8 : -8 )
      . qq~';" class="$class_sorcount" ~
      . $my_att_sort_c
      . ( $sort == -8 ? 8 : -8 )
      . qq~"><b>$fatxt{'41a'}</b></a>~
      . $my_att_sort_b
      . ( $sort == 1 ? -1 : 1 )
      . qq~';" class="$class_sortsubj" ~
      . $my_att_sort_c
      . ( $sort == 1 ? -1 : 1 )
      . qq~"><b>$fatxt{'44'}</b></a>~
      . $my_att_sort_b
      . ( $sort == 3 ? -3 : 3 )
      . qq~';" class="$class_sortuser" ~
      . $my_att_sort_c
      . ( $sort == 3 ? -3 : 3 )
      . qq~"><b>$fatxt{'42'}</b></a>~
      . $downloads_tbl_end;

    #"';
    $output =~ s/{yabb thread}/$thread/gsm;
    $output =~ s/{yabb viewattachments}/$viewattachments/gsm;

    if ( $max && ( $iamadmin || $iamgmod ) ) { $output .= '</form>'; }

    $output .= $downloads_bottom;

    print_HTML_output_and_finish();
    return;
}

sub DownloadFileCouter {
    $dfile = $INFO{'file'};

    if ( $guest_media_disallowed && $iamguest ) {
        fatal_error( q{}, $maintxt{'40'} );
    }

    if ( !-e "$uploaddir/$dfile" ) {
        fatal_error( q{}, "$dfile $maintxt{'23'}" );
    }

    fopen( ATM, "<$vardir/attachments.txt", 1 )
      or fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
    my @attachments = <ATM>;
    fclose( ATM );

    for my $aa ( 0 .. ( @attachments - 1 ) ) {
        $attachments[$aa] =~
s/(.+\|)(.+)\|(\d+)(\s+)$/ $1 . ($dfile eq $2 ? "$2|" . ($3 + 1) : "$2|$3") . $4 /exsm;
    }
    fopen( ATM, ">$vardir/attachments.txt", 1 )
      or fatal_error( 'cannot_open', "$vardir/attachments.txt", 1 );
    print {ATM} @attachments or croak "$croak{'print'} ATM";
    fclose(ATM);

    print "Location: $uploadurl/$dfile\n\r\n\r"
      or croak "$croak{'print'} Location";

    exit;
}

1;
