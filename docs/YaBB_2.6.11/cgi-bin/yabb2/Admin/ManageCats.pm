###############################################################################
# ManageCats.pm                                                               #
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

$managecatspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

sub DoCats {
    is_admin_or_gmod();
    my $i = 0;
    while ( $_ = each %FORM ) {
        if ( $FORM{$_} && /^yitem_(.+)$/xsm ) {
            $editcats[$i] = $1;
            $i++;
        }
    }

    if ( $FORM{'baction'} eq 'edit' ) { AddCats(@editcats); }
    elsif ( $FORM{'baction'} eq 'delme' ) {
        get_forum_master();
        foreach my $catid (@editcats) {
            ##Check if category has any boards, and if it does remove them.
            if ( $cat{$catid} ne q{} ) {
                require Admin::ManageBoards;
                DeleteBoards( split /,/xsm, $cat{$catid} );
            }

            delete $cat{"$catid"};
            delete $catinfo{"$catid"};

            my $x = 0;
            foreach my $categoryid (@categoryorder) {
                if ( $catid eq $categoryid ) {
                    splice @categoryorder, $x, 1;
                    last;
                }
                $x++;
            }

            $yymain .=
              qq~$admin_txt{'830'} <i>$catid</i> $admin_txt{'831'}<br />~;
        }
        Write_ForumMaster();
    }
    $yytitle     = "$admin_txt{'3'}";
    $action_area = 'managecats';
    AdminTemplate();
    return;
}

