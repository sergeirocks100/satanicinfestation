###############################################################################
# InstantMessage.pm                                                           #
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
#use warnings;
#no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$instantmessagepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
require Sources::PostBox;
require Sources::SpamCheck;
LoadLanguage('FA');
LoadLanguage('Post');

get_micon();
get_template('MyMessage');

$set_subjectMaxLength ||= 50;

if (   ( $action eq 'imsend' || $action eq 'imsend2' )
    && $MaxIMMessLen
    && $AdMaxIMMessLen )
{
    $MaxMessLen   = $MaxIMMessLen;
    $AdMaxMessLen = $AdMaxIMMessLen;
}

if ( $iamadmin || $iamgmod ) { $MaxMessLen = $AdMaxMessLen; }

## create the send IM section of the screen

sub buildIMsend {
    LoadLanguage('InstantMessage');
    LoadCensorList();

    if ( $FORM{'previewim'} ) {
        require Sources::Post;
        Preview($error);
    }
    $mctitle = $inmes_txt{'775'};
    if ($sendBMess) { $mctitle = $inmes_txt{'775a'}; }
    ## check for a draft being opened
    if ( $INFO{'caller'} == 4 && $INFO{'id'} ) {
        if ( !-e "$memberdir/$username.imdraft" ) {
            fatal_error( 'cannot_open', "$username.imdraft" );
        }
        fopen( DRAFT, "$memberdir/$username.imdraft" );
        my @draftPM = <DRAFT>;
        fclose(DRAFT);
        chomp @draftPM;
        my $flagfound;
        foreach my $draftMess (@draftPM) {
            my ( $checkId, undef ) = split /\|/xsm, $draftMess, 2;
            if ( $checkId eq $INFO{'id'} ) {
                (
                    $dmessageid,    $dmusername,   $userto,
                    $usernamecc,    $usernamebcc,  $subject,
                    $dmdate,        $message,      $dmpmessageid,
                    $dmreplyno,     $dmips,        $dmessageStatus,
                    $dmessageFlags, $dstoreFolder, $dmessageAttachment
                ) = split /\|/xsm, $draftMess;
                $flagfound = 1;
                last;
            }
        }
        if ( !$flagfound ) { fatal_error('cannot_find_draftmess'); }
        FromHTML($message);
        FromHTML($subject);
    }

    my $pmicon = 'standard';
    if ( $FORM{'status'} || $INFO{'status'} ) {
        $thestatus = $FORM{'status'} || $INFO{'status'};
    }
    elsif ($dmessageStatus) { $thestatus = $dmessageStatus; }
    else                    { $thestatus = 's'; }

    my @ststs    = qw( s u c );
    my @ststt    = qw( sb ub cb );
    my @s_select = ();

    foreach my $i ( 0 .. 2 ) {
        if ( $thestatus eq $ststs[$i] ) {
            $s_select[$i] = q~ selected="selected"~;
        }
    }

    foreach my $i ( 0 .. 2 ) {
        if ( $thestatus eq $ststt[$i] ) {
            $s_select[$i] = q~ selected="selected"~;
            $sendBMess = 1;
        }
    }
    if (
        $sendBMess != 1
        || (
               ( $PMenableBm_level != 1 || ( !$staff ) )
            && ( $PMenableBm_level != 2 || ( !$iamadmin && !$iamgmod ) )
            && ( $PMenableBm_level != 4
                || ( !$iamadmin && !$iamgmod && !$iamfmod ) )
            && ( $PMenableBm_level != 3 || !$iamadmin )
        )
      )
    {
        $sendBMess = 0;
    }

    ##########   post code   #########
    if (   !$iamadmin
        && !$iamgmod
        && !$staff
        && ${ $uid . $username }{'postcount'} < $numposts )
    {
        fatal_error('im_low_postcount');
    }

    if ( !$replyguest ) {
        if ($is_preview) { $post_txt{'507'} = $post_txt{'771'}; }
        $normalquot = $post_txt{'599'};
        $simpelquot = $post_txt{'601'};
        $simpelcode = $post_txt{'602'};
        $edittext   = $post_txt{'603'};
        if ( !$fontsizemax ) { $fontsizemax = 72; }
        if ( !$fontsizemin ) { $fontsizemin = 6; }

        # this defines what the top area of the post box will look like:
        ## if this is a reply , load the 'from' name off the message
        if ( $INFO{'reply'} || $INFO{'quote'} ) { $INFO{'to'} = $mfrom; }
        if ( !$INFO{'to'} && $FORM{'to'} ne q{} ) { $INFO{'to'} = $FORM{'to'}; }

        ## if cloaking is enabled, and 'to' is not a blank
        if ( $do_scramble_id && $INFO{'to'} ne q{} ) {
            decloak( $INFO{'to'} );
        }

        if ( !$sendBMess ) { LoadUser( $INFO{'to'} ); }
    }

    $message =~ s/<br.*?>/\n/igsm;
    $message =~ s/&nbsp;/ /gsm;
    ToChars($message);
    $message = Censor($message);
    ToHTML($message);
    $message =~ s/ &nbsp; &nbsp; &nbsp;/\t/igsm;

    if ($msubject) { $subject = $msubject; }
    ToChars($subject);
    $subject = Censor($subject);
    ToHTML($subject);

    if ( $action eq 'modify' || $action eq 'modify2' ) {
        $displayname = qq~$mename~;
    }
    else {
        $displayname = ${ $uid . $username }{'realname'};
    }
    require Sources::ContextHelp;
    ContextScript('post');

    $MCGlobalFormStart .= qq~
    $ctmain
    <script type="text/javascript">
    var displayNames = new Object();
    $template_names
    </script>
    ~;
    $my_gimsend  = q{};
    $my_tosend_a = q{};
    if ( !$replyguest ) {
        if ($prevmain) {
            $my_gimsend = $myIM_prevmain;
            $my_gimsend =~ s/{yabb prevmain}/$prevmain/sm;
        }
        $my_gimsend .= $myIM_liveprev;
    }
    else {
        $my_gimsend = $myIM_replyguest;
        $my_gimsend =~ s/{yabb guest_reply}/$guest_reply{'guesttext'}/sm;
    }

    if ( !$replyguest && !$sendBMess && ( $PMenable_cc || $PMenable_bcc ) ) {
        $yyjavascripttoform = q~
            <script type="text/javascript">
            function changeRecepientTab(tabto) {
                document.getElementById('usersto').style.display = 'none';
                document.getElementById('bnttoto').className = 'windowbg  bnttoto';
        ~;

        $my_tosend_a =
qq~<div id="bnttoto" class="windowbg2 bnttoto"><a href="javascript:void(0);" onclick="changeRecepientTab('to'); return false;">$inmes_txt{'324'}:</a></div>
        ~;

        if ($PMenable_cc) {
            $yyjavascripttoform .= q~
                document.getElementById('userscc').style.display = 'none';
                document.getElementById('bnttocc').className = 'windowbg  bnttoto';
            ~;
            $my_tosend_a .= qq~
                    <div id="bnttocc" class="windowbg bnttoto"><a href="javascript:void(0);" onclick="changeRecepientTab('cc'); return false;">$inmes_txt{'325'}:</a></div>
            ~;
        }
        if ($PMenable_bcc) {
            $yyjavascripttoform .= q~
                document.getElementById('usersbcc').style.display = 'none';
                document.getElementById('bnttobcc').className = 'windowbg bnttoto';
            ~;
            $my_tosend_a .= qq~
                    <div id="bnttobcc" class="windowbg bnttoto"><a href="javascript:void(0);" onclick="changeRecepientTab('bcc'); return false;">$inmes_txt{'326'}:</a></div>
            ~;
        }
        $yyjavascripttoform .= q~
                document.getElementById('users' + tabto).style.display = 'inline';
                document.getElementById('bntto' + tabto).className = 'windowbg2 bnttoto';
            }
        </script>
        ~;
        $my_send = $my_tosend;
        $my_send =~ s/{yabb yyjavascripttoform}/$yyjavascripttoform/sm;
        $my_send =~ s/{yabb my_tosend_a}/$my_tosend_a/sm;
    }

    # now uses a multi-line select
    ProcIMrecs();

    $toname = $INFO{'forward'} ? q{} : $INFO{'to'};

    my $toUsersTitle = $inmes_txt{'torecepients'};

    if ( !$replyguest ) {
        $onchangeText = q~ onkeyup="autoPreview();"~;

        if ($sendBMess) { $toUsersTitle = $inmes_txt{'togroups'}; }
        if ( $PMenable_cc || $PMenable_bcc ) {
            $us_winhight = $us_winhight_cc;
        }
        else {
            $us_winhight = $us_winhight_to;
        }

        my $toIdtext = $sendBMess ? 'groups' : 'toshow';

        $imWinop = qq~
        <script type="text/javascript">
        function imWin() {
            window.open('$scripturl?action=imlist;sort=recentpm;toid=$toIdtext','imWin','status=no,height=$us_winhight,width=$us_winwidth_to,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
        }
        function imWinCC() {
            window.open('$scripturl?action=imlist;sort=recentpm;toid=toshowcc','imWin','status=no,height=$us_winhight,width=$us_winwidth_cc,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
        }
        function imWinBCC() {
            window.open('$scripturl?action=imlist;sort=recentpm;toid=toshowbcc','imWin','status=no,height=$us_winhight,width=$us_winwidth_cc,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
        }
        function removeUser(oElement) {
            var indexToRemove = oElement.options.selectedIndex;
            if (confirm("$post_txt{'768'}")) { oElement.remove(indexToRemove); }
        }
        </script>
        <div id="usersto" class="usersto">
        <b>$inmes_txt{'324'} $toUsersTitle:</b>&nbsp;<a href="javascript: void(0);" onclick="imWin();" tabindex="1"><span class="small">$inmes_txt{'clickto1'} <i>$inmes_txt{'324'}</i> $toUsersTitle $inmes_txt{'clickto2'}</span></a><br />
        <select name="toshow" id="toshow" multiple="multiple" size="6" class="width_100" ondblclick="removeUser(this);">\n~;

        if ( !$sendBMess ) {
            if ($toname) {
                LoadUser($toname);
                if ( ${ $uid . $toname }{'realname'} ) {
                    $imWinop .=
qq~<option selected="selected" value="$useraccount{$toname}">${$uid.$toname}{'realname'}</option>\n~;
                }
            }
            if ( $FORM{'toshow'} ) {
                foreach my $touser ( split /,/xsm, $FORM{'toshow'} ) {
                    LoadUser($touser);
                    $imWinop .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                }
            }
            if ($userto) {
                foreach my $touser ( split /,/xsm, $userto ) {
                    LoadUser($touser);
                    $imWinop .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                }
            }
        }
        else {
            $FORM{'toshow'} = $mto || $FORM{'toshow'};
            if ( $FORM{'toshow'} ) {
                foreach my $touser ( split /,/xsm, $FORM{'toshow'} ) {
                    if ( $touser eq 'all' ) {
                        $imWinop .=
qq~<option selected="selected" value="all">$inmes_txt{'bmallmembers'}</option>\n~;
                    }
                    elsif ( $touser eq 'admins' ) {
                        $imWinop .=
qq~<option selected="selected" value="admins">$inmes_txt{'bmadmins'}</option>\n~;
                    }
                    elsif ( $touser eq 'gmods' ) {
                        $imWinop .=
qq~<option selected="selected" value="gmods">$inmes_txt{'bmgmods'}</option>\n~;
                    }
                    elsif ( $touser eq 'fmods' ) {
                        $imWinop .=
qq~<option selected="selected" value="fmods">$inmes_txt{'bmfmods'}</option>\n~;
                    }
                    elsif ( $touser eq 'mods' ) {
                        $imWinop .=
qq~<option selected="selected" value="mods">$inmes_txt{'bmmods'}</option>\n~;
                    }
                    else {
                        foreach ( keys %NoPost ) {
                            my ( $title, undef ) =
                              split /\|/xsm, $NoPost{$_}, 2;
                            if ( $touser eq $_ ) {
                                $imWinop .=
qq~<option selected="selected" value="$_">$title</option>\n~;
                            }
                        }
                    }
                }
            }
        }

        $imWinop .=
q~            </select><input type="hidden" name="immulti" value="yes" />
            </div>
        ~;

        $JSandInput = q~
        <script type="text/javascript">
        // this function forces all users listed on IM mult to be selected for processing
        function selectNames() {
            var oList = document.getElementById('toshow');
            for (var i = 0; i < oList.options.length; i++) { oList.options[i].selected = true; }
        ~;

        if ( !$sendBMess ) {
            if ($PMenable_cc) {
                $JSandInput .= q~
                    oList = document.getElementById('toshowcc');
                    for ( i = 0; i < oList.options.length; i++){ oList.options[i].selected = true; }
                ~;
                $imsend_cc .= qq~
                <div id="userscc" class="usersto">
                <b>$inmes_txt{'325'} $toUsersTitle:</b>&nbsp;<a href="javascript: void(0);" onclick="imWinCC();"><span class="small">$inmes_txt{'clickto1'} <i>$inmes_txt{'325'}</i> $toUsersTitle $inmes_txt{'clickto2'}</span></a><br />
                <select name="toshowcc" id="toshowcc" multiple="multiple" size="6" class="width_100" ondblclick="removeUser(this);">\n~;
                if ( $FORM{'toshowcc'} ) {
                    foreach my $touser ( split /\,/xsm, $FORM{'toshowcc'} ) {
                        LoadUser($touser);
                        $imsend_cc .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                    }
                }
                if ($usernamecc) {
                    foreach my $touser ( split /\,/xsm, $usernamecc ) {
                        LoadUser($touser);
                        $imsend_cc .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                    }
                }
                $imsend_cc .= q~               </select>
                </div>
                ~;
            }

            if ($PMenable_bcc) {
                $JSandInput .= q~
                    oList = document.getElementById('toshowbcc');
                    for ( i = 0; i < oList.options.length; i++) { oList.options[i].selected = true; }
                ~;
                $imsend_cc .= qq~
                <div id="usersbcc" class="usersto">
                <b>$inmes_txt{'326'} $toUsersTitle:</b>&nbsp;<a href="javascript: void(0);" onclick="imWinBCC();"><span class="small">$inmes_txt{'clickto1'} <i>$inmes_txt{'326'}</i> $toUsersTitle $inmes_txt{'clickto2'}</span></a><br />
                <select name="toshowbcc" id="toshowbcc" multiple="multiple" size="6" class="width_100" ondblclick="removeUser(this);">\n~;
                if ( $FORM{'toshowbcc'} ) {
                    foreach my $touser ( split /\,/xsm, $FORM{'toshowbcc'} ) {
                        LoadUser($touser);
                        $imsend_cc .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                    }
                }
                if ($usernamebcc) {
                    foreach my $touser ( split /\,/xsm, $usernamebcc ) {
                        LoadUser($touser);
                        $imsend_cc .=
qq~<option selected="selected" value="$useraccount{$touser}">${$uid.$touser}{'realname'}</option>\n~;
                    }
                }
                $imsend_cc .= q~               </select>
                </div>
                ~;
            }
        }

        $JSandInput .= q~
            }
        </script>
        ~;

        my $iconopts = q{};
        for my $i ( sort keys %pmiconlist ) {
            my ( $img, $alt ) = split /[|]/xsm, $pmiconlist{$i};
            if ( $icon eq $img ) { $myic = ' selected="selected" '; }
            $iconopts .=
qq~                            <option value="$img"$myic>$alt</option>\n~;
        }
        $imsend_send = $my_imsend_IM;
        $imsend_send =~ s/{yabb my_send}/$my_send/sm;
        $imsend_send =~ s/{yabb my_gimsend}/$my_gimsend/sm;
        $imsend_send =~ s/{yabb imWinop}/$imWinop/sm;
        $imsend_send =~ s/{yabb imsend_cc}/$imsend_cc/sm;
        $imsend_send =~ s/{yabb onchange_text2}/$onchange_text2/sm;
        $imsend_send =~ s/{yabb iconopts}/$iconopts/sm;
        $imsend_send =~ s/{yabb pmicon}/$pmicon/gsm;
        $imsend_send =~ s/{yabb pmicon_img}/$micon_bg{$pmicon}/gsm;
    }
    else {
        $imsend_send = $my_imsend_Guest;
        $imsend_send =~ s/{yabb my_gimsend}/$my_gimsend/sm;
        $imsend_send =~ s/{yabb my_send}/$my_send/sm;
        $imsend_send =~ s/{yabb toUsersTitle}/$toUsersTitle/sm;
        $imsend_send =~ s/{yabb guestName}/$guestName/gsm;
        $imsend_send =~ s/{yabb guestEmail}/$guestEmail/sm;
    }

    $subtitle = "<i>$subject</i>";

    #this is the end of the upper area of the post page.

    # this declares the beginning of the UBBC section
    $JSandInput .= qq~
    <script type="text/javascript">
    function Hash() {
        this.length = 0;
        this.items = new Array();
        for (var i = 0; i < arguments.length; i += 2) {
            if (typeof(arguments[i + 1]) != 'undefined') {
                this.items[arguments[i]] = arguments[i + 1];
                this.length++;
            }
        }

        this.getItem = function(in_key) {
            return this.items[in_key];
        };
    }

    function showimage() {
        $jsIM
        var icon_set = document.getElementById("status").options[document.getElementById("status").selectedIndex].value;
        var icon_show = jsIM.getItem(icon_set);
        document.images.status.src = icon_show;
    }
    </script>
    ~;

    $JSandInput .= qq~
    <input type="hidden" name="threadid" id="threadid" value="$threadid" />
    <input type="hidden" name="postid" id="postid" value="$postid" />
    <input type="hidden" name="info" id="info" value="$INFO{'id'}$FORM{'info'}" />
    <input type="hidden" name="mename" id="mename" value="$mename" />
    <input type="hidden" name="post_entry_time" id="post_entry_time" value="$date" />
    ~;

    if ( $FORM{'draftid'} || $INFO{'caller'} == 4 ) {
        $JSandInput .=
          q~<input type="hidden" name="draftid" id="draftid" value="~
          . ( $FORM{'draftid'} || $INFO{'id'} ) . q~" />~;
    }

    $my_max = ( $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 ) );

    # this is for the ubbc buttons
    if ( !$replyguest ) {
        if ( $enable_ubbc && $showyabbcbutt ) {
            $my_ubbc_yes .= qq~<b>$post_txt{'252'}:</b><br />~;

            # ubbc set separated out into PostBox.pm DAR 11/13/2012 #
            $my_ubbc_yes .= postbox();
        }
    }

    if ($replyguest) {
        $tmpmtext = qq~<b>$post_txt{'72'}:</b> ~;
    }

    $postbox2 = postbox2();
    $postbox3 = postbox3();

    if ( !$replyguest ) {
        $imsend_notguest = $my_postbox_notguest;

        $moresmilieslist   = q{};
        $more_smilie_array = q{};
        $i                 = 0;
        if ( $showadded == 1 ) {
            while ( $SmilieURL[$i] ) {
                if ( $SmilieURL[$i] =~ /\//ism ) { $tmpurl = $SmilieURL[$i]; }
                else { $tmpurl = qq~$imagesdir/$SmilieURL[$i]~; }
                $moresmilieslist .=
qq~             <img src="$tmpurl" alt="$SmilieDescription[$i]" onclick="javascript: MoreSmilies($i);" class="bottom cursor" />$SmilieLinebreak[$i]\n~;
                $tmpcode = $SmilieCode[$i];
                $tmpcode =~ s/\&quot;/"+'"'+"/gsm;

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
qq~             <img src="$yyhtml_root/Smilies/$line" alt="$name" onclick="javascript: MoreSmilies($i);" class="cursor bottom" />$SmilieLinebreak[$i]\n~;
                        $more_smilie_array .= qq~" [smiley=$line]", ~;
                        $i++;
                    }
                }
            }
        }

        $more_smilie_array .= q~""~;
        if ( $smiliestyle == 1 ) {
            $smiliewinlink = qq~$scripturl?action=smilieput~;
        }
        else { $smiliewinlink = qq~$scripturl?action=smilieindex~; }

        $im_smilies .= $imsend_notguest . qq~
                moresmiliecode = new Array($more_smilie_array);
                function MoreSmilies(i) {
                    AddTxt=moresmiliecode[i];
                    AddText(AddTxt);
                }
                    function smiliewin() {
        window.open("$smiliewinlink", 'list', 'width=$winwidth, height=$winheight, scrollbars=yes');
    }
    </script>~;
        $im_smilies .= smilies_list();
        $im_smilies .= qq~
        <span class="small"><a href="javascript: smiliewin();">$post_smiltxt{'17'}</a></span>\n~;

        # SpellChecker start
        if ($enable_spell_check) {
            $yyinlinestyle .= googiea();
            $userdefaultlang = ( split /-/xsm, $abbr_lang )[0];
            $userdefaultlang ||= 'en';
            $im_smilies .= googie($userdefaultlang);
        }

        # SpellChecker end

        $im_smilies .= $my_postbox_smilie;
    }

    # PM File Attachments Browse Box Code
    $allowAttachIM ||= 0;
    $pmFileLimit   ||= 0;
    $allowGroups = GroupPerms( $allowAttachIM, $pmAttachGroups );
    my ( $pmFileTypeInfo, $pmFileSizeInfo, $pmFileExtensions, @files,
        @fileUsers );
    if ( !$replyguest && $allowAttachIM && $allowGroups && -d "$pmuploaddir" ) {
        $pmFileExtensions = join q{ }, @pmAttachExt;
        $pmFileTypeInfo =
          $pmCheckExt == 1
          ? qq~$fatxt{'2'} $pmFileExtensions~
          : qq~$fatxt{'2'} $fatxt{'4'}~;
        $pmFileSizeInfo =
          $pmFileLimit != 0
          ? qq~$fatxt{'3'} $pmFileLimit KB~
          : qq~$fatxt{'3'} $fatxt{'5'}~;
        $FORM{'oldattach'} = decloak( $FORM{'oldattach'} );
        $mattach = $mattach || $FORM{'oldattach'};
        chomp $mattach;
        foreach my $senderFile ( split /,/xsm, $mattach ) {
            chomp $senderFile;
            my ( $forwardFileName, $forwardFileUser ) =
              split /~/xsm, $senderFile;
            push @files,     $forwardFileName;
            push @fileUsers, $forwardFileUser;
        }
        $cloakAttach = cloak($mattach);
        $my_show_FA .= $my_FA_show;
        $my_show_FA =~ s/{yabb cloakAttach}/$cloakAttach/sm;

        if ( $allowAttachIM > 1 ) {
            $my_allow_FA = qq~
            <img src="$imagesdir/$newload{'brd_exp'}" id="attform_add" alt="$fatxt{'80a'}" title="$fatxt{'80a'}" class="cursor" onclick="enabPrev2(1);" />
            <img src="$imagesdir/$newload{'brd_col'}" id="attform_sub" alt="$fatxt{'80s'}" title="$fatxt{'80s'}" class="cursor" style="visibility:hidden;" onclick="enabPrev2(-1);" />~;
        }
        $my_imFA = $my_FA_attach;
        $my_imFA =~ s/{yabb my_show_FA}/$my_show_FA/sm;
        $my_imFA =~ s/{yabb pmFileTypeInfo}/$pmFileTypeInfo/sm;
        $my_imFA =~ s/{yabb pmFileSizeInfo}/$pmFileSizeInfo/sm;
        $my_imFA =~ s/{yabb my_allow_FA}/$my_allow_FA/sm;

        my $startcount;
        if ( $allowAttachIM > 0 ) {
            for my $y ( 1 .. $allowAttachIM ) {
                if (
                    (
                        (
                               $action eq 'imsend2'
                            || $INFO{'forward'}
                            || $FORM{'draftid'}
                            || $INFO{'caller'} == 4
                        )
                        && !$FORM{'reply'}
                    )
                    && $files[ $y - 1 ] ne q{}
                    && -e "$pmuploaddir/$files[$y-1]"
                  )
                {
                    if ( $FORM{'draftid'} || $INFO{'caller'} == 4 ) {
                        $fatxt{'6d'} = $fatxt{'6f'};
                        $fatxt{'6e'} = $fatxt{'6c'};
                    }
                    $startcount++;
                    $pmAttachUser = cloak( $fileUsers[ $y - 1 ] );
                    $my_att_FA .= qq~
            <div id="attform_a_$y" class="att_lft~
                      . ( $y > 1 ? q~_b~ : q{} )
                      . qq~"><b>$fatxt{'6'} $y:</b></div>
            <div id="attform_b_$y" class="att_rgt~
                      . ( $y > 1 ? q~_b~ : q{} ) . qq~">
                <input type="file" name="file$y" id="file$y" size="50" onchange="selectNewattach($y);" /> <span class="cursor small bold" title="$fatxt{'81'}" onclick="document.getElementById('file$y').value='';">X</span><br />
                        <span style="font-size:x-small">
                <input type="hidden" id="w_filename$y" name="w_filename$y" value="$files[$y-1]" />
                <input type="hidden" name="w_fileuser$y" value="$pmAttachUser" />
                <select id="w_file$y" name="w_file$y" size="1">
                <option value="attachold" selected="selected">$fatxt{'6d'}</option>
                <option value="attachdel">$fatxt{'6e'}</option>
                <option value="attachnew">$fatxt{'6b'}</option>
                </select>&nbsp;$fatxt{'40'}: <a href="$pmuploadurl/$files[$y-1]" target="_blank">$files[$y-1]</a>
                        </span>~;
                }
                else {
                    $my_att_FA .= qq~
            <div id="attform_a_$y" class="att_lft"~
                      . ( $y > 1
                        ? q~ style="visibility:hidden; height:0px"~
                        : q{} )
                      . qq~><b>$fatxt{'6'} $y:</b></div>
            <div id="attform_b_$y" class="att_rgt"~
                      . ( $y > 1
                        ? q~ style="visibility:hidden; height:0px"~
                        : q{} )
                      . qq~>\n             <input type="file" name="file$y" id="file$y" size="50" /> <span class="cursor small bold" title="$fatxt{'81'}" onclick="document.getElementById('file$y').value='';">X</span>~;
                }
                $my_att_FA .= qq~\n            </div>\n~;
            }
            if ( !$startcount ) { $startcount = 1; }

            if ( $allowAttachIM > 1 ) {
                $my_att_FA .= qq~
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
                if ($allowAttachIM <= countattach) {
                    document.getElementById("attform_add").style.visibility = "hidden";
                } else {
                    document.getElementById("attform_add").style.visibility = "visible";
                }
            }
            </script>~;
            }
            $my_imFA .= $my_FA_att;
            $my_imFA =~ s/{yabb my_att_FA}/$my_att_FA/sm;
        }
    }

    # /PM File Attachments Browse Box Code

    if ( $INFO{'quote'} || $INFO{'reply'} || $FORM{'reply'} )
    {    # if this is a reply, need to pass the reply # forward
        $my_isreply = qq~
            <input type="hidden" name="reply" id="reply" value="$INFO{'quote'}$INFO{'reply'}$FORM{'reply'}" />~;
    }

    if ( !$replyguest ) {
        $my_isreply .= qq~
            <input type="checkbox" name="ns" id="ns" value="NS"$nscheck onchange="autoPreview();" /> <label for="ns"><span class="small">$post_txt{'277'}</span></label><br />~;
        if ( $FORM{'draftid'} || $INFO{'caller'} == 4 ) {
            $my_isreply .= qq~
            <input type="checkbox" name="draftleave" id="draftleave" value="1" /> <span class="small"> $post_txt{'draftleave'}</span><br />~;
        }
        my $sentboxAttachInfo;
        if ( $allowAttachIM && $allowGroups ) {
            $sentboxAttachInfo = qq~<br />$inmes_txt{'321'}~;
        }
        $my_isreply .= q~
            <input type="checkbox" name="dontstoreinoutbox" id="dontstoreinoutbox" value="1"~
          . ( $FORM{'dontstoreinoutbox'} ? ' checked="checked"' : q{} )
          . qq~ /> <label for="dontstoreinoutbox"><span class="small">$inmes_txt{'320'}$sentboxAttachInfo</span></label><br />~;
    }

    #these are the buttons to submit
    my $sendBMessFlag;
    if ( $sendBMess || $isBMess ) {
        $sendBMessFlag =
          q~<input type="hidden" name="isBMess" id="isBMess" value="yes" />~;
    }

    if ($speedpostdetection) {
        $my_spdpost = q~
            <script type="text/javascript">~;
        $my_spdpost .= speedpost();
        $my_spdpost .= q~</script>~;
    }

    if ( !$replyguest ) {
        $my_draft =
qq~&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="submit" name="$draft" id="$draft" value="$inmes_txt{'savedraft'}" accesskey="d" tabindex="7" class="button" />~;
    }

    $smilie_url_array  = q{};
    $smilie_code_array = q{};
    $i                 = 0;
    if ( $showadded == 2 ) {
        while ( $SmilieURL[$i] ) {
            if ( $SmilieURL[$i] =~ /\//ism ) { $tmpurl = $SmilieURL[$i]; }
            else { $tmpurl = qq~$defaultimagesdir/$SmilieURL[$i]~; }
            $smilie_url_array .= qq~"$tmpurl", ~;
            $tmpcode = $SmilieCode[$i];
            $tmpcode =~ s/\&quot;/"+'"'+"/gsm;    # "'
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
                    $smilie_url_array  .= qq~"$yyhtml_root/Smilies/$line", ~;
                    $smilie_code_array .= qq~" [smiley=$line]", ~;
                    $i++;
                }
            }
        }
    }

    $my_browser =
      qq~<script src="$yyhtml_root/ajax.js" type="text/javascript"></script>
        <script type="text/javascript">
