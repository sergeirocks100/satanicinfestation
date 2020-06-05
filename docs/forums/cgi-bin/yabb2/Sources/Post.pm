###############################################################################
# Post.pm                                                                     #
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
# no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$postpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Post');
LoadLanguage('Display');
LoadLanguage('FA');
LoadLanguage('UserSelect');
LoadLanguage('LivePreview');

require Sources::Notify;
require Sources::SpamCheck;
require Sources::PostBox;
get_micon();
get_template('Post');


if (   $iamguest
    && $gpvalid_en
    && ( $enable_guestposting || $PMenableGuestButton || $PMAlertButtonGuests )
  )
{
    require Sources::Decoder;
}
$set_subjectMaxLength ||= 50;

LoadCensorList();
if ( $action eq 'eventcal' && $MaxCalMessLen && $AdMaxCalMessLen ) {
    $MaxMessLen   = $MaxCalMessLen;
    $AdMaxMessLen = $AdMaxCalMessLen;
}
if (
    (
           $action eq 'guestpm'
        || $action eq 'guestpm2'
        || $action eq 'modalert'
        || $action eq 'modalert2'
    )
    && $MaxIMMessLen
    && $AdMaxIMMessLen
  )
{
    $MaxMessLen   = $MaxIMMessLen;
    $AdMaxMessLen = $AdMaxIMMessLen;
}

if ( $iamadmin || $iamgmod ) { $MaxMessLen = $AdMaxMessLen; }

