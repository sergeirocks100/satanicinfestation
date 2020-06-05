###############################################################################
# Settings_ExtendedProfiles.pm                                                #
# $Date: 12.02.14 $                                                           #
###############################################################################
# YaBB: Yet another Bulletin Board                                            #
# Version:        YaBB 2.6.11                                                 #
# Packaged:       December 2, 2014                                            #
# Distributed by: http://www.yabbforum.com                                    #
# =========================================================================== #
# Copyright (c) 2000-2014 YaBB (www.yabbforum.com) - All Rights Reserved.     #
# Software by:  The YaBB Development Team                                     #
#               with assistance from the YaBB community.                      #
###############################################################################
# This file was part of the Extended Profiles Mod which has been created by   #
# Michael Prager. Last modification by him: 15.11.07                          #
# Added to the YaBB default code on 07. September 2008                        #
###############################################################################
our $VERSION = '2.6.11';

$settings_extendedprofilespmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('ExtendedProfiles');

$ext_spacer_hr        = q~<hr class="hr" />~;
$ext_spacer_br        = q~<br />~;
$ext_max_email_length = 60;
$ext_max_url_length   = 100;
$ext_max_image_length = 100;

my %field;

# outputs the value of a user's extended profile field
## USAGE: $value = ext_get("admin","my_custom_fieldname");
##  or    $value_raw = ext_get("admin","my_custom_fieldname",1);
## pass the third argument if you want to get the raw content e.g. an unformatted date
sub ext_get {
    my (
        $pusername, $fieldname, $no_parse,           @ext_profile,
        @options,   $field,     $id,                 $value,
        $width,     $height,    @allowed_extensions, $extension,
        $match
    ) = ( shift, shift, shift );

    ext_get_profile($pusername);
    $id    = ext_get_field_id($fieldname);
    $value = ${ $uid . $pusername }{ 'ext_' . $id };
    if ( $no_parse eq q{} || $no_parse == 0 ) {
        $field = ext_get_field($id);
        if ( $field{'type'} eq 'text' ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $options[3] ne q{} && $value eq q{} ) { $value = $options[3]; }
            if ( $options[4] == 1 ) {
                $value = ext_parse_ubbc( $value, $pusername );
            }

        }
        elsif ( $field{'type'} eq 'text_multi' && $value ne q{} ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $options[3] == 1 ) {
                $value = ext_parse_ubbc( $value, $pusername );
            }

        }
        elsif ( $field{'type'} eq 'select' ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $value > $#options || $value eq q{} ) { $value = 0; }
            $value = $options[$value];

        }
        elsif ( $field{'type'} eq 'radiobuttons' ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $value > $#options ) { $value = 0; }
            if ( !$field{'radiounselect'} && $value eq q{} ) { $value = 0; }
            if ( $value ne q{} ) { $value = $options[$value]; }

        }
        elsif ( $field{'type'} eq 'date' && $value ne q{} ) {
            $value = ext_timeformat($value);

        }
        elsif ( $field{'type'} eq 'checkbox' ) {
            if   ( $value == 1 ) { $value = $lang_ext{'true'} }
            else                 { $value = $lang_ext{'false'} }
        }
        elsif ( $field{'type'} eq 'spacer' ) {
            @options = split /\^/xsm, $field{'options'};
            if   ( $options[0] == 1 ) { $value = qq~$ext_spacer_br~; }
            else                      { $value = qq~$ext_spacer_hr~; }
        }
        elsif ( $field{'type'} eq 'url' && $value ne q{} ) {
            if ( $value !~ m{\Ahttp://}sm ) { $value = "http://$value"; }
        }
        elsif ( $field{'type'} eq 'image' && $value ne q{} ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $options[2] ne q{} ) {
                @allowed_extensions = split /\ /xsm, $options[2];
                $match = 0;
                foreach my $extension (@allowed_extensions) {
                    if ( grep { /$extension$/ism } $value ) {
                        $match = 1;
                        last;
                    }
                }
                if ( $match == 0 ) { return q{}; }
            }
            if ( $options[0] ne q{} && $options[0] != 0 ) {
                $width = q~ width="~ . ( $options[0] + 0 ) . q~"~;
            }
            else { $width = q{}; }
            if ( $options[1] ne q{} && $options[1] != 0 ) {
                $height = q~ height="~ . ( $options[1] + 0 ) . q~"~;
            }
            else { $height = q{}; }
            if ( $value !~ m{\Ahttp://}sm ) { $value = "http://$value"; }
            $value = qq~<img src="$value" class="vtop"$width$height alt=q{} />~;
        }
    }

    return $value;
}

sub ext_get_profile {
    LoadUser(shift);
    return;
}

# returns an array of the form qw(ext_0 ext_1 ext_2 ...)
sub ext_get_fields_array {
    my ( $count, @result ) = (0);
    foreach (@ext_prof_fields) {
        push @result, "ext_$count";
        $count++;
    }
    return @result;
}

# returns the id of a field through the fieldname
sub ext_get_field_id {
    my ( $fieldname, $count, $id, $current, $currentname, $dummy ) =
      ( shift, 0 );
    foreach my $current (@ext_prof_fields) {
        ( $currentname, $dummy ) = split /\|/xsm, $current;
        if ( $currentname eq $fieldname ) { $id = $count; last; }
        $count++;
    }
    return $id;
}

# returns all settings of a specific field
sub ext_get_field {
    $field{'id'} = shift;
    (
        $field{'name'},                   $field{'type'},
        $field{'options'},                $field{'active'},
        $field{'comment'},                $field{'required_on_reg'},
        $field{'visible_in_viewprofile'}, $field{'v_users'},
        $field{'v_groups'},               $field{'visible_in_posts'},
        $field{'p_users'},                $field{'p_groups'},
        $field{'p_displayfieldname'},     $field{'visible_in_memberlist'},
        $field{'m_users'},                $field{'m_groups'},
        $field{'editable_by_user'},       $field{'visible_in_posts_popup'},
        $field{'pp_users'},               $field{'pp_groups'},
        $field{'pp_displayfieldname'},    $field{'radiounselect'},
        undef
    ) = split /\|/xsm, $ext_prof_fields[ $field{'id'} ];
    return;
}

# formats a MM/DD/YYYY string to the user's preferred format, ignores time completely!
sub ext_timeformat {
    my (
        $mytimeselected, $oldformat,  $mytimeformat, $newday,
        $newday2,        $newmonth,   $newmonth2,    $newyear,
        $newshortyear,   $oldmonth,   $oldday,       $oldyear,
        $newweekday,     $newyearday, $newweek,      $dummy,
        $usefullmonth
    );

    if ( ${ $uid . $username }{'timeselect'} > 0 ) {
        $mytimeselected = ${ $uid . $username }{'timeselect'};
    }
    else { $mytimeselected = $timeselected; }

    $oldformat = shift;
    if ( $oldformat eq q{} || $oldformat eq "\n" ) { return $oldformat; }

    $oldmonth = substr $oldformat, 0, 2;
    $oldday   = substr $oldformat, 3, 2;
    $oldyear  = substr $oldformat, 6, 4;

    if ( $oldformat ne q{} ) {
        $newday       = $oldday + 0;
        $newmonth     = $oldmonth + 0;
        $newyear      = $oldyear + 0;
        $newshortyear = substr $newyear, 2, 2;
        if ( $newmonth < 10 ) { $newmonth = "0$newmonth"; }
        if ( $newday < 10 && $mytimeselected != 4 ) { $newday = "0$newday"; }

        if ( $mytimeselected == 1 ) {
            qq~$newmonth/$newday/$newshortyear~;

        }
        elsif ( $mytimeselected == 2 ) {
            $newformat = qq~$newday.$newmonth.$newshortyear~;
            return $newformat;

        }
        elsif ( $mytimeselected == 3 ) {
            $newformat = qq~$newday.$newmonth.$newyear~;
            return $newformat;

        }
        elsif ( $mytimeselected == 4 || $mytimeselected == 8 ) {
            $newmonth--;
            $newmonth2 = $months[$newmonth];
            if ( $newday > 10 && $newday < 20 ) {
                $newday2 = "$timetxt{'4'}";
            }
            elsif ( $newday % 10 == 1 ) {
                $newday2 = "$timetxt{'1'}";
            }
            elsif ( $newday % 10 == 2 ) {
                $newday2 = "$timetxt{'2'}";
            }
            elsif ( $newday % 10 == 3 ) {
                $newday2 = "$timetxt{'3'}";
            }
            else { $newday2 = "$timetxt{'4'}"; }
            $newformat = qq~$newmonth2 $newday$newday2, $newyear~;
            return $newformat;

        }
        elsif ( $mytimeselected == 5 ) {
            $newformat = qq~$newmonth/$newday/$newshortyear~;
            return $newformat;

        }
        elsif ( $mytimeselected == 6 ) {
            $newmonth2 = $months[ $newmonth - 1 ];
            $newformat = qq~$newday. $newmonth2 $newyear~;
            return $newformat;

        }
        elsif ( $mytimeselected == 7 ) {
            (
                $dummy,      $dummy,      $dummy,
                $dummy,      $dummy,      $dummy,
                $newweekday, $newyearday, $dummy
            ) = gmtime $oldformat;
            $newweek = int( ( $newyearday + 1 - $newweekday ) / 7 ) + 1;

            $mytimeformat = ${ $uid . $username }{'timeformat'};
            if ( $mytimeformat =~ m/MM/sm ) { $usefullmonth = 1; }
            $mytimeformat =~ s/(?:\s)*\@(?:\s)*//gxsm;
            $mytimeformat =~ s/HH(?:\s)?//gxsm;
            $mytimeformat =~ s/mm(?:\s)?//gxsm;
            $mytimeformat =~ s/ss(?:\s)?//gxsm;
            $mytimeformat =~ s/://gxsm;
            $mytimeformat =~ s/ww(?:\s)?//gxsm;
            $mytimeformat =~ s/(.*?)(?:\s)*$/$1/gxsm;

            if ( $mytimeformat =~ m/\+/sm ) {
                if ( $newday > 10 && $newday < 20 ) {
                    $dayext = "$timetxt{'4'}";
                }
                elsif ( $newday % 10 == 1 ) {
                    $dayext = "$timetxt{'1'}";
                }
                elsif ( $newday % 10 == 2 ) {
                    $dayext = "$timetxt{'2'}";
                }
                elsif ( $newday % 10 == 3 ) {
                    $dayext = "$timetxt{'3'}";
                }
                else { $dayext = "$timetxt{'4'}"; }
            }
            $mytimeformat =~ s/YYYY/$newyear/gxsm;
            $mytimeformat =~ s/YY/$newshortyear/gxsm;
            $mytimeformat =~ s/DD/$newday/gxsm;
            $mytimeformat =~ s/D/$newday/gxsm;
            $mytimeformat =~ s/\+/$dayext/gxsm;
            if ( $usefullmonth == 1 ) {
                $mytimeformat =~ s/MM/$months[$newmonth-1]/gxsm;
            }
            else {
                $mytimeformat =~ s/M/$newmonth/gxsm;
            }

            $mytimeformat =~ s/\*//gxsm;
            return $mytimeformat;
        }
    }
    else { return q{}; }

    #no return;
}


# returns the output for the Extended Profile Controls in admin center
sub ext_admin {
    my ( $id, $output, $fieldname, @options, $active, @selected, @contents );

    is_admin_or_gmod();

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">$admin_img{'profile'} <b>$lang_ext{'Profiles_Controls'}</b></td>
        </tr><tr>
            <td class="windowbg2">$lang_ext{'admin_description'}</td>
        </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">$admin_img{'profile'} <b>$lang_ext{'edit_title'}</b></td>
        </tr><tr>
            <td class="windowbg2">$lang_ext{'edit_description'}</td>
        </tr><tr>
            <td class="windowbg2">
                <table class="windowbg2 pad-cell">
                    <colgroup>
                        <col style="width:25%" span="4" />
                    </colgroup>
                    <tr>
                        <td class="center">$lang_ext{'active'}</td>
                        <td class="center">$lang_ext{'field_name'}</td>
                        <td class="center">$lang_ext{'field_type'}</td>
                        <td class="center">$lang_ext{'actions'}</td>
                    </tr>~;
    if ( !@ext_prof_order ) {
        $yymain .= qq~<tr>
                        <td class="windowbg2 center" style="padding:.5em 0 1em 0;" colspan="4"><i>$lang_ext{'no_additional_fields_set'}</i></td>
                    </tr>
                </table>~;
    }
    else {
         $yymain .= q~              </table>~;
        foreach my $fieldname (@ext_prof_order) {
            $id = ext_get_field_id($fieldname);
            ext_get_field($id);
            my @typelist = qw( text text_multi select radiobuttons checkbox date email url spacer image );
            foreach my $i (0 .. 9) {
                if ($field{'type'} eq $typelist[$i]) {
                    $selected[$i] = ' selected="selected"';
            }
                else { $selected[$i] = q{}; }
            }
            if   ( $field{'active'} == 1 ) { $active = ' checked="checked"'; }
            else                           { $active = q{}; }

            $yymain .= qq~
                <form action="$adminurl?action=ext_edit" method="post">
                <table class="windowbg2 pad-cell">
                    <colgroup>
                        <col style="width:25%" span="4" />
                    </colgroup>
                    <tr>
                        <td class="windowbg2 center">
                            <input name="id" type="hidden" value="$id" />
                            <input type="checkbox" name="active" value="1"$active />
                        </td>
                        <td class="windowbg2 center">
                            <input name="name" value="$field{'name'}" size="20" />
                        </td>
                        <td class="windowbg2 center">
                            <select name="type" size="1">
                                <option value="text"$selected[0]>$lang_ext{'text'}</option>
                                <option value="text_multi"$selected[1]>$lang_ext{'text_multi'}</option>
                                <option value="select"$selected[2]>$lang_ext{'select'}</option>
                                <option value="radiobuttons"$selected[3]>$lang_ext{'radiobuttons'}</option>
                                <option value="checkbox"$selected[4]>$lang_ext{'checkbox'}</option>
                                <option value="date"$selected[5]>$lang_ext{'date'}</option>
                                <option value="email"$selected[6]>$lang_ext{'email'}</option>
                                <option value="url"$selected[7]>$lang_ext{'url'}</option>
                                <option value="spacer"$selected[8]>$lang_ext{'spacer'}</option>
                                <option value="image"$selected[9]>$lang_ext{'image'}</option>
                            </select>
                        </td>
                        <td class="windowbg2 center">
                            <input type="submit" name="apply" value="$lang_ext{'apply'}" />
                            <input type="submit" name="options" value="$lang_ext{'options'}" />
                            <input type="submit" name="delete" value="$lang_ext{'delete'}" />
                        </td>
                    </tr>
                </table>
            </form>~;
        }
    }

    $yymain .= qq~
         </td>
    </tr>
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <td class="titlebg">$admin_img{'profile'} <b>$lang_ext{'create_new_title'}</b></td>
    </tr><tr>
        <td class="windowbg2">$lang_ext{'create_new_description'}</td>
    </tr><tr>
        <td class="windowbg2">
            <form action="$adminurl?action=ext_create" method="Post">
    <table class="pad-cell">
      <tr>
        <td class="windowbg2 center"><label for="name">$lang_ext{'field_name'}</label></td>
        <td class="windowbg2 center"><label for="type">$lang_ext{'field_type'}</label></td>
        <td class="windowbg2 center">$lang_ext{'actions'}</td>
      </tr><tr>
        <td class="windowbg2 center">
          <input name="name" id="name" size="30" />
        </td>
        <td class="windowbg2 center">
          <select name="type" id="type" size="1">
            <option value="text" selected="selected">$lang_ext{'text'}</option>
            <option value="text_multi">$lang_ext{'text_multi'}</option>
            <option value="select">$lang_ext{'select'}</option>
            <option value="radiobuttons">$lang_ext{'radiobuttons'}</option>
            <option value="checkbox">$lang_ext{'checkbox'}</option>
            <option value="date">$lang_ext{'date'}</option>
            <option value="email">$lang_ext{'email'}</option>
            <option value="url">$lang_ext{'url'}</option>
            <option value="spacer">$lang_ext{'spacer'}</option>
            <option value="image">$lang_ext{'image'}</option>
          </select>
        </td>
        <td class="windowbg2 center">
          <input type="submit" name="create" value="$lang_ext{'create_field'}" />
        </td>
                </tr>
            </table>
        </form>
        </td>
      </tr>
    </table>
</div>
<div class="bordercolor rightboxdiv">
<form action="$adminurl?action=ext_reorder" method="post">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
      <tr>
        <td class="titlebg">$admin_img{'profile'} <b>$lang_ext{'reorder_title'}</b></td>
    </tr><tr>
        <td class="windowbg2">
            <table class="pad_6px">
                <tr>
            <td class="windowbg2 vtop">
          <textarea name="reorder" cols="30" rows="6">~;

    foreach my $fieldname (@ext_prof_order) { $yymain .= $fieldname . "\n"; }

    $yymain .= qq~</textarea>
        </td>
            <td class="windowbg2 vtop">
          $lang_ext{'reorder_description'}<br /><br />
          <input type="submit" name="reorder_submit" value="$lang_ext{'reorder'}" />
        </td>
                </tr>
            </table>

        </td>
    </tr>
    </table>
</form>
</div>
~;
    if ( -e "$vardir/Extended.lock" ) { $yymain .= FoundExtLock();}
    else {
    if ( -e "$vardir/ConvSettings.txt" ) {
        require "$vardir/ConvSettings.txt";
    }
    else {
        $convmemberdir = './Convert/Members';
        $convvardir    = './Convert/Variables';
    }

    $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg"><img src="$imagesdir/profile.gif" alt="" /> <b>$lang_ext{'converter_title'}</b></td>
        </tr><tr>
            <td class="windowbg2">$lang_ext{'converter_description'}
                <form action="$adminurl?action=ext_convert" method="post">
                <p class="center"><br />
                <label for="members">$lang_ext{'path_old_members_folder'}:</label>  <input name="members" id="members" value="$convmemberdir" /><br />
                <label for="vars">$lang_ext{'path_old_variables_folder'}:</label>  <input name="vars" id="vars" value="$convvardir" /><br /><br />
                <input type="submit" name="convert" value="$lang_ext{'converter_button'}" /><br /><br /></p>
        </form>
        </td>
      </tr>
      </table>
</div>
~;
}
    $yytitle     = $lang_ext{'Profiles_Controls'};
    $action_area = 'ext_admin';
    AdminTemplate();
    return;
}

# reorders the fields as submitted
sub ext_admin_reorder {
    is_admin_or_gmod();

    $FORM{'reorder'} =~ tr/\r//d;
    $FORM{'reorder'} =~ s/\A[\s\n]+//xsm;
    $FORM{'reorder'} =~ s/[\s\n]+\Z//xsm;
    $FORM{'reorder'} =~ s/\n\s*\n/\n/gxsm;
    ToHTML( $FORM{'reorder'} );

    @ext_prof_order = split /\n/xsm, $FORM{'reorder'};

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=ext_admin~;
    redirectexit();
    return;
}

# creates a new field as submitted
sub ext_admin_create {
    is_admin_or_gmod();

    ToHTML( $FORM{'name'} );

    push @ext_prof_order, $FORM{'name'};
    push @ext_prof_fields,
      "$FORM{'name'}|$FORM{'type'}||1||0|1|||0|||0|0|||1|0|||0|0";

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=ext_admin~;
    redirectexit();
    return;
}

# will generate us a nicely formated table row for the input form
sub ext_admin_gen_inputfield {
    my ( $var1, $var2, $var3, $output ) = ( shift, shift, shift );
    $output = qq~<tr>
            <td class="windowbg2 vtop"><b>$var1: </b>
                <br /><span class="small">$var2</span></td>
            <td class="windowbg2 vtop">$var3</td>
        </tr>~;

    return $output;
}

# generate html form option list depending on the passed groups string
sub ext_admin_gen_groupslist {
    my ( $groups, $output, $groupid, @groups, %groupcheck ) = ( shift, q{} );

    @groups = split /\s*\,\s*/xsm, $groups;
    foreach (@groups) {
        $groupcheck{$_} = ' selected="selected"';
    }
    my @grps = ( 'Administrator','Global Moderator','Mid Moderator','Moderator',);
    my $output = q{};
    foreach (@grps) {
        $output .= qq~<option value="$_"$groupcheck{$_}>~
      . ( split /\|/xsm, $Group{$_} )[0]
      . qq~</option>\n~;
    }

    foreach ( sort { $a <=> $b } keys %NoPost ) {
        $groupid = $_;
        $output .=
qq~<option value="NoPost{$groupid}"$groupcheck{'NoPost{'.$groupid.'}'}>~
          . ( split /\|/xsm, ( split /\|/xsm, $NoPost{$groupid} )[0] )[0]
          . qq~</option>\n~;
    }
    foreach ( reverse sort { $a <=> $b } keys %Post ) {
        $groupid = $_;
        $output .=
            qq~<option value="Post{$groupid}"$groupcheck{'Post{'.$groupid.'}'}>~
          . ( split /\|/xsm, ( split /\|/xsm, $Post{$groupid} )[0] )[0]
          . qq~</option>\n~;
    }

    return $output;
}

# performs all actions done in the edit profile field panel
sub ext_admin_edit {
    @x = @_;
    my (
        @fields,    @order,       $type,           $active,
        $id,        $name,        $oldname,        $req1,
        $req2,      $req3,        $v_check,        $p_check,
        $p_d_check, $m_check,     @editable_check, $is_numeric,
        $ubbc,      @options,     $check1,         $check2,
        @contents,  @old_content, $new_content,    $output
    );
    $oldname = $x[0];
    is_admin_or_gmod();

    if ( $FORM{'apply'} ne q{} ) {
        ToHTML( $FORM{'name'} );
        $name   = $FORM{'name'};
        $id     = $FORM{'id'};
        $type   = $FORM{'type'};
        $active = $FORM{'active'} ne q{} ? 1 : 0;

        @fields = @ext_prof_fields;
        @_ = split /\|/xsm, $fields[ $FORM{'id'} ];
        $fields[ $FORM{'id'} ] =
"$name|$type|$x[2]|$active|$x[4]|$x[5]|$x[6]|$x[7]|$x[8]|$x[9]|$x[10]|$x[11]|$x[12]|$x[13]|$x[14]|$x[15]|$x[16]|$x[17]|$x[18]|$x[19]|$x[20]|$x[21]";
        @ext_prof_fields = @fields;

        @order = @ext_prof_order;
        $id    = 0;
        foreach (@order) {
            if ( $oldname eq $_ ) { $order[$id] = $name; last; }
            $id++;
        }
        @ext_prof_order = @order;

        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');

        $yySetLocation = qq~$adminurl?action=ext_admin~;
        redirectexit();

    }
    elsif ( $FORM{'options'} ne q{} ) {
        ext_get_field( $FORM{'id'} );
        if   ( $field{'active'} == 1 ) { $active = $lang_ext{'true'}; }
        else                           { $active = $lang_ext{'false'}; }
        if ( $field{'required_on_reg'} == 1 ) {
            $req1 = q{};
            $req2 = ' checked="checked"';
            $req3 = q{};
        }
        elsif ( $field{'required_on_reg'} == 2 ) {
            $req1 = q{};
            $req2 = q{};
            $req3 = ' checked="checked"';
        }
        else { $req1 = ' checked="checked"'; $req2 = q{}; $req3 = q{}; }
        if ( $field{'visible_in_viewprofile'} == 1 ) {
            $v_check = ' checked="checked"';
        }
        else { $v_check = q{}; }
        if ( $field{'visible_in_posts'} == 1 ) {
            $p_check = ' checked="checked"';
        }
        else { $p_check = q{}; }
        if ( $field{'visible_in_posts_popup'} == 1 ) {
            $pp_check = ' checked="checked"';
        }
        else { $pp_check = q{}; }
        if ( $field{'p_displayfieldname'} == 1 ) {
            $p_d_check = ' checked="checked"';
        }
        else { $p_d_check = q{}; }
        if ( $field{'pp_displayfieldname'} == 1 ) {
            $pp_d_check = ' checked="checked"';
        }
        else { $pp_d_check = q{}; }
        if ( $field{'visible_in_memberlist'} == 1 ) {
            $m_check = ' checked="checked"';
        }
        else { $m_check = q{}; }
        if ( $field{'radiounselect'} == 1 ) {
            $radiounselect = ' checked="checked"';
        }
        else { $radiounselect = q{}; }
        $editable_check[ $field{'editable_by_user'} ] = ' selected="selected"';
        $yymain .= qq~
<form action="$adminurl?action=ext_edit2" method="post" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <td class="titlebg">$admin_img{'profile'} <b>$lang_ext{'options_title'}</b></td>
    </tr><tr>
        <td class="catbg small">$lang_ext{'options_description'}</td>
    </tr><tr>
        <td class="windowbg2">
<table class="windowbg2 pad_6px">
    <tr>
        <td><b>$lang_ext{'active'}:</b> $active</td>
        <td class="center"><b>$lang_ext{'field_name'}:</b> $field{'name'}</td>
        <td class="center"><b>$lang_ext{'field_type'}:</b> $lang_ext{$field{'type'}}</td>
        <td class="right"><a href="$adminurl?action=ext_admin">&lt;-- $lang_ext{'change_these_settings'}</a></td>
    </tr>
</table>
        </td>
    </tr><tr>
        <td class="windowbg2">
            <table class="bordercolor borderstyle border-space pad-cell">
~;
        if ( $field{'type'} eq 'text' ) {
            @options = split /\^/xsm, $field{'options'};
            if   ( $options[2] == 1 ) { $is_numeric = ' checked="checked"' }
            else                      { $is_numeric = q{} }
            if   ( $options[4] == 1 ) { $ubbc = ' checked="checked"' }
            else                      { $ubbc = q{} }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="limit_len">$lang_ext{'limit_len'}</label>~,
qq~<label for="limit_len">$lang_ext{'limit_len_description'}</label>~,
qq~<input name="limit_len" id="limit_len" size="5" value='$options[0]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="width">$lang_ext{'width'}</label>~,
                qq~<label for="width">$lang_ext{'width_description'}</label>~,
qq~<input name="width" id="width" size="5" value='$options[1]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="is_numeric">$lang_ext{'is_numeric'}</label>~,
qq~<label for="is_numeric">$lang_ext{'is_numeric_description'}</label>~,
qq~<input name="is_numeric" id="is_numeric" type="checkbox" value="1"$is_numeric />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="default">$lang_ext{'default'}</label>~,
qq~<label for="default">$lang_ext{'default_description'}</label>~,
qq~<input name="default" id="default" size="50" value='$options[3]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="ubbc">$lang_ext{'ubbc'}</label>~,
                qq~<label for="ubbc">$lang_ext{'ubbc_description'}</label>~,
qq~<input name="ubbc" id="ubbc" type="checkbox" value="1"$ubbc />~
              );
        }
        elsif ( $field{'type'} eq 'text_multi' ) {
            @options = split /\^/xsm, $field{'options'};
            if   ( $options[3] == 1 ) { $ubbc = ' checked="checked"' }
            else                      { $ubbc = q{} }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="limit_len">$lang_ext{'limit_len'}</label>~,
qq~<label for="limit_len">$lang_ext{'limit_len_description'}</label>~,
qq~<input name="limit_len" id="limit_len" size="5" value='$options[0]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="rows">$lang_ext{'rows'}</label>~,
                qq~<label for="rows">$lang_ext{'rows_description'}</label>~,
                qq~<input name="rows" id="rows" size="5" value='$options[1]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="cols">$lang_ext{'cols'}</label>~,
                qq~<label for="cols">$lang_ext{'cols_description'}</label>~,
                qq~<input name="cols" id="cols" size="5" value='$options[2]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="ubbc">$lang_ext{'ubbc'}</label>~,
                qq~<label for="ubbc">$lang_ext{'ubbc_description'}</label>~,
qq~<input name="ubbc" id="ubbc" type="checkbox" value="1"$ubbc />~
              );
        }
        elsif ( $field{'type'} eq 'select' ) {
            @options = split /\^/xsm, $field{'options'};
            $output = q{};
            foreach (@options) { $output .= qq~$_\n~; }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="options">$lang_ext{'s_options'}</label>~,
qq~<label for="options">$lang_ext{'s_options_description'}</label>~,
qq~<textarea name="options" id="options" cols="30" rows="3">$output</textarea>~
            );
        }
        elsif ( $field{'type'} eq 'radiobuttons' ) {
            @options = split /\^/xsm, $field{'options'};
            $output = q{};
            foreach (@options) { $output .= qq~$_\n~; }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="options">$lang_ext{'s_options'}</label>~,
qq~<label for="options">$lang_ext{'s_options_description'}</label>~,
qq~<textarea name="options" id="options" cols="30" rows="3">$output</textarea>~
              )
              . ext_admin_gen_inputfield(
qq~<label for="radiounselect">$lang_ext{'radiounselect'}</label>~,
qq~<label for="radiounselect">$lang_ext{'radiounselect_description'}</label>~,
qq~<input name="radiounselect" id="radiounselect" type="checkbox" value="1"$radiounselect />~
              );
        }
        elsif ( $field{'type'} eq 'spacer' ) {
            @options = split /\^/xsm, $field{'options'};
            if ( $options[0] == 1 ) {
                $check2 = ' checked="checked"';
                $check1 = q{};
            }
            else { $check2 = q{}; $check1 = ' checked="checked"'; }
            if   ( $options[1] == 1 ) { $options[1] = ' checked="checked"'; }
            else                      { $options[1] = q{}; }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="hr_or_br">$lang_ext{'hr_or_br'}</label>~,
qq~<label for="hr_or_br">$lang_ext{'hr_or_br_description'}</label>~,
qq~<input name="hr_or_br" id="hr_or_br" type="radio" value="0"$check1 />$lang_ext{'hr'}\n~
                  . qq~<input name="hr_or_br" type="radio" value="1"$check2 />$lang_ext{'br'}~
              )
              . ext_admin_gen_inputfield(
qq~<label for="visible_in_editprofile">$lang_ext{'visible_in_editprofile'}</label>~,
qq~<label for="visible_in_editprofile">$lang_ext{'visible_in_editprofile_description'}</label>~,
qq~<input name="visible_in_editprofile" id="visible_in_editprofile" type="checkbox" value="1"$options[1] />~
              );

        }
        elsif ( $field{'type'} eq 'image' ) {
            @options = split /\^/xsm, $field{'options'};

    #if ($options[3] == 1) { $ubbc = ' checked="checked"' } else { $ubbc = q{} }
            $yymain .= ext_admin_gen_inputfield(
                qq~<label for="image_width">$lang_ext{'image_width'}</label>~,
qq~<label for="image_width">$lang_ext{'image_width_description'}</label>~,
qq~<input name="image_width" id="image_width" size="5" value='$options[0]' />~
              )
              . ext_admin_gen_inputfield(
                qq~<label for="image_height">$lang_ext{'image_height'}</label>~,
qq~<label for="image_height">$lang_ext{'image_height_description'}</label>~,
qq~<input name="image_height" id="image_height" size="5" value='$options[1]' />~
              )
              . ext_admin_gen_inputfield(
qq~<label for="allowed_extensions">$lang_ext{'allowed_extensions'}</label>~,
qq~<label for="allowed_extensions">$lang_ext{'allowed_extensions_description'}</label>~,
qq~<input name="allowed_extensions" id="allowed_extensions" size="30" value='$options[2]' />~
              );
        }

        $yymain .= ext_admin_gen_inputfield(
            qq~<label for="comment">$lang_ext{'comment'}</label>~,
            qq~<label for="comment">$lang_ext{'comment_description'}</label>~,
qq~<input name="comment" id="comment" size="50" value='$field{'comment'}' />~
          )
          . ext_admin_gen_inputfield(
qq~<label for="required_on_reg">$lang_ext{'required_on_reg'}</label>~,
qq~<label for="required_on_reg">$lang_ext{'required_on_reg_description'}</label>~,
qq~<input name="required_on_reg" type="radio" value="1"$req2 /> $lang_ext{'req1'}<br />\n~
              . qq~<input name="required_on_reg" id="required_on_reg" type="radio" value="0"$req1 /> $lang_ext{'req0'}<br />\n~
              . qq~<input name="required_on_reg" type="radio" value="2"$req3 /> $lang_ext{'req2'}\n~
          )
          . ext_admin_gen_inputfield(
qq~<label for="visible_in_viewprofile">$lang_ext{'visible_in_viewprofile'}</label>~,
qq~<label for="visible_in_viewprofile">$lang_ext{'visible_in_viewprofile_description'}</label>~,
qq~<input name="visible_in_viewprofile" id="visible_in_viewprofile" type="checkbox" value="1"$v_check /><br />\n~
              . qq~<table class="windowbg2 pad-cell">\n~
              . qq~  <tr><td><label for="v_users">$lang_ext{'v_users'}:</label> </td><td><input name="v_users" id="v_users" value="$field{'v_users'}" /></td></tr>\n~
              . qq~  <tr><td class="vtop"><label for="v_groups">$lang_ext{'v_groups'}:</label> </td><td>\n~
              . qq~    <select multiple="multiple" name="v_groups" id="v_groups" size="4">\n~
              . ext_admin_gen_groupslist( $field{'v_groups'} )
              . qq~    </select>\n~
              . qq~  </td></tr>\n~
              . qq~</table>\n~
          )
          . ext_admin_gen_inputfield(
qq~<label for="visible_in_posts">$lang_ext{'visible_in_posts'}</label>~,
qq~<label for="visible_in_posts">$lang_ext{'visible_in_posts_description'}</label>~,
qq~<input name="visible_in_posts" id="visible_in_posts" type="checkbox" value="1"$p_check /><br />\n~
              . qq~<table class="windowbg2 pad-cell">\n~
              . qq~  <tr><td><label for="p_displayfieldname">$lang_ext{'display_fieldname'}:</label> </td><td><input name="p_displayfieldname" id="p_displayfieldname" type="checkbox" value="1"$p_d_check /></td></tr>\n~
              . qq~  <tr><td><label for="p_users">$lang_ext{'p_users'}:</label> </td><td><input name="p_users" id="p_users" value="$field{'p_users'}" /></td></tr>\n~
              . qq~  <tr><td class="vtop"><label for="p_groups">$lang_ext{'p_groups'}:</label> </td><td>\n~
              . qq~    <select multiple="multiple" name="p_groups" id="p_groups" size="4">\n~
              . ext_admin_gen_groupslist( $field{'p_groups'} )
              . qq~    </select>\n~
              . qq~  </td></tr>\n~
              . qq~</table>\n~
          )
          . ext_admin_gen_inputfield(
qq~<label for="visible_in_posts_popup">$lang_ext{'visible_in_posts_popup'}</label>~,
qq~<label for="visible_in_posts_popup">$lang_ext{'visible_in_posts_popup_description'}</label>~,
qq~<input name="visible_in_posts_popup" id="visible_in_posts_popup" type="checkbox" value="1"$pp_check /><br />\n~
              . qq~<table class="windowbg2 pad-cell">\n~
              . qq~  <tr><td><label for="pp_displayfieldname">$lang_ext{'display_fieldname'}:</label> </td><td><input name="pp_displayfieldname" id="pp_displayfieldname" type="checkbox" value="1"$pp_d_check /></td></tr>\n~
              . qq~  <tr><td><label for="pp_users">$lang_ext{'p_users'}:</label> </td><td><input name="pp_users" id="pp_users" value="$field{'pp_users'}" /></td></tr>\n~
              . qq~  <tr><td class="vtop"><label for="pp_groups">$lang_ext{'p_groups'}:</label> </td><td>\n~
              . qq~    <select multiple="multiple" name="pp_groups" id="pp_groups" size="4">\n~
              . ext_admin_gen_groupslist( $field{'pp_groups'} )
              . qq~    </select>\n~
              . qq~  </td></tr>\n~
              . qq~</table>\n~
          )
          . ext_admin_gen_inputfield(
qq~<label for="visible_in_memberlist">$lang_ext{'visible_in_memberlist'}</label>~,
qq~<label for="visible_in_memberlist">$lang_ext{'visible_in_memberlist_description'}</label>~,
qq~<input name="visible_in_memberlist" id="visible_in_memberlist" type="checkbox" value="1"$m_check /><br />\n~
              . qq~<table class="windowbg2 pad-cell">\n~
              . qq~  <tr><td><label for="m_users">$lang_ext{'m_users'}:</label> </td><td><input name="m_users" id="m_users" value="$field{'m_users'}" /></td></tr>\n~
              . qq~  <tr><td class="vtop"><label for="m_groups">$lang_ext{'m_groups'}:</label> </td><td>\n~
              . qq~    <select multiple="multiple" name="m_groups" id="m_groups" size="4">\n~
              . ext_admin_gen_groupslist( $field{'m_groups'} )
              . qq~    </select>\n~
              . qq~  </td></tr>\n~
              . qq~</table>\n~
          );

        if ( $field{'type'} ne 'spacer' ) {
            $yymain .= ext_admin_gen_inputfield(
qq~\n        <label for="editable_by_user">$lang_ext{'editable_by_user'}</label>~,
qq~\n        <label for="editable_by_user">$lang_ext{'editable_by_user_description'}</label>~,
qq~\n                <select name="editable_by_user" id="editable_by_user" size="1">\n~
                  . qq~  <option value="0"$editable_check[0]>$lang_ext{'page_admin'}</option>\n~
                  . qq~  <option value="1"$editable_check[1]>$lang_ext{'page_edit'}</option>\n~
                  . qq~  <option value="2"$editable_check[2]>$lang_ext{'page_contact'}</option>\n~
                  . qq~  <option value="3"$editable_check[3]>$lang_ext{'page_options'}</option>\n~
                  . qq~  <option value="4"$editable_check[4]>$lang_ext{'page_im'}</option>\n~
                  . qq~</select>\n~
            );
        }
        $yymain .= qq~
            </table>
            <input name="id" type="hidden" value="$FORM{'id'}" />
            <input name="name" type="hidden" value="$FORM{'name'}" />
            <input name="type" type="hidden" value="$FORM{'type'}" />
            <input name="active" type="hidden" value="$FORM{'active'}" />
            ~;
        if ( $field{'type'} eq 'spacer' ) {
            $yymain .=
              q~<input name="editable_by_user" type="hidden" value="1" />
            ~;
        }
       $yymain .= qq~
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
             <input type="submit" name="save" value="$lang_ext{'Save'}" />
        </td>
    </tr>
