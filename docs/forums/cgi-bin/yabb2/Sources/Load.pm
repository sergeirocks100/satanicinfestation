###############################################################################
# Load.pm                                                                     #
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

$loadpmver = 'YaBB 2.6.11 $Revision: 1611 $';

sub LoadBoardControl {
    $binboard = q{};
    $annboard = q{};

    fopen( FORUMCONTROL, "$boardsdir/forum.control" )
      or fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    my @boardcontrols = <FORUMCONTROL>;
    fclose(FORUMCONTROL);
    $maxboards = $#boardcontrols;

    foreach my $boardline (@boardcontrols) {
        $boardline =~ s/[\r\n]//gxsm;    # Built in chomp
        my (
            $cntcat,         $cntboard,        $cntpic,
            $cntdescription, $cntmods,         $cntmodgroups,
            $cnttopicperms,  $cntreplyperms,   $cntpollperms,
            $cntzero,        $cntmembergroups, $cntann,
            $cntrbin,        $cntattperms,     $cntminageperms,
            $cntmaxageperms, $cntgenderperms,  $cntcanpost,
            $cntparent,      $rules,           $rulestitle,
            $rulesdesc,      $rulescollapse,   $brdpasswr,
            $brdpassw,       $cntbdrss,
            ## Mod Hook 1 ##
        ) = split /\|/xsm, $boardline;
        ## create a global boards array
        push @allboards, $cntboard;

        $cntdescription =~ s/\&\ /\&amp; /gxsm;
        if ( substr( $cntmods, 0, 2 ) eq ', ' ) {
            substr( $cntmods, 0, 2 ) = q{};
        }
        if ( substr( $cntmodgroups, 0, 2 ) eq ', ' ) {
            substr( $cntmodgroups, 0, 2 ) = q{};
        }

        %{ $uid . $cntboard } = (
            'cat'           => $cntcat,
            'description'   => $cntdescription,
            'pic'           => $cntpic,
            'mods'          => $cntmods,
            'modgroups'     => $cntmodgroups,
            'topicperms'    => $cnttopicperms,
            'replyperms'    => $cntreplyperms,
            'pollperms'     => $cntpollperms,
            'zero'          => $cntzero,
            'membergroups'  => $cntmembergroups,
            'ann'           => $cntann,
            'rbin'          => $cntrbin,
            'attperms'      => $cntattperms,
            'minageperms'   => $cntminageperms,
            'maxageperms'   => $cntmaxageperms,
            'genderperms'   => $cntgenderperms,
            'canpost'       => $cntcanpost,
            'parent'        => $cntparent,
            'rules'         => $rules,
            'rulestitle'    => $rulestitle,
            'rulesdesc'     => $rulesdesc,
            'rulescollapse' => $rulescollapse,
            'brdpasswr'     => $brdpasswr,
            'brdpassw'      => $brdpassw,
            'brdrss'        => $cntbdrss,
             ## Mod Hook 2 ##
        );
        if ( $cntann == 1 )  { $annboard = $cntboard; }
        if ( $cntrbin == 1 ) { $binboard = $cntboard; }
    }
    return;
}

sub LoadIMs {
    return
      if ( $iamguest
        || $PM_level == 0
        || ( $maintenance   && !$iamadmin )
        || ( $PM_level == 2 && ( !$staff ) )
        || ( $PM_level == 4 && ( !$iamadmin && !$iamgmod && !$iamfmod ) )
        || ( $PM_level == 3 && ( !$iamadmin && !$iamgmod ) ) );

    if ( !exists ${$username}{'PMmnum'} ) { buildIMS( $username, 'load' ); }

    my $imnewtext;
    if ( ${$username}{'PMimnewcount'} == 1 ) {
        $imnewtext =
qq~<a href="$scripturl?action=imshow;caller=1;id=-1">1 $load_txt{'155'}</a>~;
    }
    elsif ( !${$username}{'PMimnewcount'} ) { $imnewtext = $load_txt{'nonew'}; }
    else {
        $imnewtext =
qq~<a href="$scripturl?action=imshow;caller=1;id=-1">${$username}{'PMimnewcount'} $load_txt{'154'}</a>~;
    }

    if ( ${$username}{'PMmnum'} == 1 ) {
        if ( ${$username}{'PMimnewcount'} == 1 ) {
          $yyim = qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'155b'}</a>~;
        }
        else {
          $yyim =
 qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'471'}</a>, $imnewtext~;
        }
    }
    elsif ( !${$username}{'PMmnum'} && !${$username}{'PMimnewcount'} ) {
        $yyim =
 qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'153'}</a>~;
    }
    elsif ( ${$username}{'PMmnum'} == ${$username}{'PMimnewcount'} ) {
        $yyim = qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'154b'}</a>~;
    }
    else {
         $yyim =
 qq~$load_txt{'152'} <a href="$scripturl?action=im">${$username}{'PMmnum'} $load_txt{'153'}</a>, $imnewtext~;
    }

    if ( !$user_ip && $iamadmin ) {
        $yyim .= qq~<br /><b>$load_txt{'773'}</b>~;
    }
    return;
}

sub LoadCensorList {
    opendir DIR, $langdir;
    my @langDir = readdir DIR;
    closedir DIR;
    @lang = ();
    foreach my $langitems ( sort { lc($a) cmp lc $b } @langDir ) {
        chomp $langitems;
        if (   ( $langitems ne q{.} )
            && ( $langitems ne q{..} )
            && ( $langitems ne q{.htaccess} )
            && ( $langitems ne q{index.html} ) )
        {
            push @lang, $langitems;
        }
    }

    if ( $#censored > 0 ) {
        return;
    }
    elsif (
        scalar @lang == 1
        && ( ( -s "$langdir/$language/censor.txt" ) < 3
            || !-e "$langdir/$language/censor.txt" )
      )
    {
        return;
    }
    for my $langd (@lang) {
        if ( -e "$langdir/$langd/censor.txt" ) {
            fopen( CENSOR, "$langdir/$langd/censor.txt" );
            while ( chomp( $buffer = <CENSOR> ) ) {
                $buffer =~ s/\r(?=\n*)//gxsm;
                if ( $buffer =~ m/\~/sm ) {
                    ( $tmpa, $tmpb ) = split /\~/xsm, $buffer;
                    $tmpc = 0;
                }
                else {
                    ( $tmpa, $tmpb ) = split /=/xsm, $buffer;
                    $tmpc = 1;
                }
                push @censored, [ $tmpa, $tmpb, $tmpc ];
            }
        }
    }
    fclose(CENSOR);
    return;
}

