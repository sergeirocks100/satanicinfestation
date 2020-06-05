#!/usr/bin/perl --
# $Id: YaBB Converter $
# $HeadURL: YaBB $
# $Source: /Convert.pl $
###############################################################################
# Convert.pl                                                                  #
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
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

$convertplver = 'YaBB 2.6.11 $Revision: 1619 $';

# conversion will stop after $max_process_time
# in seconds, than the browser will call the script
# again until all is done. Don't put it too high
# or you will run into server or browser timeout
$max_process_time = 20;
$time_to_jump     = time() + $max_process_time;

if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
    $yyIIS = 1;
    if ( $PROGRAM_NAME =~ m{(.*)(\\|/)}xsm ) {
        $yypath = $1;
    }
    $yypath =~ s/\\/\//gxsm;
    chdir $yypath;
    push @INC, $yypath;
}

### Requirements and Errors ###
$script_root = $ENV{'SCRIPT_FILENAME'};
if ( !$script_root ) {
    $script_root = $ENV{'PATH_TRANSLATED'};
    $script_root =~ s/\\/\//gxsm;
}
$script_root =~ s/\/Convert\.(pl|cgi)//igxsm;
if    ( -e './Paths.pm' )            { require Paths; }
elsif ( -e "$script_root/Paths.pm" ) { require "$script_root/Paths.pm"; }
elsif ( -e "$script_root/Variables/Paths.pm" ) {
    require "$script_root/Variables/Paths.pm";
}

if   ( -e 'YaBB.cgi' ) { $yyext = 'cgi'; }
else                   { $yyext = 'pl'; }
if   ($boardurl) { $set_cgi = "$boardurl/Convert.$yyext"; }
else             { $set_cgi = "Convert.$yyext"; }

# Make sure the module path is present
push @INC, './Modules';

require Sources::Subs;
require Sources::System;
require Sources::Load;
require Sources::DateTime;

#############################################
# Conversion starts here                    #
#############################################
$px = 'px';

# Conversion was rewritten and fixed for xx-large
# forums by Detlef Pilzecker (deti) in June 2008

# The 'our' function is available since Perl v5.6.0
# If your Perl version is lower, then comment the 'our'-lines out and use this:
# use vars qw(@categoryorder,@catboards,@catdata,@boarddata,@allboards,%catinfo,%cat,%board,%boarddata,$catfile,$boardfile,$key,$value,$cnt);
our ( @categoryorder, @catboards, @catdata, @boarddata, @allboards );
our ( %catinfo,       %cat,       %board,   %boarddata );
our ( $catfile,       $boardfile, $key,     $value,     $cnt );
our (%fixed_users);