</table>
</div>
</form>
~;
        $yytitle =
          "$lang_ext{'Profiles_Controls'} - $lang_ext{'options_title'}";
        $action_area = 'ext_admin';
        AdminTemplate();

    }
    elsif ( $FORM{'delete'} ne q{} ) {
        $id = 0;
        ext_get_field( $FORM{'id'} );
        @fields          = @ext_prof_fields;
        @ext_prof_fields = ();
        foreach (@fields) {
            if ( $FORM{'id'} != $id ) { push @ext_prof_fields, $_; }
            $id++;
        }

        @order          = @ext_prof_order;
        @ext_prof_order = ();
        foreach (@order) {
            if ( $_ ne $field{'name'} ) { push @ext_prof_order, $_; }
        }

        require Admin::NewSettings;
        SaveSettingsTo('Settings.pm');

        opendir EXT_DIR, "$memberdir";
        @contents = grep { /\.vars$/sm } readdir EXT_DIR;
        closedir EXT_DIR;

        foreach (@contents) {
            fopen( EXT_FILE, "+<$memberdir/$_" )
              || fatal_error( 'cannot_open', "$memberdir/$_" );
            seek EXT_FILE, 0, 0;
            @old_content = <EXT_FILE>;
            $new_content = join q{}, @old_content;
            $new_content =~ s/\n'ext_$FORM{'id'}',"(?:.*?)"\n/\n/igsm;
            seek EXT_FILE, 0, 0;
            truncate EXT_FILE, 0;
            print {EXT_FILE} $new_content or croak "$croak{'print'} EXT_FILE";
            fclose(EXT_FILE);
        }

        $yySetLocation = qq~$adminurl?action=ext_admin~;
        redirectexit();
    }
    else {
        $yySetLocation = qq~$adminurl?action=ext_admin~;
        redirectexit();
    }
    return;
}