sub LoadUserSettings {
    LoadBoardControl();
    $iamguest = $username eq 'Guest' ? 1 : 0;
    if ( $username ne 'Guest' ) {
        LoadUser($username);
        if ( !$maintenance
            || ${ $uid . $username }{'position'} eq 'Administrator' )
        {
            $iammod = is_moderator($username);
            if (   ${ $uid . $username }{'position'} eq 'Administrator'
                || ${ $uid . $username }{'position'} eq 'Global Moderator'
                || ${ $uid . $username }{'position'} eq 'Mid Moderator'
                || $iammod )
            {
                $staff = 1;
            }
            else { $staff = 0; }
            $sessionvalid = 1;
            if ( $sessions == 1 && $staff == 1 ) {
                $cursession = encode_password($user_ip);
                chomp $cursession;
                if (   ${ $uid . $username }{'session'} ne $cursession
                    || ${ $uid . $username }{'session'} ne $cookiesession )
                {
                    $sessionvalid = 0;
                }
            }
            $spass = ${ $uid . $username }{'password'};

         # Make sure that if the password doesn't match you get FULLY Logged out
            if ( $spass && $spass ne $password && $action ne 'logout' ) {
                $yySetLocation =
                  $guestaccess ? qq~$scripturl~ : qq~$scripturl?action=login~;
                UpdateCookie('delete');
                redirectexit();
            }

            $iamadmin =
              ( ${ $uid . $username }{'position'} eq 'Administrator'
                  && $sessionvalid == 1 ) ? 1 : 0;
            $iamgmod =
              ( ${ $uid . $username }{'position'} eq 'Global Moderator'
                  && $sessionvalid == 1 ) ? 1 : 0;
            $iamfmod =
              ( ${ $uid . $username }{'position'} eq 'Mid Moderator'
                  && $sessionvalid == 1 ) ? 1 : 0;
            if ( $sessionvalid == 1 ) {
                ${ $uid . $username }{'session'} = $cursession;
            }
            CalcAge( $username, 'calc' );

            # Set the order how Topic summaries are displayed
            if ( !$adminscreen && $ttsureverse ) {
                $ttsreverse = ${ $uid . $username }{'reversetopic'};
            }
            return;
        }
    }

    FormatUserName(q{});
    UpdateCookie('delete');
    $username = 'Guest';
    $iamguest = '1';
    $iamadmin = q{};
    $iamgmod  = q{};
    $iamfmod  = q{};
    $password = q{};
    local $ENV{'HTTP_COOKIE'} = q{};
    $yyim    = q{};
    $yyuname = q{};
    return;
}

sub FormatUserName {
    my ($user) = @_;
    return if $useraccount{$user};
    $useraccount{$user} = $do_scramble_id ? cloak($user) : $user;
    return;
}

sub LoadUser {
    my ( $user, $userextension ) = @_;
    return 1 if exists ${ $uid . $user }{'realname'};
    return 0 if $user eq q{} || $user eq 'Guest';

    if ( !$userextension ) { $userextension = 'vars'; }
    if ( ( $regtype == 1 || $regtype == 2 ) && -e "$memberdir/$user.pre" ) {
        $userextension = 'pre';
    }
    elsif ( $regtype == 1 && -e "$memberdir/$user.wait" ) {
        $userextension = 'wait';
    }

    if ( -e "$memberdir/$user.$userextension" ) {
        if ( $user ne $username ) {
            fopen( LOADUSER, "$memberdir/$user.$userextension" )
              or fatal_error( 'cannot_open', "$memberdir/$user.$userextension",
                1 );
            my @settings = <LOADUSER>;
            fclose(LOADUSER);
            foreach (@settings) {
                if ( $_ =~ /'(.*?)',"(.*?)"/xsm ) {
                    ${ $uid . $user }{$1} = $2;
                }
            }
        }
        else {
            fopen( LOADUSER, "<$memberdir/$user.$userextension" )
              or fatal_error( 'cannot_open',
                "$memberdir/$user.$userextension load 1", 1 );
            my @settings = <LOADUSER>;
            fclose(LOADUSER);
            for my $i ( 0 .. ( @settings - 1 ) ) {
                if ( $settings[$i] =~ /'(.*?)',"(.*?)"/xsm ) {
                    ${ $uid . $user }{$1} = $2;
                    if (   $1 eq 'lastonline'
                        && $INFO{'action'} ne 'login2'
                        && !${ $uid . $user }{'stealth'} )
                    {
                        ${ $uid . $user }{$1} = $date;
                        $settings[$i] = qq~'lastonline',"$date"\n~;
                    }
                }
            }
            if ( scalar @settings != 0 ) {
                fopen( LOADUSER, ">$memberdir/$user.$userextension" )
                  or fatal_error( 'cannot_open',
                    "$memberdir/$user.$userextension load2", 1 );
                print {LOADUSER} @settings or croak "$croak{'print'} LOADUSER";
                fclose(LOADUSER);
            }
            else {
                fatal_error( 'missingvars', "$memberdir/$user.$userextension",
                    1 );
            }
        }

        ToChars( ${ $uid . $user }{'realname'} );
        FormatUserName($user);
        LoadMiniUser($user);

        return 1;
    }

    return 0;    # user not found
}

sub is_moderator {
    my ( $user, $brd ) = @_;
    my @checkboards;
    if   ($brd) { @checkboards = ($brd); }
    else        { @checkboards = @allboards; }

    foreach (@checkboards) {

        # check if user is in the moderator list
        foreach ( split /, ?/sm, ${ $uid . $_ }{'mods'} ) {
            if ( $_ eq $user ) { return 1; }
        }

        # check if user is member of a moderatorgroup
        foreach my $testline ( split /, /sm, ${ $uid . $_ }{'modgroups'} ) {
            if ( $testline eq ${ $uid . $user }{'position'} ) { return 1; }

            foreach ( split /,/xsm, ${ $uid . $user }{'addgroups'} ) {
                if ( $testline eq $_ ) { return 1; }
            }
        }
    }
    return 0;
}

sub is_moderator_b {
    my ($user) = @_;
    $mybrds = q{ };

    foreach my $i (@allboards) {

        # check if user is in the moderator list
        foreach ( split /, ?/sm, ${ $uid . $i }{'mods'} ) {
            if ( $_ eq $user ) {
                get_forum_master();
                ( $boardname, $boardperms, $boardview ) =
                  split /\|/xsm, $board{$i};

                $mybrds .= qq~$boardname<br />~;
                return 1;
            }
        }
    }

    return 0;
}

sub KillModerator {
    my ($killmod) = @_;
    my ( @boardcontrol, @newmods, @boardline );
    fopen( FORUMCONTROL, "<$boardsdir/forum.control" )
      or fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    @oldcontrols = <FORUMCONTROL>;
    fclose(FORUMCONTROL);

    for my $boardline (@oldcontrols) {
        chomp $boardline;
        if ( $boardline ne q{} ) {
            @newmods = ();
            @boardline = split /\|/xsm, $boardline;
            foreach ( split /, /sm, $boardline[4] ) {
                if ( $killmod ne $_ ) { push @newmods, $_; }
            }
            $boardline[4] = join q{, }, @newmods;
            $newboardline = join q{|}, @boardline;
            push @boardcontrol, $newboardline . "\n";
        }
    }
    @boardcontrol = undupe(@boardcontrol);
    fopen( FORUMCONTROL, ">$boardsdir/forum.control" )
      or fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    print {FORUMCONTROL} @boardcontrol or croak "$croak{'print'} FORUMCONTROL";
    fclose(FORUMCONTROL);
    return;
}

