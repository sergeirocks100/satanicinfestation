###############################################################################
# Checkspace.pm                                                               #
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
use English '-no_match_vars';
our $VERSION = '2.6.11';

$checkspacepmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub checkspace {
    is_admin_or_gmod();

    # Free Disk Space Checking
    if ( $OSNAME =~ /Win/sm ) {
        open my $fh, q{-|}, 'DIR /-C' or croak "Can't open pipe: $!";
        my @x = <$fh>;
        close $fh or croak "Can't close pipe: $!";
        my $lastline = pop @x;

        # should look like: 17 Directory(s), 21305790464 Bytes free
        return -1
          if $lastline !~ m/byte/ism;

        # error trapping if output fails. The word byte should be in the line
        if ( $lastline =~ /^\s+(\d+)\s+(.+?)\s+(\d+)\s+(.+?)\n$/xsm ) {
            $FreeBytes = $3 - 100_000;
        }    # 100000 bytes reserve
        if ( $FreeBytes >= 1_073_741_824 ) {
            $yyfreespace =
              sprintf( '%.2f', $FreeBytes / ( 1024 * 1024 * 1024 ) ) . ' GB';
        }
        elsif ( $FreeBytes >= 1_048_576 ) {
            $yyfreespace =
              sprintf( '%.2f', $FreeBytes / ( 1024 * 1024 ) ) . ' MB';
        }
        else {
            $yyfreespace = sprintf( '%.2f', $FreeBytes / 1024 ) . ' KB';
        }
        @disk_space = $yyfreespace;
    }
    else {
        open my $dsh, q{-|}, 'df -k .' or croak "Can't open pipe: $!";
        @disk_space = <$dsh>;
        close $dsh or croak "Can't close pipe: $!";

        map { $_ =~ s/ +/  /gsm } @disk_space;

        open my $ffh, q{-|}, 'find . -noleaf -type f -printf "%s-"'
          or croak "Can't open pipe: $!";
        my @find = <$ffh>;
        close $ffh or croak "Can't close pipe: $!";
    }
    $hostusername = $hostusername
      || ( split / +/sm, qx{ls -l YaBB.$yyext} )[2];
    my @quota = qx{quota -u $hostusername -v};
    $quota[0] =~ s/^ +//sm;
    $quota[0] =~ s/ /&nbsp;/gsm;
    $quota[1] =~ s/^ +//sm;
    $quota[1] =~ s/ /&nbsp;/gsm;
    my $quota_select = qq~$quota[0]<br />$quota[1]~;

    if ( $quota[2] ) {
        if ( !$enable_quota ) { $ds = ( split / +/sm, $disk_space[1], 2 )[0]; }
        $my_q_select =
          isselected( $i == $enable_quota
              || ( $ds && $quota[$i] =~ /^$ds/sm ) );
        $quota_select .= q~<br /><select name="enable_quota_value" id="enable_quota_value">~;
        for my $i ( 2 .. ( @quota - 1 ) ) {
            $quota[$i] =~ s/^ +//sm;
            $quota[$i] =~ s/ +/&nbsp;&nbsp;/gsm;
            $quota_select .=
              qq~<option value="$i" ~ . $my_q_select . qq~>$quota[$i]</option>~;
        }
        $quota_select .= '</select>';
    }

    #    }

    $ch_spc      = ischecked($enable_freespace_check);
    $ch_enable_q = ischecked($enable_quota);

    @settings = (
        {
            name  => $settings_txt{'checkspace'},
            id    => 'checkspace',
            items => [
                { header => $settings_txt{'freedisk'}, },
                {
                    description =>
                      qq~<label for="enable_quota">$admin_txt{'quota'}</label>~,
                    input_html =>
q~<input type="checkbox" name="enable_quota" id="enable_quota" value="1" ~
                      . (
                         !$quota[2] ? 'disabled="disabled" '
                        : $ch_enable_q
                      )
                      . q~/>~,
                    name       => 'enable_quota',
                    validate   => 'boolean',
                    depends_on => (
                        !$quota[2] ? []
                        : [
                            '!enable_freespace_check',
                            '(findfile_time==0||',
                            'findfile_time==||',
                            'findfile_maxsize==0||',
                            'findfile_maxsize==)'
                        ]
                    ),
                },
                {
                    description =>
qq~<label for="enable_quota_value">$admin_txt{'quota_value'}</label>~,
                    input_html => (
                        $quota[2] ? $quota_select
                        : q~<input type="text" disabled="disabled" name="enable_quota_value" id="enable_quota_value" value="" style="display:none" />~
                    ),
                    name       => 'enable_quota_value',
                    validate   => 'number,null',
                    depends_on => ['enable_quota'],
                },
                {
                    description =>
qq~<label for="hostusername">$admin_txt{'quotahostuser'}</label>~,
                    input_html =>
qq~<input type="text" name="hostusername" id="hostusername" size="20" value="$hostusername" />~,
                    name       => 'hostusername',
                    validate   => 'text,null',
                    depends_on => ['enable_quota'],
                },
                {
                    description =>
qq~<label for="findfile_time">$admin_txt{'findtime'}</label>~,
                    input_html =>
q~<input type="text" name="findfile_time" id="findfile_time" size="4" value="~
                      . (
                        @find ? qq~$findfile_time"~ : '0" disabled="disabled"'
                      )
                      . qq~ /> $admin_txt{'537'}~,
                    name       => 'findfile_time',
                    validate   => 'number,null',
                    depends_on => (
                        @find ? [ '!enable_quota', '!enable_freespace_check' ]
                        : []
                    ),
                },
                {
                    description =>
qq~<label for="findfile_root">$admin_txt{'findroot'}</label>~,
                    input_html =>
qq~<input type="text" name="findfile_root" id="findfile_root" size="40" value="$findfile_root" ~
                      . ( @find ? q{} : 'disabled="disabled" ' ) . q~/>~,
                    name       => 'findfile_root',
                    validate   => 'text,null',
                    depends_on => (
                        @find ? [ '!enable_quota', '!enable_freespace_check' ]
                        : []
                    ),
                },
                {
                    description =>
qq~<label for="findfile_maxsize">$admin_txt{'findmax'}</label>~,
                    input_html =>
qq~<input type="text" name="findfile_maxsize" id="findfile_maxsize" size="10" value="$findfile_maxsize" ~
                      . ( @find ? q{} : 'disabled="disabled" ' )
                      . q~/> MB~,
                    name       => 'findfile_maxsize',
                    validate   => 'number,null',
                    depends_on => (
                        @find ? [ '!enable_quota', '!enable_freespace_check' ]
                        : []
                    ),
                },
                {
                    description =>
qq~<label for="enable_freespace_check">$admin_txt{'diskspacecheck'}</label>~,
                    input_html =>
qq~<input type="checkbox" name="enable_freespace_check" id="enable_freespace_check" value="1" $ch_spc /><pre>@disk_space</pre>~,
                    name       => 'enable_freespace_check',
                    validate   => 'boolean',
                    depends_on => [
                        '!enable_quota',     '(findfile_time==0||',
                        'findfile_time==||', 'findfile_maxsize==0||',
                        'findfile_maxsize==)'
                    ],
                },
            ],
        },
    );
    chsettings();
    $action_area = 'checkspace';
    AdminTemplate();
    exit;
}