# modifies a field as submitted
sub ext_admin_edit2 {
    my ( @fields, @options );
    is_admin_or_gmod();

    ToHTML( $FORM{'name'} );
    ToHTML( $FORM{'comment'} );
    if ( $FORM{'active'}          eq q{} ) { $FORM{'active'}          = 0; }
    if ( $FORM{'required_on_reg'} eq q{} ) { $FORM{'required_on_reg'} = 0; }
    if ( $FORM{'visible_in_viewprofile'} eq q{} ) {
        $FORM{'visible_in_viewprofile'} = 0;
    }
    if ( $FORM{'visible_in_posts'} eq q{} ) { $FORM{'visible_in_posts'} = 0; }
    if ( $FORM{'visible_in_posts_popup'} eq q{} ) {
        $FORM{'visible_in_posts_popup'} = 0;
    }
    if ( $FORM{'p_displayfieldname'} eq q{} ) {
        $FORM{'p_displayfieldname'} = 0;
    }
    if ( $FORM{'pp_displayfieldname'} eq q{} ) {
        $FORM{'pp_displayfieldname'} = 0;
    }
    if ( $FORM{'visible_in_memberlist'} eq q{} ) {
        $FORM{'visible_in_memberlist'} = 0;
    }
    if ( $FORM{'editable_by_user'} eq q{} ) { $FORM{'editable_by_user'} = 0; }
    $FORM{'v_users'}   =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'v_groups'}  =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'p_users'}   =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'p_groups'}  =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'pp_users'}  =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'pp_groups'} =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'m_users'}   =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'m_groups'}  =~ s/^(\s)*(.+?)(\s)*$/$2/xsm;
    $FORM{'v_groups'}  = join q{,}, split /\s*\,\s*/xsm, $FORM{'v_groups'};
    $FORM{'p_groups'}  = join q{,}, split /\s*\,\s*/xsm, $FORM{'p_groups'};
    $FORM{'pp_groups'} = join q{,}, split /\s*\,\s*/xsm, $FORM{'pp_groups'};
    $FORM{'m_groups'}  = join q{,}, split /\s*\,\s*/xsm, $FORM{'m_groups'};

    if ( $FORM{'type'} eq 'text' ) {
        if ( $FORM{'width'} == 0 ) { $FORM{'width'} = q{}; }
        if ( $FORM{'is_numeric'} eq q{} ) { $FORM{'is_numeric'} = 0; }
        if ( $FORM{'ubbc'}       eq q{} ) { $FORM{'ubbc'}       = 0; }
        $FORM{'options'} =
"$FORM{'limit_len'}^$FORM{'width'}^$FORM{'is_numeric'}^$FORM{'default'}^$FORM{'ubbc'}";

    }
    elsif ( $FORM{'type'} eq 'text_multi' ) {
        if ( $FORM{'rows'} == 0 ) { $FORM{'rows'} = q{}; }
        if ( $FORM{'cols'} == 0 ) { $FORM{'cols'} = q{}; }
        if ( $FORM{'ubbc'} eq q{} ) { $FORM{'ubbc'} = 0; }
        $FORM{'options'} =
          "$FORM{'limit_len'}^$FORM{'rows'}^$FORM{'cols'}^$FORM{'ubbc'}";
    }
    elsif ( $FORM{'type'} eq 'select' ) {
        $FORM{'options'} =~ tr/\r//d;
        $FORM{'options'} =~ s/\A[\s\n]+/ \n/xsm;
        $FORM{'options'} =~ s/[\s\n]+\Z//xsm;
        $FORM{'options'} =~ s/\n\s*\n/\n/gxsm;
        @options = split /\n/xsm, $FORM{'options'};
        $FORM{'options'} = q{};
        foreach (@options) { $FORM{'options'} .= q{\^} . $_; }
        $FORM{'options'} =~ s/^\^//xsm;
    }
    elsif ( $FORM{'type'} eq 'radiobuttons' ) {
        $FORM{'options'} =~ tr/\r//d;
        $FORM{'options'} =~ s/\A[\s\n]+//xsm;
        $FORM{'options'} =~ s/[\s\n]+\Z//xsm;
        $FORM{'options'} =~ s/\n\s*\n/\n/gxsm;
        @options = split /\n/xsm, $FORM{'options'};
        $FORM{'options'} = q{};
        foreach (@options) { $FORM{'options'} .= q{\^} . $_; }
        $FORM{'options'} =~ s/^\^//xsm;
        if ( $FORM{'radiounselect'} eq q{} ) { $FORM{'radiounselect'} = 0; }
    }
    elsif ( $FORM{'type'} eq 'spacer' ) {
        if ( $FORM{'visible_in_editprofile'} eq q{} ) {
            $FORM{'visible_in_editprofile'} = 0;
        }
        $FORM{'options'} = "$FORM{'hr_or_br'}^$FORM{'visible_in_editprofile'}";
    }
    elsif ( $FORM{'type'} eq 'image' ) {
        if ( $FORM{'image_width'} == 0 )  { $FORM{'image_width'}  = q{}; }
        if ( $FORM{'image_height'} == 0 ) { $FORM{'image_height'} = q{}; }
        $FORM{'options'} =
"$FORM{'image_width'}^$FORM{'image_height'}^$FORM{'allowed_extensions'}";
    }

    @fields = @ext_prof_fields;
    $fields[ $FORM{'id'} ] =
