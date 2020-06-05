###############################################################################
# GuardianAdmin.pm                                                            #
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

$guardianadminpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Guardian');
$admin_images = "$yyhtml_root/Templates/Admin/default";
$guardimg      = 'guardian.png';

sub setup_guardian {
    is_admin_or_gmod();

    # figure out what to print
    if ($use_guardian)      { $guardian_checked = ' checked="checked" ' }
    if ($use_htaccess)      { $htaccess_checked = ' checked="checked" ' }
    if ($disallow_proxy_on) { $proxy_on_checked = ' checked="checked" ' }
    if ($disallow_proxy_notify) {
        $proxy_notify_checked = ' checked="checked" ';
    }
    if ($disallow_proxy_htaccess) {
        $proxy_htaccess_checked = ' checked="checked" ';
    }
    if ($referer_on)       { $referer_on_checked       = ' checked="checked" ' }
    if ($referer_notify)   { $referer_notify_checked   = ' checked="checked" ' }
    if ($referer_htaccess) { $referer_htaccess_checked = ' checked="checked" ' }
    if ($harvester_on)     { $harvester_on_checked     = ' checked="checked" ' }
    if ($harvester_notify) { $harvester_notify_checked = ' checked="checked" ' }
    if ($harvester_htaccess) {
        $harvester_htaccess_checked = ' checked="checked" ';
    }
    if ($request_on)       { $request_on_checked       = ' checked="checked" ' }
    if ($request_notify)   { $request_notify_checked   = ' checked="checked" ' }
    if ($request_htaccess) { $request_htaccess_checked = ' checked="checked" ' }
    if ($string_on)        { $string_on_checked        = ' checked="checked" ' }
    if ($string_notify)    { $string_notify_checked    = ' checked="checked" ' }
    if ($string_htaccess)  { $string_htaccess_checked  = ' checked="checked" ' }
    if ($union_on)         { $union_on_checked         = ' checked="checked" ' }
    if ($union_notify)     { $union_notify_checked     = ' checked="checked" ' }
    if ($union_htaccess)   { $union_htaccess_checked   = ' checked="checked" ' }
    if ($clike_on)         { $clike_on_checked         = ' checked="checked" ' }
    if ($clike_notify)     { $clike_notify_checked     = ' checked="checked" ' }
    if ($clike_htaccess)   { $clike_htaccess_checked   = ' checked="checked" ' }
    if ($script_on)        { $script_on_checked        = ' checked="checked" ' }
    if ($script_notify)    { $script_notify_checked    = ' checked="checked" ' }
    if ($script_htaccess)  { $script_htaccess_checked  = ' checked="checked" ' }

    ## make splits turn into linefeeds for the forms
    chomp $banned_harvesters;
    chomp $banned_referers;
    chomp $banned_requests;
    chomp $banned_strings;
    chomp $whitelist;
    $banned_harvesters =~ s/\|/\n/gxsm;
    $banned_referers   =~ s/\|/\n/gxsm;
    $banned_requests   =~ s/\|/\n/gxsm;
    $banned_strings    =~ s/\|/\n/gxsm;
    $whitelist         =~ s/\|/\n/gxsm;
    @access_denied = update_htaccess('load');

    foreach (@access_denied) {
        chomp $_;
        $acc_denied .= "$_\n";
    }

    $yymain .= qq~
<form action="$adminurl?action=setup_guardian2" method="post" onsubmit="savealert()" enctype="application/x-www-form-urlencoded" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'title'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$guardian_txt{'description'}</div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'general'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="use_guardian">$guardian_txt{'use_guardian'}</label>
                    <input type="checkbox" name="use_guardian" id="use_guardian" value="1"$guardian_checked />
                </div>
                <div class="setting-cell3">
                    <label for="use_htaccess">$guardian_txt{'use_htaccess'}
                    <input type="checkbox" name="use_htaccess" id="use_htaccess" value="1"$htaccess_checked onmouseup="remove_htaccess();" /><br />$guardian_txt{'use_htaccess_support'}</label>
                </div>
                <script type="text/javascript">
            var old_htaccess = '';
            function remove_htaccess() {
                if (document.getElementById("use_htaccess").checked) {
                    old_htaccess = document.getElementById("access_denied").value;
                    document.getElementById("access_denied").value = '';
                    document.getElementById("access_denied").disabled = "disabled";
                } else {
                    document.getElementById("access_denied").value = old_htaccess;
                    document.getElementById("access_denied").disabled = "";
                }
            }
                </script>
                <div class="setting-cell3">
                    <label for="access_denied">$guardian_txt{'htaccess_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="access_denied" id="access_denied" style="width:98%"~
      . ( $use_htaccess ? q{} : ' disabled="disabled"' )
      . qq~>$acc_denied</textarea>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'proxy'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="disallow_proxy_on">$guardian_txt{'proxy_on'}</label>
                    <input type="checkbox" name="disallow_proxy_on" id="disallow_proxy_on" value="1"$proxy_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="whitelist">$guardian_txt{'white_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="whitelist" id="whitelist" style="width:98%">$whitelist</textarea>
                </div>
                <div class="setting-cell3">
                    <label for="disallow_proxy_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="disallow_proxy_notify" id="disallow_proxy_notify" value="1"$proxy_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="disallow_proxy_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="disallow_proxy_htaccess" id="disallow_proxy_htaccess" value="1"$proxy_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'referer'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="referer_on">$guardian_txt{'referer_on'}</label>
                    <input type="checkbox" name="referer_on" id="referer_on" value="1"$referer_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="banned_referers">$guardian_txt{'referer_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="banned_referers" id="banned_referers" style="width:98%">$banned_referers</textarea>
                </div>
                <div class="setting-cell3">
                    <label for="referer_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="referer_notify" id="referer_notify" value="1"$referer_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="referer_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="referer_htaccess" id="referer_htaccess" value="1"$referer_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'harvester'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="harvester_on">$guardian_txt{'harvester_on'}</label>
                    <input type="checkbox" name="harvester_on" id="harvester_on" value="1"$harvester_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="banned_harvesters">$guardian_txt{'harvester_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="banned_harvesters" id="banned_harvesters" style="width:98%">$banned_harvesters</textarea>
                </div>
                <div class="setting-cell3">
                    <label for="harvester_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="harvester_notify" id="harvester_notify" value="1"$harvester_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="harvester_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="harvester_htaccess" id="harvester_htaccess" value="1"$harvester_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'request'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="request_on">$guardian_txt{'request_on'}</label>
                    <input type="checkbox" name="request_on" id="request_on" value="1"$request_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="banned_requests">$guardian_txt{'request_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="banned_requests" id="banned_requests" style="width:98%">$banned_requests</textarea>
                </div>
                <div class="setting-cell3">
                    <label for="request_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="request_notify" id="request_notify" value="1"$request_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="request_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="request_htaccess" id="request_htaccess" value="1"$request_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'string'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="string_on">$guardian_txt{'string_on'}</label>
                    <input type="checkbox" name="string_on" id="string_on" value="1"$string_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="banned_strings">$guardian_txt{'string_list'}</label>
                </div>
                <div class="setting-cell4">
                    <textarea cols="40" rows="8" name="banned_strings" id="banned_strings" style="width:98%">$banned_strings</textarea>
                </div>
                <div class="setting-cell3">
                    <label for="string_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="string_notify" id="string_notify" value="1"$string_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="string_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="string_htaccess" id="string_htaccess" value="1"$string_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'script'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="script_on">$guardian_txt{'script_on'}</label>
                    <input type="checkbox" name="script_on" id="script_on" value="1"$script_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="script_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="script_notify" id="script_notify" value="1"$script_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="script_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="script_htaccess" id="script_htaccess" value="1"$script_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'union'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="union_on">$guardian_txt{'union_on'}</label>
                    <input type="checkbox" name="union_on" id="union_on" value="1"$union_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="union_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="union_notify" id="union_notify" value="1"$union_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="union_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="union_htaccess" id="union_htaccess" value="1"$union_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                <img src="$admin_images/$guardimg" alt="" /> <b>$guardian_txt{'clike'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="setting-cell3">
                    <label for="clike_on">$guardian_txt{'clike_on'}</label>
                    <input type="checkbox" name="clike_on" id="clike_on" value="1"$clike_on_checked />
                </div>
                <div class="setting-cell3">
                    <label for="clike_notify">$guardian_txt{'notify'}</label>
                    <input type="checkbox" name="clike_notify" id="clike_notify" value="1"$clike_notify_checked />
                </div>
                <div class="setting-cell3">
                    <label for="clike_htaccess">$guardian_txt{'htaccess_add'}
                    <input type="checkbox" name="clike_htaccess" id="clike_htaccess" value="1"$clike_htaccess_checked /><br />$guardian_txt{'htaccess_support'}</label>
                </div>
            </td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input type="submit" value="$guardian_txt{'save'}" class="button" />
        </td>
    </tr>
</table>
</div>
</form>
~;
    $yytitle     = $guardian_txt{'setup'};
    $action_area = 'setup_guardian';
    AdminTemplate();
    return;
}

sub setup_guardian2 {
    is_admin_or_gmod();
    my @onoff = qw{
      use_guardian use_htaccess disallow_proxy_on disallow_proxy_htaccess referer_on referer_htaccess harvester_on harvester_htaccess request_on request_htaccess string_on string_htaccess union_on union_htaccess clike_on clike_htaccess script_on script_htaccess disallow_proxy_notify referer_notify harvester_notify request_notify string_notify union_notify clike_notify script_notify};

    # Set as 0 or 1 if box was checked or not
    my $fi;
    map { $fi = lc $_; ${$_} = $FORM{$fi} == 1 ? 1 : 0; } @onoff;

    $banned_harvesters = $FORM{'banned_harvesters'};
    $banned_referers   = $FORM{'banned_referers'};
    $banned_requests   = $FORM{'banned_requests'};
    $banned_strings    = $FORM{'banned_strings'};
    $access_denied     = $FORM{'access_denied'};
    $whitelist         = $FORM{'whitelist'};
    chomp $banned_harvesters;
    chomp $banned_referers;
    chomp $banned_requests;
    chomp $banned_strings;
    chomp $whitelist;
    $banned_harvesters =~ s/\r//gxsm;
    $banned_referers   =~ s/\r//gxsm;
    $banned_requests   =~ s/\r//gxsm;
    $banned_strings    =~ s/\r//gxsm;
    $access_denied     =~ s/\r//gxsm;
    $whitelist         =~ s/\r//gxsm;
    $banned_harvesters =~ s/\n/|/gxsm;
    $banned_referers   =~ s/\n/|/gxsm;
    $banned_requests   =~ s/\n/|/gxsm;
    $banned_strings    =~ s/\n/|/gxsm;
    $access_denied     =~ s/\n/,/gxsm;
    $whitelist         =~ s/\n/|/gxsm;

    # We shouldn't let them block POST and GET since it'll mess things up.
    $banned_requests =~ s/post//igsm;
    $banned_requests =~ s/get//igsm;
    $banned_requests =~ s/\|+/\|/igsm;    # Clean up extra pipes

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');
    @access_denied = split /\,/xsm, $access_denied;
    update_htaccess( 'save', @access_denied );

    $yySetLocation = qq~$adminurl?action=setup_guardian~;
    redirectexit();
    return;
}

sub update_htaccess {
    my ( $action, @values ) = @_;
    my ( $htheader, $htfooter, @denies, @htout );
    if ( !$action ) { return 0; }
    fopen( HTA, '.htaccess' );
    @htlines = <HTA>;
    fclose(HTA);

# header to determine only who has access to the main script, not the admin script
    $htheader = q~<Files YaBB*>~;
    $htfooter = q~</Files>~;
    $start    = 0;
    foreach (@htlines) {
        chomp $_;
        if ( $_ eq $htheader ) { $start = 1; }
        if ( $start == 0 && $_ !~ m{#}sm && $_ ne q{} ) { push @htout, "$_\n"; }
        if ( $_ eq $htfooter ) { $start = 0; }
        if ( $start == 1 && $_ =~ s/Deny from //gsm ) {
            push @denies, $_;
        }
    }
    if ( $action eq 'load' ) {
        return @denies;
    }
    elsif ( $action eq 'save' ) {
        fopen( HTA, '>.htaccess' );
        print {HTA} '# Last modified by The Guardian: '
          . timeformat( $date, 1 )
          . " #\n\n"
          or croak "$croak{'print'} HTA";
        print {HTA} @htout or croak "$croak{'print'} HTA";
        if (@values) {
            print {HTA} "\n$htheader\n" or croak "$croak{'print'} HTA";
            foreach (@values) {
                chomp $_;
                if ( $_ ne q{} ) {
                    print {HTA} "Deny from $_\n" or croak "$croak{'print'} HTA";
                }
            }
            print {HTA} "$htfooter\n" or croak "$croak{'print'} HTA";
        }
        fclose(HTA);
    }
    elsif ( $action eq 'add' ) {
        push @denies, @values;
        update_htaccess( 'save', @denies );
    }
    return;
}

sub guardian_block {
    is_admin_or_gmod();

    if ( $use_guardian && $use_htaccess ) {
        require Sources::Guardian;
        my $blockIP = $INFO{'ip'};
        update_htaccess( 'add', $blockIP );
        $yySetLocation = qq~$adminurl?action=$INFO{'return'}~;
        redirectexit();
    }
    return;
}

1;
