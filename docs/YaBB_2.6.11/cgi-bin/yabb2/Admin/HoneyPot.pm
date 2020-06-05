###############################################################################
# HoneyPot.pm                                                                 #
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

$honeypotpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

my $honey_language = $FORM{'honey_language'} || $INFO{'honey_language'} || $lang;

sub honeypot {

    is_admin_or_gmod();

    opendir LNGDIR, $langdir;
    my @lfilesanddirs = readdir LNGDIR;
    closedir LNGDIR;

    foreach my $fld (sort {lc($a) cmp lc $b} @lfilesanddirs) {
        if (-e "$langdir/$fld/Main.lng") {
            my $displang = $fld;
            $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
            if ($honey_language eq $fld) { $drawnldirs .= qq~<option value="$fld" selected="selected">$displang</option>~; }
            else { $drawnldirs .= qq~<option value="$fld">$displang</option>~; }
        }
    }

    if (-e "$langdir/$honey_language/honey.txt") {
        fopen(HONEYPOT, "<$langdir/$honey_language/honey.txt") || fatal_error('cannot_open',"$langdir/$honey_language/honey.txt", 1);
    @honey_label = <HONEYPOT>;
    fclose(HONEYPOT);
    }

    $total_labels = @honey_label || 0;

    if ($total_labels) {
        $show_hon_labels =
          qq~<tr class="catbg">
                    <td><b>$honeypot{'label'}</b></td>
                    <td><b>$honeypot{'edits'}</b></td>
                    <td><b>$honeypot{'deletes'}</b></td>
                </tr>~;

        foreach my $hon_labels ( sort { $a <=> $b } @honey_label ) {
            chomp $hon_labels;
            $show_hon_labels .= qq~<tr class="windowbg2">
                    <td>$hon_labels</td>
                    <td>
                        <form action="$adminurl?action=honeypot_edit" method="post">
                            <input type="hidden" name="hon_label" value="$hon_labels" />
                            <input class="button" type="submit" value="$admin_txt{'edit'}" />
                            <input type="hidden" name="honey_language" value="$honey_language" />
                        </form>
                    </td>
                    <td>
                        <form action="$adminurl?action=honeypot_delete" method="post">
                            <input type="hidden" name="hon_label" value="$hon_labels" />
                            <input class="button" type="submit" value="$admin_txt{'delete'}" onclick="return confirm('$honeypot{'confirm'}');"/>
                            <input type="hidden" name="honey_language" value="$honey_language" />
                        </form>
                    </td>
                </tr>~;
        }
    }
    else {
        $show_hon_labels = qq~<tr class="windowbg2">
                    <td colspan="3">$honeypot{'no_label'}</td>
                </tr>~;
    }

    $yymain = qq~<div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <colgroup>
                    <col style="width: 50%" />
                    <col span="2" style="width: 25%" />
                </colgroup>
                <tr>
                    <th class="titlebg" colspan="3">$admin_img{'prefimg'} $honeypot{'labels'} ($total_labels)
                        <div style="display: inline; float: right;">
                            <form action="$adminurl?action=honeypot" method="post" enctype="application/x-www-form-urlencoded">
                                <select name="honey_language" id="honey_language" size="1">
                                $drawnldirs
                                </select>
                                <input type="submit" value="$admin_txt{'462'}" class="button" />
                            </form>
                        </div>
                    </th>
                </tr>
                $show_hon_labels
            </table>
        </div>
        <form action="$adminurl?action=honeypot_add" method="post" accept-charset="$yymycharset">
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell" style="margin-bottom: .5em;">
                    <colgroup>
                        <col style="width: 25%" />
                        <col style="width: 75%" />
                    </colgroup>
                    <tr>
                        <th class="titlebg" colspan="2">$admin_img{'prefimg'} $honeypot{'add_new_label'}</th>
                    </tr><tr class="windowbg2 vtop bold">
                        <td><label for="honey_add">$honeypot{'new_label'}:</label></td>
                        <td><input type="text" name="honey_add" id="honey_add" size="60" maxlength="50" /></td>
                    </tr>
                </table>
            </div>
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell" style="margin-bottom: .5em;">
                    <tr>
                        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
                    </tr><tr>
                        <td class="catbg center">
                            <input class="button" type="submit" value="$honeypot{'add_label'}" />
                            <input type="hidden" name="honey_language" value="$honey_language" />
                        </td>
                    </tr>
                </table>
            </div>
        </form>~;

    $yytitle     = $honeypot{'labels'};
    $action_area = 'honeypot';
    AdminTemplate();
    exit;
}

