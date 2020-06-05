###############################################################################
# RegistrationLog.pm                                                          #
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
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

$registrationlogpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Register');

sub view_reglog {
    is_admin_or_gmod();

    $yytitle = $prereg_txt{'15a'};

    if ( -e "$vardir/registration.log" ) {
        fopen( LOGFILE, "$vardir/registration.log" );
        @logentries = <LOGFILE>;
        fclose(LOGFILE);
        @logentries = reverse @logentries;

        fopen( FILE, "$memberdir/memberlist.txt" );
        @memberlist = <FILE>;
        fclose(FILE);

        # If a pre-registration list exists load it
        if ( -e "$memberdir/memberlist.inactive" ) {
            fopen( INACT, "$memberdir/memberlist.inactive" );
            @reglist = <INACT>;
            fclose(INACT);
        }

        # grab pre regged user activationkey for admin activation
        foreach (@reglist) {
            ( undef, $actcode, $regmember, undef ) = split /\|/xsm, $_, 4;
            $actkey{$regmember} = $actcode;
        }
    }
    else {
        $servertime = $date;
        push @logentries, "$servertime|LD|$username|$username|$user_ip";
    }
    @memberlist = reverse @memberlist;

    if ( @logentries > 0 ) {
        $logcount = @logentries;
        my $newstart = $INFO{'newstart'} || 0;

        $postdisplaynum = 8;
        $max            = $logcount;
        $newstart       = ( int( $newstart / 25 ) ) * 25;
        $tmpa           = 1;
        if ( $newstart >= ( ( $postdisplaynum - 1 ) * 25 ) ) {
            $startpage = $newstart - ( ( $postdisplaynum - 1 ) * 25 );
            $tmpa = int( $startpage / 25 ) + 1;
        }
        if ( $max >= $newstart + ( $postdisplaynum * 25 ) ) {
            $endpage = $newstart + ( $postdisplaynum * 25 );
        }
        else { $endpage = $max }
        if ( $startpage > 0 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0" class="norm">1</a>&nbsp;...&nbsp;~;
        }
        if ( $startpage == 25 ) {
            $pageindex =
qq~<a href="$adminurl?action=$action;newstart=0" class="norm">1</a>&nbsp;~;
        }
        foreach my $counter ( $startpage .. ( $endpage - 1 ) ) {
            if ( $counter % 25 == 0 ) {
                $pageindex .=
                  $newstart == $counter
                  ? qq~<b>$tmpa</b>&nbsp;~
                  : qq~<a href="$adminurl?action=$action;newstart=$counter" class="norm">$tmpa</a>&nbsp;~;
                $tmpa++;
            }
        }
        $lastpn  = int( $logcount / 25 ) + 1;
        $lastptn = ( $lastpn - 1 ) * 25;
        if ( $endpage < $max - (25) ) { $pageindexadd = q~...&nbsp;~; }
        if ( $endpage != $max ) {
            $pageindexadd .=
qq~<a href="$adminurl?action=$action;newstart=$lastptn">$lastpn</a>~;
        }
        $pageindex .= $pageindexadd;

        $pageindex = qq~<tr>
                <td class="windowbg" colspan="4"><span class="small" style="float: left;">$admin_txt{'139'}: $pageindex</span></td>
            </tr>~;

        $numbegin = ( $newstart + 1 );
        $numend   = ( $newstart + 25 );
        if   ( $numend > $logcount ) { $numend  = $logcount; }
        if   ( $logcount == 0 )      { $numshow = q{}; }
        else                         { $numshow = qq~($numbegin - $numend)~; }

        @logentries = splice @logentries, $newstart, 25;
    }

    foreach my $logentry (@logentries) {
        chomp $logentry;
        my ( $logtime, $status, $userid, $actid, $ipadd ) =
          split /\|/xsm, $logentry;
        if ($do_scramble_id) {
            $cryptactid  = cloak($actid);
            $cryptuserid = cloak($userid);
        }
        else {
            $cryptactid  = $actid;
            $cryptuserid = $userid;
        }
        if ( $userid ne $actid && $actid ne q{} ) {
            LoadUser($actid);
            $actadminlink =
qq~ $prereg_txt{'by'} <a href="$scripturl?action=viewprofile;username=$cryptactid">${$uid.$actid}{'realname'}</a>~;
        }
        else {
            $actadminlink = q{};
        }
        if ( $status eq 'AA' && LoadUser($userid) ) {
            LoadUser($userid);
            $linkuserid =
qq~$userid (<a href="$scripturl?action=viewprofile;username=$cryptuserid">${$uid.$userid}{'realname'}</a>)~;
        }
        else {
            $linkuserid = $userid;
        }
        $is_member = check_member($userid);
        if   ($do_scramble_id) { $cryptid = cloak($userid); }
        else                   { $cryptid = $userid; }
        $reclogtime = timeformat($logtime);
        if ( $status eq 'N' && $is_member == 0 && -e "$memberdir/$userid.pre" )
        {
            $delrecord =
qq~<a href="$adminurl?action=del_regentry;username=$cryptid">$prereg_txt{'del'}</a>~;
            $delrecord .=
qq~<br /><a href="$adminurl?action=view_regentry;username=$cryptid~
              . (
                $actkey{$userid} ne q{}
                ? ";activationkey=$actkey{$userid};type=validate"
                : q{}
              ) . qq~">$prereg_txt{'view'}</a>~;
            $delrecord .=
qq~<br /><a href="$scripturl?action=activate;username=$cryptid;activationkey=$actkey{$userid}">$prereg_txt{'act'}</a>~;
        }
        elsif ($status eq 'W'
            && $is_member == 0
            && -e "$memberdir/$userid.wait" )
        {
            $delrecord =
qq~<a href="$adminurl?action=rej_regentry;username=$userid">$prereg_txt{'reject'}</a>~;
            $delrecord .=
qq~<br /><a href="$adminurl?action=view_regentry;username=$cryptid;type=approve">$prereg_txt{'view'}</a>~;
            $delrecord .=
qq~<br /><a href="$adminurl?action=apr_regentry;username=$userid">$prereg_txt{'apr'}</a>~;
        }
        else {
            $delrecord = '---';
        }
        my $lookupIP =
          ($ipLookup)
          ? qq~<a href="$scripturl?action=iplookup;ip=$ipadd">$ipadd</a>~
          : qq~$ipadd~;
        $loglist .= qq~<tr>
            <td class="windowbg center">$reclogtime</td>
            <td class="windowbg2 center">$prereg_txt{$status}$actadminlink<br />IP: $lookupIP - <a href="$adminurl?action=ipban_err;ban=$ipadd;lev=p;return=view_reglog">$admin_txt{'725f'}</a></td>
            <td class="windowbg center">$linkuserid</td>
            <td class="windowbg2 center">$delrecord</td>
        </tr>~;
    }

    $yymain .= qq~
    <script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
    <form name="reglog_form" action="$adminurl?action=clean_reglog" method="post" onsubmit="return submitproc();">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <colgroup>
                <col style="width: 20%" />
                <col style="width: 35%" />
                <col style="width: 25%" />
                <col style="width: 20%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="4">$admin_img{'xx'} <b>$yytitle</b></td>
            </tr><tr>
                <td class="windowbg2" colspan="4">
                    <div class="pad-more">$prereg_txt{'20'}</div>
                </td>
            </tr>
            $pageindex
            <tr>
                <td class="catbg center"><b>$prereg_txt{'17'}</b></td>
                <td class="catbg center"><b>$prereg_txt{'18'}</b></td>
                <td class="catbg center"><b>$prereg_txt{'19'}</b></td>
                <td class="catbg center"><b>$prereg_txt{'action'}</b></td>
            </tr>
            $loglist
            </table>
        </div>
        <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell">
                <tr>
                    <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'725e'}</th>
                </tr><tr>
                    <td class="catbg center">
                        <input type="submit" value="$prereg_txt{'9'}" onclick="return confirm('$prereg_txt{'9'}');" class="button" />
                    </td>
                </tr>
            </table>
            </div>
            </form>