~;

    if ( !$replyguest ) {
        $my_ajxcall = 'ajximmessage';
        $my_savetable .= my_liveprev();
        $my_savetable .= qq~
            $jsIM
            function showtpstatus() {
            var theimg = '$pmicon';
            var objIconSelected = document.getElementById("status").selectedIndex != -1 ? document.getElementById("status").options[document.getElementById("status").selectedIndex].value : 's';
            if (objIconSelected == 's') { theimg = 'standard'; }
            if (objIconSelected == 'c') { theimg = 'confidential'; }
            if (objIconSelected == 'u') { theimg = 'urgent'; }
            var picon_show = jsIM.getItem(theimg);
            document.images.icons.src = picon_show;
            document.getElementById("iconholder").value = theimg;
            if (autoprev === true) autoPreview();
        }~;
        $my_savetable .= q~        showtpstatus();
~;
    }

    if ( $action eq 'modify' || $action eq 'modify2' ) {
        $displayname = $mename;
    }
    else {
        $displayname = ${ $uid . $username }{'realname'};
    }

    get_template('Display');

    foreach (@months) { $jsmonths .= qq~'$_',~; }
    $jsmonths =~ s/\,\Z//xsm;
    $jstimeselected = ${ $uid . $username }{'timeselect'} || $timeselected;

    $imsend .= $imsend_send;
    $imsend .= $my_imsend_jsin;
    $imsend .= $my_ubbc_yes;
    $imsend .= $my_postbox;
    $imsend .= $im_smilies;
    $imsend .= $my_imFA;
    $imsend .= $my_FA_browse;
    $imsend =~ s/{yabb JSandInput}/$JSandInput/sm;
    $imsend =~ s/{yabb my_max}/$my_max/sm;
    $imsend =~ s/{yabb subject}/$subject/sm;
    $imsend =~ s/{yabb onchangeText}/$onchangeText/sm;
    $imsend =~ s/{yabb postbox2}/$postbox2/sm;
    $imsend =~ s/{yabb postbox3}/$postbox3/sm;
    $imsend =~ s/{yabb my_ispreview}/$my_ispreview/sm;
    $imsend =~ s/{yabb my_isreply}/$my_isreply/sm;
    $imsend =~ s/{yabb post}/$post/sm;
    $imsend =~ s/{yabb hidestatus}/$hidestatus/sm;
    $imsend =~ s/{yabb submittxt}/$submittxt/sm;
    $imsend =~ s/{yabb sendBMessFlag}/$sendBMessFlag/sm;
    $imsend =~ s/{yabb my_spdpost}/$my_spdpost/sm;
    $imsend =~ s/{yabb my_draft}/$my_draft/sm;
    $imsend =~ s/{yabb my_browser}/$my_browser/sm;
    $imsend =~ s/{yabb my_savetable}/$my_savetable/sm;
    $imsend =~ s/{yabb my_chars}/$my_chars/sm;
    ##########  end post code
    return $imsend;
}

