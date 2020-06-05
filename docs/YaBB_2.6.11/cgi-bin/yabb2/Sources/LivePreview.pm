###############################################################################
# LivePreview.pm                                                              #
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
# Mod created by Carsten Dalgaard                                             #
#                and added to YaBB core in Version 2.5.4/2.6.0                #
# Released: May 11, 2013, Copyright 2013 Carsten Dalgaard                     # 
###############################################################################
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$livepreviewpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
use URI::Escape;
if ( $yymycharset ne 'UTF-8' ) {
    use Encode;
}
LoadCensorList();
guard();
if ( $enable_ubbc  ) {
    if (!$yyYaBBCloaded ) {
        require Sources::YaBBC;
    }
}

sub DoLiveMessage {
    $displayname = $FORM{'musername'};
    $FORM{'message'} =~ s/\r//gsm;
    $message = $FORM{'message'};
    uri_unescape($message);
    if ( $yymycharset ne 'UTF-8' ) {
         $message = decode_utf8($message);
    }
    $message =~ s/\[ch8203\]//igsm;
    $message =~ s/\&#8203;//igsm;
    FromChars($message);
    ToHTML($message);
    my $mess = $message;
    $message =~ s/\cM//gsm;
    $message =~ s/\[([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[$1$2\]/gsm;
    $message =~ s/\[\/([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[\/$1$2\]/gsm;
    $message =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
    $message =~ s/\n/<br \/>/gsm;
    $message =~ s/([\000-\x09\x0b\x0c\x0e-\x1f\x7f])/\x0d/gsm;
    wrap();
    if ( $FORM{'nschecked'} == 1 ) { $ns = 'NS'; }

    if ($enable_ubbc) {
        DoUBBC();
        $message =~ s/ style="display:none"/ style="display:inline"/gsm;
    }
    wrap2();
    ToChars($message);
    $message  = Censor($message);
    $csubject = $FORM{'subject'};
    uri_unescape($csubject);
    if ( $yymycharset ne 'UTF-8' ) {
         $csubject = decode_utf8($csubject);
    }
    $csubject =~ s/[\r\n]//gsm;
    FromChars($csubject);
    $convertstr = $csubject;
    $convertcut = $set_subjectMaxLength + ( $csubject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $csubject = $convertstr;
    ToHTML($csubject);
    ToChars($csubject);
    $csubject = Censor($csubject);
    liveimage_resize();
    $myname = $FORM{'guestname'};
    uri_unescape($myname);
    if ( $yymycharset ne 'UTF-8' ) {
         $myname = decode_utf8($myname);
    }
    $myname =~ s/[\r\n]//gsm;
    FromChars($myname);
    ToHTML($myname);
    ToChars($myname);
    $myname = Censor($myname);
    if ( $yymycharset ne 'UTF-8' ) {
        $csubject = encode_utf8($csubject);
        $message = encode_utf8($message);
        $myname = encode_utf8($message);
    }
    print "Content-type: application/x-www-form-urlencoded\n\n"
      or croak "$croak{'print'} content-type";
    print qq~$csubject|$message|$myname~ or croak "$croak{'print'}";
    $message = $mess;
    exit;
}

sub DoLiveIM {
    $subjdate = timeformat($date,0,0,0,1);
    $FORM{'message'} =~ s/\r//gxsm;
    $message = $FORM{'message'};
    uri_unescape($message);
    if ( $yymycharset ne 'UTF-8' ) {
        $message = decode_utf8($message);
    }
    $message =~ s/\[ch8203\]//igsm;
    $message =~ s/\&#8203;//igsm;
    FromChars($message);
    ToHTML($message);
    my $mess = $message;
    $message =~ s/\cM//gsm;
    $message =~ s/\[([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[$1$2\]/gsm;
    $message =~ s/\[\/([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[\/$1$2\]/gsm;
    $message =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
    $message =~ s/\n/<br \/>/gsm;
    $message =~ s/([\000-\x09\x0b\x0c\x0e-\x1f\x7f])/\x0d/gsm;
    wrap();
    if ( $FORM{'nschecked'} == 1 ) { $ns = 'NS'; }

    if ($enable_ubbc) {
        $displayname = ${ $uid . $tmpmusername }{'realname'};
        DoUBBC();
        $message =~ s/ style="display:none"/ style="display:inline"/gsm;
    }
    wrap2();
    ToChars($message);
    $message  = Censor($message);
    $csubject = $FORM{'subject'};
    uri_unescape($csubject);
    if ( $yymycharset ne 'UTF-8' ) {
        $csubject = decode_utf8($csubject);
    }
    $csubject =~ s/[\r\n]//gsm;
    FromChars($csubject);
    $convertstr = $csubject;
    $convertcut = $set_subjectMaxLength + ( $csubject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $csubject = $convertstr;
    ToHTML($csubject);
    ToChars($csubject);
    $csubject = Censor($csubject);
    $icon     = $FORM{'icon'};
    CheckIcon();
    get_micon();
    $msgimg = qq~$micon{$icon}~;
    $css    = q~windowbg~;
    LoadLanguage('InstantMessage');

    get_template('MyMessage');
    $liveipimg = qq~<img src="$micon_bg{'ip'}" alt="" />~;
    $livemip   = $inmes_txt{'511'};

    $messageblock = $myIM_liveprev_b;
    $messageblock =~ s/{yabb css}/$css/gsm;
    $messageblock =~ s/{yabb msgimg}/$msgimg/gsm;
    $messageblock =~ s/{yabb subjdate}/$subjdate/gsm;
    $messageblock =~ s/{yabb csubject}/$csubject/gsm;
    $messageblock =~ s/{yabb message}/$message/gsm;
    $messageblock =~ s/{yabb my_sig}/$my_sig/gsm;
    $messageblock =~ s/{yabb my_attach}/$my_attach/gsm;
    $messageblock =~ s/{yabb my_showIP}/$liveipimg $livemip/gsm;

    liveimage_resize();
    if ( $yymycharset ne 'UTF-8' ) {
        $messageblock = encode_utf8($messageblock);
    }

    print "Content-type: application/x-www-form-urlencoded\n\n"
      or croak "$croak{'print'} content-type";
    print qq~$messageblock\n~ or croak "$croak{'print'} messageblock";
    $message = $mess;
    exit;
}

sub DoLiveCal {
    LoadLanguage('EventCal');
    $message = $FORM{'message'};
    uri_unescape($message);
    if ( $yymycharset ne 'UTF-8' ) {
        $message = decode_utf8($message);
    }
    $message =~ s/\r//gxsm;
    $message =~ s/\[ch8203\]//igsm;
    $message =~ s/\&#8203;//igsm;
    FromChars($message);
    ToHTML($message);
    my $mess = $message;
    $message =~ s/\cM//gsm;
    $message =~ s/\[([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[$1$2\]/gsm;
    $message =~ s/\[\/([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[\/$1$2\]/gsm;
    $message =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
    $message =~ s/\n/<br \/>/gsm;
    $message =~ s/([\000-\x09\x0b\x0c\x0e-\x1f\x7f])/\x0d/gsm;
    wrap();
    if ( $FORM{'nschecked'} == 1 ) { $ns = 'NS'; }

    if ($enable_ubbc) {
        $displayname = ${ $uid . $tmpmusername }{'realname'};
        DoUBBC();
        $message =~ s/ style="display:none"/ style="display:inline"/gsm;
    }
    wrap2();
    ToChars($message);
    $message = Censor($message);
    liveimage_resize();
    CountChars();
    $myname = $FORM{'guestname'};
    uri_unescape($myname);
    if ( $yymycharset ne 'UTF-8' ) {
        $myname = decode_utf8($myname);
    }
    $myname =~ s/[\r\n]//gsm;
    FromChars($myname);
    ToHTML($myname);
    ToChars($myname);
    $myname     = Censor($myname);
    $d_year     = $FORM{'cal_year'};
    $d_mon      = $FORM{'cal_mon'};
    $d_day      = $FORM{'cal_day'};
    $my_icontxt = $FORM{'icon_txt'};
    $txt_icon   = $var_cal{$my_icontxt};
    $my_caltype = $FORM{'cal_type'};
    get_micon();
    if   ( $my_caltype == 2 ) { $mycal_type = $cal_icon{'eventprivate'}; }
    else                      { $mycal_type = q{}; }
    $mybtime   = stringtotime(qq~$d_mon/$d_day/$d_year~);
    $mybtimein = timeformat($mybtime);
    $cdate     = dtonly($mybtimein);
    if ( $yymycharset ne 'UTF-8' ) {
        $message = encode_utf8($message);
        $myname = encode_utf8($myname);
        $cdate = encode_utf8($cdate);
        $txt_icon = encode_utf8($txt_icon);
    }
    print "Content-type: application/x-www-form-urlencoded\n\n"
      or croak "$croak{'print'} content-type";
    print qq~$message|$myname|$cdate|$txt_icon|$mycal_type~
      or croak "$croak{'print'} message";
    $message = $mess;
    exit;
}

sub liveimage_resize {
    my ($resize_num);
    *check_image_resize = sub {
        my @x = @_;
        $resize_num++;
        $x[0] = "post_liveimg_resize_$resize_num";
        return qq~"$x[0]"$x[1]~;
    };

    $messageblock =~
      s/"(post_liveimg_resize)"([^>]*>)/ check_image_resize($1,$2) /gesm;
    $message =~
      s/"(post_liveimg_resize)"([^>]*>)/ check_image_resize($1,$2) /gesm;

    return;
}

1;