~;
    $action_area = 'view_reglog';
    AdminTemplate();
    return;
}

sub check_member {
    my ($inp) = @_;
    my $is_member = 0;
    foreach my $lstmember (@memberlist) {
        chomp $lstmember;
        ( $listmember, undef ) = split /\t/xsm, $lstmember, 2;
        if ( $inp eq $listmember ) {
            $is_member = 1;
            last;
        }
    }
    return $is_member;
}

sub clean_reglog {
    is_admin_or_gmod();
    my (@outlist);
    fopen( REG, "$vardir/registration.log", 1 );
    my @reglist = <REG>;
    fclose(REG);
    ## depending on registration type only leave uncompleted entries in the log for completion and remove the failed or completed ones ##
    foreach (@reglist) {
        my ( undef, $regstatus, $reguser, undef ) = split /\|/xsm, $_;
        if (   ( $regtype == 1 || $regtype == 2 )
            && $regstatus eq 'N'
            && -e "$memberdir/$reguser.pre" )
        {
            push @outlist, $_;
        }
        if (   $regtype == 1
            && $regstatus eq 'W'
            && -e "$memberdir/$reguser.wait" )
        {
            push @outlist, $_;
        }
    }
    fopen( REG, ">$vardir/registration.log", 1 );
    print {REG} @outlist or croak "$croak{'print'} REG";
    fclose(REG);

    $yySetLocation = qq~$adminurl?action=view_reglog~;
    redirectexit();
    return;
}