sub KillModeratorGroup {
    my ($killmod) = @_;
    my ( @boardcontrol, @newmods, @boardline );
    fopen( FORUMCONTROL, "<$boardsdir/forum.control" )
      or fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    @oldcontrols = <FORUMCONTROL>;
    fclose(FORUMCONTROL);

    foreach my $boardline (@oldcontrols) {
        chomp $boardline;
        if ( $boardline ne q{} ) {
            @newmods = ();
            @boardline = split /\|/xsm, $boardline;
            foreach ( split /, /sm, $boardline[5] ) {
                if ( $killmod ne $_ ) { push @newmods, $_; }
            }
            $boardline[5] = join q{, }, @newmods;
            $newboardline = join q{|}, @boardline;
            push @boardcontrol, $newboardline . "\n";
        }
    }
    @boardcontrol = undupe(@boardcontrol);
    fopen( FORUMCONTROL, ">$boardsdir/forum.control" )
      or fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    print {FORUMCONTROL} @boardcontrol or croak "$croak{'print'} FORUMCONTROL";
    fclose(FORUMCONTROL);
    return;
}

sub LoadUserDisplay {
    my ($user) = @_;
    if ( exists ${ $uid . $user }{'password'} ) {
        if ( $yyUDLoaded{$user} ) { return 1; }
    }
    else {
        LoadUser($user);
    }
    LoadCensorList();

    if ( !$minlinkweb ) { $minlinkweb = 0; }
    ${ $uid . $user }{'weburl'} =
      (
        ${ $uid . $user }{'weburl'}
          && ( ${ $uid . $user }{'postcount'} >= $minlinkweb
            || ${ $uid . $user }{'position'} eq 'Administrator'
            || ${ $uid . $user }{'position'} eq 'Mid Moderator'
            || ${ $uid . $user }{'position'} eq 'Global Moderator' )
      )
      ? qq~<a href="${$uid.$user}{'weburl'}" target="_blank">~
      . ( $sm ? $img{'website_sm'} : $img{'website'} ) . '</a>'
      : q{};

    $displayname = ${ $uid . $user }{'realname'};
    if ( ${ $uid . $user }{'signature'} ) {
        $message = ${ $uid . $user }{'signature'};

        if ($enable_ubbc) {
            enable_yabbc();
            DoUBBC(1);
        }

        ToChars($message);

        ${ $uid . $user }{'signature'} = Censor($message);

        # use height like code boxes do. Set to 200px at > 15 newlines
        if ( 15 < ${ $uid . $user }{'signature'} =~ /<br \/>|<tr>/gsm ) {
            ${ $uid . $user }{'signature'} =
              qq~<div class="load_sig">${$uid.$user}{'signature'}</div>~;
        }
        else {
            ${ $uid . $user }{'signature'} =
              qq~<div class="load_sig_b">${$uid.$user}{'signature'}</div>~;
        }
    }

    $thegtalkuser = $user;
    $thegtalkname = ${ $uid . $user }{'realname'};

    if ( !$UseMenuType ) {
        $UseMenuType = $MenuType;
    }

    get_micon();

    $yimimg      = SetImage( 'yim',      $UseMenuType );
    $aimimg      = SetImage( 'aim',      $UseMenuType );
    $skypeimg    = SetImage( 'skype',    $UseMenuType );
    $myspaceimg  = SetImage( 'myspace',  $UseMenuType );
    $facebookimg = SetImage( 'facebook', $UseMenuType );
    $gtalkimg    = SetImage( 'gtalk',    $UseMenuType );
    $icqimg      = SetImage( 'icq',      $UseMenuType );
    $twitterimg  = SetImage( 'twitter',  $UseMenuType );
    $youtubeimg  = SetImage( 'youtube',  $UseMenuType );

    $icqad{$user} =
      $icqad{$user}
      ? qq~<a href="http://web.icq.com/${$uid.$user}{'icq'}" target="_blank">$load_con{'icqadd'}</a>~
      : q{};
    $icqad{$user} =~ s/{yabb usericq}/${$uid.$user}{'icq'}/gsm;

    ${ $uid . $user }{'icq'} =
      ${ $uid . $user }{'icq'}
      ? qq~<a href="http://web.icq.com/${$uid.$user}{'icq'}" title="${$uid.$user}{'icq'}" target="_blank">$icqimg</a>~
      : q{};

    ${ $uid . $user }{'aim'} =
      ${ $uid . $user }{'aim'}
      ? qq~<a href="aim:goim?screenname=${$uid.$user}{'aim'}&#38;message=Hi.+Are+you+there?">$aimimg</a>~
      : q{};

    ${ $uid . $user }{'skype'} =
      ${ $uid . $user }{'skype'}
      ? qq~<a href="javascript:void(window.open('callto://${$uid.$user}{'skype'}','skype','height=80,width=340,menubar=no,toolbar=no,scrollbars=no'))">$skypeimg</a>~
      : q{};

    ${ $uid . $user }{'myspace'} =
      ${ $uid . $user }{'myspace'}
      ? qq~<a href="http://www.myspace.com/${$uid.$user}{'myspace'}" target="_blank">$myspaceimg</a>~
      : q{};

    ${ $uid . $user }{'facebook'} =
      ${ $uid . $user }{'facebook'}
      ? q~<a href="http://www.facebook.com/~
      . ( ${ $uid . $user }{'facebook'} !~ /\D/xsm ? 'profile.php?id=' : q{} )
      . qq~${$uid.$user}{'facebook'}" target="_blank">$facebookimg</a>~
      : q{};

    ${ $uid . $user }{'twitter'} =
      ${ $uid . $user }{'twitter'}
      ? qq~<a href="http://twitter.com/${$uid.$user}{'twitter'}" target="_blank">$twitterimg</a>~
      : q{};

    ${ $uid . $user }{'youtube'} =
      ${ $uid . $user }{'youtube'}
      ? qq~<a href="http://www.youtube.com/${$uid.$user}{'youtube'}" target="_blank">$youtubeimg</a>~
      : q{};

    ${ $uid . $user }{'gtalk'} = ${ $uid . $user }{'gtalk'} ? $gtalkimg : q{};

    $yimon{$user} =
      $yimon{$user}
      ? qq~<img src="http://opi.yahoo.com/online?u=${$uid.$user}{'yim'}&#38;m=g&#38;t=0" alt="" />~
      : q{};

    ${ $uid . $user }{'yim'} =
      ${ $uid . $user }{'yim'}
      ? qq~<a href="http://edit.yahoo.com/config/send_webmesg?.target=${$uid.$user}{'yim'}" target="_blank">$yimimg</a>~
      : q{};

    if ( $showgenderimage && ${ $uid . $user }{'gender'} ) {
        ${ $uid . $user }{'gender'} =
          ${ $uid . $user }{'gender'} =~ m/Female/ixsm ? 'female' : 'male';
        $genderTitle = ${ $uid . $user }{'gender'};
        ${ $uid . $user }{'gender'} =
          ${ $uid . $user }{'gender'}
          ? qq~$load_txt{'231'}: $load_con{'gender'}<br />~
          : q{};
        ${ $uid . $user }{'gender'} =~ s/{yabb gender}/$genderTitle/sm;
        ${ $uid . $user }{'gender'} =~
          s/{yabb genderTitle}/$load_txt{$genderTitle}/gsm;
    }
    else {
        ${ $uid . $user }{'gender'} = q{};
    }

    if ($showzodiac && ${ $uid . $user }{'bday'}) {
        require Sources::EventCalBirthdays;
        my ($user_bdmon, $user_bdday, undef ) = split /\//xsm, ${ $uid . $user }{'bday'} ;
        $zodiac = starsign($user_bdday, $user_bdmon);
        ${ $uid . $user }{'zodiac'} = qq~<span style="vertical-align: middle;">$zodiac_txt{'sign'}:</span> $zodiac<br />~;
    }
    else {
        ${ $uid . $user }{'zodiac'} = q{};
    }

    if ( $showusertext && ${ $uid . $user }{'usertext'} )
    {    # Censor the usertext and wrap it
        ${ $uid . $user }{'usertext'} =
          WrapChars( Censor( ${ $uid . $user }{'usertext'} ), 20 );
    }
    else {
        ${ $uid . $user }{'usertext'} = q{};
    }

    # Create the userpic / avatar html
    if ( $showuserpic && $allowpics ) {
        ${ $uid . $user }{'userpic'} ||= $my_blank_avatar;
        ${ $uid . $user }{'userpic'} = q~<img src="~
          . (
              ${ $uid . $user }{'userpic'} =~ m/\A[\s\n]*https?:\/\//ism
            ? ${ $uid . $user }{'userpic'}
            : ( $default_avatar
                  && ${ $uid . $user }{'userpic'} eq $my_blank_avatar )
            ? "$imagesdir/$default_userpic"
            : "$facesurl/${$uid.$user}{'userpic'}"
          ) . q~" id="avatar_img_resize" alt="" style="display:none" />~;
        if ( !$iamguest ) {
            ${ $uid . $user }{'userpic'} =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}">${ $uid . $user }{'userpic'}</a>~;
        }
        ${ $uid . $user }{'userpic'} .= q~<br />~;
    }
    else {
        ${ $uid . $user }{'userpic'} = q~<br />~;
    }

    LoadMiniUser($user);

    $yyUDLoaded{$user} = 1;
    return 1;
}

