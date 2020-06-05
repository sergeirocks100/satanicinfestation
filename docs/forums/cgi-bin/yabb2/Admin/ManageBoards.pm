###############################################################################
# ManageBoards.pm                                                             #
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

$manageboardspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }
$admin_images = "$yyhtml_root/Templates/Admin/default";

sub ManageBoards {
    is_admin_or_gmod();
    LoadBoardControl();
    get_forum_master();
    if ( $INFO{'action'} eq 'managecats' ) {
        $colspan = q~colspan="2"~;
        $add     = $admin_txt{'47'};
        $act     = 'catscreen';
        $manage =
qq~<a href="$adminurl?action=reordercats"><img src="$admin_img{'reorder'}" alt="$admin_txt{'829'}" title="$admin_txt{'829'}" /></a> &nbsp;<b>$admin_txt{'49'}</b>~;
        $managedescr = $admin_txt{'678'};
        $act2        = 'addcat';
        $action_area = 'managecats';
    }
    else {
        $colspan = q~colspan="4"~;
        $add     = $admin_txt{'50'};
        $act     = 'boardscreen';
        $manage =
qq~$admin_img{'cat_img'} &nbsp;<b>$admin_txt{'51'}</b>~;
        $managedescr = $admin_txt{'677'};
        $act2        = 'addboard';
        $action_area = 'manageboards';
    }
    $yymain .= qq~<script type="text/javascript">
        function checkSubmit(where){
            var something_checked = false;
            for (i=0; i<where.elements.length; i++){
                if(where.elements[i].type == "checkbox"){
                    if(where.elements[i].checked === true){
                        something_checked = true;
                    }
                }
            }
            if(something_checked === true){
                if (where.baction[1].checked === false){
                    return true;
                }
                if (confirm("$admin_txt{'617'}")) {
                    return true;
                } else {
                    return false;
                }
            } else {
                alert("$admin_txt{'5'}");
                return false;
            }
        }

        function editSingle(board) {
            var where = document.getElementById("whattodo");
            for (i=0; i<where.elements.length; i++){
                if(where.elements[i].type == "checkbox"){
                    if(where.elements[i].getAttribute("name") == board){
                        where.elements[i].checked = true;
                    } else {
                        where.elements[i].checked = false;
                    }
                }
            }
            document.getElementById("baction").checked = true;
            where.submit();
        }

        function delSingle(board) {
            var where = document.getElementById("whattodo");
            for (i=0; i<where.elements.length; i++){
                if(where.elements[i].type == "checkbox"){
                    if(where.elements[i].getAttribute("name") == board){
                        where.elements[i].checked = true;
                    } else {
                        where.elements[i].checked = false;
                    }
                }
            }
            document.getElementById("delme").checked = true;
            if (confirm("$admin_txt{'617'}")) {
                where.submit();
            }
        }
        </script>
        <form name="whattodo" id="whattodo" action="$adminurl?action=$act" onsubmit="return checkSubmit(this);" method="post" enctype="multipart/form-data">
            <div class="rightboxdiv">
                <table class="bordercolor border-space pad-cell" style="margin-bottom: .5em;">
                    <tr>
                        <td class="titlebg" $colspan>$manage</td>
                    </tr><tr>
                        <td class="windowbg2" $colspan>
                            <div class="pad-more">$managedescr</div>
                        </td>
                    </tr>
                </table>~;
    for my $catid (@categoryorder) {
        @bdlist = split /,/xsm, $cat{$catid};
        ( $curcatname, $catperms, undef, $catpic ) = split /\|/xsm, $catinfo{$catid};
        ToChars($curcatname);
        $temppic = q{};
        if ( $INFO{'action'} eq 'managecats' ) {
            $tempcolspan   = q{};
            $tempclass     = 'windowbg2';
            $temphrefclass = q{};
        }
        else {
            $tempcolspan   = q~colspan="4"~;
            $tempclass     = 'catbg';
            if ( $catpic ) {
                $temppic = qq~<div style="float:right; margin-right: 10%"><img src="$yyhtml_root/Templates/Forum/default/$catpic" id="brd_img_resize" alt="$catid" /></div>~;
            }
            $temphrefclass = q~class="catbg a"~;
        }

        $yymain .= qq~
                <table class="bordercolor borderstyle border-space pad-cell" style="margin-bottom: .5em;">
                    <tr>
                        <td class="$tempclass" style="height:25px" $tempcolspan>
                            <a href="$adminurl?action=reorderboards;item=$catid" $temphrefclass><img src="$admin_img{'reorder'}" alt="$admin_txt{'832'}" title="$admin_txt{'832'}" /></a> &nbsp;<b>$curcatname</b>$temppic</td>~;
        if ( $INFO{'action'} eq 'managecats' ) {
            $yymain .= qq~
                        <td class="windowbg center" style="height:25px; width: 10%"><input type="checkbox" name="yitem_$catid" value="1" /></td>~;
        }

        $yymain .= q~
                    </tr>
                </table>~;
        if ( $INFO{'action'} ne 'managecats' ) {
            my $indent = -3;

            # recursive loop to display all sub boards

            *show_boards = sub {
                my @brdlist = @_;
                $indent += 3;
                for my $curboard (@brdlist) {
                    ( $boardname, $boardperms, $boardview ) =
                      split /\|/xsm, $board{$curboard};
                    $boardname =~ s/\&quot\;/&#34;/gxsm;
                    ToChars($boardname);
                    $descr = ${ $uid . $curboard }{'description'};
                    $descr =~ s/\<br \/>/\n/gsm;
                    my $bicon = q{};
                    fopen( BRDPIC, "<$boardsdir/brdpics.db" );
                    my @brdpics = <BRDPIC>;
                    fclose( BRDPIC);
                    chomp @brdpics;
                    for (@brdpics) {
                        my ( $brdnm, $style, $brdpic ) = split /[|]/xsm, $_;
                        if ( $brdnm eq $curboard && $style eq $usestyle ) {
                            if ( $brdpic =~ /\//ixsm ) {
                                $bicon = qq~ <img src="$brdpic" id="brd_img_resize" alt="" /> ~;
                            }
                            else {
                                $bicon = qq~<img src="$yyhtml_root/Templates/Forum/$style/Boards/$brdpic" id="brd_img_resize" alt="$boardname" />~;
                            }
                        }
                    }
                    if ( ${ $uid . $curboard }{'ann'} == 1 ) {
                        $bicon =
qq~ <img src="$imagesdir/ann.png" alt="$admin_txt{'64g'}" title="$admin_txt{'64g'}" />~;
                    }
                    if ( ${ $uid . $curboard }{'rbin'} == 1 ) {
                        $bicon =
qq~ <img src="$imagesdir/recycle.png" alt="$admin_txt{'64i'}" title="$admin_txt{'64i'}" />~;
                    }
                    $convertstr = $descr;
                    if ( $convertstr !~ /<.+?>/xsm )
                    {    # Don't cut it if there's HTML in it.
                        $convertcut = 60;
                        CountChars();
                    }
                    my $descr = $convertstr;
                    ToChars($descr);
                    if ($cliped) { $descr .= q{...}; }

                    my $tmpwidth  = 100 - $indent;
                    my $tmpwidth2 = 90 - $indent;

                    my @children = split /\|/xsm, $subboard{$curboard};

                    $reorder_subs =
                      @children > 0
                      ? qq~                                <a href="$adminurl?action=reorderboards;item=$curboard;subboards=1"><img src="$admin_images/reorder_sub.png" alt="$admin_txt{'252'}" title="$admin_txt{'252'}" /></a>~
                      : q{};

                    my $del_txt  = $admin_txt{'251'};
                    my $edit_txt = $admin_txt{'253'};
                    if ( ${ $uid . $curboard }{'parent'} ) {
                        $del_txt  =~ s/{(.*?)}/$admin_txt{'254'}$1/gxsm;
                        $edit_txt =~ s/{(.*?)}/$admin_txt{'254'}$1/gxsm;
                    }
                    else {
                        $del_txt  =~ s/{(.*?)}/$1/gxsm;
                        $edit_txt =~ s/{(.*?)}/$1/gxsm;
                    }

                    $yymain .= q~
                <table class="bordercolor borderstyle border-space pad-cell" style="margin-bottom: .5em; margin-left:~
                      . $indent . q~%; width:~ . $tmpwidth . q~%">
                    <colgroup>
                        <col style="width:~ . $tmpwidth2 . qq~%" />
                        <col span="2" style="width: 5%" />
                    </colgroup>
                    <tr>
                        <td class="windowbg2">
                            <b>$boardname</b>
                            <div style="position:relative; display:inline; float:right;">
                                <a href="$adminurl?action=addboard;parent=$curboard;category=$catid"><img src="$admin_images/add_sub.png" alt="$admin_txt{'250'}" title="$admin_txt{'250'}" /></a>
                                <a href="javascript:editSingle('yitem_$curboard')"><img src="$admin_images/edit_sub.png" alt="$edit_txt" title="$edit_txt" /></a>
                                <a href="javascript:delSingle('yitem_$curboard')"><img src="$admin_images/delete_sub.png" alt="$del_txt" title="$del_txt" /></a>
~ . $reorder_subs . qq~
                            </div>
                        </td>
                        <td class="windowbg2 center">$bicon</td>
                        <td class="titlebg center"><input type="checkbox" name="yitem_$curboard" value="1" /></td>
                    </tr><tr>
                        <td class="windowbg" colspan="3">$descr</td>
                    </tr>
                </table>~;
                    if ( $subboard{$curboard} ) { show_boards(@children); }
                }
                $indent -= 3;
            };
            show_boards(@bdlist);
        }
    }

    $yymain .= qq~
                <table class="bordercolor borderstyle border-space pad-cell" style="margin-bottom: .5em;">
                    <tr>
                        <td class="catbg center" $colspan> <label for="baction">$admin_txt{'52'}</label>
                            <input type="radio" name="baction" id="baction" value="edit" checked="checked" /> $admin_txt{'53'}
                            <input type="radio" name="baction" id="delme" value="delme" /> $admin_txt{'54'}
                            <input type="submit" value="$admin_txt{'32'}" class="button" />
                        </td>
                    </tr>
                </table>
            </div>
        </form>
        <form name="diff" id="diff" action="$adminurl?action=$act2" method="post" accept-charset="$yymycharset">
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell">
                    <tr>
                        <th class="titlebg">$admin_img{'cat_img'} $add</th>
                    </tr><tr>
                        <td class="catbg center">
                            <label for="amount"><b>$add: </b></label>
                            <input type="text" name="amount" id="amount" value="3" size="2" maxlength="2" />
                            <input type="submit" value="$admintxt{'45'}" class="button" />
                        </td>
                    </tr>
                </table>
            </div>
        </form>~;
    $yytitle = "$admintxt{'a4_title'}";
    AdminTemplate();
    return;
}

