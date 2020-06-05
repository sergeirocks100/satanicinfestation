###############################################################################
# EventCalBirthdays.pm                                                        #
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

$eventcalbirthdayspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('EventCal');
get_template('Bdaylist');

sub birthdaylist {
    if ( !$Show_BirthdaysList || ( $iamguest && $Show_BirthdaysList != 2 ) ) {
        fatal_error('not_allowed');
    }
    $heute = $date;
    my $toffs = 0;
    if ($enabletz) {
        $toffs = toffs($date);
    }

    ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst ) =
      gmtime( $heute + $toffs );
    $year += 1900;
    $mon       = $mon + 1;
    $actualmon = $mon;
    $actualday = $mday;
    if ( $actualmon < 10 ) { $actualmon = "0$actualmon"; }
    if ( $actualday < 10 ) { $actualday = "0$actualday"; }

    timeformat($date);    # get only correct $mytimeselected

    # GoTo begin

    my $boxdays =
qq~ <label for="selday"><span class="small">$var_cal{'calday'}</span></label>
    <select class="input" name="selday" id="selday">
    <option value="0">---</option>\n~;
    for my $i ( 1 .. 31 ) {
        my $sel = q{};
        if ( $mday == $i && !$sel_day ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_day == $i ) {
            $sel = ' selected="selected"';
        }
        $boxdays .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
    }
    $boxdays .= '   </select>';

    my $boxmonths =
qq~ <label for="selmon"><span class="small">$var_cal{'calmonth'}</span></label>
    <select class="input" name="selmon" id="selmon">\n~;
    for my $i ( 1 .. 12 ) {
        my $sel = q{};
        if ( $mon == $i && !$sel_mon ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_mon == $i ) {
            $sel = ' selected="selected"';
        }
        $boxmonths .=
            q~      <option value="~
          . sprintf( '%02d', $i )
          . qq~"$sel>$i</option>\n~;
    }
    $boxmonths .= ' </select>';

    my $gyears3 = $year - 3;
    my $gyears2 = $year - 2;
    my $gyears1 = $year - 1;
    my $boxyears .=
qq~ <label for="selyear"><span class="small">&nbsp;$var_cal{'calyear'}</span></label>
    <select class="input" name="selyear" id="selyear">
        <option value="$gyears3">$gyears3</option>
        <option value="$gyears2">$gyears2</option>
        <option value="$gyears1">$gyears1</option>\n~;
    for my $i ( $year .. ( $year + 3 ) ) {
        my $sel = q{};
        if ( $year == $i && !$sel_year ) {
            $sel = ' selected="selected"';
        }
        elsif ( $sel_year == $i ) {
            $sel = ' selected="selected"';
        }
        $boxyears .= qq~        <option value="$i"$sel>$i</option>\n~;
    }
    $boxyears .= '  </select>';

    my $calgotobox = qq~
    <form action="$scripturl?action=eventcal;calshow=1;calgotobox=1" method="post">
    <span class="small"><b>$var_cal{'calsubmit'}</b></span>~;

    if ( $mytimeselected == 6 || $mytimeselected == 3 || $mytimeselected == 2 )
    {
        $calgotobox .= $boxdays . $boxmonths;
    }
    else {
        $calgotobox .= $boxmonths . $boxdays;
    }
    $calgotobox .= qq~$boxyears
    &nbsp; <input type="submit" name="Go" value="$var_cal{'calgo'}" />
    </form>\n~;

    # GoTo end

    # Begin Birthdaylist

    my $sortiert = $INFO{'sort'} || $FORM{'sort'};
    my $letter   = lc $INFO{'letter'} || lc $FORM{'letter'};
    $vmonth = $INFO{'vmonth'} || $FORM{'vmonth'};
    # Begin Letter

    if ( !$sortiert ) { $sortiert = 'sortdate'; }
    my @abcde = ( 'a' .. 'z' );
    my $letter_s = qq~
<form method="post" action="$scripturl?action=birthdaylist">
    <select size="1" name="letter" onchange="submit()" class="small" style="vertical-align: middle;">
        <option value="">&nbsp;</option>
        <option value="other">$var_cal{'other'}</option>~;
    for my $i ( 0 .. ( @abcde - 1 ) ) {
        $letter_s .= qq~        <option value="$abcde[$i]"$sel>$abcde[$i]</option>\n~;
    }
    $letter_s .=