if ( -e "$vardir/Setup.lock" ) {
    if ( -e "$vardir/Converter.lock" ) { FoundConvLock(); }

    if ( -e "$vardir/fixusers.txt" ) {
        fopen( FIXUSER, "$vardir/fixusers.txt" )
          || setup_fatal_error( "$maintext_23 $vardir/fixusers.txt: ", 1 );
        my @fixed = <FIXUSER>;
        fclose(FIXUSER);
        foreach (@fixed) {
            my ( $user, $fixedname, undef, $displayedname, undef ) =
              split /\|/xsm, $_;
            @{ $fixed_users{$user} } = ( $fixedname, $displayedname );
        }
    }

    tempstarter();
    tabmenushow();

    if ( $action && !$INFO{'convert'} ) {

        # needed for: sub conv_stringtotime
        require Time::Local;
        import Time::Local 'timegm';

    }
    elsif ( !$action || $INFO{'convert'} ) {
        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <form action="$set_cgi?action=prepare" method="post">
        <table class="cs_thin pad_4px">
            <col style="width:5%" />
            <tr>
                <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
            </tr><tr>
                <td class="windowbg center">
                    <img src="$imagesdir/thread.gif" alt="" />
                </td>
                <td class="windowbg2 fontbigger">
                    Make sure your YaBB 2.6.11 installation is running and that it has all the correct folder paths and URLs.<br />
                    Proceed through the following steps to convert your YaBB 1 Gold - SP 1.x forum to YaBB 2.6.11.<br /><br />
                    <b>If</b> your YaBB 1 Gold - SP 1.x forum is located on the same server as your YaBB 2.6.11 installation:
                    <ol>
                        <li>Insert the path to your YaBB 1 Gold - SP 1.x forum in the input field below</li>
                        <li>Click on the 'Continue' button</li>
                    </ol>
                    <b>Else</b> if your YaBB 1 Gold - SP 1.x forum is located on a different server than your YaBB 2.6.11 installation or if you do not know the path to your SP 1.x forum:
                    <ol>
                        <li>Copy all files in the /Boards, /Members, and /Messages folders from your YaBB 1 Gold - SP 1.x installation, to the corresponding Convert/Boards, Convert/Members, Convert/Messages, and Convert/Variables folders of your YaBB 2.6.11 installation, and chmod them 755.</li>
                        <li>Copy Settings.pl from the yabb folder of your YaBB 1 Gold - SP 1.x installation to the Convert/Variables folder of your YaBB 2.6.11 installation, and CHMOD it 644.</li>
                        <li>Click on the 'Continue' button</li>
                    </ol>
                    <div style="width: 100%; text-align: center;">
                        <b>Path to your YaBB 1 Gold - SP 1.x files: </b> <input type="text" name="convertdir" value="$convertdir" size="50" />
                    </div>
                    <br />
                </td>
            </tr><tr>
                <td class="catbg center" colspan="2">
                    <input type="submit" value="Continue" />
                </td>
            </tr>
        </table>
    </form>
    </div>
            ~;
    }

    if ( $action eq 'prepare' ) {
        UpdateCookie('delete');

        $username = 'Guest';
        $iamguest = '1';
        $iamadmin = q{};
        $iamgmod  = q{};
        $password = q{};
        $yyim     = q{};
        local $ENV{'HTTP_COOKIE'} = q{};
        $yyuname = q{};

        $convertdir = $FORM{'convertdir'};

        if ( !-d "$convertdir/Boards" ) {
            setup_fatal_error( "Directory: $convertdir/Boards", 1 );
        }
        else { $convboardsdir = "$convertdir/Boards"; }

        if ( !-e "$convertdir/Members/memberlist.txt" ) {
            setup_fatal_error( "File: $convertdir/Members/memberlist.txt", 1 );
        }
        else { $convmemberdir = "$convertdir/Members"; }

        if ( !-d "$convertdir/Messages" ) {
            setup_fatal_error( "Directory: $convertdir/Messages", 1 );
        }
        else { $convdatadir = "$convertdir/Messages"; }

        if ( !-e "$convertdir/Variables/cat.txt" ) {
            setup_fatal_error( "File: $convertdir/Variables/cat.txt", 1 );
        }
        else { $convvardir = "$convertdir/Variables"; }

        my $setfile = << "EOF";
\$convertdir = qq~$convertdir~;
\$convboardsdir = qq~$convertdir/Boards~;
\$convmemberdir = qq~$convertdir/Members~;
\$convdatadir = qq~$convertdir/Messages~;
\$convvardir = qq~$convertdir/Variables~;

1;
EOF

        fopen( SETTING, ">$vardir/ConvSettings.txt" )
          || setup_fatal_error( "$maintext_23 $vardir/ConvSettings.txt: ", 1 );
        print {SETTING} nicely_aligned_file($setfile)
          or croak 'cannot print SETTING';
        fclose(SETTING);

        $yytabmenu = $NavLink1a . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
        <table class="cs_thin pad_4px">
            <col style="width:5%" />
            <tr>
                <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
            </tr><tr>
                <td class="windowbg center">
                    <img src="$imagesdir/thread.gif" alt="" />
                </td>
                <td class="windowbg2 fontbigger">
                    <ul>
                        <li>Members info found in: <b>$convmemberdir</b></li>
                        <li>Board and Category info found in: <b>$convboardsdir</b></li>
                        <li>Messages info found in: <b>$convdatadir</b></li>
                        <li>cat.txt found in: <b>$convvardir</b></li>
                    </ul>
                </td>
            </tr><tr>
                <td class="windowbg center">
                    <img src="$imagesdir/info.png" alt="" />
                </td>
                <td class="windowbg2 fontbigger">
                  - Conversion can take a long time depending on the size of your forum (30 seconds to a couple hours).<br />
                  - Your browser will be refreshed automatically every $max_process_time seconds and you will see the ongoing process in the status bar.<br />
                  - Some internet connections refresh their IP-Address automatically every 24 hours.<br />
                  &nbsp; Make sure that your IP-Address will not change during conversion, or you must restart the conversion after that! <br />
                  - Your forum will be set to maintenance while converting.
                  <p id="memcontinued">Click on 'Members' in the menu to start.<br />&nbsp;</p>
                </td>
            </tr>
        </table>
    </div>
    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:red"><b>Converting - please wait!<br />If you want to stop \\'Members\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }
      </script>
            ~;
    }
    elsif ( $action eq 'members' ) {
        require qq~$vardir/ConvSettings.txt~;
        if ( !exists $INFO{'mstart1'} ) { PrepareConv(); }
        $INFO{'mstart2'} ? ConvertMembers2() : ConvertMembers1();

        $yytabmenu = $NavLink1 . $NavLink2a . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convnotdone">Board and Category Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Message Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Date &amp; Time Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                New User data files have been created.<br />
                Password encryption is done for each user the first time he/she logs in.<br />
                <br />
                You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.
                <br />
                <br />
                <p id="memcontinued">Click on 'Boards &amp; Categories' in the menu to continue.<br />
                    If you do not do that the script will continue itself in 5 Minutes.</p>
            </td>
        </tr>
    </table>
    </div>
    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:red"><b>Converting - please wait!<br />If you want to stop \\'Boards & Categories\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function membtick() {
                   PleaseWait();
                   location.href="$set_cgi?action=cats;st=$INFO{'st'}";
            }

            setTimeout("membtick()",300000);
    </script>
            ~;

        if ( -e "$vardir/fixusers.txt" ) {

            fopen( FIXUSER, "$vardir/fixusers.txt" )
              || setup_fatal_error( "$maintext_23 $vardir/fixusers.txt: ", 1 );
            my @fixed = <FIXUSER>;
            fclose(FIXUSER);
            chomp @fixed;
            foreach my $set(@fixed) {
                $set =~ s/[\r\n]//gsm;
            }
            $yymain .= qq~
    <br />
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="windowbg" colspan="5">
               Member(s) with illegal username(s) were found and converted to legal name(s).<br />
               You can find this information in the <i>$vardir/fixusers.txt</i> file. If you do not need it, you can delete it later.
            </td>
        </tr><tr>
            <td class="catbg center">Invalid name</td>
            <td class="catbg center">Fixed name</td>
            <td class="catbg center">Reg. date</td>
            <td class="catbg center">Displayed name</td>
            <td class="catbg center">E-mail</td>
        </tr>~;

            foreach my $userfixed (@fixed) {
                ( $inname, $fxname, $rgdate, $dspname, $tmail ) =
                  split /\|/xsm, $userfixed;
                $yymain .= qq~<tr>
            <td class="windowbg2">$inname</td>
            <td class="windowbg2">$fxname</td>
            <td class="windowbg2">$rgdate</td>
            <td class="windowbg2">$dspname</td>
            <td class="windowbg2">$tmail</td>
        </tr>~;
            }
            $yymain .= q~
    </table>
    </div>~;
        }
    }
    elsif ( $action eq 'members2' ) {
        if ( $INFO{'mstart1'} <= 0 || $INFO{'mstart2'} < 0 ) {
            setup_fatal_error(
"Member conversion (members2) 'mstart1' ($INFO{'mstart1'}), 'mstart2' ($INFO{'mstart2'}) error!"
            );
        }

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        my $mwidth =
          int( ( ( $INFO{'mstart2'} + $INFO{'mstart1'} ) / 2 ) /
              $INFO{'mtotal'} *
              100 );
        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                <div class="divouter">
                    <div class="divvary" style="width: $mwidth$px;">&nbsp;</div>
                </div>
                <div class="divvary2">$mwidth %</div>
                <br />
                <div class="convnotdone">Board and Category Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Message Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Date &amp; Time Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
                </td>
            </tr><tr>
                <td class="windowbg center">
                    <img src="$imagesdir/info.png" alt="" />
                </td>
                <td class="windowbg2 fontbigger">
                    To prevent server time-out due to the amount of members to be converted, the conversion is split into more steps.<br />
                    <br />
                    The time-step (\$max_process_time) is set to <i>$max_process_time seconds</i>.<br />
                    The last step took <i>~
          . ( $time_to_jump - $INFO{'starttime'} ) . q~ seconds</i>.
                    <br />
                    You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . q~ minutes</i>.
                  <br />
                  <br />
                  There are <b>~
          . int(
            $INFO{'mtotal'} - ( ( $INFO{'mstart2'} + $INFO{'mstart1'} ) / 2 ) )
          . qq~/$INFO{'mtotal'}</b> Members left to be converted.
                  <br />
                  <p id="memcontinued">If nothing happens in 5 seconds <a href="$set_cgi?action=members;st=$INFO{'st'};mstart1=$INFO{'mstart1'};mstart2=$INFO{'mstart2'}" onclick="PleaseWait();">click here to continue</a>...<br />If you want to <a href="javascript:stoptick();">STOP 'Members' conversion click here</a>. Then copy the actual browser address and type it in when you want to continue the conversion.</p>
              </td>
          </tr>
      </table>
      </div>
      <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:red"><b>Converting - please wait!<br />If you want to stop \\'Members\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function stoptick() { stop = 1; }

            stop = 0;
            function membtick() {
                  if (stop != 1) {
                        PleaseWait();
                        location.href="$set_cgi?action=members;st=$INFO{'st'};mstart1=$INFO{'mstart1'};mstart2=$INFO{'mstart2'}";
                  }
            }

            setTimeout("membtick()",2000);
      </script>
            ~;

    }
    elsif ( $action eq 'cats' ) {
        require qq~$vardir/ConvSettings.txt~;
        if ( !exists $INFO{'bstart'} || !exists $INFO{'bfstart'} ) {
            GetCats();
            CreateControl();
        }
        ConvertBoards();

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3a . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board &amp; Category Conversion.</div>
                $ConvDone
                <div class="convnotdone">Message Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Date &amp; Time Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                New forum.master file has been created.<br />
                New forum.control file has been created.<br />
                All dates in files have been converted to timestamps.<br />
                All threads have been converted.<br />
                <br />
                You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
                <br />
                <p id="memcontinued">Click on 'Messages' in the menu to continue. Otherwise the script will continue by itself in 5 minutes.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Messages\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function membtick() {
                   PleaseWait();
                   location.href="$set_cgi?action=messages;st=$INFO{'st'}";
            }

            setTimeout("membtick()",300000);
      </script>
            ~;
    }
    elsif ( $action eq 'cats2' ) {
        if (   ( !$INFO{'bstart'} && !$INFO{'bfstart'} )
            || $INFO{'bstart'} < 0
            || $INFO{'bfstart'} < 0 )
        {
            setup_fatal_error(
"Boards conversion (cats2) 'bstart' ($INFO{'bstart'}) or 'bfstart' ($INFO{'bfstart'}) error!"
            );
        }

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        my $bwidth = int( $INFO{'bstart'} / $INFO{'btotal'} * 100 );

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board and Category Conversion.</div>
                <div class="divouter">
                    <div class="divvary" style="width: $bwidth$px;">&nbsp;</div>
                </div>
                <div class="divvary2">$bwidth %</div>
                <br />
                <div class="convnotdone">Message Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Date &amp; Time Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                  To prevent server time-out due to the amount of boards to be converted, the conversion is split into more steps.<br />
                  <br />
                  The time-step (\$max_process_time) is set to <i>$max_process_time seconds</i>.<br />
                  The last step took <i>~
          . ( $time_to_jump - $INFO{'starttime'} ) . q~ seconds</i>.<br />
                  You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . q~ minutes</i>.<br />
                  <br />
                  There are <b>~
          . ( $INFO{'btotal'} - $INFO{'bstart'} )
          . qq~/$INFO{'btotal'}</b> Boards left to be converted.<br />
                  <p id="memcontinued">If nothing happens in 5 seconds <a href="$set_cgi?action=cats;st=$INFO{'st'};bstart=$INFO{'bstart'};bfstart=$INFO{'bfstart'}" onclick="PleaseWait();">click here to continue</a>...<br />If you want to <a href="javascript:stoptick();">STOP 'Boards & Categories' conversion click here</a>. Then copy the actual browser address and type it in when you are going to continue the conversion.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Boards & Categories\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function stoptick() { stop = 1; }

            stop = 0;
            function membtick() {
                  if (stop != 1) {
                        PleaseWait();
                        location.href="$set_cgi?action=cats;st=$INFO{'st'};bstart=$INFO{'bstart'};bfstart=$INFO{'bfstart'}";
                  }
            }

            setTimeout("membtick()",2000);
      </script>
            ~;
    }
    elsif ( $action eq 'messages' ) {
        require qq~$vardir/ConvSettings.txt~;
        ConvertMessages();

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4a . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
       </tr><tr>
           <td class="windowbg center">
               <img src="$imagesdir/thread.gif" alt="" />
           </td>
           <td class="windowbg2">
               <div class="convdone">Member Conversion.</div>
               $ConvDone
               <div class="convdone">Board and Category Conversion.</div>
               $ConvDone
               <div class="convdone">Message Conversion.</div>
               $ConvDone
               <div class="convnotdone">Date &amp; Time Conversion.</div>
               $ConvNotDone
               <div class="convnotdone">Final Cleanup.</div>
               $ConvNotDone
           </td>
       </tr><tr>
           <td class="windowbg center">
               <img src="$imagesdir/info.png" alt="" />
           </td>
           <td class="windowbg2 fontbigger">
               New style message files have been created.<br />
               <br />
               <i>$INFO{'total_threads'}</i> Threads have been converted.<br />
               <i>$INFO{'total_mess'}</i> Messages have been converted.<br />
               <br />
               You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
               <br />
               <p id="memcontinued">Click on 'Date &amp; Time' in the menu to continue.<br />
               If you do not do that the script will continue by itself in 5 minutes.</p>
           </td>
       </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Date &amp; Time\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function membtick() {
                   PleaseWait();
                   location.href="$set_cgi?action=dates;st=$INFO{'st'}";
            }

            setTimeout("membtick()",300000);
      </script>
            ~;
    }
    elsif ( $action eq 'messages2' ) {
        if (   ( !$INFO{'count'} && !$INFO{'tcount'} )
            || $INFO{'count'} < 0
            || $INFO{'tcount'} < 0 )
        {
            setup_fatal_error(
"Message conversion (messages2) 'count' ($INFO{'count'}) or 'tcount' ($INFO{'tcount'}) error!",
                1
            );
        }

        my $bwidth = int( $INFO{'count'} / $INFO{'totboard'} * 100 );
        my $mwidth =
          $INFO{'totmess'}
          ? int( $INFO{'tcount'} / $INFO{'totmess'} * 100 )
          : 0;

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board and Category Conversion.</div>
                $ConvDone
                <div class="convdone">Message Conversion.</div>
                <div class="divouter">
                    <div class="divvary" style="width: $bwidth$px;">&nbsp;</div>
                </div>
                <div class="divvary2">$bwidth %</div><br />
                <div class="convnotdone">Date &amp; Time Conversion.</div>
                $ConvNotDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                To prevent server time-out due to the amount of messages to be converted, the conversion is split into more steps.<br />
                <br />
                The time-step (\$max_process_time) is set to <i>$max_process_time seconds</i>.<br />
                The last step took <i>~
          . ( $time_to_jump - $INFO{'starttime'} ) . q~ seconds</i>.<br />
                  You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
                <br />
                <i>$INFO{'total_threads'}</i> Threads where converted until now.<br />
                <i>$INFO{'total_mess'}</i> Messages where converted until now.<br />
                <br />
                There are <b>~
          . ( $INFO{'totboard'} - $INFO{'count'} )
          . qq~/$INFO{'totboard'}</b> Boards left, to convert the Messages in.<br />
                <div style="float: left;">There are <b>~
          . ( $INFO{'totmess'} - $INFO{'tcount'} )
          . qq~/$INFO{'totmess'}</b> Threads left in the actual Board to be converted. &nbsp; </div>
                <div class="divouter">
                    <div class="divvary" style="width: $mwidth$px;">&nbsp;</div>
                </div>
                <div class="divvary2">$mwidth %</div>
                <br />
                <p id="memcontinued">If nothing happens in 5 seconds <a href="$set_cgi?action=messages;st=$INFO{'st'};count=$INFO{'count'};tcount=$INFO{'tcount'};total_mess=$INFO{'total_mess'};total_threads=$INFO{'total_threads'}" onclick="PleaseWait();">click here to continue</a>...<br />If you want to <a href="javascript:stoptick();">STOP 'Messages' conversion click here</a>. Then copy the actual browser address and type it in when you are going to continue the conversion.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Messages\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function stoptick() { stop = 1; }

            stop = 0;
            function membtick() {
                  if (stop != 1) {
                        PleaseWait();
                        location.href="$set_cgi?action=messages;st=$INFO{'st'};count=$INFO{'count'};tcount=$INFO{'tcount'};total_mess=$INFO{'total_mess'};total_threads=$INFO{'total_threads'}";
                  }
            }

            setTimeout("membtick()",2000);
      </script>
            ~;

    }
    elsif ( $action eq 'dates' ) {
        require qq~$vardir/ConvSettings.txt~;
        ConvertTimeToString();

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5a . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board &amp; Category Conversion.</div>
                $ConvDone
                <div class="convdone">Message Conversion.</div>
                $ConvDone
                <div class="convdone">Date &amp; Time Conversion.</div>
                $ConvDone
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                New style timestamps have been created throughout the board. All old style dates have been converted.<br />
                <br />
                You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
                <br />
                <p id="memcontinued">Click on 'Clean Up' in the menu to continue.<br />
                    If you do not do that the script will continue by itself in 5 minutes.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Clean Up\\', click here on STOP before this red message appears again on next page.</b></span>';
            }

            function membtick() {
                   PleaseWait();
                   location.href="$set_cgi?action=cleanup;st=$INFO{'st'}";
            }

            setTimeout("membtick()",300000);
    </script>
            ~;

    }
    elsif ( $action eq 'dates2' ) {
        require qq~$vardir/ConvSettings.txt~;
        if ( $INFO{'pollfile'} <= 0 && $INFO{'polledfile'} <= 0 ) {
            setup_fatal_error(
"Date &amp; Time conversion (dates2) error! pollfile($INFO{'pollfile'}), polledfile($INFO{'polledfile'})",
                1
            );
        }

        my $pollwidth =
          ( $INFO{'totalpolls'} && $INFO{'pollfile'} )
          ? int( $INFO{'pollfile'} / $INFO{'totalpolls'} * 100 )
          : 100;
        $INFO{'pollfile'} =
          $INFO{'pollfile'} ? $INFO{'pollfile'} : $INFO{'totalpolls'};
        my $polledwidth =
          ( $INFO{'totalpolled'} && $INFO{'polledfile'} )
          ? int( $INFO{'polledfile'} / $INFO{'totalpolled'} * 100 )
          : 0;
        $INFO{'polledfile'} =
          $INFO{'polledfile'} ? $INFO{'polledfile'} : $INFO{'totalpolled'};

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board &amp; Category Conversion.</div>
                $ConvDone
                <div class="convdone">Message Conversion.</div>
                $ConvDone
                <div class="convdone">Date &amp; Time Conversion.</div>
                <div class="divouter_center">
                  See info below!
                </div>
                <div class="divvary2">--- %</div><br />
                <div class="convnotdone">Final Cleanup.</div>
                $ConvNotDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
               To prevent server time-out due to the amount of Date &amp; Time conversion, the conversion is split into more steps.<br />
               <br />
               The time-step (\$max_process_time) is set to <i>$max_process_time seconds</i>.<br />
               The last step took <i>~
          . ( $time_to_jump - $INFO{'starttime'} ) . q~ seconds</i>.<br />
                  You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . q~ minutes</i>.<br />
               <br />
               <div class="totals">There are <b>~
          . ( $INFO{'totalpolls'} - $INFO{'pollfile'} )
          . qq~/$INFO{'totalpolls'}</b> Polls left to be converted. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="width: $pollwidth$px;">&nbsp;</div>
                    </div>
                    <div class="divvary2">$pollwidth %</div>
                </div>
                <br /><br />
                <div class="totals">There are <b>~
          . ( $INFO{'totalpolled'} - $INFO{'polledfile'} )
          . qq~/$INFO{'totalpolled'}</b> Polled-Files left to be converted. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="width: $polledwidth$px;">&nbsp;</div>
                    </div>
                    <div class="divvary2">$polledwidth %</div>
                </div>
                <br /><br />
                <p id="memcontinued">If nothing happens in 5 seconds <a href="$set_cgi?action=dates;st=$INFO{'st'};timeconv=$INFO{'timeconv'};pollfile=$INFO{'pollfile'};totalpolls=$INFO{'totalpolls'};polledfile=$INFO{'polledfile'}" onclick="PleaseWait();">click here to continue</a>...<br />If you want to <a href="javascript:stoptick();">STOP 'Date &amp; Time' conversion click here</a>. Then copy the actual browser address and type it in when you are going to continue the conversion.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Date &amp; Time\\' conversion, click here on STOP before this red message appears again on next page.</b></span>';
            }

            function stoptick() { stop = 1; }

            stop = 0;
            function membtick() {
                  if (stop != 1) {
                        PleaseWait();
                        location.href="$set_cgi?action=dates;st=$INFO{'st'};timeconv=$INFO{'timeconv'};pollfile=$INFO{'pollfile'};totalpolls=$INFO{'totalpolls'};polledfile=$INFO{'polledfile'}";
                  }
            }

            setTimeout("membtick()",2000);
      </script>
            ~;

    }
    elsif ( $action eq 'cleanup' ) {
        require qq~$vardir/ConvSettings.txt~;
        require "$boardsdir/forum.master";

        if ( !$INFO{'clean'} ) {
            fopen( FORUMTOTALS, ">>$boardsdir/forum.totals" )
              || setup_fatal_error( "Can not open $boardsdir/forum.totals", 1 );
            foreach my $testboard (@allboards) {
                $testboard =~ s/[\r\n]//gsm;
                chomp $testboard;
                if ( -e "$convboardsdir/$testboard.ttl" ) {
                    fopen( BOARDTTL, "$convboardsdir/$testboard.ttl" )
                      || setup_fatal_error(
                        "Can not open $convboardsdir/$testboard.ttl", 1 );
                    my $line = <BOARDTTL>;
                    fclose(BOARDTTL);
                    chomp $line;
                    $line =~ s/[\r\n]//gsm;
                    print {FORUMTOTALS} "$testboard|$line|\n"
                      or croak 'cannot print FORUMTOTALS';

                    #unlink "$convboardsdir/$testboard.ttl";
                }
            }
            print {FORUMTOTALS} "recycle|0|0|N/A|N/A||||\n"
              or croak 'cannot print FORUMTOTALS';
            print {FORUMTOTALS} "announcements|0|0|N/A|N/A||||\n"
              or croak 'cannot print FORUMTOTALS';
            $firstmstime = time();
            print {FORUMTOTALS} "general|1|1|$firstmstime|admin|$firstmstime|0|Welcome to your new YaBB 2.6.11 forum!|xx|0|\n"
              or croak 'cannot print FORUMTOTALS';
            fclose(FORUMTOTALS);
            fopen ( FIRSTMS, ">$datadir/$firstmstime.txt");
            my $initmail = 'webmaster@mysite.com';
            print {FIRSTMS} qq~Welcome to your New YaBB 2.6.11 Forum!|Administrator|$initmail|$firstmstime|admin|xx|0|127.0.0.1|Welcome to your new YaBB 2.6.11 forum.<br /><br />The YaBB team would like to thank you for choosing Yet another Bulletin Board for your forum needs. We pride ourselves on the cost (FREE), the features, and the security. Visit http://www.yabbforum.com to view the latest development information, read YaBB news, and participate in community discussions.<br /><br />Make sure you login to your new forum as an administrator and visit the Admin Center. From there, you can maintain your forum. You'll want to look at all of the settings, membergroups, categories/boards, and security options to make sure they are set properly according to your needs.||||\n~;
            fclose(FIRSTMS);
            fopen (FIRSTMSC, ">$datadir/$firstmstime.ctb");
            $msgdat = timeformat( $firstmstime, 1, 'rfc' );
            print {FIRSTMSC} qq~### ThreadID: $firstmstime, LastModified: $msgdat  ###

'board',"general"
'replies',"0"
'views',"1"
'lastposter',"admin"
'lastpostdate',"$firstmstime"
'threadstatus',"0"
'repliers',"$firstmstime|admin|0"~;
            fclose (FIRSTMSC);
            fopen ( FIRSTBRD, ">>$boardsdir/general.txt");
            print {FIRSTBRD} qq~$firstmstime|Welcome to your New YaBB 2.6 Forum!|Administrator|$initmail|$firstmstime|0|admin|xx|0\n~;
            fclose (FIRSTBRD);

            $yySetLocation =
                qq~$set_cgi?action=cleanup2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;clean=1;pass_error=1;total_boards=~
              . @allboards;
            redirectexit();
        }
        if ( $INFO{'clean'} == 1 ) { MyReCountTotals(); }
        if ( $INFO{'clean'} == 2 ) { MyMemberIndex(); }
        if ( $INFO{'clean'} == 3 ) { MyMailNotify(); }
        if ( $INFO{'clean'} == 4 ) { FixNopost(); }

        if ( $INFO{'tmp_firstforum'} > $INFO{'firstforum'} ) {
            $setforumstart = timeformat( $INFO{'tmp_firstforum'} );
            $firstmember   = timeformat( $INFO{'firstforum'} );
            $forumstarttext =
qq~The Forum Start date was set to $setforumstart but the first member was registered $firstmember. So we changed the Forum Start Date to $firstmember.~;
        }

        $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6a;

        $formsession = cloak("$mbname$username");

        if ( -e "$convmemberdir/admin.dat" ) {
            $convtext .=
q~<br /><br />After you have tested your forum and made sure everything was converted correctly you can go to your Admin Center and delete /Convert/Boards, /Convert/Members, /Convert/Messages and /Convert/Variables folders and their contents.~;
        }

        if ( -e "$vardir/fixusers.txt" ) {
            $convtext .=
qq~<br /><br />There were some illegal user IDs. These have been changed. Please inform those users of these changes. You can find the list in the $vardir/fixusers.txt~;
        }

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board and Category Conversion.</div>
                $ConvDone
                <div class="convdone">Message Conversion.</div>
                $ConvDone
                <div class="convdone">Date &amp; Time Conversion.</div>
                $ConvDone
                <div class="convdone">Final Cleanup.</div>
                $ConvDone
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                $forumstarttext
                $convtext<br />
                <br />
                The conversion took <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
                <br />
                <br />
                <span style="color:#f00">We recommend you delete the file "$ENV{'SCRIPT_NAME'}". This is to prevent someone else running the converter and damaging your files.<br />
                <br />
                Further more, we strongly recommend to run the following "Maintenance Controls" in the "Admin Center" before you start doing other things:<br />
                - Rebuild Message Index<br />
                - Recount Board Totals<br />
                - Rebuild Members List<br />
                - Recount Membership<br />
                - Rebuild Members History<br />
                - Rebuild Notifications Files<br />
                - Clean Users Online Log<br />
                - Attachment Functions => Rebuild Attachments<br /></span>
                <br />
                <br />
                You may now log in to your forum. If your old forum had Extended Profiles installed, you should turn on Extended Profiles in Admin Center -&gt; Forum Settings -&gt; Members and run the Extended Profiles converter from Admin Center -&gt; Profile Fields. Enjoy using YaBB 2.6.11!
            </td>
        </tr><tr>
            <td class="catbg center" colspan="2">
                <form action="YaBB.$yyext" method="post" style="display: inline;">
                    <input type="submit" value="Start" />
                    <input type="hidden" name="formsession" value="$formsession" />
                </form>
            </td>
        </tr>
    </table>
    </div>~;
    CreateConvLock();
    }

    elsif ( $action eq 'setup3' )       { CheckInstall(); }
    elsif ( $action eq 'cleanup2' ) {
        if (   ( !$INFO{'pass_error'} && $INFO{'my_re_tot'} <= 0 )
            && $INFO{'memb_index'} <= 0
            && $INFO{'my_mail_n'} <= 0
            && $INFO{'fix_nopost'} <= 1 )
        {
            setup_fatal_error(
"Clean Up (cleanup2) error! pass_error($INFO{'pass_error'}), my_re_tot($INFO{'my_re_tot'}), memb_index($INFO{'memb_index'}), my_mail_n($INFO{'my_mail_n'})",
                1
            );
        }

        my $re_tot_width =
          ( $INFO{'total_re_tot'} && $INFO{'my_re_tot'} )
          ? int( $INFO{'my_re_tot'} / $INFO{'total_re_tot'} * 100 )
          : ( $INFO{'total_re_tot'} ? 100 : 0 );
        $INFO{'my_re_tot'} =
          $INFO{'my_re_tot'} ? $INFO{'my_re_tot'} : $INFO{'total_re_tot'};
        my $memb_index_width =
          ( $INFO{'total_memb'} && $INFO{'memb_index'} )
          ? int( $INFO{'memb_index'} / $INFO{'total_memb'} * 100 )
          : ( $INFO{'total_memb'} ? 100 : 0 );
        $INFO{'memb_index'} =
          $INFO{'memb_index'} ? $INFO{'memb_index'} : $INFO{'total_memb'};
        my $mail_not_width =
          ( $INFO{'total_mail_n'} && $INFO{'my_mail_n'} )
          ? int( $INFO{'my_mail_n'} / $INFO{'total_mail_n'} * 100 )
          : ( $INFO{'total_mail_n'} ? 100 : 0 );
        $INFO{'my_mail_n'} =
          $INFO{'my_mail_n'} ? $INFO{'my_mail_n'} : $INFO{'total_mail_n'};
        my $nopost_width =
          $INFO{'total_nopost'}
          ? int( $INFO{'fix_nopost'} / $INFO{'total_nopost'} * 100 )
          : 0;

        $yytabmenu =  $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

        $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <col style="width:5%" />
        <tr>
            <td class="tabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/thread.gif" alt="" />
            </td>
            <td class="windowbg2">
                <div class="convdone">Member Conversion.</div>
                $ConvDone
                <div class="convdone">Board &amp; Category Conversion.</div>
                $ConvDone
                <div class="convdone">Message Conversion.</div>
                $ConvDone
                <div class="convdone">Date &amp; Time Conversion.</div>
                $ConvDone
                <div class="convdone">Final Cleanup.</div>
                <div class="divouter_center">
                    See info below!
                </div>
                <div class="divvary2">--- %</div>
            </td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2 fontbigger">
                To prevent server time-out due to the amount to Clean Up, the Cleanup is split into more steps.<br />
                <br />
                The time-step (\$max_process_time) is set to <i>$max_process_time seconds</i>.<br />
                The last step took <i>~
          . ( $time_to_jump - $INFO{'starttime'} ) . q~ seconds</i>.<br />
                You are converting <i>~
          . int( ( $INFO{'st'} + 60 ) / 60 ) . qq~ minutes</i>.<br />
                <br />
                <div class="totals">There are <b>0/$INFO{'total_boards'}</b> Boards (1) left to be recounted. &nbsp; </div>
                <div class="divouter">
                    <div class="divvary" style="width: 100px">&nbsp;</div>
                </div>
                <div class="divvary2">100 %</div>
                </div>
                <br /><br />
                <div class="totals">There are <b>~
          . ( $INFO{'total_re_tot'} - $INFO{'my_re_tot'} )
          . qq~/$INFO{'total_re_tot'}</b> Boards (2) left to be recounted. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="$re_tot_width$px">&nbsp;</div>
                    </div>
                    <div class="divvary2">$re_tot_width %</div>
                </div>
                <br /><br />
                <div class="totals">There are <b>~
          . ( $INFO{'total_memb'} - $INFO{'memb_index'} )
          . qq~/$INFO{'total_memb'}</b> Members left to be recounted. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="$mem_index_width$px">&nbsp;</div>
                    </div>
                    <div class="divvary2">$memb_index_width %</div>
                </div>
                <br /><br />
                <div class="totals">There are <b>~
          . ( $INFO{'total_mail_n'} - $INFO{'my_mail_n'} )
          . qq~/$INFO{'total_mail_n'}</b> Notifications left to be written new. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="$mail_not_width$px">&nbsp;</div>
                    </div>
                    <div class="divvary2">$mail_not_width %</div>
                </div>
                <br /><br />
                <div class="totals">There are <b>~
          . ( $INFO{'total_nopost'} - $INFO{'fix_nopost'} )
          . qq~/$INFO{'total_nopost'}</b> NoPost-Membergroups left to be updated. &nbsp; </div>
                    <div class="divouter">
                        <div class="divvary" style="$nopost_width$px">&nbsp;</div>
                    </div>
                    <div class="divvary2">$nopost_width %</div>
                </div>
                <br /><br />
                <p id="memcontinued">If nothing happens in 5 seconds <a href="$set_cgi?action=cleanup;st=$INFO{'st'};clean=$INFO{'clean'};total_boards=$INFO{'total_boards'};total_re_tot=$INFO{'total_re_tot'};my_re_tot=$INFO{'my_re_tot'};tmp_firstforum=$INFO{'tmp_firstforum'};firstforum=$INFO{'firstforum'};siglength=$INFO{'siglength'};total_memb=$INFO{'total_memb'};memb_index=$INFO{'memb_index'};total_mail_n=$INFO{'total_mail_n'};my_mail_n=$INFO{'my_mail_n'};total_nopost=$INFO{'total_nopost'};fix_nopost=$INFO{'fix_nopost'}" onclick="PleaseWait();">click here to continue</a>...<br />If you want to <a href="javascript:stoptick();">STOP 'Clean Up' conversion click here</a>. Then copy the actual browser address and type it in when you are going to continue the conversion.</p>
            </td>
        </tr>
    </table>
    </div>

    <script type="text/javascript">
            function PleaseWait() {
                  document.getElementById("memcontinued").innerHTML = '<span style="color:#f00"><b>Converting - please wait!<br />If you want to stop \\'Clean Up\\', click here on STOP before this red message appears again on next page.</b></span>';
            }

            function stoptick() { stop = 1; }

            stop = 0;
            function membtick() {
                  if (stop != 1) {
                        PleaseWait();
                        location.href="$set_cgi?action=cleanup;st=$INFO{'st'};clean=$INFO{'clean'};total_boards=$INFO{'total_boards'};total_re_tot=$INFO{'total_re_tot'};my_re_tot=$INFO{'my_re_tot'};tmp_firstforum=$INFO{'tmp_firstforum'};firstforum=$INFO{'firstforum'};siglength=$INFO{'siglength'};total_memb=$INFO{'total_memb'};memb_index=$INFO{'memb_index'};total_mail_n=$INFO{'total_mail_n'};my_mail_n=$INFO{'my_mail_n'};total_nopost=$INFO{'total_nopost'};fix_nopost=$INFO{'fix_nopost'}";
                  }
            }

            setTimeout("membtick()",2000);
      </script>
            ~;
    }

    $yyim    = 'You are running the YaBB 2.6.11 Converter.';
    $yytitle = 'YaBB 2.6.11 Converter';
    SetupTemplate();
}