sub kill_registration {
    my ($inp) = @_;
    is_admin_or_gmod();
    my $changed;
    my $deluser = $inp || $INFO{'username'};
    if ($do_scramble_id) { $deluser = decloak($deluser); }

    fopen( INFILE, "$memberdir/memberlist.inactive" );
    @actlist = <INFILE>;
    fclose(INFILE);

    # check if user is in pre-registration and check activation key
    foreach (@actlist) {
        ( $regtime, undef, $regmember, undef ) = split /\|/xsm, $_, 4;
        if ( $deluser eq $regmember ) {
            $changed = 1;
            unlink "$memberdir/$regmember.pre";

            # add entry to registration log
            fopen( REG, ">>$vardir/registration.log", 1 );
            print {REG} "$date|D|$regmember|$username|$user_ip\n"
              or croak "$croak{'print'} REG";
            fclose(REG);
        }
        else {

            # update non activate user list
            # write valid registration to the list again
            push @outlist, $_;
        }
    }
    if ($changed) {

        # re-open inactive list for update if changed
        fopen( OUTFILE, ">$memberdir/memberlist.inactive", 1 );
        print {OUTFILE} @outlist or croak "$croak{'print'} OUTFILE";
        fclose(OUTFILE);
    }
    $yySetLocation = qq~$adminurl?action=view_reglog~;
    redirectexit();
    return;
}