sub chsettings {
    is_admin_or_gmod();

    $yytitle = $admin_txt{'checkspclabel'};
    $page    = 'checkspace';

    my @requireorder;    # an array for the correct order of the requirements
    my %requirements;    # a hash that says "Y is required by X"

    $yymain .= qq~
    <div class="bordercolor rightboxdiv">
        <table class="border-space pad-cell" style="margin-bottom:.5em">
            <tr>
                <td class="titlebg"><b>$yytitle</b></td>
            </tr><tr>
                <td class="windowbg2"><div class="pad-more">$admin_txt{'347'}</div></td>
            </tr>
        </table>
  </div>
  <form action="$adminurl?action=checkspace_save" method="post" onsubmit="savealert()" accept-charset="$yymycharset">
~;
    foreach my $tab (@settings) {
        $yymain .= qq~
    <div class="bordercolor rightboxdiv">
        <table class="section border-space pad-cell" style="margin-bottom:.5em" id="tab_$tab->{'id'}">
            <colgroup>
                <col span="2" style="width:50%" />
            </colgroup>
            <tr>
                <td class="titlebg" colspan="2">
                    $admin_img{'prefimg'} <b>$tab->{'name'}</b>
                </td>
           </tr>~;

        foreach my $item ( @{ $tab->{'items'} } ) {
            if ( $item->{'header'} ) {
                $yymain .= qq~<tr>
                <td class="catbg" colspan="2">
                    <span class="small">$item->{'header'}</span>
                </td>
            </tr>~;
            }
            elsif ( $item->{'two_rows'} && $item->{'input_html'} ) {
                $yymain .= qq~<tr>
                <td class="windowbg2" colspan="2">
         $item->{'description'}
       </td>
            </tr><tr>
                <td class="windowbg2" colspan="2">
         $item->{'input_html'}
       </td>
     </tr>~;
            }
            elsif ( $item->{'input_html'} ) {
                $yymain .= qq~<tr>
                <td class="windowbg2 vtop">
         $item->{'description'}
       </td>
                <td class="windowbg2 vtop">
         $item->{'input_html'}
       </td>
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
            $dependicies .= qq~     checkDependent("$require");\n~;
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
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <td class="titlebg" colspan="2">
                $admin_img{'prefimg'} <b>$admin_txt{'10'}</b>
       </td>
        </tr><tr>
            <td class="catbg center pad-cell" colspan="2">
         <input class="button" type="submit" value="$admin_txt{'10'}" />
       </td>
     </tr>
   </table>
  </div>
  </form>
  <script type="text/javascript">
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

    return;
}

sub ischecked {
    my ($inp) = @_;

    # Return a ref so we can be used like ${ischecked($var)} inside a string
    if ( $inp == 1 ) { return 'checked="checked"'; }
    return;
}

sub isselected {
    my ($inp) = @_;

    # Return a ref so we can be used like ${ischecked($var)} inside a string
    if ( $inp == 1 ) { return 'selected="selected"'; }
    return;
}

sub checkspace_save {
    is_admin_or_gmod();

    $enable_quota           = $FORM{'enable_quota'}           || '0';
    $enable_quota_value     = $FORM{'enable_quota_value'}     || '0';
    $hostusername           = $FORM{'hostusername'}           || q{};
    $findfile_time          = $FORM{'findfile_time'}          || 0;
    $findfile_root          = $FORM{'findfile_root'}          || q{};
    $findfile_maxsize       = $FORM{'findfile_maxsize'}       || 0;
    $findfile_space         = $FORM{'findfile_space'}         || '1<>0';
    $enable_freespace_check = $FORM{'enable_freespace_check'} || 0;

    if ( $enable_quota && $enable_quota_value > 1 && $hostusername ) {
        $enable_quota           = $enable_quota_value;
        $findfile_maxsize       = 0;
        $enable_freespace_check = 0;
    }
    elsif (-d "$findfile_root"
        && $findfile_maxsize > 0
        && !$enable_freespace_check )
    {
        $findfile_space = '1<>0';
        $enable_quota   = 0;
    }
    elsif ($enable_freespace_check) {
        $findfile_maxsize = 0;
        $enable_quota     = 0;
    }
    elsif ( !-d "$findfile_root" || !$findfile_maxsize ) {
        $findfile_time    = 0;
        $findfile_maxsize = 0;
    }

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    if ( $action eq 'checkspace_save' ) {
        $yySetLocation = qq~$adminurl?action=newsettings;page=advanced~;
        redirectexit();
    }
    return;
}

1;