sub BoardScreen {
    is_admin_or_gmod();
    get_forum_master();
    $i = 0;
    while ( $_ = each %FORM ) {
        if ( $FORM{$_} && $_ =~ /^yitem_(.+)$/xsm ) {
            $editboards[$i] = $1;
            $i++;
        }
    }
    $i = 1;
    for my $thiscat (@categoryorder) {
        my @catboards = split /,/xsm, $cat{$thiscat};

        # make an array of all sub boards recursively
        *recursive_boards = sub {
            my @x = @_;
            push @theboards, @x;
            for my $childbd (@x) {
                if ( $subboard{$childbd} ) {
                    recursive_boards( split /\|/xsm, $subboard{$childbd} );
                }
            }
        };
        recursive_boards(@catboards);

        for my $z ( 0 .. ( @theboards - 1 ) ) {
            my $found = 0;
            for my $j ( 0 .. ( @editboards - 1 ) ) {
                if ( $editboards[$j] eq $theboards[$z] ) {
                    $editbrd[$i] = $theboards[$z];
                    $found = 1;
                    $i++;
                    splice @editboards, $j, 1;
                    last;
                }
            }
        }
    }
    if ( $FORM{'baction'} eq 'edit' ) { AddBoards(@editbrd); }
    elsif ( $FORM{'baction'} eq 'delme' ) {
        shift @editbrd;
        get_forum_master();
        for my $bd (@editbrd) {

# Remove Board form category it belongs to unless it's a sub board, then it's not in the cat list
            if ( !${ $uid . $bd }{'parent'} ) {
                $category = ${ $uid . $bd }{'cat'};
                @bdlist = split /,/xsm, $cat{$category};
                my $c = 0;
                for (@bdlist) {
                    if ( $_ eq $bd ) { splice @bdlist, $c, 1; last; }
                    $c++;
                }
                $cat{$category} = join q{,}, undupe(@bdlist);
            }
            else
            { # if it has a parent, remove it from its parent's child board list
                my @bdlist =
                  split /\|/xsm, $subboard{ ${ $uid . $bd }{'parent'} };

                # Remove Board from old parent board
                my $k = 0;
                for (@bdlist) {
                    if ( $bd eq $_ ) { splice @bdlist, $k, 1; }
                    $k++;
                }
                $subboard{ ${ $uid . $bd }{'parent'} } = join q{|}, @bdlist;
            }

# remove the $subboard{} hash that contains children list, since it's a parent board and move children up
            if ( $subboard{$bd} ) {
                for my $childbd ( split /\|/xsm, $subboard{$bd} ) {

# if this one has a parent board, move its children up to that, otherwise to category.
                    if ( ${ $uid . $bd }{'parent'} ) {
                        if ( $subboard{ ${ $uid . $bd }{'parent'} } ) {
                            $subboard{ ${ $uid . $bd }{'parent'} } .=
                              qq~|$childbd~;
                        }
                        else {
                            $subboard{ ${ $uid . $bd }{'parent'} } = $childbd;
                        }
                        ${ $uid . $childbd }{'parent'} =
                          ${ $uid . $bd }{'parent'};
                    }
                    else {
                        $cat{ ${ $uid . $bd }{'cat'} } .= ",$childbd";
                        ${ $uid . $childbd }{'parent'} = q{};
                    }
                    push @del_updateparent, $childbd;
                }
                delete $subboard{$bd};
            }
            delete $board{$bd};
            $yymain .= qq~$admin_txt{'55'}$bd <br />~;
        }

        # Actual deleting
        DeleteBoards(@editbrd);
        Write_ForumMaster();
    }
    else {
        fatal_error( 'no_action', "$FORM{'baction'}" );
    }

    $action_area = 'manageboards';
    AdminTemplate();
    return;
}

