###############################################################################
# NewSettings.pm                                                              #
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
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$newsettingspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

# Figure out what tabset to use, depending on the page= parameter.
my %settings_dispatch = (
    news        => "$admindir/Settings_News.pm",
    main        => "$admindir/Settings_Main.pm",
    advanced    => "$admindir/Settings_Advanced.pm",
    security    => "$admindir/Settings_Security.pm",
    antispam    => "$admindir/Settings_Antispam.pm",
    maintenance => "$admindir/Settings_Maintenance.pm",

    ### BOARDMOD SETTINGS ANCHOR ###
    ### ADD BEFORE THESE LINES   ###
);

my $page = $INFO{'page'};

# 'eval' because NewSettings.pm can be called by Sources/TabMenu.pm
eval { require $settings_dispatch{$page}; };

sub settings {
    is_admin_or_gmod();

    $yytitle =
      $page eq 'main' ? $admin_txt{'222'}
      : (
        $page eq 'advanced' ? $admin_txt{'223'}
        : (
            $page eq 'security' ? $admintxt{'a3_title'}
            : (
                $page eq 'antispam' ? $admintxt{'a3_sub4'}
                : (
                      $page eq 'maintenance' ? $admintxt{'a7_title'}
                    : $admintxt{'a2_sub1'}
                )
            )
        )
      );

    my @requireorder;    # an array for the correct order of the requirements
    my %requirements;    # a hash that says "Y is required by X"

    $yymain .= qq~
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom:.5em">
            <tr>
                <td class="titlebg"><b>$yytitle</b></td>
            </tr><tr>
                <td class="windowbg2">
                    <div class="pad-more">$admin_txt{'347'}</div>
                </td>
            </tr>
        </table>
    </div>
<form action="$adminurl?action=newsettings2;page=$page" onsubmit="undisableAll(this); savealert()" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
    <ul id="navlist">
~;
    my $i = 0;
    foreach my $tab (@settings) {
        $tab->{'name'} =~ s/ /&nbsp;/gsm;

        # The &nbsp;'s are for Konqueror, and also to add a little more padding.
        $yymain .=
qq~                <li id="button_$tab->{'id'}" onclick="changeToTab('$tab->{'id'}'); return false;">&nbsp;<a href="#tab_$tab->{'id'}">$tab->{'name'}</a>&nbsp;</li>
~;
    }
    $yymain .= q~  </ul>~;

    foreach my $tab (@settings) {
        $yymain .= qq~
    <div class="bordercolor borderstyle rightboxdiv">
        <table class="section" style="border-collapse:separate; border-spacing: 1px;" id="tab_$tab->{'id'}">
            <colgroup>
                <col span="2" style="width: 50%" />
            </colgroup>
            <tr>
                <td class="titlebg padd-cell" colspan="2">
                    $admin_img{'prefimg'} <b>$tab->{'name'}</b>
         <span style="float: right;" class="js_remove_me"><a href="#"><b>$settings_txt{'top'}</b></a></span>
       </td>
     </tr>~;

        foreach my $item ( @{ $tab->{'items'} } ) {
            if ( $item->{'header'} ) {
                $yymain .= qq~<tr>
         <td class="catbg padd-cell" colspan="2"><span class="small">$item->{'header'}</span></td>
     </tr>~;
            }
            elsif ( $item->{'two_rows'} && $item->{'input_html'} ) {
                $yymain .= qq~<tr>
                <td class="windowbg2 padd-cell" colspan="2">$item->{'description'}</td>
            </tr><tr>
                <td class="windowbg2 padd-cell" colspan="2">$item->{'input_html'}</td>
     </tr>~;
            }
            elsif ( $item->{'input_html'} ) {
                $yymain .= qq~<tr>
                <td class="windowbg2 vtop padd-cell">$item->{'description'}</td>
                <td class="windowbg2 vtop padd-cell">$item->{'input_html'}</td>
     </tr>~;
            }

            # Handle settings that require other settings
            if ( $item->{'depends_on'} && $item->{'name'} ) {
                foreach my $require ( @{ $item->{'depends_on'} } ) {

# This is somewhat messy, but it works well.
# We strip off the possible options: inverse, equal, and not equal
# Then we attach those to this current option in the detailed string for requirements
# While this data does not really belong with the value, it transfers nicely.
# We then remove it and reuse it later.
                    my ( $inverse, $realname, $remainder ) =
                      $require =~ m{(\(?\!?)(\w+)(.*)}xsm;
                    if ( !$requirements{$realname} ) {
                        push @requireorder, $realname;
                    }
                    push
                      @{ $requirements{$realname} },
                      $inverse . $item->{'name'} . $remainder;
                }
            }
        }

        $yymain .= q~
   </table>
  </div>~;
    }

# The old method isn't quite good enough.
# So we build a hash with the Javascript logic needed to determine if this item should be enabled.
# When in doubt, generate some code :)
    my %requirejs;

    my $dependicies = q{};
    my $onloadevents;
    foreach my $ritem (@requireorder) {
        $dependicies .= qq~
    function handleDependent_$ritem() {
        var isChecked = document.getElementsByName("$ritem")[0].checked;
        var itemValue = document.getElementsByName("$ritem")[0].value;\n~;

        foreach my $require ( @{ $requirements{$ritem} } ) {

            # && or ||, ( and )
            my $AndOr = $require =~ s/\)//xsm ? ')' : q{};
            $AndOr .= $require =~ s/\|\|//xsm ? ' ||' : ' &&';
            my $C = $require =~ s/\(//xsm ? '(' : q{};

            # Is false
            if ( $require =~ s/^\!//xsm ) {
                $requirejs{$require} .=
qq~$C\!document.getElementsByName("$ritem")[0].checked$AndOr ~;
            }

            # Is equal to
            elsif ( $require =~ s/\=\=(.*)$//xsm ) {
                $requirejs{$require} .=
qq~$C\document.getElementsByName("$ritem")[0].value == '$1'$AndOr ~;
            }

            # Is not equal to
            elsif ( $require =~ s/\!\=(.*)$//xsm ) {
                $requirejs{$require} .=
qq~$C\document.getElementsByName("$ritem")[0].value != '$1'$AndOr ~;
            }

            # Is true
            else {
                $requirejs{$require} .=
                  qq~$C\document.getElementsByName("$ritem")[0].checked$AndOr ~;
            }
            $dependicies .= qq~        checkDependent("$require");\n~;
        }
        $dependicies .= qq~ }
    document.getElementsByName("$ritem")[0].onclick = handleDependent_$ritem;
    document.getElementsByName("$ritem")[0].onkeyup = handleDependent_$ritem;
~;
        $onloadevents .= qq~handleDependent_$ritem(); ~;
    }

    # Hidden "feature": jump directly to a tab by default via the URL bar.
    $INFO{'tab'} =~ s/\W//gxsm;
    $default_tab = $INFO{'tab'} || $settings[0]->{'id'};
    $yymain .= qq~
<div class="bordercolor rightboxdiv" style="margin: .5em auto 0 0">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg" colspan="2">$admin_img{'prefimg'} <b>$admin_txt{'10'}</b></td>
        </tr><tr>
            <td class="catbg center" colspan="2">
                <input class="button" type="submit" value="$admin_txt{'10'}" />
            </td>
        </tr>
   </table>
  </div>
  </form>
  <script type="text/javascript">
    function getElementsByClass(searchClass,node,tag) {
        var classElements = new Array();
        if ( node === null || node === undefined )
            node = document;
        if ( tag === null || tag === undefined )
            tag = '*';
        var els = node.getElementsByTagName(tag);
        var elsLen = els.length;
        var pattern = new RegExp('(^|\\s)'+searchClass+'(\\s|\$)');
        for (i = 0, j = 0; i < elsLen; i++) {
            if ( pattern.test(els[i].className) ) {
                classElements[j] = els[i];
                j++;
            }
        }
        return classElements;
    }
    function changeToTab(tab) {
        var elements = getElementsByClass('section');
        var i;
        for(i = 0; i < elements.length; i++) {
            if(elements[i].id == 'tab_' + tab) {
                elements[i].style.display = '';
            }
            else {
                elements[i].style.display = 'none';
            }
        }
        var elm = getElementsByClass('curtab')[0];
        if(elm) {
            elm.className = '';
        }
        document.getElementById('button_' + tab).className = 'curtab';
    }
    var removables = getElementsByClass('js_remove_me');
    var i;
    for(i = 0; i < removables.length; i++) {
        removables[i].innerHTML = '';
    }
    changeToTab('$default_tab'); // Focus default tab
    function checkDependent(eid) {
        var elm = document.getElementsByName(eid)[0];\n~;

    # Loop through each item that depends on something else
    foreach my $name ( keys %requirejs ) {
        my $logic = $requirejs{$name};
        $logic =~ s/ (&&|\|\|) $//sm;
        $yymain .= qq~
        if (eid == "$name" && ($logic)) {
            elm.disabled = false;
        } else if (eid == "$name") {
            elm.disabled = true;
        }\n~;
    }

    $yymain .= qq~
    }
$dependicies
    window.onload = function(){ $onloadevents};
    function undisableAll(node) {
        var elements = document.getElementsByTagName("input");
        for(var i = 0; i < elements.length; i++) {
            elements[i].disabled = false;
        }
        elements = document.getElementsByTagName("textarea");
        for( i = 0; i < elements.length; i++) {
            elements[i].disabled = false;
        }
        elements = document.getElementsByTagName("select");
        for( i = 0; i < elements.length; i++) {
            elements[i].disabled = false;
        }
    }
  </script>~;

    $action_area = "newsettings;page=$page";
    AdminTemplate();
    return;
}

sub ischecked {
    my ($inp) = @_;

    # Return a ref so we can be used like ${ischecked($var)} inside a string
    return \' checked="checked"' if $inp;
    return \q{};
}

sub isselected {
    my ($inp) = @_;

    # Return a ref so we can be used like ${isselected($var)} inside a string
    return \' selected="selected"' if $inp;
    return \q{};
}

# Regexes. Will be used like this: $var =~ /^(?:$regexes{'a'}|$regexes{'b'}|$regexes{'c'})$/ || die;
my %regexes = (
    boolean =>
      q{.*},    # anything. True is not 0 and defined, false is 0/undefined
    number     => '\d+',               # just numbers
    fullnumber => '(?:\+|\-|)[\d\.]+', # optional sign, plus numbers and decimal
    hexadecimal => '#?[0-9a-fA-F]+',

    # optional "#" (for hex color codes), plus hex characters
    alpha    => '[a-zA-Z]+',           # Letters
    text     => '[^\n\r]+',            # Anything but newlines
    fulltext => '(?s).+',              # Anything, including newlines
    null     => q{},

# Use this if something can be false, in addition to the normal valid characters (not needed for boolean)
);

# Preserve the traditional "2" name as well as the nicer SaveSettings.
sub settings2 {
    is_admin_or_gmod();

    # Load/Verify the settings
    foreach my $tab (@settings) {
        foreach my $item ( @{ $tab->{'items'} } ) {

            # Get the value
            my $name = $item->{'name'} || next;    # Skip non-items
            $settings{$name} = $FORM{$name};
            if ( !defined $settings{$name} ) { $settings{$name} = q{}; }

            $settings{$name} =~ s/^\s+//xsm;
            $settings{$name} =~ s/\s+$//xsm;

            # Validate it
            if ( $item->{'validate'} ) {

                # Handle numbers/nulls better (empty string is 0)
                if (   $item->{'validate'} =~ /null/sm
                    && $item->{'validate'} =~ /number/sm )
                {
                    $settings{$name} ||= 0;
                }

                # Handle text/nulls better (empty string is empty string :)
                if (   $item->{'validate'} =~ /null/sm
                    && $item->{'validate'} =~ /text/sm )
                {
                    $settings{$name} ||= q{};
                }

# Piece together the patterns. It only needs to validate 1 pattern, but the pattern must be the whole string.
                my $pattern = '^(?:'
                  . join( q{|}, @regexes{ split /,/xsm, $item->{'validate'} } )
                  . ')$';
                if ( $settings{$name} !~ /$pattern/sm ) {
                    fatal_error( 'invalid_value',
                        qq~$name ($item->{'description'})~ );
                }

                # Set numeric options to 0 if they are null
                if ( $item->{'validate'} eq 'boolean' ) {
                    $settings{$name} = $settings{$name} ? 1 : 0;
                }
            }
        }
    }

# Save them, as according to this type of settings
# This subroutine resides in the file that is loaded in the hash at the top of the file.
    SaveSettings(%settings);
    $yySetLocation = "$adminurl?action=newsettings;page=$page";
    redirectexit();
    return;
}

# Subroutine for saving to Settings.pm
sub SaveSettingsTo {
    my $file     = shift;
    my %settings = @_;

    # these cannot be reversed per Perl Critic.

    # This is why we should use hashes for options to begin with.
    foreach my $key ( keys %settings ) {
        ${$key} = delete $settings{$key};
    }

    if ( $codemaxchars > 15 ) { $codemaxchars = 15; }
    my $setfile;
    if ( $file eq 'Settings.pm' ) {
        $fadertext       ||= $color{'fadertext'};
        $faderbackground ||= $color{'faderbg'};

        my $templateset = join q{},
          map { qq~'$_' => "$templateset{$_}",\n~; } keys %templateset;

        if (@ext_prof_order) {
            $ext_prof_order = q{"} . join( q{","}, @ext_prof_order ) . q{"};
        }
        if (@ext_prof_fields) {
            $ext_prof_fields =
              q{"} . join( qq~",\n"~, @ext_prof_fields ) . q{"};
        }

        my $member_groups = "# Static Member Groups\n";
        foreach ( keys %Group ) {
            $member_groups .= qq~\$Group{'$_'} = '$Group{$_}';\n~;
        }
        $member_groups .= "\n# Post independent Member Groups\n";
        foreach ( keys %NoPost ) {
            $member_groups .= qq~\$NoPost{'$_'} = '$NoPost{$_}';\n~;
        }
        $member_groups .= "\n# Post dependent Member Groups\n";
        foreach ( keys %Post ) {
            $member_groups .= qq~\$Post{'$_'} = '$Post{$_}';\n~;
        }

        if (@pallist) { $pallist = q{"} . join( q{","}, @pallist ) . q{"}; }

        if ( $INFO{'page'} eq 'main' ) {
            if ( !$enable_notifications_N ) {
                if ( !$enable_notifications_PM ) {
                    $enable_notifications = 0;
                }
                elsif ($enable_notifications_PM) {
                    $enable_notifications = 2;
                }
            }
            elsif ($enable_notifications_N) {
                if ( !$enable_notifications_PM ) {
                    $enable_notifications = 1;
                }
                elsif ($enable_notifications_PM) {
                    $enable_notifications = 3;
                }
            }
        }

        my $AdvancedTabs = q{"} . join( q{","}, @AdvancedTabs ) . q{"};

        if (@SmilieURL) {
            $SmilieURL = q{"} . join( q{","}, @SmilieURL ) . q{"};
        }
        if (@SmilieCode) {
            $SmilieCode = q{"} . join( q{","}, @SmilieCode ) . q{"};
        }
        if (@SmilieDescription) {
            $SmilieDescription =
              q{"} . join( q{","}, @SmilieDescription ) . q{"};
        }
        if (@SmilieLinebreak) {
            $SmilieLinebreak = q{"} . join( q{","}, @SmilieLinebreak ) . q{"};
        }

        my $backup_paths = join q{ }, @backup_paths;

        $smtp_server =~ s/^\s+|\s+$//gxsm;

        $setfile = << "EOF";
###############################################################################
# Settings.pm                                                                 #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Open-Source Community Software for Webmasters                               #
# Version:        YaBB 2.6.11                                                 #
# Packaged:       December 2, 2014                                            #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2014  YaBB (www.yabbforum.com) - All Rights Reserved.    #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
###############################################################################

########## Board Info ##########
# Note: these settings must be properly changed for YaBB to work

\$settings_file_version = "$YaBBversion";
# If not equal actual YaBBversion then the updating process is run through
\$yymycharset = '$yymycharset';                 # character encoding (usually ISO-8859-1 for older forums)
                                            # or 'UTF-8';

\%templateset = ($templateset);             # Forum templates settings

\$maintenance = $maintenance;               # Set to 1 to enable Maintenance mode
\$rememberbackup = $rememberbackup;         # seconds past since last backup until alert is displayed
\$maintenancetext = "\Q$maintenancetext\E"; # Admin-defined text for Maintenance mode

\$guestaccess = $guestaccess;               # Set to 0 to disallow guests from doing anything but login or register

\$mbname = "\Q$mbname\E";                   # The name of your YaBB forum
\$forumstart = "\Q$forumstart\E";           # The start date of your YaBB Forum
\$Cookie_Length = $Cookie_Length;           # Default minutes to set login cookies to stay for
\$cookieusername = "\Q$cookieusername\E";   # Name of the username cookie
\$cookiepassword = "\Q$cookiepassword\E";   # Name of the password cookie
\$cookiesession_name = "\Q$cookiesession_name\E";   # Name of the Session cookie
\$cookietsort = "\Q$cookietsort\E";   # Name of the message Index sort cookie
\$cookieview = "\Q$cookieview\E";           # Name of the Guest Message Limit cookie
\$cookieviewtime = $cookieviewtime;         # life time for Guest Message Limit cookie
\$screenlogin = $screenlogin;                # allow members to login using their screen name.

\$regtype = $regtype;                       # 0 = registration closed (only admin can register), 1 = pre registration with admin approval,
                                    # 2 = pre registration and email activation, 3 = open registration
\$RegAgree = $RegAgree;                     # 0 = Don't show registration agreement, 1 = Show registration agreement before registration form, 2 = Show registration agreement on registration form
\$imp_email_check = $imp_email_check;    # Set to 1 to enable improved e-mail check
\$RegReasonSymbols = $RegReasonSymbols;         # Maximum allowed symbols in User reason(s) for registering
\$preregspan = $preregspan;                 # Time span in hours for users to account activation before cleanup
\$pwstrengthmeter_scores = "\Q$pwstrengthmeter_scores\E";   # Password-Strength-Meter Scores
\$pwstrengthmeter_common = "\Q$pwstrengthmeter_common\E";   # Password-Strength-Meter common words
\$pwstrengthmeter_minchar = $pwstrengthmeter_minchar;   # Password-Strength-Meter minimum characters
\$emailpassword = $emailpassword;           # 0 - instant registration. 1 - password emailed to new members
\$emailnewpass = $emailnewpass;             # Set to 1 to email a new password to members if they change their email address
\$emailwelcome = $emailwelcome;             # Set to 1 to email a welcome message to users even when you have mail password turned off
\$name_cannot_be_userid = $name_cannot_be_userid;   # Set to 1 to require users to have different usernames and display names
\$birthday_on_reg = $birthday_on_reg;       # Set to 0: don't ask for birthday on registration
                                            # 1: ask for the birthday, no input required
                                            # 2: ask for the birthday, input required

\$gender_on_reg = $gender_on_reg;           # 0: don't ask for gender on registration
                                            # 1: ask for gender, no input required
                                            # 2: ask for gender, input required
\$nomailspammer = $nomailspammer;           # 1: send deleted account email
\$lang = "\Q$lang\E";                       # Default Forum Language
\$default_template = "\Q$default_template\E";   # Default Forum Template

\$mailprog = "\Q$mailprog\E";               # Location of your sendmail program
\$smtp_server = "\Q$smtp_server\E";         # Address of your SMTP-Server (for Net::SMTP::TLS, specify the port number with a ":<portnumber>" at the end)
\$smtp_auth_required = $smtp_auth_required; # Set to 1 if the SMTP server requires Authorisation
\$authuser = "\Q$authuser\E";               # Username for SMTP authorisation
\$authpass = "\Q$authpass\E";               # Password for SMTP authorisation
\$webmaster_email = "\Q$webmaster_email\E"; # Your email address. (eg: \$webmaster_email = q^admin\@host.com^;)
\$mailtype = $mailtype;                     # Mail program to use: 0 = sendmail, 1 = SMTP, 2 = Net::SMTP, 3 = Net::SMTP::TLS

\$UseHelp_Perms = $UseHelp_Perms;           # Help Center: 1 == use permissions, 0 == don't use permissions

########## MemberGroups ##########

$member_groups
\@nopostorder = qw(@nopostorder);           # Order how "Post independent Member Groups" are displayed

########## Layout ##########

\$MenuType = $MenuType;                     # 1 for text menu or anything else for images menu
\$profilebutton = $profilebutton;           # 1 to show view profile button under post, or 0 for blank
\$threadtools = $threadtools;               # Enable dropdown for post actions
\$posttools = $posttools;                   # Enable dropdown for post actions
\$usertools = $usertools;                   # Allow admin to hide the list of tools that show when clicking a userlink
\$allow_hide_email = $allow_hide_email;     # Allow users to hide their email from public. Set 0 to disable
\$user_hide_avatars = $user_hide_avatars;       # Allow users to hide Avatars in threads. Set 0 to disable
\$user_hide_user_text = $user_hide_user_text;       # Allow users to hide User Text in threads. Set 0 to disable
\$user_hide_img = $user_hide_img;       # Allow users to hide Images in threads. Set 0 to disable
\$user_hide_attach_img = $user_hide_attach_img;     # Allow users to hide Attached Images in threads. Set 0 to disable
\$user_hide_signat = $user_hide_signat;         # Allow users to hide User Signatures in threads. Set 0 to disable
\$user_hide_smilies_row = $user_hide_smilies_row;   # Allow users to hide Smilies row below the Post Message-inputarea. Set 0 to disable
\$editGenderLimit = $editGenderLimit;       # Set a limit on the amount of times that member's can edit their gender
\$editAgeLimit = $editAgeLimit;             # Set a limit on the amount of times that member's can edit their birthdate
\$buddyListEnabled = $buddyListEnabled;     # Enable Buddy List
\$addmemgroup_enabled = $addmemgroup_enabled;   # Enable Users choose additional MemberGroups
\$showlatestmember = $showlatestmember;     # Set to 1 to display "Welcome Newest Member" on the Board Index
\$shownewsfader = $shownewsfader;           # 1 to allow or 0 to disallow NewsFader javascript
\$Show_RecentBar = $Show_RecentBar;         # Set to 1 to display the Recent Post on Board Index
\$showmodify = $showmodify;                 # Set to 1 to display "Last modified: Realname - Date" under each message
\$ShowBDescrip = $ShowBDescrip;             # Set to 1 to display board descriptions on the topic (message) index for each board
\$showuserpic = $showuserpic;               # Set to 1 to display each member's avatar in the message view (by the ICQ.. etc.)
\$showusertext = $showusertext;             # Set to 1 to display each member's personal text in the message view (by the ICQ.. etc.)
\$showtopicviewers = $showtopicviewers;     # Set to 1 to display members viewing a topic
\$showtopicrepliers = $showtopicrepliers;   # Set to 1 to display members replying to a topic
\$hide_signat_for_guests = $hide_signat_for_guests; # Set to 1 to hide all signatures for Guests (only Members can see them).
\$showgenderimage = $showgenderimage;       # Set to 1 to display each member's gender in the message view (by the ICQ.. etc.)
\$showzodiac = $showzodiac;                     # Set to 1 to display each member's zodiac sign in view profile and message view
\$showuserage = $showuserage;               # Set to 1 to display each member's age in the message view
\$showage = $showage;                       # Set to 1 to allow member to hide their age and birthyear (Except from the Administrator.)
\$showregdate = $showregdate;               # Set to 1 to show date of registration.
\$showyabbcbutt = $showyabbcbutt;           # Set to 1 to display the yabbc buttons on Posting and IM Send Pages
\$nestedquotes = $nestedquotes;             # Set to 1 to allow quotes within quotes (0 will filter out quotes within a quoted message)
\$parseflash = $parseflash;                 # Set to 1 to parse the flash tag
\$enableclicklog = $enableclicklog;         # Set to 1 to track stats in Clicklog (this may slow your board down)
\$showimageinquote = $showimageinquote;     # Set to 1 to shows images in quotes, 0 displays a link to the image
\$enabletopichover = $enabletopichover;     # Set to 1 to enable Topic Hover on Message Index
\$staff_reason = $staff_reason;             # Set to 1 to enable Reason for Editing for Staff
\$user_reason = $user_reason;               # Set to 1 to enable Reason for Editing for users

\@pallist = ($pallist);         # color settings of the palette

########## Feature Settings ##########

\$enable_spell_check = $enable_spell_check; # Set to 1 if you want to enable SpellChecker. By doing this you agree to the terms of license under which googiespell runs. See: /yabbfiles/googiespell/GPL.txt and http://creativecommons.org/licenses/by-nc-sa/3.0/
\$enable_ubbc = $enable_ubbc;               # Set to 1 if you want to enable UBBC (Uniform Bulletin Board Code)
\$enable_news = $enable_news;               # Set to 1 to turn news on, or 0 to set news off
\$allowpics = $allowpics;                   # set to 1 to allow members to choose avatars in their profile
\$upload_useravatar = $upload_useravatar;   # set to 1 to allow members to upload avatars for their profile
\$upload_avatargroup = "\Q$upload_avatargroup\E";   # membergroups allowed to upload avatars for their profile, '' == all members
\$avatar_limit = $avatar_limit;             # set to the maximum size of the uploaded avatar, 0 == no limit
\$avatar_dirlimit = $avatar_dirlimit;       # set to the maximum size of the upload avatar directory, 0 == no limit
\$default_avatar = $default_avatar;         # Set to 1 to show a default avatar if the member hasn't added a picture
\$default_userpic = "\Q$default_userpic\E"; # Set the file name for the default avatar

\$enable_guestposting = $enable_guestposting;   # Set to 0 if do not allow 1 is allow.
\$guest_media_disallowed = $guest_media_disallowed; # disallow browsing guests to see media files or have clickable auto linked urls in messages.
\$enable_guestlanguage = $enable_guestlanguage; # allow browsing guests to select their language - requires more than one language pack! - Set to 0 if do not allow 1 is allow.
\$enable_guest_view_limit = $enable_guest_view_limit;    # Set to 1 to enable guest topic view limit.
\$guest_view_limit = $guest_view_limit;    # Set the amount of topics guests are allowed to view before they are encouraged to register.
\$guest_view_limit_block = $guest_view_limit_block ;    # Set to 1 to block guests viewing topics if they reach the topic view limit. Set to 0 to display a message at the top of the message view.

\$enable_notifications = $enable_notifications; # - Allow e-mail notification for boards/threads listed in "My Notifications" => value == 1
            # - Allow e-mail notification when new PM comes in => value == 2
            # - value == 0 => both disabled | value == 3 => both enabled

\$NewNotificationAlert = $NewNotificationAlert; # enable notification alerts (popup) for new notifications
\$autolinkurls = $autolinkurls;             # Set to 1 to turn URLs into links, or 0 for no auto-linking.

\$forumnumberformat = $forumnumberformat;   # Select your preferred output Format for Numbers
\$timeselected = $timeselected;             # Select your preferred output Format of Time and Date
\$timecorrection = $timecorrection;         # Set time correction for server time in seconds
\$enabletz = $enabletz;                     # Allow for timezone selection
\$default_tz = "$default_tz";               # default forum timezone
\$timeoffset = "\Q$timeoffset\E";           # Time Offset to GMT/UTC (0 for GMT/UTC)
\$dstoffset = $dstoffset;                   # Time Offset (for daylight savings time, 0 to disable DST)
\$dynamic_clock = $dynamic_clock;           # Set to a value enables the dynamic clock at the top of the page
\$TopAmmount = $TopAmmount;                 # No. of top posters to display on the top members list
\$maxdisplay = $maxdisplay;                 # Maximum of topics to display
\$maxfavs = $maxfavs;                       # Maximum of favorite topics to save in a profile
\$maxrecentdisplay = $maxrecentdisplay;     # Maximum of posts to display on recent posts by a user (-1 to disable)
\$maxrecentdisplay_t = $maxrecentdisplay_t;     # Maximum of topics to display on recent topics (-1 to disable)
\$maxsearchdisplay = $maxsearchdisplay;     # Maximum of messages to display in a search query (-1 to disable search)
\$maxmessagedisplay = $maxmessagedisplay;   # Maximum of messages to display
\$showpageall = $showpageall;               # Disable or Enable show All on page selectors
\$checkallcaps = $checkallcaps;             # Set to 0 to allow ALL CAPS in posts (subject and message) or set to a value > 0 to open a JS-alert if more characters in ALL CAPS were there.
\$set_subjectMaxLength = $set_subjectMaxLength; # Maximum Allowed Characters in a Posts Subject
\$MaxMessLen = $MaxMessLen;                 # Maximum Allowed Characters in a Posts
\$AdMaxMessLen = $AdMaxMessLen;             # Maximum Allowed Characters in a Posts for Admins
\$MaxIMMessLen = $MaxIMMessLen;             # Maximum Allowed Characters in a PM
\$AdMaxIMMessLen = $AdMaxIMMessLen;                    # Maximum Allowed Characters in a PM for Admins
\$MaxCalMessLen = $MaxCalMessLen;           # Maximum Allowed Characters in a Cal event
\$AdMaxCalMessLen = $AdMaxCalMessLen;                   # Maximum Allowed Characters in a Cal Event for Admins
\$calsplit = $calsplit;                     # Maximum number to be shown on page without breaking into months.
\$honeypot = $honeypot;                     # Set to 1 to activate Honeypot spam deterrent
\$spamfruits = $spamfruits;                 # Set to 1 to activate SpamFruits spam deterrent
\$min_reg_time = $min_reg_time;             # Minimum amount of time to be spent filling out the registration form
\$speedpostdetection = $speedpostdetection; # Set to 1 to detect speedposters and delay their spam actions
\$spd_detention_time = $spd_detention_time; # Time in seconds before a speedposting ban is lifted again
\$min_post_speed = $min_post_speed;         # Minimum time in seconds between entering a post form and submitting a post
\$minlinkpost = $minlinkpost;               # Minimum amount of posts a member needs to post links and images
\$minlinksig = $minlinksig;                 # Minimum amount of posts a member needs to create links and images in signature
\$minlinkweb = $minlinkweb;                 # Minimum amount of posts a member needs to link to a website in their profile
\$post_speed_count = $post_speed_count; # Maximum amount of abuses before a user gets banned
\$fontsizemin = $fontsizemin;               # Minimum Allowed Font height in pixels
\$fontsizemax = $fontsizemax;               # Maximum Allowed Font height in pixels
\$MaxSigLen = $MaxSigLen;                   # Maximum Allowed Characters in Signatures
\$ClickLogTime = $ClickLogTime;             # Time in minutes to log every click to your forum (longer time means larger log file size)
\$max_log_days_old = $max_log_days_old; # If an entry in the user's log is older than ... days remove it

\$maxsteps = $maxsteps;                     # Number of steps to take to change from start color to endcolor
\$stepdelay = $stepdelay;                   # Time in milliseconds of a single step
\$fadelinks = $fadelinks;                   # Fade links as well as text?

\$defaultusertxt = "\Q$defaultusertxt\E";   # The default user text visible in users posts
\$timeout = $timeout;                       # Minimum time between 2 postings from the same IP
\$HotTopic = $HotTopic;                     # Number of posts needed in a topic for it to be classed as "Hot"
\$VeryHotTopic = $VeryHotTopic;             # Number of posts needed in a topic for it to be classed as "Very Hot"

\$barmaxdepend = $barmaxdepend;             # Set to 1 to let bar-max-length depend on top poster or 0 to depend on a number of your choice
\$barmaxnumb = $barmaxnumb;                 # Select number of post for max. bar-length in memberlist
\$defaultml = "\Q$defaultml\E";

\$ML_Allowed = $ML_Allowed;                 # allow browse MemberList
\$showuserpicml = $showuserpicml;           # Set to 1 to display each member's avatar in the member list
\$group_stars_ml = $group_stars_ml;         # Set to 1 to display group stars in the member list

########## Quick Reply configuration ##########

\$enable_quickpost = $enable_quickpost;     # Set to 1 if you want to enable the quick post box
\$enable_quickreply = $enable_quickreply;   # Set to 1 if you want to enable the quick reply box
\$enable_quickjump = $enable_quickjump;     # Set to 1 if you want to enable the jump to quick reply box
\$enable_markquote = $enable_markquote;     # Set to 1 if you want to enable the mark&quote feature
\$quick_quotelength = $quick_quotelength;   # Set the max length for Quick Quotes
\$enable_quoteuser = $enable_quoteuser;     # Set to 1 if you want to enable userquote
\$quoteuser_color = "\Q$quoteuser_color\E"; # Set the default color of @ in userquote

########## MemberPic Settings ##########

\$max_avatar_width = $max_avatar_width;     # Set maximum pixel width to which the self-selected avatars are resized, 0 disables this limit
\$max_avatar_height = $max_avatar_height;   # Set maximum pixel height to which the self-selected avatars are resized, 0 disables this limit
\$fix_avatar_img_size = $fix_avatar_img_size;   # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_avatarml_width = $max_avatarml_width;         # Set maximum pixel width to which the self-selected avatars in member list are resized, 0 disables this limit
\$max_avatarml_height = $max_avatarml_height;       # Set maximum pixel height to which the self-selected avatars in member list are resized, 0 disables this limit
\$fix_avatarml_img_size = $fix_avatarml_img_size;   # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_post_img_width = $max_post_img_width; # Set maximum pixel width for images, 0 disables this limit
\$max_post_img_height = $max_post_img_height;   # Set maximum pixel height for images, 0 disables this limit
\$fix_post_img_size = $fix_post_img_size;   # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_signat_img_width = $max_signat_img_width; # Set maximum pixel width for images in the signature, 0 disables this limit
\$max_signat_img_height = $max_signat_img_height;   # Set maximum pixel height for images in the signature, 0 disables this limit
\$fix_signat_img_size = $fix_signat_img_size;   # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_attach_img_width = $max_attach_img_width; # Set maximum pixel width for attached images, 0 disables this limit
\$max_attach_img_height = $max_attach_img_height;   # Set maximum pixel height for attached images, 0 disables this limit
\$fix_attach_img_size = $fix_attach_img_size;   # Set to 1 disable the image resize feature and sets the image size to the max_... values. If one of the max_... values is 0 the image is shown in its proportions to the other value. If both are 0 the image is shown at its original size.
\$max_brd_img_width = $max_brd_img_width;                           # Set maximum pixel width to which the Board Images are resized, 0 disables this limit
\$max_brd_img_height = $max_brd_img_height;                          # Set maximum pixel height to which the Board Images are resized, 0 disables this limit
\$fix_brd_img_size = $fix_brd_img_size;
\$img_greybox = $img_greybox;           # Set to 0 to disable "greybox" (each image is shown in a new window)
                            # Set to 1 to enable the attachment and post image "greybox" (one image/page)
                            # Set to 2 to enable the attachment and post image "greybox" => attachment images: (all images/page), post images: (one image/page)

########## Extended Profiles ##########

\$extendedprofiles = $extendedprofiles;     # Set to 1 to enabled 'Extended Profiles'. Turn it off (0) to save server load.
\@ext_prof_order = ($ext_prof_order);       # Order of the extended profile fields.
\@ext_prof_fields = (
$ext_prof_fields
);                      # Settings of the extended profiles fields.

######################################################################
# Event Calendar                                                     #
######################################################################

########## Standard Calendar Setting ##########
\$Show_EventCal = $Show_EventCal;
\$Show_EventButton = $Show_EventButton;
\$Show_EventBirthdays = $Show_EventBirthdays;
\$Show_MiniCalIcons = $Show_MiniCalIcons;
\$ShowSunday = $ShowSunday;
\$Show_ColorLinks = $Show_ColorLinks;
\$No_ShortUbbc = $No_ShortUbbc;
\$Event_TodayColor = "$Event_TodayColor";
\$Show_caltoday = $Show_caltoday;
\$Delete_EventsUntil = $Delete_EventsUntil;
\$CalShortEvent = $CalShortEvent;
\$CalEventPerms = qq~$CalEventPerms~;
\$CalEventMods = qq~$CalEventMods~;
\$CalEventPrivate = $CalEventPrivate;
\$CalEventNoName = $CalEventNoName;
\$Scroll_Events = $Scroll_Events;
\$DisplayCalEvents = $DisplayCalEvents;
\$DisplayEvents = $DisplayEvents;

########## Birthdaylist Setting ##########
\$Show_BirthdaysList = $Show_BirthdaysList;
\$Show_BirthdayButton = $Show_BirthdayButton;
\$Show_BirthdayDate = $Show_BirthdayDate;
\$Show_BdColorLinks = $Show_BdColorLinks;
\$Show_BdStarsign = $Show_BdStarsign;

########## Social Bookmarks settings ##########
\$en_bookmarks   = $en_bookmarks;  # Enable Social Bookmarks
\$bm_subcut = $bm_subcut; # Maximum characters in subject
\$bm_boards = "\Q$bm_boards\E"; # Select the boards which Social Bookmarks will be shown in

########## File Settings ##########

\$checkspace = $checkspace;         # Set to 1 to enable any freespace checking (should remain disabled on Windows/IIS servers)
\$enable_quota = $enable_quota;         # Set to 1 to enable free HOST size check with command 'quota' on every pageview
\$hostusername = "\Q$hostusername\E";       # Username on the above host HDD
\$findfile_time = $findfile_time;       # Used HOST size check with 'find' every ... minutes
\$findfile_root = "\Q$findfile_root\E";     # Used HOST size check with 'find' in this folder -r
\$findfile_maxsize = $findfile_maxsize;     # Maximum size in KB the above folder is allowed to store
\$findfile_space = "\Q$findfile_space\E";   # dynamically inserted available space on the user account and timestamp of the last check
\$enable_freespace_check = $enable_freespace_check; # Set to 1 to enable the free DISK space check on every pageview

\$gzcomp = $gzcomp;             # GZip compression: 0 = No Compression, 1 = External gzip, 2 = Zlib::Compress
\$gzforce = $gzforce;               # Don't try to check whether browser supports GZip
\$cachebehaviour = $cachebehaviour;     # Browser Cache Control: 0 = No Cache must revalidate, 1 = Allow Caching
\$use_flock = $use_flock;           # Set to 0 if your server doesn't support file locking, 1 for Unix/Linux and WinNT and 2 for Windows 95/98/ME

\$faketruncation = $faketruncation;     # Enable this option only if YaBB fails with the error:
                            # "truncate() function not supported on this platform."
                            # 0 to disable, 1 to enable.

\$debug = $debug;               # If set to 1 debug info is added to the template. Tag in template is {yabb debug}

########## Search Settings ##########
\$enableguestsearch = $enableguestsearch;       # Set to 1 to enable guests access to advanced search.
\$enableguestquicksearch = $enableguestquicksearch; # Set to 1 to enable guests access to quick search.
\$mgqcksearch = "\Q$mgqcksearch\E";
\$mgadvsearch = "\Q$mgadvsearch\E";
\$qcksearchtype = "\Q$qcksearchtype\E";
\$qckage = "\Q$qckage\E";

########## Anti-spam Question Settings ##########

\$en_spam_questions = $en_spam_questions;        # Set to 1 to enable Anti-spam Questions on registration
\$spam_questions_send = $spam_questions_send;    # Set to 1 to enable Anti-spam Questions on forgot password and send topic
\$spam_questions_gp = $spam_questions_gp;        # Set to 1 to enable Anti-spam Questions for guest posting, guest broadcast message and guest alert moderator
\$spam_questions_case = $spam_questions_case;    # Set to 1 to enable case-sensitive answers

###############################################################################
# Advanced Settings                                                           #
###############################################################################

########## RSS Settings ##########

\$rss_disabled = $rss_disabled;         # Set to 1 to disable the RSS feed
\$rss_limit = $rss_limit;           # Maximum number of topics in the feed
\$rss_message = $rss_message;           # Message to display in the feed
                            # 0: None
                            # 1: Latest Post
                            # 2: Original Post in the topic
\$showauthor = $showauthor;         # Show author name
\$rssemail = '$rssemail';             # default email if author email not shown
\$showdate = $showdate;             # Show post date

########## New Member Notification Settings ##########

\$new_member_notification = $new_member_notification;       # Set to 1 to enable the new member notification
\$new_member_notification_mail = "\Q$new_member_notification_mail\E";   # Your "New Member Notification"-email address.

\$sendtopicmail = $sendtopicmail;       # Set to 0 for send NO topic email to friend
                            # Set to 1 to send topic email to friend via YaBB
                            # Set to 2 to send topic email to friend via user program
                            # Set to 3 to let user decide between 1 and 2

########## In-Thread Multi Delete ##########

\$mdadmin = $mdadmin;
\$mdglobal = $mdglobal;
\$mdfmod = $mdfmod;
\$mdmod = $mdmod;
\$adminbin = $adminbin;             # Skip recycle bin step for admins and delete directly

########## Moderation Update ##########

\$adminview = $adminview;           # Multi-admin settings for Administrators: 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$gmodview = $gmodview;             # Multi-admin settings for Global Moderators: 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$fmodview = $fmodview;             # Multi-admin settings for Mid Moderators: 0=none, 1=icons 2=single checkbox 3=multiple checkboxes
\$modview = $modview;               # Multi-admin settings for Moderators: 0=none, 1=icons 2=single checkbox 3=multiple checkboxes

########## Advanced Memberview Plus ##########

\$showallgroups = $showallgroups;
\$OnlineLogTime = $OnlineLogTime;       # Time in minutes before Users are removed from the Online Log
\$lastonlineinlink = $lastonlineinlink;     # Show "Last online X days and XX:XX:XX hours ago." to all members == 1

########## Polls ##########

\$numpolloptions = $numpolloptions;     # Number of poll options
\$maxpq = $maxpq;               # Maximum Allowed Characters in a Poll Qestion?
\$maxpo = $maxpo;               # Maximum Allowed Characters in a Poll Option?
\$maxpc = $maxpc;               # Maximum Allowed Characters in a Poll Comment?
\$useraddpoll = $useraddpoll;           # Allow users to add polls to existing threads? (1 = yes)
\$ubbcpolls = $ubbcpolls;           # Allow UBBC tags and smilies in polls? (1 = yes)

########## My Center and Personal Messaging Features ##########

\$PM_level = $PM_level;             # minimum user level for private messaging: 0 = off, 1 = members, 2 = mods, 3 = gmod
\$PMenableGuestButton = $PMenableGuestButton;   # enable 'pm to admin' for guests? 1=yes, 0=no. Appears on the general menu instead of 'my center'
\$PMenableAlertButton = $PMenableAlertButton;   # enable 'alert moderator' button on thread view? 1=yes 0=no. Acts as a broadcast message to mods etc.
\$PMAlertButtonGuests = $PMAlertButtonGuests;   # enable 'alert moderator' button for Guests
\$enable_PMsearch = $enable_PMsearch;       # enable/max returns for PM search - 0 = off / 10 - 50 range for results

\$send_welcomeim = $send_welcomeim;     # enable auto-welcome message from forum to new member. 1=yes, 0=no
\$sendname = "\Q$sendname\E";           # username 'from' for welcome message. Defaults to fa.
\$imsubject = "\Q$imsubject\E";         # title of welcome message.
\$imtext = "\Q$imtext\E";           # message sent to new member

\$numposts = $numposts;             # Number of posts required to send Instant Messages
\$imspam = $imspam;             # Percent of Users a user is a allowed to send a message at once

\$enable_imlimit = $enable_imlimit;     # Set to 1 to enable limitation of incoming and outgoing im messages
\$numibox = $numibox;               # Number of maximum Messages in the IM-Inbox
\$numobox = $numobox;               # Number of maximum Messages in the IM-Outbox
\$numstore = $numstore;             # Number of maximum Messages in the Storage box
\$numdraft = $numdraft;             # Number of maximum Messages in the draft box

\$PMenable_cc = $PMenable_cc;           # enable cc for PM posting 1 yes, 0 no
\$PMenable_bcc = $PMenable_bcc;         # enable bcc for PM posting 1 yes, 0 no
\$PMenableBm_level = $PMenableBm_level;     # minimum level to send? 0 = off, 1 = mods, 2 = gmod, 3 = admin

\$enable_storefolders = $enable_storefolders;   # enable additonal store folders - in/out are default for all
                            # 0=no > 1 = number, max 25

\$enable_YaBBBut = $enable_YaBBBut;     # enable YABBC Buttons on post page? 1=yes, 0=no

\$enable_PMautoAway = $enable_PMautoAway;   # enable PM 'away' auto reply for inbox.
\$enable_MCaway = $enable_MCaway;       # enable 'away' indicator 0=Off 1=Staff to Staff 2=Staff to all 3=Members
\$MaxAwayLen = $MaxAwayLen;             # maximum allowed characters in Away message
\$enable_MCstatusStealth = $enable_MCstatusStealth; # enable 'stealth' mode for fa/gmods. Allows status label to stay at offline/away for all members viewing.
\$self_del_user = $self_del_user;           # 1: allow member to delete own account.

########## Topic Summary Cutter ##########

\$cutamount = $cutamount;           # Number of posts to list in topic summary
\$tsreverse = $tsreverse;           # Reverse Topic Summaries in Topic Reply (most recent becomes first)
\$ttsreverse = $ttsreverse;         # Reverse Topic Summaries in Topic (most recent becomes first)
\$ttsureverse = $ttsureverse;           # Reverse Topic Summaries in Topic (most recent becomes first) allowed as user wishes? Yes == 1

########## Time Lock ##########

\$tlnomodflag = $tlnomodflag;           # Set to 1 limit time users may modify posts
\$tlnomodtime = $tlnomodtime;           # Time limit on modifying posts (days)
\$tlnodelflag = $tlnodelflag;           # Set to 1 limit time users may delete posts
\$tlnodeltime = $tlnodeltime;           # Time limit on deleting posts (days)
\$tllastmodflag = $tllastmodflag;       # Set to 1 allow users to modify posts up to the specified time limit w/o showing "last Edit" message
\$tllastmodtime = $tllastmodtime;       # Time limit to modify posts w/o triggering "last Edit" message (in minutes)

########## Permalinks ##########

\$accept_permalink = $accept_permalink;     # Set to 1 to have the board accept permalink alike environment strings
\$symlink = "\Q$symlink\E";         # The part defined in .htaccess redirection rules that is between domainname and permalink
\$perm_spacer = "\Q$perm_spacer\E";     # The character used in the permalink output file that replaces the space.
\$perm_domain = "\Q$perm_domain\E";     # The full domainname (no http://) where the .haccess redirect is set on.

########## bypass post for locked thread ##########

\$bypass_lock_perm = "\Q$bypass_lock_perm\E";   # set level of permission - fa / fa+gmod / fa+gmod+mod; '' if disabled

########## File Attachment Settings ##########

\$limit = $limit;               # Set to the maximum number of kilobytes an attachment can be. Set to 0 to disable the file size check.
\$dirlimit = $dirlimit;             # Set to the maximum number of kilobytes the attachment directory can hold. Set to 0 to disable the directory size check.
\$overwrite = $overwrite;           # Set to 0 to auto rename attachments if they exist, 1 to overwrite them or 2 to generate an error if the file exists already.
\@ext = qw(@ext);               # The allowed file extensions for file attachements. Variable should be set in the form of "jpg bmp gif" and so on.
\$checkext = $checkext;             # Set to 1 to enable file extension checking, set to 0 to allow all file types to be uploaded
\$amdisplaypics = $amdisplaypics;       # Set to 1 to display attached pictures in posts, set to 0 to only show a link to them.
\$allowattach = $allowattach;           # Set to the number of maximum files attaching a post, set to 0 to disable file attaching.
\$allowguestattach = $allowguestattach;     # Set to 1 to allow guests to upload attachments, 0 to disable guest attachment uploading.
\$allowAttachIM = $allowAttachIM;           # Set the maximum number of file attachments allowed in personal messages, set to 0 to disable file attachments in personal messages.
\$pmAttachGroups = "\Q$pmAttachGroups\E";   # Member groups allowed to send pm attachments, '' == all members
\$pmDisplayPics = $pmDisplayPics;           # Set to 1 to display attached pictures in personal messages, set to 0 to only show a link to them.
\$pmCheckExt = $pmCheckExt;                 # Set to 1 to enable file extension checking on pm attachments, set to 0 to allow all file types to be uploaded
\@pmAttachExt = qw(@pmAttachExt);           # The allowed file extensions for pm file attachements. Variable should be set in the form of "jpg bmp gif" and so on.
\$pmFileLimit = $pmFileLimit;               # Set to the maximum number of kilobytes a pm attachment can be. Set to 0 to disable the file size check.
\$pmDirLimit = $pmDirLimit;                 # Set to the maximum number of kilobytes the pm attachment directory can hold. Set to 0 to disable the directory size check.
\$pmFileOverwrite = $pmFileOverwrite;       # Set to 0 to auto rename pm attachments if they exist, 1 to overwrite them or 2 to generate an error if the file exists already.

########## Error Logger ##########

\$elmax = $elmax;               # Max number of log entries before rotation
\$elenable = $elenable;             # allow for error logging
\$elrotate = $elrotate;             # Allow for log rotation

\$maxadminlog = $maxadminlog;               #Maximum number of entries stored in adminlog.txt (oldest entries deleted).

########## Advanced Tabs ##########
\$addtab_on = $addtab_on;               # show advanced tabs on Forum (For admin only.)
\@AdvancedTabs = ($AdvancedTabs);       # Advanced Tabs order and infos

########## Smilies ##########

\@SmilieURL = ($SmilieURL);         # Additional Smilies URL
\@SmilieCode = ($SmilieCode);           # Additional Smilies Code
\@SmilieDescription = ($SmilieDescription); # Additional Smilies Description
\@SmilieLinebreak = ($SmilieLinebreak);     # Additional Smilies Linebreak

\$smiliestyle = "$smiliestyle";         # smiliestyle
\$showadded = "$showadded";         # showadded
\$showsmdir = "$showsmdir";         # showsmdir
\$detachblock = "$detachblock";         # detachblock
\$winwidth = "$winwidth";           # winwidth
\$winheight = "$winheight";         # winheight
\$popback = "$popback";             # popback
\$poptext = "$poptext";             # poptext
\$showinbox = "$showinbox";         # showinbox
\$removenormalsmilies = "$removenormalsmilies"; # removenormalsmilies

###############################################################################
# Security Settings                                                           #
###############################################################################

\$regcheck = $regcheck;             # Set to 1 if you want to enable automatic flood protection enabled
\$gpvalid_en = $gpvalid_en;         # Set to 1 if you want to enable validation code on guest posting
\$codemaxchars = $codemaxchars;         # Set max length of validation code (15 is max)
\$captchastyle = "\Q$captchastyle\E";       # Set L = lowercase only, U = uppercase only, A = both upper and lowercase letters
\$captchaStartChars = "\Q$captchaStartChars\E"; # Set extra characters at the start of the validation code
\$captchaEndChars = "\Q$captchaEndChars\E"; # Set extra characters at the end of the validation code
\$rgb_foreground = "\Q$rgb_foreground\E";   # Set hex RGB value for validation image foreground color
\$rgb_shade = "\Q$rgb_shade\E";         # Set hex RGB value for validation image shade color
\$rgb_background = "\Q$rgb_background\E";   # Set hex RGB value for validation image background color
\$translayer = $translayer;         # Set to 1 background for validation image should be transparent
\$randomizer = $randomizer;         # Set 0 to 3 to create background random noise based on foreground or shade color or both
\$distortion = $distortion;         # Set 1 to distort the captcha image even more
\$stealthurl = $stealthurl;         # Set to 1 to mask referer url to hosts if a hyperlink is clicked.
\$do_scramble_id = $do_scramble_id;     # Set to 1 scambles all visible links containing user ID's
\$referersecurity = $referersecurity;       # Set to 1 to activate referer security checking.
\$sessions = $sessions;             # Set to 1 to activate session id protection.
\$show_online_ip_admin = $show_online_ip_admin; # Set to 1 to show online IP's to admins.
\$show_online_ip_gmod = $show_online_ip_gmod;   # Set to 1 to show online IP's to global moderators.
\$show_online_ip_fmod = $show_online_ip_fmod;   # Set to 1 to show online IP's to yabb moderators.
\$ipLookup = $ipLookup;                        # Set to 1 to enable IP Lookup.
\$masterkey = "\Q$masterkey\E";         # Seed for encryption of captchas

###############################################################################
# Guardian Settings (old Guardian.banned and Guardian.settings)               #
###############################################################################

\$banned_harvesters = qq~$banned_harvesters~;
\$banned_referers = qq~$banned_referers~;
\$banned_requests = qq~$banned_requests~;
\$banned_strings = qq~$banned_strings~;
\$whitelist = qq~$whitelist~;

\$use_guardian = $use_guardian;
\$use_htaccess = $use_htaccess;

\$disallow_proxy_on = $disallow_proxy_on;
\$referer_on = $referer_on;
\$harvester_on = $harvester_on;
\$request_on = $request_on;
\$string_on = $string_on;
\$union_on = $union_on;
\$clike_on = $clike_on;
\$script_on = $script_on;

\$disallow_proxy_htaccess = $disallow_proxy_htaccess;
\$referer_htaccess = $referer_htaccess;
\$harvester_htaccess = $harvester_htaccess;
\$request_htaccess = $request_htaccess;
\$string_htaccess = $string_htaccess;
\$union_htaccess = $union_htaccess;
\$clike_htaccess = $clike_htaccess;
\$script_htaccess = $script_htaccess;

\$disallow_proxy_notify = $disallow_proxy_notify;
\$referer_notify = $referer_notify;
\$harvester_notify = $harvester_notify;
\$request_notify = $request_notify;
\$string_notify = $string_notify;
\$union_notify = $union_notify;
\$clike_notify = $clike_notify;
\$script_notify = $script_notify;

###############################################################################
# Banning Settings Time bans                                                  #
###############################################################################

\@timeban = qw( d w m p );
\@bandays = ( 1, 7, 30, 365 );

###############################################################################
# Backup Settings                                                             #
###############################################################################

\@backup_paths = qw($backup_paths);
\$backupprogusr = '$backupprogusr';
\$backupprogbin = '$backupprogbin';
\$backupmethod = '$backupmethod';
\$compressmethod = '$compressmethod';
\$backupdir = '$backupdir';
\$lastbackup = $lastbackup;
\$backupsettingsloaded = $backupsettingsloaded;

###############################################################################
# Mod Settings                                                                #
###############################################################################
1;
EOF
    }
    else {

        # This should only be seen by developers.
        # If you get this, you messed up.
        croak 'I do not know how to write to this file.';
    }

    WriteSettingsTo( "$vardir/$file", $setfile );
    return;
}

# Subroutine for writing the common format of settings file
sub WriteSettingsTo {
    my ( $file, $setfile ) = @_;

    # Fix a certain type of syntax error
    $setfile =~ s/=\s+;/= 0;/gsm;

    # Make it look nicely aligned. The comment starts after 50 Col

    *cut_comment = sub {
        my ( $comment, $length ) =
          ( q{}, 150 );    # 120 Col is the max width of page
        my $var_length = length $_[0];
        while ( $length < $var_length ) { $length += 150; }
        foreach ( split / +/sm, $_[1] ) {
            if ( ( $var_length + length($comment) + length $_ ) > $length ) {
                $comment =~ s/ $//sm;
                $comment .= "\n$filler#  $_ ";
                $length += 150;
            }
            else { $comment .= "$_ "; }
        }
        $comment =~ s/ $//sm;
        return $comment;
    };
    my $filler = q{ } x 50;
    $setfile =~
s/(.+;)[ \t]+(#.+$)/ $1 . substr($filler,(length $1 < 50 ? length $1 : 49)) . $2 /gem;
    $setfile =~ s/\t+(#.+$)/$filler$1/gm;
    $setfile =~ s/(.+)(#.+$)/ $1 . cut_comment($1,$2) /gem;

    # Write it out
    fopen( SETTINGS, ">$file" ) || fatal_error( 'cannot_open', $file, 1 );
    print {SETTINGS} $setfile or croak "$croak{'print'} SETTINGS";
    fclose(SETTINGS);
    return;
}

1;