sub honeypot_add {
    is_admin_or_gmod();

    $h_label = $FORM{'honey_add'};

    if ( $h_label eq q{} ) {
        fatal_error( 'invalid_value', "$honeypot{'label'}" );
    }

    fopen( HONEYPOT, ">>$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    print {HONEYPOT} "$h_label\n"
      or croak "$croak{'print'} HONEYPOT";
    fclose(HONEYPOT);

    if ( $action eq 'honeypot_add' ) {
        $yySetLocation = qq~$adminurl?action=honeypot;honey_language=$FORM{'honey_language'}~;
        redirectexit();
    }
    return;
}

sub honeypot_edit {
    is_admin_or_gmod();

    $h_label = $FORM{'hon_label'};

    fopen( HONEYPOT, "<$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    @h_labels = <HONEYPOT>;
    fclose(HONEYPOT);
    my $aa = 0;
    foreach my $id (@h_labels) {
        chomp $id;
        if ( $id eq $h_label ) {
            last;
        }
        $aa++;
    }


    $yymain = qq~
    <form action="$adminurl?action=honeypot_edit2" method="post" accept-charset="$yymycharset">
        <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell" style="margin-bottom: .5em;">
                <colgroup>
                    <col style="width: 25%" />
                    <col style="width: 75%" />
                </colgroup>
                <tr>
                    <th class="titlebg" colspan="2">$admin_img{'prefimg'} $honeypot{'edits'}</th>
                </tr><tr class="windowbg2 vtop bold;">
                    <td><label for="hon_label">$honeypot{'label'}:</label></td>
                    <td><input type="text" name="hon_label2" id="hon_label2" size="60" maxlength="50" value="$h_label" /><input type="hidden" name="hon_line" value="$aa" /></td>
                </tr>
            </table>
        </div>
        <div class="bordercolor rightboxdiv">
            <table class="border-space pad-cell">
                <tr>
                    <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
                </tr><tr>
                    <td class="catbg center">
                        <input class="button" type="submit" value="$admin_txt{'10'} $honeypot{'save'}" />&nbsp;<input type="button" class="button" value="$admin_txt{'cancel'}" onclick="location.href='$adminurl?action=honeypot;honey_language=$FORM{'honey_language'}';" />
                        <input type="hidden" name="honey_language" value="$honey_language" />
                    </td>
                </tr>
            </table>
        </div>
    </form>~;

    $yytitle = $honeypot{'labels'};
    AdminTemplate();
    exit;
}

sub honeypot_edit2 {
    is_admin_or_gmod();

    $h_label    = $FORM{'hon_label2'};
    $line = $FORM{'hon_line'};

    if ( $h_label eq q{} ) {
        fatal_error( 'invalid_value', "$honeypot{'label'}" );
    }

    fopen( HONEYPOT, "<$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    @h_labels = <HONEYPOT>;
    fclose(HONEYPOT);

    fopen( HONEYPOT, ">$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    $aa = 0;
    foreach my $i ( @h_labels) {
        chomp $i;
        if($aa == $line) {
            print {HONEYPOT} "$h_label\n" or croak "$croak{'print'} HONEYPOT";
        }
        else {    print {HONEYPOT} "$i\n" or croak "$croak{'print'} HONEYPOT"; }
        $aa++;
    }

    fclose(HONEYPOT);

    $yySetLocation = qq~$adminurl?action=honeypot;honey_language=$FORM{'honey_language'}~;
    redirectexit();
    return;
}

sub honeypot_delete {

    is_admin_or_gmod();
    $h_label = $FORM{'hon_label'};

    fopen( HONEYPOT, "<$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    @h_labels = <HONEYPOT>;
    fclose(HONEYPOT);

    fopen( HONEYPOT, ">$langdir/$honey_language/honey.txt" )
      || fatal_error( 'cannot_open', "$langdir/$honey_language/honey.txt",
        1 );
    foreach my $i ( @h_labels) {
        chomp $i;
        if( $h_label eq $i) {
            print {HONEYPOT} q{} or croak "$croak{'print'} HONEYPOT";
        }
        else {    print {HONEYPOT} "$i\n" or croak "$croak{'print'} HONEYPOT"; }
    }
    fclose(HONEYPOT);

    $yySetLocation = qq~$adminurl?action=honeypot;honey_language=$FORM{'honey_language'}~;
    redirectexit();
    return;
}

1;
