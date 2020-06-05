###############################################################################
# Ban.pm                                                                      #
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
use CGI qw(:standard);
use Time::Local;
our $VERSION = '2.6.11';

$banpmver = 'YaBB 2.6.11 $Revision: 1611 $';

#the ban list in the Admin Center
sub ipban {
    is_admin_or_gmod();

    use Time::gmtime;
    fopen( BAN, "<$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    @banlist = <BAN>;
    fclose(BAN);
    $today = time;

    *time_ban = sub {
        my $ban_user = $banned[3];
        $tmc = localtime($banned[2]);
        for my $i ( 0 .. 3 ) {
            if ( $banned[4] eq $timeban[$i] ) {
                $tmb = $banned[2] + ( $bandays[$i] * 86400 );
            }
        }

        if ( $banned[4] eq 'p' ) {
            $timeb =
"$tmc by ${$uid.$ban_user}{'realname'} [$ban_user] - Permanent";
        }
        elsif ( $banned[4] ne 'p' && $tmb < $today ) {
            $timeb =
"$tmc by ${$uid.$ban_user}{'realname'} [$ban_user] - Expired";
        }
        else {
            $tma = timeformat($tmb,1);
            $timeb =
qq~$tmc by ${$uid.$ban_user}{'realname'} [$ban_user] - Expires on: $tma~;
        }
        return $timeb;
    };

    for my $i (@banlist) {
        chomp $i;
        my $ii = 0;
        my $ee = 0;
        my $uu = 0;
        @banned = split /\|/xsm, $i;
        if ( $banned[0] eq 'I' ) {
            $ban_i    = $banned[1];
            $timebana = time_ban();
            $iban .= qq~<option value="$i"> $ban_i - $timebana</option>\n~;
            $ii ++;
        }
        if ( $banned[0] eq 'E' ) {
            $ban_e  = $banned[1];
            $e_show = $banned[1];
            $e_show =~ s/\\@/@/xsm;
            $timebana = time_ban();
            $eban .= qq~<option value="$i"> $e_show - $timebana</option>\n~;
            $ee++;
        }
        if ( $banned[0] eq 'U' ) {
            $ban_u = $banned[1];
            $timebana = time_ban();
            $uban .= qq~<option value="$i"> $ban_u - $timebana</option>\n~;
            $uu++;
        }
    }
    if ( $ii == 0 ) { $iban .= q~<option value="">--</option>~; }
    if ( $ee == 0 ) { $eban .= q~<option value="">--</option>~; }
    if ( $uu == 0 ) { $uban .= q~<option value="">--</option>~; }

    $yymain .= qq~
    <form action="$adminurl?action=ipban2" method="post">
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <td class="titlebg">
                    $admin_img{'banimg'} <b>$admin_txt{'340'}</b>
                </td>
            </tr><tr>
                <td class="catbg">
                    <label for="iban"><span class="small">$admin_txt{'724a'}</span></label>
                </td>
            </tr><tr>
                <td class="windowbg2">
                    <select id="iban" name="iban" size="20" multiple="multiple" style="min-width:45%">
                        $iban
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
            </tr><tr>
                <td class="catbg center">
                    <input type="submit" value="$admin_txt{'10'}" class="button" />
                </td>
            </tr>
        </table>
    </div>
    </form>
    <form action="$adminurl?action=ipban2" method="post">
    <div class="bordercolor borderstyle rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <td class="catbg">
                    <label for="eban"><span class="small">$admin_txt{'725b'}</span></label>
                </td>
            </tr><tr>
                <td class="windowbg2">
                    <select id="eban" name="eban" size="20" multiple="multiple" style="min-width:45%">
                        $eban
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
    </div>
    </form>
    <form action="$adminurl?action=ipban2" method="post">
    <div class="bordercolor borderstyle rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <tr>
                <td class="catbg">
                    <label for="uban"><span class="small">$admin_txt{'725c'}</span></label>
                </td>
            </tr><tr>
                <td class="windowbg2">
                    <select id="uban" name="uban" size="20" multiple="multiple" style="min-width:45%">
                        $uban
                    </select>
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
    </div>
    </form>
        <form action="$adminurl?action=ipban_add" method="post">
        <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom: .5em;">
            <colgroup>
                <col span="2" style="width: 50%" />
            </colgroup>
            <tr>
                <td class="titlebg">
                    $admin_img{'banimg'} <b>$admin_txt{'340a'}</b>
                </td>
                <td class="titlebg">
                    <b>$admin_txt{'340b'}</b>
                </td>
            </tr><tr>
                <td class="catbg" style="background-repeat:repeat-x">
                    <span class="small">$admin_txt{'724'}<br />$admin_txt{'725'}<br />$admin_txt{'725a'}</span>
                </td>
                <td class="windowbg2 vtop" rowspan="2">
                    <div style="height:30em; overflow:auto">
                    <ul>~;
    $yymain .= banlog();
    $yymain .= qq~            </ul>
                    </div>
                </td>
            </tr><tr>
                <td class="windowbg2">
               $admin_txt{'340c'}<br /><input type='radio' name='type' value='U' />$admin_txt{'340d'}
               <br /><input type='radio' name='type' value='I' checked="checked" />$admin_txt{'340e'}
               <br /><input type='radio' name='type' value='E' />$admin_txt{'307'}
               <br /><textarea rows="10" cols="100" name="banned" style="width:90%"></textarea>
                <input type="hidden" name="unban" value="1" />
                </td>
            </tr>
        </table>
    </div>
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
    </div>
    </form>
    <form action="$adminurl?action=ban_clean" method="post">
        <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell">
            <tr>
                <td class="titlebg">
                    $admin_img{'banimg'} <b>$admin_txt{'725d'}</b>
                </td>
            </tr><tr>
                <td class="catbg center">
                    <span class="small">$admin_txt{'725g'}</span><br />
                    <input type="submit" value="$admin_txt{'725e'}" class="button" />
                </td>
            </tr>
        </table>
        </div>
    </form>
~;

    $yytitle     = "$admin_txt{'340'}";
    $action_area = 'ipban';
    AdminTemplate();
    return;
}

#Admin center ban save
sub ipban2 {
    is_admin_or_gmod_or_fmod();
    my $ban_u = $FORM{'uban'};
    my $ban_e = $FORM{'eban'};
    my $ban_i = $FORM{'iban'};

    fopen( BAN, "<$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    my @myban = <BAN>;
    chomp @myban;
    fclose(BAN);

    fopen( BAN2, ">$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    my @banned_u = split /\, /sm, $ban_u;
    chomp @banned_u;
    my @banned_e = split /\, /sm, $ban_e;
    chomp @banned_e;
    my @banned_i = split /\, /sm, $ban_i;
    chomp @banned_i;
    my %seen   = ();
    my @allban = ();

    *banning = sub {
        my @in = @_;
        foreach my $item (@in) { $seen{$item} = 1 }

        foreach my $item (@myban) {
            if ( !$seen{$item} ) {
                push @allban, $item;
            }
        }
    };

    if ($ban_i) {
        banning(@banned_i);
    }
    if ($ban_u) {
        banning(@banned_u);
    }
    if ($ban_e) {
        banning(@banned_e);
    }

    foreach my $j (@allban) {
        print {BAN2} qq~$j\n~ or croak "$croak{'print'} UNBAN";
    }
    fclose(BAN2);

    $yySetLocation = qq~$adminurl?action=ipban~;
    redirectexit();
    return;
}

#Admin center ban add
sub ipban_add {
    is_admin_or_gmod();
    my $ban_in = $FORM{'banned'};
    my $type   = $FORM{'type'};

    my @banin = split /\n/xsm, $ban_in;

    fopen( BAN, "<$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    my @myban = <BAN>;
    chomp @myban;
    fclose(BAN);
    $time = time;
    *time_ban = sub {
        for my $i ( 0 .. 3 ) {
            if ( $banned[4] eq $timeban[$i] ) {
                $tmb = $banned[2] + ( $bandays[$i] * 86_400 );
            }
       }
       return $tmb;
    };
    my $ihave = 0;
    foreach my $j (@banin) {
        $j =~ tr/\r//d;
        $j =~ s/\A[\s\n]+| |[\s\n]+\Z//gsm;
        $j =~ s/\n\s*\n/\n/gsm;
        $j =~ s/@/\\@/xsm;
        foreach my $i (@myban) {
            @banned = split /\|/xsm, $i;
            $tmb = time_ban();
            if ( $banned[1] eq $j && ( $banned[4] eq 'p' || $tmb > $time ) ) {
                $ihave = 1;
            }
        }

        fopen( BAN2, ">>$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
        if ( $j && $ihave == 0 && $j ne '127.0.0.1' ) {
            print {BAN2}
              qq~$type|$j|$time|${$uid.$username}{'realname'} ($username)|p|\n~
              or croak "$croak{'print'} BAN2";
        }
        fclose(BAN2);
    }
    $yySetLocation = qq~$adminurl?action=ipban~;
    redirectexit();
    return;
}

#ipban_update moved to Sources/Security.pm

#clean the banlist of expired entries.
sub ban_clean {
    is_admin_or_gmod();

    my $time    = time;
    fopen( BAN, "<$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    my @myban = <BAN>;
    chomp @myban;
    fclose(BAN);
    fopen( BAN2, ">$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );

    *time_ban = sub {
        for my $i ( 0 .. 3 ) {
            if ( $banned[4] eq $timeban[$i] ) {
                $tmb = $banned[2] + ( $bandays[$i] * 86_400 );
            }
        }
    };
    for my $j (@myban) {
        @banned = split /\|/xsm, $j;
        if ( $banned[4] eq 'p' ) {
            print {BAN2}
              qq~$banned[0]|$banned[1]|$banned[2]|$banned[3]|$banned[4]|\n~
              or croak "$croak{'print'} BAN2";
        }
        else {
            time_ban();
            if ( $time > $tmb ) {
                print {BAN2} q{} or croak "$croak{'print'} BAN2";
            }
            else {
                print {BAN2}
                  qq~$banned[0]|$banned[1]|$banned[2]|$banned[3]|$banned[4]|\n~
                  or croak "$croak{'print'} BAN2";
            }
        }
    }
    fclose(BAN2);
    $yySetLocation = qq~$adminurl?action=ipban~;
    redirectexit();
    return;
}

sub banlog {
    fopen( BANLOG, "<$vardir/ban_log.txt" ) || fatal_error( 'cannot_open', "$vardir/ban_log.txt", 1 );
    my @mybanlog = <BANLOG>;
    chomp @mybanlog;
    fclose(BANLOG);
    my @myban = reverse sort @mybanlog;
    import Time::gmtime;
    for my $ban (@myban) {
        @banned = split /\|/xsm, $ban;
        $tm     = gmtime $banned[0];
        $year   = $tm->year + 1900;
        $mon    = $tm->mon + 1;
        $day    = $tm->mday;
        if ( $use_guardian && $use_htaccess ) {
            @banned_ip = ();
            if ( $banned[1] =~ m/\(/sm ) {
                @banned_ip = split /\(/xsm,$banned[1];
                $banned_ip[1] =~ s/\)//xsm;
                if ($banned_ip[0]) {
                    $banned_ip[0] = qq~ ( $banned_ip[0] )~;
                }
                else {$banned_ip[0] = q~~;}
            }
            else {$banned_ip[1] = $banned[1];}
            $banlog .=  qq~<li>$banned_ip[1]$banned_ip[0] - on $mon/$day/$year (<a href="$adminurl?action=guardian_block;ip=$banned_ip[1];return=ipban" onclick="return confirm('$admin_txt{'ipblock_confirm'}$banned_ip[1]');">$admin_txt{'ipblock'}</a>)</li>\n~;
        }
        else {
        $banlog .=  qq~<li>$banned[1] on $mon/$day/$year</li>\n~;
        }
    }
    return $banlog;
}

#Banning from the error log
sub ipban_err {
    is_admin_or_gmod();
    my $ip_ban  = $INFO{'ban'};
    my $lev     = $INFO{'lev'};
    my $tmb     = 0;

    my $time  = time;
    my $ihave = 0;
    $ban =~ tr/\r//d;
    $ban =~ s/\A[\s\n]+| |[\s\n]+\Z//gsm;
    $ban =~ s/\n\s*\n/\n/gsm;
    fopen( BAN, "<$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    my @myban = <BAN>;
    chomp @myban;
    fclose(BAN);

    *time_ban = sub {
        for my $i ( 0 .. 3 ) {
            if ( $banned[4] eq $timeban[$i] ) {
                $tmb = $banned[2] + ( $bandays[$i] * 84_600 );
            }
        }
        return $tmb;
    };
    foreach my $i (@myban) {
        @banned = split /\|/xsm, $i;
        if ( $banned[0] eq 'I' && $banned[1] eq $ip_ban ) {
            $tmb = time_ban();
            if ( ( $banned[4] ne 'p' && $tmb > $today ) || $banned[4] eq 'p' ) {
                $ihave = 1;
            }
        }
    }

    fopen( BAN2, ">>$vardir/banlist.txt" ) || fatal_error( 'cannot_open', "$vardir/banlist.txt", 1 );
    if ( $ip_ban && $ihave == 0 && $ip_ban ne '127.0.0.1' ) {
        print {BAN2} qq~I|$ip_ban|$time|${$uid.$username}{'realname'}|$lev|\n~
          or croak "$croak{'print'} BAN2";
    }
    fclose(BAN2);

    $yySetLocation = qq~$adminurl?action=$INFO{'return'}~;
    redirectexit();
    return;
}
1;