sub LoadMiniUser {
    my ($user) = @_;
    my $load   = q{};
    my $key    = q{};
    $g = 0;
    my $dg = 0;
    my $tempgroup;
    my $bold   = 0;

    $tempgroupcheck = ${ $uid . $user }{'position'} || q{};

    my @memstat = ();
    if ( exists $Group{$tempgroupcheck} && $tempgroupcheck ne q{} ) {
        #(
        #    $title,     $stars,     $starpic,    $color,
        #    $noshow,    $viewperms, $topicperms, $replyperms,
        #    $pollperms, $attachperms
        #)
        @memstat = split /\|/xsm, $Group{$tempgroupcheck};
        $temptitle = $memstat[0];
        $tempgroup = $Group{$tempgroupcheck};
        if ( $memstat[4] == 0 ) { $bold = 1; }
        $memberunfo{$user} = $tempgroupcheck;
    }
    elsif ( $moderators{$user} ) {
        @memstat = split /\|/xsm, $Group{'Moderator'};
        $temptitle         = $memstat[0];
        $tempgroup         = $Group{'Moderator'};
        $memberunfo{$user} = $tempgroupcheck;
    }
    elsif ( exists $NoPost{$tempgroupcheck} && $tempgroupcheck ne q{} ) {
        @memstat = split /\|/xsm, $NoPost{$tempgroupcheck};
        $temptitle         = $memstat[0];
        $tempgroup         = $NoPost{$tempgroupcheck};
        $memberunfo{$user} = $tempgroupcheck;
    }

    if ( !$tempgroup ) {
        foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
            if ( ${ $uid . $user }{'postcount'} >= $postamount ) {
                @memstat = split /\|/xsm, $Post{$postamount};
                $tempgroup = $Post{$postamount};
                last;
            }
        }
        $memberunfo{$user} = $memstat[0];
    }

    if ( $memstat[4] == 1 ) {
        $temptitle = $memstat[0];
        foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
            if ( ${ $uid . $user }{'postcount'} > $postamount ) {
                @memstat = split /\|/xsm, $Post{$postamount}, 5;
                last;
            }
        }
    }

    if ( !$tempgroup ) {
        $temptitle   = 'no group';
        @memstat = ( q{}, 0, q{}, q{}, 1, q{}, q{}, q{}, q{}, q{} );
    }