"$FORM{'name'}|$FORM{'type'}|$FORM{'options'}|$FORM{'active'}|$FORM{'comment'}|$FORM{'required_on_reg'}|$FORM{'visible_in_viewprofile'}|$FORM{'v_users'}|$FORM{'v_groups'}|$FORM{'visible_in_posts'}|$FORM{'p_users'}|$FORM{'p_groups'}|$FORM{'p_displayfieldname'}|$FORM{'visible_in_memberlist'}|$FORM{'m_users'}|$FORM{'m_groups'}|$FORM{'editable_by_user'}|$FORM{'visible_in_posts_popup'}|$FORM{'pp_users'}|$FORM{'pp_groups'}|$FORM{'pp_displayfieldname'}|$FORM{'radiounselect'}";

    @ext_prof_fields = @fields;

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    $yySetLocation = qq~$adminurl?action=ext_admin~;
    redirectexit();
    return;
}

# converts a user's .ext file to Y2 format
sub ext_user_convert {
    my ( $pusername, $old_membersdir, @ext_profile, $id ) = ( shift, shift );
    is_admin_or_gmod();

    if ( -e "$old_membersdir/$pusername.ext" ) {
        if ( -e "$memberdir/$pusername.vars" ) {
            ext_get_profile($pusername);

            fopen( EXT_FILE, "$old_membersdir/$pusername.ext" )
              || admin_fatal_error( 'cannot_open',
                "$old_membersdir/$pusername.ext" );
            @ext_profile = <EXT_FILE>;
            fclose(EXT_FILE);
            chomp @ext_profile;

            $id = 0;
            foreach (@ext_prof_fields) {
                ${ $uid . $pusername }{ 'ext_' . $id } = $ext_profile[$id];
                $id++;
            }
            UserAccount( $pusername, 'update' );

            # don't delete old .ext files anymore, user can do that himself now.
            #unlink "$old_membersdir/$pusername.ext";
        }
    }
    return;
}