##  process and send the IM to whomever
sub IMsendMessage {

    LoadLanguage('InstantMessage');
    LoadLanguage('Error');

    ##  sorry - no guests
    if ($iamguest) { fatal_error('im_members_only'); }

    my (
        @ignore,  $igname,   $messageid,  $subject,
        $message, $ignored,  $memnums,    $file,
        $fixfile, @filelist, %filesizekb, $pmAttachUrl
    );
    $isBMess = $FORM{'isBMess'};

    # set size of messagebox and text
    ${ $uid . $username }{'postlayout'} =
qq~$FORM{'messageheight'}|$FORM{'messagewidth'}|$FORM{'txtsize'}|$FORM{'col_row'}~;

# receipts for IM are now handled by "toshow" only, so we need to switch to the right
# test for no recipient. also switch on flag to stop us going back to the form all the time
# if there is only the one (intended) recipient, 'to' must contain the name
    if ( ( !$FORM{'toshow'} && !$INFO{'to'} ) && !$FORM{'draft'} ) {
        $error = $error_txt{'no_recipient'};
    }
    $toshow = $FORM{'toshow'} || $INFO{'to'};

    # if there are several intended - can be one of course ;)

    $subject = $FORM{'subject'};
    $subject =~ s/^\s+|\s+$//gsm;

    $message = $FORM{'message'};
    $message =~ s/^\s+|\s+$//g;

    #above regex cannot use /s or /m flags. IT WILL BREAK!

    # no subject/no message are bad!
    if ( !$subject ) { $error = $error_txt{'no_subject'}; }
    if ( !$message ) { $error = $error_txt{'no_message'}; }

    FromChars($subject);
    FromChars($message);

    ToHTML($subject);
    ToHTML($message);

    # manage line returns and tabs
    $subject =~ s/\s+/ /gsm;
    $message =~ s/\n/<br \/>/gsm;
    $message =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;

    # Check Length
    $convertstr = $subject;
    $convertcut = $set_subjectMaxLength + ( $subject =~ /^Re: /sm ? 4 : 0 );
    CountChars();
    $subject = $convertstr;

    $convertstr = $message;
    $convertcut = $MaxMessLen;
    CountChars();
    if ($cliped) {
        $error =
            "$inmes_txt{'536'} "
          . ( length($message) - length $convertstr )
          . " $inmes_txt{'537'}";
    }
    $message = $convertstr;

    if ( $FORM{'ns'} eq 'NS' ) { $message .= '#nosmileys'; }

    if ($error) {
        $IM_box = $inmes_txt{'148'};
        $FORM{'previewim'} = 1;
        IMPost();
        buildIMsend();
        return;
    }

    undef @multiple;
    fopen( MEMLIST, "$memberdir/memberlist.txt" );
    my @memberlist = <MEMLIST>;
    my $allmems    = @memberlist;
    fclose(MEMLIST);

    ProcIMrecs();

    $memnums = $#multiple + 1;
    ## no need to check for spam if its a broadcast, as this only creates the one post
    if ( $imspam eq 'off' ) { $imspam = 0; }
    $imspam ||= 0;
    if ( $imspam > 0 && !$isBMess ) {
        $checkspam = 100 / $allmems * $memnums;
        if ( $memnums == 1 ) { $checkspam = 0; }
        if ( $checkspam > $imspam && !$iamadmin ) {
            fatal_error('im_spam_alert');
        }
    }

    # Create unique Message ID
    $messageid = getnewid();
    $allowAttachIM ||= 0;
    $allowGroups = GroupPerms( $allowAttachIM, $pmAttachGroups );
    if ( $allowAttachIM && $allowGroups ) {
        for my $y ( 1 .. $allowAttachIM ) {
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
                        $spam_hits_left_count = $post_speed_count -
                          ${ $uid . $username }{'spamcount'};
                        foreach (@filelist) { unlink "$pmuploaddir/$_"; }
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
                $fixext =~ s/\.(pl|pm|cgi|php)/._$1/ixsm;
                $fixname =~ s/\.(?!tar$)/_/gxsm;
                $fixfile = qq~$fixname$fixext~;
                if ( $fixfile eq 'index.html' || $fixfile eq '.htaccess' ) {
                    fatal_error('attach_file_blocked');
                }

                if ( !$pmFileOverwrite ) {
                    $fixfile = check_existence( $pmuploaddir, $fixfile );
                }
                elsif ( $pmFileOverwrite == 2 && -e "$pmuploaddir/$fixfile" ) {
                    foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                    fatal_error('file_overwrite');
                }

                my $match = 0;
                if ( !$pmCheckExt ) { $match = 1; }
                else {
                    foreach my $ext (@pmAttachExt) {
                        if ( grep { /$ext$/ixsm } $fixfile ) {
                            $match = 1;
                            last;
                        }
                    }
                }
                if ($match) {
                    if ( $allowAttachIM == 0 ) {
                        foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                        fatal_error('no_perm_att');
                    }
                }
                else {
                    foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                    fatal_error( q{}, "$fixfile $fatxt{'20'} @pmAttachExt" );
                }

                my ( $size, $buffer, $filesize, $file_buffer );
                while ( $size = read $file, $buffer, 512 ) {
                    $filesize += $size;
                    $file_buffer .= $buffer;
                }
                $pmFileLimit ||= 0;
                if ( $pmFileLimit > 0 && $filesize > ( 1024 * $pmFileLimit ) ) {
                    foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                    fatal_error( q{},
                            "$fatxt{'21'} $fixfile ("
                          . int( $filesize / 1024 )
                          . " KB) $fatxt{'21b'} "
                          . $pmFileLimit );
                }
                $pmDirLimit ||= 0;
                if ( $pmDirLimit > 0 ) {
                    my $dirsize = dirsize($pmuploaddir);
                    if ( $filesize > ( ( 1024 * $pmDirLimit ) - $dirsize ) ) {
                        foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                        fatal_error(
                            q{},
                            "$fatxt{'22'} $fixfile ("
                              . (
                                int( $filesize / 1024 ) -
                                  $pmDirLimit +
                                  int( $dirsize / 1024 )
                              )
                              . " KB) $fatxt{'22b'}"
                        );
                    }
                }

 # create a new file on the server using the formatted ( new instance ) filename
                if ( fopen( NEWFILE, ">$pmuploaddir/$fixfile" ) ) {
                    binmode NEWFILE;

                   # needed for operating systems (OS) Windows, ignored by Linux
                    print {NEWFILE} $file_buffer
                      or croak "$croak{'print'} NEWFILE"; # write new file on HD
                    fclose(NEWFILE);
                }
                else
                { # return the server's error message if the new file could not be created
                    foreach (@filelist) { unlink "$pmuploaddir/$_"; }
                    fatal_error( 'file_not_open', "$pmuploaddir" );
                }

     # check if file has actually been uploaded, by checking the file has a size
                $filesizekb{$fixfile} = -s "$pmuploaddir/$fixfile";
                if ( !$filesizekb{$fixfile} ) {
                    foreach (qw("@filelist" $fixfile)) {
                        unlink "$pmuploaddir/$_";
                    }
                    fatal_error( 'file_not_uploaded', $fixfile );
                }
                $filesizekb{$fixfile} = int( $filesizekb{$fixfile} / 1024 );

                if ( $fixfile =~ /\.(jpg|gif|png|jpeg)$/ism ) {
                    my $okatt = 1;
                    if ( $fixfile =~ /gif$/ism ) {
                        my $header;
                        fopen( ATTFILE, "$pmuploaddir/$fixfile" );
                        read ATTFILE, $header, 10;
                        my $giftest;
                        ( $giftest, undef, undef, undef, undef, undef ) =
                          unpack 'a3a3C4', $header;
                        fclose(ATTFILE);
                        if ( $giftest ne 'GIF' ) { $okatt = 0; }
                    }
                    fopen( ATTFILE, "$pmuploaddir/$fixfile" );
                    while ( read ATTFILE, $buffer, 1024 ) {
                        if ( $buffer =~ /<(html|script|body)/igxsm ) {
                            $okatt = 0;
                            last;
                        }
                    }
                    fclose(ATTFILE);
                    if ( !$okatt )
                    {    # delete the file as it contains illegal code
                        foreach (qw("@filelist" $fixfile)) {
                            unlink "$pmuploaddir/$_";
                        }
                        fatal_error( 'file_not_uploaded',
                            "$fixfile $fatxt{'20a'}" );
                    }
                }

                $logFixfile = $fixfile;
                push @logfilelist, $logFixfile;
                $fixfile .= q{~} . $username;
                push @filelist, $fixfile;

            }

            if ( $FORM{"w_filename$y"} && $FORM{"w_file$y"} eq 'attachold' ) {
                $pmAttachUser = decloak( $FORM{"w_fileuser$y"} );
                $FORM{"w_filename$y"} .= q{~} . $pmAttachUser;
                push @filelist, $FORM{"w_filename$y"};
            }
        }

        # Create the list of files
        $fixfile    = join q{,}, @filelist;
        $logFixfile = join q{,}, @logfilelist;
        if (@filelist) {
            fopen( PMATTACHLOG, ">>$vardir/pm.attachments" )
              or fatal_error( 'cannot_open', "$vardir/pm.attachments" );
            foreach my $logFixfile (@logfilelist) {
                print {PMATTACHLOG}
qq~$messageid|$date|$filesizekb{$logFixfile}|$logFixfile|${$uid.$username}{'realname'}|$username\n~
                  or croak "$croak{'print'} PMATTACHLOG";
            }
            fclose(PMATTACHLOG);
        }
    }

    # go through each member in list
    # add to each msg (inbox) but only one to outbox

    $actlang = $language;
    if ( !$FORM{'draft'} && !$isBMess && !$replyguest ) {
        foreach my $UserTo (@allto) {
            $addnr++;
            chomp $UserTo;
            my ( $status, $UserTo ) = split /:/xsm, $UserTo;
            $ignored = 0;
            $UserTo =~ s/\A\s+//xsm;
            $UserTo =~ s/\s+\Z//xsm;
            $UserTo =~ s/[^0-9A-Za-z#%+,-\.@^_]//gsm;

            # Check Ignore-List, unless sender is FA
            LoadUser($UserTo);
            if ( !$isBMess ) {
                if (   ${ $uid . $UserTo }{'im_ignorelist'}
                    && !$iamadmin
                    && !$iamgmod )
                {

                    # Build Ignore-List
                    @ignore =
                      split /\|/xsm, ${ $uid . $UserTo }{'im_ignorelist'};

                    # If User is on Recipient's Ignore-List, show Error Message
                    foreach my $igname (@ignore) {

   # adds ignored user's name to array which error list will be built from later
                        chomp $igname;
                        if ( $igname eq $username ) {
                            push @nouser, $UserTo;
                            $ignored = 1;
                        }
                        if ( $igname eq q{*} ) {
                            push @nouser,
                              "$inmes_txt{'761'} $UserTo $inmes_txt{'762'};";
                            $ignored = 1;
                        }
                    }
                }
            }
            ## check and see if 1) username is marked 'away' 2) they left a message 3) you have not already had an auto-reply
            my $sendAutoReply = 1;
            if (   ${ $uid . $UserTo }{'offlinestatus'} eq 'away'
                && ${ $uid . $UserTo }{'awayreply'} ne q{}
                && ${ $uid . $UserTo }{'awaysubj'} ne q{} )
            {
                if ( ${ $uid . $UserTo }{'awayreplysent'} eq q{} ) {
                    ${ $uid . $UserTo }{'awayreplysent'} = $username;
                    UserAccount( $UserTo, 'update' );
                }
                else {
                    foreach my $replyListName ( split /,/xsm,
                        ${ $uid . $UserTo }{'awayreplysent'} )
                    {
                        if ( $replyListName eq $username ) {
                            $sendAutoReply = 0;
                            last;
                        }
                    }
                    if ($sendAutoReply) {
                        ${ $uid . $UserTo }{'awayreplysent'} .= qq~,$username~;
                        UserAccount( $UserTo, 'update' );
                    }
                }
            }
            else { $sendAutoReply = 0; }

            if ( !-e ("$memberdir/$UserTo.vars") ) {

   # adds invalid user's name to array which error list will be built from later
                push @nouser, $UserTo;
                $ignored = 1;
            }

            if ( !$ignored ) {

                # Send message to user
                fopen( INBOX, "$memberdir/$UserTo.msg" );
                my @inmessages = <INBOX>;
                fclose(INBOX);
                fopen( INBOX, ">$memberdir/$UserTo.msg" );
                print {INBOX}
"$messageid|$username|$FORM{'toshow'}|$FORM{'toshowcc'}|$FORM{'toshowbcc'}|$subject|$date|$message|$messageid|0|$ENV{'REMOTE_ADDR'}|$FORM{'status'}|u||$fixfile\n"
                  or croak "$croak{'print'} INBOX";
                print {INBOX} @inmessages or croak "$croak{'print'} INBOX";
                fclose(INBOX);

                # we've added the msg to the inbox, now update the ims file
                updateIMS( $UserTo, $messageid, 'messagein' );
                ## if we need to drop the 'away' reply in....
                if ($sendAutoReply) {
                    my $rmessageid = getnewid();
                    fopen( INBOX, "$memberdir/$username.msg" );
                    my @myinmessages = <INBOX>;
                    fclose(INBOX);
                    fopen( INBOX, ">$memberdir/$username.msg" );
                    print {INBOX}
"$rmessageid|$UserTo|$username|||${$uid.$UserTo}{'awaysubj'}|$date|${$uid.$UserTo}{'awayreply'}|$messageid|1|$ENV{'REMOTE_ADDR'}|s|u||$fixfile\n"
                      or croak "$croak{'print'} INBOX";
                    print {INBOX} @myinmessages
                      or croak "$croak{'print'} INBOX";
                    fclose(INBOX);
                }
                ## relocated sender msg out of the loop

# Send notification (Will only work if Admin has allowed the Email Notification)
                if ( ${ $uid . $UserTo }{'notify_me'} > 1
                    && $enable_notifications > 1 )
                {
                    require Sources::Mailer;
                    $language = ${ $uid . $UserTo }{'language'};
                    LoadLanguage('Email');
                    LoadLanguage('Notify');
                    LoadCensorList();
                    $useremail = ${ $uid . $UserTo }{'email'};
                    $useremail =~ s/[\n\r]//gxsm;
                    if ( $useremail ne q{} ) {
                        my $msubject = $subject ? $subject : $inmes_txt{'767'};
                        $fromname = ${ $uid . $username }{'realname'};
                        FromHTML($msubject);
                        ToChars($msubject);
                        $msubject = Censor($msubject);
                        my $chmessage = $message;
                        FromHTML($chmessage);
                        ToChars($chmessage);
                        $chmessage = Censor($chmessage);
                        $chmessage = regex_4($chmessage);

                        $pmAttachUrl = q{};
                        if ( $fixfile ne q{} ) {
                            foreach ( split /,/xsm, $fixfile ) {
                                my ( $pmAttachFile, undef ) = split /~/xsm, $_;
                                $pmAttachUrl .=
                                  qq~$pmuploadurl/$pmAttachFile\n~;
                            }
                            $pmAttachTxt = qq~\n$fatxt{'80'}:\n~;
                            $mailattach  = $pmAttachTxt . $pmAttachUrl;
                        }
                        sendmail(
                            $useremail,
                            qq~$notify_txt{'145'} $fromname ($msubject)~,
                            template_email(
                                $privatemessagenotificationemail,
                                {
                                    'sender'      => $fromname,
                                    'subject'     => $msubject,
                                    'message'     => $chmessage,
                                    'attachments' => $mailattach
                                }
                            ),
                            q{},
                            $emailcharset
                        );
                    }
                }
            }    #end add PM to outbox
        }    #end foreach loop
        if ( $#allto == $#nouser ) {
            my $badusers;
            foreach my $baduser (@nouser) {
                LoadUser($baduser);
                $badusers .=
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$baduser}">$format_unbold{$baduser}</a>, ~;
            }
            $badusers =~ s/, \Z//sm;
            fatal_error( 'im_bad_users', $badusers );
        }
    }

    if ( !$FORM{'draft'} && $isBMess ) {
        fopen( INBOX, "<$memberdir/broadcast.messages" );
        my @inmessages = <INBOX>;
        fclose(INBOX);
        fopen( INBOX, ">$memberdir/broadcast.messages" );
        print {INBOX}
"$messageid|$username|$FORM{'toshow'}|||$subject|$date|$message|$messageid|0|$ENV{'REMOTE_ADDR'}|$FORM{'status'}b|u||$fixfile\n"
          or croak "$croak{'print'} INBOX";
        print {INBOX} @inmessages or croak "$croak{'print'} INBOX";
        fclose(INBOX);
    }

    if ( $FORM{'reply'} && $FORM{'info'} ) {    # mark msg replied
        updateMessageFlag( $username, $FORM{'info'}, 'msg', q{}, 'r' );
    }

    ## this now outside the foreach, to allow just one write in the outbox
    # Add message to outbox, read outbox

    @outmessages = ();
    my $savetofile = 'outbox';
    if ( $FORM{'draft'} ) { $savetofile = 'imdraft'; }
    fopen( OUTBOX, "$memberdir/$username.$savetofile" );
    @outmessages = <OUTBOX>;
    fclose(OUTBOX);

    # add the PM to the outbox
    # the sep users now live together
    my $messFlag = q{};
    if ($isBMess) { $messFlag = 'b'; }
    if ($replyguest) {
        $messFlag = 'gr';

        $FORM{'toguest'} =~ s/ /%20/gsm;
        $FORM{'toshow'} = $FORM{'toguest'} . q{ } . $FORM{'guestemail'};
        $FORM{'toshow'} =~ s/[\n\r]//gsm;
        $FORM{'guestemail'} =~ s/[\n\r]//gsm;

        $fromname = ${ $uid . $username }{'realname'};

        my $msubject = $subject;
        FromHTML($msubject);
        ToChars($msubject);

        $chmessage = $message;
        FromHTML($chmessage);
        ToChars($chmessage);
        $chmessage = regex_4($chmessage);
        $chmessage =~ s/\r(?=\n*)//gsm;

        require Sources::Mailer;
        sendmail( $FORM{'guestemail'}, $msubject, $chmessage,
            ${ $uid . $username }{'email'} );
    }

    if (  !$FORM{'dontstoreinoutbox'}
        || $FORM{'draft'}
        || ( $FORM{'dontstoreinoutbox'} && $fixfile ne q{} ) )
    {
        fopen( OUTBOX, "+>$memberdir/$username.$savetofile" )
          or
          fatal_error( 'cannot_open', "+>$memberdir/$username.$savetofile", 1 );
        ## all but drafts being resaved just get added to their file
        if ( !$FORM{'draft'} || ( $FORM{'draft'} && !$FORM{'draftid'} ) ) {
            print {OUTBOX}
"$messageid|$username|$FORM{'toshow'}|$FORM{'toshowcc'}|$FORM{'toshowbcc'}|$subject|$date|$message|$messageid|$FORM{'reply'}|$ENV{'REMOTE_ADDR'}|$FORM{'status'}$messFlag|||$fixfile\n"
              or croak "$croak{'print'} OUTBOX";
            print {OUTBOX} @outmessages or croak "$croak{'print'} OUTBOX";

        }
        elsif ( $FORM{'draft'} && $FORM{'draftid'} ) {
            ## resaving draft - find draft message id and amend the entry
            foreach my $outmessage (@outmessages) {
                chomp $outmessage;
                if ( ( split /\|/xsm, $outmessage )[0] != $FORM{'draftid'} ) {
                    print {OUTBOX} "$outmessage\n"
                      or croak "$croak{'print'} OUTBOX";
                }
                else {
                    print {OUTBOX}
"$messageid|$username|$FORM{'toshow'}|$FORM{'toshowcc'}|$FORM{'toshowbcc'}|$subject|$date|$message|$messageid|$FORM{'reply'}|$ENV{'REMOTE_ADDR'}|$FORM{'status'}$messFlag|||$fixfile\n"
                      or croak "$croak{'print'} OUTBOX";
                }
            }
        }
        fclose(OUTBOX);

        ## update ims for sent
        if ( !$FORM{'draft'} ) {
            updateIMS( $username, $messageid, 'messageout' );
        }
        elsif ( !$FORM{'draftid'} ) {
            updateIMS( $username, $messageid, 'draftadd' );
        }
    }

    ## if this is a draft being sent, remove it from the draft file
    if ( $FORM{'draftid'} && $FORM{'draft'} ne $inmes_txt{'savedraft'} ) {
        updateIMS( $username, $messageid, 'draftsend' );
        fopen( DRAFTFILE, "$memberdir/$username.imdraft" );
        my @draftPM = <DRAFTFILE>;
        fclose(DRAFTFILE);
        fopen( DRAFTFILE, ">$memberdir/$username.imdraft" );
        seek DRAFTFILE, 0, 0;
        foreach my $draftmess (@draftPM) {
            chomp $draftmess;
            if ( ( split /\|/xsm, $draftmess )[0] != $FORM{'draftid'} ) {
                print {DRAFTFILE} "$draftmess\n"
                  or croak "$croak{'print'} DRAFTFILE";
            }
            elsif ( $FORM{'draftleave'} ) {
                print {DRAFTFILE}
"$messageid|$username|$FORM{'toshow'}|$FORM{'toshowcc'}|$FORM{'toshowbcc'}|$subject|$date|$message|$messageid|$FORM{'reply'}|$ENV{'REMOTE_ADDR'}|$FORM{'status'}$messFlag|||$fixfile\n"
                  or croak "$croak{'print'} DRAFTFILE";
            }
        }
        fclose(DRAFTFILE);
    }