# The following puts some new has variables in if this user is the user browsing the board
    if ( $user eq $username ) {
        if ($tempgroup) {
            (
                undef,     undef,      undef,       undef,
                undef,     $viewperms, $topicperms, $replyperms,
                $pollperms, $attachperms
            ) = split /\|/xsm, $tempgroup;
        }
        ${ $uid . $user }{'perms'} =
          "$viewperms|$topicperms|$replyperms|$pollperms|$attachperms";
    }

    $userlink = ${ $uid . $user }{'realname'} || $user;
    $userlink = qq~<b>$userlink</b>~;
    if   ( !$scripturl ) { $scripturl         = qq~$boardurl/$yyexec.$yyext~; }
    if   ( $bold != 1 )  { $memberinfo{$user} = qq~$memstat[0]~; }
    else                 { $memberinfo{$user} = qq~<b>$memstat[0]</b>~; }

    if ( $memstat[3] ne q{} && !$iamguest ) {
        $link{$user} =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}" style="color:$memstat[3];">$userlink</a>~;
        $format{$user} = qq~<span style="color: $memstat[3];">$userlink</span>~;
        $format_unbold{$user} =
          qq~<span style="color: $memstat[3];">${$uid.$user}{'realname'}</span>~;
        $col_title{$user} =
          qq~<span style="color: $memstat[3];">$memberinfo{$user}</span>~;
    }
    elsif ( $iamguest ) {
        if ( $memstat[3] ne q{} ) {
                $link{$user} =
qq~<span style="color:$memstat[3];">$userlink</span>~;
        $format{$user} = qq~<span style="color: $memstat[3];">$userlink</span>~;
        $format_unbold{$user} =
          qq~<span style="color: $memstat[3];">${$uid.$user}{'realname'}</span>~;
        $col_title{$user} =
          qq~<span style="color: $memstat[3];">$memberinfo{$user}</span>~;
        }
        else {
            $link{$user} = qq~$userlink~;
            $format{$user}        = qq~$userlink~;
            $format_unbold{$user} = qq~${$uid.$user}{'realname'}~;
            $col_title{$user}     = qq~$memberinfo{$user}~;
        }
    }
    else {
        $link{$user} =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$userlink</a>~;
        $format{$user}        = qq~$userlink~;
        $format_unbold{$user} = qq~${$uid.$user}{'realname'}~;
        $col_title{$user}     = qq~$memberinfo{$user}~;
    }
    $addmembergroup{$user} = '<br />';
    for my $addgrptitle ( split /,/xsm, ${ $uid . $user }{'addgroups'} ) {
        for my $key ( sort { $a <=> $b } keys %NoPost ) {
            (
                $atitle,     undef,       undef,        undef,
                $anoshow,    $aviewperms, $atopicperms, $areplyperms,
                $apollperms, $aattachperms
            ) = split /\|/xsm, $NoPost{$key};
            if ( $addgrptitle eq $key && $atitle ne $memstat[0] ) {
                if ( $user eq $username && !$iamadmin ) {
                    if ( $aviewperms == 1 )   { $viewperms   = 1; }
                    if ( $atopicperms == 1 )  { $topicperms  = 1; }
                    if ( $areplyperms == 1 )  { $replyperms  = 1; }
                    if ( $apollperms == 1 )   { $pollperms   = 1; }
                    if ( $aattachperms == 1 ) { $attachperms = 1; }
                    ${ $uid . $user }{'perms'} =
"$viewperms|$topicperms|$replyperms|$pollperms|$attachperms";
                }
                if (
                    $anoshow
                    && ( $iamadmin
                        || ( $iamgmod && $gmod_access2{'profileAdmin'} ) )
                  )
                {
                    $addmembergroup{$user} .= qq~($atitle)<br />~;
                }
                elsif ( !$anoshow ) {
                    $addmembergroup{$user} .= qq~$atitle<br />~;
                }
            }
        }
    }
    $addmembergroup{$user} =~ s/<br \/>\Z//sm;

    if ( $username eq 'Guest' ) { $memberunfo{$user} = 'Guest'; }

    $topicstart{$user} = q{};
    $viewnum = q{};
    if ( $INFO{'num'} || $FORM{'threadid'} && $user eq $username ) {
        if ( $INFO{'num'} ) {
            $viewnum = $INFO{'num'};
        }
        elsif ( $FORM{'threadid'} ) {
            $viewnum = $FORM{'threadid'};
        }
        if ( $viewnum =~ m{/}xsm ) {
            ( $viewnum, undef ) = split /\//xsm, $viewnum;
        }

        # No need to open the message file so many times.
        # Opening it once is enough to do the access checks.
        if ( !$topicstarter ) {
            if ( -e "$datadir/$viewnum.txt" ) {
                if ( !ref $thread_arrayref{$viewnum} ) {
                    fopen( TOPSTART, "$datadir/$viewnum.txt" );
                    @{ $thread_arrayref{$viewnum} } = <TOPSTART>;
                    fclose(TOPSTART);
                }
                ( undef, undef, undef, undef, $topicstarter, undef ) =
                  split /\|/xsm, ${ $thread_arrayref{$viewnum} }[0], 6;
            }
        }

        if ( $user eq $topicstarter ) { $topicstart{$user} = 'Topic Starter'; }
    }
    $memberaddgroup{$user} = ${ $uid . $user }{'addgroups'};

    my $starnum        = $memstat[1];
    my $memberstartemp = q{};
    if ( $memstat[2] !~ /\//xsm ) { $starpic = "$imagesdir/$memstat[2]"; }
    while ( $starnum-- > 0 ) {
        $memberstartemp .= qq~<img src="$starpic" alt="*" />~;
    }
    $memberstar{$user} = $memberstartemp ? "$memberstartemp<br />" : q{};
    return;
}

sub QuickLinks {
    my ( $user, $online ) = @_;
    my $lastonline;
    if ($iamguest) {
        return ( $online ? $format_unbold{$user} : $format{$user} );
    }

    if ( $iamadmin || $iamgmod || $lastonlineinlink ) {
        if ( ${ $uid . $user }{'lastonline'} ) {
            $lastonline = abs( $date - ${ $uid . $user }{'lastonline'} );
            my $days  = int( $lastonline / 86400 );
            my $hours = sprintf '%02d',
              int( ( $lastonline - ( $days * 86400 ) ) / 3600 );
            my $mins = sprintf
              '%02d',
              int(
                ( $lastonline - ( $days * 86400 ) - ( $hours * 3600 ) ) / 60 );
            my $secs = sprintf
              '%02d',
              ( $lastonline -
                  ( $days * 86400 ) -
                  ( $hours * 3600 ) -
                  ( $mins * 60 ) );
            if ( !$mins ) {
                $lastonline = "00:00:$secs";
            }
            elsif ( !$hours ) {
                $lastonline = "00:$mins:$secs";
            }
            elsif ( !$days ) {
                $lastonline = "$hours:$mins:$secs";
            }
            else {
                $lastonline = "$days $maintxt{'11'} $hours:$mins:$secs";
            }
            $lastonline =
              qq~ title="$maintxt{'10'} $lastonline $maintxt{'12'}."~;
        }
        else {
            $lastonline = qq~ title="$maintxt{'13'}."~;
        }
    }
    my $quicklinks;
    if ($usertools) {
        $qlcount++;
        my $modcol = is_moderator_b($user);
        if ( $modcol == 1 ) {
            @memstats = split /\|/xsm, $Group{'Moderator'};
        }
        my $display = 'display:inline';
        if ( $ENV{'HTTP_USER_AGENT'} =~ /opera/ism || $ENV{'HTTP_USER_AGENT'} =~ /firefox/ism ) {
            $display = 'display:inline-block';
        }

        $quicklinks = qq~<div style="position:relative;$display">
            <ul id="$useraccount{$user}$qlcount" class="QuickLinks" onmouseover="keepLinks('$useraccount{$user}$qlcount')" onmouseout="TimeClose('$useraccount{$user}$qlcount')">
                <li>~
          . userOnLineStatus($user) . qq~</li>\n~;
        if ( $user ne $username ) {
            $quicklinks .=
qq~             <li><a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$maintxt{'2'} ${$uid.$user}{'realname'}$maintxt{'3'}</a></li>\n~;
            CheckUserPM_Level($user);
            if (
                   $PM_level == 1
                || ( $PM_level == 2 && $UserPM_Level{$user} > 1 && $staff )
                || (   $PM_level == 3
                    && $UserPM_Level{$user} == 4
                    && ( $iamadmin || $iamgmod || $iamfmod ) )
                || (   $PM_level == 4
                    && $UserPM_Level{$user} == 3
                    && ( $iamadmin || $iamgmod ) )
              )
            {
                $quicklinks .=
qq~             <li><a href="$scripturl?action=imsend;to=$useraccount{$user}">$maintxt{'0'} ${$uid.$user}{'realname'}</a></li>\n~;
            }
            if ( !${ $uid . $user }{'hidemail'} || $iamadmin ) {
                $quicklinks .= '                <li>'
                  . enc_eMail(
                    "$maintxt{'1'} ${$uid.$user}{'realname'}",
                    ${ $uid . $user }{'email'},
                    q{}, q{}, 1
                  ) . "</li>\n";
            }

            if ( !%mybuddie ) { loadMyBuddy(); }
            if ( $buddyListEnabled && !$mybuddie{$user} ) {
                $quicklinks .=
qq~             <li><a href="$scripturl?action=addbuddy;name=$useraccount{$user}">$maintxt{'4'} ${$uid.$user}{'realname'} $maintxt{'5'}</a></li>\n~;
            }

        }
        else {

            $quicklinks .=
qq~             <li><a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$maintxt{'6'}</a></li>\n~;
        }
        $quicklinks .=
qq~         </ul><a href="javascript:quickLinks('$useraccount{$user}$qlcount')"$lastonline>~;
        $quicklinks .= $online ? $format_unbold{$user} : $format{$user};
        $quicklinks .= q~</a></div>~;
    }
    else {
        $quicklinks =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}"$lastonline>~
          . ( $online ? $format_unbold{$user} : $format{$user} )
          . q~</a>~;
    }

    return $quicklinks;
}

