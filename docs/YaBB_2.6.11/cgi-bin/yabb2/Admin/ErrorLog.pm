###############################################################################
# ErrorLog.pm                                                                 #
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

$errorlogpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub ErrorLog {
    is_admin_or_gmod();
    $yytitle    = "$errorlog{'1'}";
    $errorcount = 0;
    fopen( ERRORFILE, "$vardir/errorlog.txt" );
    @errors = <ERRORFILE>;
    fclose(ERRORFILE);
    $errorcount = @errors;
    $date2      = $date;
    $mytest = 0;
    for my $i ( 0 .. ( $#errors ) ) {
        my @tmpArray = split /\|/xsm, $errors[$i];
        if ( $tmpArray[0] eq q{} || $tmpArray[0] =~ /[a-z]/igsm || $tmpArray[1] eq q{} || $tmpArray[1] =~ /[a-z]/igsm ) { next; }
        else {
            $date1 = $tmpArray[1];
            calcdifference();
            $date_ref = $result;
            $tmplist[$mytest] = qq~$date_ref|$errors[$i]~;
            $mytest++;
        }
    }

    $sortmode  = $INFO{'sort'};
    $sortorder = $INFO{'order'};
    if ( $sortmode eq q{} ) {
        $sortmode = 'time';
    }
    if ( $sortorder eq q{} ) {
        $sortorder = 'reverse';
    }
    my @sortlist = ();
    my $field    = '0';    # 0-based field defaults to the datecmp value
    my $type     = '0';    # 0=numeric; 1=text
    my $case     = '1';    # 0=case sensitive; 1=ignore case
    my $dir      = '0';    # 0=increasing; 1=decreasing

    if ( $sortmode eq 'time' ) {
        $field = '1';
        $type  = '0';
        $case  = '1';
        $dir   = '0';
    }
    elsif ( $sortmode eq 'users' ) {
        $field = '8';
        $type  = '1';
        $case  = '1';
        $dir   = '0';
    }
    elsif ( $sortmode eq 'ip' ) {
        $field = '3';
        $type  = '0';
        $case  = '0';
        $dir   = '0';
    }
    @sortlist =
      map { $_->[0] }
      sort { YaBBsort( $field, $type, $case, $dir ) }
      map { [ $_, split /\|/xsm ] } @tmplist;

    if ( $INFO{'order'} eq 'reverse' ) {
        @sortlist = reverse @sortlist;
    }
    else {
        if ( $sortmode eq 'time' ) {
            $order_time = ';order=reverse';
        }
        elsif ( $sortmode eq 'users' ) {
            $order_users = ';order=reverse';
        }
        elsif ( $sortmode eq 'ip' ) {
            $order_ip = ';order=reverse';
        }
    }

    if ( $sortmode ne q{} ) {
        $sortmode = ';sort=' . $INFO{'sort'};
    }
    if ( $sortorder ne q{} ) {
        $sortorder = ';order=' . $INFO{'order'};
    }

    $errorlog_error = q{};
    if ( $#errors > $#tmplist ) {
        $err = $#errors - $#tmplist;
        $errorlog_error = qq~<br /><span class="important"><b>$errorlog{'27a'} $err $errorlog{'27b'}</b></span>~;
        if ( $err == 1 ) {
            $errorlog_error = qq~<br /><span class="important"><b>$errorlog{'27c'} $err $errorlog{'27d'}</b></span>~;
        }
    }
    $yymain .= qq~\
<script src="$yyhtml_root/ubbc.js" type="text/javascript"></script>
<script type="text/javascript">
function changeBox(cbox) {
  box = eval(cbox);
  box.checked = !box.checked;
}
function checkAll() {
  for (var i = 0; i < document.errorlog_form.elements.length; i++) {
    if(document.errorlog_form.elements[i].name != "subfield" && document.errorlog_form.elements[i].name != "msgfield") {
            document.errorlog_form.elements[i].checked = true;
        }
    }
}
function uncheckAll() {
  for (var i = 0; i < document.errorlog_form.elements.length; i++) {
    if(document.errorlog_form.elements[i].name != "subfield" && document.errorlog_form.elements[i].name != "msgfield") {
            document.errorlog_form.elements[i].checked = false;
        }
  }
}
</script>
<form name="errorlog_form" action="$adminurl?action=deleteerror;$sortmode$sortorder" method="post" onsubmit="return submitproc()">
<input type="hidden" name="button" value="4" />
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom:.5em">
            <colgroup>
                <col style="width:5%" />
                <col style="width:10%" />
                <col style="width:15%" />
                <col style="width:65%" />
                <col style="width:5%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="5">$admin_img{'xx'} <b>$yytitle</b></td>
            </tr><tr>
                <td class="windowbg2" colspan="5"><div class="pad-more">$errorlog{'18'} $errorlog_error</div></td>
            </tr><tr>
                <td class="catbg center"><b>$errorlog{'21'}</b></td>
                <td class="catbg center">
                    <a href="$adminurl?action=errorlog$startmode;sort=time$order_time"><b>$errorlog{'5'}</b></a>
                </td>
                <td class="catbg center">
                    <a href="$adminurl?action=errorlog$startmode;sort=users$order_users"><b>$errorlog{'11'}</b></a> ( <a href="$adminurl?action=errorlog$startmode;sort=ip$order_ip"><b>$errorlog{'6'}</b></a> )
                </td>
                <td class="catbg center"><b>$errorlog{'7'} / $errorlog{'8'}</b></td>
                <td class="catbg center"><b>$errorlog{'13'}</b></td>
            </tr>~;
    $numshown  = 0;
    $actualnum = 0;
    $bb = 0;
    while ( $numshown <= $errorcount ) {
        my ( $tmp_user, $username, $numb, $ids, $all ) = q{};
        $numshown++;
        $sortlist[$bb] =~ s/<br \/>/\[br \/\]/gsm;
        $sortlist[$bb] =~ s/<b>/\[b\]/gxsm;
        $sortlist[$bb] =~ s/<\/b>/\[\/b\]/gxsm;
        $sortlist[$bb] =~ s/</&lt;/gxsm;
        $sortlist[$bb] =~ s/>/&gt;/gxsm;
        $sortlist[$bb] =~ s/\[b\]/<b>/gxsm;
        $sortlist[$bb] =~ s/\[\/b\]/<\/b>/gxsm;
        $sortlist[$bb] =~ s/\[br \/\]/<br \/>/gsm;
        my (
            $tmp_datecmp,      $tmp_id,    $tmp_date,
            $tmp_userip,       $tmp_error, $tmp_action,
            $tmp_topic_number, $tmp_board, $tmp_username,
            $tmp_password
        ) = split /\|/xsm, $sortlist[$bb];
        if ( !$tmp_id ) { next; }
        FormatUserName($tmp_username);
        if ( !$tmp_username ) {
            $tmp_user = 'Guest';
        }
        else {
            $tmp_user = $tmp_username;
        }
        $userlist{$tmp_user} = $userlist{$tmp_user} + 1;
        $tmp_date = timeformat($tmp_date);
        LoadUser($tmp_user);
        my $ipBlock = q{};
        my $lookupIP = qq{$tmp_userip};
        my $ipBan = q{};
        if ( $tmp_userip ne '127.0.0.1' ) {
            $ipBlock = ( $use_guardian && $use_htaccess ) ? qq~<br /><a href="$adminurl?action=guardian_block;ip=$tmp_userip;return=errorlog" onclick="return confirm('$admin_txt{'ipblock_confirm'}$tmp_userip');">$admin_txt{'ipblock'}</a>~ : qq~<br /><a href="$adminurl?action=blockip;ip=$tmp_userip;return=errorlog" onclick="return confirm('$admin_txt{'ipblock_confirm'}$tmp_userip');">$admin_txt{'ipblock2'}</a>~;

            $lookupIP =
            ($ipLookup)
            ? qq~<a href="$scripturl?action=iplookup;ip=$tmp_userip">$tmp_userip</a>~
            : qq~$tmp_userip~;
            $ipBan = qq~ - <a href="$adminurl?action=ipban_err;ban=$tmp_userip;lev=p;return=errorlog" onclick="return confirm('$admin_txt{'ipban_confirm'}$tmp_userip');">$admin_txt{'725f'}</a>~;
            }
            if ( $tmp_user eq "$useraccount{$tmp_user}" ) {
                if ( $userprofile{$tmp_user}->[1] ) {
                $username =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$tmp_user}" target="_blank">$userprofile{$tmp_user}->[1]</a>~;
                }
                else {
                    $username .= qq~$useraccount{$tmp_user}~;
                }
                $username .=
qq~<br />$lookupIP$ipBan$ipBlock~;
            }
            else {
                $username = qq~$tmp_user<br />$lookupIP$ipBan$ipBlock~;
            }
        if ( $tmp_topic_number eq q{} ) {
            $numb = "&amp;action=$tmp_action";
        }
        else {
            $numb = "&amp;action=$tmp_action&amp;num=$tmp_topic_number";
        }
        if ( $tmp_board eq q{} ) {
            $ids = '?board=';
        }
        else {
            $ids = "?board=$tmp_board";
        }
        if ( $tmp_action eq q{} && $tmp_board eq q{} ) {
            $all = "$boardurl/$yyexec.$yyext";
        }
        else {
            $all = "$boardurl/$yyexec.$yyext$ids$numb";
        }
        if ( $tmp_error eq $admin_txt{'39'} || $tmp_error eq $admin_txt{'40'} )
        {
            $tmp_error =
              $tmp_error . qq~ - (<span class="important">$tmp_password</span>)~;
        }

        $bb++;
        $addel =
qq~                <td class="windowbg center"><input type="checkbox" name="error$tmp_id" value="$tmp_id" class="windowbg" style="border: 0;" /></td>~;
        $actualnum++;
        $print_errorlog .= qq~<tr>
                <td class="windowbg center">$actualnum</td>
                <td class="windowbg">$tmp_date</td>
                <td class="windowbg2 center">$username</td>
                <td class="windowbg center">
                    <div class="small" style="height:5em; overflow:auto">$tmp_error<br /><a href="$all">$all</a></div>
                </td>
                $addel
            </tr>~;
    }
    if ( !($actualnum) ) {
        $print_errorlog = qq~<tr>
                <td class="windowbg2 center" colspan="5">$errorlog{'19'}</td>
            </tr>~;
    }
    $yymain .= qq~
$print_errorlog
    ~;

    @userlist = reverse sort { $userlist{$a} <=> $userlist{$b} } keys %userlist;
    foreach my $member (@userlist) {
        $errmember .= qq~$member ($userlist{$member}), ~;
    }
    $errmember =~ s/, \Z//sm;

    $yymain .= qq~          <tr>
                <td class="windowbg2" colspan="5"><div class="pad-more"><b>$errorlog{'26'}</b> $errmember</div></td>
            </tr><tr>
                <td class="windowbg right" colspan="4">&nbsp;~;
    if ( $errorcount > 0 ) {
        $yymain .=
          qq~<label for="checkall"><b>$admin_txt{'737'}</b></label>&nbsp;~;
    }
    $yymain .= q~
                </td>
                <td class="windowbg center">&nbsp;~;
    if ( $errorcount > 0 ) {
        $yymain .=
q~<input type="checkbox" name="checkall" id="checkall" class="windowbg" style="border: 0;" onclick="if (this.checked) checkAll(); else uncheckAll();" />~;
    }
    $yymain .= q~
            </td>
        </tr>
    </table>
</div>~;

    if ( $errorcount > 0 ) {

        $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $errorlog{'14'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="submit" value="$errorlog{'14'}" onclick="return confirm('$errorlog{'15'}')" class="button" />
                <br /><a href="$boardurl/AdminIndex.$yyaext?action=cleanerrorlog" onclick="return confirm('$errorlog{'15a'}')">$errorlog{'14a'}</a>
            </td>
        </tr>
    </table>
</div>~;
    }

    $yymain .= q~
</form>
~;
    $action_area = 'errorlog';
    AdminTemplate();
    return;
}

sub CleanErrorLog {
    is_admin_or_gmod();
    if ( -e ("$vardir/errorlog.txt") ) {
        unlink "$vardir/errorlog.txt" or croak qq~$!~;
    }
    $yySetLocation = qq~$adminurl?action=errorlog~;
    redirectexit();
    return;
}

sub DeleteError {
    is_admin_or_gmod();
    my ( $sortmode, $sortorder );
    chomp $FORM{'button'};
    if ( $FORM{'button'} ne '4' ) { fatal_error('no_access'); }
    fopen( FILE, "$vardir/errorlog.txt" );
    @errors = <FILE>;
    fclose(FILE);
    unlink "$vardir/errorlog.txt";
    fopen( FILE, ">>$vardir/errorlog.txt" );

    foreach my $line (@errors) {
        chomp $line;
        my (
            $tmp_id,    $tmp_date,  $tmp_username,
            $tmp_error, $tmp_board, $tmp_action
        ) = split /\|/xsm, $line;
        if ( !exists $FORM{"error$tmp_id"} ) {
            print {FILE} $line . "\n" or croak "$croak{'print'} FILE";
        }
    }
    fclose(FILE);
    $yySetLocation = qq~$adminurl?action=errorlog~;
    redirectexit();
    return;
}

# Moved here from Subs.pm since it was only used here
sub YaBBsort {
    my $field = ( shift || 0 ) + 1;    # 0-based field
    my $type = shift || 0;             # 0=numeric; 1=text
    my $case = shift || 0;             # 0=case sensitive; 1=ignore case
    my $dir  = shift || 0;             # 0=increasing; 1=decreasing

    if ( $type == 0 ) {
        if ( $dir == 0 ) {
            $a->[$field] <=> $b->[$field];
        }
        else {
            $b->[$field] <=> $a->[$field];
        }
    }
    else {
        if ( $case == 0 ) {
            if ( $dir == 0 ) {
                $a->[$field] cmp $b->[$field];
            }
            else {
                $b->[$field] cmp $a->[$field];
            }
        }
        else {
            if ( $dir == 0 ) {
                uc $a->[$field] cmp uc $b->[$field];
            }
            else {
                uc $b->[$field] cmp uc $a->[$field];
            }
        }
    }
    return 1;
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
        print {HTA} '# Last modified by YaBB: '
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

sub blockip {
    is_admin_or_gmod();
    my $blockIP = $INFO{'ip'};
    update_htaccess( 'add', $blockIP );
    $yySetLocation = qq~$adminurl?action=errorlog~;
    redirectexit();
    return;
}

1;