qq~    </select>
    <input type="hidden" name="vmonth" value="$vmonth" />
    <input type="hidden" name="sort" value="sortuser" />
    <input type="submit" style="display:none" />
</form>~;

    ${"class_$sortiert"}     = ' class="selected-bg center"';
    ${"styleletter_$letter"} = ' class="catbg center"';

    if ( !$class_sortuser ) { $class_sortuser = ' class="catbg center"'; }
    if ( !$class_sortage )  { $class_sortage  = ' class="catbg center"'; }
    if ( !$class_sortstarsign ) {
        $class_sortstarsign = ' class="catbg center"';
    }
    if ( !$class_sortdate ) { $class_sortdate = ' class="catbg center"'; }

    if ($Show_BdStarsign) {
        $cal_colspan       = '4';
        $cal_col           = $cal_col_ss;
        $cal_col_star_sort = $cal_col_ss_sort;
        $cal_col_star      = $cal_col_ss_top;
    }
    else {
        $cal_colspan       = '3';
        $cal_col           = $cal_col_no_ss;
        $cal_col_star_sort = q{};
        $cal_col_star      = q{};
    }

    my @mont =
      qw (null January February March April May June July August September October November December );

    my @countmont = (
        'null',           "$countJanuary",
        "$countFebruary", "$countMarch",
        "$countApril",    "$countMay",
        "$countJune",     "$countJuly",
        "$countAugust",   "$countSeptember",
        "$countOctober",  "$countNovember",
        "$countDecember",
    );

    my @viewmont = (
        'null',           "$view_January",
        "$view_February", "$view_March",
        "$view_April",    "$view_May",
        "$view_June",     "$view_July",
        "$view_August",   "$view_September",
        "$view_October",  "$view_November",
        "$view_December",
    );

    my @calmont =
      qw( null calmon_01 calmon_02 calmon_03 calmon_04 calmon_05 calmon_06 calmon_07 calmon_08 calmon_09 calmon_10 calmon_11 calmon_12 );

    ManageMemberinfo('load');
    fopen( EVENTBIRTH, "$vardir/eventcalbday.db" );
    my @birthmembers = <EVENTBIRTH>;
    fclose(EVENTBIRTH);

    my @birthmembers1 = ();
    my @birthmembers2 = ();

    @no_birthday_found    = ();
    $no_birthday_found[0] = q{};
    @no_bd                = ();
    $no_bd[0]             = 0;
    foreach my $user_name (@birthmembers) {
        chomp $user_name;
        ( $user_bdyear, $user_bdmon, $user_bdday, $user_bdname, $user_bdhide )
          = split /\|/xsm, $user_name;

        $memrealname = ( split /\|/xsm, $memberinf{$user_bdname}, 2 )[0];

        if (
            ( $user_bdmon < $actualmon )
            || (   ( $user_bdmon == $actualmon )
                && ( $user_bdday <= $actualday ) )
          )
        {
            $age = $year - $user_bdyear;
        }
        else { $age = $year - $user_bdyear; $age-- }
        $sternzeichen = q{};
        if ($Show_BdStarsign) {
            $sternzeichen = starsign( $user_bdday, $user_bdmon );
        }
        if ( $age && $user_bdyear > 1904 && $user_bdmon && $user_bdday ) {
            $string =
"$user_bdyear|$user_bdmon|$user_bdday|$user_bdname|$age|$sternzeichen|$memrealname|$user_bdhide\n";
            push @birthmembers1, $string;
            $calsplit ||= 0;
            if ( $calsplit > 0 && $vmonth eq $mont[$user_bdmon] ) {
                $string =
"$user_bdyear|$user_bdmon|$user_bdday|$user_bdname|$age|$sternzeichen|$memrealname|$user_bdhide\n";
                push @birthmembers2, $string;
            }
        }
    }
    undef %memberinf;

    $viewbirthdays = q{};
    if ( !@birthmembers1 ) {
        $viewbirthdays = $mybdlist_notbmember;
    }
    else {
        foreach my $user_name (@birthmembers1) {
            chomp $user_name;
            (
                $user_bdyear, $user_bdmon, $user_bdday, $user_bdname, $age,
                $sternzeichen, $user_bdrealname, $user_bdhide
            ) = split /\|/xsm, $user_name;

            # what birthday should we show begin

            if ( $user_bdmon == $actualmon && $user_bdday == $actualday ) {
                if ($Show_BdColorLinks) {
                    LoadUser($user_bdname);
                    $user_linkprofile = $link{$user_bdname};
                }
                else {
                    $user_linkname = $user_bdrealname;
                    LoadUser($user_bdname);
                    if ( $iamguest ) {
                        $user_linkprofile = qq~$format_unbold{$user_bdname}~;
                    }
                    else {
                        $user_linkprofile =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user_bdname}" rel="nofollow">$format_unbold{$user_bdname}</a>~;
                    }
                }
                if ( $showage && $user_bdhide ) {
                    $myage = $var_cal{'hidden'};
                }
                else {
                    $myage = $age;
                }

                $bd_today .=
                  qq~$user_linkprofile <span class="small">($myage)</span>, ~;
            }

            $showviewbd = 1;
            for my $i ( 1 .. 12 ) {
                if ( $user_bdmon == $i || $user_bdmon eq "$i" ) {
                    $countmont[$i]++;
                    $no_bd[$i] = 1;
                }
            }
        }
    }

    for my $i ( 1 .. 12 ) {
        if ( $no_bd[$i] == 0 ) {
            $no_birthday_found[$i] .= qq~&#8226; $var_cal{"$calmont[$i]"} ~;
            $no_bd_found = 1;
        }
        else {
            $no_birthday_found[$i] .= q{};
        }
    }

    # handle with the months end

    $cal_info_header = $mybdlist_calinfoheader;
    $cal_info_header =~ s/{yabb cal_colspan}/$cal_colspan/gsm;
    $cal_info_header =~ s/{yabb cal_col}/$cal_col/gsm;
    $cal_info_header =~ s/{yabb cal_col_star_sort}/$cal_col_star_sort/gsm;
    $cal_info_header =~ s/{yabb class_sortuser}/$class_sortuser/sm;
    $cal_info_header =~ s/{yabb class_sortage}/$class_sortage/sm;
    $cal_info_header =~ s/{yabb class_sortstarsign}/$class_sortstarsign/sm;
    $cal_info_header =~ s/{yabb class_sortdate}/$class_sortdate/sm;

    if ( $vmonth ) {
        $myvmnthin = qq~;vmonth=$vmonth~;
        $cal_info_header =~ s/{yabb vmonth}/$myvmnthin/gsm;
    }

    if ($bd_today) {
        $bd_today =~ s/, $//sm;
        $my_bdtoday = qq~
        <br /><br /><span class="u">$var_cal{'calbirthdaytoday'}:</span><br /><br />
$bd_today
<br /><br />
~;
    }

    if ( $calsplit > 0 && @birthmembers1 >= $calsplit ) {
        for my $i ( 1 .. 12 ) {
            if ( $countmont[$i] ) {
                $bdmonthlinks .=
qq~| <a href="$scripturl?action=birthdaylist;vmonth=$mont[$i]">$var_cal{$calmont[$i]}</a> ~;
            }
            else {
                $bdmonthlinks .= qq~| <span class="off-color">$var_cal{$calmont[$i]}</a> ~;
            }
        }
        $bdmonths = $mybd_months;
        $bdmonths =~ s/{yabb bdmonthlink}/$bdmonthlinks/gsm;
    }

    for my $i ( a .. z ) {
        $my_alpha_a .=
            $mybdlist_alpha_a
          . $i
          . q~" style="text-decoration:none;">~
          . uc($i)
          . $mybdlist_alpha_b;
        $my_alpha_a =~ s/{yabb sortiert}/$sortiert/sm;
    }

    for my $j ( 1 .. 12 ) {
        if ( $calsplit > 0 &&  @birthmembers1 >= $calsplit && $vmonth eq $mont[$j] )
        {
            $datanum = @birthmembers2;
            @birthmembers2 = sort { &{$sortiert}( $a, $b ); } @birthmembers2;
            my $b_sort = q{};
            if ( @birthmembers2 > 0 ) {
                if ( $sortiert ) {
                    $b_sort = qq~;sort=$sortiert~;
                }
                my $newstart = $INFO{'newstart'} || 0;
                $dnprpage       = $calsplit;
                $postdisplaynum = 8;
                $max            = $datanum;
                $tmpa           = 1;
                if ( $newstart >= ( ( $postdisplaynum - 1 ) * $dnprpage ) ) {
                    $startpage =
                      $newstart - ( ( $postdisplaynum - 1 ) * $dnprpage );
                    $tmpa = int( $startpage / $dnprpage ) + 1;
                }
                if ( $max >= $newstart + ( $postdisplaynum * $dnprpage ) ) {
                    $endpage = $newstart + ( $postdisplaynum * $dnprpage );
                }
                else { $endpage = $max }
                if ( $startpage > 0 ) {
                    $pageindex =
qq~<a href="$scripturl?action=$action;newstart=0;vmonth=$vmonth$b_sort" class="norm">1</a>&nbsp;...&nbsp;~;
                    $pgstart = 0;
                }
                if ( $startpage == $dnprpage ) {
                    $pageindex =
qq~<a href="$scripturl?action=$action;newstart=0;vmonth=$vmonth$b_sort" class="norm">1</a>&nbsp;~;
                    $pgstart = 0;
                }
                for my $counter ( $startpage .. ( $endpage - 1 ) ) {
                    if ( $counter % $dnprpage == 0 ) {
                        $pageindex .=
                          $newstart == $counter
                          ? qq~<b>$tmpa</b>&nbsp;~
                          : qq~<a href="$scripturl?action=$action;newstart=$counter;vmonth=$vmonth$b_sort" class="norm">$tmpa</a>&nbsp;~;
                        $pgstart = $counter;
                        $tmpa++;
                    }
                }
                $lastpn  = int( $datanum / $dnprpage ) + 1;
                $lastptn = ( $lastpn - 1 ) * $dnprpage;
                if ( $endpage < $max - ($dnprpage) ) {
                    $pageindexadd = q~...&nbsp;~;
                }
                if ( $endpage != $max ) {
                    $pageindexadd .=
qq~<a href="$scripturl?action=$action;newstart=$lastptn;vmonth=$vmonth$b_sort">$lastpn</a>~;
                    $pgstart = $lastptn;
                }
                $pageindex .= $pageindexadd;

                $pageindex =
qq~ <span class="small">$var_cal{'139'}: $pageindex</span>~;
                $numbegin = ( $newstart + 1 );
                $numend   = ( $newstart + $dnprpage );
                if ( $numend > $datanum ) { $numend  = $datanum; }
                if ( $datanum == 0 )      { $numshow = q{}; }
                else { $numshow = qq~($numbegin - $numend)~; }
                @birthmembers2 = splice @birthmembers2, $newstart, $dnprpage;
            }
            $yyvmon = $mybdlist_viewmont2;
            $yyvmon =~ s/{yabb cal_colspan}/$cal_colspan/gsm;
            $yyvmon =~ s/{yabb cal_col}/$cal_col/gsm;
            $yyvmon =~ s/{yabb cal_col_star_sort}/$cal_col_star_sort/gsm;
            $yyvmon =~ s/{yabb calmont}/$var_cal{$calmont[$j]}/sm;
            $yyvmon =~ s/{yabb countmont}/$countmont[$j]/sm;
            $yyvmon =~ s/{yabb cal_info_header}/$cal_info_header/sm;
            $yyvmon =~ s/{yabb pagecall}/\;newstart=$pgstart/gsm;
            $yyvmon =~ s/{yabb page}/$pageindex/gsm;
            $yyvmon =~ s/{yabb input_letters}/$letter_s/sm;

            for my $user_name (@birthmembers2) {
                chomp $user_name;
                (
                    $user_bdyear, $user_bdmon, $user_bdday, $user_bdname, $age,
                    $sternzeichen, $user_bdrealname, $user_bdhide
                ) = split /\|/xsm, $user_name;
                $showviewbd = 0;
                if ( $letter ) {
                    $searchbdname = $user_bdrealname;
                    $searchbdname = isempty( $searchbdname, $user_bdname );
                    if ( $searchbdname =~ /^$letter/i ) { $showviewbd = 1; }
                }
                else {
                    $showviewbd = 1;
                }
                if ($showviewbd) {
                    $cdate = $var_cal{'hidden'};
                    if ( $Show_BirthdayDate == 2
                        || ( $Show_BirthdayDate == 1 && !$iamguest ) )
                    {
                        $mybtime =
                          stringtotime(
                            qq~$user_bdmon/$user_bdday/$user_bdyear~);
                        $mybtimein = timeformatcal($mybtime);
                        $cdate     = dtonly($mybtimein);
                        if ( $showage && $user_bdhide ) {
                            $cdate = bdayno_year($mybtimein);
                        }
                    }
                    if ($Show_BdColorLinks) {
                        LoadUser($user_bdname);
                        $user_linkprofile = $link{$user_bdname};
                    }
                    else {
                        $user_linkname = $user_bdrealname;
                        LoadUser($user_bdname);
                        if ( $iamguest ) {
                            $user_linkprofile = qq~$format_unbold{$user_bdname}~;
                        }
                        else {
                            $user_linkprofile =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user_bdname}" rel="nofollow">$format_unbold{$user_bdname}</a>~;
                        }
                    }
                    if ( $showage && $user_bdhide ) {
                        $myage = $var_cal{'hidden'};
                    }
                    else {
                        $myage = $age;
                    }

                    $viewmont = $mybdlist_viewmont;
                    $viewmont =~ s/{yabb cal_col_star}/$cal_col_star/sm;
                    $viewmont =~ s/{yabb user_linkprofile}/$user_linkprofile/sm;
                    $viewmont =~ s/{yabb myage}/$myage/sm;
                    $viewmont =~ s/{yabb sternzeichen}/$sternzeichen/sm;
                    $viewmont =~ s/{yabb cdate}/$cdate/sm;
                    $montview .= $viewmont;
                }
            }
            $yyvmon =~ s/{yabb viewmont}/$montview/sm;
        }
        elsif ( ( $calsplit == 0 || @birthmembers1 < $calsplit ) && $countmont[$j] ) {
                $yyvmon .= $mybdlist_viewmont2;
                $yyvmon =~ s/{yabb cal_colspan}/$cal_colspan/gsm;
                $yyvmon =~ s/{yabb cal_col}/$cal_col/gsm;
                $yyvmon =~ s/{yabb cal_col_star_sort}/$cal_col_star_sort/gsm;
                $yyvmon =~ s/{yabb calmont}/$var_cal{$calmont[$j]}/sm;
                $yyvmon =~ s/{yabb countmont}/$countmont[$j]/sm;
                $yyvmon =~ s/{yabb cal_info_header}/$cal_info_header/sm;
                $yyvmon =~ s/{yabb input_letters}/$letter_s/sm;
                $montview = q{};
                for my $user_name ( sort { &{$sortiert}( $a, $b ); } @birthmembers1) {
                    chomp $user_name;
                    (
                        $user_bdyear, $user_bdmon, $user_bdday, $user_bdname, $age,
                        $sternzeichen, $user_bdrealname, $user_bdhide
                    ) = split /\|/xsm, $user_name;
                    if ($user_bdmon == $j || $user_bdmon eq "$j") {
                        $showviewbd = 0;
                        if ($letter) {
                            $searchbdname = $user_bdrealname;
                            $searchbdname = isempty( $searchbdname, $user_bdname );
                            if ( $searchbdname =~ /^$letter/ism ) { $showviewbd = 1; }
                        }
                        else {
                            $showviewbd = 1;
                        }
                        if ($showviewbd) {
                            $cdate = $var_cal{'hidden'};
                            if ( $Show_BirthdayDate == 2 || ( $Show_BirthdayDate == 1 && !$iamguest ) ) {
                                $mybtime = stringtotime( qq~$user_bdmon/$user_bdday/$user_bdyear~);
                                $mybtimein = timeformatcal($mybtime);
                                $cdate     = dtonly($mybtimein);
                                if ( $showage && $user_bdhide ) {
                                    $cdate = bdayno_year($mybtimein);
                                }
                            }
                            if ($Show_BdColorLinks) {
                                LoadUser($user_bdname);
                                $user_linkprofile = $link{$user_bdname};
                            }
                            else {
                                $user_linkname = $user_bdrealname;
                                LoadUser($user_bdname);
                                if ( $iamguest ) {
                                    $user_linkprofile = qq~$format_unbold{$user_bdname}~;
                                }
                                else {
                                    $user_linkprofile = qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user_bdname}" rel="nofollow">$format_unbold{$user_bdname}</a>~;
                                }
                            }
                            if ( $showage && $user_bdhide ) {
                                $myage = $var_cal{'hidden'};
                            }
                            else {
                                $myage = $age;
                            }

                            $viewmont = $mybdlist_viewmont;
                            $viewmont =~ s/{yabb cal_col_star}/$cal_col_star/sm;
                            $viewmont =~ s/{yabb user_linkprofile}/$user_linkprofile/sm;
                            $viewmont =~ s/{yabb myage}/$myage/sm;
                            $viewmont =~ s/{yabb sternzeichen}/$sternzeichen/sm;
                            $viewmont =~ s/{yabb cdate}/$cdate/sm;
                            $montview .= $viewmont;
                        }
                    }
                }
                $yyvmon =~ s/{yabb viewmont}/$montview/sm;

        }
    }
    $yymain .= $mybdlist_calgoto;
    $yymain .= $my_alpha_a;
    $yymain .= $viewbirthdays;
    $yymain .= $bdmonths;
    $yymain .= $yyvmon;
    $yymain =~ s/{yabb calgotobox}/$calgotobox/sm;
    $yymain =~ s/{yabb cal_colspan}/$cal_colspan/gsm;
    $yymain =~ s/{yabb my_bdtoday}/$my_bdtoday/gsm;
    $yymain =~ s/{yabb cal_col}/$cal_col/gsm;
    $yymain =~ s/{yabb cal_col_star_sort}/$cal_col_star_sort/gsm;
    $yymain =~ s/{yabb class_sortuser}/$class_sortuser/sm;
    $yymain =~ s/{yabb class_sortage}/$class_sortage/sm;
    $yymain =~ s/{yabb class_sortstarsign}/$class_sortstarsign/sm;
    $yymain =~ s/{yabb class_sortdate}/$class_sortdate/sm;

    if ( $no_bd_found == 1 && ( $calsplit == 0 || @birthmembers1 <= $calsplit ) ) {
        $yymain .= $mybdlist_nobd;
        for my $i ( 1 .. 12 ) {
            $nobdays .= qq~$no_birthday_found[$i]~;
        }

        $yymain =~ s/{yabb cal_colspan}/$cal_colspan/gsm;
        $yymain =~ s/{yabb nobdays}/$nobdays/sm;
    }

    # Birthdaylist output end

    $yytitle = "$var_cal{yytitle} $var_cal{'calbirthdays'}";
    template();
    exit;
}