sub LoadTools {
    my ( $where, @buttons ) = @_;

    # Load Icon+Text for tool drop downs
    my @tools;

    if ( !%tmpimg ) { %tmpimg = %img; }
    require Sources::Menu;

    foreach my $i ( 0 .. $#buttons ) {
        $tools[$i] = SetImage( $buttons[$i], 3 );
    }

    foreach my $i ( 0 .. $#tools ) {
        my ( $img_url, $img_txt ) = split /\|/xsm, $tools[$i];
        $tools[$i] =
qq~[tool=$buttons[$i]]<div class="toolbutton_a" style="background-image: url($img_url)">$img_txt</div>[/tool]~;
    }

    foreach my $i ( 0 .. $#tools ) {
        $img{ $buttons[$i] } = $tools[$i];
    }
    return;
}

sub MakeTools {
    my ( $counter, $text, $template ) = @_;
    my $list_item = '</li><li>';
    $template = qq~<li>$template</li>~;
    $template =~ s/\|\|\|/$list_item/gsm;
    $template =~ s/<li>[\s]*<\/li>//gsm;
    if ( $MenuType == 1 ) {
        $template =~ s/\Q$menusep//gsm;
    }

    my $tools_template = $template
      ? qq~
    <div class="post_tools_a">
        <a href="javascript:quickLinks('threadtools$counter')">$text</a>
    </div>
    </td>
    <td class="center bottom" style="padding:0px; width:0">
    <div class="right cursor toolbutton_b">
        <ul class="post_tools_menu" id="threadtools$counter" onmouseover="keepLinks('threadtools$counter')" onmouseout="TimeClose('threadtools$counter')">
            $template
        </ul>
    </div>
    ~
      : qq~<div class="post_tools_a">$load_con{'actionslock'}</div></td><td class="center bottom" style="padding:0px; width:0">~;
    $tools_template =~ s/{yabb actionlock}/$maintxt{'64'}/gsm;

    return $tools_template;
}

sub LoadCookie {
    foreach ( split /; /sm, $ENV{'HTTP_COOKIE'} ) {
        $_ =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/egxsm;
        ( $cookie, $value ) = split /=/xsm;
        $yyCookies{$cookie} = $value;
    }
    if ( $yyCookies{$cookiepassword} ) {
        $password      = $yyCookies{$cookiepassword};
        $username      = $yyCookies{$cookieusername} || 'Guest';
        $cookiesession = $yyCookies{$session_id};
    }
    else {
        $password = q{};
        $username = 'Guest';
    }
    if (   $yyCookies{'guestlanguage'}
        && !$FORM{'guestlang'}
        && $enable_guestlanguage )
    {
        opendir DIR, $langdir;
        my @langDir = readdir DIR;
        closedir DIR;
        @lang = ();
        foreach my $langitems ( sort { lc($a) cmp lc $b } @langDir ) {
            chomp $langitems;
            if (   ( $langitems ne q{.} )
                && ( $langitems ne q{..} )
                && ( $langitems ne q{.htaccess} )
                && ( $langitems ne q{index.html} ) )
            {
                push @lang, $langitems;
            }
        }

        $ccheck = 0;
        $clang  = q{};
        for my $lng (@lang) {
            if ( $yyCookies{'guestlanguage'} eq $lng ) {
                $clang  = $lng;
                $ccheck = 1;
                last;
            }
        }
        if ( $ccheck == 1 ) {
            $language = $guestLang = $clang;
        }
    }
    return;
}

sub guestLangcc {
    opendir DIR, $langdir;
    my @langDir = readdir DIR;
    closedir DIR;
    @lang = ();
    foreach my $langitems ( sort { lc($a) cmp lc $b } @langDir ) {
        chomp $langitems;
        if (   ( $langitems ne q{.} )
            && ( $langitems ne q{..} )
            && ( $langitems ne q{.htaccess} )
            && ( $langitems ne q{index.html} ) )
        {
            push @lang, $langitems;
        }
    }
    return \@lang;
}