# convert a string of usergroup names from the old YaBB format into Y2's new format
sub ext_admin_convert_fixgroupnames {
    my ( $input, $done, $j, @groups, $group, $groupid, %checkdoubles ) =
      ( shift, 0 );

    @groups = split /\s*\,\s*/xsm, $input;
    for my $j ( 0 .. ( @groups - 1 ) ) {

        # if groupname is in old format
        if (   $groups[$j] ne 'Administrator'
            && $groups[$j] ne 'Global Moderator'
            && $groups[$j] ne 'Moderator'
            && $groups[$j] !~ m/^(?:No)?Post{\d+}$/sm )
        {

            # find best matching usergroup
            foreach my $groupid ( sort { $a <=> $b } keys %NoPost ) {
                if ( $groups[$j] eq
                    ( split /\|/xsm, ( split /\|/xsm, $NoPost{$groupid} )[0] )
                    [0] )
                {
                    $groups[$j] = "NoPost{$groupid}";

                    # check for doubles
                    if ( $checkdoubles{ $groups[$j] } == 1 ) {
                        splice @groups, $j, 1;
                        $j--;
                        $done = 1;
                        last;
                    }
                    else {
                        $checkdoubles{ $groups[$j] } = 1;
                    }
                }
            }
            if ( $done == 1 ) { $done = 0; next; }
            foreach my $groupid ( reverse sort { $a <=> $b } keys %Post ) {
                if ( $groups[$j] eq
                    ( split /\|/xsm, ( split /\|/xsm, $Post{$groupid} )[0] )[0]
                  )
                {
                    $groups[$j] = "Post{$groupid}";

                    # check for doubles
                    if ( $checkdoubles{ $groups[$j] } == 1 ) {
                        splice @groups, $j, 1;
                        $done = 1;
                        $j--;
                        last;
                    }
                    else {
                        $checkdoubles{ $groups[$j] } = 1;
                    }
                }
            }
            if ( $done == 1 ) { $done = 0; next; }
        }
        else {
            $checkdoubles{ $groups[$j] } = 1;
        }

        # if still not matching, get rid of it!
        if (   $groups[$j] ne 'Administrator'
            && $groups[$j] ne 'Global Moderator'
            && $groups[$j] ne 'Moderator'
            && $groups[$j] !~ m/^(?:No)?Post{\d+}$/sm )
        {

            #delete $groups[$j];
            splice @groups, $j, 1;
            $j--;
        }
    }
    join q{,}, @groups;
    return;
}