# invalid users
#if there were invalid usernames in the recipient list, these names are listed after all valid users have been IMed
    if ( !$FORM{'draft'} ) {
        if (@nouser) {
            my $badusers;
            foreach my $baduser (@nouser) {
                LoadUser($baduser);
                $badusers .=
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$baduser}">$format_unbold{$baduser}</a>, ~;
            }
            $badusers =~ s/, \Z//sm;
            fatal_error( 'im_bad_users', $badusers );
        }
    }

    ## saving a draft does not count as sending
    if ( !$FORM{'draft'} ) { UserAccount( $username, 'update', 'lastim' ); }
    UserAccount( $username, 'update', 'lastonline' );

    if ( $FORM{'dontstoreinoutbox'} && $fixfile eq q{} ) {
        $yySetLocation = qq~$scripturl?action=im~;
    }
    elsif ( $FORM{'draft'} ) { $yySetLocation = qq~$scripturl?action=imdraft~; }
    else { $yySetLocation = qq~$scripturl?action=imoutbox~; }
    redirectexit();
    return;
}

##  process the to/cc/bcc lists
sub ProcIMrecs {
    $FORM{'toshow'} =~ s/ //gsm;

    if ( !$isBMess ) {
        $countMulti = 0;
        @multiple = split /\,/xsm, $FORM{'toshow'};
        foreach my $multiUser (@multiple) {
            if ($do_scramble_id) {
                $multiple[$countMulti] = decloak($multiUser);
            }
            $countMulti++;
        }
        $toshowList = join q{,}, @multiple;
        $toshowList = qq~to:$toshowList~;
        $toshowList =~ s/,/,to:/gsm;
        push @allto, ( split /\,/xsm, $toshowList );
        $FORM{'toshow'} = join q{,}, @multiple;
        $FORM{'toshowcc'} =~ s/ //gsm;
        $FORM{'toshowbcc'} =~ s/ //gsm;

        if ( $FORM{'toshowcc'} ) {
            my $countMulti = 0;
            @multiplecc = split /\,/xsm, $FORM{'toshowcc'};
            foreach my $multiUser (@multiplecc) {
                $multiUser =~ s/ //gsm;
                if ($do_scramble_id) {
                    $multiplecc[$countMulti] = decloak($multiUser);
                }
                else { $multiplecc[$countMulti] = $multiUser; }
                $countMulti++;
            }
            $toshowccList = join q{,}, @multiplecc;
            $toshowccList = qq~cc:$toshowccList~;
            $toshowccList =~ s/,/,cc:/gsm;
            push @allto, ( split /\,/xsm, $toshowccList );
            $FORM{'toshowcc'} = join q{,}, @multiplecc;
        }
        if ( $FORM{'toshowbcc'} ) {
            my $countMulti = 0;
            @multiplebcc = split /\,/xsm, $FORM{'toshowbcc'};
            foreach my $multiUser (@multiplebcc) {
                $multiUser =~ s/ //gsm;
                if ($do_scramble_id) {
                    $multiplebcc[$countMulti] = decloak($multiUser);
                }
                else { $multiplebcc[$countMulti] = $multiUser; }
                $countMulti++;
            }
            $toshowbccList = join q{,}, @multiplebcc;
            $toshowbccList = qq~bcc:$toshowbccList~;
            $toshowbccList =~ s/,/,bcc:/gsm;
            push @allto, ( split /\,/xsm, $toshowbccList );
            $FORM{'toshowbcc'} = join q{,}, @multiplebcc;
        }
    }
    return;
}