sub view_registration {
    is_admin_or_gmod();
    my $viewuser = $INFO{'username'} || $FORM{'username'};
    my $readuser = $viewuser;
    my $viewtype = $INFO{'type'};
    my $actkey   = $INFO{'activationkey'};
    if ($do_scramble_id) { $readuser = decloak($viewuser); }
    LoadUser($readuser);
    $yymain .= qq~
<form action="$adminurl?action=admin_descision;activationkey=$actkey" method="post" name="creator">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width:320px" />
        <col style="width:auto" />
    </colgroup>
    <tr>
        <td colspan="2" class="titlebg">$admin_img{'profile'} <b>$prereg_txt{'view'}</b>
            <input type="hidden" name="username" value="$viewuser" />
            <input type="hidden" name="type" value="$viewtype" />
            <input type="hidden" name="activationkey" value="$actkey" />
        </td>
    </tr><tr class="windowbg">
        <td><b>$prereg_txt{'apr_id'}: </b></td>
        <td>$readuser</td>
    </tr><tr class="windowbg">
       <td><b>$prereg_txt{'apr_name'}: </b></td>
       <td>${$uid.$readuser}{'realname'}</td>
    </tr>~;

    if ( $viewtype eq 'validate' ) {
        $yymain .= qq~<tr class="windowbg">
        <td><b>$prereg_txt{'apr_email_invalid'}: </b></td>
        <td>${$uid.$readuser}{'email'}</td>
    </tr>~;
    }
    elsif ( $viewtype eq 'approve' ) {
        $yymain .= qq~<tr class="windowbg">
   <td><b>$prereg_txt{'apr_email_valid'}: </b></td>
   <td>${$uid.$readuser}{'email'}</td>
 </tr>~;
    }

    if ( $addmemgroup_enabled == 2 || $addmemgroup_enabled == 3 ) {
        my @usergroup;
        foreach ( split /,/xsm, ${ $uid.$readuser }{'addgroups'} ) {
            push
              @usergroup,
              (
                split /\|/xsm,
                $NoPost{ ${ $uid.$readuser }{'addgroups'} }, 2
              )[0];
        }
        $yymain .= qq~<tr class="windowbg">
   <td><b>$register_txt{'765a'}:</b></td>
   <td>~ . join( q{, }, @usergroup ) . q~</td>
 </tr>~;
    }

    my $lookupIP =
      ($ipLookup)
      ? qq~<a href="$scripturl?action=iplookup;ip=${$uid.$readuser}{'lastips'}">${$uid.$readuser}{'lastips'}</a>~
      : qq~${$uid.$readuser}{'lastips'}~;

    $yymain .= qq~<tr class="windowbg">
   <td><b>$prereg_txt{'apr_language'}: </b></td>
   <td>${$uid.$readuser}{'language'}</td>
 </tr><tr class="windowbg">
   <td><b>$prereg_txt{'apr_ip'}: </b></td>
   <td>$lookupIP (<a href="$adminurl?action=ipban_err;ban=${$uid.$readuser}{'lastips'};lev=p;return=view_reglog">$admin_txt{'725f'}</a>)</td>
 </tr>~;

    if ( $regtype == 1 ) {
        $yymain .= qq~<tr class="windowbg">
   <td><b>$prereg_txt{'apr_reason'}: </b></td>
   <td>${$uid.$readuser}{'regreason'}</td>
 </tr>~;
    }
    if ($extendedprofiles) {
        require Admin::Settings_ExtendedProfiles;
        $yymain .= ext_viewprofile_r($readuser);
    }

    if ( $viewtype eq 'approve' ) {
        $yymain .= qq~<tr>
   <td colspan="2" class="titlebg">$admin_img{'profile'} <b>$prereg_txt{'apr_admin_reason_title'}</b></td>
 </tr>
 <tr class="windowbg">
   <td><b>$prereg_txt{'apr_admin_reason'}: </b></td>
   <td><textarea rows="4" cols="50" id="admin_reason" name="admin_reason">$admin_reason</textarea></td>
 </tr>
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'actions'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" name="moda" value="$prereg_txt{'apr_admin_reject'}" onclick="return confirm('$prereg_txt{'apr_admin_reject'} ?')" class="button" />
            <input type="submit" name="moda" value="$prereg_txt{'apr_admin_approve'}" onclick="return confirm('$prereg_txt{'apr_admin_approve'} ?')" class="button" />
        </td>
    </tr>
</table>
</div>~;

    }
    elsif ( $viewtype eq 'validate' ) {
        $yymain .= qq~
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'actions'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" name="moda" value="$prereg_txt{'apr_admin_delete'}" onclick="return confirm('$prereg_txt{'apr_admin_delete'} ?')" class="button" />
            <input type="submit" name="moda" value="$prereg_txt{'apr_admin_validate'}" onclick="return confirm('$prereg_txt{'apr_admin_validate'} ?')" class="button" />
        </td>
    </tr>
</table>
</div>~;
    }

    $yymain .= q~
</form>~;

    $yytitle = "$prereg_txt{'view'}";
    AdminTemplate();
    return;
}