sub Post {
    if ( $iamguest && $enable_guestposting == 0 ) {
        fatal_error('not_logged_in');
    }
    if (  !$staff
        && $speedpostdetection
        && ${ $uid . $username }{'spamcount'} >= $post_speed_count )
    {
        $detention_time =
          ${ $uid . $username }{'spamtime'} + $spd_detention_time;
        if ( $date <= $detention_time ) {
            $detention_left = $detention_time - $date;
            fatal_error('speedpostban');
        }
        else {
            ${ $uid . $username }{'spamcount'} = 0;
            UserAccount( $username, 'update' );
        }
    }
    if ( $currentboard eq q{} && !$iamguest ) { fatal_error('no_access'); }
    my ( $filetype_info, $filesize_info );
    my ( $subtitle, $x, $msubject, $mattach, $mip, $mmessage, $mns );
    my $quotemsg = $INFO{'quote'};
    $threadid = $INFO{'num'};

    my (
        $mnum,     $msub,      $mname, $memail, $mdate,
        $mreplies, $musername, $micon, $mstate
    ) = split /\|/xsm, $yyThreadLine;

    my $icanbypass;
    ## only if bypass switched on
    if ( $mstate =~ /l/ism && $bypass_lock_perm ) {
        $icanbypass = checkUserLockBypass();
    }
    if ( $action eq 'modalert' ) { $icanbypass = 1; }
    if ( $mstate =~ /l/ism && !$icanbypass ) { fatal_error('topic_locked'); }

    # Determine category
    $curcat = ${ $uid . $currentboard }{'cat'};
    BoardTotals( 'load', $currentboard );

    # Figure out the name of the category
    get_forum_master();
    ( $cat, $catperms ) = split /\|/xsm, $catinfo{$curcat};
    ToChars($cat);

    $pollthread = 0;
    $postthread = 0;
    $INFO{'title'} =~ tr/+/ /;

    if ( $INFO{'title'} eq 'CreatePoll' ) {
        $pollthread = 1;
        $t_title    = $post_polltxt{'1a'};
    }
    elsif ( $INFO{'title'} eq 'AddPoll' ) {
        $pollthread = 2;
        $t_title    = $post_polltxt{'2a'};
    }
    elsif ( $INFO{'title'} eq 'PostReply' || $INFO{'num'} ) {
        $postthread = 2;
        $t_title    = $display_txt{'116'};
    }
    else { $postthread = 1; $t_title = $post_txt{'33'}; }
    if ( $FORM{'title'} eq 'PostReply' ) { $postthread = 2; }
    if ( $pollthread == 2 && $useraddpoll == 0 ) { fatal_error('no_access'); }

    $guestpost_fields = q{};
    if ( $iamguest ) {
    $guestpost_fields = $mypost_guest_fields;
    $guestpost_fields =~ s/{yabb name}/$FORM{'name'}/sm;
    $guestpost_fields =~ s/{yabb email}/$FORM{'email'}/sm;
    }

    if ( $iamguest && $gpvalid_en ) {
        validation_code();
        $verification_field =
            $verification eq q{}
          ? $mypost_guest_c
          : q{};
        $verification_field =~ s/{yabb showcheck}/$showcheck/sm;
        $verification_field =~ s/{yabb flood_text}/$flood_text/sm;
    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$post_txt{'verification_question_case'}~;
        }
        $verification_question_field =
            $verification_question eq q{}
          ? $mypost_guest_e
          : q{};
        $verification_question_field =~
          s/{yabb spam_question}/$spam_question/gsm;
        $verification_question_field =~
          s/{yabb verification_question_desc}/$verification_question_desc/sm;
        $verification_question_field =~
          s/{yabb spam_question_id}/$spam_question_id/sm;
        $verification_question_field =~ s/{yabb spam_question_image}/$spam_image/sm;
    }

    $sub        = q{};
    $settofield = 'subject';
    if ( $threadid ne q{} ) {
        if ( !ref $thread_arrayref{$threadid} ) {
            fopen( FILE, "$datadir/$threadid.txt" )
              or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
            @{ $thread_arrayref{$threadid} } = <FILE>;
            fclose(FILE);
        }
        if ( $quotemsg ne q{} ) {
            (
                $msubject, $mname,   $memail, $mdate,    $musername,
                $micon,    $mattach, $mip,    $mmessage, $mns
            ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[$quotemsg];
            $message = $mmessage;
            $message =~ s/<br.*?>/\n/igsm;
            $message =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/igsm;
            if ( !$nestedquotes ) {
                $message =~
s/\n{0,1}\[quote([^\]]*)\](.*?)\[\/quote([^\]]*)\]\n{0,1}/\n/isgm;
            }
            $mname = isempty( $mname, isempty( $musername, $post_txt{'470'} ) );
            my $hidename = $musername;
            if ( $musername eq 'Guest' ) { $hidename = $mname; }
            if ($do_scramble_id) { $hidename = cloak($hidename); }
            $usernames_life_quote{$hidename} = $mname;

            # for display names in Quotes in LivePreview
            my $maxlengthofquote =
              $MaxMessLen -
              length(
qq~[quote author=$hidename link=$threadid/$quotemsg#$quotemsg date=$mdate\]\[/quote\]\n~
              ) - 3;
            my $mess_len = $message;
            ToChars($mess_len);
            $mess_len =~ s/[\r\n ]//igsm;
            $mess_len =~ s/&#\d{3,}?\;/X/igxsm;

            if ( length $mess_len >= $maxlengthofquote ) {
                LoadLanguage('Error');
                alertbox( $error_txt{'quote_too_long'} );
                $message = substr( $message, 0, $maxlengthofquote ) . q{...};
                my @c = $message =~ m/\[code\]/gxsm;
                my $countc = @c;
                my @d = $message =~ m~\[/code\]~gxsm;
                my $countd = @d;
                if ($countc > $countd ) {
                    $message = $message . q~[/code]~;
                }
            }
            undef $mess_len;
            $message =
qq~[quote author=$hidename link=$threadid/$quotemsg#$quotemsg date=$mdate\]$message\[/quote\]\n~;
            if ( $mns eq 'NS' ) { $nscheck = q~ checked="checked"~; }
        }
        else {
            (
                $msubject, $mname,   $memail, $mdate,    $musername,
                $micon,    $mattach, $mip,    $mmessage, $mns
            ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[0];
        }
        $msubject =~ s/\bre:\s+//igxsm;
        $sub        = "Re: $msubject";
        $settofield = 'message';
    }

    $submittxt   = "$post_txt{'105'}";
    $destination = 'post2';
    $icon        = 'xx';
    $post        = 'post';
    $prevmain    = q{};
    if ( !$Quick_Post ) { $yytitle = "$t_title"; }
    Postpage();
    if ( !$Quick_Post ) { doshowthread(); }

    template();
    return;
}

##  post message page
sub Postpage {
    my $extra;
    my ( $filetype_info, $filesize_info, $extensions );
    $extensions = join q{ }, @ext;
    $filetype_info =
      $checkext == 1
      ? qq~$fatxt{'2'} $extensions~
      : qq~$fatxt{'2'} $fatxt{'4'}~;
    $limit ||= 0;
    $filesize_info =
      $limit != 0 ? qq~$fatxt{'3'} $limit KB~ : qq~$fatxt{'3'} $fatxt{'5'}~;
    $normalquot = $post_txt{'599'};
    $simpelquot = $post_txt{'601'};
    $simpelcode = $post_txt{'602'};
    $edittext   = $post_txt{'603'};
    if ( !$fontsizemax ) { $fontsizemax = 72; }
    if ( !$fontsizemin ) { $fontsizemin = 6; }

    if ( $postid eq 'Poll' ) { $sub = "$post_txt{'66a'}"; }

    $message =~ s/<\//\&lt\;\//igxsm;
    ToChars($message);
    $message = Censor($message);
    ToChars($sub);
    $sub = Censor($sub);

    if ( $action eq 'modify' || $action eq 'modify2' ) {
        $displayname = qq~$mename~;
        $moddate     = $tmpmdate;
        if (
            $showmodify
            && ( !$tllastmodflag
                || ( $tmpmdate + ( $tllastmodtime * 60 ) ) < $date )
          )
        {
            $tmplastmodified =
                qq~&#171; <i>$display_txt{'211'}: ~
              . timeformat($date,0,0,0,1)
              . qq~ $display_txt{'525'} ${$uid.$username}{'realname'}</i> &#187;~;
        }
        $tmpmusername = $thismusername;
    }
    else {
        $displayname     = ${ $uid . $username }{'realname'};
        $moddate         = $date;
        $tmplastmodified = q{};
        $tmpmusername    = $username;
    }
    $moddate = timeformat($moddate);
    require Sources::ContextHelp;
    ContextScript('post');

    if (   $postid ne 'Poll'
        && $destination ne 'modalert2'
        && $destination ne 'guestpm2' )
    {
        $extra = $mypost_extra;
        my $iconopts = q{};

        @iconlist =();
        for my $key ( sort keys %iconlist ) {
            my ($img, $alt) = split /[|]/xsm, $iconlist{$key};
            my $myic = q{};
            if ( $icon eq $img ) {$myic = ' selected="selected" '; }
            $iconopts .= qq~                <option value="$img"$myic>$alt</option>\n~;
        }

        $extra =~ s/{yabb iconopts}/$iconopts/sm;
        $extra =~ s/{yabb icon}/$icon/sm;
        $extra =~ s/{yabb icon_img}/$micon_bg{$icon}/sm;

        if ( $iamguest && $threadid ne q{} ) { $settofield = 'name'; }
    }

    if ( $pollthread && $iamguest ) { $guest_vote = 1; }
    if ( $pollthread == 2 ) { $settofield = 'question'; }

    # this defines if the notify on reply is shown or not.
    if (   $iamguest
        || $destination eq 'modalert2'
        || $destination eq 'guestpm2' )
    {
        $notification = q{};
    }
    else {

     # check if you are already being notified and if so we check the checkbox.
     # if the mail file exists then we have to check it otherwise we continue on
        my $notify    = q{};
        my $hasnotify = 0;
        $notifytext = qq~$post_txt{'750'}~;
        if ( !$FORM{'notify'} && !exists $FORM{'hasnotify'} ) {
            ManageThreadNotify( 'load', $threadid );
            if ( exists $thethread{$username} ) {
                $notify    = q~ checked="checked"~;
                $hasnotify = 1;
            }
            undef %thethread;

            ManageBoardNotify( 'load', $currentboard );
            if ( exists $theboard{$username}
                && ( split /\|/xsm, $theboard{$username} )[1] == 2 )
            {
                $notify     = q~ disabled="disabled" checked="checked"~;
                $hasnotify  = 2;
                $notifytext = qq~$post_txt{'132'}~;
            }
            undef %theboard;

        }
        else {
            if ( $FORM{'notify'} eq 'x' ) { $notify = q~ checked="checked"~; }
            $hasnotify = $FORM{'hasnotify'};
            if ( $hasnotify == 2 ) {
                $notify     = q~ disabled="disabled" checked="checked"~;
                $notifytext = qq~$post_txt{'132'}~;
            }
        }

        if ( $postid ne 'Poll' ) {
            $notification = $mypost_notification;
            $notification =~ s/{yabb hasnotify}/$hasnotify/sm;
            $notification =~ s/{yabb notify}/$notify/sm;
            $notification =~ s/{yabb notifytext}/$notifytext/sm;
        }
    }

    #add to favorites checkbox code
    $favoriteadd = q{};
    if (  !$iamguest
        && $currentboard ne $annboard
        && $destination  ne 'modalert2' )
    {
        $favoritetext = $post_txt{'notfav'};
        require Sources::Favorites;
        $nofav = IsFav( $threadid, q{}, 1 );
        if ( $FORM{'favorite'} ) {
            $favorite = q~ checked="checked"~;
        }
        if ( !$nofav ) {
            $favorite     = q~ disabled="disabled" checked="checked"~;
            $favoritetext = $post_txt{'alreadyfav'};
            $hasfavorite  = 1;
        }
        elsif ( $nofav == 2 ) {
            $favorite     = q~ disabled="disabled"~;
            $favoritetext = $post_txt{'maximumfav'};
        }
        $favoriteadd = $mypost_favoriteadd;
        $favoriteadd =~ s/{yabb favorite}/$favorite/sm;
        $favoriteadd =~ s/{yabb favoritetext}/$favoritetext/sm;
    }

    if   ( !$sub ) { $subtitle = "<i>$post_txt{'33'}</i>"; }
    else           { $subtitle = "<i>$sub</i>"; }

    # this is shown every post page except the IM area.
    if (   $destination ne 'modalert2'
        && $destination ne 'guestpm2'
        && !$Quick_Post )
    {
        if ($threadid) {
            $threadlink =
              qq~<a href="$scripturl?num=$threadid" class="nav">$subtitle</a>~;
        }
        else {
            $threadlink = "$subtitle";
        }
        ToChars($boardname);
        ToChars($cat);
        $yynavigation =
qq~&rsaquo; <a href="$scripturl?catselect=$catid" class="nav">$cat</a> &rsaquo; <a href="$scripturl?board=$currentboard" class="nav">$boardname</a> &rsaquo; $t_title ( $threadlink )~;
    }
    elsif ( !$Quick_Post ) {
        $yynavigation = qq~&rsaquo; $t_title~;
    }
    $checkallcaps ||= 0;

    #this is the end of the upper area of the post page.
    $my_q_quote = qq~

<script type="text/javascript">
function alertqq() {
    alert("$post_txt{'alertquote'}");
}
function quick_quote_confirm(ahref) {
    if (document.postmodify.message.value === "") {
        window.location.href = ahref;
    } else {
        var Check = confirm('$post_txt{'quote_confirm'}');
        if (Check === true) {
            window.location.href = ahref;
        } else {
            document.postmodify.message.focus();
        }
    }
}

var postas = '$post';
function checkForm(theForm) {
    var isError = 0;
    var msgError = "$post_txt{'751'}\\n";
    ~ . (
        $iamguest && $post ne 'imsend' && $post ne 'imsend2'
        ? qq~if (theForm.name.value === "" || theForm.name.value == "_" || theForm.name.value == " ") { msgError += "\\n - $post_txt{'75'}"; if (isError === 0) isError = 2; }
    if (theForm.name.value.length > 25)  { msgError += "\\n - $post_txt{'568'}"; if (isError === 0) isError = 2; }
    if (theForm.email.value === "") { msgError += "\\n - $post_txt{'76'}"; if (isError === 0) isError = 3; }
    if (! checkMailaddr(theForm.email.value)) { msgError += "\\n - $post_txt{'500'}"; if (isError === 0) isError = 3; }~
        : qq~if (postas == "imsend" || postas == "imsend2") {
        if (theForm.toshow.options.length === 0 ) { msgError += "\\n - $post_txt{'752'}"; isError = 1; }
        else { selectNames(); }

    }~
      ) . qq~
    if (theForm.subject.value === "") { msgError += "\\n - $post_txt{'77'}"; if (isError === 0) isError = 4; }
    else if ($checkallcaps && theForm.subject.value.search(/[A-Z]{$checkallcaps,}/g) != -1) {
        if (isError === 0) { msgError = " - $post_txt{'79'}"; isError = 4; }
        else { msgError += "\\n - $post_txt{'79'}"; }
    }
    if (theForm.message.value === "") { msgError += "\\n - $post_txt{'78'}"; if (isError === 0) isError = 5; }
    else if ($checkallcaps && theForm.message.value.search(/[A-Z]{$checkallcaps,}/g) != -1) {
        if (isError === 0) { msgError = " - $post_txt{'79'}"; isError = 5; }
        else { msgError += "\\n - $post_txt{'79'}"; }
    }
    if (isError > 0) {
        alert(msgError);
        if (isError == 1) imWin();
        else if (isError == 2) theForm.name.focus();
        else if (isError == 3) theForm.email.focus();
        else if (isError == 4) theForm.subject.focus();
        else if (isError == 5) theForm.message.focus();
        return false;
    }
    return true;
}
</script>
~;

    # if this is an IM from the admin or to groups declare where it goes.
    if ( $INFO{'adminim'} || $INFO{'action'} eq 'imgroups' ) {
        $my_adminim =
qq~<form action="$scripturl?action=imgroups" method="post" name="postmodify" onsubmit="return submitproc()" accept-charset="$yymycharset">~;
    }
    else {
        if ($curnum) { $thecurboard = qq~num=$curnum\;action=$destination~; }
        elsif ( $destination eq 'guestpm2' ) {
            $thecurboard = qq~action=$destination~;
        }
        else { $thecurboard = qq~board=$currentboard\;action=$destination~; }

        $allowattach ||= 0;
        if (   AccessCheck( $currentboard, 4 ) eq 'granted'
            && $allowattach > 0
            && ${ $uid . $currentboard }{'attperms'} == 1 )
        {
            $my_adminim =
qq~<form action="$scripturl?$thecurboard" method="post" name="postmodify" enctype="multipart/form-data" onsubmit="if(!checkForm(this)) {return false} else {return submitproc()}" accept-charset="$yymycharset">~;
        }
        else {
            $my_adminim =
qq~<form action="$scripturl?$thecurboard" method="post" name="postmodify" enctype="application/x-www-form-urlencoded" onsubmit="if(!checkForm(this)) {return false} else {return submitproc()}" accept-charset="$yymycharset">~;
        }
    }
    if ( $postthread == 2 ) {
        $my_adminim .=
          q~<input type="hidden" id="title" name="PostReply" value="title" />~;
    }

    # this declares the beginning of the UBBC section

    $moresmilieslist   = q{};
    $more_smilie_array = q{};
    $i                 = 0;
    if ( $showadded == 1 ) {
        while ( $SmilieURL[$i] ) {
            if ( $SmilieURL[$i] =~ /\//ism ) { $tmpurl = $SmilieURL[$i]; }
            else { $tmpurl = qq~$imagesdir/$SmilieURL[$i]~; }
            $moresmilieslist .=
qq~             <img src="$tmpurl" class="bottom pointer" alt="$SmilieDescription[$i]" title="$SmilieDescription[$i]" onclick="javascript: MoreSmilies($i);" />$SmilieLinebreak[$i]\n~;
            $tmpcode = $SmilieCode[$i];
            $tmpcode =~ s/\&quot;/"+'"'+"/gxsm;

            #" Adding that because if not it screws up my syntax view'
            FromHTML($tmpcode);
            $tmpcode =~ s/&#36;/\$/gxsm;
            $tmpcode =~ s/&#64;/\@/gxsm;
            $more_smilie_array .= qq~" $tmpcode", ~;
            $i++;
        }
    }

    if ( $showsmdir == 1 ) {
        opendir DIR, "$htmldir/Smilies";
        @contents = readdir DIR;
        closedir DIR;
        foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
            ( $name, $extension ) = split /\./xsm, $line;
            if (   $extension =~ /gif/ism
                || $extension =~ /jpg/ism
                || $extension =~ /jpeg/ism
                || $extension =~ /png/ism )
            {
                if ( $line !~ /banner/ism ) {
                    $moresmilieslist .=
qq~             <img src="$yyhtml_root/Smilies/$line" class="bottom cursor" alt="$name" title="$name" onclick="javascript: MoreSmilies($i);" />$SmilieLinebreak[$i]\n~;
                    $more_smilie_array .= qq~" [smiley=$line]", ~;
                    $i++;
                }
            }
        }
    }

    $more_smilie_array .= q~""~;

    $my_smilie_code = qq~
    moresmiliecode = new Array($more_smilie_array);
    function MoreSmilies(i) {
        AddTxt=moresmiliecode[i];
        AddText(AddTxt);
    }
    ~;

    if ( $smiliestyle == 1 ) {
        $smiliewinlink = qq~$scripturl?action=smilieput~;
    }
    else { $smiliewinlink = qq~$scripturl?action=smilieindex~; }

    $my_smiliewin .= qq~
    function smiliewin() {
        window.open("$smiliewinlink", 'list', 'width=$winwidth, height=$winheight, scrollbars=yes');
    }
    ~;

    if ( $destination ne 'modalert2' && $destination ne 'guestpm2' ) {

        $my_modalert = qq~
    function showimage() {
        $jsPost
        var icon_set = document.postmodify.icon.options[document.postmodify.icon.selectedIndex].value;
        var icon_show = jsPost.getItem(icon_set);
        document.images.liveicons.src = icon_show;
        document.images.icons.src = icon_show;
    }~;
    }
    ToHTML($moddate);
    $my_topper = qq~
</script>
<input type="hidden" name="threadid" value="$threadid" />
<input type="hidden" name="postid" value="$postid" />
<input type="hidden" name="info" value="$idinfo" />
<input type="hidden" name="mename" id="mename" value="$mename" />
<input type="hidden" name="tmpmdate" id="tmpmdate" value="$tmpmdate" />
<input type="hidden" name="thismusername" value="$thismusername" />
<input type="hidden" name="tmpmusername" id="tmpmusername" value="$tmpmusername" />
<input type="hidden" name="tmpmoddate" id="tmpmoddate" value="$moddate" />
<input type="hidden" name="post_entry_time" value="$date" />
<input type="hidden" name="virboard" value="$INFO{'virboard'}$FORM{'virboard'}" />~;

    $iammod = 0;
    if ( keys(%moderators) > 0 ) {
        while ( $_ = each %moderators ) {
            if ( $username eq $_ ) { $iammod = 1; }
        }
    }
    if ( keys(%moderatorgroups) > 0 ) {
        while ( $_ = each %moderatorgroups ) {
            if ( ${ $uid . $username }{'position'} eq $_ ) { $iammod = 1; }
            foreach my $memberaddgroups ( split /,/xsm,
                ${ $uid . $username }{'addgroups'} )
            {
                if ( $memberaddgroups eq $_ ) { $iammod = 1; last; }
            }
        }
    }

    if (   $threadid
        && ( !$Quick_Post )
        && $postthread == 2
        && $username ne 'Guest' )
    {
        my ( $reptime, $repuser, $isreplying, @tmprepliers, $isrep,
            $template_viewers, $topviewers );
        chomp @repliers;
        for my $i ( 0 .. ( @repliers - 1 ) ) {
            ( $reptime, $repuser, $isreplying ) = split /\|/xsm, $repliers[$i];
            next if ( $date - $reptime ) > 600;
            if ( $repuser eq $username ) {
                push @tmprepliers, qq~$date|$repuser|1~;
                $isrep      = 1;
                $isreplying = 1;
            }
            else { push @tmprepliers, $repliers[$i]; }
            if ($isreplying) {
                LoadUser($repuser);
                $template_viewers .= qq~$link{$repuser}, ~;
                $topviewers++;
            }
        }
        if ( !$isrep ) {
            push @tmprepliers, qq~$date|$username|1~;
            $template_viewers .= qq~$link{$username}, ~;
            $topviewers++;
        }
        MessageTotals( 'load', $curnum );
        @repliers = @tmprepliers;
        MessageTotals( 'update', $curnum );

        if (   $showtopicrepliers
            && $template_viewers
            && ( $staff && $sessionvalid == 1 ) )
        {
            $template_viewers =~ s/\, \Z/\./sm;
            $my_tview = $mypost_topview;
            $my_tview =~ s/{yabb topviewers}/$topviewers/sm;
            $my_tview =~ s/{yabb template_viewers}/$template_viewers/sm;
        }
    }

    if ($pollthread) {
        $maxpq          ||= 60;
        $maxpo          ||= 50;
        $maxpc          ||= 0;
        $numpolloptions ||= 8;
        $vote_limit     ||= 0;
        $pie_radius     ||= 100;

        if ( ( $iamadmin || $iamgmod ) && -e "$datadir/showcase.poll" ) {
            fopen( FILE, "$datadir/showcase.poll" );
            if ( $threadid == <FILE> ) { $scchecked = ' checked="checked"'; }
            fclose(FILE);
        }
        if ($guest_vote)   { $gvchecked  = ' checked="checked"'; }
        if ($hide_results) { $hrchecked  = ' checked="checked"'; }
        if ($multi_choice) { $mcchecked  = ' checked="checked"'; }
        if ($pie_legends)  { $legchecked = ' checked="checked"'; }

        $piecolarray = q~["",~;
        for my $i ( 1 .. $numpolloptions ) {
            if ( $split[$i] ) { $splitchecked[$i] = ' checked="checked"'; }
            if ( $FORM{"slicecol$i"} ) {
                $slicecolor[$i] = $FORM{"slicecol$i"} || 'transparent';
            }
            $mypoll_opt .= $my_poll_options;
            $mypoll_opt =~ s/{yabb i}/$i/gsm;
            $mypoll_opt =~ s/{yabb maxpo}/$maxpo/gsm;
            $mypoll_opt =~ s/{yabb options_i}/$options[$i]/gsm;
            $mypoll_opt =~ s/{yabb slicecolor_i}/$slicecolor[$i]/gsm;
            $mypoll_opt =~ s/{yabb splitchecked_i}/$splitchecked[$i]/sm;
            $piecolarray .= qq~"$slicecolor[$i]", ~;
        }
        $piecolarray =~ s/\, $//ism;
        $piecolarray .= q~]~;

        if ( $maxpc > 0 ) {
            $my_maxpc = $my_poll_comment;
            $my_maxpc .=
qq~            <textarea name="poll_comment" rows="3" cols="60" wrap="soft" onkeyup="if (document.postmodify.poll_comment.value.length > {yabb maxpc}) {document.postmodify.poll_comment.value = document.postmodify.poll_comment.value.substring(0,$maxpc)}">$poll_comment</textarea>
~;
            $my_maxpc .= $my_poll_comment_b;
        }

        if ($poll_end) {
            my $x = $poll_end - $date;
            if ( $x <= 0 ) {
                $poll_end_min = 1;
            }
            else {
                $poll_end_days = int( $x / 86400 );
                $poll_end_min =
                  int( ( $x - ( $poll_end_days * 86400 ) ) / 60 );
            }
        }

        $my_pie = $mypost_poll_pie;
        $my_pie .=
          $poll_locked
          ? q{}
          : $my_poll_end;
        $my_pie .=
          ( $iamadmin || $iamgmod )
          ? $my_poll_sc
          : q{};
        $my_pie .= $my_poll_hide;

        $my_pie =~ s/{yabb piecolarray}/$piecolarray/sm;
        $my_pie =~ s/{yabb poll_end_days}/$poll_end_days/sm;
        $my_pie =~ s/{yabb poll_end_min}/$poll_end_min/sm;
        $my_pie =~ s/{yabb scchecked}/$scchecked/sm;
        $my_pie =~ s/{yabb gvchecked}/$gvchecked/sm;
        $my_pie =~ s/{yabb hrchecked}/$hrchecked/sm;
        $my_pie =~ s/{yabb mcchecked}/$mcchecked/sm;
        $my_pie =~ s/{yabb vote_limit}/$vote_limit/sm;
        $my_pie =~ s/{yabb legchecked}/$legchecked/sm;
        $my_pie =~ s/{yabb pie_radius}/$pie_radius/sm;

        $my_pollsection = $mypost_poll_top;
        $my_pollsection =~ s/{yabb poll_question}/$poll_question/sm;
        $my_pollsection =~ s/{yabb maxpq}/$maxpq/sm;
        $my_pollsection =~ s/{yabb pollthread}/$pollthread/sm;
        $my_pollsection =~ s/{yabb mypoll_opt}/$mypoll_opt/sm;
        $my_pollsection =~ s/{yabb my_maxpc}/$my_maxpc/sm;
        $my_pollsection =~ s/{yabb my_pie}/$my_pie/sm;
    }

    if ( $postid ne 'Poll' ) {
        $css = isempty( $css, 'windowbg' );
        if ( $tmpmusername eq 'Guest' ) {
            $liveusernamelink      = qq~<b>$mename</b>~;
            $livememberinfo        = "$maintxt{'28'}";
            $livememberstar        = q{};
            $livetemplate_postinfo = q{};
            $tmplastmodified       = q{};
            $liveuserlocation      = q{};
        }
        else {
            if ( !${ $uid . $tmpmusername }{'password'} ) {
                LoadUser($tmpmusername);
            }
            if ( $tmpmusername eq $username ) { LoadMiniUser($tmpmusername); }
            if ( !$yyUDLoaded{$tmpmusername}
                && -e ("$memberdir/$tmpmusername.vars") )
            {
                my $tmpmess = $message;
                LoadUserDisplay($tmpmusername);
                $message = $tmpmess;
            }
            $liveusernamelink = $format{$tmpmusername};
            $livememberinfo =
              "$memberinfo{$tmpmusername}$addmembergroup{$tmpmusername}";
            $livememberstar = $memberstar{$tmpmusername};

            $livepostcount =
              NumberFormat( ${ $uid . $tmpmusername }{'postcount'} );
            $livetemplate_postinfo =
              qq~$display_txt{'21'}: $livepostcount<br />~;
            if (   ${ $uid . $tmpmusername }{'bday'}
                && $showuserage
                && ( !$showage || !${ $uid . $tmpmusername }{'hideage'} ) )
            {
                CalcAge( $tmpmusername, 'calc' );
                $liveuser_age = qq~$display_txt{'age'}: $age<br />~;
            }
            if ( $showregdate && ${ $uid . $tmpmusername }{'regtime'} ) {
                $dr_regdate =
                  timeformat( ${ $uid . $tmpmusername }{'regtime'} );
                $dr_regdate = dtonly($dr_regdate);
                $dr_regdate =~ s/(.*)(, 1?[0-9]):[0-9][0-9].*/$1/xsm;
                $liveuser_regdate =
                  qq~$display_txt{'regdate'} $dr_regdate<br />~;
            }
            if ( ${ $uid . $tmpmusername }{'location'} ) {
                $liveuserlocation =
                    qq~$display_txt{'location'}:~
                  . ${ $uid . $tmpmusername }{'location'}
                  . '<br />';
            }
            if ( $action eq 'modify' ) {
                if (
                    $showmodify
                    && ( !$tllastmodflag
                        || ( $tmpmdate + ( $tllastmodtime * 60 ) ) < $date )
                  )
                {
                    $tmplastmodified =
qq~<div class="small" style="float: right; width: 100%; text-align: right; margin-top: 5px;">&#171; <i>$display_txt{'211'}: ~
                      . timeformat($date,0,0,0,1)
                      . qq~ $display_txt{'525'} ${$uid.$username}{'realname'}</i> &#187; &nbsp;</div>~;
                }
            }
            else {
                $subjdate        = timeformat($date);
                $tmplastmodified = q{};
            }
            if ( ${ $uid . $tmpmusername }{'signature'} ) {
                $livesignature_hr = q~<hr class="hr att_hr" />~;
            }
        }
        $liveipimg = qq~<img src="$micon_bg{'ip'}" alt="" />~;
        $livemip   = $display_txt{'511'};

        $livemsgimg = qq~<img src="$micon_bg{$icon}" id="liveicons" alt="" />~;
        get_template('Post');

        FromHTML($moddate);
        $messageblock = $mypost_liveprev;
        $messageblock =~ s/{yabb images}/$imagesdir/gsm;
        $messageblock =~ s/{yabb css}/$css/gsm;
        $messageblock =~
s/{yabb userlink}/<span id="savename" style="font-weight: bold">$liveusernamelink<\/span>/gsm;
        $messageblock =~ s/{yabb memberinfo}/$livememberinfo/gsm;
        $messageblock =~ s/{yabb stars}/$livememberstar/gsm;
        $messageblock =~ s/{yabb location}/$liveuserlocation/gsm;
        $messageblock =~
          s/{yabb gender}/${$uid.$tmpmusername}{'gender'}/gsm;
        $messageblock =~
          s/{yabb usertext}/${$uid.$tmpmusername}{'usertext'}/gsm;
        $messageblock =~
          s/{yabb userpic}/${$uid.$tmpmusername}{'userpic'}/gsm;
        $messageblock =~ s/{yabb postinfo}/$livetemplate_postinfo/gsm;
        $messageblock =~ s/{yabb msgdate}/$moddate/gsm;
        $messageblock =~ s/{yabb msgimg}/$livemsgimg/gsm;
        $messageblock =~ s/{yabb age}/$liveuser_age/gsm;
        $messageblock =~ s/{yabb regdate}/$liveuser_regdate/gsm;
        $messageblock =~
          s/{yabb subject}/<span id="savesubj"><\/span>/gsm;
        $messageblock =~
          s/{yabb message}/<span id="savemess"><\/span>/gsm;
        $messageblock =~ s/{yabb modified}/$tmplastmodified/gsm;
        $messageblock =~ s/{yabb ipimg}/$liveipimg/gsm;
        $messageblock =~ s/{yabb ip}/$livemip/gsm;
        $messageblock =~
          s/{yabb signature}/${$uid.$tmpmusername}{'signature'}/gsm;
        $messageblock =~ s/{yabb signaturehr}/$livesignature_hr/gsm;
        $messageblock =~ s/{yabb (.+?)}//gsm;

        if ( !$minlinkpost ) { $minlinkpost = 0; }

        if ( ( $iamguest && $minlinkpost > 0 )
            || ${ $uid . $username }{'postcount'} < $minlinkpost
            && !$iamadmin
            && !$iamgmod
            && !$iammod )
        {
            $nolinkallow = 1;
        }

        $my_postsection_ajx = my_check_prev();

        $topicstatus_row = q{};
        $stselect        = q{};
        $lcselect        = q{};
        $hdselect        = q{};
        $threadclass     = 'thread';

        (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate
        ) = split /\|/xsm, $yyThreadLine;
        if   ( $FORM{'topicstatus'} ) { $thestatus = $FORM{'topicstatus'}; }
        else                          { $thestatus = $mstate; }
        if ( $currentboard eq $annboard ) {
            $threadclass = 'announcement';
        }
        else {
            if ( $mreplies >= $VeryHotTopic ) {
                $threadclass = 'veryhotthread';
            }
            elsif ( $mreplies >= $HotTopic ) { $threadclass = 'hotthread'; }
        }
        if ( $action ne 'modalert' ) {
            if ( $thestatus =~ /s/sm ) { $stselect = q~selected="selected"~; }
            if ( $thestatus =~ /l/sm ) { $lcselect = q~selected="selected"~; }
            if ( $thestatus =~ /h/sm ) { $hdselect = q~selected="selected"~; }
            $hidestatus = q{};

            if ( $staff && $sessionvalid == 1 ) {
                $my_curbrd = $currentboard ne $annboard ? 3 : 2;
                $my_stselect =
                  $currentboard ne $annboard
                  ? qq~<option value="s" $stselect>$post_txt{'35'}</option>~
                  : q{};
                $my_t_status = $mypost_topicstatus;
                $my_t_status =~ s/{yabb my_curbrd}/$my_curbrd/sm;
                $my_t_status =~ s/{yabb my_stselect}/$my_stselect/sm;
                $my_t_status =~ s/{yabb lcselect}/$lcselect/sm;
                $my_t_status =~ s/{yabb hdselect}/$hdselect/sm;
                $my_t_status =~ s/{yabb threadclass}/$threadclass/sm;
                $my_t_status =~
                  s/{yabb threadclass_img}/$micon_bg{$threadclass}/sm;
            }
            else {
                $hidestatus =
qq~<input type="hidden" value="$thestatus" name="topicstatus" />~;
            }
        }
        $my_submax = $set_subjectMaxLength + ( $sub =~ /^Re: /sm ? 4 : 0 );

        if (   $post ne 'imsend'
            && $postid ne 'Poll'
            && ( $action eq 'modify' || $action eq 'modify2' )
            && ( ( $staff && $staff_reason ) || $user_reason ) )
        {
            $my_reason = $mypost_reason;
            $my_reason =~ s/{yabb reason}/$reason/sm;
        }

        $my_rem_smilies =
          (      !$removenormalsmilies
              || ( $showadded == 3 && $showsmdir != 2 )
              || ( $showsmdir == 3 && $showadded != 2 ) ) ? 2 : 3;

        if ( $enable_ubbc && $showyabbcbutt ) {
            $my_ubbc = postbox();
        }

        # SpellChecker start
        if ($enable_spell_check) {
            $yyinlinestyle .= googiea();
            $userdefaultlang = ( split /-/xsm, $abbr_lang )[0];
            $userdefaultlang ||= 'en';
            $my_googie = googie($userdefaultlang);
        }

        # SpellChecker end

        if ( $showadded == 2 || $showsmdir == 2 ) {
            $mypost_smilie_array_top = q~
            <script type="text/javascript">
            function Smiliextra() {
                AddTxt=smiliecode[document.postmodify.smiliextra_list.value];
                AddText(AddTxt);
            }
            </script>~;

            $smilieslist       = q{};
            $smilie_url_array  = q{};
            $smilie_code_array = q{};
            $i                 = 0;
            if ( $showadded == 2 ) {
                while ( $SmilieURL[$i] ) {
                    $smilieslist .= qq~ <option value="$i"~
                      . (
                        $SmilieDescription[$i] eq $showinbox
                        ? ' selected="selected"'
                        : q{}
                      ) . qq~>$SmilieDescription[$i]</option>\n~;
                    if ( $SmilieURL[$i] =~ /\//ism ) {
                        $tmpurl = $SmilieURL[$i];
                    }
                    else { $tmpurl = qq~$defaultimagesdir/$SmilieURL[$i]~; }
                    $smilie_url_array .= qq~"$tmpurl", ~;
                    $tmpcode = $SmilieCode[$i];
                    $tmpcode =~ s/\&quot;/"+'"'+"/gxsm;
                    FromHTML($tmpcode);
                    $tmpcode =~ s/&#36;/\$/gxsm;
                    $tmpcode =~ s/&#64;/\@/gxsm;
                    $smilie_code_array .= qq~" $tmpcode", ~;
                    $i++;
                }
            }
            if ( $showsmdir == 2 ) {
                opendir DIR, "$htmldir/Smilies";
                @contents = readdir DIR;
                closedir DIR;
                foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
                    ( $name, $extension ) = split /\./xsm, $line;
                    if (   $extension =~ /gif/ism
                        || $extension =~ /jpg/ism
                        || $extension =~ /jpeg/ism
                        || $extension =~ /png/ism )
                    {
                        if ( $line !~ /banner/ism ) {
                            $smilieslist .=
                              qq~   <option value="$i"~
                              . (
                                $name eq $showinbox
                                ? ' selected="selected"'
                                : q{}
                              ) . qq~>$name</option>\n~;
                            $smilie_url_array .=
                              qq~"$yyhtml_root/Smilies/$line", ~;
                            $smilie_code_array .= qq~" [smiley=$line]", ~;
                            $i++;
                        }
                    }
                }
            }
            $smilie_url_array  .= q~""~;
            $smilie_code_array .= q~""~;

            $mypost_smilie_array = qq~
            $mypost_smilie_array_top
            <script type="text/javascript">
            smilieurl = new Array($smilie_url_array);
            smiliecode = new Array($smilie_code_array);
            </script>
            $mypost_smiley1
            ~;
            $mypost_smilie_array =~ s/{yabb smilieslist}/$smilieslist/sm;
        }
        else {
            $mypost_smilie_array .= q~
            &nbsp;
            ~;
        }

        $my_post_feata = $mypost_feata;
        $my_post_feata .= qq~
            <span class="small"><img src="$imagesdir/$newload{'brd_col'}" id="feature_col" alt="$npf_txt{'collapse_features'}" title="$npf_txt{'collapse_features'}" class="cursor" onclick="show_features(0);" /> $npf_txt{'features_text'}</span>~;

        if (
            !$removenormalsmilies
            && (   !${ $uid . $username }{'hide_smilies_row'}
                || !$user_hide_smilies_row )
          )
        {
            $my_smilies = $mypost_smilies;
            $my_smilies .= smilies_list();
        }
        else {
            $my_smilies = qq~$mypost_smilies &nbsp; ~;
        }

        if (   ( $showadded == 3 && $showsmdir != 2 )
            || ( $showsmdir == 3 && $showadded != 2 ) )
        {
            if ($removenormalsmilies) {
                $my_smilies = $mypost_smilies;
            }
            $my_smilies .=
              qq~<a href="javascript: smiliewin();">$post_smiltxt{'1'}</a>\n~;
        }

        $my_post_smilies .= $mypost_smilies_c;
        $my_post_smilies =~ s/{yabb my_smilies}/$my_smilies/sm;

        # File Attachment's Browse Box Code
        $allowattach ||= 0;
        if (
               AccessCheck( $currentboard, 4 ) eq 'granted'
            && $allowattach > 0
            && ${ $uid . $currentboard }{'attperms'} == 1
            && -d "$uploaddir"
            && (   $action eq 'post'
                || $action eq 'post2'
                || $action eq 'modify'
                || $action eq 'modify2' )
            && ( ( $allowguestattach == 0 && !$iamguest )
                || $allowguestattach == 1 )
          )
        {
            $mfn = $mfn || $FORM{'oldattach'};
            my @files = split /,/xsm, $mfn;

            if ( $allowattach > 1 ) {
                $my_att_allow = qq~
            <img src="$imagesdir/$newload{'brd_exp'}" id="attform_add" alt="$fatxt{'80a'}" title="$fatxt{'80a'}" class="cursor" onclick="enabPrev2(1);" />
            <img src="$imagesdir/$newload{'brd_col'}" id="attform_sub" alt="$fatxt{'80s'}" title="$fatxt{'80s'}" class="cursor" style="visibility:hidden;" onclick="enabPrev2(-1);" />~;
            }

            my $startcount;
            for my $y ( 1 .. $allowattach ) {
                if (   ( $action eq 'modify' || $action eq 'modify2' )
                    && $files[ $y - 1 ] ne q{}
                    && -e "$uploaddir/$files[$y-1]" )
                {
                    $startcount++;
                    $my_att_a = qq~
            <div id="attform_a_$y" class="att_lft~
                      . ( $y > 1 ? q~_b~ : q{} )
                      . qq~"><b>$fatxt{'6'} $y:</b></div>
            <div id="attform_b_$y" class="att_rgt~
                      . ( $y > 1 ? q~_b~ : q{} ) . qq~">
                <input type="file" name="file$y" id="file$y" size="50" onchange="selectNewattach($y);" /> <span class="cursor small bold" title="$fatxt{'81'}" onclick="document.getElementById('file$y').value='';">X</span><br />
                    <span style="font-size:x-small">
                        <input type="hidden" id="w_filename$y" name="w_filename$y" value="$files[$y-1]" />
                        <select id="w_file$y" name="w_file$y" size="1">
                        <option value="attachdel">$fatxt{'6c'}</option>
                        <option value="attachnew">$fatxt{'6b'}</option>
                        <option value="attachold" selected="selected">$fatxt{'6a'}</option>
                        </select>&nbsp;$fatxt{'40'}: <a href="$uploadurl/$files[$y-1]" target="_blank">$files[$y-1]</a>
                    </span></div>~;
                }
                else {
                    $my_att_a = qq~
            <div id="attform_a_$y" class="att_lft"~
                      . (
                        $y > 1
                        ? q~ style="visibility:hidden; height:0px"~
                        : q{}
                      )
                      . qq~><b>$fatxt{'6'} $y:</b></div>
            <div id="attform_b_$y" class="att_rgt"~
                      . (
                        $y > 1
                        ? q~ style="visibility:hidden; height:0px"~
                        : q{}
                      )
                      . qq~>\n             <input type="file" name="file$y" id="file$y" size="50" /> <span class="cursor small bold" title="$fatxt{'81'}" onclick="document.getElementById('file$y').value='';">X</span></div>~;
                }
                $mypoll_att .= $my_att_a;

            }
            if ( !$startcount ) { $startcount = 1; }

            if ( $allowattach > 1 ) {
                $my_att_b = qq~
            <script type="text/javascript">
            var countattach = $startcount;~
                  . (
                    $startcount > 1
                    ? qq~\n         document.getElementById("attform_sub").style.visibility = "visible";~
                    : q{}
                  )
                  . qq~
            function enabPrev2(add_sub) {
                if (add_sub == 1) {
                    countattach = countattach + add_sub;
                    document.getElementById("attform_a_" + countattach).style.visibility = "visible";
                    document.getElementById("attform_a_" + countattach).style.height = "auto";
                    document.getElementById("attform_a_" + countattach).style.paddingTop = "5px";
                    document.getElementById("attform_b_" + countattach).style.visibility = "visible";
                    document.getElementById("attform_b_" + countattach).style.height = "auto";
                    document.getElementById("attform_b_" + countattach).style.paddingTop = "5px";
                } else {
                    document.getElementById("attform_a_" + countattach).style.visibility = "hidden";
                    document.getElementById("attform_a_" + countattach).style.height = "0px";
                    document.getElementById("attform_a_" + countattach).style.paddingTop = "0px";
                    document.getElementById("attform_b_" + countattach).style.visibility = "hidden";
                    document.getElementById("attform_b_" + countattach).style.height = "0px";
                    document.getElementById("attform_b_" + countattach).style.paddingTop = "0px";
                    countattach = countattach + add_sub;
                }
                if (countattach > 1) {
                    document.getElementById("attform_sub").style.visibility = "visible";
                } else {
                    document.getElementById("attform_sub").style.visibility = "hidden";
                }
                if ($allowattach <= countattach) {
                    document.getElementById("attform_add").style.visibility = "hidden";
                } else {
                    document.getElementById("attform_add").style.visibility = "visible";
                }
            }
            </script>~;
            }
            $my_feat5 = $mypost_feat5;
            $my_feat5 =~ s/{yabb mfn}/$mfn/sm;
            $my_feat5 =~ s/{yabb my_att_mfn}/$my_att_mfn/sm;
            $my_feat5 =~ s/{yabb my_att_allow}/$my_att_allow/sm;
            $my_feat5 =~ s/{yabb filetype_info}/$filetype_info/sm;
            $my_feat5 =~ s/{yabb filesize_info}/$filesize_info/sm;
            $my_feat5 =~ s/{yabb mypoll_att}/$mypoll_att/sm;
            $my_feat5 =~ s/{yabb my_att_b}/$my_att_b/sm;

        }

        # /File Attachment's Browse Box Code

        ### Return To mod start ###
        my ($return_to);
        my $rts =
            $FORM{'return_to'}
          ? $FORM{'return_to'}
          : ${ $uid . $username }{'return_to'};
        for my $rt ( 1 .. 3 ) {
            $return_to_select .=
              $rts == $rt
              ? qq~<option value="$rt" selected="selected">$return_to_txt{$rt}</option>~
              : qq~<option value="$rt">$return_to_txt{$rt}</option>~;
        }
        if ( $destination ne 'modalert2' && $destination ne 'guestpm2' ) {
            $return_to = $mypost_return_to;
            $return_to =~ s/{yabb return_to_select}/$return_to_select/sm;
        }
        ### Return To modify end ###
        $guestpost_col = $my_guestpost_col;
        if ( $iamguest ) { $guestpost_col = $my_guestpost_col + 2; }
        $my_postsec_b   = postbox2();
        $my_postsection = $mypost_postblock;
        $my_postsection =~ s/{yabb my_postsection_ajx}/$my_postsection_ajx/sm;
        $my_postsection =~ s/{yabb messageblock}/$messageblock/sm;
        $my_postsection =~ s/{yabb my_t_status}/$my_t_status/sm;
        $my_postsection =~ s/{yabb extra}/$extra/sm;
        $my_postsection =~ s/{yabb name_field}/$guestpost_fields/sm;
        $my_postsection =~ s/{yabb email_field}/$email_field/sm;
        $my_postsection =~ s/{yabb verification_field}/$verification_field/sm;
        $my_postsection =~ s/{yabb guestcol}/$guestpost_col/gsm;
        $my_postsection =~ s/{yabb verification_question_field}/$verification_question_field/sm;
        $my_postsection =~ s/{yabb sub}/$sub/sm;
        $my_postsection =~ s/{yabb my_submax}/$my_submax/sm;
        $my_postsection =~ s/{yabb myreason}/$my_reason/sm;
        $my_postsection =~ s/{yabb my_rem_smilies}/$my_rem_smilies/sm;
        $my_postsection =~ s/{yabb my_ubbc}/$my_ubbc/sm;
        $my_postsection =~ s/{yabb my_postsec_b}/$my_postsec_b/sm;
        $my_postsection =~ s/{yabb my_googie}/$my_googie/sm;
        $my_postsection =~ s/{yabb mypost_smilie_array}/$mypost_smilie_array/sm;
        $my_postsection =~ s/{yabb my_post_feata}/$my_post_feata/sm;
        $my_postsection =~ s/{yabb my_post_smilies}/$my_post_smilies/sm;
        $my_postsection =~ s/{yabb my_feat5}/$my_feat5/sm;
        $my_postsection =~ s/{yabb my_is_prev}/$my_is_prev/sm;
        $my_postsection =~ s/{yabb notification}/$notification/sm;
        $my_postsection =~ s/{yabb favoriteadd}/$favoriteadd/sm;
        $my_postsection =~ s/{yabb lastmod}/$lastmod/sm;
        $my_postsection =~ s/{yabb nscheck}/$nscheck/sm;
        $my_postsection =~ s/{yabb return_to}/$return_to/sm;
    }

    #    these are the buttons to submit
    $my_post_submit = qq~$mypost_submit
            $hidestatus
            <input type="submit" name="$post" id="$post" value="$submittxt" accesskey="s" tabindex="5" class="button" />
            <script type="text/javascript">
~;

    if ($speedpostdetection) {
        $my_spdpost = speedpost();
    }

    if ( !$yyinlinestyle =~ /cookiesupport\.js/xsm ) {
        $yyinlinestyle .=
qq~<script type="text/javascript" src="$yyhtml_root/googiespell/cookiesupport.js"></script>~;
    }

    if (   $postid ne 'Poll'
        && $post ne 'imsend'
        && $staff
        && $sessionvalid == 1 )
    {
        $my_tclass = qq~
<script type="text/javascript">
function showtpstatus() {
    $jsPstat
    var z = 0;
    var x = 0;
    var theimg = '$threadclass';
    for(var i=0; i<document.postmodify.topicstatus.length; i++) {
        if (document.postmodify.topicstatus[i].selected) { z++; x += i; }
    }~;
        if ( $currentboard ne $annboard ) {
            $my_tclass .= q~
    if(z == 1 && x === 0)  theimg = 'sticky';
    if(z == 1 && x == 1)  theimg = 'locked';
    if(z == 2 && x == 1)  theimg = 'stickylock';
    if(z == 1 && x == 2)  theimg = 'hide';
    if(z == 2 && x == 2)  theimg = 'hidesticky';
    if(z == 2 && x == 3)  theimg = 'hidelock';
    if(z == 3 && x == 3)  theimg = 'hidestickylock';~;
        }
        else {
            $my_tclass .= q~
    if(z == 1 && x === 0)  theimg = 'announcementlock';
    if(z == 1 && x == 1)  theimg = 'hide';
    if(z == 2 && x == 1)  theimg = 'hidelock';~;
        }
        $my_tclass .= q~
    var picon_show = jsPstat.getItem(theimg);
    document.images.thrstat.src = picon_show;
}
showtpstatus();
</script>~;
    }

    if ( $action eq 'modify' || $action eq 'modify2' ) {
        $displayname = qq~$mename~;
        $moddate     = $tmpmdate;
        if (
            $showmodify
            && ( !$tllastmodflag
                || ( $tmpmdate + ( $tllastmodtime * 60 ) ) < $date )
          )
        {
            $tmplastmodified =
                qq~&#171; <i>$display_txt{'211'}: ~
              . timeformat($date,0,0,0,1)
              . qq~ $display_txt{'525'} ${$uid.$username}{'realname'}</i> &#187;~;
        }
        $tmpmusername = $thismusername;
    }
    else {
        $displayname     = ${ $uid . $username }{'realname'};
        $moddate         = $date;
        $tmplastmodified = q{};
        $tmpmusername    = $username;
    }
    $moddate = timeformat($moddate);

    get_template('Display');

    foreach (@months) { $jsmonths .= qq~'$_',~; }
    $jsmonths =~ s/\,\Z//xsm;
    $jstimeselected = ${ $uid . $username }{'timeselect'} || $timeselected;

    if ( $postid ne 'Poll' ) {
        $my_ajxcall   = 'ajxmessage';
        $my_postbox_3 = postbox3();
        $my_postbox_3 .= qq~
<script src="$yyhtml_root/ajax.js" type="text/javascript"></script>
<script type="text/javascript">~;
        $my_postbox_3 .= my_liveprev();

        $my_postbox_3 .=
          ( !$Quick_Post ? "document.postmodify.$settofield.focus();" : q{} )
          . qq~\n\n~;

        if ( $post eq 'imsend' ) {
            $my_showCC = q~
if(document.getElementById('toshowcc').length > 0) document.getElementById('toshowcc').style.display = 'inline';
if(document.getElementById('toshowbcc').length > 0) document.getElementById('toshowbcc').style.display = 'inline';
~;
        }
        $my_postbox_3 .= q~</script>
~;
    }
    $yymain .= $ctmain;
    $yymain .= $my_q_quote;
    $yymain .= $my_adminim;
    $yymain .= $mypost_ubbc;
    $yymain .= $my_smilie_code;
    $yymain .= $my_smiliewin;
    $yymain .= $my_modalert;
    $yymain .= $mypost_title;

    $yymain .= $my_pollsection;
    $yymain .= $my_postsection;
    if ( $postid eq 'Poll' && $action eq 'modify') {
        $yymain .= $mypoll_tablefix;
    }
    $yymain .= $my_post_submit;
    $yymain .= $my_spdpost;
    $yymain .= $mypost_formend;
    $yymain .= $my_tclass;
    $yymain .= $my_postbox_3;
    $yymain .= $my_showCC;
    $yymain =~ s/{yabb my_topper}/$my_topper/sm;
    $yymain =~ s/{yabb icon}/$icon/sm;
    $yymain =~ s/{yabb icon_img}/$micon_bg{$icon}/sm;
    $yymain =~ s/{yabb yytitle}/$yytitle/sm;
    $yymain =~ s/{yabb my_topview}/$my_tview/sm;
    return;
}