# view birthdays end

# sort area begin

sub sortdate {
    my @zahl1 = split /\|/xsm, $a;
    my @zahl2 = split /\|/xsm, $b;

    return ( $zahl1[2] . $zahl1[0] <=> $zahl2[2] . $zahl2[0] );
}

sub sortage {
    my @zahl1 = split /\|/xsm, $a;
    my @zahl2 = split /\|/xsm, $b;

    return ($zahl1[4]
          . $zahl1[2]
          . $zahl1[0] <=> $zahl2[4]
          . $zahl2[2]
          . $zahl2[0] );
}

sub sortstarsign {
    my @name1 = split /\|/xsm, $a;
    my @name2 = split /\|/xsm, $b;

    return ( $name1[5] cmp $name2[5] );
}

sub sortuser {
    my @name1 = split /\|/xsm, $a;
    my @name2 = split /\|/xsm, $b;
    return ( lc $name1[6] cmp lc $name2[6] );
}

sub starsign {
    my ( $user_bdday, $user_bdmon, $text ) = @_;
    my @stars =
      qw(Capricorn Aquarius Aquarius Pisces Pisces Aries Aries Taurus Taurus Gemini Gemini Cancerian Cancerian Leo Leo Virgo Virgo Libra Libra Scorpio Scorpio Sagittarius Sagittarius Capricorn);
    my @bd_1 = (
        1, 21, 1, 20, 1, 21, 1, 21, 1, 21, 1, 22,
        1, 23, 1, 24, 1, 24, 1, 24, 1, 23, 1, 22,
    );
    my @bd_2 = (
        20, 31, 19, 29, 20, 31, 20, 30, 20, 31, 21, 30,
        21, 31, 22, 31, 23, 30, 23, 31, 22, 30, 21, 31,
    );
    my @bd_3 = (
        1, 1, 2, 2, 3, 3, 4,  4,  5,  5,  6,  6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12,
    );

    for my $i ( 0 .. 23 ) {
        if (   $user_bdday >= $bd_1[$i]
            && $user_bdday <= $bd_2[$i]
            && $user_bdmon == $bd_3[$i] )
        {
            if ($text) {
                LoadLanguage('Profile');
                $sternzeichen = "$zodiac_txt{$stars[$i]}";
            }
            else {
                $sternzeichen = "$var_cal{$stars[$i]}";
            }
        }
    }
    return $sternzeichen;
}

1;