sub process_registration_review {
    is_admin_or_gmod();
    my $descuser  = $FORM{'username'};
    my $desctype  = $FORM{'type'};
    my $descision = $FORM{'moda'};
    my $actkey    = $FORM{'activationkey'};
    $admin_reason = $FORM{'admin_reason'};
    if ( $desctype eq 'validate' ) {
        if ( $descision eq $prereg_txt{'apr_admin_validate'} ) {
            require Sources::Register;
            user_activation( $descuser, $actkey );
        }
        elsif ( $descision eq $prereg_txt{'apr_admin_delete'} ) {
            kill_registration($descuser);
        }
    }
    elsif ( $desctype eq 'approve' ) {
        if ( $descision eq $prereg_txt{'apr_admin_approve'} ) {
            approve_registration($descuser);
        }
        elsif ( $descision eq $prereg_txt{'apr_admin_reject'} ) {
            reject_registration($descuser);
        }
    }
    return;
}

sub reject_registration {
    my ($inp) = @_;
    is_admin_or_gmod();
    my $deluser = $inp || $INFO{'username'};
    if ( !$admin_reason ) { $admin_reason = $FORM{'admin_reason'}; }

    if ($do_scramble_id)  { $deluser      = decloak($deluser); }

    if ( -e "$memberdir/memberlist.approve" && $regtype == 1 ) {
        fopen( APR, "$memberdir/memberlist.approve" );
        @aprlist = <APR>;
        fclose(APR);
    }

    # check if waiting user exists
    if ( -e "$memberdir/$deluser.wait" ) {
        LoadUser($deluser);
        ## send a rejection email ##
        my $templanguage = $language;
        $language = ${ $uid . $deluser }{'language'};
        LoadLanguage('Email');
        require Sources::Mailer;
        if ( $admin_reason ne q{} ) {
            $message = template_email(
                $reviewrejectedemail,
                {
                    'displayname' => ${ $uid . $deluser }{'realname'},
                    'username'    => $deluser,
                    'reviewer'    => ${ $uid . $username }{'realname'},
                    'reason'      => $admin_reason
                }
            );
            sendmail(
                ${ $uid . $deluser }{'email'},
                "$mailreg_txt{'apr_result_reject'} $mbname",
                $message, q{}, $emailcharset
            );
        }
        elsif ( $nomailspammer == 1 ) {
            $message = template_email(
                $instantrejectedemail,
                {
                    'displayname' => ${ $uid . $deluser }{'realname'},
                    'username'    => $deluser,
                    'reviewer'    => ${ $uid . $username }{'realname'}
                }
            );

            sendmail(
                ${ $uid . $deluser }{'email'},
                "$mailreg_txt{'apr_result_reject'} $mbname",
                $message, q{}, $emailcharset
            );
        }
        $language = $templanguage;

        ## remove the registration data for the rejected user ##
        unlink "$memberdir/$deluser.wait";
        foreach (@aprlist) {
            ( undef, undef, $regmember, undef ) = split /\|/xsm, $_, 4;
            if ( $regmember ne $deluser ) {
                push @aprchnglist, $_;
            }
        }

        # update approval user list
        fopen( APR, ">$memberdir/memberlist.approve" );
        print {APR} @aprchnglist or croak "$croak{'print'} APR";
        fclose(APR);

        ## add entry to registration log ##
        fopen( REG, ">>$vardir/registration.log", 1 );
        print {REG} "$date|AR|$deluser|$username|$user_ip\n"
          or croak "$croak{'print'} REG";
        fclose(REG);
    }
    $yySetLocation = qq~$adminurl?action=view_reglog~;
    redirectexit();
    return;
}