sub AddCats {
    my @editcats = @_;
    is_admin_or_gmod();

    if ( $INFO{'action'} eq 'catscreen' ) { $FORM{'amount'} = @editcats; }
    get_forum_master();

    $yymain .= qq~
<form action="$adminurl?action=addcat2" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg">
                $admin_img{'cat_img'}
                <b>$admin_txt{'3'}</b>
            </td>
        </tr><tr>
            <td class="windowbg2">
                <div class="pad-more">$admin_txt{'43'}</div>
            </td>
        </tr>
    </table>
</div>
~;
    require Admin::ManageBoards;

    # Start Looping through and repeating the board adding wherever needed
    for my $i ( 0 .. ( $FORM{'amount'} - 1 ) ) {
        if (   ( !$editcats[$i] && $INFO{'action'} eq 'catscreen' )
            || ( $editcats[$i] eq q{} && $INFO{'action'} eq 'catscreen' ) )
        {
            next;
        }
        if ( $INFO{'action'} eq 'catscreen' ) {
            $id = $editcats[$i];
            foreach my $catid (@categoryorder) {
                if ( $id ne $catid ) { next; }
                @bdlist = split /,/xsm, $cat{$catid};
                ( $curcatname, $catperms, $catallowcol, $catimage, $catrss ) =
                  split /\|/xsm, $catinfo{"$catid"};
                ToChars($curcatname);
                $cattext = $curcatname;
                if ( $catallowcol eq q{} || $catallowcol eq '1' ) {
                    $allowChecked = 'checked="checked"';
                }
                else { $allowChecked = q{}; }
                ### RSS on Board Index Start ###
                if ( $catrss == 1 ) { $catrssch = ' checked="checked"'; }
                else { $catrssch = q{}; }
                ### RSS on Board Index End ###
            }
        }
        else {
            my $cat_num = $i + 1;
            $cattext = "$admin_txt{'44'} $cat_num:";
        }
        my $catimage_value = q{};
        if ( $catimage ) {
            $catimage_value = qq~<div class="small bold">$admin_txt{'current_img'}: <a href="$yyhtml_root/Templates/Forum/default/$catimage" target="_blank">$catimage</a><br /><input type="checkbox" name="del_catimage$i" id="del_catimage$i" value="1" /> <label for="del_catimage$i">$admin_txt{'64b5'}</label></div>~;
        }
        $catperms = DrawPerms( $catperms, 0 );
       $yymain .= qq~
<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell" style="margin-bottom: .5em;">
        <tr>
            <td class="titlebg" colspan="4"><b>$cattext</b></td>
        </tr><tr>
            <td class="windowbg" colspan="2">&nbsp;</td>
            <td class="windowbg center"><label for="catperms$i"><b>$admin_txt{'45'}</b></label></td>
            <td class="windowbg center"><label for="allowcol$i"><b>$exptxt{'6'}</b></label></td>
        </tr><tr>~;
        if ( $INFO{'action'} eq 'catscreen' ) {
            $yymain .= qq~
            <td class="windowbg"><b>$admin_txt{'61a'}</b></td>
            <td class="windowbg2">
                <div class="pad-more"><input type="hidden" name="theid$i" id="theid$i" value="$id" />$id~;
        }
        else {
            $yymain .= qq~
            <td class="windowbg"><label for="theid$i"><b>$admin_txt{'61a'}</b><br />$admin_txt{'61b'}</label></td>
            <td class="windowbg2">
                <div class="pad-more"><input type="text" name="theid$i" id="theid$i" value="$id" />~;
        }
        $yymain .= qq~
                </div>
            </td>
            <td class="windowbg2 center" rowspan="4"><select multiple="multiple" name="catperms$i" id="catperms$i" size="5">$catperms</select><br /><label for="catperms$i"><span class="small">$admin_txt{'14'}</span></label></td>
            <td class="windowbg2 center" rowspan="4"><input type="checkbox" $allowChecked name="allowcol$i" id="allowcol$i" /></td>
        </tr><tr>
            <td class="windowbg"><label for="name$i"><b>$admin_txt{'68'}:</b></label></td>
            <td class="windowbg2">
                <div class="pad-more"><input type="text" name="name$i" id="name$i" value="$curcatname" size="40" /></div>
            </td>
        </tr><tr>
            <td class="windowbg"><label for="catimage$i"><b>$admin_txt{'64b2'}:</b><br /><span class="small">$admin_txt{'64b3'}</span></label></td>
            <td class="windowbg2">
                <div class="pad-more">
                    <input type="file" name="catimage$i" id="catimage$i" size="35" />
                    <input type="hidden" name="cur_catimage$i" value="$catimage" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('catimage$i').value='';">X</span>~ . ($catimage ? qq~<br /><img src="$imagesdir/$catimage" alt="" />~ : q{}) . qq~$catimage_value
                </div>
            </td>
        </tr><tr>
            <td class="windowbg"><label for="catrss$i"><b>$admin_txt{'brdrss1'}:</b></label></td>
            <td class="windowbg2">
                <div class="pad-more"><input type="checkbox" name="catrss$i" id="catrss$i"$catrssch /> <label for="catrss$i"><span class="small">$admin_txt{'brdrss2'}</span></label></div>
            </td>
        </tr>
    </table>
</div>~;
    }
    $yymain .= qq~<div class="bordercolor rightboxdiv">
    <table class="border-space pad-cell">
        <tr>
            <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
        </tr><tr>
            <td class="catbg center">
                <input type="hidden" name="amount" value="$FORM{"amount"}" />
                <input type="hidden" name="screenornot" value="$INFO{'action'}" />
                <input type="submit" value="$admin_txt{'10'}" class="button" />
            </td>
        </tr>
    </table>
</div>
</form>~;

    $yytitle     = "$admin_txt{'3'}";
    $action_area = 'managecats';
    AdminTemplate();
    return;
}