sub UpdateCookie {
    my ( $what, $user, $passw, $sessionval, $pathval, $expire ) = @_;
    my ( $valid, $expiration );
    if ( $what eq 'delete' ) {
        $expiration = 'Thursday, 01-Jan-1970 00:00:00 GMT';
        if ( $pathval eq q{} ) { $pathval = q~/~; }
        if ( $iamguest && $FORM{'guestlang'} && $enable_guestlanguage ) {
            if ( $FORM{'guestlang'} && !$guestLang ) {
                $guestLang = qq~$FORM{'guestlang'}~;
            }
            $language       = qq~$guestLang~;
            $cookiepassword = 'guestlanguage';
            $passw          = qq~$language~;
            $expire         = 'persistent';
        }
        $valid = 1;
    }
    elsif ( $what eq 'write' ) {
        $expiration = $expire;
        if ( $pathval eq q{} ) { $pathval = q~/~; }
        $valid = 1;
    }

    if ($valid) {
        if ( $expire eq 'persistent' ) {
            $expiration = 'Sunday, 17-Jan-2038 00:00:00 GMT';
        }
        $yySetCookies1 = write_cookie(
            -name    => "$cookieusername",
            -value   => "$user",
            -path    => "$pathval",
            -expires => "$expiration"
        );
        $yySetCookies2 = write_cookie(
            -name    => "$cookiepassword",
            -value   => "$passw",
            -path    => "$pathval",
            -expires => "$expiration"
        );
        $yySetCookies3 = write_cookie(
            -name    => "$cookiesession_name",
            -value   => "$sessionval",
            -path    => "$pathval",
            -expires => "$expiration"
        );

        my $adminpass   = 'adminpass';
        my $admincookie = "$cookieusername$adminpass";
        if ( $yyCookies{$admincookie} ) {
            push @otherCookies,
              write_cookie(
                -name    => "$admincookie",
                -value   => q{},
                -path    => q{/},
                -expires => 'Thursday, 01-Jan-1970 00:00:00 GMT'
              );
            $yyCookies{$admincookie} = q{};
        }

        foreach my $catid (@categoryorder) {
            if ( !$catid ) { next; }
            my $boardlist = $cat{$catid};
            my @bdlist = split /\,/xsm, $boardlist;
            foreach my $curboard (@bdlist) {
                chomp $curboard;
                my $tsortcookie = "$cookietsort$curboard$username";
                if ( $yyCookies{$tsortcookie} ) {
                    push @otherCookies,
                      write_cookie(
                        -name    => "$tsortcookie",
                        -value   => q{},
                        -path    => q{/},
                        -expires => 'Thursday, 01-Jan-1970 00:00:00 GMT'
                      );
                    $yyCookies{$tsortcookie} = q{};
                }
                my $cookiename = "$cookiepassword$curboard$username";
                if ( $yyCookies{$cookiename} ) {
                    push @otherCookies,
                      write_cookie(
                        -name    => "$cookiename",
                        -value   => q{},
                        -path    => q{/},
                        -expires => 'Thursday, 01-Jan-1970 00:00:00 GMT'
                      );
                    $yyCookies{$cookiename} = q{};
                }
            }
        }
    }
    return;
}