# Prepare Conversion ##

sub PrepareConv {
    fopen( FILE, ">$boardsdir/dummy.testfile" ) || setup_fatal_error(
"The CHMOD of the $boardsdir is not set correctly! Cannot write this directory!",
        1
    );
    print {FILE} "dummy testfile\n" or croak 'cannot print FILE';
    fclose(FILE);
    opendir( BDIR, $boardsdir ) || setup_fatal_error(
"The CHMOD of the $boardsdir is not set correctly! Cannot read this directory! ",
        1
    );
    @boardlist = readdir BDIR;
    closedir BDIR;

    fopen( FILE, ">$memberdir/dummy.testfile" ) || setup_fatal_error(
"The CHMOD of the $memberdir is not set correctly! Cannot write this directory!",
        1
    );
    print {FILE} "dummy testfile\n" or croak 'cannot print FILE';
    fclose(FILE);
    opendir( MBDIR, $memberdir ) || setup_fatal_error(
"The CHMOD of the $memberdir is not set correctly! Cannot read this directory! ",
        1
    );
    @memblist = readdir MBDIR;
    closedir MBDIR;

    fopen( FILE, ">$datadir/dummy.testfile" ) || setup_fatal_error(
"The CHMOD of the $datadir is not set correctly! Cannot write this directory!",
        1
    );
    print {FILE} "dummy testfile\n" or croak 'cannot print FILE';
    fclose(FILE);
    opendir( MSDIR, $datadir ) || setup_fatal_error(
"The CHMOD of the $datadir is not set correctly! Cannot read this directory! ",
        1
    );
    @msglist = readdir MSDIR;
    closedir MSDIR;

    automaintenance('on');

    unlink "$vardir/fixusers.txt";

    foreach my $file (@boardlist) {
        if (   $file ne '.htaccess'
            && $file ne 'index.html'
            && $file ne 'forum.control'
            && $file ne q{.}
            && $file ne q{..} )
        {
            unlink "$boardsdir/$file";
        }
    }
    foreach my $file (@memblist) {
        if (   $file ne '.htaccess'
            && $file ne 'index.html'
            && $file ne 'admin.vars'
            && $file ne q{.}
            && $file ne q{..} )
        {
            unlink "$memberdir/$file";
        }
    }
    foreach my $file (@msglist) {
        if (   $file ne '.htaccess'
            && $file ne 'index.html'
            && $file ne q{.}
            && $file ne q{..} )
        {
            unlink "$datadir/$file";
        }
    }
    return;
}

# / Prepare Conversion ##

# Member Conversion ##

sub ConvertMembers1 {
    fopen( MEMDIR, "$convmemberdir/memberlist.txt" )
      || setup_fatal_error( "$maintext_23 $convmemberdir/memberlist.txt: ", 1 );
    my @memlist = <MEMDIR>;
    fclose(MEMDIR);
    chomp @memlist;

    for my $i ( ( $INFO{'mstart1'} || 0 ) .. ( @memlist - 1 ) ) {
        $uname = $memlist[$i];
        chomp $uname;

        next if !-e "$convmemberdir/$uname.dat";

        if ( $uname =~ /[^\w\+\-\.\@]|guest/ixsm ) {
            IllegalUser($uname);
        }
        else {
            MyUpdateUser($uname);
        }

        if ( time() > $time_to_jump && ( $i + 1 ) < @memlist ) {
            $yySetLocation =
                qq~$set_cgi?action=members2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;mtotal=~
              . @memlist
              . q~;mstart1=~
              . ( $i + 1 );
            redirectexit();
        }
    }

    $INFO{'mstart1'} = @memlist;

    if ( -e "$convvardir/MemberStats.txt" ) { groupconvert(); }
    else { memgrpconvert();}

    if ( -e "$vardir/fixusers.txt" ) {
        fopen( FIXUSER, "$vardir/fixusers.txt" )
          || setup_fatal_error( "$maintext_23 $vardir/fixusers.txt: ", 1 );
        my @fixed = <FIXUSER>;
        fclose(FIXUSER);
        foreach (@fixed) {
            my ( $user, $fixedname, undef, $displayedname, undef ) =
              split /\|/xsm, $_;
            @{ $fixed_users{$user} } = ( $fixedname, $displayedname );
        }
    }

    ConvertMembers2();
    return;
}