sub DeleteBoards {
    my @x = @_;
    is_admin_or_gmod();

    fopen( FORUMCONTROL, "+<$boardsdir/forum.control" )
      || fatal_error( 'cannot_open', "$boardsdir/forum.control", 1 );
    seek FORUMCONTROL, 0, 0;
    my @oldcontrols = <FORUMCONTROL>;
    for my $board (@x) {
        fopen( BOARDDATA, "$boardsdir/$board.txt" );
        @messages = <BOARDDATA>;
        fclose(BOARDDATA);
        for my $curmessage (@messages) {
            my ( $id, undef ) = split /\|/xsm, $curmessage, 2;
            unlink "$datadir/$id\.txt";
            unlink "$datadir/$id\.mail";
            unlink "$datadir/$id\.ctb";
            unlink "$datadir/$id\.data";
            unlink "$datadir/$id\.poll";
            unlink "$datadir/$id\.polled";
        }
        for my $cnt ( 0 .. ( @oldcontrols - 1 ) ) {
            my $oldboard;
            ( undef, $oldboard, undef ) = split /\|/xsm, $oldcontrols[$cnt], 3;
            $yydebug .= "$cnt   $oldboard \n";
            if ( $oldboard eq $board ) {
                $oldcontrols[$cnt] = q{};
                $yydebug .= qq~\$board{\"$oldboard\"}~;
                delete $board{"$board"};
                last;
            }
        }
        unlink "$boardsdir/$board.txt";
        unlink "$boardsdir/$board.ttl";
        unlink "$boardsdir/$board.poster";
        unlink "$boardsdir/$board.mail";

        fopen( ATM, "+<$vardir/attachments.txt", 1 );
        seek ATM, 0, 0;
        my @buffer = <ATM>;
        my ( $amcurrentboard, $amfn );
        for my $aa ( 0 .. ( @buffer - 1 ) ) {
            (
                undef, undef,           undef,
                undef, $amcurrentboard, undef,
                undef, $amfn,           undef
            ) = split /\|/xsm, $buffer[$aa];
            if ( $amcurrentboard eq $board ) {
                $buffer[$aa] = q{};
                unlink "$upload_dir/$amfn";
            }
        }
        truncate ATM, 0;
        seek ATM, 0, 0;
        print {ATM} @buffer or croak "$croak{'print'} ATM";
        fclose(ATM);

        BoardTotals( 'delete', $board );
    }

    # Update parents for subboards that had a parent deleted.
    if (@del_updateparent) {
        for my $cnt ( 0 .. ( @oldcontrols - 1 ) ) {
            @newbrd = split /\|/xsm, $oldcontrols[$cnt];
            for my $changedboard (@del_updateparent) {
                if ( $changedboard eq $oldboard ) {
                    $newbrd[18] = ${$uid.$changedboard}{'parent'};
                    $newbrd = join q{|}, @newbrd;
                    $oldcontrols[$cnt] = $newbrd . "\n";
                    last;
                }
            }
        }
    }
    my @boardcontrol = grep { $_; } @oldcontrols;

    truncate FORUMCONTROL, 0;
    seek FORUMCONTROL, 0, 0;
    print {FORUMCONTROL} sort @boardcontrol
      or croak "$croak{'print'} FORUMCONTROL";
    fclose(FORUMCONTROL);

    fopen( FORUMCONTROL, "$boardsdir/forum.control" );
    @forum_control = <FORUMCONTROL>;
    fclose(FORUMCONTROL);
    return;
}

sub AddBoards {
    my @editboards = @_;
    is_admin_or_gmod();
    $addtext = $admin_txt{'50'};
    if ( $INFO{'action'} eq 'boardscreen' ) {
        $FORM{'amount'} = $#editboards;
        $addtext = $admin_txt{'50a'};
    }
    if ( $INFO{'parent'} ) {
        $FORM{'amount'} = 1;
    }
    get_forum_master();
    LoadBoardControl();

# build recursive drop down of boards in each category for selecting parent board
    *get_subboards = sub {
        my @x = @_;
        $indent += 2;
        for my $childbd (@x) {
            my $dash;
            if ( $indent > 0 ) { $dash = q{-}; }
            ( $chldboardname, undef, undef ) =
              split /\|/xsm, $board{"$childbd"};
            ToChars($chldboardname);
            $catboardlist{$thiscat} .=
                qq~$childbd|~
              . ( q{ } x $indent )
              . ( $dash x ( $indent / 2 ) )
              . qq~ $chldboardname|~;
            if ( $subboard{$childbd} ) {
                get_subboards( split /\|/xsm, $subboard{$childbd} );
            }
        }
        $indent -= 2;
    };
    for $thiscat (@categoryorder) {
        # $thiscat cannot be properly localized
        my @catboards = split /\,/xsm, $cat{$thiscat};
        my $indent = -2;
        $catboardlist{$thiscat} = q~||~;

        get_subboards(@catboards);

        $catboardlist_js .= qq~
            catboardlist['$thiscat'] = "$catboardlist{$thiscat}";
        ~;
    }

    $yymain .= qq~<script type="text/javascript">
    var copyValues = new Array();
    var copyList = new Array();

    var catboardlist = new Array();
    $catboardlist_js

// this function removes an entry from the IM multi-list
function removeUser(oElement) {
    var oList = oElement.options;
    var noneSelected = 1;

    for (var i = 0; i < oList.length; i++) {
        if(oList[i].selected) noneSelected = 0;
    }
    if(noneSelected) return false;

    var indexToRemove = oList.selectedIndex;
    if (confirm("$selector_txt{'remove'}"))
        {oElement.remove(indexToRemove);}
}
// this function forces all users listed in moderators to be selected for processing
function selectNames(total) {
    for(var x = 1; x <= total; x++) {
    var oList = document.getElementById('moderators'+x);
    for (var i = 0; i < oList.options.length; i++)
        {oList.options[i].selected = true;}
    }
}
// allows copying one or multiple items from moderators list
function copyNames(num) {
    copyList = new Array();
    copyValues = new Array();
    var oList = document.getElementById('moderators'+num).options;
    for (var i = 0; i < oList.length; i++) {
        if(oList[i].selected === true) {
            copyList[copyList.length] = oList[i].text;
            copyValues[copyValues.length] = oList[i].value;
        }
    }
}
// allows pasting from previously copied moderator list items
function pasteNames(num,total) {
    var found = false;
    var oList = null;
    var which = 0;
    if(copyList.length !== 0) {
        for(var x = 0; x < total; x++) {
            which = num + x;
            oList = document.getElementById('moderators'+which).options;
            for (var e = 0; e < copyList.length; e++) {
                found = false;
                for (var i = 0; i < oList.length; i++) {
                    if(oList[i].value == copyValues[e] || oList[i].text == copyList[e]) {
                        found = true;
                        break;
                    }
                }
                if(found === false) {
                    if(navigator.appName=="Microsoft Internet Explorer") {
                        document.getElementById('moderators'+which).add(new Option(copyList[e],copyValues[e]));
                    } else {
                        document.getElementById('moderators'+which).add(new Option(copyList[e],copyValues[e]),null);
                    }
                }
            }
        }
    }
}
// updates parent drop down list when new category is selected
function updateParent(cat, board, id) {
    var parentsel = document.getElementById("parent" + id);
    var insertbds = catboardlist[cat].split("|");

    clearSelect(parentsel);
    for (var j = 1; j < insertbds.length; j += 2) {
        var op;
        if(navigator.appName=="Microsoft Internet Explorer") {
            op = new Option(insertbds[j],insertbds[j-1]);
        } else {
            op = new Option(insertbds[j],insertbds[j-1],null);
        }
        if(insertbds[j-1] == board) {
            op.style.backgroundColor = "#ffbbbb";
        }
        op.value = insertbds[j-1];
        parentsel.add(op);
    }
}
// changes the parent board dropdown to whatever it should be, otherwise default is the first category's set of boards
function selectParentBoard() {
    for (var i = 1; i <= editbrds.length - 1; i++) {
        var parentsel = document.getElementById("parent" + i);

        var bdinfo = editbrds[i].split("|");
        var insertbds;

        if(bdinfo[0]) {
            insertbds = catboardlist[bdinfo[0]].split("|");
        } else {
            insertbds = catboardlist[document.getElementById("cat" + i).value].split("|");
        }

        clearSelect(parentsel);
        for (var j = 1; j < insertbds.length; j += 2) {
            var op = new Option(insertbds[j],insertbds[j-1]);
            if(insertbds[j-1] == bdinfo[1]) {
                op.style.backgroundColor = "#ffbbbb";
            }
            if(insertbds[j-1] == bdinfo[2]) {
                op.selected = true;
            }
            op.value = insertbds[j-1];
            if(navigator.appName=="Microsoft Internet Explorer") {
                parentsel.add(op);
            } else {
                parentsel.add(op,null);
            }
        }
    }
}
// clear a select box
function clearSelect(sel) {
    for (var i = sel.options.length - 1; i >= 0 ; i--) {
        sel.options[i] = null;
    }
}
// make sure we don't select a board and decide to move it to itself....
function checkParent(id, board) {
    var parent = document.getElementById("parent" + id).value;
    if(parent == board) {
        alert("$admin_txt{'735'}");
    }
}
        </script>
        <form name="boardsadd" id="boardsadd" action="$adminurl?action=addboard2" method="post" enctype="multipart/form-data" onsubmit="selectNames($FORM{'amount'});" accept-charset="$yymycharset">
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell" style="margin-bottom: .5em;">
                    <tr>
                        <td class="titlebg">$admin_img{'cat_img'} <b>$addtext</b></td>
                    </tr><tr>
                        <td class="windowbg2">
                            <div class="pad-more">$admin_txt{'57'}</div>
                        </td>
                    </tr>
                </table>
            </div>
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell" style="margin-bottom:.5em">
                    <colgroup>
                        <col span="4" style="width:25%" />
                    </colgroup>
~;

    # Check if and which board are set for announcements or recycle bin
    # Start Looping through and repeating the board adding wherever needed
    $istart    = 0;
    $annexist  = q{};
    $rbinexist = q{};

    for my $i ( 1 .. $FORM{'amount'} ) {

        # differentiate between edit or add boards
        if ( $editboards[$i] eq q{} && $INFO{'action'} eq 'boardscreen' ) {
            next;
        }
        if ( $INFO{'action'} eq 'boardscreen' ) {
            $id = $editboards[$i];
        }
        else {
            $boardtext = "$admin_txt{'58'} $i:";
        }

        # print javascript hash of board names and their equivalent category
        if ( !$INFO{'parent'} ) {
            $brd_javascript .=
qq~editbrds[$i] = "${$uid.$editboards[$i]}{'cat'}|$editboards[$i]|${$uid.$editboards[$i]}{'parent'}";\n~;
        }
        else {
            $brd_javascript .=
              qq~editbrds[$i] = "$INFO{'category'}||$INFO{'parent'}";\n~;
        }

        my $boardcat = ${ $uid . $editboards[$i] }{'cat'};
        for my $catid (@categoryorder) {
            @bdlist = split /,/xsm, $cat{$catid};
            ( $curcatname, $catperms ) = split /\|/xsm, $catinfo{"$catid"};
            if ( $INFO{'action'} eq 'boardscreen' || $INFO{'parent'} ) {
                if ( $catid eq $boardcat || $catid eq $INFO{'category'} ) {
                    $selected = q~ selected="selected"~;
                }
                else { $selected = q{}; }
            }
            ToChars($curcatname);
            $catsel{$i} .=
              qq~<option value="$catid"$selected>$curcatname</option>~;
        }
        $catsel .= q~</select>~;
        if ( $istart == 0 ) { $istart = $i; }

        ( $boardname, $boardperms, $boardview ) = split /\|/xsm, $board{"$id"};
        ToChars($boardname);
        if ( $INFO{'action'} eq 'boardscreen' ) { $boardtext = $boardname; }
        $boardpic    = ${ $uid . $editboards[$i] }{'pic'};
        $description = ${ $uid . $editboards[$i] }{'description'};
        $description =~ s/<br \/>/\n/gsm;
        ToChars($description);
        $moderators      = ${ $uid . $editboards[$i] }{'mods'};
        $moderatorgroups = ${ $uid . $editboards[$i] }{'modgroups'};
        $boardminage     = ${ $uid . $editboards[$i] }{'minageperms'};
        $boardmaxage     = ${ $uid . $editboards[$i] }{'maxageperms'};
        $boardgender     = ${ $uid . $editboards[$i] }{'genderperms'};
        $genselect       = qq~<select name="gender$i" id="gender$i">~;
        $gentag[0]       = q{};
        $gentag[1]       = 'M';
        $gentag[2]       = 'F';
        $gentag[3]       = 'B';
        for my $genlabel (@gentag) {
            $gentext = '99';
            $gentext .= $genlabel;
            if ( $genlabel eq $boardgender ) {
                $genselect .=
qq~<option value="$genlabel" selected="selected">$admin_txt{$gentext}</option>~;
            }
            else {
                $genselect .=
                  qq~<option value="$genlabel">$admin_txt{$gentext}</option>~;
            }
        }
        $genselect .= q~</select>~;
        my $canpostch;
        if ( ${ $uid . $id }{'canpost'} == 1
            || $INFO{'action'} ne 'boardscreen' )
        {
            $canpostch = q~ checked="checked"~;
        }

        # Make children list if it contains sub boards
        my $childrenlist;
        if ( $subboard{$id} ) {
            for my $childbd ( split /\|/xsm, $subboard{$id} ) {
                my ( $chldboardname, undef, undef ) =
                  split /\|/xsm, $board{"$childbd"};
                ToChars($chldboardname);
                $childrenlist .= qq~$chldboardname, ~;
            }
            $childrenlist =~ s/, $//gsm;
        }

        if ( $childrenlist eq q{} ) { $childrenlist = $admin_txt{'246'}; }

        # Retrieve Optional Details
        $ann      = q{};
        $rbin     = q{};
        $zeroch   = q{};
        $attch    = q{};
        $showpriv = q{};
        $brdpic   = q{};
        $brdrssch = q{}; ### RSS on Board Index ###
        $brdpasswr = q{};
        $brdpassw = ${$uid.$editboards[$i]}{'brdpassw'};
        $brdpassw3 = q{};
        $brdpassw2 = q{};
        if ($brdpassw ne q{}) { $brdpassw2 = qq~$boardpass_txt{'900pt'}~; }
        if (${$uid.$editboards[$i]}{'brdpasswr'} == 1) { $brdpasswr   = q~ checked="checked"~; }
        if ( $boardview == 1 ) { $showpriv = q~ checked="checked"~; }
        if ( ${ $uid . $id }{'zero'} == 1 ) {
            $zeroch = q~ checked="checked"~;
        }

        if ( ${ $uid . $id }{'attperms'} == 1 ) {
            $attch = q~ checked="checked"~;
        }
        if ( ${ $uid . $id }{'brdrss'} == 1 )   {
            $brdrssch = q~ checked="checked"~;
        } ### RSS on Board Index ###

        if ( ${ $uid . $id }{'ann'} == 1 ) {
            $annch  = q~ checked="checked"~;
            $brdpic = q~ disabled="disabled"~;
        }
        elsif ( $annboard ne q{} ) {
            $annch    = q~ disabled="disabled"~;
            $annexist = 1;
        }
        if ( ${ $uid . $id }{'rbin'} == 1 ) {
            $rbinch = q~ checked="checked"~;
            $brdpic = q~ disabled="disabled"~;
        }
        elsif ( $binboard ne q{} ) {
            $rbinch    = q~ disabled="disabled"~;
            $rbinexist = 1;
        }
        $en_rules = q{};
        if ( ${ $uid . $id }{'rules'} == 1 ) {
            $en_rules = q~ checked="checked"~;
        }
        $en_rulescoll = q{};
        if ( ${ $uid . $id }{'rulescollapse'} == 1 ) {
            $en_rulescoll = q~ checked="checked"~;
        }
        $rulestitle = ${ $uid . $editboards[$i] }{'rulestitle'};
        ToChars($rulestitle);
        $rulesdesc = ${ $uid . $editboards[$i] }{'rulesdesc'};
        $rulesdesc =~ s/<br \/>/\n/gsm;
        ToChars($rulesdesc);

        #Get Board permissions here
        my $startperms = DrawPerms( ${ $uid . $id }{'topicperms'}, 0 );
        my $replyperms = DrawPerms( ${ $uid . $id }{'replyperms'}, 1 );
        my $viewperms  = DrawPerms( $boardperms,                   0 );
        my $pollperms  = DrawPerms( ${ $uid . $id }{'pollperms'},  0 );

        $yymain .= qq~                  <tr>
                        <td class="titlebg" colspan="4"> <b>$boardtext</b></td>
                    </tr><tr>
                        <td class="catbg" colspan="4"><b>$admin_txt{'59'}:</b> $admin_txt{'60'}</td>
                    </tr><tr>~;
        if ( $id ne q{} ) {
            $yymain .= qq~
                        <td class="windowbg2"><b>$admin_txt{'61'}</b></td>
                        <td class="windowbg2" colspan="3"><input type="hidden" name="id$i" id="id$i" value="$id" />$id</td>~;
        }
        else {
            $yymain .= qq~
                        <td class="windowbg2"><label for="id$i"><b>$admin_txt{'61'}</b><br />$admin_txt{'61b'}</label></td>
                        <td class="windowbg2" colspan="3"><input type="text" name="id$i" id="id$i" /></td>~;
        }
        $yymain .= qq~
                    </tr><tr>
                        <td class="windowbg2"><label for="name$i"><b>$admin_txt{'68'}:</b><br />$admin_txt{'68a'}</label></td>
                        <td class="windowbg2" colspan="3"><input type="text" name="name$i" id="name$i" value="$boardname" size="50" maxlength="100" /></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="description$i"><b>$admin_txt{'62'}:</b><br />$admin_txt{'62a'}</label></td>
                        <td class="windowbg2" colspan="3"><textarea name="description$i" id="description$i" rows="5" cols="30" style="width:98%; height:60px">$description</textarea></td>
                    </tr><tr>
                        <td class="windowbg2">
                            <b>$admin_txt{'63'}:</b><br /><span class="small">
                            <a href="javascript:void(0);" onclick="window.open('$scripturl?action=qsearch;toid=moderators$i','','status=no,height=350px,width=300,menubar=no,toolbar=no,top=50,left=50,scrollbars=no')">$selector_txt{linklabel}</a><br />
                            <a href="javascript:copyNames($i)">$admin_txt{'63a'}</a><br/>
                            <a href="javascript:pasteNames($i,1)">$admin_txt{'63b'}</a><br/>
                            <a href="javascript:pasteNames(1,$FORM{'amount'})">$admin_txt{'63c'}</a></span>
                        </td>
                        <td class="windowbg2" colspan="3">
                            <select name="moderators$i" id="moderators$i" multiple="multiple" size="3" style="width: 320px;" ondblclick="removeUser(this);">~;

        my @thisBoardModerators = split /, ?/sm, $moderators;
        for my $thisMod (@thisBoardModerators) {
            LoadUser($thisMod);
            my $thisModname = ${ $uid . $thisMod }{'realname'};
            if ( !$thisModname ) { $thisModname = $thisMod; }
            if ($do_scramble_id) { $thisMod     = cloak($thisMod); }
            $yymain .= qq~
                                <option value="$thisMod">$thisModname</option>~;
        }

        $yymain .= qq~
                                <option value="" disabled="disabled">--</option>
                            </select>
                            <br /><span class="small">$selector_txt{instructions}</span>
                        </td>
                    </tr><tr>
                        <td class="windowbg2"><label for="moderatorgroups$i"><b>$admin_txt{'13'}:</b></label></td>
                        <td class="windowbg2" colspan="3">
~;

        # Allows admin to select entire membergroups to be a board moderator
        $k = 0;
        my $box = q{};
        for (@nopostorder) {
            @groupinfo = split /\|/xsm, $NoPost{$_};
            $box .= qq~<option value="$_"~;
            for ( split /, /sm, $moderatorgroups ) {
                ( $lineinfo, undef ) = split /\|/xsm, $NoPost{$_}, 2;
                if ( $lineinfo eq $groupinfo[0] ) {
                    $box .= q~ selected="selected" ~;
                }
            }
            $box .= qq~>$groupinfo[0]</option>~;
            $k++;
        }
        if ( $k > 5 ) { $k = 5; }
        if ( $k > 0 ) {
            $yymain .=
qq~                     <select multiple="multiple" name="moderatorgroups$i" id="moderatorgroups$i" size="$k">$box</select> <label for="moderatorgroups$i"><span class="small">$admin_txt{'14'}</span></label>~;
        }
        else {
            $yymain .= qq~$admin_txt{'15'}~;
        }

        my $drawndirs = q{};
        for my $curtemplate ( sort { $templateset{$a} cmp $templateset{$b} } keys %templateset ) {
            @templatelst = split /\|/xsm, $templateset{$curtemplate};
            $drawndirs .= qq~<option value="$templatelst[1]">$curtemplate</option>\n~;
            push @tmplt, $templatelst[1];
        }

        my $boardpic_value = q{};
        my $brdpic_addr = q{};
        my $brdpic_loc  = q{};
        my $mystyle = q{};
        if ( $boardpic ) {
            fopen( BRDPIC, "<$boardsdir/brdpics.db" );
            my @brdpics = <BRDPIC>;
            fclose( BRDPIC);
            chomp @brdpics;
            for (@brdpics) {
                my ( $brdnm, $style, $brdpic ) = split /[|]/xsm, $_;

                if ( $brdnm eq $editboards[$i] ) {
                    for ( @tmplt ) {
                        if ($style eq $_) {
                            $mystyle = $style;
                            if ( $brdpic =~ /\//ixsm ) {
                                $brdpic_addr = qq~$brdpic~;
                            }
                            else {
                                $brdpic_addr = qq~$yyhtml_root/Templates/Forum/$style/Boards/$brdpic~;
                            }
                        }
                    }
                    $boardpic_value .= qq~               <div class="small bold"><input type="checkbox" name="del_pic$i" id="del_pic$i" value="$brdnm|$style|$brdpic" /><label for="del_pic$i">$admin_txt{'64b4'}</label><br />$admin_txt{'current_img'}: <a href="$brdpic_addr" target="_blank">$mystyle - $brdpic</a> <img src="$brdpic_addr" id="brd_img_resize" alt="board_pic" /> </div>~;
                }
            }
        }

        $yymain .= qq~
                        </td>
                    </tr><tr>
                        <td class="windowbg2"><label for="cat$i"><b>$admin_txt{'44'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><select name="cat$i" id="cat$i" onchange="updateParent(this.value, '$editboards[$i]', $i)">$catsel{$i}</select></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="parent$i"><b>$admin_txt{'249'}:</b></label></td>
                        <td class="windowbg2" colspan="3">
                            <select onchange="checkParent($i, '$editboards[$i]')" name="parent$i" id="parent$i">
                                <option value="">--</option>
                            </select>
                        </td>
                    </tr><tr>
                        <td class="windowbg2"><b>$admin_txt{'248'}:</b></td>
                        <td class="windowbg2" colspan="3">$childrenlist</td>
                    </tr><tr>
                        <td class="windowbg2"><label for="canpost$i"><b>$admin_txt{'247'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="canpost$i" id="canpost$i" value="1"$canpostch /> <label for="canpost$i">$admin_txt{'247a'}</label></td>
                    </tr><tr>
                        <td class="catbg" colspan="4"><b>$admin_txt{'64'}</b> $admin_txt{'64a'} </td>
                    </tr><tr>
                        <td class="windowbg2"><label for="pic$i"><b>$admin_txt{'64b'}:</b></label></td>
                         <td class="windowbg2" colspan="3"><span class="small">$admin_txt{'64b3'}</span>
                            <br />$admin_txt{'for_template'}: <select id="templt$i" name="templt$i">
                                $drawndirs
                            </select>
                            <br /><input type="file" name="pic$i" id="pic$i" size="35" /><input type="hidden" name="cur_pic$i" value="$brdpic_addr" />
                            <br /><span class="small">$admin_txt{'64b6'}</span>
                            <br /><input type="text" name="mypic$i" id="mypic$i" value="$myboardpic" size="50" maxlength="255"$brdpic /><span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('pic$i').value='';">X</span>$boardpic_value
                         </td>
                    </tr><tr>
                        <td class="windowbg2"><label for="brdrss$i"><b>$admin_txt{'brdrss1'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="brdrss$i" id="brdrss$i" value="1"$brdrssch /> <label for="brdrss$i"><span class="small">$admin_txt{'brdrss3'}</span></label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="zero$i"><b>$admin_txt{'64c'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="zero$i" id="zero$i" value="1"$zeroch /> <label for="zero$i">$admin_txt{'64d'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="show$i"><b>$admin_txt{'64e'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="show$i" id="show$i" value="1"$showpriv /> <label for="show$i">$admin_txt{'64f'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="att$i"><b>$admin_txt{'64k'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="att$i" id="att$i" value="1"$attch /> <label for="att$i">$admin_txt{'64l'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="ann$i"><b>$admin_txt{'64g'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" id="ann$i" name="ann$i" value="1" $annch onclick="javascript: if (this.checked) checkann(true, '$i'); else checkann(false, '$i');" /> <label for="ann$i">$admin_txt{'64h'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="rbin$i"><b>$admin_txt{'64i'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" id="rbin$i" name="rbin$i" value="1" $rbinch onclick="javascript: if (this.checked) checkbin(true, '$i'); else checkbin(false, '$i');" /> <label for="rbin$i">$admin_txt{'64j'}</label></td>
                    </tr><tr>
                        <td class="catbg"  colspan="4"><b>$admin_txt{'rules'}:</b></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="rules$i"><b>$admin_txt{'rules1'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="rules$i" id="rules$i" value="1"$en_rules /></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="rulescollapse$i"><b>$exptxt{'6'}</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="checkbox" name="rulescollapse$i" id="rulescollapse$i" value="1"$en_rulescoll /></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="rulestitle$i"><b>$admin_txt{'rules2'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="text" name="rulestitle$i" id="rulestitle$i" value="$rulestitle" size="50" maxlength="100" /></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="rulesdesc$i"><b>$admin_txt{'rules3'}:</b><br /><span class="small">$admin_txt{'rules4'}</span></label></td>
                        <td class="windowbg2" colspan="3"><textarea name="rulesdesc$i" id="rulesdesc$i" rows="5" cols="30" style="width:98%; height:60px">$rulesdesc</textarea></td>
                    </tr><tr>
                        <td class="catbg" colspan="4"><b>$admin_txt{'100'}:</b> $admin_txt{'100a'}</td>
                    </tr><tr>
                        <td class="windowbg2"><label for="minage$i"><b>$admin_txt{'95'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="text" size="3" name="minage$i" id="minage$i" value="$boardminage" /> <label for="minage$i">$admin_txt{'96'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="maxage$i"><b>$admin_txt{'95a'}:</b></label></td>
                        <td class="windowbg2" colspan="3"><input type="text" size="3" name="maxage$i" id="maxage$i" value="$boardmaxage" /> <label for="maxage$i">$admin_txt{'96a'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="gender$i"><b>$admin_txt{'97'}:</b></label></td>
                        <td class="windowbg2" colspan="3">$genselect <label for="gender$i">$admin_txt{'98'}</label></td>
                    </tr><tr>
                        <td class="windowbg2"><label for="pasww$i"><b>$boardpass_txt{'900pw'}:</b><br /><br />$boardpass_txt{'900pwb'}</label></td>
                        <td class="windowbg2" colspan="3">
                            <input type="checkbox" name="paswwr$i" id="paswwr$i" value="1"$brdpasswr /> <input type="text" size="15" name="pasww$i" id="pasww$i" value="$brdfpassw3" />
                            <br /><label for="paswwr$i">$boardpass_txt{'900pf'}</label>
                            <br /><span class="important">$brdpassw2</span>
                            <input type="hidden" name="brdpassw$i" value="$brdpassw" />
                        </td>
                    </tr><tr>
                        <td class="catbg"  colspan="4"><b>$admin_txt{'65'}:</b> $admin_txt{'65a'} <span class="small">$admin_txt{'14'}</span></td>
                    </tr><tr>
                        <td class="titlebg center"><label for="topicperms$i"><b>$admin_txt{'65b'}:</b></label></td>
                        <td class="titlebg center"><label for="replyperms$i"><b>$admin_txt{'65c'}:</b></label></td>
                        <td class="titlebg center"><label for="viewperms$i"><b>$admin_txt{'65d'}:</b></label></td>
                        <td class="titlebg center"><label for="pollperms$i"><b>$admin_txt{'65e'}:</b></label></td>
                    </tr><tr>
                        <td class="windowbg2 center">
                            <select multiple="multiple" name="topicperms$i" id="topicperms$i" size="8">\n$startperms
                            </select>
                        </td>
                        <td class="windowbg2 center">
                            <select multiple="multiple" name="replyperms$i" id="replyperms$i" size="8">\n$replyperms
                            </select>
                        </td>
                        <td class="windowbg2 center">
                            <select multiple="multiple" name="viewperms$i" id="viewperms$i" size="8">\n$viewperms
                            </select>
                        </td>
                        <td class="windowbg2 center">
                            <select multiple="multiple" name="pollperms$i" id="pollperms$i" size="8">\n$pollperms
                            </select>
                        </td>
                    </tr>
                </table>
            </div>
            <div class="bordercolor rightboxdiv">
                <table class="border-space pad-cell" style="margin-bottom: .5em;">
~;
    }
    $yymain .= qq~                  <tr>
                        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
                    </tr><tr>
                        <td class="catbg center">
                            <input type="hidden" name="amount" value="$FORM{'amount'}" />
                            <input type="hidden" name="screenornot" value="$INFO{'action'}" />
                            <input type="submit" value="$admin_txt{'10'}" class="button" />
                        </td>
                    </tr>
                </table>
            </div>
        </form>
        <script type="text/javascript">
var numboards = "$FORM{'amount'}";
var annexist = "$annexist";
var rbinexist = "$rbinexist";
var istart = "$istart";
var editbrds = new Array();
$brd_javascript

function checkann(acheck, awho) {
    var adischeck = acheck;
    var adisuncheck = acheck;
    for (var i = istart; i <= numboards; i++) {
        if(i != awho) {
            if(document.getElementById('rbin'+i).checked === true) {
                adischeck = true;
                document.getElementById('ann'+i).disabled = true;
            }
            else {
                document.getElementById('ann'+i).disabled = acheck;
            }
        }
    }
    if(document.getElementById('ann'+awho).checked === true) {
        adischeck = true;
        document.forms["boardsadd"].elements['topicperms'+awho].selectedIndex = -1;
        document.forms["boardsadd"].elements['topicperms'+awho].options[0].selected = true;
        document.forms["boardsadd"].elements['replyperms'+awho].selectedIndex = -1;
        document.forms["boardsadd"].elements['replyperms'+awho].options[0].selected = true;
        document.forms["boardsadd"].elements['pollperms'+awho].selectedIndex = -1;
        document.forms["boardsadd"].elements['pollperms'+awho].options[0].selected = true;
    }
    document.getElementById('rbin'+awho).disabled = adischeck;
    document.getElementById('pic'+awho).disabled = adisuncheck;
    if(rbinexist == '1') document.getElementById('rbin'+awho).disabled = true;
}

function checkbin(bcheck, bwho) {
    var bdischeck = bcheck;
    var bdisuncheck = bcheck;
    for (var i = istart; i <= numboards; i++) {
        if(i != bwho) {
            if(document.getElementById('ann'+i).checked === true) {
                bdischeck = true;
                document.getElementById('rbin'+i).disabled = true;
            }
            else document.getElementById('rbin'+i).disabled = bcheck;
        }
    }
    if(document.getElementById('rbin'+bwho).checked === true) bdischeck = true;
    document.getElementById('ann'+bwho).disabled = bdischeck;
    document.getElementById('pic'+bwho).disabled = bdisuncheck;
    if(annexist == '1') document.getElementById('ann'+bwho).disabled = true;
}

selectParentBoard();
        </script>
    ~;
   $yytitle     = "$admin_txt{'50'}";
   if ( $INFO{'action'} eq 'boardscreen' ) {
    $yytitle     = "$admin_txt{'50a'}";
    }
    $action_area = 'manageboards';
    AdminTemplate();
    return;
}

sub DrawPerms {
    my ( $permissions, $permstype ) = @_;
    my ( $foundit, %found, $groupsel, $groupsel2, $name );
    my $count = 0;
    if ( $permissions eq q{} ) { $permissions = 'xk8yj56ndkal'; }
    my @perms = split /, /sm, $permissions;
    for my $perm (@perms) {
        $foundit = 0;
        if ( $permstype == 1 ) {
            $name = $admin_txt{'65f'};
            if ( $perm eq 'Topic Starter' ) {
                $foundit = 1;
                $found{$name} = 1;
                $groupsel .=
qq~                         <option value="Topic Starter" selected="selected">$name</option>\n~;
            }
            if ( $count == $#perms && $found{$name} != 1 ) {
                $groupsel2 .=
                  qq~                           <option value="Topic Starter">$name</option>\n~;
            }
        }

        ( $name, undef ) = split /\|/xsm, $Group{'Administrator'}, 2;
        if ( $perm eq 'Administrator' ) {
            $foundit = 1;
            $found{$name} = 1;
            $groupsel .=
qq~                         <option value="Administrator" selected="selected">$name</option>\n~;
        }
        if ( $count == $#perms && $found{$name} != 1 ) {
            $groupsel2 .= qq~                           <option value="Administrator">$name</option>\n~;
        }

        ( $name, undef ) = split /\|/xsm, $Group{'Global Moderator'}, 2;
        if ( $perm eq 'Global Moderator' ) {
            $foundit = 1;
            $found{$name} = 1;
            $groupsel .=
qq~                         <option value="Global Moderator" selected="selected">$name</option>\n~;
        }
        if ( $count == $#perms && $found{$name} != 1 ) {
            $groupsel2 .= qq~                           <option value="Global Moderator">$name</option>\n~;
        }

        ( $name, undef ) = split /\|/xsm, $Group{'Mid Moderator'}, 2;
        if ( $perm eq 'Mid Moderator' ) {
            $foundit = 1;
            $found{$name} = 1;
            $groupsel .=
qq~                         <option value="Mid Moderator" selected="selected">$name</option>\n~;
        }
        if ( $count == $#perms && $found{$name} != 1 ) {
            $groupsel2 .= qq~                           <option value="Mid Moderator">$name</option>\n~;
        }
        if ( $foundit != 1 || $count == $#perms ) {
            for (@nopostorder) {
                ( $name, undef ) = split /\|/xsm, $NoPost{$_}, 2;
                if ( $perm eq $_ ) {
                    $foundit = 1;
                    $found{$_} = 1;
                    $groupsel .=
qq~                         <option value="$_" selected="selected">$name</option>\n~;
                }
                if ( $found{$_} != 1 && $count == $#perms ) {
                    $groupsel2 .= qq~                           <option value="$_">$name</option>\n~;
                }
            }
            if ( $foundit != 1 || $count == $#perms ) {
                for ( reverse sort { $a <=> $b } keys %Post ) {
                    ( $name, undef ) = split /\|/xsm, $Post{$_}, 2;
                    if ( $perm eq $name ) {
                        $foundit = 1;
                        $found{$name} = 1;
                        $groupsel .=
qq~                         <option value="$name" selected="selected">$name</option>\n~;
                    }
                    if ( $count == $#perms
                        && ( $found{$name} != 1 || $found{$name} eq q{} ) )
                    {
                        $groupsel2 .=
                          qq~                           <option value="$name">$name</option>\n~;
                    }
                }
            }
        }
        $count++;
    }
    return $groupsel . $groupsel2;
}

sub AddBoards2 {
    is_admin_or_gmod();
    get_forum_master();
    $anncount  = 0;
    $rbincount = 0;
    my ( @boardcontrol, @changes, @updatecats );
    LoadBoardControl();

    for my $i ( 1 .. $FORM{'amount'} ) {
        ##### Dealing with Required Info here #####
        if ( $FORM{"id$i"} eq q{} ) { next; }
        $id = $FORM{"id$i"};
        if ( $FORM{"ann$i"} )  { $anncount++; }
        if ( $FORM{"rbin$i"} ) { $rbincount++; }
        if ( $anncount > 1 )   { fatal_error('announcement_defined'); }
        if ( $rbincount > 1 )  { fatal_error('recycle_bin_defined'); }
        if ( $id !~ /\A[0-9A-Za-z#%+-\.@^_]+\Z/xsm ) {
            fatal_error( 'invalid_character',
                "$admin_txt{'61'} $admin_txt{'241'}" );
        }
        my $newpic = q{};
        if ( $FORM{"pic$i"} ne q{} ) {
            $newpic = $FORM{"pic$i"};
            $FORM{"pic$i"} = UploadFile("pic$i", qq~Templates/Forum/$FORM{"templt$i"}/Boards~, 'png jpg jpeg gif', '250', '0');
            fopen( BRDPIC, ">>$boardsdir/brdpics.db" );
            print {BRDPIC} qq~$id|$FORM{"templt$i"}|$newpic\n~;
            fclose(BRDPIC);

            if ( $FORM{"cur_pic$i"} ne q{} ) {
                unlink qq~$htmldir/Templates/Forum/$FORM{"templt$i"}/Boards/$FORM{"cur_pic$i"}~;
            }
        }
        elsif ( $FORM{"mypic$i"} ne q{} ) {
            $newpic = $FORM{"mypic$i"};
            if ( $newpic !~ m{^[0-9a-zA-Z_\.\#\%\-\:\+\?\$\&\~\.\,\@/]+\.(gif|png|bmp|jpg)$}xsm )
            {
                fatal_error('invalid_picture');
            }
            else {
                fopen( BRDPIC, ">>$boardsdir/brdpics.db" );
                print {BRDPIC} qq~$id|$FORM{"templt$i"}|$newpic\n~;
                fclose(BRDPIC);
                $FORM{"pic$i"} = $FORM{"mypic$i"};
            }
        }
        else {
            $FORM{"pic$i"} = $FORM{"cur_pic$i"};
        }

        if ( $FORM{"del_pic$i"} ) {
            my @pklst = split /[|]/xsm, $FORM{"del_pic$i"};
            if ( $pklst[2] !~ /[ht|f]tp[s]{0,1}:\/\//xsm ) {
                unlink qq~$htmldir/Templates/Forum/$pklst[1]/Boards/$pklst[2]~;;
                fopen( BRDPIC, "<$boardsdir/brdpics.db" );
                @piclist = <BRDPIC>;
                fclose(BRDPIC);
                chomp @piclist;
                fopen( BRDPIC2, ">$boardsdir/brdpics.db" );
                for ( @piclist) {
                    if ( $_ ne $FORM{"del_pic$i"} ) {
                        print {BRDPIC2} qq~$_\n~;
                    }
                    else { print {BRDPIC2} q{};
                    }
                }
                fclose(BRDPIC2);
            }
            $FORM{"pic$i"} = q{};
        }

        if ( $FORM{'screenornot'} ne 'boardscreen' ) {

            # adding a board
            # make sure no board already exists with that id
            if ( exists $board{"$id"} ) {
                fatal_error( 'board_defined', "$id" );
            }

# add to category if it's not a sub board, otherwise add it to subboard list for its parent
            if ( !$FORM{"parent$i"} ) {
                my @bdlist = split /\,/xsm, $cat{ $FORM{"cat$i"} };
                push @bdlist, "$id";
                $cat{ $FORM{"cat$i"} } = join q{,}, @bdlist;
            }
            else {
                if ( $subboard{ $FORM{"parent$i"} } ne q{} ) {
                    $subboard{ $FORM{"parent$i"} } .= qq~|$id~;
                }
                else {
                    $subboard{ $FORM{"parent$i"} } = $id;
                }
            }
            fopen( BOARDINFO, ">$boardsdir/$id.txt" );
            print {BOARDINFO} q{} or croak "$croak{'print'}' BOARDINFO";
            fclose(BOARDINFO);
        }
        if ( $FORM{'screenornot'} eq 'boardscreen' ) {

            # editing a board
            my $category = ${ $uid . $id }{'cat'};

            # move category of board
            if ( $category ne $FORM{"cat$i"} ) {
                ${ $uid . $id }{'cat'} = qq~$FORM{"cat$i"}~;

                # recursively change the category of child boards.
                if ( $subboard{$id} ) {

                    *cat_change = sub {
                        my @x = @_;
                        for my $childbd (@x) {
                            ${ $uid . $childbd }{'cat'} = qq~$FORM{"cat$i"}~;
                            push @updatecats, $childbd;
                            if ( $subboard{$childbd} ) {
                                cat_change( split /\|/xsm,
                                    $subboard{$childbd} );
                            }
                        }
                    };
                    cat_change( split /\|/xsm, $subboard{$id} );
                }

                # if it's not a sub board, remove from the old category
                if ( !${ $uid . $id }{'parent'} ) {
                    my @bdlist = split /,/xsm, $cat{$category};

                    # Remove Board from old Category
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $id eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $cat{"$category"} = join q{,}, @bdlist;
                }

                # Add Category to new Category, but only if it isn't a sub board
                if ( !$FORM{"parent$i"} ) {
                    my $ncat = $FORM{"cat$i"};
                    if ( $cat{$ncat} ne q{} ) { $cat{$ncat} .= ",$id"; }
                    else                      { $cat{$ncat} = $id; }
                }
            }

            # move parent board of board
            if ( ${ $uid . $id }{'parent'} ne $FORM{"parent$i"} ) {

# if it had a parent, remove it from that list, otherwise it didnt have a parent so remove it from cat list
                if ( ${ $uid . $id }{'parent'} ) {
                    my @bdlist =
                      split /\|/xsm, $subboard{ ${ $uid . $id }{'parent'} };

                    # Remove Board from old parent board
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $id eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $subboard{ ${ $uid . $id }{'parent'} } = join q{|}, @bdlist;
                }

# only remove from old category if it now has a parent and its in the same cat as before, otherwise
# cat had to have been changed to get a parent in a different cat, and the cat change takes care of
# removing it from the previous category
                elsif ( $category eq $FORM{"cat$i"} ) {
                    my @bdlist = split /,/xsm, $cat{$category};

                    # Remove Board from old Category
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $id eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $cat{$category} = join q{,}, @bdlist;
                }

# if we're removing the parent board, move it back up to it's category, otherwise add to new parent board
                if ( $FORM{"parent$i"} eq q{} ) {

                    # only move up to cat if cat is the same as previously
                    if ( $category eq $FORM{"cat$i"} ) {
                        my @bdlist = split /\,/xsm, $cat{ $FORM{"cat$i"} };
                        push @bdlist, "$id";
                        $cat{ $FORM{"cat$i"} } = join q{,}, @bdlist;
                    }
                }
                else {

                    # Add to new parent board
                    if ( $subboard{ $FORM{"parent$i"} } ) {
                        $subboard{ $FORM{"parent$i"} } .= qq~|$id~;
                    }
                    else {
                        $subboard{ $FORM{"parent$i"} } = $id;
                    }
                }
            }

            if ( -e "$boardsdir/$id.txt" ) { # fix a(nnboard) in the boardid.txt
                fopen( BOARDINFO, "$boardsdir/$id.txt" )
                  || fatal_error( 'cannot_open', "$openboard/$id.txt", 1 );
                my @boardtomodify = <BOARDINFO>;
                fclose(BOARDINFO);
                my $x;
                if ( $FORM{"ann$i"}
                    && ( split /\|/xsm, $boardtomodify[0] )[8] !~ /a/ism )
                {
                    for my $x ( 0 .. ( @boardtomodify - 1 ) ) {
                        $boardtomodify[$x] =~
s/(.*\|)(0?)(.*)/ $1 . ($2 eq '0' ? "0a$3" : "a$3") /exsm;
                    }
                }
                elsif ( !$FORM{"ann$i"}
                    && ( split /\|/xsm, $boardtomodify[0] )[8] =~ /a/ism )
                {
                    *take_a_off =
                      sub { my $y = shift; $y =~ s/a//gsm; return $y; };
                    for my $x ( 0 .. ( @boardtomodify - 1 ) ) {
                        $boardtomodify[$x] =~
                          s/(.*\|)(.*)/ $1 . take_a_off($2) /exsm;
                    }
                }
                if ($x) {
                    fopen( BOARDINFO, ">$boardsdir/$id.txt" )
                      || fatal_error( 'cannot_open', "$openboard/$id.txt", 1 );
                    print {BOARDINFO} @boardtomodify
                      or croak "$croak{'print'} BOARDINFO";
                    fclose(BOARDINFO);
                }
            }
        }

        $bname = $FORM{"name$i"};
        FromChars($bname);
        ToHTML($bname);

      # If someone has the bright idea of starting a membergroup with a $
      # We need to escape it for them, to prevent us interpreting it as a var...
        $FORM{"viewperms$i"} =~ s/\$/\\\$/gxsm;

        $board{"$id"} = "$bname|$FORM{\"viewperms$i\"}|$FORM{\"show$i\"}";
        $bdescription = $FORM{"description$i"};
        FromChars($bdescription);
        $bdescription =~ s/\r//gxsm;
        $bdescription =~ s/\n/<br \/>/gsm;
        if ($do_scramble_id) {
            my @mods;
            for ( split /\, /sm, $FORM{"moderators$i"} ) {
                push @mods, decloak($_);
            }
            $FORM{"moderators$i"} = join q{, }, @mods;
        }
        if ( $FORM{"brdrss$i"} eq q{} ) { $FORM{"brdrss$i"} = 0; } ### RSS on Board Index ###
        if ( $FORM{"zero$i"} eq q{} ) { $FORM{"zero$i"} = 0; }
        $FORM{"minage$i"} =~ tr/[0-9]//cd;    ## remove non numbers
        $FORM{"maxage$i"} =~ tr/[0-9]//cd;    ## remove non numbers
        if ( $FORM{"minage$i"} < 0 )   { $FORM{"minage$i"} = q{}; }
        if ( $FORM{"maxage$i"} < 0 )   { $FORM{"maxage$i"} = q{}; }
        if ( $FORM{"minage$i"} > 180 ) { $FORM{"minage$i"} = q{}; }
        if ( $FORM{"maxage$i"} > 180 ) { $FORM{"maxage$i"} = q{}; }

        if ( $FORM{"maxage$i"} && $FORM{"maxage$i"} < $FORM{"minage$i"} ) {
            $FORM{"maxage$i"} = $FORM{"minage$i"};
        }

        if ( $FORM{"rules$i"}         eq q{} ) { $FORM{"rules$i"}         = 0; }
        if ( $FORM{"rulescollapse$i"} eq q{} ) { $FORM{"rulescollapse$i"} = 0; }
        $brulestitle = $FORM{"rulestitle$i"};
        FromChars($brulestitle);
        $brulesdesc = $FORM{"rulesdesc$i"};
        FromChars($brulesdesc);
        $brulesdesc =~ s/\r//gxsm;
        $brulesdesc =~ s/\n/<br \/>/gsm;

        $FORM{"pasww$i"} =~ s/ //gsm;
        if ($FORM{"pasww$i"} ne q{}) {
            if ($FORM{"pasww$i"} !~ /\A[\s0-9A-Za-z!@#$%\^&*\(\)_\+|`~\-=\\:;'",\.\/?\[\]\{\}]+\Z/sm) { fatal_error("$register_txt{'240'} $register_txt{'36'} $register_txt{'241'}") }
            $encryptopass = encode_password($FORM{"pasww$i"});
        }
        else {
            if ($FORM{"paswwr$i"}) { $encryptopass = $FORM{"brdpassw$i"}; } else { $encryptopass = q{};}
        }
        if ( $FORM{"pic$i"} ) {
            $mypic = 'y';
        }
        @modhook = (
        );
        ## BRD Mod Hook ##
        $modchk = @modhook;
        $modhook = q{};
        if ( $modchk > 0 ) {
            $modhook = join q{|}, @modhook;
        }
        push @boardcontrol,
qq~$FORM{"cat$i"}|$id|$mypic|$bdescription|$FORM{"moderators$i"}|$FORM{"moderatorgroups$i"}|$FORM{"topicperms$i"}|$FORM{"replyperms$i"}|$FORM{"pollperms$i"}|$FORM{"zero$i"}|$FORM{"membergroups$i"}|$FORM{"ann$i"}|$FORM{"rbin$i"}|$FORM{"att$i"}|$FORM{"minage$i"}|$FORM{"maxage$i"}|$FORM{"gender$i"}|$FORM{"canpost$i"}|$FORM{"parent$i"}|$FORM{"rules$i"}|$brulestitle|$brulesdesc|$FORM{"rulescollapse$i"}|$FORM{"paswwr$i"}|$encryptopass|$FORM{"brdrss$i"}|$modhook\n~;
        push @changes, $id;
        $yymain .= qq~<i>'$FORM{"name$i"}'</i> $admin_txt{'48'} <br />~;
    }

    # do the saving here, after all new boards passed the tests (fatal_error)
    if ( $FORM{'screenornot'} ne 'boardscreen' ) {
        BoardTotals( 'add', @changes );
    }

    Write_ForumMaster();
    fopen( FORUMCONTROL, "+<$boardsdir/forum.control" );
    seek FORUMCONTROL, 0, 0;
    my @oldcontrols = <FORUMCONTROL>;
    my $oldboard;

    # Update categories for subboards that got changed.
    for my $cnt ( 0 .. ( @oldcontrols - 1 ) ) {
        ( undef, $oldboard, undef ) = split /\|/xsm, $oldcontrols[$cnt], 3;
        for my $changedboard (@updatecats) {
            if ( $changedboard eq $oldboard ) {
                my ( $oldcat, $therest ) = split /\|/xsm, $oldcontrols[$cnt], 2;
                $oldcontrols[$cnt] = qq~${$uid.$changedboard}{'cat'}|$therest~;
                last;
            }
        }
    }

    for my $cnt ( 0 .. ( @oldcontrols - 1 ) ) {
        ( undef, $oldboard, undef ) = split /\|/xsm, $oldcontrols[$cnt], 3;
        for my $changedboard (@changes) {
            if ( $changedboard eq $oldboard ) {
                $oldcontrols[$cnt] = q{};
                last;
            }
        }
    }
    push @oldcontrols, @boardcontrol;
    @boardcontrol = grep { $_; } @oldcontrols;

    truncate FORUMCONTROL, 0;
    seek FORUMCONTROL, 0, 0;
    print {FORUMCONTROL} sort @boardcontrol or croak "$croak{'print'} FORUMCONTOL";
    fclose(FORUMCONTROL);

    $yytitle = $admin_txt{'50a'};
    $action_area = 'manageboards';
    AdminTemplate();
    return;
}

sub ReorderBoards {
    is_admin_or_gmod();
    get_forum_master();
    if ( $INFO{'subboards'} ) { LoadBoardControl(); }
    if ( $#categoryorder > 0 ) {
        for my $category (@categoryorder) {
            chomp $category;
            ( $categoryname, undef ) = split /\|/xsm, $catinfo{$category};
            ToChars($categoryname);
            if (
                ( $category eq $INFO{'item'} && !$INFO{'subboards'} )
                || (   $category eq ${ $uid . $INFO{'item'} }{'cat'}
                    && $INFO{'subboards'} )
              )
            {
                $categorylistsel =
qq~<option value="$category" selected="selected">$categoryname</option>~;
            }
            else {
                $categorylist .=
                  qq~<option value="$category">$categoryname</option>~;
            }

            # build option lists for parent boards
            my @catboards = split /,/xsm, $cat{$category};
            my $indent = -2;
            $catboardlist{$category} = q~<option value=''>&nbsp;</option>~;

            *get_subboards2 = sub {
                my @x = @_;
                $indent += 2;
                for my $childbd (@x) {
                    my $dash;
                    if ( $indent > 0 ) { $dash = q{-}; }
                    ( $chldboardname, undef, undef ) =
                      split /\|/xsm, $board{"$childbd"};
                    ToChars($chldboardname);
                    $catboardlist{$category} .=
                        qq~<option value='$childbd'>~
                      . ( '&nbsp;' x $indent )
                      . ( $dash x ( $indent / 2 ) )
                      . qq~ $chldboardname</option>~;
                    if ( $subboard{$childbd} ) {
                        get_subboards2( split /\|/xsm, $subboard{$childbd} );
                    }
                }
                $indent -= 2;
            };
            get_subboards2(@catboards);

            $catboardlist_js .= qq~
                catboardlist['$category'] = "$catboardlist{$category}";
            ~;
        }
    }

# get list of subboards if that's what we're reordering otherwise boards in the selected category
    if ( $INFO{'subboards'} ) {
        @bdlist = split /\|/xsm, $subboard{ $INFO{'item'} };
        $INFO{'subboards'} = ';subboards=1';
        ( $curname, $boardperms, $boardview ) =
          split /\|/xsm, $board{ $INFO{'item'} };
        ToChars($curname);
        $cur_txt = $admin_txt{'832a'};
    }
    else {
        @bdlist = split /,/xsm, $cat{ $INFO{'item'} };
        ( $curname, $catperms ) = split /\|/xsm, $catinfo{ $INFO{'item'} };
        ToChars($curname);
        $cur_txt = $admin_txt{'832'};
    }
    $bdcnt = @bdlist;
    $bdnum = $bdcnt;
    if ( $bdcnt < 4 ) { $bdcnt = 4; }

    # Prepare the list of current boards to be put in the select box
    $boardslist =
qq~<select name="selectboards" id="selectboards" size="$bdcnt" style="width: 190px;">~;
    for my $board (@bdlist) {
        chomp $board;
        ( $boardname, undef ) = split /\|/xsm, $board{$board}, 2;
        ToChars($boardname);
        if ( $board eq $INFO{'theboard'} ) {
            $boardslist .=
qq~<option value="$board" selected="selected">$boardname</option>~;
        }
        else {
            $boardslist .= qq~<option value="$board">$boardname</option>~;
        }
    }
    $boardslist .= q~</select>~;

    if ( $INFO{'subboards'} ) {
        $cat_or_bd_txt = $admin_txt{'739h'};
        $admin_txt{'739c'} =~ s/{(.*?)}/$admin_txt{'739j'}$1/gsm;
        $admin_txt{'739d'} =~ s/{(.*?)}/$admin_txt{'739j'}$1/gsm;
        $admin_txt{'739f'} =~ s/{(.*?)}/$admin_txt{'739j'}$1/gsm;
    }
    else {
        $cat_or_bd_txt = $admin_txt{'739'};
        $admin_txt{'739c'} =~ s/{(.*?)}/$1/gsm;
        $admin_txt{'739d'} =~ s/{(.*?)}/$1/gsm;
        $admin_txt{'739f'} =~ s/{(.*?)}/$1/gsm;
    }

    $yymain .= qq~
<br /><br />
<form action="$adminurl?action=reorderboards2;item=$INFO{'item'}$INFO{'subboards'}" method="post" id="bdform" accept-charset="$yymycharset">
    <table class="bordercolor border-space pad-cell" style="width:535px">
  <tr>
            <td class="titlebg">$admin_img{'board'} <b>$cur_txt ($curname)</b></td>
        </tr><tr>
            <td class="windowbg">
~;
    if ($bdnum) {
        $yymain .= qq~
    <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small"><label for="selectboards">$cat_or_bd_txt</label></div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">$boardslist</div>
    <div style="float: left; width: 280px; text-align: left; margin-bottom: 4px;" class="small">$admin_txt{'739d'}</div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
    <input type="submit" value="$admin_txt{'739a'}" name="moveup" style="font-size: 11px; width: 95px;" class="button" />
    <input type="submit" value="$admin_txt{'739b'}" name="movedown" style="font-size: 11px; width: 95px;" class="button" />
    </div>
~;
        if ( $#categoryorder > 0 ) {
            $yymain .= qq~
    <div class="small" style="float: left; width: 280px; text-align: left; margin-bottom: 4px;"><label for="selectcategory">$admin_txt{'739c'}</label></div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
    <select name="selectcategory" id="selectcategory" style="width: 190px;" onchange = "updateParent(this.value, '~
              . ( $INFO{'subboards'} ? $INFO{'item'} : q{} ) . qq~')">
    $categorylistsel
    $categorylist
    </select>
    </div><br />
~;
        }
        $yymain .= qq~
    <div class="small" style="float: left; width: 280px; text-align: left; margin-bottom: 4px;"><label for="selectboard">$admin_txt{'739f'}</label></div>
    <div style="float: left; width: 230px; text-align: center; margin-bottom: 4px;">
    <select name="selectboard" id="selectboard" style="width: 190px;"><option>&nbsp;</option></select>
    </div>
    <br />
    <div style="float: left; width: 280px; text-align: left;">&nbsp;</div>
    <div style="float: left; width: 230px; text-align: center;">
        <input type="button" onclick="checkParent()" value="$admin_txt{'739g'}" name="update" style="font-size: 11px; width: 190px;" class="button" />
    </div>
~;
    }
    else {
        $yymain .= qq~
                <div class="small center" style="margin-bottom: 4px;">$admin_txt{'739e'}</div>
~;
    }
    $yymain .= q~
    </td>
  </tr>
</table>
</form>
~;
    $yymain .= qq~
<script type="text/javascript">
var catboardlist = new Array();
$catboardlist_js

// updates parent drop down list when new category is selected
function updateParent(cat, board) {
    var parentsel = document.getElementById("selectboard");
    parentsel.innerHTML = catboardlist[cat];

    for (var i = 0; i < parentsel.options.length; i++) {
        if(parentsel.options[i].value == board) {
            parentsel.options[i].style.backgroundColor = "#ffbbbb";
        }
    }
}

// make sure we don't select a board and decide to move it to itself....
function checkParent() {
    var parent = document.getElementById("selectboard").value;
    var board = document.getElementById("selectboards").value;
    if(parent == board) {
        alert("$admin_txt{'733'}");
    }
    else if (!board) {
        alert("$admin_txt{'734'}");
    } else {
        document.getElementById("bdform").submit();
    }
}

updateParent('~
      . (
        $INFO{'subboards'} ? ${ $uid . $INFO{'item'} }{'cat'} : $INFO{'item'} )
      . qq~','$INFO{'item'}');
var parentsel = document.getElementById("selectboard");
~;

    if ( $INFO{'subboards'} ) {
        $yymain .= qq~
for (var i = 0; i < parentsel.options.length; i++) {
        if(parentsel.options[i].value == '$INFO{'item'}') {
            parentsel.options[i].selected = true;
        }
}
~;
    }

    $yymain .= q~
</script>
~;

    $yytitle     = "$admin_txt{'832'}";
    $action_area = 'manageboards';
    AdminTemplate();
    return;
}

sub ReorderBoards2 {
    is_admin_or_gmod();
    get_forum_master();

    if ( $INFO{'subboards'} ) {
        @itemorder = split /\|/xsm, $subboard{ $INFO{'item'} };
    }
    else {
        @itemorder = split /,/xsm, $cat{ $INFO{'item'} };
    }

    LoadBoardControl();

    my $moveitem = $FORM{'selectboards'};
    my $catorbd  = $INFO{'item'};
    my @updatecats;
    if ($moveitem) {
        if ( $FORM{'moveup'} || $FORM{'movedown'} ) {
            if ( $FORM{'moveup'} ) {
                for my $i ( 0 .. ( @itemorder - 1 ) ) {
                    if ( $itemorder[$i] eq $moveitem && $i > 0 ) {
                        $j             = $i - 1;
                        $itemorder[$i] = $itemorder[$j];
                        $itemorder[$j] = $moveitem;
                        last;
                    }
                }
            }
            elsif ( $FORM{'movedown'} ) {
                for my $i ( 0 .. ( @itemorder - 1 ) ) {
                    if ( $itemorder[$i] eq $moveitem && $i < $#itemorder ) {
                        $j             = $i + 1;
                        $itemorder[$i] = $itemorder[$j];
                        $itemorder[$j] = $moveitem;
                        last;
                    }
                }
            }
            if ( $INFO{'subboards'} ) {
                $subboard{$catorbd} = join q{|}, grep { $_; } @itemorder;
            }
            else {
                $cat{$catorbd} = join q{,}, grep { $_; } @itemorder;
            }
        }
        else {
            my $category = ${ $uid . $moveitem }{'cat'};
            if ( ${ $uid . $moveitem }{'cat'} ne $FORM{'selectcategory'} ) {
                ${ $uid . $moveitem }{'cat'} = qq~$FORM{'selectcategory'}~;
                my @bdlist = split /,/xsm, $cat{$category};

                # recursively change the category of child boards.
                if ( $subboard{$moveitem} ) {

                    *cat_change2 = sub {
                        my @x = @_;
                        for my $childbd (@x) {
                            ${ $uid . $childbd }{'cat'} =
                              qq~$FORM{'selectcategory'}~;
                            push @updatecats, $childbd;
                            if ( $subboard{$childbd} ) {
                                cat_change2( split /\|/xsm,
                                    $subboard{$childbd} );
                            }
                        }
                    };
                    cat_change2( split /\|/xsm, $subboard{$moveitem} );
                }

                # remove from the category list only if it was not a subboard
                if ( !${ $uid . $moveitem }{'parent'} ) {
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $moveitem eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $cat{$category} = join q{,}, @bdlist;
                }

                # add to new category if there's no parent selected
                if ( !$FORM{'selectboard'} ) {

                    # add to new cat list
                    my $ncat = $FORM{'selectcategory'};
                    if ( $cat{$ncat} ne q{} ) { $cat{$ncat} .= ",$moveitem"; }
                    else                      { $cat{$ncat} = $moveitem; }
                }
            }

            # if parent has changed
            if ( ${ $uid . $moveitem }{'parent'} ne $FORM{'selectboard'} ) {

# if it had a parent, remove it from that list, otherwise it didnt have a parent so remove it from cat list
                if ( ${ $uid . $moveitem }{'parent'} ) {
                    my @bdlist = split /\|/xsm,
                      $subboard{ ${ $uid . $moveitem }{'parent'} };

                    # Remove Board from old parent board
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $moveitem eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $subboard{ ${ $uid . $moveitem }{'parent'} } = join q{|},
                      @bdlist;
                }

# only remove from old category if it now has a parent and its in the same cat as before, otherwise
# cat had to have been changed to get a parent in a different cat, and the cat change takes care of
# removing it from the previous category
                elsif ( $category eq $FORM{'selectcategory'} ) {
                    my @bdlist = split /,/xsm, $cat{$category};

                    # Remove Board from old Category
                    my $k = 0;
                    for my $bd (@bdlist) {
                        if ( $moveitem eq $bd ) { splice @bdlist, $k, 1; }
                        $k++;
                    }
                    $cat{$category} = join q{,}, @bdlist;
                }

# if we're removing the parent board, move it back up to its category, otherwise add to new parent board
                if ( $FORM{'selectboard'} eq q{} ) {

                    # only move up to cat if cat is the same as previously
                    if ( $category eq $FORM{'selectcategory'} ) {
                        my @bdlist =
                          split /\,/xsm, $cat{ $FORM{'selectcategory'} };
                        push @bdlist, "$moveitem";
                        $cat{ $FORM{'selectcategory'} } = join q{,}, @bdlist;
                    }
                }
                else {

                    # Add to new parent board
                    if ( $subboard{ $FORM{'selectboard'} } ) {
                        $subboard{ $FORM{'selectboard'} } .= qq~|$moveitem~;
                    }
                    else {
                        $subboard{ $FORM{'selectboard'} } = $moveitem;
                    }
                }
                ${ $uid . $moveitem }{'parent'} = $FORM{'selectboard'};
            }
        }
        Write_ForumMaster();
        fopen( FORUMCONTROL, "+<$boardsdir/forum.control" );
        seek FORUMCONTROL, 0, 0;
        my @oldcontrols = <FORUMCONTROL>;
        for my $cnt ( 0 .. ( @oldcontrols - 1 ) ) {
            my @newbrd  = split /\|/xsm, $oldcontrols[$cnt];
            if ( $moveitem eq $oldboard ) {
                $newbrd[0] = ${$uid.$moveitem}{'cat'};
                $newbrd[18] = ${$uid.$moveitem}{'parent'};
                $newboardline = join q{|}, @newbrd;
                $oldcontrols[$cnt] = $newboardline . "\n";
            }
            for my $changedboard (@updatecats) {
                if ( $changedboard eq $oldboard ) {
                    $newbrd[0] = ${$uid.$changedboard}{'cat'};
                    $newbrd[18] = ${$uid.$changedboard}{'parent'};
                    $newboardline = join q{|}, @newbrd;
                    $oldcontrols[$cnt] = $newboardline . "\n";
                }
            }
        }
        my @boardcontrol = grep { $_; } @oldcontrols;

        truncate FORUMCONTROL, 0;
        seek FORUMCONTROL, 0, 0;
        print {FORUMCONTROL} sort @boardcontrol
          or croak "$croak{'print'} FORUMCONTROL";
        fclose(FORUMCONTROL);

    }
    $yySetLocation =
      qq~$adminurl?action=reorderboards;item=$category;theboard=$moveitem~;
    if ( !$INFO{'subboards'} ) {
        $yySetLocation =
          qq~$adminurl?action=reorderboards;item=$catorbd;theboard=$moveitem~;
    }
    else {
        $yySetLocation =
qq~$adminurl?action=reorderboards;item=$catorbd;theboard=$moveitem;subboards=1~;
    }
    redirectexit();
    return;
}

sub ConfRemBoard {
    $yymain .= qq~
    <table class="bordercolor border-space">
        <tr>
            <td class="titlebg"><b>$admin_txt{'31'} - '$FORM{'boardname'}'?</b></td>
        </tr><tr>
            <td class="windowbg">
                $admin_txt{'617'}<br />
                <b><a href="$adminurl?action=modifyboard;cat=$FORM{'cat'};id=$FORM{'id'};moda=$admin_txt{'31'}2">$admin_txt{'163'}</a> - <a href="$adminurl?action=manageboards">$admin_txt{'164'}</a></b>
            </td>
        </tr>
    </table>
~;
    $yytitle     = "$admin_txt{'31'} - '$FORM{'boardname'}'?";
    $action_area = 'manageboards';
    AdminTemplate();
    return;
}
1;
