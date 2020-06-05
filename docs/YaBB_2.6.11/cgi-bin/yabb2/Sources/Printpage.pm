###############################################################################
# Printpage.pm                                                                #
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

$printpagepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
get_micon();

sub Print_IM {
    if ($iamguest) { fatal_error('not_allowed'); }
    LoadLanguage('InstantMessage');

    my (
        $fromTitle,    $toTitle,      $toTitleCC,     $toTitleBCC,
        $usernameFrom, $usernameTo,   $usernameCC,    $usernameBCC,
        $pmAttachment, $pmShowAttach, $pmAttachments, %attach_gif
    );

    if ( $INFO{'caller'} == 1 ) {
        fopen( THREADS, "$memberdir/$username.msg" ) || donoopen();
        $boxtitle = qq~$inmes_txt{'inbox'}~;
    }
    elsif ( $INFO{'caller'} == 2 ) {
        fopen( THREADS, "$memberdir/$username.outbox" ) || donoopen();
        $boxtitle = qq~$inmes_txt{'outbox'}~;
    }
    elsif ( $INFO{'caller'} == 3 ) {
        fopen( THREADS, "$memberdir/$username.imstore" ) || donoopen();
        $boxtitle   = qq~$inmes_txt{'storage'}~;
        $storetitle = qq~$INFO{'viewfolder'}~;
    }
    elsif ( $INFO{'caller'} == 5 ) {
        fopen( THREADS, "$memberdir/broadcast.messages" ) || donoopen();
        $boxtitle = qq~$inmes_txt{'broadcast'}~;
    }
    @threads = <THREADS>;
    fclose(THREADS);

    $threadid = $INFO{'id'};
    foreach my $thread (@threads) {
        chomp $thread;
        if ( $thread =~ /$threadid/xsm ) {
            (
                undef,          $threadposter,   $threadtousers,
                $threadccusers, $threadbccusers, $threadtitle,
                $threaddate,    $threadpost,     undef,
                undef,          undef,           $threadstatus,
                undef,          $fold,           $threadAttach
            ) = split /\|/xsm, $thread;
            if ( $INFO{'caller'} == 3 ) {
                $folder = ucfirst $fold;
                $boxtitle .= qq~ &gt;&gt; $folder~;
            }
        }
    }

    $printDate = timeformat( $date, 1 );

    # Lets output all that info.
    if ($yycharset) {$yymycharset = $yycharset;}
    $output =
qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$abbr_lang" lang="$abbr_lang">
<head>
<title>$mbname - $maintxt{'668'}</title>
<meta http-equiv="Content-Type" content="text/html; charset=$yymycharset" />
<meta name="robots" content="noindex,noarchive" />
<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />
<style type="text/css">
    body { background-color:#fff;background-image:none; }
</style>
<style type="text/css" media="print">
    .no-print { display: none; }
</style>
<script type="text/javascript" src="$yyhtml_root/YaBB.js"></script>
<script type="text/javascript">
var imgdisplay = 'none';
function do_images() {
    for (var i = 0; i < document.images.length; i++) {
        document.images[i].style.display = imgdisplay;
    }
    if (imgdisplay == 'none') {
        imgdisplay = 'inline';
        document.getElementById("Hide_Image").value = "$maintxt{'669b'}";
    } else {
        imgdisplay = 'none';
        document.getElementById("Hide_Image").value = "$maintxt{'669a'}";
    }
}

</script>
</head>
<body>

<table style="width:96%; margin-top:10px">
    <tr>
        <td class="vtop">
            <span style="font-family: arial, sans-serif; font-size: 18px; font-weight: bold;">$mbname</span>
        </td>
        <td class="right vtop">
            <input type="button" id="Hide_Image" value="$maintxt{'669a'}" class="no-print" onclick="do_images();" />
        </td>
    </tr><tr>
        <td class="vtop" colspan="2">
        <!-- Uncomment the following line if you want the Forum URL to appear-->
            <!--<span style="font-family: arial, sans-serif; font-size: 10px;">$scripturl</span><br />-->
            <!--<span style="font-family: arial, sans-serif; font-size: 16px; font-weight: bold;">$load_imtxt{'71'} $boxtitle $inmes_txt{'30'} $printDate</span>-->
            <!--<span style="font-family: arial, sans-serif; font-size: 16px; font-weight: bold;">$mbname &gt;&gt; $inmes_txt{'usercp'} &gt;&gt; $boxtitle $storetitle</span>-->
            <span style="font-family: arial, sans-serif; font-size: 16px; font-weight: bold;">$load_imtxt{'71'} $inmes_txt{'usercp'} &gt;&gt; $boxtitle  $storetitle $inmes_txt{'30'} $printDate</span>
            <br />
            <span style="font-family: arial, sans-serif; font-size: 10px;">$scripturl?action=imshow;caller=$INFO{'caller'};id=$INFO{'id'}</span>
        </td>
    </tr>
</table>
<br />
~;

    $threadDate = timeformat( $threaddate, 1 );

    if ( $INFO{'caller'} == 1 ) {
        if ($threadtousers) {
            foreach my $uname ( split /,/xsm, $threadtousers ) {
                LoadUser($uname);
                $usernameTo .= (
                      ${ $uid . $uname }{'realname'}
                    ? ${ $uid . $uname }{'realname'}
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernameTo =~ s/, $//sm;
            $usernameTo = qq~<b>$usernameTo</b><br />~;
            $toTitle    = qq~$inmes_txt{'324'}:~;
        }
        if ($threadccusers) {
            foreach my $uname ( split /,/xsm, $threadccusers ) {
                LoadUser($uname);
                $usernameCC .= (
                      ${ $uid . $uname }{'realname'}
                    ? ${ $uid . $uname }{'realname'}
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };
            }
            $usernameCC =~ s/, $//sm;
            $usernameCC = qq~<b>$usernameCC</b><br />~;
            $toTitleCC  = qq~$inmes_txt{'325'}:~;
        }
        if ($threadbccusers) {
            foreach my $uname ( split /,/xsm, $threadbccusers ) {
                if ( $uname eq $username ) {
                    LoadUser($uname);
                    $usernameBCC =
                        ${ $uid . $uname }{'realname'}
                      ? ${ $uid . $uname }{'realname'}
                      : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                      );
                }
            }
            if ($usernameBCC) {
                $usernameBCC = qq~<b>$usernameBCC</b>~;
                $toTitleBCC  = qq~$inmes_txt{'326'}:~;
            }
        }

        if ( $threadstatus eq 'g' || $threadstatus eq 'ga' ) {
            my ( $guestName, $guestEmail ) = split / /sm, $threadposter;
            $guestName =~ s/%20/ /gsm;
            $usernameFrom = qq~<b>$guestName ($guestEmail)</b><br />~;
        }
        else {
            LoadUser($threadposter);
            $usernameFrom =
                ${ $uid . $threadposter }{'realname'}
              ? ${ $uid . $threadposter }{'realname'}
              : (
                  $threadposter ? qq~$threadposter ($maintxt{'470a'})~
                : $maintxt{'470a'}
              );    # 470a == Ex-Member
            $usernameFrom = qq~<b>$usernameFrom</b><br />~;
        }
        $fromTitle = qq~$inmes_txt{'318'}:~;
    }
    chomp $threadAttach;
    if ( $threadAttach ne q{} ) {
        LoadLanguage('FA');
        foreach ( split /,/xsm, $threadAttach ) {
            my ( $pmAttachFile, undef ) = split /~/xsm, $_;
            if ( $pmAttachFile =~ /\.(.+?)$/sm ) {
                $ext = lc $1;
            }
            if ( !exists $attach_gif{$ext} ) {
                $attach_gif{$ext} =
                  ( $ext
                      && -e "$htmldir/Templates/Forum/$useimages/$att_img{$ext}"
                  ) ? "$imagesdir/$att_img{$ext}" : "$micon_bg{'paperclip'}";
            }
            my $filesize = -s "$pmuploaddir/$pmAttachFile";
            if ($filesize) {
                if (   $pmAttachFile =~ /\.(bmp|jpe|jpg|jpeg|gif|png)$/ism
                    && $pmDisplayPics == 1 )
                {
                    $imagecount++;
                    $pmShowAttach .=
qq~<div class="small" style="float:left; margin:8px;"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $pmAttachFile ( ~
                      . int( $filesize / 1024 )
                      . qq~ KB)<br /><img src="$pmuploadurl/$pmAttachFile" name="attach_img_resize" alt="$pmAttachFile" title="$pmAttachFile" style="display:none;" /></div>\n~;
                }
                else {
                    $pmAttachment .=
qq~<div class="small"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $pmAttachFile ( ~
                      . int( $filesize / 1024 )
                      . q~ KB)</div>~;
                }
            }
            else {
                $pmAttachment .=
qq~<div class="small"><img src="$attach_gif{$ext}" class="bottom" alt="" />  $pmAttachFile ($fatxt{'1'})</div>~;
            }
        }
        if ( $pmShowAttach && $pmAttachment ) {
            $pmAttachment =~
              s/<div class="small">/<div class="small" style="margin:8px;">/gsm;
        }
        $pmAttachments .= qq~
            <hr />
            $pmAttachment
            $pmShowAttach~;
    }
    elsif ( $INFO{'caller'} == 2 ) {
        LoadUser($threadposter);
        $usernameFrom =
            ${ $uid . $threadposter }{'realname'}
          ? ${ $uid . $threadposter }{'realname'}
          : (
              $threadposter ? qq~$threadposter ($maintxt{'470a'})~
            : $maintxt{'470a'}
          );    # 470a == Ex-Member
        $usernameFrom = qq~<b>$usernameFrom</b><br />~;
        $fromTitle    = qq~$inmes_txt{'318'}:~;

        if ( $threadstatus !~ /b/sm ) {
            if ( $threadstatus !~ /gr/sm ) {
                foreach my $uname ( split /,/xsm, $threadtousers ) {
                    LoadUser($uname);
                    $usernameTo .= (
                          ${ $uid . $uname }{'realname'}
                        ? ${ $uid . $uname }{'realname'}
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
            }
            else {
                my ( $guestName, $guestEmail ) = split / /sm, $threadtousers;
                $guestName =~ s/%20/ /gxsm;
                $usernameTo = qq~$guestName ($guestEmail)~;
            }
            $toTitle = qq~$inmes_txt{'324'}:~;
        }
        else {
            require Sources::InstantMessage;
            foreach my $uname ( split /,/xsm, $threadtousers ) {
                $usernameTo .= links_to($uname);
            }
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }
        $usernameTo =~ s/, $//sm;
        $usernameTo = qq~<b>$usernameTo</b><br />~;
        if ($threadccusers) {
            foreach my $uname ( split /,/xsm, $threadccusers ) {
                LoadUser($uname);
                $usernameCC .= (
                      ${ $uid . $uname }{'realname'}
                    ? ${ $uid . $uname }{'realname'}
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernameCC =~ s/, $//sm;
            $usernameCC = qq~<b>$usernameCC</b><br />~;
            $toTitleCC  = qq~$inmes_txt{'325'}:~;
        }
        if ($threadbccusers) {
            foreach my $uname ( split /,/xsm, $threadbccusers ) {
                LoadUser($uname);
                $usernameBCC .= (
                      ${ $uid . $uname }{'realname'}
                    ? ${ $uid . $uname }{'realname'}
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernameBCC =~ s/, $//sm;
            $usernameBCC = qq~<b>$usernameBCC</b>~;
            $toTitleBCC  = qq~$inmes_txt{'326'}:~;
        }
    }
    elsif ( $INFO{'caller'} == 3 ) {
        if ( $threadstatus !~ /b/sm ) {
            if ( $threadstatus !~ /gr/sm ) {
                foreach my $uname ( split /,/xsm, $threadtousers ) {
                    LoadUser($uname);
                    $usernameTo .= (
                          ${ $uid . $uname }{'realname'}
                        ? ${ $uid . $uname }{'realname'}
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
            }
            else {
                my ( $guestName, $guestEmail ) = split / /sm, $threadtousers;
                $guestName =~ s/%20/ /gsm;
                $usernameTo = qq~$guestName ($guestEmail)~;
            }
            $toTitle = qq~$inmes_txt{'324'}:~;
            if ( $threadccusers && $threadposter eq $username ) {
                foreach my $uname ( split /,/xsm, $threadccusers ) {
                    LoadUser($uname);
                    $usernameCC .= (
                          ${ $uid . $uname }{'realname'}
                        ? ${ $uid . $uname }{'realname'}
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
                $usernameCC =~ s/, $//sm;
                $usernameCC = qq~<b>$usernameCC</b><br />~;
                $toTitleCC  = qq~$inmes_txt{'325'}:~;
            }
            if ( $threadbccusers && $threadposter eq $username ) {
                foreach my $uname ( split /,/xsm, $threadbccusers ) {
                    LoadUser($uname);
                    $usernameBCC .= (
                          ${ $uid . $uname }{'realname'}
                        ? ${ $uid . $uname }{'realname'}
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
                $usernameBCC =~ s/, $//sm;
                $usernameBCC = qq~<b>$usernameBCC</b>~;
                $toTitleBCC  = qq~$inmes_txt{'326'}:~;
            }
        }
        else {
            foreach my $uname ( split /,/xsm, $threadtousers ) {
                require Sources::InstantMessage;
                $usernameTo .= links_to($uname);
            }
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }
        $usernameTo =~ s/, $//sm;
        $usernameTo = qq~<b>$usernameTo</b><br />~;

        if ( $threadstatus eq 'g' || $threadstatus eq 'ga' ) {
            my ( $guestName, $guestEmail ) = split / /sm, $threadposter;
            $guestName =~ s/%20/ /gsm;
            $usernameFrom = qq~$guestName ($guestEmail)~;
        }
        else {
            LoadUser($threadposter);
            $usernameFrom =
                ${ $uid . $threadposter }{'realname'}
              ? ${ $uid . $threadposter }{'realname'}
              : (
                  $threadposter ? qq~$threadposter ($maintxt{'470a'})~
                : $maintxt{'470a'}
              );    # 470a == Ex-Member
        }
        $usernameFrom = qq~<b>$usernameFrom</b><br />~;
        $fromTitle    = qq~$inmes_txt{'318'}:~;

    }
    elsif ( $INFO{'caller'} == 5
        && ( $threadstatus eq 'g' || $threadstatus eq 'ga' ) )
    {
        my ( $guestName, $guestEmail ) = split / /sm, $threadposter;
        $guestName =~ s/%20/ /gsm;
        $usernameFrom = qq~<b>$guestName ($guestEmail)</b><br />~;
        $fromTitle    = qq~$inmes_txt{'318'}:~;

    }
    elsif ( $INFO{'caller'} == 5 && $threadstatus =~ /b/sm ) {
        if ($threadtousers) {
            require Sources::InstantMessage;    # Needed for To Member Groups
            foreach my $uname ( split /,/xsm, $threadtousers ) {
                $usernameTo .= links_to($uname);
            }
            $usernameTo =~ s/, $//sm;
            $usernameTo .= q~<br />~;
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }

        LoadUser($threadposter);
        $usernameFrom =
            ${ $uid . $threadposter }{'realname'}
          ? ${ $uid . $threadposter }{'realname'}
          : (
              $threadposter ? qq~$threadposter ($maintxt{'470a'})~
            : $maintxt{'470a'}
          );    # 470a == Ex-Member

        $usernameFrom = qq~<b>$usernameFrom</b><br />~;
        $fromTitle    = qq~$inmes_txt{'318'}:~;
    }

    do_print();
    $output .= qq~
<table class="cs_10px" style="border: 1px solid #000000; width:96%">
    <tr>
        <td style="font-family: arial, sans-serif; font-size: 12px;">
            <div>$inmes_txt{'70'}: <b>$threadtitle</b></div>
            <div>$inmes_txt{'317'}: <b>$threadDate</b></div>
            $toTitle $usernameTo
            $fromTitle $usernameFrom
            $toTitleCC $usernameCC
            $toTitleBCC $usernameBCC
            <hr />
            <span style="font-family: arial, sans-serif; font-size: 12px;">
            $threadpost
            </span>
            $pmAttachments
        </td>
    </tr>
</table>
<form><p class="no-print" style="text-align:center"><input class="no-print" type="button" value=" $maintxt{'printpage'} " onclick="window.print();" /></p></form>
~;

    $output .= qq~
<table class="pad_10px" style="width:96%">
    <tr>
        <td class="center">
            <span style="font-family: arial, sans-serif; font-size: 10px;">
            $yycopyright
            </span>
        </td>
    </tr>
</table>
</body>
</html>~;

    image_resize();

    print_output_header();
    print_HTML_output_and_finish();
    return;
}

sub Print {
    $num  = $INFO{'num'};
    $post = $INFO{'post'};

    # Determine category
    $curcat = ${ $uid . $currentboard }{'cat'};
    MessageTotals( 'load', $num );

    my $ishidden;
    if ( ${$num}{'threadstatus'} =~ /h/ism ) {
        $ishidden = 1;
    }

    if ( $ishidden && !$staff ) {
        fatal_error('no_access');
    }

    # Figure out the name of the category
    get_forum_master();
    ( $cat, $catperms ) = split /\|/xsm, $catinfo{"$curcat"};

    ( $boardname, $boardperms, $boardview ) =
      split /\|/xsm, $board{"$currentboard"};

    LoadCensorList();

    # Lets open up the thread file itself
    if ( !ref $thread_arrayref{$num} ) {
        fopen( THREADS, "$datadir/$num.txt" ) || donoopen();
        @{ $thread_arrayref{$num} } = <THREADS>;
        fclose(THREADS);
    }
    $cat =~ s/\n//gxsm;

    ( $messagetitle, $poster, undef, $date, undef ) =
      split /\|/xsm, ${ $thread_arrayref{$num} }[0];

    $startedby = $poster;
    $startedon = timeformat( $date, 1 );
    ToChars($messagetitle);
    ( $messagetitle, undef ) = Split_Splice_Move( $messagetitle, 0 );
    my $pageTitle = $post ? $maintxt{'668a'} : $maintxt{'668'};

    ### Lets output all that info. ###
    if ($yycharset) {$yymycharset = $yycharset;}
    $output =
qq~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$abbr_lang" lang="$abbr_lang">
<head>
<title>$mbname - $pageTitle</title>
<meta http-equiv="Content-Type" content="text/html; charset=$yymycharset" />
<meta name="robots" content="noindex,noarchive" />
<link rel="canonical" href="$scripturl?num=$num" />
<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />
<style type="text/css">
    body { background-color:#fff;background-image:none; }
</style>
<style type="text/css" media="print">
    .no-print { display: none; }
</style>
<script type="text/javascript" src="$yyhtml_root/YaBB.js"></script>
<script type="text/javascript">
var imgdisplay = 'none';
var urldisplay = 'inline';
function do_images() {
    for (var i = 0; i < document.images.length; i++) {
        if (document.images[i].align != 'bottom') {
            document.images[i].style.display = imgdisplay;
            imageid = document.images[i].id;
            if (imageid) document.getElementById('url' + imageid).style.display = urldisplay;
        }
    }
    if (imgdisplay == 'none') {
        imgdisplay = 'inline';
        urldisplay = 'none';
        document.getElementById("Hide_Image").value = "$maintxt{'669b'}";
    } else {
        imgdisplay = 'none';
        urldisplay = 'inline';
        document.getElementById("Hide_Image").value = "$maintxt{'669a'}";
    }
}

</script>
</head>
<body>

<table style="width:96%; margin-top:10px">
    <tr>
        <td class="vtop">
            <span style="font-family: arial, sans-serif; font-size: 18px; font-weight: bold;">$mbname</span>
        </td>
        <td class="right vtop">
            <input type="button" id="Hide_Image" value="$maintxt{'669a'}" class="no-print" onclick="do_images();" />
        </td>
    </tr><tr>
        <td class="vtop" colspan="2">
            <!-- Uncomment the following line if you want the Forum URL to appear -->
            <!--<span style="font-family: arial, sans-serif; font-size: 10px;">$scripturl</span><br />-->
            <span style="font-family: arial, sans-serif; font-size: 16px; font-weight: bold;">$cat &gt;&gt; $boardname &gt;&gt; $messagetitle</span>
            <br />
            <span style="font-family: arial, sans-serif; font-size: 10px;">$scripturl?num=$num</span>
            <br />
            <hr  />
            <span style="font-family: arial, sans-serif; font-size: 14px; font-weight: bold;">$maintxt{'195'} $startedby $maintxt{'30'} $startedon</span>
        </td>
    </tr>
</table>
<br />~;

    LoadLanguage('FA');

    # Split the threads up so we can print them.
    $postnum = 0;
    foreach my $thread ( @{ $thread_arrayref{$num} } ) {
        $postnum++;
        (
            $threadtitle, $threadposter, undef, $threaddate,
            undef,        undef,         undef, undef,
            $threadpost,  undef,         undef, undef,
            $attachments
        ) = split /\|/xsm, $thread;
        if ( $post && ( $post ne $postnum ) ) {
            next;
            (
                $threadtitle, $threadposter, undef, $threaddate,
                undef,        undef,         undef, undef,
                $threadpost,  undef,         undef, undef,
                $attachments
            ) = split /\|/xsm, @{ $thread_arrayref{$num} }[$post];
            last;
        }
        ( $threadtitle, undef ) = Split_Splice_Move( $threadtitle, 0 );
        ( $threadpost,  undef ) = Split_Splice_Move( $threadpost,  $num );
        do_print();

        $output .= qq~
<table class="pad_10px" style="border: 1px solid #000000; width:96%">
    <tr>
        <td style="font-family: arial, sans-serif; font-size: 12px;">
            $maintxt{'196'}: <b>$threadtitle</b><br />
            $maintxt{'197'} <b>$threadposter</b> $maintxt{'30'} <b>$threaddate</b>
            <hr />
            <div style="font-family: arial, sans-serif; font-size: 12px;">
            $threadpost~;

        chomp $attachments;
        if ($attachments) {

            # store all downloadcounts in variable
            if ( !%attach_count ) {
                my ( $atfile, $atcount );
                fopen( ATM, "$vardir/attachments.txt" );
                while (<ATM>) {
                    (
                        undef, undef, undef,   undef, undef,
                        undef, undef, $atfile, $atcount
                    ) = split /\|/xsm, $_;
                    $attach_count{$atfile} = $atcount;
                }
                fclose(ATM);
                if ( !%attach_count ) { $attach_count{'no_attachments'} = 1; }
            }

            my $attachment = q{};
            my $showattach = q{};

            foreach ( split /,/xsm, $attachments ) {
                if ( $_ =~ /\.(.+?)$/xsm ) {
                    $ext = lc $1;
                }
                if ( !exists $attach_gif{$ext} ) {
                    $attach_gif{$ext} =
                      ( $ext
                          && -e "$htmldir/Templates/Forum/$useimages/$att_img{$ext}"
                      )
                      ? "$imagesdir/$att_img{$ext}"
                      : "$micon_bg{'paperclip'}";
                }
                my $filesize = -s "$uploaddir/$_";
                $download_txt = ( $attach_count{$_} == 1 ) ? $fatxt{'41b'} : isempty( $fatxt{'41c'}, $fatxt{'41a'} ); 
                if ($filesize) {
                    if (   $_ =~ /\.(bmp|jpe|jpg|jpeg|gif|png)$/ixsm
                        && $amdisplaypics == 1 )
                    {
                        $imagecount++;
                        $showattach .=
qq~<div class="small" style="float:left; margin:8px;"><img src="$attach_gif{$ext}" class="bottom" alt="" /> <span id="urlimagecount$imagecount" style="display:none">$scripturl?action=downloadfile;file=</span>$_ ( ~
                          . int( $filesize / 1024 )
                          . qq~ KB | $attach_count{$_} $download_txt )<br /><img src="$uploadurl/$_" name="attach_img_resize" alt="$_" id="imagecount$imagecount" title="$_" style="display:none" /></div>\n~;
                    }
                    else {
                        $attachment .=
qq~<div class="small"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $scripturl?action=downloadfile;file=$_ ( ~
                          . int( $filesize / 1024 )
                          . qq~ KB | $attach_count{$_} $download_txt )</div>~;
                    }
                }
                else {
                    $attachment .=
qq~<div class="small"><img src="$attach_gif{$ext}" class="bottom" alt="" />  $_ ($fatxt{'1'}~
                      . (
                        exists $attach_count{$_}
                        ? qq~ | $attach_count{$_} $download_txt ~ 
                        : q{}
                      ) . q~)</div>~;
                }
            }
            if ( $showattach && $attachment ) {
                $attachment =~
s/<div class="small">/<div class="small" style="margin:8px;">/gsm;
            }
            $output .= qq~
            <hr />
            $attachment
            $showattach~;
        }

        $output .= q~
            </div>
        </td>
    </tr>
</table>
<br />
~;
    }

    $output .= qq~
<form><p class="no-print" style="text-align:center"><input class="no-print" type="button" value=" $maintxt{'printpage'} " onclick="window.print();" /></p></form>
<table class="pad_10px" style="width:96%">
    <tr>
        <td class="center" style="font-family: arial, sans-serif; font-size: 10px;">
            $yycopyright
        </td>
    </tr>
</table>
</body>
</html>~;

    image_resize();

    print_output_header();
    print_HTML_output_and_finish();
    return;
}

sub codemsg {
    my ($code) = @_;
    my %killhash = (
        q{;}  => '&#059;',
        q{!}  => '&#33;',
        q{(}  => '&#40;',
        q{)}  => '&#41;',
        q{-}  => '&#45;',
        q{.}  => '&#46;',
        q{/}  => '&#47;',
        q{:}  => '&#58;',
        q{?}  => '&#63;',
        q{[}  => '&#91;',
        q{\\} => '&#92;',
        q{]}  => '&#93;',
        q{^}  => '&#94;',
    );
    if ( $code !~ /&\S*;/xsm ) { $code =~ s/;/&#059;/gxsm; }
    $code =~ s/([\(\)\-\:\\\/\?\!\]\[\.\^])/$killhash{$1}/gxsm;
    $_ =
q~<br /><b>Code:</b><br /><table class="cs_thin" style="width:90%"><tr><td><table class="padd_2px"><tr><td><span style="font-family:courier; font-size:80%">CODE</span></td></tr></table></td></tr></table>~;
    $_ =~ s/CODE/$code/gxsm;
    return $_;
}

sub donoopen {
    print qq~Content-Type: text/html\r\n\r\n
<html>
<head>
<title>$maintxt{'199'}</title>
</head>
<body>
<p style="font-size:small; font-family:Arial,Helvetica; text-align:center">$maintxt{'199'}</p>
</body>
</html>~ or croak "$croak{'print'}";
    exit;
}

sub do_print {
    $threadpost =~ s/\[reason\](.+?)\[\/reason\]//isgxm;
    $threadpost =~ s/<br \/>/\n/igxsm;
    $threadpost =~ s/\[highlight(.*?)\](.*?)\[\/highlight\]/$2/isgxm;
    $threadpost =~
s/\[code\s*(.+?)\]\n*(.+?)\n*\[\/code\]/<br \/><b>Code ($1):<\/b><br \/><table class=\"cs_thin\"><tr><td><table class=\"pad_2px\"><tr><td><span style=\"font-family:courier; font-size:80%\">$2<\/span><\/td><\/tr><\/table><\/td><\/tr><\/table>/isgm;
    $threadpost =~ s/\[([^\]]{0,30})\n([^\]]{0,30})\]/\[$1$2\]/gxsm;
    $threadpost =~ s/\[\/([^\]]{0,30})\n([^\]]{0,30})\]/\[\/$1$2\]/gxsm;
    $threadpost =~ s/(\w+:\/\/[^<>\s\n\"\]\[]+)\n([^<>\s\n\"\]\[]+)/$1\n$2/gxsm;

    $threadpost =~ s/\[b\](.*?)\[\/b\]/<b>$1<\/b>/isgxm;
    $threadpost =~ s/\[i\](.*?)\[\/i\]/<i>$1<\/i>/isgxm;
    $threadpost =~
s/\[u\](.*?)\[\/u\]/<span style="text-decoration:underline">$1<\/span>/isgm;
    $threadpost =~ s/\[s\](.*?)\[\/s\]/<s>$1<\/s>/isgxm;
    $threadpost =~ s/\[move\](.*?)\[\/move\]/$1/isgxm;

    $threadpost =~ s/\[glow(.*?)\](.*?)\[\/glow\]/&elimnests($2)/eisgxm;
    $threadpost =~ s/\[shadow(.*?)\](.*?)\[\/shadow\]/&elimnests($2)/eisgxm;

    $threadpost =~ s/\[shadow=(\S+?),(.+?),(.+?)\](.+?)\[\/shadow\]/$4/eisgxm;
    $threadpost =~ s/\[glow=(\S+?),(.+?),(.+?)\](.+?)\[\/glow\]/$4/eisgxm;

    $threadpost =~ s/\[color=([\w#]+)\](.*?)\[\/color\]/$2/isgxm;
    $threadpost =~ s/\[black\](.*?)\[\/black\]/$1/isgxm;
    $threadpost =~ s/\[white\](.*?)\[\/white\]/$1/isgxm;
    $threadpost =~ s/\[red\](.*?)\[\/red\]/$1/isgxm;
    $threadpost =~ s/\[green\](.*?)\[\/green\]/$1/isgxm;
    $threadpost =~ s/\[blue\](.*?)\[\/blue\]/$1/isgxm;
    $threadpost =~
s/\[font=(.+?)\](.+?)\[\/font\]/<span style="font-family:$1;">$2<\/span>/isgm;

    while (
        $threadpost =~ s/\[size=(.+?)\](.+?)\[\/size\]/sizefont($1,$2)/eisgxm )
    {
    }

    $threadpost =~
s/\[quote\s+author=(.*?)\s+link=(.*?)\].*\/me\s+(.*?)\[\/quote\]/\[quote author=$1 link=$2\]<i>* $1 $3<\/i>\[\/quote\]/isgm;
    $threadpost =~
s/\[quote(.*?)\].*\/me\s+(.*?)\[\/quote\]/\[quote$1\]<i>* Me $2<\/i>\[\/quote\]/isgm;
    $threadpost =~
      s/\/me\s+(.*)/* $displayname $1/igsm;    #*/ make my syntax checker happy

    # Images in message
    $threadpost =~ s/\[img(.*?)\](.*?)\[\/img\]/ imagemsg($1,$2) /eisgm;

    $threadpost =~ s/\[tt\](.*?)\[\/tt\]/<tt>$1<\/tt>/isgxm;
    $threadpost =~
      s/\[left\](.*?)\[\/left\]/<div style="text-align: left;">$1<\/div>/isgm;
    $threadpost =~
s/\[center\](.*?)\[\/center\]/<div style="text-align: center;">$1<\/div>/isgm;
    $threadpost =~
s/\[right\](.*?)\[\/right\]/<div style="text-align: right;">$1<\/div>/isgm;
    $threadpost =~
s/\[justify\](.*?)\[\/justify\]/<div style="text-align: justify">$1<\/div>/isgm;
    $threadpost =~ s/\[sub\](.*?)\[\/sub\]/<sub>$1<\/sub>/isxgm;
    $threadpost =~ s/\[sup\](.*?)\[\/sup\]/<sup>$1<\/sup>/isgxm;
    $threadpost =~
s/\[fixed\](.*?)\[\/fixed\]/<span style="font-family: Courier New;">$1<\/span>/isgm;

    $threadpost =~ s/\[\[/\{\{/gxsm;
    $threadpost =~ s/\]\]/\}\}/gxsm;
    $threadpost =~ s/\|/\&#124;/gxsm;
    $threadpost =~
      s/\[hr\]\n/<hr style="width:40%; text-align:left" class="hr" \/>/gsm;
    $threadpost =~
      s/\[hr\]/<hr style="width:40%; text-align:left" class="hr" \/>/gsm;
    $threadpost =~ s/\[br\]/\n/igxsm;

    $threadpost =~ s/\[flash\](.*?)\[\/flash\]/\[media\]$1\[\/media\]/isgxm;

    $threadpost =~
      s/\[url=\s*(.+?)\s*\]\s*(.+?)\s*\[\/url\]/format_url2($1, $2)/eisgxm;
    $threadpost =~ s/\[url\]\s*(\S+?)\s*\[\/url\]/format_url3($1)/eisgxm;

    if ($autolinkurls) {
        $threadpost =~ s/\[url\]\s*([^\[]+)\s*\[\/url\]/[url]$1\[\/url]/gxsm;
        $threadpost =~
          s/\[link\]\s*([^\[]+)\s*\[\/link\]/[link]$1\[\/link]/gxsm;
        $threadpost =~ s/\[news\](\S+?)\[\/news\]/<a href="$1">$1<\/a>/isgm;
        $threadpost =~ s/\[gopher\](\S+?)\[\/gopher\]/<a href="$1">$1<\/a>/isgm;
        $threadpost =~ s/&quot;&gt;/">/gxsm;                  #"
        $threadpost =~ s/(\[\*\])/ $1/gsm;
        $threadpost =~ s/(\[\/list\])/ $1/gsm;
        $threadpost =~ s/(\[\/tr\])/ $1/gsm;
        $threadpost =~ s/(\[\/td\])/ $1/gsm;
        $threadpost =~ s/\<span style\=/\<span_style\=/gsm;
        $threadpost =~ s/\<div style\=/\<div_style\=/gsm;
        $threadpost =~
s/([^\w\"\=\[\]]|[\n\b]|\&quot\;|\[quote.*?\]|\[edit\]|\[highlight\]|\[\*\]|\[td\]|\A)\\*(\w+?\:\/\/(?:[\w\~\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\](?:\<\S+?\>\S+?\<\/\S+?\>)]+?)\.(?:[\w\~\.\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\]\x80-\xFF]{1,})+?)/format_url($1,$2)/eisgm;
        $threadpost =~
s/([^\"\=\[\]\/\:\.\-(\:\/\/\w+)]|[\n\b]|\&quot\;|\[quote.*?\]|\[edit\]|\[highlight\]|\[\*\]|\[td\]|\A|\()\\*(www\.[^\.](?:[\w\~\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\](?:\<\S+?\>\S+?\<\/\S+?\>)]+?)\.(?:[\w\~\.\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\]\x80-\xFF]{1,})+?)/format_url($1,$2)/eisgm;
        $threadpost =~ s/\<span_style\=/\<span style\=/gsm;
        $threadpost =~ s/\<div_style\=/\<div style\=/gsm;
    }

    if ($stealthurl) {
        $threadpost =~
s/\[url=\s*(\w+\:\/\/.+?)\](.+?)\s*\[\/url\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1" target="_blank">$2<\/a>/isgm;
        $threadpost =~
s/\[url=\s*(.+?)\]\s*(.+?)\s*\[\/url\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/$1" target="_blank">$2<\/a>/isgm;

        $threadpost =~
s/\[link\]\s*www\.\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/www.$1">www.$1<\/a>/isgm;
        $threadpost =~
s/\[link=\s*(\w+\:\/\/.+?)\](.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1">$2<\/a>/isgm;
        $threadpost =~
s/\[link=\s*(.+?)\]\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/$1">$2<\/a>/isgm;
        $threadpost =~
s/\[link\]\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1">$1<\/a>/isgm;
        $threadpost =~
s/\[ftp\]\s*(.+?)\s*\[\/ftp\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1" target="_blank">$1<\/a>/isgm;
    }
    else {
        $threadpost =~
s/\[url=\s*(\S\w+\:\/\/\S+?)\s*\](.+?)\[\/url\]/<a href="$1" target="_blank">$2<\/a>/isgm;
        $threadpost =~
s/\[url=\s*(\S+?)\](.+?)\s*\[\/url\]/<a href="http:\/\/$1" target="_blank">$2<\/a>/isgm;
        $threadpost =~
s/\[link\]\s*www\.(\S+?)\s*\[\/link\]/<a href="http:\/\/www.$1">www.$1<\/a>/isgm;
        $threadpost =~
s/\[link=\s*(\S\w+\:\/\/\S+?)\s*\](.+?)\[\/link\]/<a href="$1">$2<\/a>/isgm;
        $threadpost =~
s/\[link=\s*(\S+?)\](.+?)\s*\[\/link\]/<a href="http:\/\/$1">$2<\/a>/isgm;
        $threadpost =~
          s/\[link\]\s*(\S+?)\s*\[\/link\]/<a href="$1">$1<\/a>/isgm;
        $threadpost =~
s/\[ftp\]\s*(ftp:\/\/)?(.+?)\s*\[\/ftp\]/<a href="ftp:\/\/$2">$1$2<\/a>/isgm;
    }

    $threadpost =~ s/(dereferer\;url\=http\:\/\/.*?)#(\S+?\")/$1;anch=$2/isgm;

    if ( $guest_media_disallowed && $iamguest ) {
        my $oops =
qq~ <i>$maintxt{'40'}&nbsp;&nbsp;$maintxt{'41'} <a href="$scripturl?action=login"><b>$maintxt{'34'}</b></a></i>~;
        if ($regtype) {
            $oops .=
qq~<i> $maintxt{'42'} <a href="$scripturl?action=register"><b>$maintxt{'97'}</b></a></i>~;
        }

        $threadpost =~ s/<a href=".+?<\/a>/[oops]/gsm;
        $threadpost =~ s/<img src=".+?>/[oops]/gsm;
        $threadpost =~ s/\[media\].*?\[\/media\]/[oops]/isgxm;
        $threadpost =~ s/\[oops\]/$oops/gxsm;
    }

    $threadpost =~ s/\[media\](.*?)\[\/media\]/$1/isgxm;

    $threadpost =~ s/\[email\]\s*(\S+?\@\S+?)\s*\[\/email\]/$1/isgxm;
    $threadpost =~
      s/\[email=\s*(\S+?\@\S+?)\]\s*(.*?)\s*\[\/email\]/$2 ($1)/isgm;

    $threadpost =~ s/\[news\](.+?)\[\/news\]/$1/isgxm;
    $threadpost =~ s/\[gopher\](.+?)\[\/gopher\]/$1/isgxm;
    $threadpost =~ s/\[ftp\](.+?)\[\/ftp\]/$1/isgxm;

    while ( $threadpost =~
/\[quote\s+author=(.*?)\slink=.*?\s+date=(.*?)\s*\]\n*.*?\n*\[\/quote\]/ism
      )
    {
        my $author = $1;
        my $date = timeformat( $2, 1 );

        if ($author) {    # out of YaBBC.pm -> sub quotemsg {
            ToChars($author);
            if ( !-e "$memberdir/$author.vars" )
            {             # if the file is there it is an unencrypted user ID
                $author = decloak($author);

                # if not, decrypt it and see if it is a regged user
                if ( !-e "$memberdir/$author.vars" )
                {    # if still not found probably the author is a screen name
                    $testauthor = MemberIndex( 'check_exist', "$author" );

                    # check if this name exists in the memberlist
                    if ( $testauthor ne q{} )
                    {    # if it is, load the user id returned
                        $author = $testauthor;
                        LoadUser($author);
                        $author = ${ $uid . $author }{'realname'};

                        # set final author var to the current users screen name
                    }
                    else {
                        $author = decloak($author);

 # if all fails it is a non existing real name so decode and asign as screenname
                    }
                }
                else {
                    LoadUser($author);

# after encoding the user ID was found and loaded, setting the current real name
                    $author = ${ $uid . $author }{'realname'};
                }
            }
            else {
                LoadUser($author);

# it was an old style user id which could be loaded and screen name set to final author
                $author = ${ $uid . $author }{'realname'};
            }
        }

        $threadpost =~
s/\[quote\s+author=.*?link=.*?\s+date=.*?\s*\]\n*(.*?)\n*\[\/quote\]/<br \/><i>$author $maintxt{'30a'} $date:<\/i><table style="padding:1px; width:90%; border:thin solid #000"><tr><td style="width:100%;font-size:10px">$1<\/td><\/tr><\/table>/ism;
    }
    $threadpost =~
s/\[quote\]\n*(.+?)\n*\[\/quote\]/<br \/><i>$maintxt{'31'}:<\/i><table style="padding:1px; width:90%; border:thin solid #000"><tr><td style="width:100%;font-size:10px; font-family:Arial,Helvetica">$1<\/td><\/tr><\/table>/isgm;

## list code from YaBBC.pm - DAR ##
    $threadpost =~ s/\s*\[\*\]/<\/li><li>/isgm;
    $threadpost =~ s/\[olist\]/<ol>/isgm;
    $threadpost =~ s/\s*\[\/olist\]/<\/li><\/ol>/isgm;
    $threadpost =~ s/<\/li><ol>/<ol>/isgm;
    $threadpost =~ s/<ol><\/li>/<ol>/isgm;
    $threadpost =~ s/\[list\]/<ul>/isgm;
    $threadpost =~
s/\[list (.+?)\]/<ul style="list-style-image\: url($defaultimagesdir\/$1\.gif)">/isgm;
    $threadpost =~ s/\s*\[\/list\]/<\/li><\/ul>/isgm;
    $threadpost =~ s/<\/li><ul>/<ul>/isgm;
    $threadpost =~ s/<ul><\/li>/<ul>/isgm;
    $threadpost =~ s/<\/li><ul (.+?)>/<ul $1>/isgm;
    $threadpost =~ s/<ul (.+?)><\/li>/<ul $1>/isgm;

    $threadpost =~
      s/\[pre\](.+?)\[\/pre\]/'<pre>' . dopre($1) . '<\/pre>'/isegm;

    $threadpost =~ s/\[flash=(\S+?),(\S+?)\](\S+?)\[\/flash\]/$3/isxgm;

    $threadpost =~ s/\{\{/\[/gxsm;
    $threadpost =~ s/\}\}/\]/gxsm;

    if ( $threadpost =~ m{\[table\]}ixsm ) {
        $threadpost =~
s/\n{0,1}\[table\]\n*(.+?)\n*\[\/table\]\n{0,1}/<table>$1<\/table>/isgxm;
        while ( $threadpost =~
s/\<table\>(.*?)\n*\[tr\]\n*(.*?)\n*\[\/tr\]\n*(.*?)\<\/table\>/<table>$1<tr>$2<\/tr>$3<\/table>/isxm
          )
        {
        }
        while ( $threadpost =~
s/\<tr\>(.*?)\n*\[td\]\n{0,1}(.*?)\n{0,1}\[\/td\]\n*(.*?)\<\/tr\>/<tr>$1<td>$2<\/td>$3<\/tr>/isxm
          )
        {
        }
    }

    $threadpost =~ s/\[\&table(.*?)\]/<table$1>/gxsm;
    $threadpost =~ s/\[\/\&table\]/<\/table>/gxsm;
    $threadpost =~ s/\n/<br \/>/igsm;

    ### Censor it ###
    $threadtitle = Censor($threadtitle);
    $threadpost  = Censor($threadpost);

    ToChars($threadtitle);
    ToChars($threadpost);

    $threaddate = timeformat( $threaddate, 1 );
    return;
}

sub imagemsg {    # out of YaBBC.pm -> sub imagemsg {
    my ( $attribut, $url ) = @_;

    # use or kill urls
    $url =~ s/\[url\](.*?)\[\/url\]/$1/igxsm;
    $url =~ s/\[link\](.*?)\[\/link\]/$1/igxsm;
    $url =~ s/\[url\s*=\s*(.*?)\s*.*?\].*?\[\/url\]/$1/igxsm;
    $url =~ s/\[link\s*=\s*(.*?)\s*.*?\].*?\[\/link\]/$1/igxsm;
    $url =~ s/\[url.*?\/url\]//igxsm;
    $url =~ s/\[link.*?\/link\]//igxsm;

    my $char_160 = chr 160;
    $url =~ s/(\s|&nbsp;|$char_160)+//gxsm;

    if ( $url !~ /^http.+?\.(gif|jpg|jpeg|png|bmp)$/ixsm ) {
        return q{ } . $url;
    }

    my %parameter;
    FromHTML($attribut);
    $attribut =~ s/(\s|$char_160)+/ /gsm;
    foreach ( split / +/sm, $attribut ) {
        my ( $key, $value ) = split /=/xsm, $_;
        $value =~ s/["']//gxsm;    #'" make my syntax checker happy;
        $parameter{$key} = $value;
    }

    if ( $parameter{'name'} ne 'signat_img_resize' ) {
        $parameter{'name'} = 'post_img_resize';
    }
    ToHTML( $parameter{'alt'} );
    $parameter{'align'}  =~ s/[^a-z]//igxsm;
    $parameter{'width'}  =~ s/\D//gxsm;
    $parameter{'height'} =~ s/\D//gxsm;
    if ( $parameter{'align'} ) {
        $parameter{'align'} = qq~ align:$parameter{'align'};~;
    }
    if ( $parameter{'width'} ) {
        $parameter{'width'} = qq~ width:$parameter{'width'};~;
    }
    if ( $parameter{'height'} ) {
        $parameter{'height'} = qq~ height:$parameter{'height'};~;
    }

    $imagecount++;
    return
qq~ <img src="$url" name="$parameter{'name'}" alt="$parameter{'alt'}" style="display:none;$parameter{'align'}$parameter{'width'}$parameter{'height'}" /><span id="urlimagecount$imagecount" style="display:none">$url</span>~;
}

1;