sub LoadAccess {
    $yesaccesses .= "$load_txt{'805'} $load_txt{'806'} $load_txt{'808'}<br />";
    $noaccesses = q{};

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

    # Topic Check
    my $tcaccess = AccessCheck( $currentboard, 1 ) || 0;
    if ( $tcaccess eq 'granted' ) {
        $yesaccesses .=
          "$load_txt{'805'} $load_txt{'806'} $load_txt{'810'}<br />";
    }
    else {
        $noaccesses .=
          "$load_txt{'805'} $load_txt{'807'} $load_txt{'810'}<br />";
    }

    # Poll Check
    my $access = AccessCheck( $currentboard, 3 ) || 0;
    if ( $access eq 'granted' ) {
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

    $accesses = qq~$yesaccesses<br />$noaccesses~;
    return $accesses;
}

sub WhatTemplate {
    $found = 0;
    while ( ( $curtemplate, $value ) = each %templateset ) {
        if ( $curtemplate eq $default_template ) {
            $template = $curtemplate;
            $found    = 1;
        }
    }
    if ( !$found ) { $template = 'Forum default'; }
    if ( ${ $uid . $username }{'template'} ne q{} ) {
        if ( !exists $templateset{ ${ $uid . $username }{'template'} } ) {
            ${ $uid . $username }{'template'} = 'Forum default';
            UserAccount( $username, 'update' );
        }
        while ( ( $curtemplate, $value ) = each %templateset ) {
            if ( $curtemplate eq ${ $uid . $username }{'template'} ) {
                $template = $curtemplate;
            }
        }
    }
    (
        $usestyle,       $useimages,  $usehead,     $useboard,
        $usemessage,     $usedisplay, $usemycenter, $UseMenuType,
        $useThreadtools, $usePosttools,
    ) = split /\|/xsm, $templateset{$template};

    if ( !-e "$htmldir/Templates/Forum/$usestyle.css" ) {
        $usestyle = 'default';
    }
    if ( !-e "$templatesdir/$usehead/$usehead.html" ) { $usehead = 'default'; }
    if ( !-e "$templatesdir/$useboard/BoardIndex.template" ) {
        $useboard = 'default';
    }
    if ( !-e "$templatesdir/$usemessage/MessageIndex.template" ) {
        $usemessage = 'default';
    }
    if ( !-e "$templatesdir/$usedisplay/Display.template" ) {
        $usedisplay = 'default';
    }
    if ( !-e "$templatesdir/$usemycenter/MyCenter.template" ) {
        $usemycenter = 'default';
    }

    if ( $UseMenuType eq q{} ) { $UseMenuType = $MenuType; }
    if ( $useThreadtools eq q{} ) { $useThreadtools = $threadtools; }
    if ( $usePosttools eq q{} ) { $usePosttools = $posttools; }

    if ( -d "$htmldir/Templates/Forum/$useimages" ) {
        $imagesdir = "$yyhtml_root/Templates/Forum/$useimages";
    }
    else { $imagesdir = "$yyhtml_root/Templates/Forum/default"; }
    $defaultimagesdir = "$yyhtml_root/Templates/Forum/default";

    $extpagstyle =~ s/$usestyle\///gxsm;
    return;
}

sub WhatLanguage {
    if ( ${ $uid . $username }{'language'} ne q{} ) {
        $language = ${ $uid . $username }{'language'};
    }
    elsif ( $FORM{'guestlang'} && $enable_guestlanguage ) {
        $language = $FORM{'guestlang'};
    }
    elsif ( $guestLang && $enable_guestlanguage ) {
        $language = $guestLang;
    }
    else {
        $language = $lang;
    }

    LoadLanguage('Main');
    LoadLanguage('Menu');

    if ($adminscreen) {
        LoadLanguage('Admin');
        LoadLanguage('FA');
    }
    return;
}

sub buildIMS {
    my ( $builduser, $job ) = @_;
    my ( $incurr, $inunr, $outcurr, $draftcount, @imstore, $storetotal,
        @storefoldersCount, $storeCounts );

    if ($job) {
        if ( $job eq 'load' ) {
            load_IMS($builduser);
        }
        else {
            update_IMS($builduser);
        }
        return;
    }

    ## inbox if it exists, either load and count totals or parse and update format.
    if ( -e "$memberdir/$builduser.msg" ) {
        fopen( USERMSG, "$memberdir/$builduser.msg" )
          or fatal_error( 'cannot_open', "$memberdir/$builduser.msg", 1 );

        # open inbox
        my @messages = <USERMSG>;
        fclose(USERMSG);

  # test the data for version. 16 elements in new format, no more than 8 in old.
        foreach my $message (@messages) {

            # If the message is flagged as u(nopened), add to the new count
            if ( ( split /\|/xsm, $message )[12] =~ /u/sm ) { $inunr++; }
        }
        $incurr = @messages;

    }

    ## do the outbox
    if ( -e "$memberdir/$builduser.outbox" ) {
        fopen( OUTMESS, "$memberdir/$builduser.outbox" )
          or fatal_error( 'cannot_open', "$memberdir/$builduser.outbox", 1 );
        my @outmessages = <OUTMESS>;
        fclose(OUTMESS);
        $outcurr = @outmessages;
    }

    if ( -e "$memberdir/$builduser.imdraft" ) {
        fopen( DRAFTMESS, "$memberdir/$builduser.imdraft" )
          or fatal_error( 'cannot_open', "$memberdir/$builduser.imdraft", 1 );
        my @d = <DRAFTMESS>;
        fclose(DRAFTMESS);
        $draftcount = @d;
    }

    ## grab the current list of store folders
    ## else, create an entry for the two 'default ones' for the in/out status stuff
    my $storefolders = ${$builduser}{'PMfolders'} || 'in|out';
    my @currStoreFolders = split /\|/xsm, $storefolders;
    if ( -e "$memberdir/$builduser.imstore" ) {
        fopen( STOREMESS, "$memberdir/$builduser.imstore" )
          or fatal_error( 'cannot_open', "$memberdir/$builduser.imstore", 1 );
        @imstore = <STOREMESS>;
        fclose(STOREMESS);
        if (@imstore) {
            my ( $storeUpdated, $storeMessLine ) = ( 0, 0 );
            foreach my $message (@imstore) {
                my @messLine = split /\|/xsm, $message;
                ## look through list for folder name
                if ( $messLine[13] eq q{} )
                {    # some folder missing within imstore
                    if ( $messLine[1] ne q{} ) {    # 'from' name so inbox
                        $messLine[13] = 'in';
                    }
                    else {                          # no 'from' so outbox
                        $messLine[13] = 'out';
                    }
                    $imstore[$storeMessLine] = join q{|}, @messLine;
                    $storeUpdated = 1;
                }
                if ( $storefolders !~ /\b$messLine[13]\b/sm ) {
                    push @currStoreFolders, $messLine[13];
                    $storefolders = join q{|}, @currStoreFolders;
                }
                $storeMessLine++;
            }
            if ( $storeUpdated == 1 ) {
                fopen( STRMESS, "+>$memberdir/$builduser.imstore" )
                  or fatal_error( 'cannot_open',
                    "$memberdir/$builduser.imstore", 1 );
                print {STRMESS} @imstore or croak "$croak{'print'} STRMESS";
                fclose(STRMESS);
            }
            $storetotal = @imstore;
            $storefolders = join q{|}, @currStoreFolders;

        }
        else {
            unlink "$memberdir/$builduser.imstore";
        }
    }
    ## run through the messages and count against the folder name
    for my $y ( 0 .. ( @currStoreFolders - 1 ) ) {
        $storefoldersCount[$y] = 0;
        for my $x ( 0 .. ( @imstore - 1 ) ) {
            if ( ( split /\|/xsm, $imstore[$x] )[13] eq $currStoreFolders[$y] )
            {
                $storefoldersCount[$y]++;
            }
        }
    }
    $storeCounts = join q{|}, @storefoldersCount;

    LoadBroadcastMessages($builduser);

    ${$builduser}{'PMmnum'}         = $incurr      || 0;
    ${$builduser}{'PMimnewcount'}   = $inunr       || 0;
    ${$builduser}{'PMmoutnum'}      = $outcurr     || 0;
    ${$builduser}{'PMdraftnum'}     = $draftcount  || 0;
    ${$builduser}{'PMstorenum'}     = $storetotal  || 0;
    ${$builduser}{'PMfolders'}      = $storefolders;
    ${$builduser}{'PMfoldersCount'} = $storeCounts || 0;
    update_IMS($builduser);
    return;
}

sub update_IMS {
    my $builduser = shift;
    my @tag =
      qw(PMmnum PMimnewcount PMmoutnum PMstorenum PMdraftnum PMfolders PMfoldersCount PMbcRead);

    fopen( UPDATE_IMS, ">$memberdir/$builduser.ims", 1 )
      or fatal_error( 'cannot_open', "$memberdir/$builduser.ims", 1 );
    print {UPDATE_IMS} qq~### UserIMS YaBB 2.6.11 Version ###\n\n~
      or croak "$croak{'print'} update IMS";
    for my $cnt ( 0 .. ( @tag - 1 ) ) {
        print {UPDATE_IMS} qq~'$tag[$cnt]',"${$builduser}{$tag[$cnt]}"\n~
          or croak "$croak{'print'} update IMS";
    }
    fclose(UPDATE_IMS);
    return;
}

sub load_IMS {
    my $builduser = shift;
    my @ims;
    if ( -e "$memberdir/$builduser.ims" ) {
        fopen( IMSFILE, "$memberdir/$builduser.ims" )
          or fatal_error( 'cannot_open', "$memberdir/$builduser.ims", 1 );
        @ims = <IMSFILE>;
        fclose(IMSFILE);
    }

    if ( $ims[0] =~ /###/xsm ) {
        foreach (@ims) {
            if ( $_ =~ /'(.*?)',"(.*?)"/xsm ) { ${$builduser}{$1} = $2; }
        }
    }
    else {
        buildIMS( $builduser, q{} );
    }
    return;
}

sub LoadBroadcastMessages {    #check broadcast messages
    return
      if ( $iamguest
        || $PM_level == 0
        || ( $maintenance   && !$iamadmin )
        || ( $PM_level == 2 && ( !$staff ) )
        || ( $PM_level == 3 && ( !$iamadmin && !$iamgmod ) )
        || ( $PM_level == 4 && ( !$iamadmin && !$iamgmod && !$iamfmod ) ) );

    my $builduser = shift;
    $BCnewMessage = 0;
    $BCCount      = 0;
    if ( -e "$memberdir/broadcast.messages" ) {
        my %PMbcRead;
        map { $PMbcRead{$_} = 1; } split /,/xsm, ${$builduser}{'PMbcRead'};

        fopen( BCMESS, "<$memberdir/broadcast.messages" )
          or fatal_error( 'cannot_open', "$memberdir/broadcast.messages", 1 );
        my @bcmessages = <BCMESS>;
        fclose(BCMESS);
        foreach (@bcmessages) {
            my ( $mnum, $mfrom, $mto, undef ) = split /\|/xsm, $_, 4;
            if ( $mfrom eq $username ) { $BCCount++; $PMbcRead{$mnum} = 1; }
            elsif ( BroadMessageView($mto) ) {
                $BCCount++;
                if ( exists $PMbcRead{$mnum} ) { $PMbcRead{$mnum} = 1; }
                else                           { $BCnewMessage++; }
            }
        }
        ${$builduser}{'PMbcRead'} = q{};
        foreach ( keys %PMbcRead ) {
            if ( $PMbcRead{$_} ) {
                ${$builduser}{ 'PMbcRead' . $_ } = 1;
                ${$builduser}{'PMbcRead'} .=
                  ${$builduser}{'PMbcRead'} ? ",$_" : $_;
            }
        }
    }
    else {
        ${$builduser}{'PMbcRead'} = q{};
    }
    return;
}

1;