##  show Error
sub Preview {
    my ($error) = @_;
    ToHTML($error);

    # allows the following HTML-tags in error messages: <br /> <b>
    $error =~ s/&lt;br( \/)&gt;/<br \/>/igsm;
    $error =~ s/&lt;(\/?)b&gt;/<$1b>/igxsm;
    if ( $action eq 'modify2' ) {
        $tmpmusername = $thismusername;
    }
    else {
        $tmpmusername = $username;
    }

    if ($error) {
        LoadLanguage('Error');
        $prevmain .= $mypost_prevmain_error;
        $prevmain =~ s/{yabb preverror}/$error/sm;
        $prevmain =~ s/{yabb error_occurred}/$error_txt{'error_occurred'}/sm;
    }

    $message = $mess;

    if ($error) { $csubject = $error; }

    $yytitle =
      $error
      ? "$error_txt{'error_occurred'} $csubject"
      : "$post_txt{'507'} - $csubject";
    $settofield = 'message';
    $postthread = 2;

    if ( !$view ) {
        Postpage();
        if ( $threadid ne q{} && $post eq 'post' ) { doshowthread(); }

        template();
    }
    return;
}

sub Post2 {
    if ( $iamguest && $enable_guestposting == 0 ) {
        fatal_error('not_logged_in');
    }

    if (  !$staff
        && $speedpostdetection
        && ${ $uid . $username }{'spamcount'} >= $post_speed_count )
    {
        $detention_time =
          ${ $uid . $username }{'spamtime'} + $spd_detention_time;
        if ( $date <= $detention_time ) {
            $detention_left = $detention_time - $date;
            fatal_error('speedpostban');
        }
        else {
            ${ $uid . $username }{'spamcount'} = 0;
            UserAccount( $username, 'update' );
        }
    }
    if ( $iamguest && $gpvalid_en ) {
        validation_check( $FORM{'verification'} );
    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    }
    my (
        $email,     $ns,    $notify, $hasnotify, $i,
        $mnum,      $msub,  $mname,  $memail,    $mdate,
        $musername, $micon, $mstate, $pageindex, $tempname
    );

    BoardTotals( 'load', $currentboard );

    # Get the form values
    $name     = $FORM{'name'};
    $email    = $FORM{'email'};
    $subject  = $FORM{'subject'};
    $message  = $FORM{'message'};
    $icon     = $FORM{'icon'};
    $ns       = $FORM{'ns'};
    $ann      = $FORM{'ann'};
    $threadid = $FORM{'threadid'};
    if ( $threadid =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }
    $pollthread = $FORM{'pollthread'} || 0;
    $posttime   = $FORM{'post_entry_time'};
    $notify     = $FORM{'notify'};
    $hasnotify  = $FORM{'hasnotify'};
    $favorite   = $FORM{'favorite'};
    $thestatus  = $FORM{'topicstatus'};
    $thestatus =~ s/\, //gsm;
    chomp $thestatus;

    # Check if poster isn't using a distilled email domain
    email_domain_check($email);
    my $spamdetected = spamcheck("$name $subject $message");
    if ( !${ $uid . $FORM{$username} }{'spamcount'} ) {
        ${ $uid . $FORM{$username} }{'spamcount'} = 0;
    }
    $postspeed = $date - $posttime;
    if ( !$staff ) {
        if ( ( $speedpostdetection && $postspeed < $min_post_speed )
            || $spamdetected == 1 )
        {
            ${ $uid . $username }{'spamcount'}++;
            ${ $uid . $username }{'spamtime'} = $date;
            UserAccount( $username, 'update' );
            $spam_hits_left_count =
              $post_speed_count - ${ $uid . $username }{'spamcount'};
            if   ( $spamdetected == 1 ) { fatal_error('tsc_alert'); }
            else                        { fatal_error('speed_alert'); }
        }
    }

    # Permission checks for posting.
    if ( !$threadid ) {

        # Check for ability to post new threads
        if ( AccessCheck( $currentboard, 1 ) ne 'granted' && !$pollthread ) {
            fatal_error('no_perm_post');
        }
    }
    else {

        # Check for ability to reply to threads
        if ( AccessCheck( $currentboard, 2 ) ne 'granted' && !$pollthread ) {
            fatal_error('no_perm_reply');
        }
        $postthread = 2;
    }
    if ($pollthread) {

        # Check for ability to post polls
        if ( AccessCheck( $currentboard, 3 ) ne 'granted' ) {
            fatal_error('no_perm_poll');
        }
    }
    $allowattach ||= 0;
    if ( $allowattach > 0 ) {
        for my $y ( 1 .. $allowattach ) {
            if ( $CGI_query && $CGI_query->upload("file$y") ) {

            # Check once for ability to post attachments
                if ( AccessCheck( $currentboard, 4 ) ne 'granted' ) {
                    fatal_error('no_perm_att');
                }
                last;
            }
        }
    }

    # End Permission Checks

    ## clean name and email - remove | from name and turn any _ to spaces for mail
    if ( $name && $email ) {
        ToHTML($name);
        $email =~ s/\|//gxsm;
        ToHTML($email);
        $tempname = $name;
        $name =~ s/\_/ /gsm;
    }

    # Fixes a bug with posting hexed characters.
    $name =~ s/amp;//gxsm;

    spam_protection();

    $subject =~ s/[\r\n]//gxsm;
    my $testsub = $subject;
    $testsub =~ s/ |\&nbsp;//gsm;
    if ( $testsub eq q{} && $pollthread != 2 ) {
        fatal_error( 'useless_post', "$testsub" );
    }

    my $testmessage = regex_1($message);
    if ( $testmessage eq q{} && $message ne q{} && $pollthread != 2 ) {
        fatal_error( 'useless_post', "$testmessage" );
    }

    if ( !$minlinkpost ) { $minlinkpost = 0; }
    if ( ${ $uid . $username }{'postcount'} < $minlinkpost
        && !$staff )
    {
        if (   $message =~ m{http:\/\/}xsm
            || $message =~ m{https:\/\/}xsm
            || $message =~ m{ftp:\/\/}xsm
            || $message =~ m{www.}xsm
            || $message =~ m{ftp.}xsm =~ m{\[url}xsm
            || $message =~ m{\[link}xsm
            || $message =~ m{\[img}xsm
            || $message =~ m{\[ftp}xsm )
        {
            fatal_error('no_links_allowed');
        }
    }

    FromChars($subject);
    $convertstr = $subject;
    $convertcut = $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $subject = $convertstr;
    ToHTML($subject);
    $doadsubject = $subject;

    $message = regex_2($message);

    FromChars($message);
    ToHTML($message);
    $message = regex_3($message);
    CheckIcon();

    if ( -e ("$datadir/.txt") ) { unlink "$datadir/.txt"; }

    if ( !$iamguest ) {

        # If not guest, get name and email.
        $name  = ${ $uid . $username }{'realname'};
        $email = ${ $uid . $username }{'email'};

    }
    else {

        # If user is Guest, then make sure the chosen name and email
        # is not reserved or used by a member.
        if ( lc $name eq lc MemberIndex( 'check_exist', $name ) ) {
            fatal_error( 'guest_taken', "($name)" );
        }
        if ( lc $email eq lc MemberIndex( 'check_exist', $email ) ) {
            fatal_error( 'guest_taken', "($email)" );
        }
    }

    my @poll_data;
    if ($pollthread) {
        $maxpq          ||= 60;
        $maxpo          ||= 50;
        $maxpc          ||= 0;
        $numpolloptions ||= 8;

        my $numcount   = 0;
        my $testspaces = regex_1( $FORM{'question'} );
        if ( length($testspaces) == 0 && length( $FORM{'question'} ) > 0 ) {
            fatal_error( 'useless_post', "$testspaces" );
        }

        FromChars( $FORM{'question'} );
        $convertstr = $FORM{'question'};
        $convertcut = $maxpq;
        CountChars();
        $FORM{'question'} = $convertstr;

        ToHTML( $FORM{'question'} );

        $guest_vote   = $FORM{'guest_vote'}   || 0;
        $hide_results = $FORM{'hide_results'} || 0;
        $multi_choice = $FORM{'multi_choice'} || 0;
        $poll_comment = $FORM{'poll_comment'} || q{};
        $vote_limit   = $FORM{'vote_limit'}   || 0;
        $pie_legends  = $FORM{'pie_legends'}  || 0;
        $pie_radius   = $FORM{'pie_radius'}   || 100;
        $poll_end_days = $FORM{'poll_end_days'};
        $poll_end_min  = $FORM{'poll_end_min'};

        if ( $pie_radius =~ /\D/xsm ) { $pie_radius = 100; }
        if ( $pie_radius < 100 ) { $pie_radius = 100; }
        if ( $pie_radius > 200 ) { $pie_radius = 200; }

        FromChars($poll_comment);
        $convertstr = $poll_comment;
        $convertcut = $maxpc;
        CountChars();
        $poll_comment = $convertstr;

        ToHTML($poll_comment);
        $poll_comment =~ s/\n/<br \/>/gsm;
        $poll_comment =~ s/\r//gxsm;
        if ( !$poll_end_days || $poll_end_days =~ /\D/xsm ) {
            $poll_end_days = q{};
        }
        if ( !$poll_end_min || $poll_end_min =~ /\D/xsm ) {
            $poll_end_min = q{};
        }
        if ($poll_end_days) { $poll_end = $poll_end_days * 86400; }
        if ($poll_end_min) { $poll_end += $poll_end_min * 60; }
        if ($poll_end)     { $poll_end += $date; }

        push @poll_data,
qq~$FORM{'question'}|0|$username|$name|$email|$date|$guest_vote|$hide_results|$multi_choice|||$poll_comment|$vote_limit|$pie_radius|$pie_legends|$poll_end\n~;

        for my $i ( 1 .. $numpolloptions ) {
            if ( $FORM{"option$i"} ) {
                $FORM{"option$i"} =~ s/\&nbsp;/ /gsm;
                $testspaces = regex_1( $FORM{"option$i"} );
                if (   length($testspaces) == 0
                    && length( $FORM{"option$i"} ) > 0 )
                {
                    fatal_error( 'useless_post', "$testspaces" );
                }

                FromChars( $FORM{"option$i"} );
                $convertstr = $FORM{"option$i"};
                $convertcut = $maxpo;
                CountChars();
                $FORM{"option$i"} = $convertstr;

                ToHTML( $FORM{"option$i"} );

                $numcount++;
                $split[$i] = $FORM{"split$i"} || 0;
                push @poll_data,
                  qq~0|$FORM{"option$i"}|$FORM{"slicecol$i"}|$split[$i]\n~;
            }
        }
    }

    my ( $file, $fixfile, @filelist, %filesizekb );
    $allowattach ||= 0;
    if ( $allowattach > 0 ) {
        for my $y ( 1 .. $allowattach ) {
            if ($CGI_query) { $file = $CGI_query->upload("file$y"); }
            if ($file) {
                $fixfile = $file;
                $fixfile =~ s/.+\\([^\\]+)$|.+\/([^\/]+)$/$1/xsm;
                if ( $fixfile =~ /[^0-9A-Za-z\+\-\.:_]/xsm )
                {    # replace all inappropriate characters
                    # Transliteration
                my @ISO_8859_1 =
                  qw(A B V G D E JO ZH Z I J K L M N O P R S T U F H C CH SH SHH _ Y _ JE JU JA a b v g d e jo zh z i j k l m n o p r s t u f h c ch sh shh _ y _ je ju ja);
                my $x = 0;
                foreach (
                    qw(À Á Â Ã Ä Å ¨ Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å ¸ æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ ÿ)
                  )
                {
                    $fixfile =~ s/$_/$ISO_8859_1[$x]/igxsm;
                    $x++;
                }

              # END Transliteration. Thanks to "Velocity" for this contribution.
                $fixfile =~ s/[^0-9A-Za-z\+\-\.:_]/_/gxsm;
            }

            # replace . with _ in the filename except for the extension
            my $fixname = $fixfile;
            if ( $fixname =~ s/(.+)(\..+?)$/$1/xsm ) {
                $fixext = $2;
            }
            $spamdetected = spamcheck("$fixname");
            if ( !$staff ) {
                if ( $spamdetected == 1 ) {
                    ${ $uid . $username }{'spamcount'}++;
                    ${ $uid . $username }{'spamtime'} = $date;
                    UserAccount( $username, 'update' );
                    $spam_hits_left_count =
                      $post_speed_count - ${ $uid . $username }{'spamcount'};
                    foreach (@filelist) { unlink "$uploaddir/$_"; }
                    fatal_error('tsc_alert');
                }
            }
            if ( $use_guardian && $string_on ) {
                @bannedstrings = split /\|/xsm, $banned_strings;
                foreach (@bannedstrings) {
                    chomp $_;
                    if ( $fixname =~ m/$_/ism ) {
                        fatal_error( 'attach_name_blocked', "($_)" );
                    }
                }
            }
            $fixext  =~ s/\.(pl|pm|cgi|php)/._$1/ixsm;
            $fixname =~ s/\.(?!tar$)/_/gxsm;
            $fixfile = qq~$fixname$fixext~;

            if ( !$overwrite ) {
                $fixfile = check_existence( $uploaddir, $fixfile );
            }
            elsif ( $overwrite == 2 && -e "$uploaddir/$fixfile" ) {
                foreach (@filelist) { unlink "$uploaddir/$_"; }
                fatal_error('file_overwrite');
            }

            my $match = 0;
            if ( !$checkext ) { $match = 1; }
            else {
                foreach my $ext (@ext) {
                    if ( grep { /$ext$/ixsm } $fixfile ) {
                        $match = 1;
                        last;
                    }
                }
            }
            $allowattach ||= 0;
            if ($match) {
                if (
                    $allowattach == 0
                    || ( ( $allowguestattach != 0 && $username eq 'Guest' )
                        && $allowguestattach != 1 )
                  )
                {
                    foreach (@filelist) { unlink "$uploaddir/$_"; }
                    fatal_error('no_perm_att');
                }
            }
            else {
                foreach (@filelist) { unlink "$uploaddir/$_"; }
            }

            my ( $size, $buffer, $filesize, $file_buffer );
            while ( $size = read $file, $buffer, 512 ) {
                $filesize += $size;
                $file_buffer .= $buffer;
            }
            $limit ||= 0;
            if ( $limit > 0  && $filesize > ( 1024 * $limit ) ) {
                foreach (@filelist) { unlink "$uploaddir/$_"; }
            }
            $dirlimit ||= 0;
            if ($dirlimit > 0) {
                my $dirsize = dirsize($uploaddir);
                if ( $filesize > ( ( 1024 * $dirlimit ) - $dirsize ) ) {
                    foreach (@filelist) { unlink "$uploaddir/$_"; }
                 }
            }

 # create a new file on the server using the formatted ( new instance ) filename
            if ( fopen( NEWFILE, ">$uploaddir/$fixfile" ) ) {
                binmode NEWFILE;

                # needed for operating systems (OS) Windows, ignored by Linux
                print {NEWFILE} $file_buffer
                  or croak "$croak{'print'} NEWFILE";    # write new file on HD
                fclose(NEWFILE);
            }
            else
            { # return the server's error message if the new file could not be created
                foreach (@filelist) { unlink "$uploaddir/$_"; }
                fatal_error( 'file_not_open', "$uploaddir" );
            }

     # check if file has actually been uploaded, by checking the file has a size
            $filesizekb{$fixfile} = -s "$uploaddir/$fixfile";
            if ( !$filesizekb{$fixfile} ) {
                foreach (qw("@filelist" $fixfile)) {
                    unlink "$uploaddir/$_";
                }
                fatal_error( 'file_not_uploaded', $fixfile );
            }
            $filesizekb{$fixfile} = int( $filesizekb{$fixfile} / 1024 );

            if ( $fixfile =~ /\.(jpg|gif|png|jpeg)$/ism ) {
                my $okatt = 1;
                if ( $fixfile =~ /gif$/ism ) {
                    my $header;
                    fopen( ATTFILE, "$uploaddir/$fixfile" );
                    read ATTFILE, $header, 10;
                    my $giftest;
                    ( $giftest, undef, undef, undef, undef, undef ) =
                      unpack 'a3a3C4', $header;
                    fclose(ATTFILE);
                    if ( $giftest ne 'GIF' ) { $okatt = 0; }
                }
                fopen( ATTFILE, "$uploaddir/$fixfile" );
                while ( read ATTFILE, $buffer, 1024 ) {
                    if ( $buffer =~ /<(html|script|body)/igxsm ) {
                        $okatt = 0;
                        last;
                    }
                }
                fclose(ATTFILE);
                if ( !$okatt ) {   # delete the file as it contains illegal code
                    foreach (qw("@filelist" $fixfile)) {
                        unlink "$uploaddir/$_";
                    }
                    fatal_error( 'file_not_uploaded',
                        "$fixfile $fatxt{'20a'}" );
                }
            }
            push @filelist, $fixfile;
        }
    }
    }

    #Create the list of files
    $fixfile = join q{,}, @filelist;

    # If no thread specified, this is a new thread.
    # Find a valid random ID for it.
    if ( $threadid eq q{} ) {
        $newthreadid = getnewid();
    }
    else {
        $newthreadid = q{};
    }

    # set announcement flag according to status of current board
    if ($newthreadid) {
        $mreplies = 0;
        if ($staff) {
            $mstate =
              $currentboard eq $annboard ? "0a$thestatus" : "0$thestatus";
        }
        else { $mstate = '0'; }

        # This is a new thread. Save it.
        fopen( FILE, "<$boardsdir/$currentboard.txt", 1 )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        my @buffer = <FILE>;
        fclose(FILE);
         fopen( FILE, ">$boardsdir/$currentboard.txt", 1 )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        print {FILE}
qq~$newthreadid|$subject|$name|$email|$date|$mreplies|$username|$icon|$mstate\n~
          or croak "$croak{'print'} FILE";
        print {FILE} @buffer or croak "$croak{'print'} FILE";
        fclose(FILE);
        fopen( FILE, ">$datadir/$newthreadid.txt" )
          or fatal_error( 'cannot_open', "$datadir/$newthreadid.txt", 1 );
        print {FILE}
qq~$subject|$name|$email|$date|$username|$icon|0|$user_ip|$message|$ns|||$fixfile\n~
          or croak "$croak{'print'} FILE";
        fclose(FILE);

        if (@filelist) {
            fopen( AMP, ">>$vardir/attachments.txt" )
              or fatal_error( 'cannot_open', "$vardir/attachments.txt" );
            foreach my $fixfile (@filelist) {
                print {AMP}
qq~$newthreadid|$mreplies|$subject|$name|$currentboard|$filesizekb{$fixfile}|$date|$fixfile|0\n~
                  or croak "$croak{'print'} AMP";
            }
            fclose(AMP);
        }
        if ($pollthread) {    # Save Poll data for new thread
            if ( ( $iamadmin || $iamgmod ) && $FORM{'scpoll'} )
            {                 # Save ShowcasePoll
                fopen( SCFILE, ">$datadir/showcase.poll" );
                print {SCFILE} $newthreadid or croak "$croak{'print'} SCFILE";
                fclose(SCFILE);
            }

            fopen( POLL, ">$datadir/$newthreadid.poll" );
            print {POLL} @poll_data or croak "$croak{'print'} POLL";
            fclose(POLL);
        }
        ## write the ctb file for the new thread
        ${$newthreadid}{'board'}        = $currentboard;
        ${$newthreadid}{'replies'}      = 0;
        ${$newthreadid}{'views'}        = 0;
        ${$newthreadid}{'lastposter'}   = $iamguest ? "Guest-$name" : $username;
        ${$newthreadid}{'lastpostdate'} = $newthreadid;
        ${$newthreadid}{'threadstatus'} = $mstate;
        MessageTotals( 'update', $newthreadid );

        if ( ( $enable_notifications == 1 || $enable_notifications == 3 )
            && -e "$boardsdir/$currentboard.mail" )
        {
            ToChars($subject);
            $subject = Censor($subject);
            NewNotify( $newthreadid, $subject );
        }
    }
    else {

        # This is an existing thread.
        (
            $mnum,     $msub,      $mname, $memail, $mdate,
            $mreplies, $musername, $micon, $mstate
        ) = split /\|/xsm, $yyThreadLine;

        if ( $mstate =~ /l/ism ) {    # locked thread
            if ($bypass_lock_perm) {
                $icanbypass = checkUserLockBypass();
            }                         # only if bypass switched on
            if ( !$icanbypass ) { fatal_error('topic_locked'); }
        }
        if ($staff) {
            $mstate =
              $currentboard eq $annboard ? "0a$thestatus" : "0$thestatus";
        }    # Leave the status as is if the user isn't allowed to change it

        # Get the right timeformat for the .ctb file
        # First save the user time format
        my $timeformat = ${ $uid . $username }{'timeformat'};
        my $timeselect = ${ $uid . $username }{'timeselect'};

        # Override user settings
        ${ $uid . $username }{'timeformat'} =
          'SDT, DD MM YYYY HH:mm:ss zzz';    # The .ctb time format
        ${ $uid . $username }{'timeselect'} = 7;

        # Get the time for the .ctb
        my $newtime = timeformat( $date, 1, 'rfc' );

        # Now restore the user settings
        ${ $uid . $username }{'timeformat'} = $timeformat;
        ${ $uid . $username }{'timeselect'} = $timeselect;

# First load the current .ctb info but don't close the file before saving the changed data
# or you can get wrong .ctb files if two users save at the exact same moment.
# Therefore we can't use &MessageTotals("load", $threadid); here.
# File locking should be enabled in AdminCenter!
# Changes here on @tag must also be done in System.pm -> sub MessageTotals -> my @tag = ...
        my @tag =
          qw(board replies views lastposter lastpostdate threadstatus repliers);
        fopen( UPDATE_CTB, "+<$datadir/$threadid.ctb", 1 )
          or fatal_error( 'cannot_open', "$datadir/$threadid.ctb", 1 );
        while ( my $aa = <UPDATE_CTB> ) {
            if ( $aa =~ /^'(.*?)',"(.*?)"/xsm ) {
                ${$threadid}{$1} = $2;
            }
        }
        truncate UPDATE_CTB, 0;
        seek UPDATE_CTB, 0, 0;
        print {UPDATE_CTB}
          qq~### ThreadID: $threadid, LastModified: $newtime ###\n\n~
          or croak "$croak{'print'} UPDATE_CTB";

        # Check if thread has moved. And do necessary access check
        if ( ${$threadid}{'board'} ne $currentboard ) {
            if ( AccessCheck( ${$threadid}{'board'}, 2 ) ne 'granted' ) {
                foreach my $cnt ( 0 .. ( @tag - 1 ) ) {
                    print {UPDATE_CTB}
                      qq~'$tag[$cnt]',"${$threadid}{$tag[$cnt]}"\n~
                      or croak "$croak{'print'} UPDATE_CTB";
                }
                fclose(UPDATE_CTB);
                fatal_error('no_perm_reply');
            }

            # Thread has moved, but we can still post
            # the current board is now the new board.
            $currentboard = ${$threadid}{'board'};
        }

# update the ctb file for the existing thread with number of replies and lastposter
        ${$threadid}{'board'} = $currentboard;
        ${$threadid}{'replies'}++;
        ${$threadid}{'lastposter'}   = $iamguest ? "Guest-$name" : $username;
        ${$threadid}{'lastpostdate'} = $date;
        ${$threadid}{'threadstatus'} = $mstate;

        foreach my $cnt ( 0 .. ( @tag - 1 ) ) {
            print {UPDATE_CTB} qq~'$tag[$cnt]',"${$threadid}{$tag[$cnt]}"\n~
              or croak "$croak{'print'} UPDATE_CTB";
        }
        fclose(UPDATE_CTB);

        # end of .ctb file saving

        $mreplies = ${$threadid}{'replies'};

        if ($pollthread) {    # Save new Poll data
            if ( ( $iamadmin || $iamgmod ) && $FORM{'scpoll'} )
            {                 # Save ShowcasePoll
                fopen( SCFILE, ">$datadir/showcase.poll" );
                print {SCFILE} $threadid or croak "$croak{'print'} SCFILE";
                fclose(SCFILE);
            }
            fopen( POLL, ">$datadir/$threadid.poll" );
            print {POLL} @poll_data or croak "$croak{'print'} POLL";
            fclose(POLL);
        }

        fopen( BOARDFILE, "<$boardsdir/$currentboard.txt", 1 )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        my @buffer = <BOARDFILE>;
        fclose( BOARDFILE );

        foreach my $i ( 0 .. ( @buffer - 1 ) ) {
            if ( $buffer[$i] =~ m{\A$mnum\|}oxsm ) { $buffer[$i] = q{}; last; }
        }
        fopen( BOARDFILE, ">$boardsdir/$currentboard.txt", 1 )
          or fatal_error( 'cannot_open', "$boardsdir/$currentboard.txt", 1 );
        print {BOARDFILE}
qq~$mnum|$msub|$mname|$memail|$date|$mreplies|$musername|$micon|$mstate\n~
          or croak "$croak{'print'} BOARDFILE";
        print {BOARDFILE} @buffer or croak "$croak{'print'} BOARDFILE";
        fclose(BOARDFILE);

        fopen( THREADFILE, ">>$datadir/$threadid.txt" )
          or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
        print {THREADFILE}
qq~$subject|$name|$email|$date|$username|$icon|0|$user_ip|$message|$ns|||$fixfile\n~
          or croak "$croak{'print'} THREADFILE";
        fclose(THREADFILE);

        if (@filelist) {
            fopen( AMP, ">>$vardir/attachments.txt" )
              or fatal_error( 'cannot_open', "$vardir/attachments.txt" );
            foreach my $fixfile (@filelist) {
                print {AMP}
qq~$mnum|$mreplies|$subject|$name|$currentboard|$filesizekb{$fixfile}|$date|$fixfile|0\n~
                  or croak "$croak{'print'} AMP";
            }
            fclose(AMP);
        }

        ToChars($subject);
        $subject = Censor($subject);
        if ( $enable_notifications == 1 || $enable_notifications == 3 ) {
            ReplyNotify( $threadid, $subject, $mreplies );
        }
    }    # end else

    if ( !$iamguest ) {
        ${ $uid . $username }{'postlayout'} =
qq~$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}~;

        # Increment post count and lastpost date for the member.
        # Check whether zeropost board
        if ( !${ $uid . $currentboard }{'zero'} ) {
            ${ $uid . $username }{'postcount'}++;

            if ( ${ $uid . $username }{'position'} ) {
                $grp_after = qq~${$uid.$username}{'position'}~;
            }
            else {
                foreach my $postamount (
                    reverse sort { $a <=> $b }
                    keys %Post
                  )
                {
                    if ( ${ $uid . $username }{'postcount'} >= $postamount ) {
                        ( $title, undef ) =
                          split /\|/xsm, $Post{$postamount}, 2;
                        $grp_after = $title;
                        last;
                    }
                }
            }
            ManageMemberinfo( 'update', $username, q{}, q{}, $grp_after,
                ${ $uid . $username }{'postcount'} );
        }
        UserAccount( $username, 'update', 'lastpost+lastonline' );
    }

    # The thread ID, regardless of whether it's a new thread or not.
    $thread = $newthreadid || $threadid;

    # Let's figure out what page number to show
    $maxmessagedisplay ||= 10;
    $pageindex = int( $mreplies / $maxmessagedisplay );
    $start     = $pageindex * $maxmessagedisplay;

    ${ $uid . $currentboard }{'messagecount'}++;
    if ( !$FORM{'threadid'} ) {
        ${ $uid . $currentboard }{'threadcount'}++;
        ++$threadcount;
    }
    $myname = $iamguest ? qq~Guest-$name~ : $username;
    ${ $uid . $currentboard }{'lastposttime'}   = $date;
    ${ $uid . $currentboard }{'lastposter'}     = $myname;
    ${ $uid . $currentboard }{'lastpostid'}     = $thread;
    ${ $uid . $currentboard }{'lastreply'}      = $mreplies;
    ${ $uid . $currentboard }{'lastsubject'}    = $doadsubject;
    ${ $uid . $currentboard }{'lasttopicstate'} = $mstate;
    ${ $uid . $currentboard }{'lasticon'}       = $icon;
    BoardTotals( 'update', $currentboard );

    if ( !$iamguest ) { Recent_Write( 'incr', $thread, $username, $date ); }

    if ( $favorite && !$hasfavorite ) {
        require Sources::Favorites;
        AddFav( $thread, $mreplies, 1 );
    }

    if ( $notify && !$hasnotify ) {
        ManageThreadNotify( 'add', $thread, $username,
            ${ $uid . $username }{'language'},
            1, 1 );
    }
    elsif ( !$notify && $hasnotify == 1 ) {
        ManageThreadNotify( 'delete', $thread, $username );
    }

    my $rts = $FORM{'return_to'};
    if ( $rts == 3 ) {
        $yySetLocation = qq~$scripturl~;
        dumplog( $currentboard, $date );
        dumplog( $thread,       $date );
        if ( !$INFO{'num'} ) { MessageTotals( 'incview', $thread ); }
    }
    elsif ( $rts == 2 ) {
        $yySetLocation = qq~$scripturl?board=$currentboard~;
        dumplog( $thread, $date );
        if ( !$INFO{'num'} ) { MessageTotals( 'incview', $thread ); }
    }
    else {
        if ( $currentboard eq $annboard ) {
            $yySetLocation =
qq~$scripturl?virboard=$FORM{'virboard'};num=$thread/$start#$mreplies~;
        }
        else {
            $yySetLocation = qq~$scripturl?num=$thread/$start#$mreplies~;
        }
    }
    redirectexit();
    return;
}

# We load all the notification strings from a given language and store them in memory
sub LoadNotifyMessages {
    my $languages   = shift;
    my $currentlang = $language;
    ${$languages}{$currentlang} = 1;    # Load the current language too

    foreach my $lang ( keys %{$languages} ) {
        next
          if $notifystrings{$lang}
          {'boardnewtopicnotificationemail'};    # next if already loaded
        $language = $lang;
        LoadLanguage('Email');
        $notifystrings{$lang} = {
            'boardnewtopicnotificationemail' => $boardnewtopicnotificationemail,
            'boardnotificationemail'         => $boardnotificationemail,
            'topicnotificationemail'         => $topicnotificationemail,
        };
        LoadLanguage('Notify');
        $notifysubjects{$lang} = {
            '118' => $notify_txt{'118'},
            '136' => $notify_txt{'136'},
        };
        $notifycharset{$lang} = { 'emailcharset' => $emailcharset, };
    }
    $language = $currentlang;
    return;
}

sub NewNotify {
    my ( $thisthread, $thissubject ) = @_;

    my $thisauthor = ${ $uid . $username }{'realname'} || $maintxt{'28'};
    my $thismessage = $message;
    $thismessage =~ s/ &nbsp; &nbsp; &nbsp;/\t/g;
    $thismessage =~ s~\[b\](.*?)\[/b\]~*$1*~ig;
    $thismessage =~ s~\[i\](.*?)\[/i\]~/$1/~ig;
    $thismessage =~ s~\[u\](.*?)\[/u\]~_$1_~ig;
    $thismessage =~ s/\[.*?\]//g;
    $thismessage =~ s/<(br|p).*?>/\n/ig;
    $thismessage =~ s/<.*?>//g;
    FromHTML($thismessage);
    my $boardname;
    ( $boardname, undef ) = split /\|/xsm, $board{$currentboard}, 2;
    ToChars($boardname);

    $thissubject .= " ($boardname)";
    $thissubject =~ s/<.*?>//gxsm;
    FromHTML($thissubject);

    require Sources::Mailer;

    ManageMemberinfo('load');
    ManageBoardNotify( 'load', $currentboard );
    my %languages;
    foreach ( keys %theboard ) {
        $languages{ ( split /\|/xsm, $theboard{$_}, 2 )[0] } = 1;
    }
    LoadNotifyMessages( \%languages );

    while ( my ( $curuser, $value ) = each %theboard ) {
        my ( $curlang, undef ) = split /\|/xsm, $value, 2;
        if ( $curuser ne $username ) {
            LoadUser($curuser);
            if (   ${ $uid . $curuser }{'notify_me'} == 1
                || ${ $uid . $curuser }{'notify_me'} == 3 )
            {
                ( undef, $curmail, undef ) =
                  split /\|/xsm, $memberinf{$curuser}, 3;
                sendmail(
                    $curmail,
                    "$notifysubjects{$curlang}{'136'}: $thissubject",
                    template_email(
                        $notifystrings{$curlang}
                          {'boardnewtopicnotificationemail'},
                        { 'subject' => $thissubject, 'num' => $thisthread, 'tauthor' => $thisauthor, 'tmessage' => $thismessage }
                    ),
                    q{},
                    $notifycharset{$curlang}{'emailcharset'}
                );
            }
            undef %{ $uid . $curuser };
        }
    }
    undef %theboard;
    undef %memberinf;
    return;
}

sub ReplyNotify {
    my ( $thisthread, $thissubject, $tem ) = @_;
    my $page = qq{$tem#$tem};

    my $thisauthor = ${ $uid . $username }{'realname'} || $maintxt{'28'};
    my $thismessage = $message;
    $thismessage =~ s/ &nbsp; &nbsp; &nbsp;/\t/g;
    $thismessage =~ s~\[b\](.*?)\[/b\]~*$1*~ig;
    $thismessage =~ s~\[i\](.*?)\[/i\]~/$1/~ig;
    $thismessage =~ s~\[u\](.*?)\[/u\]~_$1_~ig;
    $thismessage =~ s/\[.*?\]//g;
    $thismessage =~ s/<(br|p).*?>/\n/ig;
    $thismessage =~ s/<.*?>//g;
    FromHTML($thismessage);
    my $boardname;
    ( $boardname, undef ) = split /\|/xsm, $board{$currentboard}, 2;
    ToChars($boardname);

    $thissubject .= " ($boardname)";
    $thissubject =~ s/<.*?>//gxsm;
    FromHTML($thissubject);

    require Sources::Mailer;

    my %mailsent;
    ManageMemberinfo('load');
    if ( -e "$boardsdir/$currentboard.mail" ) {
        ManageBoardNotify( 'load', $currentboard );
        my %languages;
        foreach ( keys %theboard ) {
            $languages{ ( split /\|/xsm, $theboard{$_}, 2 )[0] } = 1;
        }
        LoadNotifyMessages( \%languages );

        while ( my ( $curuser, $value ) = each %theboard ) {
            my ( $curlang, $notify_type, undef ) =
              split /\|/xsm, $value;
            if ( $curuser ne $username && $notify_type == 2 ) {
                LoadUser($curuser);
                if (   ${ $uid . $curuser }{'notify_me'} == 1
                    || ${ $uid . $curuser }{'notify_me'} == 3 )
                {
                    ( undef, $curmail, undef ) =
                      split /\|/xsm, $memberinf{$curuser}, 3;
                    sendmail(
                        $curmail,
                        "$notifysubjects{$curlang}{'136'}: $thissubject",
                        template_email(
                            $notifystrings{$curlang}{'boardnotificationemail'},
                            {
                                'subject' => $thissubject,
                                'num' => $thisthread,
                                'start' => $page,
                                'tauthor' => $thisauthor,
                                'tmessage' => $thismessage
                            }
                        ),
                        q{},
                        $notifycharset{$curlang}{'emailcharset'}
                    );
                    $mailsent{$curuser} = 1;
                }
                undef %{ $uid . $curuser };
            }
        }
        undef %theboard;
    }
    if ( -e "$datadir/$thisthread.mail" ) {
        ManageThreadNotify( 'load', $thisthread );
        my %languages;
        foreach ( keys %thethread ) {
            $languages{ ( split /\|/xsm, $thethread{$_}, 2 )[0] } = 1;
        }
        LoadNotifyMessages( \%languages );

        while ( my ( $curuser, $value ) = each %thethread ) {
            my ( $curlang, $notify_type, $hasviewed ) =
              split /\|/xsm, $value;
            if (   $curuser ne $username
                && !exists $mailsent{$curuser}
                && $hasviewed )
            {
                LoadUser($curuser);
                if (   ${ $uid . $curuser }{'notify_me'} == 1
                    || ${ $uid . $curuser }{'notify_me'} == 3 )
                {
                    ( undef, $curmail, undef ) =
                      split /\|/xsm, $memberinf{$curuser}, 3;
                    sendmail(
                        $curmail,
                        "$notifysubjects{$curlang}{'118'}: $thissubject",
                        template_email(
                            $notifystrings{$curlang}{'topicnotificationemail'},
                            {
                                'subject' => $thissubject,
                                'num' => $thisthread,
                                'start' => $page,
                                'tauthor' => $thisauthor,
                                'tmessage' => $thismessage
                            }
                        ),
                        q{},
                        $notifycharset{$curlang}{'emailcharset'}
                    );
                    $thethread{$curuser} = qq~$curlang|$notify_type|0~;
                }
                undef %{ $uid . $curuser };
            }
        }
        ManageThreadNotify( 'save', $thisthread );
    }
    undef %memberinf;
    return;
}

sub doshowthread {
    my ( $line, $tempname, $tempdate );
    if ( $INFO{'start'} ) { $INFO{'start'} = "/$INFO{'start'}"; }

    if ( !ref( $thread_arrayref{$threadid} ) && $threadid ) {
        fopen( THREADFILE, "$datadir/$threadid.txt" )
          or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
        @{ $thread_arrayref{$threadid} } = <THREADFILE>;
        fclose(THREADFILE);
    }
    my @messages = @{ $thread_arrayref{$threadid} };

    if (@messages) {
        if ( @messages < $cutamount ) { $cutamount = @messages; }
        $showall = $post_cutts{'3'};

        if ( @messages => $cutamount && $showpageall ) {
            $showall .=
qq~ $post_cutts{'3a'} <a href="$scripturl?action=post;num=$threadid;title=PostReply$INFO{'start'};showall=yes" class="under">$post_cutts{'4'}</a> $post_cutts{'5'} ~;
        }

        if ( $INFO{'showall'} ne q{} || $cutamount eq 'all' ) {
            $origcutamount = $cutamount;
            $cutamount     = $pidtxt{'01'};
            $showall =
qq~$post_cutts{'3'} $post_cutts{'3a'} <a href="$scripturl?action=post;num=$threadid;title=PostReply/$INFO{'start'}" class="under"> $post_cutts{'4'}</a> $post_cutts{'6'} ~;
        }
        $my_showmess_disnum = qq~
            <b>$post_txt{'468'} - $post_cutts{'2'} $cutamount $showall</b>~;
        if ( $tsreverse == 1 ) { @messages = reverse @messages; }
        if ( $INFO{'showall'} ne q{} || $cutamount eq 'all' ) {
            $cutamount = 1000;
        }
        foreach my $amounter ( 0 .. ( $cutamount - 1 ) ) {
            (
                undef, $temprname, undef, $tempdate, $tempname,
                undef, undef,      undef, $message,  $ns
            ) = split /\|/xsm, $messages[$amounter];
            $messagedate = $tempdate;
            $tempdate    = timeformat($tempdate);
            $parseflash  = 0;

            if ( $tempname ne 'Guest'
                && -e ("$memberdir/$tempname.vars") )
            {
                LoadUser($tempname);
            }
            if ( ${ $uid . $tempname }{'regtime'} ) {
                $registrationdate = ${ $uid . $tempname }{'regtime'};
            }
            else {
                $registrationdate = int time;
            }
            if ( ${ $uid . $tempname }{'regdate'}
                && ( $messagedate > $registrationdate || $tempname eq 'admin' ) )
            {
                if ( $iamguest) {
                    $displaynamelink = qq~$format_unbold{$tempname}~;
                }
                else {
                    $displaynamelink =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tempname}">$format_unbold{$tempname}</a>~;
                }
            }
            elsif ($tempname !~ m{Guest}sm
                && $messagedate < $registrationdate )
            {
                $displaynamelink = qq~$tempname - $display_txt{'470a'}~;
            }
            else {
                $displaynamelink = $temprname;
            }

            my $quickmessage = $message;
            $quickmessage =~ s/<(br|p).*?>/\\r\\n/igsm;
            $quickmessage =~ s/'/\\'/gxsm;
            my $quote_mname = $useraccount{$tempname};
            $quote_mname =~ s/'/\\'/gxsm;
            my $quote_msg_id =
              $tsreverse == 1
              ? ( @messages - $amounter - 1 )
              : $amounter;

            wrap();
            ( $message, undef ) = Split_Splice_Move( $message, $threadid );
            if ($enable_ubbc) {
                enable_yabbc();
                $displayname = ${ $uid . $tempname }{'realname'};
                DoUBBC();
            }
            wrap2();
            ToChars($message);
            $message = Censor($message);

            if ( $message ne q{} ) {
                $my_enable_markquote =
                  ( $enable_markquote && $enable_quickreply )
                  ? qq~&nbsp;&nbsp;<a href="javascript:void(quoteSelection('$quote_mname',$threadid,$quote_msg_id,$messagedate,''))">$img{'mquote'}</a>~
                  : q{};
                $my_enable_quickjump =
                  ( $enable_quickjump
                      && length($quickmessage) <= $quick_quotelength )
                  ? qq~$menusep<a href="javascript:void(quoteSelection('$quote_mname',$threadid,$quote_msg_id,$messagedate,'$quickmessage'))">$img{'quote'}</a>~
                  : q{};

                $my_showmess_mess .= $mypost_showmessages_a;
                $my_showmess_mess =~
                  s/{yabb displaynamelink}/$displaynamelink/sm;
                $my_showmess_mess =~
                  s/{yabb my_enable_markquote}/$my_enable_markquote/sm;
                $my_showmess_mess =~
                  s/{yabb my_enable_quickjump}/$my_enable_quickjump/sm;
                $my_showmess_mess =~ s/{yabb tempdate}/$tempdate/sm;
                $my_showmess_mess =~ s/{yabb quote_msg_id}/$quote_msg_id/sm;
                $my_showmess_mess =~ s/{yabb message}/$message/sm;

            }
        }
        $my_showmess = $mypost_showmessages;
        $my_showmess =~ s/{yabb my_showmess_disnum}/$my_showmess_disnum/sm;
        $my_showmess =~ s/{yabb my_showmess_mess}/$my_showmess_mess/sm;
    }
    else {
        $my_showmess .= '<!--no summary-->';
    }
    $yymain .= $my_showmess;
    return;
}

## Guest can send a PM to Admin
## this is a hybrid broadcast message, with fixed audience of Admin
## and some guest posting elements in, where id/email are required.
sub sendGuestPM {
    if ( !$iamguest ) { $yySetLocation = $scripturl; redirectexit(); }
    if ( !$PMenableGuestButton )  { fatal_error('no_access'); }
    if ( $PMenableBm_level == 0 ) { fatal_error('no_access'); }

    $INFO{'title'} = 'PostReply';
    $postthread = 2;

    $guestpost_fields = $mypost_guest_fields;
    $guestpost_fields =~ s/{yabb name}/$FORM{'name'}/sm;
    $guestpost_fields =~ s/{yabb email}/$FORM{'email'}/sm;

    if ($gpvalid_en) {
        validation_code();
        $verification_field =
            $verification eq q{}
          ? $mypost_guest_c
          : q{};
        $verification_field =~ s/{yabb showcheck}/$showcheck/sm;
        $verification_field =~ s/{yabb flood_text}/$flood_text/sm;

    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$post_txt{'verification_question_case'}~;
        }
        $verification_question_field =
            $verification_question eq q{}
          ? $mypost_veri_c
          : q{};
        $verification_question_field =~
          s/{yabb spam_question}/$spam_question/gsm;
        $verification_question_field =~
          s/{yabb verification_question_desc}/$verification_question_desc/gsm;
        $verification_question_field =~
          s/{yabb spam_question_id}/$spam_question_id/gsm;
        $verification_question_field =~ s/{yabb spam_question_image}/$spam_image/gsm;
    }
    $sub        = q{};
    $settofield = 'subject';
    $t_title     = $post_txt{'sendmessguest'};
    $submittxt   = $post_txt{'148'};
    $destination = 'guestpm2';
    $icon        = 'alert';
    $post        = 'guestpm';
    $prevmain    = q{};
    $yytitle     = $post_txt{'sendmessguest'};
    Postpage();
    template();
    return;
}

sub sendGuestPM2 {
    if ( !$iamguest ) { $yySetLocation = $scripturl; redirectexit(); }
    if ( !$PMenableGuestButton )  { fatal_error('no_access'); }
    if ( $PMenableBm_level == 0 ) { fatal_error('no_access'); }
    if ($gpvalid_en) {
        validation_check( $FORM{'verification'} );
    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    }

    # Poster is a Guest then evaluate the legality of name and email
    $FORM{'name'} =~ s/\A\s+//xsm;
    $FORM{'name'} =~ s/\s+\Z//xsm;

    # Get the form values
    $name     = $FORM{'name'};
    $email    = $FORM{'email'};
    $subject  = $FORM{'subject'};
    $message  = $FORM{'message'};
    $ns       = $FORM{'ns'};
    $threadid = $FORM{'threadid'};
    $posttime = $FORM{'post_entry_time'};
    if ( $threadid =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }

    # Check if poster isn't using a distilled email domain
    email_domain_check($email);
    my $spamdetected = spamcheck("$name $subject $message");
    ${ $uid . $username }{'spamcount'} = 0;
    $postspeed = $date - $posttime;
    if ( ( $speedpostdetection && $postspeed < $min_post_speed )
        || $spamdetected == 1 )
    {
        ${ $uid . $username }{'spamcount'}++;
        $spam_hits_left_count =
          $post_speed_count - ${ $uid . $username }{'spamcount'};
        if   ( $spamdetected == 1 ) { fatal_error('tsc_alert'); }
        else                        { fatal_error('speed_alert'); }
    }

    ## clean name and email - remove | from email and turn any _ to spaces in name
    if ( $name && $email ) {
        ToHTML($name);
        $tempname = $name;
        $name  =~ s/\_/ /gsm;
        $email =~ s/\|//gxsm;
        ToHTML($email);
    }

    # Fixes a bug with posting hexed characters.
    $name =~ s/amp;//gxsm;

    # Check Message Length Precisely
    my $mess_len = $message;
    $mess_len =~ s/[\r\n ]//igsm;
    $mess_len =~ s/&#\d{3,}?\;/X/igxsm;

    undef $mess_len;

    spam_protection();

    my $testsub = $subject;
    $testsub =~ s/[\r\n\ ]|\&nbsp;//gsm;
    if ( $testsub eq q{} ) { fatal_error( 'useless_post', $testsub ); }

    my $testmessage = regex_1($message);
    if ( $testmessage eq q{} && $message ne q{} ) {
        fatal_error( 'useless_post', $testmessage );
    }

    $subject =~ s/[\r\n]//gxsm;
    FromChars($subject);
    $convertstr = $subject;
    $convertcut = $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $subject = $convertstr;
    ToHTML($subject);
    $message = regex_2($message);

    FromChars($message);
    ToHTML($message);
    $message = regex_3($message);
    CheckIcon();

    if ( -e ("$datadir/.txt") ) { unlink "$datadir/.txt"; }

# User is Guest, then make sure the chosen name and email is not reserved or used by a member
    if ( lc $name eq lc MemberIndex( 'check_exist', $name ) ) {
        fatal_error( 'guest_taken', "($name)" );
    }
    if ( lc $email eq lc MemberIndex( 'check_exist', $email ) ) {
        fatal_error( 'guest_taken', "($email)" );
    }

    # Find a valid random ID for it
    $newthreadid = getnewid();

    # Encode spaces in name, to avoid confusing bm
    $name =~ s/ /%20/gsm;
    $mreplies = 0;

    # set announcement flag according to status of current board
    if ( -e "$memberdir/broadcast.messages" ) {
        fopen( INBOX, "$memberdir/broadcast.messages" );
        @bmessages = <INBOX>;
        fclose(INBOX);
    }
    fopen( INBOX, ">$memberdir/broadcast.messages" );

    # new format:  #messageid|from user|touser(s)|(ccuser(s))|(bccuser(s))|
    #    subject|date|message|(parentmid)|(reply#)|ip|
    #           messagestatus|flags|storefolder|attachment
    print {INBOX}
"$newthreadid|$name $email|admin|||$subject|$date|$message|$newthreadid|0|$ENV{'REMOTE_ADDR'}|g|||\n"
      or croak "$croak{'print'} INBOX";
    print {INBOX} @bmessages or croak "$croak{'print'} INBOX";
    fclose(INBOX);
    undef @bmessages;

    # The thread ID, regardless of whether it's a new thread or not
    $thread = $newthreadid || $threadid;
    $yySetLocation = $scripturl;
    redirectexit();
    return;
}

sub modAlert {
    if ( $iamguest && !$PMAlertButtonGuests ) {
        fatal_error('not_logged_in');
    }
    if ( !$iamguest && !$PMenableAlertButton ) {
        fatal_error('no_access');
    }
    if ( $currentboard eq q{} && !$iamguest ) {
        fatal_error('no_access');
    }
    if ( !$PM_level ) { fatal_error('no_access'); }

    my $quotemsg = $INFO{'quote'};
    $postid   = $INFO{'quote'};
    $threadid = $INFO{'num'};
    my (
        $mnum,     $msub,      $mname, $memail, $mdate,
        $mreplies, $musername, $micon, $mstate
    ) = split /\|/xsm, $yyThreadLine;

    # Determine category
    $curcat = ${ $uid . $currentboard }{'cat'};
    BoardTotals( 'load', $currentboard );

    # Figure out the name of the category
    get_forum_master();
    ( $cat, $catperms ) = split /\|/xsm, $catinfo{$curcat};
    ToChars($cat);

    $INFO{'title'} =~ tr/+/ /;
    $postthread = 2;

    $guestpost_fields = q{};
    if ( $iamguest ) {
    $guestpost_fields = $mypost_guest_fields;
    $guestpost_fields =~ s/{yabb name}/$FORM{'name'}/sm;
    $guestpost_fields =~ s/{yabb email}/$FORM{'email'}/sm;
    }

    if ( $iamguest && $gpvalid_en ) {
        validation_code();
        $verification_field =
            $verification eq q{}
          ? $mypost_guest_c
          : q{};
        $verification_field =~ s/{yabb showcheck}/$showcheck/sm;
        $verification_field =~ s/{yabb flood_text}/$flood_text/sm;
    }

    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestion();
        my $verification_question_desc;
        if ($spam_questions_case) {
            $verification_question_desc =
              qq~<br />$post_txt{'verification_question_case'}~;
        }
        $verification_question_field =
            $verification_question eq q{}
          ? $mypost_veri_c
          : q{};
        $verification_question_field =~
          s/{yabb spam_question}/$spam_question/gsm;
        $verification_question_field =~
          s/{yabb verification_question_desc}/$verification_question_desc/gsm;
        $verification_question_field =~
          s/{yabb spam_question_id}/$spam_question_id/gsm;
        $verification_question_field =~ s/{yabb spam_question_image}/$spam_image/gsm;
    }

    $sub        = q{};
    $settofield = 'subject';
    if ( $threadid ne q{} ) {
        if ( !ref $thread_arrayref{$threadid} ) {
            fopen( FILE, "$datadir/$threadid.txt" )
              or fatal_error( 'cannot_open', "$datadir/$threadid.txt", 1 );
            @{ $thread_arrayref{$threadid} } = <FILE>;
            fclose(FILE);
        }
        if ( $quotemsg ne q{} ) {
            (
                $msubject, $mname,   $memail, $mdate,    $musername,
                $micon,    $mattach, $mip,    $mmessage, $mns
            ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[$quotemsg];
            $message = $mmessage;
            $message =~ s/<br.*?>/\n/igsm;
            $message =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/igsm;
            if ( !$nestedquotes ) {
                $message =~
s/\n{0,1}\[quote([^\]]*)\](.*?)\[\/quote([^\]]*)\]\n{0,1}/\n/isgxm;
            }
            $mname = isempty( $mname, isempty( $musername, $post_txt{'470'} ) );
            my $hidename = $musername;
            if ( $musername eq 'Guest' ) { $hidename = $mname; }
            if ($do_scramble_id) { $hidename = cloak($hidename); }
            my $maxlengthofquote =
              $MaxMessLen -
              length(
qq~[quote author=$hidename link=$threadid/$quotemsg#$quotemsg date=$mdate\]\[/quote\]\n~
              ) - 3;
            if ( length $message >= $maxlengthofquote ) {
                require Sources::System;
                LoadLanguage('Error');
                alertbox( $error_txt{'quote_too_long'} );
                $message = substr( $message, 0, $maxlengthofquote ) . q{...};
            }
            $message =
qq~[quote author=$hidename link=$threadid/$quotemsg#$quotemsg date=$mdate\]$message\[/quote\]\n~;
            $msubject =~ s/\bre:\s+//igxsm;
            if ( $mns eq 'NS' ) { $nscheck = 'checked'; }
        }
        else {
            (
                $msubject, $mname,   $memail, $mdate,    $musername,
                $micon,    $mattach, $mip,    $mmessage, $mns
            ) = split /\|/xsm, ${ $thread_arrayref{$threadid} }[0];
            $msubject =~ s/\bre:\s+//igxsm;
        }
        $sub        = "Re: $msubject";
        $settofield = 'message';
    }

    $t_title     = $post_txt{'alertmod'};
    $submittxt   = $post_txt{'148'};
    $destination = 'modalert2';
    $icon        = 'alert';
    $post        = 'modalert';
    $prevmain    = q{};
    $yytitle     = $post_txt{'alertmod'};
    Postpage();
    template();
    return;
}

sub modAlert2 {
    if ( $iamguest && !$PMAlertButtonGuests ) {
        fatal_error('not_logged_in');
    }
    if ( !$iamguest && !$PMenableAlertButton ) {
        fatal_error('no_access');
    }
    if ( !$PM_level ) { fatal_error('no_access'); }
    if ( $iamguest && $gpvalid_en ) {
        validation_check( $FORM{'verification'} );
    }
    if (   $iamguest
        && $spam_questions_gp
        && -e "$langdir/$language/spam.questions" )
    {
        SpamQuestionCheck( $FORM{'verification_question'},
            $FORM{'verification_question_id'} );
    }

    # Get the form values
    $name     = $FORM{'name'};
    $gname    = $FORM{'name'};
    $email    = $FORM{'email'};
    $subject  = $FORM{'subject'};
    $message  = $FORM{'message'};
    $ns       = $FORM{'ns'};
    $threadid = $FORM{'threadid'};
    $postid   = $FORM{'postid'};
    $posttime = $FORM{'post_entry_time'};
    if ( $threadid =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }

    if ($iamguest) {
        $name =~ s/\A\s+//xsm;
        $name =~ s/\s+\Z//xsm;
        ## clean name and email - remove | from name and turn any _ to spaces for email
        ToHTML($name);
        $tempname = $name;
        $name  =~ s/_/ /gsm;
        $email =~ s/\|//gxsm;
        ToHTML($email);

        # Fixes a bug with posting hexed characters
        $name =~ s/amp;//gxsm;

# If user is Guest, then make sure the chosen name and email is not reserved or used by a member
        if ( lc $name eq lc MemberIndex( 'check_exist', $name ) ) {
            fatal_error( 'guest_taken', "($name)" );
        }
        if ( lc $email eq lc MemberIndex( 'check_exist', $email ) ) {
            fatal_error( 'guest_taken', "($email)" );
        }

        # Encode spaces in name, to avoid confusing!
        $name =~ s/ /%20/gsm;
        $name .= qq~ $email~;
    }
    else {
        $name = $username;
    }

    # Check if poster isn't using a distilled email domain
    email_domain_check($email);
    my $spamdetected = spamcheck("$name $subject $message");
    if ( !${ $uid . $FORM{$username} }{'spamcount'} ) {
        ${ $uid . $FORM{$username} }{'spamcount'} = 0;
    }
    $postspeed = $date - $posttime;
    if ( !$staff ) {
        if ( ( $speedpostdetection && $postspeed < $min_post_speed )
            || $spamdetected == 1 )
        {
            ${ $uid . $username }{'spamcount'}++;
            ${ $uid . $username }{'spamtime'} = $date;
            UserAccount( $username, 'update' );
            $spam_hits_left_count =
              $post_speed_count - ${ $uid . $username }{'spamcount'};
            if   ( $spamdetected == 1 ) { fatal_error('tsc_alert'); }
            else                        { fatal_error('speed_alert'); }
        }
    }

    spam_protection();

    $subject =~ s/[\r\n]//gxsm;
    my $tstsubject = $subject;
    my $testsub    = $subject;
    $testsub =~ s/ |\&nbsp;//gsm;
    if ( $testsub eq q{} ) { fatal_error( 'useless_post', $testsub ); }

    my $testmessage = regex_1($message);
    if ( $testmessage eq q{} && $message ne q{} ) {
        fatal_error( 'useless_post', $testmessage );
    }

    FromChars($subject);
    $convertstr = $subject;
    $convertcut = $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 );

    CountChars();
    $subject = $convertstr;
    ToHTML($subject);
    $message = regex_2($message);

    FromChars($message);
    ToHTML($message);
    $message = regex_3($message);

    if ( -e ("$datadir/.txt") ) { unlink "$datadir/.txt"; }

    # Find a valid random ID for it
    $newthreadid = getnewid();

    my $x;
    my $mods    = ${ $uid . $currentboard }{'mods'};
    my $modgrps = ${ $uid . $currentboard }{'modgroups'};
    $modgrps =~ s/, /,/gsm;

# because modgroups are saved with ' ' and this MyCenter.pm does not understand ;-)
# If no BM is allowed and no mods is assigned => send the "AlertMod" to admin
    if ( !$PMenableBm_level && !$mods ) {
        $mods = $mods ? $mods : 'admin';

# If BM is allowed and no mods and no moderator group is assigned => send the "AlertMod" to admin and gmods via BM
    }
    elsif ( $PMenableBm_level && !$mods && !$modgrps ) {
        $modgrps = $PMenableBm_level == 3 ? 'admins' : 'admins,gmods,fmods';
    }

    # Check if there is at least one user in the moderator group
    # if not and no mod is assigned too => send the "AlertMod" to admin via PM
    if ( $PMenableBm_level && $modgrps ) {
        if ( $modgrps =~ /admins|gmods|fmods|mods/xsm ) { $x = 1; }
        else {
            if ( !%memberinf ) { ManageMemberinfo('load'); }
          MANAGEINFO: foreach ( keys %memberinf ) {
                for ( split /,/xsm, ( split /\|/xsm, $memberinf{$_} )[4] ) {
                    if ( $_ && $modgrps =~ /\b$_\b/xsm ) {
                        $x = 1;
                        last MANAGEINFO;
                    }
                }
            }
            if ( !$x && !$mods ) { $mods = 'admin'; }
        }
    }
    if ($mods) {
      MANAGEMODS: foreach my $toBoardMod ( split /, ?/sm, $mods ) {
            chomp $toBoardMod;

# Send notification (Will only work if Admin has allowed the Email Notification)
            LoadUser($toBoardMod);
            if (   ${ $uid . $toBoardMod }{'notify_me'} > 1
                && $enable_notifications > 1
                && ${ $uid . $toBoardMod }{'email'} ne q{} )
            {
                require Sources::Mailer;
                $language = ${ $uid . $toBoardMod }{'language'};
                LoadLanguage('Email');
                LoadLanguage('Notify');
                LoadLanguage('InstantMessage');
                my $msubject = $tstsubject ? $tstsubject : $inmes_txt{'767'};
                ToChars($msubject);
                my $chmessage = $message;
                ToChars($chmessage);
                $chmessage = regex_4($chmessage);
                $chmessage = template_email(
                    $privatemessagenotificationemail,
                    {
                        'date'    => timeformat($date),
                        'subject' => $msubject,
                        'sender'  => ${ $uid . $username }{'realname'},
                        'message' => $chmessage
                    }
                );
                if ($iamguest) { $fromname = $gname; }
                else { $fromname = ${ $uid . $username }{'realname'}; }
                sendmail(
                    ${ $uid . $toBoardMod }{'email'},
                    qq~$notify_txt{'145'} $fromname ($msubject)~,
                    $chmessage, q{}, $emailcharset
                );
            }
            elsif ( $PMenableBm_level && $x ) {
                if ( !%memberinf ) { ManageMemberinfo('load'); }
                for ( split /,/xsm,
                    ( split /\|/xsm, $memberinf{$toBoardMod} )[4] )
                {
                    if ( $_ && $modgrps =~ /\b$_\b/xsm ) { next MANAGEMODS; }
                }
            }
            if   ($iamguest) { $mstatus = q~ga~; }
            else             { $mstatus = q~a~; }

            # Send message to user
            fopen( INBOX, "$memberdir/$toBoardMod.msg" );
            my @inmessages = <INBOX>;
            fclose(INBOX);
            fopen( INBOX, ">$memberdir/$toBoardMod.msg" );
            print {INBOX}
"$newthreadid|$name|$toBoardMod|||$subject|$date|$message|$newthreadid|0|$user_ip|$mstatus|u||\n"
              or croak "$croak{'print'} INBOX";
            print {INBOX} @inmessages or croak "$croak{'print'} INBOX";
            fclose(INBOX);
            require Sources::MyCenter;
            updateIMS( $toBoardMod, $newthreadid, 'messagein' );
        }
    }

    if ( $PMenableBm_level && $x ) {
        # set announcement flag according to status of current board
            if   ($iamguest) { $mstatus = q~ga~; }
            else             { $mstatus = q~ab~; }
        #if sender is guest and Alert is going to ModGroup
        fopen( INBOX, "$memberdir/broadcast.messages" )
          or fatal_error( 'cannot_open', "$memberdir/broadcast.messages" );
        my @inmessages = <INBOX>;
        fclose(INBOX);
        fopen( INBOX, ">$memberdir/broadcast.messages" );
        print {INBOX}
"$newthreadid|$name|$modgrps|||$subject|$date|$message|$newthreadid|0|$ENV{'REMOTE_ADDR'}|$mstatus|||\n"
          or croak "$croak{'print'} INBOX";
        print {INBOX} @inmessages or croak "$croak{'print'} INBOX";
        fclose(INBOX);
    }

    $yySetLocation = qq~$scripturl?num=$threadid/$postid#$postid~;
    redirectexit();
    return;
}

1;