sub AddCats2 {
    is_admin_or_gmod();
    get_forum_master();

    for my $i ( 0 .. ( $FORM{'amount'} - 1 ) ) {
        if ( $FORM{"catimage$i"} ne q{} ) {
            $FORM{"catimage$i"} = UploadFile("catimage$i", 'Templates/Forum/default', 'png jpg jpeg gif', '250', '0');
            if ( $FORM{"cur_catimage$i"} ne q{} ) {
                unlink "$htmldir/Templates/Forum/default/$FORM{\"cur_catimage$i\"}";
            }
        }
        else {
            $FORM{"catimage$i"} = $FORM{"cur_catimage$i"};
        }

        if ( $FORM{"cur_catimage$i"} ne q{} && $FORM{"del_catimage$i"} ) {
            unlink "$htmldir/Templates/Forum/default/$FORM{\"cur_catimage$i\"}";
            $FORM{"catimage$i"} = q{};
        }
        if ( $FORM{"theid$i"} eq q{} ) { next; }
        $id = $FORM{"theid$i"};
        if ( $id !~ /^[0-9A-Za-z#%+-\.@^_]+$/xsm ) {
            fatal_error( 'invalid_character',
                "$admin_txt{'44'} $admin_txt{'241'}" );
        }
        if ( $FORM{'screenornot'} ne 'catscreen' ) {
            if   ( $catinfo{"$id"} ) { fatal_error('cat_defined'); }
            else                     { $cat{"$id"} = q{}; }
            push @categoryorder, $id;
        }
        if ( !$FORM{"name$i"} ) { $FORM{"name$i"} = $id; }

        $cname = $FORM{"name$i"};
        FromChars($cname);
        ToHTML($cname);

        if   ( $FORM{"allowcol$i"} eq 'on' ) { $FORM{"allowcol$i"} = 1; }
        else                                 { $FORM{"allowcol$i"} = 0; }

        if ( $FORM{"catrss$i"} eq 'on' ) { $FORM{"catrss$i"} = 1; }
        else { $FORM{"catrss$i"} = 0; }

        $catinfo{"$id"} = qq~$cname|$FORM{"catperms$i"}|$FORM{"allowcol$i"}|$FORM{"catimage$i"}|$FORM{"catrss$i"}~;

        $yymain .= qq~$admin_txt{'830'} <i>$id</i> $admin_txt{'48'}<br />~;
    }
    Write_ForumMaster();

    $action_area = 'managecats';
    AdminTemplate();
    return;
}

sub ReorderCats {
    is_admin_or_gmod();
    get_forum_master();
    if ( @categoryorder > 1 ) {
        $catcnt = @categoryorder;
        $catnum = $catcnt;
        if ( $catcnt < 4 ) { $catcnt = 4; }
        $categorylist =
qq~<select name="selectcats" id="selectcats" size="$catcnt" style="width: 190px;">~;
        foreach my $category (@categoryorder) {
            chomp $category;
            ( $categoryname, undef ) = split /\|/xsm, $catinfo{$category}, 2;
            ToChars($categoryname);
            if ( $category eq $INFO{'thecat'} ) {
                $categorylist .=
qq~<option value="$category" selected="selected">$categoryname</option>~;
            }
            else {
                $categorylist .=
                  qq~<option value="$category">$categoryname</option>~;
            }
        }
        $categorylist .= q~</select>~;
    }
    $yymain .= qq~
<br /><br />
<form action="$adminurl?action=reordercats2" method="post" accept-charset="$yymycharset">
    <table class="bordercolor border-space pad-cell" style="width:525px">
        <tr>
            <td class="titlebg">$admin_img{'board'} <b>$admin_txt{'829'}</b></td>
        </tr><tr>
            <td class="windowbg">~;

    if ( $catnum > 1 ) {
        $yymain .= qq~
                <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small"><label for="selectcats">$admin_txt{'738'}</label></div>
                <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">$categorylist</div>
                <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small">$admin_txt{'738a'}</div>
                <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
                    <input type="submit" value="$admin_txt{'739a'}" name="moveup" style="font-size: 11px; width: 95px;" class="button" />
                    <input type="submit" value="$admin_txt{'739b'}" name="movedown" style="font-size: 11px; width: 95px;" class="button" />
                </div>~;
    }
    else {
        $yymain .= qq~
                <div class="small" style="text-align: center; margin-bottom: 4px;">$admin_txt{'738b'}</div>~;
    }
    $yymain .= q~
            </td>
        </tr>
    </table>
</form>
~;
    $yytitle     = "$admin_txt{'829'}";
    $action_area = 'managecats';
    AdminTemplate();
    return;
}

sub ReorderCats2 {
    is_admin_or_gmod();
    my $moveitem = $FORM{'selectcats'};
    get_forum_master();
    if ($moveitem) {
        if ( $FORM{'moveup'} ) {
            for my $i ( 0 .. ( @categoryorder - 1 ) ) {
                if ( $categoryorder[$i] eq $moveitem && $i > 0 ) {
                    $j                 = $i - 1;
                    $categoryorder[$i] = $categoryorder[$j];
                    $categoryorder[$j] = $moveitem;
                    last;
                }
            }
        }
        elsif ( $FORM{'movedown'} ) {
            for my $i ( 0 .. ( @categoryorder - 1 ) ) {
                if ( $categoryorder[$i] eq $moveitem && $i < $#categoryorder ) {
                    $j                 = $i + 1;
                    $categoryorder[$i] = $categoryorder[$j];
                    $categoryorder[$j] = $moveitem;
                    last;
                }
            }
        }
        Write_ForumMaster();
    }
    $yySetLocation = qq~$adminurl?action=reordercats;thecat=$moveitem~;
    redirectexit();
    return;
}

1;