# converts ALL old .ext files into the the YaBB 2 file format
sub ext_admin_convert {
    my ( @contents, $filename, $old_membersdir, $old_vardir, $i );
    is_admin_or_gmod();

    $old_membersdir = $FORM{'members'};
    $old_vardir     = $FORM{'vars'};

    if ( !-e $old_vardir ) {
        admin_fatal_error( 'extended_profiles_convert',
            $lang_ext{'converter_missing_vars'} );
    }
    if ( !-e "$old_vardir/extended_profiles_order.txt" ) {
        admin_fatal_error( 'extended_profiles_convert',
            $lang_ext{'converter_missing_order'} );
    }
    if ( !-e "$old_vardir/extended_profiles_fields.txt" ) {
        admin_fatal_error( 'extended_profiles_convert',
            $lang_ext{'converter_missing_fields'} );
    }

    fopen( CONVERTER, "$old_vardir/extended_profiles_order.txt" )
      || admin_fatal_error( 'cannot_open',
        "$old_vardir/extended_profiles_order.txt" );
    @ext_prof_order = <CONVERTER>;
    fclose(CONVERTER);
    chomp @ext_prof_order;

    # copy old extended_profiles_fields and extended_profiles_order files
    fopen( CONVERTER, "$old_vardir/extended_profiles_fields.txt" )
      || admin_fatal_error( 'cannot_open',
        "$old_vardir/extended_profiles_fields.txt" );
    @ext_prof_fields = <CONVERTER>;
    fclose(CONVERTER);
    chomp @ext_prof_fields;

    #check if used membergroups still exist + convert to YaBB new format
    for my $i ( 0 .. ( @ext_prof_fields - 1 ) ) {
        my @field = split /\|/xsm, $ext_prof_fields[$i];
        $field[8]  = ext_admin_convert_fixgroupnames( $field[8] );
        $field[11] = ext_admin_convert_fixgroupnames( $field[11] );
        $field[15] = ext_admin_convert_fixgroupnames( $field[15] );
        $field[19] = ext_admin_convert_fixgroupnames( $field[19] );
        $ext_prof_fields[$i] = join q{|}, @field;
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    opendir EXT_DIR, "$old_membersdir";
    @contents = grep { /\.ext$/xsm } readdir EXT_DIR;
    closedir EXT_DIR;

    foreach my $filename (@contents) {
        $filename =~ s/.ext$//xsm;
        ext_user_convert( $filename, $old_membersdir );
    }

    $yymain .= $lang_ext{'converter_succeeded'};
    CreateExtLock();
    $yytitle = "$lang_ext{'Profiles_Controls'} - $lang_ext{'options_title'}";
    $action_area = 'ext_admin';
    AdminTemplate();
    return;
}

sub ext_viewprofile_r {
    my (
        $pusername, @ext_profile,   $id,    $output,
        $fieldname, @options,       $value, $previous,
        $count,     $last_field_id, $pre_output
    ) = (shift);

    if ( $#ext_prof_order > 0 ) {
        $last_field_id = ext_get_field_id( $ext_prof_order[-1] );
    }

    foreach my $fieldname (@ext_prof_order) {
        $id = ext_get_field_id($fieldname);
        ext_get_field($id);
        $value = ext_get( $pusername, $fieldname );
        if ( $field{'required_on_reg'} == 1 ) {

            if ( $output eq q{} && $previous != 1 ) {
                $pre_output = q~<tr>
        <td class="windowbg2 vtop" colspan="2">~;
                $previous = 1;
            }

            # format the output dependent on the field type
            if (   ( $field{'type'} eq 'text' && $value ne q{} )
                || ( $field{'type'} eq 'text_multi'   && $value ne q{} )
                || ( $field{'type'} eq 'select'       && $value ne q{ } )
                || ( $field{'type'} eq 'radiobuttons' && $value ne q{} )
                || ( $field{'type'} eq 'date'         && $value ne q{} )
                || $field{'type'} eq 'checkbox' )
            {
                $output .= qq~<tr>
            <td class="windowbg2 vtop"><b>$field{'name'}:</b></td>
            <td class="windowbg2 vtop">$value&nbsp;</td>
        </tr>~;
                $previous = 0;
            }
            elsif ( $field{'type'} eq 'spacer' ) {

# only print spacer if the previous entry was no spacer of the same type and if this is not the last entry
                if ( ( $previous == 0 || $field{'comment'} ne q{} )
                    && $id ne $last_field_id )
                {
                    if ( $value eq $ext_spacer_br ) {
                        $output .= qq~<tr>
            <td class="windowbg2 vtop" colspan="2">$ext_spacer_br</td>
    </tr>~;
                        $previous = 0;
                    }
                    else {
                        $output .= q~
        </td>
    </tr><tr>~;
                        if ( $field{'comment'} ne q{} ) {
                            $output .= qq~
        <td class="catbg" colspan="2">
            $admin_img{'profile'}&nbsp;
            <span class="text1"><b>$field{'comment'}</b></span>
        </td>
    </tr><tr>
        <td class="windowbg2 vtop" colspan="2">~;
                        }
                        else {
                            $output .= q~
        <td class="windowbg2 vtop" colspan="2">~;
                        }
                        $previous = 1;
                    }
                }
            }
            elsif ( $field{'type'} eq 'email' && $value ne q{} ) {
                $output .= qq~<tr>
                <td class="windowbg2 vtop"><b>$field{'name'}:</b></td>
                <td class="windowbg2 vtop">
            ~ . enc_eMail( $img_txt{'69'}, $value, q{}, q{} ) . q~
            </td>
        </tr>~;
                $previous = 0;
            }
            elsif ( $field{'type'} eq 'url' && $value ne q{} ) {
                $output .= qq~<tr>
            <td class="windowbg2 vtop"><b>$field{'name'}:</b></td>
            <td class="windowbg2 vtop"><a href="$value" target="_blank">$value</a></td>
        </tr>~;
                $previous = 0;

            }
            elsif ( $field{'type'} eq 'image' && $value ne q{} ) {
                $output .= qq~<tr>
            <td class="windowbg2 vtop"><b>$field{'name'}:</b></td>
            <td class="windowbg2 vtop">$value</td>
        </tr>~;
                $previous = 0;
            }
        }
    }

    # only add spacer if there there is at least one field displayed
    if ( $output ne q{} ) {
        $output = $pre_output . $output . q~
        </td>
    </tr>~;
    }
    return $output;
}

sub CreateExtLock {
    fopen( LOCKFILE, ">$vardir/Extended.lock" )
      || setup_fatal_error( "$maintext_23 $vardir/Extended.lock: ", 1 );
    print {LOCKFILE} qq~This is a lockfile for the Extended Profiles.\n~
      or croak 'cannot print to LOCKFILE';
    print {LOCKFILE}
      qq~It prevents it being run again after it has been run once.\n~
      or croak 'cannot print to LOCKFILE';
    print {LOCKFILE} q~Delete this file if you want to run the Converter again.~
      or croak 'cannot print to LOCKFILE';
    fclose(LOCKFILE);

    return;
}
sub FoundExtLock {
    $found = qq~
    <div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;"">
        <tr>
            <td class="titlebg"><img src="$imagesdir/profile.gif" alt="" /> <b>$lang_ext{'convlock'}</b></td>
        </tr><tr>
            <td class="windowbg2 center" style="font-size: 11px;">$lang_ext{'convlock_desc'}</td>
        </tr>
    </table>
    </div>
      ~;
    return $found;
}
1;

# file formats used by this code:
#
#  username.vars - contains the additional user profile information. Number is field-id
#  -------------
#  ...
#  'ext_0',"value"
#  'ext_1',"value"
#  'ext_2',"value"
#  ...
#
#  @ext_prof_order - contains the order in which the fields will be displayed
#  ---------------------------
#  ("name","name","name",....)
#
#  extended_profiles_fields.txt - defines the new profile fields. Uses line number as field-id
#  ----------------------------
#  ("name|type|options|active|comment|required_on_reg|visible_in_viewprofile|v_users|v_groups|visible_in_posts|p_users|p_groups|p_displayfieldname|visible_in_memberlist|m_users|m_groups|editable_by_user|visible_in_posts_popup|pp_users|pp_groups|pp_displayfieldname","name|type|options|active|comment|required_on_reg|visible_in_viewprofile|v_users|v_groups|visible_in_posts|p_users|p_groups|p_displayfieldname|visible_in_memberlist|m_users|m_groups|editable_by_user|visible_in_posts_popup|pp_users|pp_groups|pp_displayfieldname","name|type|options|active|comment|required_on_reg|visible_in_viewprofile|v_users|v_groups|visible_in_posts|p_users|p_groups|p_displayfieldname|visible_in_memberlist|m_users|m_groups|editable_by_user|visible_in_posts_popup|pp_users|pp_groups|pp_displayfieldname",....)
#
#  Here are all types with their possible type-specific options. If options contain multiple entries, separated by ^
#  - text       limit_len^width^is_numberic^default_value^allow_ubbc
#  - text_multi     limit_len^rows^cols^allow_ubbc
#  - select     option1^option2^option3... (first option is default)
#  - radiobuttons   option1^option2^option3... (first option is default)
#  - spacer     br_or_hr^visible_in_editprofile
#  - checkbox       -
#  - date       -
#  - emial      -
#  - url        -
#  - image      width^height^allowed_extensions
#
#  required_on_reg can have value 0 (disabled), 1 (required on registration) and 2 (not req. but display on reg. page anyway)
#  editable_by_user can have value 0 (will only show on the "admin edits" page), 1 ("edit profile" page), 2 ("contact information" page), 3 ("Options" page) and 4 ("PM Preferences" page)
#  allowed_extensions is a space-seperated list of file extensions, example: "jpg jpeg gif bmp png"
#  v_groups, p_groups, m_groups, pp_groups format: "Administrator" or "Moderator" or "Global Moderator" or NoPost{...} or Post{...}
#
# NOTE: use prefix "ext_" in sub-, variable- and formnames to prevent conflicts with other mods
#
# easy mod integration: use &ext_get($username,"fieldname") go get user's field value
#
###############################################################################