sub approve_registration {
    my ($inp) = @_;
    is_admin_or_gmod();
    my $apruser = $inp || $INFO{'username'};
    if ( !$admin_reason ) { $admin_reason = $FORM{'admin_reason'}; }

    if ($do_scramble_id)  { $apruser      = decloak($apruser); }

    ## load the list with waiting approvals ##
    fopen( APR, "$memberdir/memberlist.approve" );
    @aprlist = <APR>;
    fclose(APR);

    foreach (@aprlist) {
        ( undef, undef, $regmember, $regpassword ) = split /\|/xsm, $_;
        if ( $regmember ne $apruser ) {
            push @aprchnglist, $_;
        }
        else {
            $foundmember   = $regmember;
            $foundpassword = $regpassword;
        }
    }

    ## check if waiting user exists and was indeed in the waiting list ##
    if ( -e "$memberdir/$apruser.wait" && $foundmember ne q{} ) {
        LoadUser($apruser);

        # ckeck if email is already in active use
        if (
            lc ${ $uid . $apruser }{'email'} eq
            lc MemberIndex( 'check_exist', ${ $uid . $apruser }{'email'} ) )
        {
            $yymain .=
qq~<span class="important"><b>$prereg_txt{'email_taken'} <i>${$uid.$apruser}{'email'}</i> ($prereg_txt{'35'}: $apruser)</b></span>~;
            view_reglog();
        }

        ## user is approved, so let him/her in ##
        rename "$memberdir/$apruser.wait", "$memberdir/$apruser.vars";
        MemberIndex( 'add', $apruser );

        # update approval user list
        fopen( APR, ">$memberdir/memberlist.approve" );
        print {APR} @aprchnglist or croak "$croak{'print'} APR";
        fclose(APR);

        ## add entry to registration log ##
        fopen( REG, ">>$vardir/registration.log", 1 );
        print {REG} "$date|AA|$apruser|$username|$user_ip\n"
          or croak "$croak{'print'} REG";
        fclose(REG);

        ## send a approval email ##
        my $templanguage = $language;
        $language = ${ $uid . $apruser }{'language'};
        LoadLanguage('Email');
        require Sources::Mailer;
        if ($emailpassword) {
            if ( $admin_reason ne q{} ) {
                $message = template_email(
                    $pwreviewapprovedemail,
                    {
                        'displayname' => ${ $uid . $apruser }{'realname'},
                        'username'    => $apruser,
                        'reviewer'    => ${ $uid . $username }{'realname'},
                        'reason'      => $admin_reason,
                        'password'    => $foundpassword
                    }
                );
            }
            else {
                $message = template_email(
                    $pwinstantapprovedemail,
                    {
                        'displayname' => ${ $uid . $apruser }{'realname'},
                        'username'    => $apruser,
                        'reviewer'    => ${ $uid . $username }{'realname'},
                        'password'    => $foundpassword
                    }
                );
            }
        }
        else {
            if ( $admin_reason ne q{} ) {
                $message = template_email(
                    $reviewapprovedemail,
                    {
                        'displayname' => ${ $uid . $apruser }{'realname'},
                        'username'    => $apruser,
                        'reviewer'    => ${ $uid . $username }{'realname'},
                        'reason'      => $admin_reason
                    }
                );
            }
            else {
                $message = template_email(
                    $instantapprovedemail,
                    {
                        'displayname' => ${ $uid . $apruser }{'realname'},
                        'username'    => $apruser,
                        'reviewer'    => ${ $uid . $username }{'realname'}
                    }
                );
            }
        }
        sendmail(
            ${ $uid . $apruser }{'email'},
            "$mailreg_txt{'apr_result_approved'} $mbname",
            $message, q{}, $emailcharset
        );
        $language = $templanguage;

        if ( $send_welcomeim == 1 ) {

# new format msg file:
# messageid|(from)user|(touser(s))|(ccuser(s))|(bccuser(s))|subject|date|message|(parentmid)|reply#|ip|messagestatus|flags|storefolder|attachment
            $messageid = $BASETIME . $PROCESS_ID;
            fopen( INBOX, ">$memberdir/$apruser.msg" );
            print {INBOX}
"$messageid|$sendname|$apruser|||$imsubject|$date|$imtext|$messageid|0|$ENV{'REMOTE_ADDR'}|s|u||\n"
              or croak "$croak{'print'} INBOX";
            fclose(INBOX);
        }
    }
    $yySetLocation = qq~$adminurl?action=view_reglog~;
    redirectexit();
    return;
}

1;