sub IllegalUser {
    my ($user) = @_;

    my $fixeduser = $user;
    $fixeduser =~ s/[^\w\+\-\.\@]|guest//gixm;
    if ( !$fixeduser ) { $fixeduser = 'fixeduser'; }
    $fixeduser = check_existence( $memberdir, "$fixeduser.vars" );
    $fixeduser =~ s/(\S+?)(\.\S+$)/$1/xm;

    fopen( LOADOLDUSER, "$convmemberdir/$user.dat" )
      || setup_fatal_error( "$maintext_23 $convmemberdir/$user.dat: ", 1 );
    my @settings = <LOADOLDUSER>;
    fclose(LOADOLDUSER);
    chomp @settings;
    foreach my $set(@settings) {
        $set = s/[\r\n]//gsm;
    }
    chomp @settings;

    my ( $pmignorelist, $pmnotify, $pmpopup, $pmspop );
    if ( -e "$convmemberdir/$user.imconfig" ) {
        fopen( PMUSER, "$convmemberdir/$user.imconfig" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.imconfig: ",
            1 );
        @pmconfics = <PMUSER>;
        fclose(PMUSER);
        chomp $pmconfics[0];
        chomp $pmconfics[1];
        chomp $pmconfics[3];
        chomp $pmconfics[5];
        $pmignorelist = $pmconfics[0];
        $pmnotify     = $pmconfics[1] ? 3 : 0;
        $pmpopup      = $pmconfics[3];
        $pmspop       = $pmconfics[5];
    }

    my ( $lastonline, $lastpost, $lastim );
    if ( -e "$convmemberdir/$user.ll" ) {
        fopen( LLFILE, "$convmemberdir/$user.ll" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.ll: ", 1 );
        ( $lastonline, $lastpost, $lastim ) = <LLFILE>;
        fclose(LLFILE);
        chomp $lastonline;
        chomp $lastpost;
        chomp $lastim;
        $lastonline =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
        $lastpost =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
        $lastim =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
    }

    if ( -e "$convmemberdir/$user.yam" ) {
        fopen( YAMFILE, "$convmemberdir/$user.yam" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.yam: ", 1 );
        my @ipsettings = <YAMFILE>;
        fclose(YAMFILE);
        chomp $ipsettings[1];
        ( $c_ip_one, $c_ip_two, $c_ip_three ) = split /\|/xsm, $ipsettings[1];
        if ( $c_ip_one   eq '0' ) { $c_ip_one   = q{}; }
        if ( $c_ip_two   eq '0' ) { $c_ip_two   = q{}; }
        if ( $c_ip_three eq '0' ) { $c_ip_three = q{}; }
    }

    $settings[14] = format_timestring( $settings[14] );

    $regitime = "$settings[14]";
    $regitime =~
s/(\d{2}\/\d{2}\/\d{2,4}).*?(\d{2}\:\d{2}\:\d{2})/&conv_stringtotime("$1 at $2")/eism;

    if   ($default_template) { $new_template = $default_template; }
    else                     { $new_template = q~Forum default~; }

    if ( $settings[1] eq q{} ) { $settings[1] = $user; }

    if ( $settings[5] ) {
        $settings[5] =~ s/&&/&amp;&amp;/gxsm;
        $settings[5] =~ s/\"/&quot;/gxsm;       #";
        $settings[5] =~ s/\[size=([+-]?\d)\](.*?)\[\/size\]/ '\[size=' . conv_size($1) . "\]$2\[\/size\]" /igesm;
        $settings[5] =~ s/<br>/<br \/>/igsm;
    }

    my @location = split /,|\|/xsm, $settings[15];
    shift @location;

    %{ $uid . $fixeduser } = (
        'password' => "$settings[0]",
        'realname' => "$settings[1]",
        'email'    => "$settings[2]",
        'webtitle' => "$settings[3]",
        'weburl'   => (
            ( $settings[4] && $settings[4] !~ m{\Ahttps?://}sm )
            ? 'http://'
            : q{}
          )
          . $settings[4],
        'signature'     => "$settings[5]",
        'postcount'     => "$settings[6]",
        'position'      => "$settings[7]",
        'icq'           => "$settings[8]",
        'aim'           => "$settings[9]",
        'yim'           => "$settings[10]",
        'gender'        => "$settings[11]",
        'usertext'      => "$settings[12]",
        'userpic'       => "$settings[13]",
        'regdate'       => "$settings[14]",
        'regtime'       => "$regitime",
        'location'      => join( ', ', grep { $_ } @location ),
        'bday'          => "$settings[16]",
        'timeselect'    => "$settings[17]",
        'timeoffset'    => "$timeoffset",
        'hidemail'      => ( $settings[19] ? 1 : 0 ),
        'gtalk'         => "$settings[32]",
        'template'      => "$new_template",
        'language'      => "$language",
        'lastonline'    => "$lastonline",
        'lastpost'      => "$lastpost",
        'lastim'        => "$lastim",
        'im_ignorelist' => "$pmignorelist",
        'notify_me'     => "$pmnotify",
        'im_popup'      => ( $pmpopup ? 1 : 0 ),
        'im_imspop'     => ( $pmspop ? 1 : 0 ),
        'cathide'       => "$settings[30]",
        'postlayout'    => ( $settings[31] ? "$settings[31]|0" : q{} ),
        'dsttimeoffset' => "$dstoffset",
        'pageindex'     => '1|1|1',
        'lastips'       => "$c_ip_one|$c_ip_two|$c_ip_three",
    );

    UserAccount( $fixeduser, 'update' );

    fopen( FIXUSER, ">>$vardir/fixusers.txt" )
      || setup_fatal_error( "$maintext_23 $vardir/fixusers.txt: ", 1 );
    print {FIXUSER} "$user|$fixeduser|$settings[14]|$settings[1]|$settings[2]\n"
      or croak 'cannot print FIXUSER';
    fclose(FIXUSER);

    if ( $fixeduser ne $username ) { undef %{ $uid . $fixeduser }; }
    return;
}

sub MyUpdateUser {
    my ($user) = @_;

    fopen( LOADOLDUSER, "$convmemberdir/$user.dat" )
      || setup_fatal_error( "$maintext_23 $convmemberdir/$user.dat: ", 1 );
    my @settings = <LOADOLDUSER>;
    fclose(LOADOLDUSER);
    foreach my $set(@settings) {
        $set =~ s/[\r\n]//gsm;
    }
    chomp @settings;

    my ( $pmignorelist, $pmnotify, $pmpopup, $pmspop );
    if ( -e "$convmemberdir/$user.imconfig" ) {
        fopen( PMUSER, "$convmemberdir/$user.imconfig" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.imconfig: ",
            1 );
        @pmconfics = <PMUSER>;
        fclose(PMUSER);
        chomp $pmconfics[0];
        chomp $pmconfics[1];
        chomp $pmconfics[3];
        chomp $pmconfics[5];
        $pmignorelist = $pmconfics[0];
        $pmnotify     = $pmconfics[1] ? 3 : 0;
        $pmpopup      = $pmconfics[3];
        $pmspop       = $pmconfics[5];
    }

    my ( $lastonline, $lastpost, $lastim );
    if ( -e "$convmemberdir/$user.ll" ) {
        fopen( LLFILE, "$convmemberdir/$user.ll" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.ll: ", 1 );
        ( $lastonline, $lastpost, $lastim ) = <LLFILE>;
        fclose(LLFILE);
        chomp $lastonline;
        chomp $lastpost;
        chomp $lastim;
        $lastonline =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
        $lastpost =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
        $lastim =~
s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
    }

    if ( -e "$convmemberdir/$user.yam" ) {
        fopen( YAMFILE, "$convmemberdir/$user.yam" )
          || setup_fatal_error( "$maintext_23 $convmemberdir/$user.yam: ", 1 );
        my @ipsettings = <YAMFILE>;
        fclose(YAMFILE);
        chomp $ipsettings[1];
        ( $c_ip_one, $c_ip_two, $c_ip_three ) = split /\|/xsm, $ipsettings[1];
        if ( $c_ip_one   eq '0' ) { $c_ip_one   = q{}; }
        if ( $c_ip_two   eq '0' ) { $c_ip_two   = q{}; }
        if ( $c_ip_three eq '0' ) { $c_ip_three = q{}; }
    }

    $settings[14] = format_timestring( $settings[14] );

    $regitime = "$settings[14]";
    $regitime =~
s/(\d{2}\/\d{2}\/\d{2,4}).*?(\d{2}\:\d{2}\:\d{2})/&conv_stringtotime("$1 at $2")/eism;

    if   ($default_template) { $new_template = $default_template; }
    else                     { $new_template = q~Forum default~; }

    if ( $settings[1] eq q{} ) { $settings[1] = $user; }

    if ( $settings[5] ) {
        $settings[5] =~ s/&&/&amp;&amp;/gxsm;
        $settings[5] =~ s/\"/&quot;/gxsm;       #";
        $settings[5] =~
s/\[size=([+-]?\d)\](.*?)\[\/size\]/ '\[size=' . conv_size($1) . "\]$2\[\/size\]" /igesm;
        $settings[5] =~ s/<br>/<br \/>/igxsm;
    }

    my @location = split /,|\|/xsm, $settings[15];
    shift @location;

    %{ $uid . $user } = (
        'password' => "$settings[0]",
        'realname' => "$settings[1]",
        'email'    => "$settings[2]",
        'webtitle' => "$settings[3]",
        'weburl'   => (
            ( $settings[4] && $settings[4] !~ m{\Ahttps?://}sm )
            ? 'http://'
            : q{}
          )
          . $settings[4],
        'signature'     => "$settings[5]",
        'postcount'     => "$settings[6]",
        'position'      => "$settings[7]",
        'icq'           => "$settings[8]",
        'aim'           => "$settings[9]",
        'yim'           => "$settings[10]",
        'gender'        => "$settings[11]",
        'usertext'      => "$settings[12]",
        'userpic'       => "$settings[13]",
        'regdate'       => "$settings[14]",
        'regtime'       => "$regitime",
        'location'      => join( ', ', grep { $_ } @location ),
        'bday'          => "$settings[16]",
        'timeselect'    => "$settings[17]",
        'user_tz'       => 'UTC',
        'hidemail'      => ( $settings[19] ? 1 : 0 ),
        'gtalk'         => "$settings[32]",
        'template'      => "$new_template",
        'language'      => "$language",
        'lastonline'    => "$lastonline",
        'lastpost'      => "$lastpost",
        'lastim'        => "$lastim",
        'im_ignorelist' => "$pmignorelist",
        'notify_me'     => "$pmnotify",
        'im_popup'      => ( $pmpopup ? 1 : 0 ),
        'im_imspop'     => ( $pmspop ? 1 : 0 ),
        'cathide'       => "$settings[30]",
        'postlayout'    => "$settings[31]|0",
        'pageindex'     => '1|1|1',
        'lastips'       => "$c_ip_one|$c_ip_two|$c_ip_three",
    );

    UserAccount( $user, 'update' );

    if ( $user ne $username ) { undef %{ $uid . $user }; }
    return;
}

sub groupconvert {
    require "$convvardir/MemberStats.txt";
    my $i = 0;
    my $z = 1;
    undef %Post;

    $Post{'-1'} = qq~$MemStatNewbie|$MemStarNumNewbie|$MemStarPicNewbie|$MemTypeColNewbie|0|0|0|0|0|0~;

    while ( $MemStat[$i] ) {
        if ( $MemPostNum[$i] eq 'x' ) {
            $NoPost{$z} = qq~$MemStat[$i]|$MemStarNum[$i]|$MemStarPic[$i]|$MemTypeCol[$i]|0|0|0|0|0|0~;
            push @nopostorder, $z;
            $z++;
        }
        else {
            $Post{ $MemPostNum[$i] } =
qq~$MemStat[$i]|$MemStarNum[$i]|$MemStarPic[$i]|$MemTypeCol[$i]|0|0|0|0|0|0~;
        }
        $i++;
    }
    foreach my $key ( keys %Group ) {
        $value = $Group{$key};
        $value =~ s/'/&#39;/gxsm;    #';
        $Group{$key} = $value;
    }
    foreach my $key ( keys %NoPost ) {
        $value = $NoPost{$key};
        $value =~ s/'/&#39;/gxsm;    #';
        $NoPost{$key} = $value;
    }
    foreach my $key ( keys %Post ) {
        $value = $Post{$key};
        $value =~ s/'/&#39;/gxsm;    #';
        $Post{$key} = $value;
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');    # save %Group, %NoPost and %Post
    return;
}

sub memgrpconvert {
    fopen( MEMGRP, "$convvardir/membergroups.txt" )
      || setup_fatal_error( "$maintext_23 $convvardir/membergroups.txt: ", 1 );
    my @memgrp = <MEMGRP>;
    fclose(MEMGRP);
    foreach my $set(@memgrp) {
                $set =~ s/[\r\n]//gsm;
    }
    chomp @memgrp;
    $Group{'Mid Moderator'} = 'Forum Moderator|5|starfmod.png|#008080|0|0|0|0|0|0|0';
    $Group{'Global Moderator'} = 'Global Moderator|5|stargmod.png|#0000FF|0|0|0|0|0|0|0';
    $Group{'Administrator'} = "$memgrp[0]|5|staradmin.png|#FF0000|0|0|0|0|0|0|0";
    $Group{'Moderator'} = "$memgrp[1]|5|starmod.png|#008000|0|0|0|0|0|0|0";
    $Post{'50'} = "$memgrp[3]|2|stargold.png||0|0|0|0|0|0|0";
    $Post{'250'} = "$memgrp[5]|4|stargold.png||0|0|0|0|0|0|0";
    $Post{'500'} = "$memgrp[6]|5|starsilver.png||0|0|0|0|0|0|0";
    $Post{'100'} = "$memgrp[4]|3|starblue.png||0|0|0|0|0|0|0";
    $Post{'-1'} = "$memgrp[2]|1|stargold.png||0|0|0|0|0|0|0";

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');    # save %Group and %Post
    return;
}

sub ConvertMembers2 {
    fopen( MEMDIR, "$convmemberdir/memberlist.txt" )
      || setup_fatal_error( "$maintext_23 $convmemberdir/memberlist.txt: ", 1 );
    my @memlist = <MEMDIR>;
    fclose(MEMDIR);
    chomp @memlist;

    for my $i ( ( $INFO{'mstart2'} || 0 ) .. ( @memlist - 1 ) ) {
        my $user = $memlist[$i];
        chomp $user;

        next if !-e "$convmemberdir/$user.dat";

        my $newuser =
          exists $fixed_users{$user} ? ${ $fixed_users{$user} }[0] : $user;

        my @xtn = qw(msg ims imstore log outbox);
        for my $cnt ( 0 .. ( @xtn - 1 ) ) {
            if ( -e "$convmemberdir/$user.$xtn[$cnt]" ) {
                fopen( FILEUSER, "$convmemberdir/$user.$xtn[$cnt]" )
                  || setup_fatal_error(
                    "$maintext_23 $convmemberdir/$user.$xtn[$cnt]: ", 1 );
                my @divfiles = <FILEUSER>;
                fclose(FILEUSER);

                if ( $cnt == 0 || $cnt == 2 || $cnt == 4 )
                {    # msg || imstore || outbox
                    chomp @divfiles;
                    for my $i ( 0 .. ( @divfiles - 1 ) ) {
                        if ( $cnt == 2 ) {    # imstore
                            my ( $name, $subject, $date, $message, $id, $ip,
                                $read_flag, $folder )
                              = split /\|/xsm, $divfiles[$i];
                            $name =
                              exists $fixed_users{$name}
                              ? ${ $fixed_users{$name} }[0]
                              : $name;
                            $date =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/conv_stringtotime("$1 at $2")/eism;
                            $message =~ s/<br>/<br \/>/igsm;
                            if ( $folder eq 'outbox' ) {
                                $folder = 'out';
                                if    ( !$read_flag )     { $read_flag = 'u'; }
                                elsif ( $read_flag == 1 ) { $read_flag = 'r'; }
                                $divfiles[$i] = "$id|$newuser|$name|||$subject|$date|$message|$id|0|$ip|s|$read_flag|$folder|\n";
                            }
                            elsif ( $folder eq 'inbox' ) {
                                $folder = 'in';
                                if    ( $read_flag == 1 ) { $read_flag = 'u'; }
                                elsif ( $read_flag == 2 ) { $read_flag = 'r'; }
                                $divfiles[$i] = "$id|$name|$newuser|||$subject|$date|$message|$id|0|$ip|s|$read_flag|$folder|\n";
                            }
                        }
                        else {    # msg || outbox
                            my ( $name, $subject, $date, $message, $id, $ip,
                                $read_flag )
                              = split /\|/xsm, $divfiles[$i];
                            $name =
                              exists $fixed_users{$name}
                              ? ${ $fixed_users{$name} }[0]
                              : $name;
                            $date =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/conv_stringtotime("$1 at $2")/eism;
                            $message =~ s/<br>/<br \/>/igsm;
                            if ( $id < 101 || $id eq q{} ) { $id = $date; }
                            if ( $cnt == 0 ) {    # msg
                                if ( $read_flag == 1 ) {
                                    $read_flag = 'u';
                                }                 # u(nread)
                                elsif ( $read_flag == 2 ) {
                                    $read_flag = 'r';
                                }                 # r(eplied)
                                $divfiles[$i] =
"$id|$name|$newuser|||$subject|$date|$message|$id|0|$ip|s|$read_flag||\n";
                            }
                            else {                # outbox
                                if ( !$read_flag ) {
                                    $read_flag = 'u';
                                }                 # u(rgent)
                                elsif ( $read_flag == 1 ) {
                                    $read_flag = 's';
                                }                 # s(tandard)
                                $divfiles[$i] =
"$id|$newuser|$name|||$subject|$date|$message|$id|0|$ip|s|$read_flag||\n";
                            }
                        }
                    }
                }

                fopen( FILEUSER, ">$memberdir/$newuser.$xtn[$cnt]" )
                  || setup_fatal_error(
                    "$maintext_23 $memberdir/$newuser.$xtn[$cnt]: ", 1 );
                print {FILEUSER} @divfiles or croak 'cannot print FILEUSER';
                fclose(FILEUSER);
            }
        }

        if ( time() > $time_to_jump && ( $i + 1 ) < @memlist ) {
            $yySetLocation =
                qq~$set_cgi?action=members2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;mtotal=~
              . @memlist
              . qq~;mstart1=$INFO{'mstart1'};mstart2=~
              . ( $i + 1 );
            redirectexit();
        }
    }
    return;
}

# / Member Conversion ##

# Board + Category Conversion ##

sub GetCats {
    fopen( VDIR, "$convvardir/cat.txt" )
      || setup_fatal_error( "$maintext_23 $convvardir/cat.txt: ", 1 );
    @categoryorder = <VDIR>;
    fclose(VDIR);
    foreach my $set(@categoryorder) {
        $set =~ s/[\r\n]//gsm;
    }
    chomp @categoryorder;

    my @allboards;
    foreach my $fcat (@categoryorder) {
        fopen( VCAT, "$convboardsdir/$fcat.cat" )
          || setup_fatal_error( "$maintext_23 $convboardsdir/$fcat.cat: ", 1 );
        @catdata = <VCAT>;
        fclose(VCAT);
        foreach my $set(@catdata) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp @catdata;

        $catinfo{$fcat} = qq~$catdata[0]|$catdata[1]|1~;

        @catboards = ();
        for my $cnt ( 2 .. ( @catdata - 1 ) ) {
            if ( $catdata[$cnt] ) { push @catboards, $catdata[$cnt]; }
        }
        push @allboards, @catboards;
        $cat{$fcat} = join q{,}, @catboards;
    }
    foreach my $fboard (@allboards) {
        fopen( VBRD, "$convboardsdir/$fboard.dat" )
          || setup_fatal_error( "$maintext_23 $convboardsdir/$fboard.dat: ",
            1 );
        @bdata = <VBRD>;
        fclose(VBRD);
        foreach my $set(@bdata) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp $bdata[0];

        # get board access data
        if ( -e "$convboardsdir/$fboard.mbo" ) {
            require "$convboardsdir/$fboard.mbo";
        }
        $board{$fboard} =
          qq~$bdata[0]|$view_groups{$fboard}|$showprivboards{$fboard}~;
    }

    # add trash if not exists
    if ( !exists $cat{'staff'} ) {
        push @categoryorder, 'staff';
        $cat{'staff'}     = 'announcements,recycle';
        $catinfo{'staff'} = 'Forum Staff|Administrator, Global Moderator|0';
    }
    else {
        my @temp;
        foreach ( split /,/xsm, $cat{'staff'} ) {
            if ( $_ ne 'recycle' && $_ ne 'announcements' ) { push @temp, $_; }
        }
        push @temp, 'recycle';
        push @temp, 'announcements';
        $cat{'staff'} = join q{,}, @temp;
    }
    if ( !exists $cat{'general'} ) {
        push @categoryorder, 'general';
        $cat{'general'}     = 'general';
        $catinfo{'general'} = 'General Category||0|';
    }
    else {
        my @temp;
        foreach ( split /,/xsm, $cat{'general'} ) {
            if ( $_ ne 'general' ) { push @temp, $_; }
        }
        push @temp, 'general';
        $cat{'general'} = join q{,}, @temp;
    }
    if ( !exists $board{'recycle'} ) { $board{'recycle'} = 'Recycle Bin||'; }
    if ( !exists $board{'announcements'} ) {
        $board{'announcements'} = 'Global Announcements||';
    }
    if ( !exists $board{'general'} ) { $board{'general'} = 'General Board||1'; }

    @temparray = ();
    while ( ( $key, $value ) = each %cat ) {

        # Strip membergroups with a ~ from them
        $value =~ s/~//gsm;
        push @temparray, qq~\$cat{$key} = qq\~$value\~;\n~;
    }
    while ( ( $key, $value ) = each %catinfo ) {

        # Strip membergroups with a ~ from them
        $value =~ s/~//gxsm;
        $value =~ s/,/, /gsm;
        push @temparray, qq~\$catinfo{$key} = qq\~$value\~;\n~;
    }
    while ( ( $key, $value ) = each %board ) {

        # Strip membergroups with a ~ from them
        $value =~ s/~//gxsm;
        $value =~ s/,/, /gsm;
        push @temparray, qq~\$board{'$key'} = qq\~$value\~;\n~;
    }
    fopen( FILE, ">$boardsdir/forum.master" )
      || setup_fatal_error( "$maintext_23 $boardsdir/forum.master: ", 1 );
    print {FILE} qq~\$mloaded = 1;\n~,
      qq~\@categoryorder = qw(@categoryorder);\n~, @temparray, "\n1;"
      or croak 'cannot print FILE';
    fclose(FILE);
    return;
}

sub CreateControl {
    require "$boardsdir/forum.master";

    foreach my $foundboard ( keys %board ) {

        # get category
        fopen( CINFO, "$convboardsdir/$foundboard.ctb" );
        @category = <CINFO>;
        fclose(CINFO);
        foreach my $set(@category) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp $category[0];
        $cntcat = $category[0];

        # get boardinfo
        fopen( BINFO, "$convboardsdir/$foundboard.dat" );
        @boardinfo = <BINFO>;
        fclose(BINFO);
        foreach my $set(@boardinfo) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp @boardinfo;

        $boardinfo[2] =~ s/^\||\|$//gxsm;
        $boardinfo[2] =~ s/\|(\S?)/,$1/gxsm;
        $cntmods = join q{,},
          grep { exists $fixed_users{$_} ? ${ $fixed_users{$_} }[0] : $_; }
          split /,/xsm, $boardinfo[2];
        $cntpic         = q{};
        $cntdescription = $boardinfo[1];

        # get board access data
        if ( -e "$convboardsdir/$foundboard.mbo" ) {
            require "$convboardsdir/$foundboard.mbo";
        }

        $cntstartperms = "$start_groups{$foundboard}";
        $cntreplyperms = "$reply_groups{$foundboard}";
        $cntpollperms  = q{};
        $cntstartperms =~ s/,/, /gsm;
        $cntreplyperms =~ s/,/, /gsm;
        $cntpollperms  =~ s/,/, /gsm;
        $cntpic      = "$boardpic{$foundboard}";
        $cntzero     = q{};
        $cntpassword = q{};
        $cnttotals   = q{};
        $cntattperms = q{};
        $spare       = q{};

        if ( $cntcat && $foundboard ) {
            $mypic = q{};
            if ($cntpic ) { $mypic = 'y'; }
            push @boardcontrol,
"$cntcat|$foundboard|$mypic|$cntdescription|$cntmods|$cntmodgroups|$cntstartperms|$cntreplyperms|$cntpollperms|$cntzero|$cntpassword|$cnttotals|$cntattperms|$spare|||\n";
            fopen( BRDPIC, ">>$boardsdir/brdpics.db" );
            print {BRDPIC} qq~$foundboard|default|$cntpic\n~;
            fclose(BRDPIC);
        }
        elsif ( !$cntcat && $foundboard eq 'general' )
        {    # add general board if not exist
            push @boardcontrol,
qq{general|general||This is the board for General Discussions.<br /><i>The board description can now hold multiple lines and can use HTML!</i>|admin|||||0||||1|||\n};
            if ( !-e "$convboardsdir/general.txt" ) {
                fopen( BOARDFILE, ">$convboardsdir/general.txt" )
                  || setup_fatal_error(
                    "$maintext_23 $convboardsdir/general.txt: ", 1 );
                print {BOARDFILE}
qq{1378046604|Welcome to your new YaBB 2.6.11 forum!|Administrator|webmaster\@yoursite.com|1378046604|0|admin|xx|0\n}
                  or croak 'cannot print BOARDFILE';
                fclose(BOARDFILE);
            }
        }
        elsif ( !$cntcat && $foundboard eq 'recycle' )
        {    # add trash if not exists
            push @boardcontrol,
qq{staff|recycle||If the Recycle Bin is turned on, removed topics will be moved to this board. This will allow you to recover them if it is necessary. You should purge messages in this board frequently to keep it clean.|admin|||||1|||1||||\n};
            if ( !-e "$convboardsdir/recycle.txt" ) {
                fopen( BOARDFILE, ">$convboardsdir/recycle.txt" )
                  || setup_fatal_error(
                    "$maintext_23 $convboardsdir/recycle.txt: ", 1 );
                print {BOARDFILE} q{} or croak 'cannot print BOARDFILE';
                fclose(BOARDFILE);
            }
        }
        elsif ( !$cntcat && $foundboard eq 'announcements' ) {
            push @boardcontrol,
qq{staff|announcements||Topics you place in this board will display as a "Global Announcement" on the top of all other boards. Use this for things such as forum rules, top news articles, or important statements.|admin||Administrator|||0||1|||||\n};
            if ( !-e "$convboardsdir/announcements.txt" ) {
                fopen( BOARDFILE, ">$convboardsdir/announcements.txt" )
                  || setup_fatal_error(
                    "$maintext_23 $convboardsdir/announcements.txt: ", 1 );
                print {BOARDFILE} q{} or croak 'cannot print BOARDFILE';
                fclose(BOARDFILE);
            }
        }
    }

    fopen( CONTROL, ">$boardsdir/forum.control" )
      || setup_fatal_error( "$maintext_23 $boardsdir/forum.control: ", 1 );
    @boardcontrol = sort @boardcontrol;
    print {CONTROL} @boardcontrol or croak 'cannot print CONTROL';
    fclose(CONTROL);
    return;
}

sub ConvertBoards {
    require "$boardsdir/forum.master";

    my %stickies;
    if ( open $DATADIR, '<', "$convboardsdir/sticky.stk" ) {
        my @stickies = <$DATADIR>;
        close $DATADIR or croak 'cannot close stickies file';
        chomp @stickies;
        foreach (@stickies) { $stickies{$_} = 1; }
    }

    @boards = sort keys %board;

    for my $i ( ( $INFO{'bstart'} || 0 ) .. ( @boards - 1 ) ) {
        fopen( BOARDFILE, "$convboardsdir/$boards[$i].txt" )
          || setup_fatal_error( "$maintext_23 $convboardsdir/$boards[$i].txt: ",
            1 );
        @boardfile = <BOARDFILE>;
        fclose(BOARDFILE);
        foreach my $set(@boardfile) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp @boardfile;

        @temparray = ();
        for my $j ( ( $INFO{'bfstart'} || 0 ) .. ( @boardfile - 1 ) ) {
            my $line = $boardfile[$j];
            $line =~ s/[\r\n]//gsm;
            chomp $line;

            my (
                $mnum,     $msub,      $mname, $memail, $mdate,
                $mreplies, $musername, $micon, $mstate
            ) = split /\|/xsm, $line;

            next
              if (!-e "$convdatadir/$mnum.txt"
                || -s "$convdatadir/$mnum.txt" < 35 );

            $mname =
              exists $fixed_users{$mname}
              ? ${ $fixed_users{$mname} }[1]
              : $mname;
            $musername =
              exists $fixed_users{$musername}
              ? ${ $fixed_users{$musername} }[0]
              : $musername;
            $mdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
            $mstate =~ s/1/l/xsm;
            if ( exists $stickies{$mnum} ) { $mstate .= 's'; }
            push @temparray,
"$mnum|$msub|$mname|$memail|$mdate|$mreplies|$musername|$micon|$mstate\n";

            if ( time() > $time_to_jump && ( $j + 1 ) < @boardfile ) {
                fopen( BOARDFILE, ">>$boardsdir/$boards[$i].txt" )
                  || setup_fatal_error(
                    "$maintext_23 $boardsdir/$boards[$i].txt: ", 1 );
                foreach my $set(@temparray) {
                    $set =~ s/[\r\n]//gsm;
                }
                print {BOARDFILE} @temparray or croak 'cannot print BOARDFILE';
                fclose(BOARDFILE);
                $yySetLocation =
                  qq~$set_cgi?action=cats2;st=~
                  . int( $INFO{'st'} +
                      time() -
                      ( $time_to_jump - $max_process_time ) )
                  . qq~;starttime=$time_to_jump;bfstart=~
                  . ( $j + 1 )
                  . qq~;bstart=$i;btotal=~
                  . @boards;
                redirectexit();
            }
        }
        fopen( BOARDFILE, ">>$boardsdir/$boards[$i].txt" )
          || setup_fatal_error( "$maintext_23 $boardsdir/$boards[$i].txt: ",
            1 );
        print {BOARDFILE} @temparray or croak 'cannot print BOARDFILE';
        fclose(BOARDFILE);

        if ( time() > $time_to_jump && ( $i + 1 ) < @boards ) {
            $yySetLocation =
                qq~$set_cgi?action=cats2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;mtotal=~
              . @memlist
              . q~;bfstart=0;bstart=~
              . ( $i + 1 );
            redirectexit();
        }
        $INFO{'bfstart'} = 0;
    }
    return;
}

# / Board + Category Conversion ##

# Message Conversion ##

sub ConvertMessages {
    require "$boardsdir/forum.master";

    ${ $uid . $username }{'timeformat'} =
      'SDT, DD MM YYYY HH:mm:ss zzz';    # the .ctb time format
    ${ $uid . $username }{'timeselect'} = 7;
    my $ctbtime = timeformat( $date, 1, 'rfc' );

    my %stickies;

    if ( open $DATADIR, '<', "$convboardsdir/sticky.stk" ) {
        my @stickies = <$DATADIR>;
        close $DATADIR or croak 'cannot close sticky.stk';
        chomp @stickies;
        foreach (@stickies) { $stickies{$_} = 1; }
    }

    my @boards = sort keys %board;

    my $totalbdr = @boards;
    for my $next_board ( ( $INFO{'count'} || 0 ) .. ( $totalbdr - 1 ) ) {
        my $boardname = $boards[$next_board];

        fopen( BRDFILE, "$boardsdir/$boardname.txt" )
          || setup_fatal_error( "$maintext_23 $boardsdir/$boardname.txt: ", 1 );
        my @brdmessageline = <BRDFILE>;
        fclose(BRDFILE);

        my %newreply  = ();
        my $totalmess = @brdmessageline;
        for my $tops ( ( $INFO{'tcount'} || 0 ) .. ( $totalmess - 1 ) ) {
            ( $thread, undef, undef, undef, undef, $replies, undef ) =
              split /\|/xsm, $brdmessageline[$tops], 7;

            fopen( MSGFILE, "$convdatadir/$thread.txt" )
              || setup_fatal_error( "$maintext_23 $convdatadir/$thread.txt: ",
                1 );
            @messagelines = <MSGFILE>;
            fclose(MSGFILE);
            chomp @messagelines;

            $INFO{'total_mess'} += @messagelines;
            $INFO{'total_threads'}++;

            @temparray = ();
            foreach my $msgline (@messagelines) {
                my (
                    $subject,   $name, $email,    $mdate,
                    $musername, $icon, $dummy,    $user_ip,
                    $message,   $ns,   $editdate, $editby,
                    undef,      $attachment
                ) = split /\|/xsm, $msgline;
                $name =
                  exists $fixed_users{$name}
                  ? ${ $fixed_users{$name} }[1]
                  : $name;
                $musername =
                  exists $fixed_users{$musername}
                  ? ${ $fixed_users{$musername} }[0]
                  : $musername;
                $editby =
                  exists $fixed_users{$editby}
                  ? ${ $fixed_users{$editby} }[0]
                  : $editby;
                if ( $message =~ /\[[qgs]/ixsm )
                {    # too many RegExpr take too much time!!!
                    $message =~ s/\[quote(\s+author=(.*?)\s+link=(.*?)\s+date=(.*?)\s*)?\](.*?)\[\/quote\]/QuoteFix($2,$3,$4,$5)/eigsm;
                    $message =~ s/\[(glow|shadow)=.*?\](.*?)\[\/(glow|shadow)\]/\[glb\]$2\[\/glb\]/igsm;
                    $message =~ s/\[size=([+-]?\d)\](.*?)\[\/size\]/ '\[size=' . conv_size($1) . "\]$2\[\/size\]" /igesm;
                }
                $message =~ s/<br>/<br \/>/igsm;
                $mdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2}).*/&conv_stringtotime("$1 at $2")/eism;
                $editdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2}).*/&conv_stringtotime("$1 at $2")/eism;
                push @temparray,
"$subject|$name|$email|$mdate|$musername|$icon|$dummy|$user_ip|$message|$ns|$editdate|$editby|$attachment\n";
                if ( $musername ne 'Guest' ) {
                    ${ $uid . $thread }{$musername}++;
                    ${ $uid . $thread . 'time' }{$musername} = $mdate;
                }
            }
            fopen( MSGFILE, ">$datadir/$thread.txt" )
              || setup_fatal_error( "$maintext_23 $datadir/$thread.txt: ", 1 );
            print {MSGFILE} @temparray
              or croak "cannot print $datadir/$thread.txt";
            fclose(MSGFILE);

            # do the .ctb
            my $views = 1;
            if ( -e "$convdatadir/$thread.data" ) {
                fopen( DATA, "$convdatadir/$thread.data" )
                  || setup_fatal_error(
                    "$maintext_23 $convdatadir/$thread.data: ", 1 );
                $data = <DATA>;
                fclose(DATA);
                chomp $data;
                ( $views, undef ) = split /\|/xsm, $data, 2;
            }

            my $trstate = exists $stickies{$thread} ? 's' : q{};
            $lastposter = $musername eq 'Guest' ? "Guest-$name" : $musername;

            fopen( CTB, ">$datadir/$thread.ctb" )
              || setup_fatal_error( "$maintext_23 $datadir/$thread.ctb: ", 1 );
            print {CTB}
qq~### ThreadID: $thread, LastModified: $ctbtime ###\n\n'board',"$boardname"\n'replies',"$#messagelines"\n'views',"$views"\n'lastposter',"$lastposter"\n'lastpostdate',"$mdate"\n'threadstatus',"$trstate"\n'repliers',""\n~
              or croak "cannot print $datadir/$thread.ctb";
            fclose(CTB);

            if ( $replies != $#messagelines ) {
                $newreply{$tops} = $#messagelines;
            }

            if ( time() > $time_to_jump && ( $tops + 1 ) < $totalmess ) {
                writerecentlog( ( $INFO{'tcount'} || 0 ),
                    $totalmess, \@brdmessageline );

                if (%newreply) {    # fix reply display
                    foreach ( keys %newreply ) {
                        my @temp = split /\|/xsm, $brdmessageline[$_];
                        $temp[5] = $newreply{$_};
                        $brdmessageline[$_] = join q{|}, @temp;
                    }

                    fopen( BOARDFILE, ">$boardsdir/$boardname.txt" )
                      || setup_fatal_error(
                        "$maintext_23 $boardsdir/$boardname.txt: ", 1 );
                    print {BOARDFILE} @brdmessageline
                      or croak "cannot print $boardsdir/$boardname.txt";
                    fclose(BOARDFILE);
                }

                $yySetLocation =
                  qq~$set_cgi?action=messages2;st=~
                  . int( $INFO{'st'} +
                      time() -
                      ( $time_to_jump - $max_process_time ) )
                  . qq~;starttime=$time_to_jump;count=$next_board;tcount=~
                  . ( $tops + 1 )
                  . qq~;total_mess=$INFO{'total_mess'};total_threads=$INFO{'total_threads'};totboard=$totalbdr;totmess=$totalmess~;
                redirectexit();
            }
        }

        writerecentlog( ( $INFO{'tcount'} || 0 ), $totalmess,
            \@brdmessageline );

        if (%newreply) {    # fix reply display
            foreach ( keys %newreply ) {
                my @temp = split /\|/xsm, $brdmessageline[$_];
                $temp[5] = $newreply{$_};
                $brdmessageline[$_] = join q{|}, @temp;
            }

            fopen( BOARDFILE, ">$boardsdir/$boardname.txt" )
              || setup_fatal_error( "$maintext_23 $boardsdir/$boardname.txt: ",
                1 );
            print {BOARDFILE} @brdmessageline
              or croak "cannot print $boardsdir/$boardname.txt";
            fclose(BOARDFILE);
        }

        if ( time() > $time_to_jump && ( $next_board + 1 ) < $totalbdr ) {
            $yySetLocation =
              qq~$set_cgi?action=messages2;st=~
              . int(
                $INFO{'st'} + time() - ( $time_to_jump - $max_process_time ) )
              . qq~;starttime=$time_to_jump;count=~
              . ( $next_board + 1 )
              . qq~;tcount=0;total_mess=$INFO{'total_mess'};total_threads=$INFO{'total_threads'};totboard=$totalbdr;totmess=0~;
            redirectexit();
        }
        $INFO{'tcount'} = 0;
    }
    return;
}

sub QuoteFix {
    my ( $qauthor, $qlink, $qdate, $qmessage ) = @_;
    if ( $qauthor eq q{} || $qlink eq q{} || $qdate eq q{} ) {
        $quote = "\[quote\]$qmessage\[/quote\]";
    }
    else {
        $qdate = conv_stringtotime($qdate);
        ( undef, $threadlink, $start ) = split /;/xsm, $qlink;
        ( undef, $num )   = split /=/xsm, $threadlink;
        ( undef, $start ) = split /=/xsm, $start;
        $quote = "\[quote author=$qauthor link=$num/$start date=$qdate\]$qmessage\[/quote\]";
    }
    return $quote;
}

sub conv_size {
    my $size = shift;
    if    ( $size eq '1' || $size eq '-2' ) { $size = 10; }
    elsif ( $size eq '2' || $size eq '-1' ) { $size = 13; }
    elsif ( $size eq '3' ) { $size = 16; }
    elsif ( $size eq '4' || $size eq '+1' ) { $size = 18; }
    elsif ( $size eq '5' || $size eq '+2' ) { $size = 24; }
    elsif ( $size eq '6' || $size eq '+3' ) { $size = 32; }
    elsif ( $size eq '7' || $size eq '+4' ) { $size = 48; }
    return $size;
}

sub writerecentlog {
    my ( $start, $total, $messageref ) = @_;

    for my $t ( $start .. ( $total - 1 ) ) {
        ( $thread, undef ) = split /\|/xsm, ${$messageref}[$t], 2;
        foreach my $user ( keys %{ $uid . $thread } ) {
            fopen( RLOG, ">>$memberdir/$user.rlog" )
              || setup_fatal_error( "$maintext_23 $memberdir/$user.rlog: ", 1 );
            print {RLOG}
              "$thread\t${$uid.$thread}{$user},${$uid.$thread.'time'}{$user}\n"
              or croak "cannot print $memberdir/$user.rlog";
            fclose(RLOG);
        }
        undef %{ $uid . $thread };
        undef %{ $uid . $thread . 'time' };
    }
    return;
}

# / Message Conversion ##

# Date Conversion ##

sub ConvertTimeToString {
    if ( $INFO{'timeconv'} < 1 ) {
        opendir( DATADIR, $convdatadir )
          || setup_fatal_error( "Directory: $convdatadir: ", 1 );
        my @polls = sort grep { /\.poll$/xsm } readdir DATADIR;
        closedir DATADIR;

        my $totalpolls = @polls;
        for my $i ( ( $INFO{'pollfile'} || 0 ) .. ( $totalpolls - 1 ) ) {
            $file = $polls[$i];
            fopen( POLLFILE, "$convdatadir/$file" )
              || setup_fatal_error( "$maintext_23 $convdatadir/$file: ", 1 );
            @pollsfile = <POLLFILE>;
            fclose(POLLFILE);

            chomp $pollsfile[0];
            my (
                $dummy1, $dummy2, $polluname, $dummy4,
                $dummy5, $pdate,  $dummy6,    $dummy7,
                $dummy8, $epdate, $dummy10,   $dummy11
            ) = split /\|/xsm, shift @pollsfile;
            $polluname =
              exists $fixed_users{$polluname}
              ? ${ $fixed_users{$polluname} }[0]
              : $polluname;
            $pdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
            $epdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2}).*/&conv_stringtotime("$1 at $2")/eism;

            fopen( POLLFILE, ">$datadir/$file" )
              || setup_fatal_error( "$maintext_23 $datadir/$file: ", 1 );
            print {POLLFILE}
"$dummy1|$dummy2|$polluname|$dummy4|$dummy5|$pdate|$dummy6|$dummy7|$dummy8|$epdate|$dummy10|$dummy11\n",
              @pollsfile
              or croak "cannot print $datadir/$file";
            fclose(POLLFILE);

            if ( time() > $time_to_jump && ( $i + 1 ) < $totalpolls ) {
                $yySetLocation =
                  qq~$set_cgi?action=dates2;st=~
                  . int(
                    $INFO{'st'} + time() - $time_to_jump + $max_process_time )
                  . qq~;starttime=$time_to_jump;timeconv=0;totalpolls=$totalpolls;pollfile=~
                  . ( $i + 1 );
                redirectexit();
            }
        }
        $INFO{'totalpolls'} = $totalpolls;
    }

    if ( $INFO{'timeconv'} < 2 ) {
        opendir( DATADIR, $convdatadir )
          || setup_fatal_error( "Directory: $convdatadir: ", 1 );
        my @polled = sort grep { /\.polled$/xsm } readdir DATADIR;
        closedir DATADIR;

        my $totalpolled = @polled;
        for my $i ( ( $INFO{'polledfile'} || 0 ) .. ( $totalpolled - 1 ) ) {
            $file = $polled[$i];
            fopen( POLLEDFILE, "$convdatadir/$file" )
              || setup_fatal_error( "$maintext_23 $convdatadir/$file: ", 1 );
            @polledfile = <POLLEDFILE>;
            fclose(POLLEDFILE);
            chomp @polledfile;

            @temparray = ();
            foreach my $line (@polledfile) {
                my ( $dummy1, $pollername, $dummy3, $pdate ) =
                  split /\|/xsm, $line;
                $pollername =
                  exists $fixed_users{$pollername}
                  ? ${ $fixed_users{$pollername} }[0]
                  : $pollername;
                $pdate =~ s/(\d{1,2}\/\d{1,2}\/\d{2,4}).*?(\d{1,2}\:\d{1,2}\:\d{1,2})/&conv_stringtotime("$1 at $2")/eism;
                push @temparray, "$dummy1|$pollername|$dummy3|$pdate\n";
            }
            fopen( POLLEDFILE, ">$datadir/$file" )
              || setup_fatal_error( "$maintext_23 $datadir/$file: ", 1 );
            print {POLLEDFILE} @temparray
              or croak "cannot print $datadir/$file";
            fclose(POLLEDFILE);

            if ( time() > $time_to_jump && ( $i + 1 ) < $totalpolled ) {
                $yySetLocation =
                  qq~$set_cgi?action=dates2;st=~
                  . int(
                    $INFO{'st'} + time() - $time_to_jump + $max_process_time )
                  . qq~;starttime=$time_to_jump;timeconv=1;totalpolls=$INFO{'totalpolls'};totalpolled=$totalpolled;polledfile=~
                  . ( $i + 1 );
                redirectexit();
            }
        }
    }
    return;
}

# / Date Conversion ##

# Cleanup ##

sub MyReCountTotals {
    @boards = sort keys %board;

    my $totalboards = @boards;
    for my $j ( ( $INFO{'my_re_tot'} || 0 ) .. ( $totalboards - 1 ) ) {
        my $cntboard = $boards[$j];
        next if !$cntboard;

        fopen( BOARD, "$boardsdir/$cntboard.txt" )
          || setup_fatal_error( "$maintext_23 $boardsdir/$cntboard.txt: ", 1 );
        my @threads = <BOARD>;
        fclose(BOARD);

        my $threadcount  = @threads;
        my $messagecount = $threadcount;
        if ($threadcount) {
            for my $i ( 0 .. ( @threads - 1 ) ) {
                $messagecount += ( split /\|/xsm, $threads[$i] )[5];
            }
        }
        BoardTotals( 'load', $cntboard );
        ${ $uid . $cntboard }{'threadcount'}  = $threadcount;
        ${ $uid . $cntboard }{'messagecount'} = $messagecount;

        # &BoardTotals("update", ...) is done in &BoardSetLastInfo
        BoardSetLastInfo( $cntboard, \@threads );

        if ( time() > $time_to_jump && ( $j + 1 ) < $totalboards ) {
            $yySetLocation =
                qq~$set_cgi?action=cleanup2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;clean=1;total_boards=$INFO{'total_boards'};total_re_tot=$totalboards;my_re_tot=~
              . ( $j + 1 );
            redirectexit();
        }
    }
    $INFO{'total_re_tot'} = $totalboards;
    $INFO{'clean'}        = 2;
    return;
}

sub MyMemberIndex {
    if ( $INFO{'memb_index'} > 0 ) {
        ManageMemberlist('load');
        ManageMemberinfo('load');
        $siglength = $INFO{'siglength'};
    }
    else {
        $INFO{'tmp_firstforum'} = $INFO{'firstforum'} =
          conv_stringtotime($forumstart);
        $siglength = 200;
    }

    opendir( MEMBERS, $memberdir )
      || setup_fatal_error( "Directory: $memberdir: ", 1 );
    @members = sort grep { /.\.vars$/xsm } readdir MEMBERS;
    closedir MEMBERS;

    $totalmemb = @members;
    for my $j ( ( $INFO{'memb_index'} || 0 ) .. ( $totalmemb - 1 ) ) {
        $member = $members[$j];
        $member =~ s/\.vars$//gxsm;

        LoadUser($member);

        Recent_Load($member);
        ${ $uid . $member }{'postcount'} = 0;
        foreach ( keys %recent ) {
            ${ $uid . $member }{'postcount'} += ${ $recent{$_} }[0];
        }

        if ( $INFO{'firstforum'} > ${ $uid . $member }{'regtime'} ) {
            $INFO{'firstforum'} = ${ $uid . $member }{'regtime'};
        }

        if ( length( ${ $uid . $member }{'signature'} ) > $siglength ) {
            $siglength = length( ${ $uid . $member }{'signature'} );
        }

        if ( ${ $uid . $member }{'position'} ) {
            foreach my $key ( keys %NoPost ) {
                ( $NoPostname, undef ) = split /\|/xsm, $NoPost{$key}, 2;
                if ( ${ $uid . $member }{'position'} eq $NoPostname ) {
                    ${ $uid . $member }{'position'} = $key;
                    last;
                }
            }
        }
        if ( !${ $uid . $member }{'position'} ) {
            ${ $uid . $member }{'position'} =
              MyMemberPostGroup( ${ $uid . $member }{'postcount'} );
        }

        if ( ${ $uid . $member }{'addgroups'} ) {
            my $newaddigrp = q{};
            foreach
              my $addigrp ( split /, ?/sm, ${ $uid . $member }{'addgroups'} )
            {
                foreach my $key ( keys %NoPost ) {
                    ( $NoPostname, undef ) = split /\|/xsm, $NoPost{$key}, 2;
                    if ( $addigrp eq $NoPostname ) { $addigrp = $key; last; }
                }
                $newaddigrp .= qq~$addigrp,~;
            }
            $newaddigrp =~ s/,$//xsm;
            ${ $uid . $member }{'addgroups'} = $newaddigrp;
        }

        UserAccount( $member, 'update' );

        $memberlist{$member} = sprintf '%010d', ${ $uid . $member }{'regtime'};
        $memberinf{$member} =
qq~${$uid.$member}{'realname'}|${$uid.$member}{'email'}|${$uid.$member}{'position'}|${$uid.$member}{'postcount'}~;

        if ( time() > $time_to_jump && ( $j + 1 ) < $totalmemb ) {
            ManageMemberlist('save');
            ManageMemberinfo('save');
            $yySetLocation =
                qq~$set_cgi?action=cleanup2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;clean=2;total_boards=$INFO{'total_boards'};total_re_tot=$INFO{'total_re_tot'};tmp_firstforum=$INFO{'tmp_firstforum'};firstforum=$INFO{'firstforum'};siglength=$siglength;total_memb=$totalmemb;memb_index=~
              . ( $j + 1 );
            redirectexit();
        }
    }
    ManageMemberlist('save');
    ManageMemberinfo('save');

    $INFO{'total_memb'} = $totalmemb;
    $INFO{'clean'}      = 3;

    fopen( MEMBERLISTREAD, "$memberdir/memberlist.txt" )
      || setup_fatal_error( "$maintext_23 $memberdir/memberlist.txt: ", 1 );
    my @num = <MEMBERLISTREAD>;
    fclose(MEMBERLISTREAD);
    my $membertotal = @num;

    ( $latestmember, undef ) = split /\t/xsm, $num[-1], 2;

    fopen( MEMTTL, ">$memberdir/members.ttl" )
      || setup_fatal_error( "$maintext_23 $memberdir/members.ttl: ", 1 );
    print {MEMTTL} qq~$membertotal|$latestmember~
      or croak "cannot print $memberdir/members.ttl";
    fclose(MEMTTL);

    if ( $INFO{'tmp_firstforum'} > $INFO{'firstforum'} || $siglength > 200 ) {
        SetInstall2();
    }
    return;
}

sub MyMemberPostGroup {
    my ($userpostcnt) = @_;
    $grtitle = q{};
    foreach my $postamount ( reverse sort { $a <=> $b } keys %Post ) {
        if ( $userpostcnt >= $postamount ) {
            ( $grtitle, undef ) = split /\|/xsm, $Post{$postamount}, 2;
            last;
        }
    }
    return $grtitle;
}

sub MyMailNotify {
    require Sources::Notify;
    ManageMemberinfo('load');

    opendir( DIRECTORY, $convdatadir )
      || setup_fatal_error( "Directory: $convdatadir: ", 1 );
    my @files = sort grep { /\.mail$/xsm } readdir DIRECTORY;
    closedir DIRECTORY;

    my $totalfiles = @files;
    for my $j ( ( $INFO{'my_mail_n'} || 0 ) .. ( $totalfiles - 1 ) ) {
        my $filename = ( split /\./xsm, $files[$j], 2 )[0];

        fopen( MAILFILE, "$convdatadir/$filename.mail" )
          || setup_fatal_error( "$maintext_23 $convdatadir/$filename.mail: ",
            1 );
        my @mailaddresses = <MAILFILE>;
        fclose(MAILFILE);
        chomp @mailaddresses;

        foreach my $mailaddress (@mailaddresses) {
            while ( ( $curuser, $value ) = each %memberinf ) {
                if ( $mailaddress eq ( split /\|/xsm, $value, 3 )[1] ) {
                    ManageThreadNotify( 'add', $filename, $curuser, $language,
                        1, 1 );
                    if ( $curuser ne $username ) { undef %{ $uid . $curuser }; }
                    last;
                }
            }
        }

        if ( time() > $time_to_jump && ( $j + 1 ) < $totalfiles ) {
            $yySetLocation =
                qq~$set_cgi?action=cleanup2;st=~
              . int( $INFO{'st'} + time() - $time_to_jump + $max_process_time )
              . qq~;starttime=$time_to_jump;clean=3;total_boards=$INFO{'total_boards'};total_re_tot=$INFO{'total_re_tot'};total_memb=$INFO{'total_memb'};tmp_firstforum=$INFO{'tmp_firstforum'};firstforum=$INFO{'firstforum'};total_mail_n=$totalfiles;my_mail_n=~
              . ( $j + 1 );
            redirectexit();
        }
    }

    $INFO{'total_mail_n'} = $totalfiles;
    $INFO{'clean'}        = 4;
    return;
}

sub FixNopost {
    if ( $NoPost{'1'} ) {
        fopen( FORUMCONTROL, "$boardsdir/forum.control" )
          || setup_fatal_error( "$maintext_23 $boardsdir/forum.control: ", 1 );
        @boardcontrols = <FORUMCONTROL>;
        fclose(FORUMCONTROL);
        foreach my $set(@boardcontrols) {
            $set =~ s/[\r\n]//gsm;
        }
        chomp @boardcontrols;

        my $totalnoposts = keys %NoPost;
        for my $i ( ( $INFO{'fix_nopost'} || 1 ) .. ( $totalnoposts - 1 ) ) {
            ( $grptitle, undef ) = split /\|/xsm, $NoPost{$i}, 2;

            foreach my $key ( keys %catinfo ) {
                ( $catname, $catperms, $catcol ) =
                  split /\|/xsm, $catinfo{$key}, 3;
                $newperm = q{};
                foreach my $theperm ( split /, /sm, $catperms ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newperm .= qq~$theperm, ~;
                }
                $newperm =~ s/, $//sm;
                $catinfo{$key} = qq~$catname|$newperm|$catcol~;
            }
            foreach my $key ( keys %board ) {
                ( $boardname, $boardperms, $boardshow ) =
                  split /\|/xsm, $board{$key}, 3;
                $newperm = q{};
                foreach my $theperm ( split /, /sm, $boardperms ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newperm .= qq~$theperm, ~;
                }
                $newperm =~ s/, $//sm;
                $board{$key} = qq~$boardname|$newperm|$boardshow~;
            }
            for my $j ( 0 .. ( @boardcontrols - 1 ) ) {
                (
                    $cntcat,         $cntboard,        $cntpic,
                    $cntdescription, $cntmods,         $cntmodgroups,
                    $cnttopicperms,  $cntreplyperms,   $cntpollperms,
                    $cntzero,        $cntmembergroups, $cntann,
                    $cntrbin,        $cntattperms,     $cntminageperms,
                    $cntmaxageperms, $cntgenderperms
                ) = split /\|/xsm, $boardcontrols[$j];

                $newmodgroups = q{};
                foreach my $theperm ( split /, /sm, $cntmodgroups ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newmodgroups .= qq~$theperm, ~;
                }
                $newmodgroups =~ s/, $//sm;

                $newtopicperms = q{};
                foreach my $theperm ( split /, /sm, $cnttopicperms ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newtopicperms .= qq~$theperm, ~;
                }
                $newtopicperms =~ s/, $//sm;

                $newreplyperms = q{};
                foreach my $theperm ( split /, /sm, $cntreplyperms ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newreplyperms .= qq~$theperm, ~;
                }
                $newreplyperms =~ s/, $//sm;

                $newpollperms = q{};
                foreach my $theperm ( split /, /sm, $cntpollperms ) {
                    if ( $theperm eq $grptitle ) { $theperm = $i; }
                    $newpollperms .= qq~$theperm, ~;
                }
                $newpollperms =~ s/, $//sm;

                $boardcontrols[$j] =
qq~$cntcat|$cntboard|$cntpic|$cntdescription|$cntmods|$newmodgroups|$newtopicperms|$newreplyperms|$newpollperms|$cntzero|$cntmembergroups|$cntann|$cntrbin|$cntattperms|$cntminageperms|$cntmaxageperms|$cntgenderperms\n~;
            }

            if ( time() > $time_to_jump && ( $i + 1 ) < $totalnoposts ) {
                Write_ForumMaster();

                fopen( FORUMCONTROL, ">$boardsdir/forum.control" )
                  || setup_fatal_error(
                    "$maintext_23 $boardsdir/forum.control: ", 1 );
                print {FORUMCONTROL} @boardcontrols
                  or croak 'cannot print FORUMCONTROL';
                fclose(FORUMCONTROL);

                $yySetLocation =
                  qq~$set_cgi?action=cleanup2;st=~
                  . int(
                    $INFO{'st'} + time() - $time_to_jump + $max_process_time )
                  . qq~;starttime=$time_to_jump;clean=4;total_boards=$INFO{'total_boards'};total_re_tot=$INFO{'total_re_tot'};total_memb=$INFO{'total_memb'};tmp_firstforum=$INFO{'tmp_firstforum'};firstforum=$INFO{'firstforum'};total_mail_n=$INFO{'total_mail_n'};total_nopost=$totalnoposts;fix_nopost=~
                  . ( $i + 1 );
                redirectexit();
            }
        }
        Write_ForumMaster();

        fopen( FORUMCONTROL, ">$boardsdir/forum.control" )
          || setup_fatal_error( "$maintext_23 $boardsdir/forum.control: ", 1 );
        print {FORUMCONTROL} @boardcontrols
          or croak 'cannot print FORUMCONTROL';
        fclose(FORUMCONTROL);
    }
    return;
}

# / Cleanup ##

sub format_timestring {
    my ($time_string) = @_;

    if ( $time_string !~
        m/(\d{1,2})\/(\d{1,2})\/(\d{2,4}).*?(\d{1,2})\:(\d{1,2})\:(\d{1,2})/ism
      )
    {
        $time_string = "$forumstart";
    }

    if ( $time_string =~
        m/(\d{1,2})\/(\d{1,2})\/(\d{2,4}).*?(\d{1,2})\:(\d{1,2})\:(\d{1,2})/ism
      )
    {
        $dr_month  = $1;
        $dr_day    = $2;
        $dr_year   = $3;
        $dr_hour   = $4;
        $dr_minute = $5;
        $dr_secund = $6;
    }

    if ( $dr_month > 12 ) { $dr_month = 12; }
    if ( $dr_month < 1 )  { $dr_month = 1; }
    if ( $dr_day > 31 )   { $dr_day   = 31; }
    if ( $dr_day < 1 )    { $dr_day   = 1; }
    if ( length($dr_year) > 2 ) {
        $dr_year = substr $dr_year, length($dr_year) - 2, 2;
    }
    if ( $dr_year < 90 && $dr_year > 20 ) { $dr_year = 90; }
    if ( $dr_year > 20 && $dr_year < 90 ) { $dr_year = 20; }
    if ( $dr_hour > 23 )   { $dr_hour   = 23; }
    if ( $dr_minute > 59 ) { $dr_minute = 59; }
    if ( $dr_secund > 59 ) { $dr_secund = 59; }

    if ( $dr_month == 4 || $dr_month == 6 || $dr_month == 9 || $dr_month == 11 )
    {
        $max_days = 30;
    }
    elsif ( $dr_month == 2 && $dr_year % 4 == 0 ) {
        $max_days = 29;
    }
    elsif ( $dr_month == 2 && $dr_year % 4 != 0 ) {
        $max_days = 28;
    }
    else {
        $max_days = 31;
    }
    if ( $dr_day > $max_days ) { $dr_day = $max_days; }

    $dr_month  = sprintf '%02d', $dr_month;
    $dr_day    = sprintf '%02d', $dr_day;
    $dr_year   = sprintf '%02d', $dr_year;
    $dr_hour   = sprintf '%02d', $dr_hour;
    $dr_minute = sprintf '%02d', $dr_minute;
    $dr_secund = sprintf '%02d', $dr_secund;

    return
qq~$dr_month/$dr_day/$dr_year $maintxt{'107'} $dr_hour:$dr_minute:$dr_secund~;
}

sub conv_stringtotime {
    my ($splitvar) = @_;
    if ( !$splitvar ) { return 0; }
    if ( $splitvar =~
        m/(\d{1,2})\/(\d{1,2})\/(\d{2,4}).*?(\d{1,2})\:(\d{1,2})\:(\d{1,2})/ism
      )
    {
        $amonth = int($1) || 1;
        $aday   = int($2) || 1;
        $ayear  = int($3) || 0;
        $ahour  = int($4) || 0;
        $amin   = int($5) || 0;
        $asec   = int($6) || 0;
    }

    if    ( $ayear >= 36 && $ayear <= 99 ) { $ayear += 1900; }
    elsif ( $ayear >= 00 && $ayear <= 35 ) { $ayear += 2000; }
    if    ( $ayear < 1904 ) { $ayear = 1904; }
    elsif ( $ayear > 2036 ) { $ayear = 2036; }

    if    ( $amonth < 1 )  { $amonth = 0; }
    elsif ( $amonth > 12 ) { $amonth = 11; }
    else                   { --$amonth; }

    if ( $amonth == 3 || $amonth == 5 || $amonth == 8 || $amonth == 10 ) {
        $max_days = 30;
    }
    elsif ( $amonth == 1 && $ayear % 4 == 0 ) { $max_days = 29; }
    elsif ( $amonth == 1 && $ayear % 4 != 0 ) { $max_days = 28; }
    else                                      { $max_days = 31; }
    if ( $aday > $max_days ) { $aday = $max_days; }

    if    ( $ahour < 1 )  { $ahour = 0; }
    elsif ( $ahour > 23 ) { $ahour = 23; }
    if    ( $amin < 1 )   { $amin  = 0; }
    elsif ( $amin > 59 )  { $amin  = 59; }
    if    ( $asec < 1 )   { $asec  = 0; }
    elsif ( $asec > 59 )  { $asec  = 59; }

    return timegm( $asec, $amin, $ahour, $aday, $amonth, $ayear );
}

#End Conversion#

sub tempstarter {
    return if !-e "$vardir/Settings.pm";

    $YaBBversion = 'YaBB 2.6.11';

    # Make sure the module path is present
    push @INC, './Modules';

    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/sm ) {
        $yyIIS = 1;
        if ( $PROGRAM_NAME =~ m{(.*)(\\|/)}xsm ) {
            $yypath = $1;
        }
        $yypath =~ s/\\/\//gxsm;
        chdir $yypath;
        push @INC, $yypath;
    }

    # Requirements and Errors
    require Variables::Settings;
    if ( -e "$vardir/convSettings.txt" ) { require "$vardir/convSettings.txt"; }
    else                                 { $convertdir = './Convert'; }

    LoadCookie();    # Load the user's cookie (or set to guest)
    LoadUserSettings();
    WhatTemplate();
    WhatLanguage();
    require Sources::Security;
    WriteLog();
    return;
}

sub CreateConvLock {
    fopen( LOCKFILE, ">$vardir/Converter.lock" )
      || setup_fatal_error( "$maintext_23 $vardir/Converter.lock: ", 1 );
    print {LOCKFILE} qq~This is a lockfile for the Converter.\n~
      or croak 'cannot print to LOCKFILE';
    print {LOCKFILE}
      qq~It prevents it being run again after it has been run once.\n~
      or croak 'cannot print to LOCKFILE';
    print {LOCKFILE} q~Delete this file if you want to run the Converter again.~
      or croak 'cannot print to LOCKFILE';
    fclose(LOCKFILE);

    return;
}

sub SetupImgLoc {
    if ( !-e "$htmldir/Templates/Forum/$useimages/$_[0]" ) {
        $thisimgloc = qq~img src="$yyhtml_root/Templates/Forum/default/$_[0]"~;
    }
    else { $thisimgloc = qq~img src="$imagesdir/$_[0]"~; }
    return $thisimgloc;
}

sub tabmenushow {    # used by the converter
    $tabsep =
      q{ &nbsp; };
    $tabfill = q{ &nbsp; };

    $NavLink1 = qq~<span style="padding:4px">$tabfill Members $tabfill</span>~;
    $NavLink2 = qq~$tabsep<span style="padding:4px">$tabfill Boards & Categories $tabfill</span>~;
    $NavLink3 = qq~$tabsep<span style="padding:4px">$tabfill Messages $tabfill</span>~;
    $NavLink4 = qq~$tabsep<span style="padding:4px">$tabfill Date &amp; Time $tabfill</span>~;
    $NavLink5 = qq~$tabsep<span style="padding:4px">$tabfill Clean Up $tabfill</span>~;
    $NavLink6 = qq~$tabsep<span style="padding:4px">$tabfill Login $tabfill</span>$tabsep&nbsp;~;

    $NavLink1a =
qq~<span class="selected"><a href="$set_cgi?action=members;st=$INFO{'st'}" style="color: #f33;" class="selected" onClick="PleaseWait();">$tabfill Members $tabfill</a></span>~;
    $NavLink2a =
qq~$tabsep<span class="selected"><a href="$set_cgi?action=cats;st=$INFO{'st'}" style="color: #f33;" class="selected" onClick="PleaseWait();">$tabfill Boards & Categories $tabfill</a></span>~;
    $NavLink3a =
qq~$tabsep<span class="selected"><a href="$set_cgi?action=messages;st=$INFO{'st'}" style="color: #f33;" class="selected" onClick="PleaseWait();">$tabfill Messages $tabfill</a></span>~;
    $NavLink4a =
qq~$tabsep<span class="selected"><a href="$set_cgi?action=dates;st=$INFO{'st'}" style="color: #f33;" class="selected" onClick="PleaseWait();">$tabfill Date &amp; Time $tabfill</a></span>~;
    $NavLink5a =
qq~$tabsep<span class="selected"><a href="$set_cgi?action=cleanup;st=$INFO{'st'}" style="color: #f33;" class="selected" onClick="PleaseWait();">$tabfill Clean Up $tabfill</a></span>~;
    $NavLink6a =
qq~$tabsep<span class="selected"><a href="$boardurl/YaBB.$yyext?action=login" style="color: #f33;" class="selected">$tabfill Login $tabfill</a></span>$tabsep&nbsp;~;

    $ConvDone = q~
            <div class="divvary_m">&nbsp;</div>
            <div class="divvary2">100 %</div><br />
            ~;

    $ConvNotDone = q~
            <div class="divouter">&nbsp;</div>
            <div class="divvary3">0 %</div><br />
            ~;
    return;
}

sub FoundConvLock {
    tempstarter();
    tabmenushow();

    $yytabmenu = $NavLink1 . $NavLink2 . $NavLink3 . $NavLink4 . $NavLink5 . $NavLink6;

    $formsession = cloak("$mbname$username");

    $yymain = qq~
    <div class="bordercolor borderbox">
    <table class="cs_thin pad_4px">
        <tr>
            <td class="ttabtitle" colspan="2">YaBB 2.6.11 Converter</td>
        </tr><tr>
            <td class="windowbg center">
                <img src="$imagesdir/info.png" alt="" />
            </td>
            <td class="windowbg2"  style="font-size: 11px;">
                Converter has already been run, attempting to run them again will cause damage to your files.<br />
                <br />
                To run Converter again, remove the file "$vardir/Converter.lock," then re-visit this page.
            </td>
        </tr><tr>
            <td class="catbg center" colspan="2">
                <form action="$boardurl/YaBB.$yyext" method="post" style="display: inline;">
                    <input type="submit" value="Go to your Forum" />
                    <input type="hidden" name="formsession" value="$formsession" />
                </form>
            </td>
        </tr>
    </table>
    </div>
      ~;

    $yyim    = 'YaBB 2.6.11 Converter has already been run.';
    $yytitle = 'YaBB 2.6.11 Converter';
    SetupTemplate();
    return;
}

sub setup_fatal_error {
    my ( $e, $v ) = @_;
    $e .= "\n";
    if ($v) { $e .= $! . "\n"; }

    $yymenu = q~Boards &amp; Categories | ~;
    $yymenu .= q~Members | ~;
    $yymenu .= q~Messages | ~;
    $yymenu .= q~Date &amp; Time | ~;
    $yymenu .= q~Clean Up | ~;
    $yymenu .= q~Login~;

    $yymain .= qq~
    <table class="bordercolor cs_thin pad_4px" style="width:80%">
        <tr>
            <td class="titlebg text1"><b>An Error Has Occurred!</b></td>
        </tr><tr>
            <td class="windowbg text1"><br />$e<br /><br /></td>
        </tr>
    </table>
    <p class="center"><a href="javascript:history.go(-1)">Back</a></p>
      ~;
    $yyim    = 'YaBB 2.6.11 Convertor Error.';
    $yytitle = 'YaBB 2.6.11 Convertor Error.';

    if ( !-e "$vardir/Settings.pm" ) { SimpleOutput(); }

    tempstarter();
    SetupTemplate();
    return;
}

sub SimpleOutput {
    $gzcomp = 0;
    print_output_header();

    print qq~
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>YaBB 2.6.11 Setup</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
</head>
<body>

<!-- Main Content -->
<div style="height: 40px;">&nbsp;</div>
<div style="text-align:center">$yymain</div>
</body>
</html>
      ~ or croak 'cannot print output screen';
    exit;
}

sub SetupTemplate {
    $gzcomp = fileno $GZIP ? 1 : 0;
    print_output_header();

    $yyposition = $yytitle;
    $yytitle    = "$mbname - $yytitle";

    $yyimages        = $imagesdir;
    $yydefaultimages = $defaultimagesdir;
    $yystyle =
qq~<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/$usestyle.css" type="text/css" />\n<link rel="stylesheet" href="$yyhtml_root/Templates/Forum/setup.css" type="text/css" />\n ~;
    $yystyle =~ s/$usestyle\///gxsm;

    $yytemplate = "$templatesdir/$usehead/$usehead.html";
    fopen( TEMPLATE, "$yytemplate" )
      || setup_fatal_error( "$maintext_23 $yytemplate: ", 1 );
    @yytemplate = <TEMPLATE>;
    fclose(TEMPLATE);

    my $output = q{};
    $yyboardname = $mbname;
    $yytime = timeformat( $date, 1 );
    $yyuname =
      $iamguest ? q{} : qq~$maintxt{'247'} ${$uid.$username}{'realname'}, ~;

    if ($enable_news) {
        fopen( NEWS, "$vardir/news.txt" );
        @newsmessages = <NEWS>;
        fclose(NEWS);
    }
    for my $i ( 0 .. ( @yytemplate - 1 ) ) {
        $curline = $yytemplate[$i];
        if (
            !$yycopyin
            && (   $curline =~ m{<yabb\ copyright>}xsm
                || $curline =~ m/{yabb\ copyright}/xsm )
          )
        {
            $yycopyin = 1;
        }
        if ( $curline =~ m{<yabb\ newstitle>}xsm && $enable_news ) {
            $yynewstitle = qq~<b>$maintxt{'102'}:</b> ~;
        }
        if ( $curline =~ m{<yabb\ news>}xsm && $enable_news ) {
            srand;
            if ( $shownewsfader == 1 ) {

                $fadedelay = ( $maxsteps * $stepdelay );
                $yynews .= qq~
                    <script type="text/javascript">
                        var maxsteps = "$maxsteps";
                        var stepdelay = "$stepdelay";
                        var fadelinks = $fadelinks;
                        var delay = "$fadedelay";
                        var bcolor = "$color{'faderbg'}";
                        var tcolor = "$color{'fadertext'}";
                        var fcontent = new Array();
                        var begintag = "";
                    ~;
                fopen( NEWS, "$vardir/news.txt" );
                @newsmessages = <NEWS>;
                fclose(NEWS);
                for my $j ( 0 .. ( @newsmessages - 1 ) ) {
                    $newsmessages[$j] =~ s/\n|\r//gxsm;
                    if ( $newsmessages[$j] eq q{} ) { next; }
                    if ( $i != 0 ) { $yymain .= qq~\n~; }
                    $message = $newsmessages[$j];
                    if ($enable_ubbc) {
                        enable_yabbc();
                        DoUBBC();
                    }
                    $message =~ s/"/\\"/gxsm;
                    $yynews .= qq~
                                    fcontent[$j] = "$message";\n
                              ~;
                }
                $yynews .= q~
                            var closetag = '';
                        </script>
                        ~;
            }
            else {
                $message = $newsmessages[ int rand @newsmessages ];
                if ($enable_ubbc) {
                    enable_yabbc();
                    DoUBBC();
                }
                $message =~ s/\'/&#39;/xsm;
                $yynews = qq~
            <script type="text/javascript">
                if (ie4 || DOM2) var news = '$message';
                var div = document.getElementById("newsdiv");
                div.innerHTML = news;
            </script>~;
            }
        }
        $yyurl = $scripturl;
        $curline =~ s/{yabb\s+(\w+)}/${"yy$1"}/gxsm;
        $curline =~ s/<yabb\s+(\w+)>/${"yy$1"}/gxsm;
        $curline =~ s/img src\=\"$imagesdir\/(.+?)\"/SetupImgLoc($1)/eisgm;
        $output .= $curline;
    }
    if ( $yycopyin == 0 ) {
        $output =
q~<h1 style="text-align:center"><b>Sorry, the copyright tag &#123;yabb copyright&#125; must be in the template.<br />Please notify this forum&#39;s administrator that this site is using an ILLEGAL copy of YaBB!</b></h1>~;
    }
    if ( fileno $GZIP ) {
        $OUTPUT_AUTOFLUSH = 1;
        print {$GZIP} $output or croak 'cannot print compressed page';
        close $GZIP or croak 'cannot close GZIP';
    }
    else {
        print $output or croak 'cannot print page';
    }
    exit;
}

sub nicely_aligned_file {
    my ( $setfile ) = @_;
    $setfile =~ s/=\s+;/= 0;/gsm;
    $filler = q{ } x 50;

    # Make files look nicely aligned. The comment starts after 50 Col

    $setfile =~
s/(.+;)[ \t]+(#.+$)/ $1 . substr($filler,(length $1 < 50 ? length $1 : 49)) . $2 /gem;
    $setfile =~ s/\t+(#.+$)/$filler$1/gsm;


    *cut_comment = sub {    # line break of too long comments
        my @x = @_;
        my ( $comment, $length ) =
          ( q{}, 120 );    # 120 Col is the max width of page
        my $var_length = length $x[0];
        while ( $length < $var_length ) { $length += 120; }
        foreach ( split / +/sm, $x[1] ) {
            if ( ( $var_length + length($comment) + length $_ ) > $length ) {
                $comment =~ s/ $//sm;
                $comment .= "\n$filler#  $_ ";
                $length += 120;
            }
            else { $comment .= "$_ "; }
        }
        $comment =~ s/ $//sm;
        return $comment;
    };
    $setfile =~ s/(.+)(#.+$)/ $1 . cut_comment($1,$2) /gem;
    return $setfile;
}

sub SetInstall2 {
    $ret = 0;
    my $oldname = q{};
    if ( -e "$vardir/convSettings.txt" ) { require "$vardir/convSettings.txt"; }
    if ( -e "$convvardir/Settings.pl" ) {
        require "$convvardir/Settings.pl";
        $oldname = $mbname;
        $oldemail = $webmaster_email;
        $oldlang = $language;
        $oldtime = $timeselected;
        $oldoffset = $timeoffset
    }
    if ( $oldname ) {
        $mbname = $oldname;
    }
    ( undef,$rancook ) = split /\-/xsm, $cookietsort;
    $cookieusername = qq~Y2User-$rancook~;
    $cookiepassword = qq~Y2Pass-$rancook~;
    $forumstart = timetostring($INFO{'firstforum'});

    $settings_file_version = 'YaBB 2.6.11';
    if ($enable_notifications eq q{}) { $enable_notifications = $enable_notification ? 3 : 0; }
    $lang                  = $oldlang || 'English';
    $webmaster_email       = $oldemail || 'webmaster@mysite.com';
    $timeselected          = $oldtime || 0;
    $timeoffset            = $oldoffset || 0;
    $cookieviewtime        = 525600;
    $MaxIMMessLen          = 2000;
    $AdMaxIMMessLen        = 3000;
    $MaxCalMessLen         = 200;
    $AdMaxCalMessLen       = 300;
    $Show_EventCal         = 0;
    $Event_TodayColor      = '#ff0000';
    $fix_avatar_img_size   = 0;
    $max_avatar_width     = 65;
    $max_avatar_height     = 65;
    $fix_avatarml_img_size = 0;
    $max_avatarml_width    = 65;
    $max_avatarml_height   = 65;
    $fix_brd_img_size      = 0;
    $max_brd_img_width     = 50;
    $max_brd_img_height    = 50;
    $enabletz              = 0;
    $default_tz            = 'UTC';
    $ip_banlist           = q{};
    $email_banlist        = q{};
    $user_banlist         = q{};
    $showsearchbox        = 1;
    $fmodview             = $gmodview;
    $mdfmod               = $mdglobal;
    $show_online_ip_admin = 1;
    $show_online_ip_gmod  = 1;
    $show_online_ip_fmod  = 1;
    $ipLookup             = 1;
    $bm_subcut            = 50;
    $screenlogin          = 1;
    if ( -e '/bin/gzip' && open $GZIP, '|gzip -f' ) {
        $gzcomp = 1;
    }
    else {
        eval { require Compress::Zlib; Compress::Zlib::memGzip('test'); };
        $gzcomp = $@ ? 0 : 2;
    }
    $gzforce        = 0;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    if ( $action eq 'setinstall2' ) {
        LoadUser('admin');
        ${ $uid . 'admin' }{'email'}      = $webmaster_email;
        ${ $uid . 'admin' }{'timeoffset'} = $timeoffset;

        # must set before &timetostring($date)
        ${ $uid . 'admin' }{'regdate'}    = timetostring($date);
        ${ $uid . 'admin' }{'regtime'}    = $date;
        ${ $uid . 'admin' }{'timeselect'} = $timeselected;
        ${ $uid . 'admin' }{'language'}   = $lang;
        UserAccount( 'admin', 'update' );
        ManageMemberinfo( 'update', 'admin', 'Administrator', $webmaster_email,'Forum Administrator' );
        $yySetLocation = qq~$set_cgi?action=setup3~;
        redirectexit();
    }
    $ret = 1;
    return;
}

1;