sub pageLinksList {

    # Build the page links list.
    $maxmessagedisplay ||= 10;
    my $userthreadpage =
      ( split /\|/xsm, ${ $uid . $username }{'pageindex'} )[3];
    my ( $pagetxtindex, $pagedropindex1, $pagedropindex2, $all, $allselected,
        $bmesslink );
    $postdisplaynum = 3;    # max number of pages to display
    $dropdisplaynum = 10;
    $startpage      = 0;
    if ( $INFO{'viewfolder'} ne q{} ) {
        $viewfolderinfo = qq~;viewfolder=$INFO{'viewfolder'}~;
    }
    if ( $INFO{'focus'} eq 'bmess' ) { $bmesslink = q~;focus=bmess~; }
    my @tempim = @dimmessages;
    if ( $action eq 'imstorage' ) {
        my $i = 0;
        foreach (@dimmessages) {
            if ( ( split /\|/xsm, $_ )[13] ne $INFO{'viewfolder'} ) {
                splice @tempim, $i, 1;
                next;
            }
            $i++;
        }
    }
    $max = $#tempim + 1;
    if ( $INFO{'start'} eq 'all' ) {
        $maxmessagedisplay = $max;
        $all               = 1;
        $allselected       = q~ selected="selected"~;
        $start             = 0;
    }
    else { $start = $INFO{'start'} || 0; }
    $start    = $start > $#tempim ? $#tempim : $start;
    $start    = ( int( $start / $maxmessagedisplay ) ) * $maxmessagedisplay;
    $tmpa     = 1;
    $pagenumb = int( ( $max - 1 ) / $maxmessagedisplay ) + 1;
    if ( $start >= ( ( $postdisplaynum - 1 ) * $maxmessagedisplay ) ) {
        $startpage = $start - ( ( $postdisplaynum - 1 ) * $maxmessagedisplay );
        $tmpa = int( $startpage / $maxmessagedisplay ) + 1;
    }
    if ( $max >= $start + ( $postdisplaynum * $maxmessagedisplay ) ) {
        $endpage = $start + ( $postdisplaynum * $maxmessagedisplay );
    }
    else { $endpage = $max; }
    $lastpn  = int( $#tempim / $maxmessagedisplay ) + 1;
    $lastptn = ( $lastpn - 1 ) * $maxmessagedisplay;
    $pageindex1 =
qq~<span class="small pgindex"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /> $display_txt{'139'}: $pagenumb</span>~;
    if ( $pagenumb > 1 || $all ) {
        if ( $userthreadpage == 1 ) {
            $pagetxtindexst = q~<span class="small pgindex">~;
            $pagetxtindexst .=
qq~<a href="$scripturl?pmaction=$action$bmesslink;start=$start;action=pmpagetext$viewfolderinfo"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /></a> $display_txt{'139'}: ~;
            if ( $startpage > 0 ) {
                $pagetxtindex =
qq~<a href="$scripturl?action=$action$bmesslink/0$viewfolderinfo"><span class="small">1</span></a>&nbsp;...&nbsp;~;
            }
            if ( $startpage == $maxmessagedisplay ) {
                $pagetxtindex =
qq~<a href="$scripturl?action=$action$bmesslink;start=0$viewfolderinfo"><span class="small">1</span></a>&nbsp;~;
            }
            foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
                if ( $counter % $maxmessagedisplay == 0 ) {
                    $pagetxtindex .=
                      $start == $counter
                      ? qq~<b>[$tmpa]</b>&nbsp;~
                      : qq~<a href="$scripturl?action=$action$bmesslink;start=$counter$viewfolderinfo"><span class="small">$tmpa</span></a>&nbsp;~;
                    $tmpa++;
                }
            }
            if ( $endpage < $max - ($maxmessagedisplay) ) {
                $pageindexadd = q~...&nbsp;~;
            }
            if ( $endpage != $max ) {
                $pageindexadd .=
qq~<a href="$scripturl?action=$action$bmesslink;start=$lastptn$viewfolderinfo"><span class="small">$lastpn</span></a>~;
            }
            $pagetxtindex .= qq~$pageindexadd~;
            $pageindex1 = qq~$pagetxtindexst$pagetxtindex</span>~;
            $pageindex2 = $pageindex1;
        }
        else {
            $pagedropindex1 = q~<span class="pagedropindex">~;
            $pagedropindex1 .=
qq~<span class="pagedropindex_inner"><a href="$scripturl?pmaction=$action$bmesslink;start=$start;action=pmpagedrop$viewfolderinfo"><img src="$index_togl{'index_togl'}" alt="$display_txt{'19'}" title="$display_txt{'19'}" /></a></span>~;
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
              int( ( $start / $maxmessagedisplay ) / $dropdisplaynum );
            if ( $pagenumb > $dropdisplaynum ) {
                $pagedropindex1 .=
qq~<span class="decselector"><select size="1" name="decselector1" id="decselector1" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
                $pagedropindex2 .=
qq~<span class="decselector"><select size="1" name="decselector2" id="decselector2" class="decselector_sel" onchange="if(this.options[this.selectedIndex].value) SelDec(this.options[this.selectedIndex].value, 'xx')">\n~;
            }
            for my $i ( 0 .. ( $indexpages - 1 ) ) {
                $indexpage  = ( $i * $dropdisplaynum ) * $maxmessagedisplay;
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
                      qq~$indexstart|$indexend|$maxmessagedisplay|$indexpage~;
                }
                if ( $pagenumb > $dropdisplaynum ) {
                    $pagedropindex1 .=
qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
                    $pagedropindex2 .=
qq~<option value="$indexstart|$indexend|$maxmessagedisplay|$indexpage"$selected>$indxoption</option>\n~;
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
            $tmpmaxmessagedisplay = $maxmessagedisplay;
            if ( substr( $INFO{'start'}, 0, 3 ) eq 'all' ) {
                $maxmessagedisplay = $maxmessagedisplay * $dropdisplaynum;
            }
            $prevpage = $start - $tmpmaxmessagedisplay;
            $nextpage = $start + $maxmessagedisplay;
            $pagedropindexpvbl =
qq~<img src="$index_togl{'index_left0'}" height="14" width="13" alt="" />~;
            $pagedropindexnxbl =
qq~<img src="$index_togl{'index_right0'}" height="14" width="13" alt="" />~;
            if ( $start < $maxmessagedisplay ) {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left0'}" height="14" width="13" alt="" />~;
            }
            else {
                $pagedropindexpv .=
qq~<img src="$index_togl{'index_left'}" height="14" width="13" alt="$pidtxt{'02'}" title="$pidtxt{'02'}" class="cursor" onclick="location.href=\\'$scripturl?action=$action$bmesslink;start=$prevpage\\'" ondblclick="location.href=\\'$scripturl?action=$action$bmesslink;start=0\\'" />~;
            }
            if ( $nextpage > $lastptn ) {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right0'}" height="14" width="13" alt="" />~;
            }
            else {
                $pagedropindexnx .=
qq~<img src="$index_togl{'index_right'}" height="14" width="13" alt="$pidtxt{'03'}" title="$pidtxt{'03'}" class="cursor"" onclick="location.href=\\'$scripturl?action=$action$bmesslink;start=$nextpage\\'" ondblclick="location.href=\\'$scripturl?action=$action$bmesslink;start=$lastptn\\'" />~;
            }
            $pageindex1  = qq~$pagedropindex1</span>~;
            $pageindexjs = qq~
            <script type="text/javascript">
            function SelDec(decparam, visel) {
                splitparam = decparam.split("|");
                var vistart = parseInt(splitparam[0]);
                var viend = parseInt(splitparam[1]);
                var maxpag = parseInt(splitparam[2]);
                var pagstart = parseInt(splitparam[3]);
                var allpagstart = parseInt(splitparam[3]);
                if (visel == 'xx' && decparam == '$pagejsindex') visel = '$tstart';
                var pagedropindex = '$visel_0';
                for (i=vistart; i<=viend; i++) {
                    if (visel == pagstart) pagedropindex += '$visel_1a<b>' + i + '</b>$visel_1b';
                    else pagedropindex += '$visel_2a<a href="$scripturl?action=$action$bmesslink;start=' + pagstart + '">' + i + '</a>$visel_1b';
                    pagstart += maxpag;
                }
                ~;
            if ($showpageall) {
                $pageindexjs .= qq~
                    if (vistart != viend) {
                        if(visel == 'all') pagedropindex += '$visel_1a<b>$pidtxt{"01"}</b></td>';
                        else pagedropindex += '$visel_2a<a href="$scripturl?action=$action$bmesslink;start=all-' + allpagstart + '">$pidtxt{"01"}</a>$visel_1b';
                    }
                    ~;
            }
            $pageindexjs .= qq~
                if (visel != 'xx') pagedropindex += '$visel_3a$pagedropindexpv$pagedropindexnx$visel_1b';
                else pagedropindex += '$visel_3a$pagedropindexpvbl$pagedropindexnxbl$visel_1b';
                pagedropindex += '$visel_4';
                document.getElementById('ViewIndex1').innerHTML=pagedropindex;
                document.getElementById('ViewIndex1').style.visibility = 'visible';
                ~;
            if ( $pagenumb > $dropdisplaynum ) {
                $pageindexjs .= q~
                document.getElementById('decselector1').value = decparam;
                ~;
            }
            $pageindexjs .= qq~
        }
        SelDec('$pagejsindex', '$tstart');
        </script>
        ~;
        }
    }
    return;
}

##  output one or all IM - detailed view
sub DoShowIM {
    my ($inp) = @_;
    $messfound = 0;
    if ( $callerid < 5 ) { updateIMS( $username, $inp, 'inread' ); }

    my (
        $showIM,           $fromTitle,      $toTitle,
        $toTitleCC,        $toTitleBCC,     $usernamelinkfrom,
        $usernamelinkto,   $usernamelinkcc, $usernamelinkbcc,
        $prevMessId,       $nextMessid,     $PMnav,
        $attachDeleteWarn, $pmAttachment,   $pmShowAttach,
        %attach_gif
    );
    $messcount = 0;
    foreach my $messagesim (@dimmessages) {
        $nextMessid = $messageid;
        (
            $messageid,   $musername,    $mtousers, $mccusers,
            $mbccusers,   $msub,         $mdate,    $immessage,
            $mpmessageid, $mreplyno,     $imip,     $mstatus,
            $mflags,      $mstorefolder, $mattach,
        ) = split /\|/xsm, $messagesim;
        $messcount++;
        if ( $messageid == $inp ) { $messfound = 1; last; }
    }

    if ( !$messfound ) {
        my $redirect;
        my @redrect =
          ( q{}, 'im', 'imoutbox', 'imstorage', 'imdraft', 'im;focus=bmess', );

        foreach my $i ( 1 .. 5 ) {
            if ( $INFO{'caller'} == $i + 1 ) {
                $redirect = $redrect[$i];
            }
        }
        $yySetLocation = qq~$scripturl?action=$redirect~;
        redirectexit();
    }

    ## if not at the end of the list, catch the 'previous' id
    if ( $messcount <= $#dimmessages ) {
        ( $prevMessId, undef ) = split /\|/xsm, $dimmessages[$messcount];
    }
    ## wrap the URL in
    if ( $INFO{'id'} ne 'all' && $prevMessId ne q{} ) {
        $previd =
qq~&laquo; <a href="$scripturl?action=imshow;caller=$INFO{'caller'};id=$prevMessId">$inmes_imtxt{'40'}</a>~;
    }
    if ( $INFO{'id'} ne 'all' && $nextMessid ne q{} ) {
        $nextid =
qq~<a href="$scripturl?action=imshow;caller=$INFO{'caller'};id=$nextMessid">$inmes_imtxt{'41'}</a> &raquo;~;
    }
    if ( $INFO{'id'} ne 'all' && $#dimmessages > 0 ) {
        $allid =
qq~<a href="$scripturl?action=imshow;caller=$INFO{'caller'};id=all">$inmes_txt{'190'}</a>~;
    }

    my $mydate = timeformat( $mdate, 0, 0, 0, 1 );
    if ( $INFO{'caller'} == 1 ) {
        if ($mtousers) {
            foreach my $uname ( split /,/xsm, $mtousers ) {
                LoadValidUserDisplay($uname);
                $usernamelinkto .= (
                    ${ $uid . $uname }{'realname'}
                    ? CreateUserDisplayLine($uname)
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernamelinkto =~ s/, $//sm;
            $toTitle = qq~$inmes_txt{'324'}:~;
        }
        if ($mccusers) {
            foreach my $uname ( split /,/xsm, $mccusers ) {
                LoadValidUserDisplay($uname);
                $usernamelinkcc .= (
                    ${ $uid . $uname }{'realname'}
                    ? CreateUserDisplayLine($uname)
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };
            }
            $usernamelinkcc =~ s/, $//sm;
            $toTitleCC = qq~$inmes_txt{'325'}:~;
        }
        if ($mbccusers) {
            foreach my $uname ( split /,/xsm, $mbccusers ) {
                if ( $uname eq $username ) {
                    LoadValidUserDisplay($uname);
                    $usernamelinkbcc =
                      ${ $uid . $uname }{'realname'}
                      ? CreateUserDisplayLine($uname)
                      : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                      );
                }
            }
            if ($usernamelinkbcc) {
                $toTitleBCC = qq~$inmes_txt{'326'}:~;
            }
        }

        if ( $mstatus eq 'g' || $mstatus eq 'ga' ) {
            my ( $guestName, $guestEmail ) = split / /sm, $musername;
            $guestName =~ s/%20/ /gsm;
            $usernamelinkfrom =
              qq~$guestName (<a href="mailto:$guestEmail">$guestEmail</a>)~;
        }
        else {
            LoadValidUserDisplay($musername);
            $usernamelinkfrom =
              ${ $uid . $musername }{'realname'}
              ? CreateUserDisplayLine($musername)
              : (
                  $musername ? qq~$musername ($maintxt{'470a'})~
                : $maintxt{'470a'}
              );    # 470a == Ex-Member
        }
        $fromTitle = qq~$inmes_txt{'318'}:~;

    }
    elsif ( $INFO{'caller'} == 2 ) {
        LoadValidUserDisplay($musername);
        $usernamelinkfrom =
          ${ $uid . $musername }{'realname'}
          ? CreateUserDisplayLine($musername)
          : (
            $musername ? qq~$musername ($maintxt{'470a'})~ : $maintxt{'470a'} );

        # 470a == Ex-Member
        $fromTitle = qq~$inmes_txt{'318'}:~;

        if ( $mstatus !~ /b/sm ) {
            if ( $mstatus !~ /gr/sm ) {
                foreach my $uname ( split /,/xsm, $mtousers ) {
                    LoadValidUserDisplay($uname);
                    $usernamelinkto .= (
                        ${ $uid . $uname }{'realname'}
                        ? CreateUserDisplayLine($uname)
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
            }
            else {
                my ( $guestName, $guestEmail ) = split / /sm, $mtousers;
                $guestName =~ s/%20/ /gsm;
                $usernamelinkto =
                  qq~$guestName (<a href="mailto:$guestEmail">$guestEmail</a>)~;
            }
            $toTitle = qq~$inmes_txt{'324'}:~;
        }
        else {
            foreach my $uname ( split /,/xsm, $mtousers ) {
                $usernamelinkto .= links_to($uname);
            }
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }
        $usernamelinkto =~ s/, $//sm;
        if ($mccusers) {
            foreach my $uname ( split /,/xsm, $mccusers ) {
                LoadValidUserDisplay($uname);
                $usernamelinkcc .= (
                    ${ $uid . $uname }{'realname'}
                    ? CreateUserDisplayLine($uname)
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernamelinkcc =~ s/, $//sm;
            $toTitleCC = qq~$inmes_txt{'325'}:~;
        }
        if ($mbccusers) {
            foreach my $uname ( split /,/xsm, $mbccusers ) {
                LoadValidUserDisplay($uname);
                $usernamelinkbcc .= (
                    ${ $uid . $uname }{'realname'}
                    ? CreateUserDisplayLine($uname)
                    : (
                          $uname ? qq~$uname ($maintxt{'470a'})~
                        : $maintxt{'470a'}
                    )
                ) . q{, };    # 470a == Ex-Member
            }
            $usernamelinkbcc =~ s/, $//sm;
            $toTitleBCC = qq~$inmes_txt{'326'}:~;
        }
    }
    elsif ( $INFO{'caller'} == 3 ) {
        if ( $mstatus !~ /b/sm ) {
            if ( $mstatus !~ /gr/sm ) {
                foreach my $uname ( split /,/xsm, $mtousers ) {
                    LoadValidUserDisplay($uname);
                    $usernamelinkto .= (
                        ${ $uid . $uname }{'realname'}
                        ? CreateUserDisplayLine($uname)
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
            }
            else {
                my ( $guestName, $guestEmail ) = split / /sm, $mtousers;
                $guestName =~ s/%20/ /gsm;
                $usernamelinkto =
                  qq~$guestName (<a href="mailto:$guestEmail">$guestEmail</a>)~;
            }
            $toTitle = qq~$inmes_txt{'324'}:~;
            if ( $mccusers && $musername eq $username ) {
                foreach my $uname ( split /,/xsm, $mccusers ) {
                    LoadValidUserDisplay($uname);
                    $usernamelinkcc .= (
                        ${ $uid . $uname }{'realname'}
                        ? CreateUserDisplayLine($uname)
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
                $usernamelinkcc =~ s/, $//sm;
                $toTitleCC = qq~$inmes_txt{'325'}:~;
            }
            if ( $mbccusers && $musername eq $username ) {
                foreach my $uname ( split /,/xsm, $mbccusers ) {
                    LoadValidUserDisplay($uname);
                    $usernamelinkbcc .= (
                        ${ $uid . $uname }{'realname'}
                        ? CreateUserDisplayLine($uname)
                        : (
                              $uname ? qq~$uname ($maintxt{'470a'})~
                            : $maintxt{'470a'}
                        )
                    ) . q{, };    # 470a == Ex-Member
                }
                $usernamelinkbcc =~ s/, $//sm;
                $toTitleBCC = qq~$inmes_txt{'326'}:~;
            }
        }
        else {
            foreach my $uname ( split /,/xsm, $mtousers ) {
                $usernamelinkto .= links_to($uname);
            }
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }
        $usernamelinkto =~ s/, $//sm;

        if ( $mstatus eq 'g' || $mstatus eq 'ga' ) {
            my ( $guestName, $guestEmail ) = split / /sm, $musername;
            $guestName =~ s/%20/ /gsm;
            $usernamelinkfrom =
              qq~$guestName (<a href="mailto:$guestEmail">$guestEmail</a>)~;
        }
        else {
            LoadValidUserDisplay($musername);
            $usernamelinkfrom =
              ${ $uid . $musername }{'realname'}
              ? CreateUserDisplayLine($musername)
              : (
                  $musername ? qq~$musername ($maintxt{'470a'})~
                : $maintxt{'470a'}
              );    # 470a == Ex-Member
        }
        $fromTitle = qq~$inmes_txt{'318'}:~;

    }
    elsif ( $INFO{'caller'} == 5 && ( $mstatus eq 'g' || $mstatus eq 'ga' ) ) {
        my ( $guestName, $guestEmail ) = split / /sm, $musername;
        $guestName =~ s/%20/ /gsm;
        $usernamelinkfrom =
          qq~$guestName (<a href="mailto:$guestEmail">$guestEmail</a>)~;
        $fromTitle = qq~$inmes_txt{'318'}:~;

    }
    elsif ( $INFO{'caller'} == 5 && $mstatus =~ /b/sm ) {
        if ($mtousers) {
            foreach my $uname ( split /,/xsm, $mtousers ) {
                $usernamelinkto .= links_to($uname);
            }
            $usernamelinkto =~ s/, $//sm;
            $toTitle = qq~$inmes_txt{'324'} $inmes_txt{'327'}:~;
        }

        LoadValidUserDisplay($musername);
        $usernamelinkfrom =
          ${ $uid . $musername }{'realname'}
          ? CreateUserDisplayLine($musername)
          : (
            $musername ? qq~$musername ($maintxt{'470a'})~ : $maintxt{'470a'} );

        # 470a == Ex-Member

        $fromTitle = qq~$inmes_txt{'318'}:~;
    }

    $PMnav = buildPMNavigator();

    ToChars($msub);
    $msub = Censor($msub);

    $message = $immessage;
    wrap();
    if ($enable_ubbc) {
        enable_yabbc();
        DoUBBC();
    }
    wrap2();
    ToChars($message);
    $message = Censor($message);

    $avstyle  = q{};
    $my_title = q{};
    $my_sig   = q{};
    if ($fromTitle) {
        $my_title = qq~
        <span class="small totitle">
        <b>$fromTitle</b> $usernamelinkfrom
        </span><br />
        ~;
    }

    if ($toTitle) {
        $my_title .= qq~
        <span class="small totitle">
        <b>$toTitle</b> $usernamelinkto
        </span><br />
        ~;
    }

    if ($toTitleCC) {
        $my_title .= qq~
        <span class="small totitle">
        <b>$toTitleCC</b> $usernamelinkcc
        </span><br />
        ~;
    }

    if ($toTitleBCC) {
        $my_title .= qq~
        <span class="small totitle">
        <b>$toTitleBCC</b> $usernamelinkbcc
        </span><br />
        ~;
    }
    if ( $mstatus ne 'ga' && $mstatus ne 'g' && $signature ) {
        $my_sig = $show_my_sig;
        $my_sig =~ s/{yabb signature}/$signature/sm;
    }

    # Do we have an attachment file?
    chomp $mattach;
    if ( $mattach ne q{} ) {
        foreach ( split /,/xsm, $mattach ) {
            my ( $pmAttachFile, undef ) = split /~/xsm, $_;
            if ( $pmAttachFile =~ /\.(.+?)$/xsm ) {
                $ext = lc $1;
            }
            if ( !exists $attach_gif{$ext} ) {
                $attach_gif{$ext} =
                  ( $ext && -e "$htmldir/Templates/Forum/$useimages/$ext.gif" )
                  ? "$imagesdir/$ext.gif"
                  : "$micon_bg{'paperclip'}";
            }
            my $filesize = -s "$pmuploaddir/$pmAttachFile";
            if ($filesize) {
                if (   $pmAttachFile =~ /\.(bmp|jpe|jpg|jpeg|gif|png)$/ixsm
                    && $pmDisplayPics == 1 )
                {
                    $pmShowAttach .=
qq~<div class="small attbox"><a href="$pmuploadurl/$pmAttachFile" target="_blank"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $pmAttachFile</a> (~
                      . int( $filesize / 1024 )
                      . q~ KB)<br />~
                      . (
                        $img_greybox
                        ? (
                            $img_greybox == 2
                            ? qq~<a href="$pmuploadurl/$pmAttachFile" data-rel="gb_imageset[nice_pics]" title="$pmAttachFile">~
                            : qq~<a href="$pmuploadurl/$pmAttachFile" data-rel="gb_image[nice_pics]" title="$pmAttachFile">~
                          )
                        : qq~<a href="$pmuploadurl/$pmAttachFile" target="_blank">~
                      )
                      . qq~<img src="$pmuploadurl/$pmAttachFile" name="attach_img_resize" alt="$pmAttachFile" title="$pmAttachFile" style="display:none" /></a></div>\n~;
                }
                else {
                    $pmAttachment .=
qq~<div class="small"><a href="$pmuploadurl/$pmAttachFile"><img src="$attach_gif{$ext}" class="bottom" alt="" /> $pmAttachFile</a> (~
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
              s/<div class="small">/<div class="small attbox_b">/gsm;
        }
        $my_attach .= $show_my_attach;
        $my_attach =~ s/{yabb pmAttachment}/$pmAttachment/sm;
        $my_attach =~ s/{yabb pmShowAttach}/$pmShowAttach/sm;
    }

    my $lookupIP =
      ($ipLookup)
      ? qq~<a href="$scripturl?action=iplookup;ip=$imip">$imip</a>~
      : qq~$imip~;
    if ( $iamadmin || $iamgmod && $gmod_access2{'ipban2'} eq 'on' ) {
        $imip = $lookupIP;
    }
    else { $imip = $inmes_txt{'511'}; }

    my $postMenuTemp = q{};
    if ( $mstatus ne 'ga' && $mstatus ne 'g' ) {
        $postMenuTemp = $sendEmail . $sendPM . $membAdInfo . '&nbsp;';
        $postMenuTemp =~ s/\Q$menusep//ism;
    }

    $mreplyno++;
    $showIM_link = q{};
    if (   $INFO{'caller'} == 1
        || ( $INFO{'caller'} == 3 && $musername ne q{} )
        || ( $INFO{'caller'} == 5 && $musername ne q{} ) )
    {    ## inbox / stored inbox can reply/quote
        if ( $mstatus eq 'g' || $mstatus eq 'ga' ) {
            $showIM_link .=
qq~<a href="$scripturl?action=imsend;caller=$INFO{'caller'};quote=$mreplyno;replyguest=1;id=$messageid">$img{'reply_ims'}</a>~;
        }
        else {
            $showIM_link .= qq~
            <a href="$scripturl?action=imsend;caller=$INFO{'caller'};quote=$mreplyno;to=$useraccount{$musername};id=$messageid">$img{'quote'}</a>$menusep
            <a href="$scripturl?action=imsend;caller=$INFO{'caller'};reply=$mreplyno;to=$useraccount{$musername};id=$messageid">$img{'reply_ims'}</a>$menusep~;
        }
    }

    if ( $INFO{'caller'} != 5 && $mstatus ne 'ga' && $mstatus ne 'g' ) {
        $showIM_link .= qq~
            <a href="$scripturl?action=imsend;caller=$INFO{'caller'};quote=$mreplyno;forward=1;id=$messageid">$img{'forward'}</a>$menusep~;
    }

    if ( $INFO{'caller'} != 5
        || ( $INFO{'caller'} == 5 && ( $iamadmin || $username eq $musername ) )
      )
    {
        chomp $mattach;
        if (   $INFO{'caller'} == 2
            || $INFO{'caller'} == 3
            || $INFO{'caller'} == 5 && $mattach ne q{} )
        {
            foreach ( split /,/xsm, $mattach ) {
                my ( $pmAttachFile, $pmAttachUser ) = split /~/xsm, $_;
                if ( $username eq $pmAttachUser
                    && -e "$pmuploaddir/$pmAttachFile" )
                {
                    $attachDeleteWarn = $inmes_txt{'770a'};
                }
            }
        }
        $showIM_link .= qq~
            <a href="$scripturl?action=deletemultimessages;caller=$INFO{'caller'};deleteid=$messageid" onclick="return confirm('$inmes_txt{'770'}$attachDeleteWarn');">$img{'im_remove'}</a>
        ~;
    }
    $showIM_link .= qq~
            $menusep<a href="javascript:void(window.open('$scripturl?action=imprint;caller=$INFO{'caller'};id=$messageid','printwindow'))">$img{'print_im'}</a>
        ~;
    $my_notme = q{};
    if    ( $mstatus =~ m/c/sm ) { $messIconName = 'confidential'; }
    elsif ( $mstatus =~ m/u/sm ) { $messIconName = 'urgent'; }
    elsif ( $mstatus =~ m/a/sm || $messStatus =~ m/ga/sm ) {
        $messIconName = 'alertmod';
    }
    elsif ( $mstatus =~ m/gr/sm ) {
        $messIconName = 'guestpmreply';
    }
    elsif ( $mstatus =~ m/g/sm ) { $messIconName = 'guestpm'; }
    else                         { $messIconName = 'standard'; }

    if ( $mstatus ne 'ga' && $mstatus ne 'g' ) {
        $notme    = $musername eq $username ? $mtousers : $musername;
        $notme    = ${ $uid . $notme }{'realname'};
        $my_notme = (
            $notme
            ? qq~<a href="$scripturl?action=pmsearch;searchtype=user;search=$notme">$inmes_imtxt{'42'} <i>$notme</i></a>~
            : '&nbsp;'
        );
    }

    $showIM .= $myIM_show;
    $showIM =~ s/{yabb my_title}/$my_title/sm;
    $showIM =~ s/{yabb msub}/$msub/sm;
    $showIM =~ s/{yabb msimg}/$micon{$messIconName}/sm;
    $showIM =~ s/{yabb mydate}/$mydate/sm;
    $showIM =~ s/{yabb message}/$message/sm;
    $showIM =~ s/{yabb my_sig}/$my_sig/sm;
    $showIM =~ s/{yabb my_showIP}/$my_showIP/sm;
    $showIM =~ s/{yabb imip}/$imip/sm;
    $showIM =~ s/{yabb my_attach}/$my_attach/sm;
    $showIM =~ s/{yabb postMenuTemp}/$postMenuTemp/sm;
    $showIM =~ s/{yabb showIM_link}/$showIM_link/sm;
    $showIM =~ s/{yabb my_notme}/$my_notme/sm;
    $showIM =~ s/{yabb PMnav}/$PMnav/sm;

    return $showIM;
}

## build the links for single PM display
sub buildPMNavigator {
    if ( $previd ne q{} ) { $PMnav = qq~$previd~; }
    if ( $allid ne q{} && $previd ne q{} ) { $PMnav .= qq~ | $allid~; }
    elsif ( $allid ne q{} ) { $PMnav = qq~$allid~; }
    if ( $nextid ne q{} && $allid ne q{} ) { $PMnav .= qq~ | $nextid~; }
    return $PMnav;
}

## show original PM/BM or the PM/BM before Preview at the bottom of the message field
sub doshowims {
    my $tempdate;
    if ( $INFO{'id'} && !$INFO{'replyguest'} ) {
        my $messageCount     = 0;
        my $messageFoundFlag = 0;
        foreach my $message (@messages) {
            my $tmnum = ( split /\|/xsm, $message )[0];
            if ( $tmnum == $INFO{'id'} ) { $messageFoundFlag = 1; last; }
            else                         { $messageCount++; }
        }
        ## as a backup, if it is not found that way, revert to the list member
        if ( !$messageFoundFlag ) { $messageCount = $INFO{'num'}; }
        (
            $messageid, $musername, $mto,     $mtocc,  $mtobcc,
            $msub,      $mdate,     $message, $mparid, $mreplyno,
            $mip,       $mstatus,   $mflags,  $mstore, $mattach
        ) = split /\|/xsm, $messages[$messageCount];
        $tempdate = timeformat($mdate);
    }
    else {
        return;
    }

    ToChars($msub);
    $msub = Censor($msub);

    wrap();
    if ($enable_ubbc) {
        enable_yabbc();
        DoUBBC();
    }
    wrap2();
    ToChars($message);
    $message = Censor($message);

    if ( !${ $uid . $musername }{'password'} ) { LoadUser($musername); }
    my $musernameRealName = ${ $uid . $musername }{'realname'};
    if ( !$musernameRealName ) { $musernameRealName = $musername; }
    $my_save_draft = (
        ( $INFO{'id'} && $INFO{'caller'} != 4 )
        ? "$inmes_txt{'30'}: "
        : ( $INFO{'id'} ? "$inmes_txt{'savedraft'} $inmes_txt{'30'}: " : q{} )
    );

    $imsend .= $my_savedraft;
    $imsend =~ s/{yabb msub}/$msub/sm;
    $imsend =~ s/{yabb musernameRealName}/$musernameRealName/sm;
    $imsend =~ s/{yabb my_save_draft}/$my_save_draft/sm;
    $imsend =~ s/{yabb tempdate}/$tempdate/sm;
    $imsend =~ s/{yabb message}/$message/sm;
    return $imsend;
}

sub links_to {
    my ($uname) = @_;
    my @opts2 = (
        [ 'all', 'admins', 'gmods', 'fmods', 'mods', ],
        [
            qq~<b>$inmes_txt{'bmallmembers'}</b>~,
            qq~<b>$inmes_txt{'bmadmins'}</b>~,
            qq~<b>$inmes_txt{'bmgmods'}</b>~,
            qq~<b>$inmes_txt{'bmfmods'}</b>~,
            qq~<b>$inmes_txt{'bmmods'}</b>~,
        ],
    );

    if (   $uname eq 'all'
        || $uname eq 'admins'
        || $uname eq 'gmods'
        || $uname eq 'fmods'
        || $uname eq 'mods' )
    {
        foreach my $i ( 0 .. 4 ) {
            my $opt0 = $opts2[0]->[$i];
            my $opt1 = $opts2[1]->[$i];

            if ( $uname eq $opt0 ) {
                $usernamelinkto = $opt1 . q{, };
            }
        }
    }
    else {
        my ( $title, undef ) = split /\|/xsm, $NoPost{$uname}, 2;
        $usernamelinkto = qq~<b>$title</b>~ . q{, };
    }
    return $usernamelinkto;
}

1;
