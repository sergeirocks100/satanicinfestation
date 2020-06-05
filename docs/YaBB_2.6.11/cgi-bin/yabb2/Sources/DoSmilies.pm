###############################################################################
# DoSmilies.pm                                                                #
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
our $VERSION = '2.6.11';

$dosmiliespmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Main');
get_template('Other');

sub SmiliePut {
    print_output_header();
    $moresmilieslist   = q{};
    $evenmoresmilies   = q{};
    $more_smilie_array = q{};
    $i                 = 0;
    while ( $SmilieURL[$i] ) {
        if ( $SmilieURL[$i] =~ /\//ixsm ) { $tmpurl = $SmilieURL[$i]; }
        else { $tmpurl = qq~$defaultimagesdir/$SmilieURL[$i]~; }
        if ( $i && ( $i / 10 ) == int( $i / 10 ) ) {
            $moresmilieslist .= q~<br />~;
        }
        $moresmilieslist .=
qq~<img src="$tmpurl" class="moresmiles" alt="$SmilieDescription[$i]" onclick="javascript:MoreSmilies($i)" />$SmilieLinebreak[$i]\n~;
        $smilie_url_array .= qq~"$tmpurl", ~;
        $tmpcode = $SmilieCode[$i];
        $tmpcode =~ s/\&quot;/"+'"'+"/gxsm;    #'; to keep my text editor happy;
        FromHTML($tmpcode);
        $tmpcode =~ s/&#36;/\$/gxsm;
        $tmpcode =~ s/&#64;/\@/gxsm;
        $more_smilie_array .= qq~" $tmpcode", ~;
        $i++;
    }
    if ( $showsmdir == 3 || ( $showsmdir == 2 && $detachblock == 1 ) ) {
        opendir DIR, "$htmldir/Smilies";
        @contents = readdir DIR;
        closedir DIR;
        $smilieslist = q{};
        foreach my $line ( sort { uc $a cmp uc $b } @contents ) {
            ( $name, $extension ) = split /\./xsm, $line;
            if (   $extension =~ /gif/ism
                || $extension =~ /jpg/ism
                || $extension =~ /jpeg/ism
                || $extension =~ /png/ism )
            {
                if ( $line !~ /banner/ism ) {
                    if ( $i && ( $i / 10 ) == int( $i / 10 ) ) {
                        $evenmoresmilies .= q~<br />~;
                    }
                    $evenmoresmilies .=
qq~<img src="$yyhtml_root/Smilies/$line" id="$name" onclick="javascript:MoreSmilies($i)" class="moresmiles" alt="moresmilies" />\n~;
                    $more_smilie_array .= qq~" [smiley=$line]", ~;
                    $i++;
                }
            }
        }
    }
    $more_smilie_array .= q~''~;
    if ( $showadded == 3 || ( $showadded == 2 && $detachblock == 1 ) ) {
        $my_output .= qq~ $moresmilieslist ~;
    }

    $output = $smilie_window_a;
    $output =~ s/{yabb popback}/$popback/sm;
    $output =~ s/{yabb poptext}/$poptext/sm;
    $output =~ s/{yabb my_output}/$my_output/sm;
    $output =~ s/{yabb evenmoresmilies}/$evenmoresmilies/sm;
    $output =~ s/{yabb more_smilie_array}/$more_smilie_array/sm;

    print_HTML_output_and_finish();
    return;
}

sub SmilieIndex {
    print_output_header();

    $i                 = 0;
    $offset            = 0;
    $smilieslist       = q{};
    $smilie_code_array = q{};
    if ( $showadded == 3 || ( $showadded == 2 && $detachblock == 1 ) ) {
        while ( $SmilieURL[$i] ) {
            if ( $i % 4 == 0 && $i != 0 ) {
                $smilieslist .= $my_smilie_window_tr;
                $offset++;
            }
            if ( ( $i + $offset ) % 2 == 0 ) {
                $smiliescolor = $my_smiliebg_a;
            }
            else { $smiliescolor = $my_smiliebg_b; }
            if ( $SmilieURL[$i] =~ /\//ixsm ) { $tmpurl = $SmilieURL[$i]; }
            else { $tmpurl = qq~$defaultimagesdir/$SmilieURL[$i]~; }

            $smilieslist .= $my_smilie_window_td;
            $smilieslist =~ s/{yabb smiliescolor}/$smiliescolor/gsm;
            $smilieslist =~ s/{yabb tmpurl}/$tmpurl/gsm;
            $smilieslist =~ s/{yabb i}/$i/gsm;
            $smilieslist =~ s/{yabb poptext}/$poptext/gsm;
            $smilieslist =~
              s/{yabb SmilieDescription}/$SmilieDescription[$i]/gsm;

            $smilie_url_array .= qq~"$tmpurl", ~;
            $tmpcode = $SmilieCode[$i];
            $tmpcode =~ s/\&quot;/"+'"'+"/gxsm;    #';
            FromHTML($tmpcode);
            $tmpcode =~ s/&#36;/\$/gxsm;
            $tmpcode =~ s/&#64;/\@/gxsm;
            $more_smilie_array .= qq~" $tmpcode", ~;
            $i++;
        }
    }
    if ( $showsmdir == 3 || ( $showsmdir == 2 && $detachblock == 1 ) ) {
        opendir DIR, "$htmldir/Smilies";
        @contents = readdir DIR;
        closedir DIR;
        foreach my $line ( sort { uc($a) cmp uc $b } @contents ) {
            ( $name, $extension ) = split /\./xsm, $line;
            if (   $extension =~ /gif/ixsm
                || $extension =~ /jpg/ixsm
                || $extension =~ /jpeg/ixsm
                || $extension =~ /png/ixsm )
            {
                if ( $line !~ /banner/ixsm ) {
                    if ( $i % 4 == 0 && $i != 0 ) {
                        $smilieslist .= $my_smilie_window_tr;
                        $offset++;
                    }
                    if ( ( $i + $offset ) % 2 == 0 ) {
                        $smiliescolor = $my_smiliebg_a;
                    }
                    else { $smiliescolor = $my_smiliebg_b; }
                    $smilieslist .= $my_smilie_window_td_line;
                    $smilieslist =~ s/{yabb smiliescolor}/$smiliescolor/gsm;
                    $smilieslist =~ s/{yabb line}/$line/gsm;
                    $smilieslist =~ s/{yabb i}/$i/gsm;
                    $smilieslist =~ s/{yabb poptext}/$poptext/gsm;

                    $more_smilie_array .= qq~" [smiley=$line]", ~;
                    $i++;
                }
            }
        }
    }
    while ( $i % 4 != 0 ) {
        if ( ( $i + $offset ) % 2 == 0 ) {
            $smiliescolor = $my_smiliebg_a;
        }
        else { $smiliescolor = $my_smiliebg_b }
        $smilieslist .= $my_smilie_window_blnk;
        $smilieslist =~ s/{yabb smiliescolor}/$smiliescolor/gsm;
        $i++;
    }
    $smilie_code_array .= q~""~;
    $more_smilie_array .= q~""~;
    if ( -e "$htmldir/Smilies/$my_banner" ) {
        $smiliesheader = $my_smilie_banner_header;
    }
    else {
        $smiliesheader = $my_smilie_header;
    }

    $output = $smilie_window_advanced;
    $output =~ s/{yabb popback}/$popback/gsm;
    $output =~ s/{yabb smiliesheader}/$smiliesheader/sm;
    $output =~ s/{yabb smilieslist}/$smilieslist/sm;
    $output =~ s/{yabb more_smilie_array}/$more_smilie_array/sm;

    print_HTML_output_and_finish();
    return;
}

1;
