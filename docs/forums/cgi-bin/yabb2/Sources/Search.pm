###############################################################################
# Search.pm                                                                   #
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

$searchpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Search');
get_micon();
get_template('Search');

if ( $FORM{'searchboards'} =~ /\A\!/xsm ) {
    my $checklist = q{};
    get_forum_master();
    foreach my $catid (@categoryorder) {
        (@bdlist) = split /\,/xsm, $cat{$catid};
        my ( $catname, $catperms, $catallowcol ) = split /\|/xsm,
          $catinfo{$catid};
        my $access = CatAccess($catperms);
        if ( !$access ) { next; }

        recursive_search(@bdlist);
    }

    sub recursive_search {
        my @x = @_;
        foreach my $curboard (@x) {
            chomp $curboard;

            # don't add to count if it's a sub board
            if ( !${ $uid . $curboard }{'parent'} ) { $cat_boardcnt{$catid}++; }
            my ( $boardname, $boardperms, $boardview ) = split /\|/xsm,
              $board{$curboard};
            my $access = AccessCheck( $curboard, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' ) { next; }
            $checklist .= qq~$curboard, ~;

            if ( $subboard{$curboard} ) {
                recursive_search( split /\|/xsm, $subboard{$curboard} );
            }
        }
        return;
    }
    $checklist =~ s/, \Z//sm;
    $FORM{'searchboards'} = $checklist;
}

sub plushSearch1 {

    # generate error if admin has disabled search options
    if ( $maxsearchdisplay < 0 ) { fatal_error('search_disabled'); }
    if ( $advsearchaccess ne 'granted' ) { fatal_error('no_access'); }
    my (
        @categories, $curcat,   %catname, %cataccess, @membergroups,
        %openmemgr,  $curboard, @threads, @boardinfo, $counter
    );

    LoadCensorList();
    if ( !$iamguest ) {
        Collapse_Load();
    }
    $yymain .= qq~
<script type="text/javascript">
function removeUser() {
    if (document.getElementById('userspec').value && confirm("$searchselector_txt{'removeconfirm'}")) {
        document.getElementById('userspec').value = "";
        document.getElementById('userspectext').value = "";
        if(document.getElementById('searchme').checked) {
            document.getElementById('searchme').checked = false;
            document.getElementById('userkind').disabled=false;
            document.getElementById('noguests').selected=true;
        }
        document.getElementById('usrsel').style.display = 'inline';
        document.getElementById('usrrem').style.display = 'none';
        document.getElementById('searchme').disabled = false;
    }
}

function addUser() {
    window.open('$scripturl?action=imlist;sort=username;toid=userspec','','status=no,height=360,width=464,menubar=no,toolbar=no,top=50,left=50,scrollbars=no');
}

function searchMe(chelem) {
    if(chelem.checked) {
        document.getElementById('userspectext').value='${$uid.$username}{'realname'}';
        document.getElementById('userspec').value='$username';
        document.getElementById('userkind').value='poster';
        document.getElementById('poster').selected=true;
        document.getElementById('userkind').disabled=true;
    } else {
        document.getElementById('userspectext').value='';
        document.getElementById('userspec').value='';
        document.getElementById('userkind').value='noguests';
        document.getElementById('noguests').selected=true;
        document.getElementById('userkind').disabled=false;
    }
}
</script>

<form action="$scripturl?action=search2" method="post" name="searchform" onsubmit="return CheckSearchFields();" accept-charset="$yymycharset">~;
    $yymain .= $mysearch_template . (
        $enable_ubbc
        ? qq~<br />
            <input type="checkbox" name="searchyabbtags" id="searchyabbtags" value="1" /><label for="searchyabbtags">$search_txt{'searchyabbtags'}</label>~
        : q{}
    );

    if (   !$ML_Allowed
        || ( $ML_Allowed == 1 && !$iamguest )
        || ( $ML_Allowed == 2 && $staff )
        || ( $ML_Allowed == 3 && ( $iamadmin || $iamgmod ) )
        || ( $ML_Allowed == 4 && ( $iamadmin || $iamgmod || $iamfmod ) ) )
    {
        $yymain .= $mysearch_template2;
        if ( !$iamguest ) {
            $yymain .=
qq~<input type="checkbox" name="searchme" id="searchme" style="margin: 0px; border: 0px; padding: 0px; vertical-align: middle;" onclick="searchMe(this);" /> <label for="searchme" class="lille">$search_txt{'searchme'}</label><br />~;
        }
        else {
            $yymain .=
q~<input type="checkbox" name="searchme" id="searchme" style="visibility: hidden;" /><br />~;
        }
        $yymain .= $mysearch_template3;
    }
    else {
        $yymain .= q~<input type="hidden" name="userkind" value="any" />~;
    }

    $yymain .= $mysearch_template4;

    $allselected = 0;
    $isselected  = 0;
    $boardscheck = q{};
    get_forum_master();

    foreach my $catid (@categoryorder) {
        $boardlist = $cat{$catid};
        (@bdlist) = split /\,/xsm, $boardlist;
        ( $catname, $catperms ) = split /\|/xsm, $catinfo{"$catid"};
        $cataccess = CatAccess($catperms);
        if ( !$cataccess ) { next; }

        foreach my $curboard (@bdlist) {
            ( $boardname, $boardperms, $boardview ) = split /\|/xsm,
              $board{"$curboard"};
            ToChars($boardname);
            my $access = AccessCheck( $curboard, q{}, $boardperms );
            if ( !$iamadmin && $access ne 'granted' ) { next; }

            if ( ${ $uid . $curboard }{'brdpasswr'} ) {
                my $bdmods = ${ $uid . $curboard }{'mods'};
                $bdmods =~ s/\, /\,/gsm;
                $bdmods =~ s/\ /\,/gsm;
                my %moderators = ();
                my $pswiammod  = 0;
                foreach my $curuser ( split /\,/xsm, $bdmods ) {
                    if ( $username eq $curuser ) { $pswiammod = 1; }
                }
                my $bdmodgroups = ${ $uid . $curboard }{'modgroups'};
                $bdmodgroups =~ s/\, /\,/gsm;
                my %moderatorgroups = ();
                foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                    if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                        $pswiammod = 1;
                    }
                    foreach my $memberaddgroups ( split /\, /sm,
                        ${ $uid . $username }{'addgroups'} )
                    {
                        chomp $memberaddgroups;
                        if ( $memberaddgroups eq $curgroup ) {
                            $pswiammod = 1;
                            last;
                        }
                    }
                }
                my $cookiename = "$cookiepassword$curboard$username";
                my $crypass    = ${ $uid . $curboard }{'brdpassw'};
                if (   !$iamadmin
                    && !$iamgmod
                    && !$pswiammod
                    && $yyCookies{$cookiename} ne $crypass )
                {
                    next;
                }
            }

            # Checks to see if category is expanded or collapsed
            if ( $username ne 'Guest' ) {
                if ( $catcol{$catid} ) {
                    $selected = q~selected="selected"~;
                    $isselected++;
                }
                else {
                    $selected = q{};
                }
            }
            else {
                $selected = q~selected="selected"~;
                $isselected++;
            }
            $allselected++;
            $checklist .=
qq~<option value="$curboard" $selected>$boardname</option>\n          ~;
            if ( !$subboard{$curboard} ) { next; }
            my $indent;

            *get_subboards = sub {
                my @x = @_;
                $indent += 2;
                foreach my $childbd (@x) {
                    my $dash;
                    if ( $indent > 0 ) { $dash = q{-}; }
                    ( $chldboardname, undef, undef ) = split /\|/xsm,
                      $board{"$childbd"};
                    ToChars($chldboardname);
                    $checklist .=
                        qq~<option value="$childbd" $selected>~
                      . ( '&nbsp;' x $indent )
                      . ( $dash x ( $indent / 2 ) )
                      . qq~ $chldboardname</option>\n          ~;
                    if ( $subboard{$childbd} ) {
                        get_subboards( split /\|/xsm, $subboard{$childbd} );
                    }
                }
                $indent -= 2;
                return;
            };
            get_subboards( split /\|/xsm, $subboard{$curboard} );
        }
    }
    if ( $isselected == $allselected ) {
        $boardscheck = q~ checked="checked"~;
    }
    if ( $iamadmin || $iamfmod || $iamgmod && $gmod_access2{'ipban2'} eq 'on' )
    {
        $search_ip =
qq~<input type="checkbox" name="search_ip" id="search_ip" value="on" /><label for="search_ip"> $search_txt{'73'}</label>~;
    }

    $yymain .= qq~
            <select multiple="multiple" name="searchboards" size="5" onchange="selectnum();">
            $checklist
            </select>
            <input type="checkbox" name="srchAll" id="srchAll"$boardscheck onclick="if (this.checked) searchAll(true); else searchAll(false);" /> <label for="srchAll">$search_txt{'737'}</label>
            <script type="text/javascript">
            function searchAll(_v) {
                for(var i=0;i<document.searchform.searchboards.length;i++)
                document.searchform.searchboards[i].selected=_v;
            }

            function selectnum() {
                document.searchform.srchAll.checked = true;
                for(var i=0;i<document.searchform.searchboards.length;i++) {
                    if (! document.searchform.searchboards[i].selected) { document.searchform.srchAll.checked = false; }
                }
            }
            </script>~;
    $yymain .= $mysearch_template5;
    $yymain =~ s/{yabb maxsearchdisplay}/$maxsearchdisplay/sm;
    $yymain =~ s/{yabb search_ip}/$search_ip/sm;

    $yymain .= qq~
<script type="text/javascript">
    document.searchform.search.focus();
    function CheckSearchFields() {
        if (document.searchform.numberreturned.value > $maxsearchdisplay) {
            alert("$search_txt{'191x'}");
            document.searchform.numberreturned.focus();
            return false;
        }
        return true;
    }
</script>
~;

    $yytitle      = $search_txt{'183'};
    $yynavigation = qq~&rsaquo; $search_txt{'182'}~;
    template();
    return;
}

sub plushSearch2 {

    # generate error if admin has disabled search options
    if ( $maxsearchdisplay < 0 ) { fatal_error('search_disabled'); }
    if ( $advsearchaccess ne 'granted' && $qcksearchaccess ne 'granted' ) {
        fatal_error('no_access');
    }
    spam_protection();

    my $maxage = $FORM{'age'}
      || ( int( ( $date - stringtotime($forumstart) ) / 86400 ) + 1 );

    my $display = $FORM{'numberreturned'} || $maxsearchdisplay;
    if ( $maxage  =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }
    if ( $display =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }

    # restrict flooding using form abuse
    if ( $display > $maxsearchdisplay ) { fatal_error('result_too_high'); }

    my $userkind = $FORM{'userkind'};
    my $userspec = $FORM{'userspec'};

    if    ( $userkind eq 'starter' )    { $userkind = 1; }
    elsif ( $userkind eq 'poster' )     { $userkind = 2; }
    elsif ( $userkind eq 'noguests' )   { $userkind = 3; }
    elsif ( $userkind eq 'onlyguests' ) { $userkind = 4; }
    else                                { $userkind = 0; $userspec = q{}; }

    if ( $userspec =~ m{/}xsm )  { fatal_error('no_user_slash'); }
    if ( $userspec =~ m{\\}xsm ) { fatal_error('no_user_backslash'); }
    $userspec =~ s/\A\s+//xsm;
    $userspec =~ s/\s+\Z//xsm;
    $userspec =~ s/[^0-9A-Za-z#%+,-\.@^_]//gxsm;
    if ($do_scramble_id) {
        $userspec =~ s/ //gsm;
        $userspec = decloak($userspec);
    }
    if ( $FORM{'searchme'} eq 'on' && !$iamguest ) {
        $userkind = 2;
        $userspec = $username;
    }
    $searchtype = $FORM{'searchtype'};
    my $search = $FORM{'search'};
    FromChars($search);
    my $one_per_thread = $FORM{'oneperthread'} || 0;
    if    ( $searchtype eq 'anywords' )  { $searchtype = 2; }
    elsif ( $searchtype eq 'asphrase' )  { $searchtype = 3; }
    elsif ( $searchtype eq 'aspartial' ) { $searchtype = 4; }
    else                                 { $searchtype = 1; }
    $search =~ s/\A\s+//xsm;
    $search =~ s/\s+\Z//xsm;
    if ( $searchtype != 3 ) { $search =~ s/\s+/ /gxsm; }
    if ( $search eq q{} || $search eq q{ } ) { fatal_error('no_search'); }
    if ( $search =~ m{/}xsm )  { fatal_error('no_search_slashes'); }
    if ( $search =~ m{\\}xsm ) { fatal_error('no_search_slashes'); }
    my $searchsubject = $FORM{'subfield'} eq 'on';
    my $searchmessage = $FORM{'msgfield'} eq 'on';
    if ( $FORM{'search_ip'} eq 'on' ) { $search_ip = $FORM{'search'}; }
    ToHTML($search);
    $search =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gxsm;
    $search =~ s/\cM//gxsm;
    $search =~ s/\n/<br \/>/gxsm;
    if ( $searchtype != 3 ) { @search = split /\s+/xsm, $search; }
    else                    { @search = ($search); }
    my $case = $FORM{'casesensitiv'};

    my (
        $curboard,  @threads,      $curthread, $tnum,      $tsub,
        $tname,     $temail,       $tdate,     $treplies,  $tusername,
        $ticon,     $tstate,       @messages,  $curpost,   $subfound,
        $msgfound,  $numfound,     %data,      $i,         $board,
        $curcat,    @categories,   %catid,     %catname,   %cataccess,
        %openmemgr, @membergroups, %cats,      @boardinfo, %boardinfo,
        @boards,    $counter,      $msgnum
    );
    my $maxtime =
      $date +
      ( 3600 * ${ $uid . $username }{'timeoffset'} ) -
      ( $maxage * 86400 );
    my $oldestfound = 9999999999;

    get_forum_master();
    foreach my $catid (@categoryorder) {
        $boardlist = $cat{$catid};
        (@bdlist) = split /\,/xsm, $boardlist;
        ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};
        $cataccess = CatAccess($catperms);
        if ( !$cataccess ) { next; }

        foreach my $cboard (@bdlist) {
            ( $bname, $bperms, $bview ) = split /\|/xsm, $board{$cboard};
            $catid{$cboard}   = $catid;
            $catname{$cboard} = $catname;
        }
    }

    foreach my $cbdlist ( keys %subboard ) {
        foreach my $cboard ( split /\|/xsm, $subboard{$cbdlist} ) {
            my $catid = ${ $uid . $cboard }{'cat'};
            ( $catname, $catperms ) = split /\|/xsm, $catinfo{$catid};
            $cataccess = CatAccess($catperms);
            if ( !$cataccess ) { next; }
            $catid{$cboard}   = $catid;
            $catname{$cboard} = $catname;
        }
    }
    if ($enable_ubbc) { require Sources::YaBBC; }

    @boards = split /\,\ /xsm, $FORM{'searchboards'};
  BOARDCHECK: foreach my $curboard (@boards) {
        ( $boardname{$curboard}, $boardperms, $boardview ) = split /\|/xsm,
          $board{$curboard};

        my $access = AccessCheck( $curboard, q{}, $boardperms );
        if ( !$iamadmin && $access ne 'granted' ) { next; }

        if ( ${ $uid . $curboard }{'brdpasswr'} ) {
            my $bdmods = ${ $uid . $curboard }{'mods'};
            $bdmods =~ s/\, /\,/gsm;
            $bdmods =~ s/\ /\,/gsm;
            my %moderators = ();
            my $pswiammod  = 0;
            foreach my $curuser ( split /\,/xsm, $bdmods ) {
                if ( $username eq $curuser ) { $pswiammod = 1; }
            }
            my $bdmodgroups = ${ $uid . $curboard }{'modgroups'};
            $bdmodgroups =~ s/\, /\,/gsm;
            my %moderatorgroups = ();
            foreach my $curgroup ( split /\,/xsm, $bdmodgroups ) {
                if ( ${ $uid . $username }{'position'} eq $curgroup ) {
                    $pswiammod = 1;
                }
                foreach my $memberaddgroups ( split /\, /sm,
                    ${ $uid . $username }{'addgroups'} )
                {
                    chomp $memberaddgroups;
                    if ( $memberaddgroups eq $curgroup ) {
                        $pswiammod = 1;
                        last;
                    }
                }
            }
            my $cookiename = "$cookiepassword$curboard$username";
            my $crypass    = ${ $uid . $curboard }{'brdpassw'};
            if (   !$iamadmin
                && !$iamgmod
                && !$pswiammod
                && $yyCookies{$cookiename} ne $crypass )
            {
                next;
            }
        }

        fopen( FILE, "$boardsdir/$curboard.txt" ) || next;
        @threads = <FILE>;
        fclose(FILE);

      THREADCHECK: foreach my $curthread (@threads) {
            chomp $curthread;

            (
                $tnum,     $tsub,      $tname, $temail, $tdate,
                $treplies, $tusername, $ticon, $tstate
            ) = split /\|/xsm, $curthread;

            if (   $tdate < $maxtime
                || $tstate =~ /m/ism
                || ( !$iamadmin && !$iamgmod && $tstate =~ /h/ism ) )
            {
                next THREADCHECK;
            }
            if ( $userkind == 1 ) {
                if ( $tusername eq 'Guest' ) {
                    if ( $tname !~ m{\A\Q$userspec\E\Z}ism ) {
                        next THREADCHECK;
                    }
                }
                else {
                    if ( $tusername !~ m{\A\Q$userspec\E\Z}ism ) {
                        next THREADCHECK;
                    }
                }
            }

            fopen( FILE, "$datadir/$tnum.txt" ) || next;
            @messages = <FILE>;
            fclose(FILE);

          POSTCHECK: foreach my $msgnum ( reverse 0 .. @messages ) {
                $curpost = $messages[$msgnum];
                chomp $curpost;

                my (
                    $msub,         $mname, $memail,  $mdate,
                    $musername,    $micon, $mattach, $mip,
                    $savedmessage, $ns
                ) = split /\|/xsm, $curpost;

                ## if either max to display or outside of filter, next
                if ( $mdate < $maxtime
                    || ( $numfound >= $display && $mdate <= $oldestfound ) )
                {
                    next POSTCHECK;
                }

                ToChars($msub);
                ( $msub, undef ) = Split_Splice_Move( $msub, 0 );

                ToChars($savedmessage);
                $message = $savedmessage;
                if ( $FORM{'searchyabbtags'} && $message =~ /\[\w[^\[]*?\]/xsm )
                {
                    wrap();
                    ( $message, undef ) = Split_Splice_Move( $message, $tnum );
                    if ($enable_ubbc) { DoUBBC(); }
                    wrap2();
                    $savedmessage = $message;
                    $message =~ s/<.+?>//gxsm;
                }
                elsif ( !$FORM{'searchyabbtags'} ) {
                    $message =~ s/\[\w[^\[]*?\]//gxsm;
                }

                if ( $musername eq 'Guest' ) {
                    if (
                        $userkind == 3
                        || (   $userkind == 2
                            && $mname !~ m{\A\Q$userspec\E\Z}ism )
                      )
                    {
                        next POSTCHECK;
                    }
                }
                else {
                    if (
                        $userkind == 4
                        || (   $userkind == 2
                            && $musername !~ m{\A\Q$userspec\E\Z}ism )
                      )
                    {
                        next POSTCHECK;
                    }
                }

                if ($searchsubject) {
                    if ( $searchtype == 2 || $searchtype == 4 ) {
                        $subfound = case_subfound( $case, $searchtype, $msub );
                    }
                    else {
                        $subfound = case_subfound2( $case, $msub );
                    }
                }
                if ( $searchmessage && !$subfound ) {
                    if ( $searchtype == 2 || $searchtype == 4 ) {
                        $msgfound =
                          case_subfound( $case, $searchtype, $message );
                    }
                    else {
                        $msgfound = case_subfound2( $case, $message );
                    }
                }

                ## blank? try next = else => build list from found mess/sub
                ## Search for IP Address start
                if ( $search_ip && !$msgfound && !$subfound ) {
                    $ipfound   = 0;
                    @mip       = split / /sm, $mip;
                    $mip       = q~~;
                    $mip_class    = q~~;
                    foreach (@mip) {
                        if ( $_ =~ /\b$search_ip/sm ) {
                            $ipfound = 1;
                        }
                        if ( $ipLookup ) {
                            if ( $_ =~ /\b$search_ip/sm ) {
                                $mip_class = ' highlight';
                            }
                            $mip .=
qq~<a href="$scripturl?action=iplookup;ip=$_"><span class="small$mip_class">$_</span></a> ~;
                        }
                        else {
                            $mip .= qq~<span class="small$mip_class">$_</span> ~;
                        }
                    }
                }
                else {
                    @mip       = split / /sm, $mip;
                    $mip    = q~~;
                    foreach (@mip) {
                        if ( $ipLookup ) {
                            $mip .=
qq~<a href="$scripturl?action=iplookup;ip=$_"><span class="small">$_</span></a> ~;
                        }
                        else {
                            $mip .= qq~<span class="small">$_</span> ~;
                        }
                    }
                }
                ## Search for IP Address end
                if ( !$msgfound && !$subfound && !$ipfound ) { next POSTCHECK; }

                $data{$mdate} = [
                    $curboard, $tnum,         $msgnum, $tusername,
                    $tname,    $msub,         $mname,  $memail,
                    $mdate,    $musername,    $micon,  $mattach,
                    $mip,      $savedmessage, $ns,     $tstate
                ];
                if ( $mdate < $oldestfound ) { $oldestfound = $mdate; }
                $numfound++;
                if ($one_per_thread) { last POSTCHECK; }
            }
        }
    }

    @messages = reverse sort { $a <=> $b } keys %data;
    if (@messages) {
        if ( @messages > $display ) { $#messages = $display - 1; }
        LoadCensorList();
    }
    else {
        $yymain .=
qq~<hr class="hr" /><b>$search_txt{'170'}<br /><a href="javascript:history.go(-1)">$search_txt{'171'}</a></b><hr class="hr" />~;
    }
    $search = Censor($search);

    # Search for censored or uncencored search string and remove duplicate words
    my @tmpsearch;
    if   ( $searchtype == 3 ) { @tmpsearch = ($search); }
    else                      { @tmpsearch = split /\s+/xsm, $search; }
    push @tmpsearch, @search;
    undef %found;
    @search = grep { !$found{$_}++ } @tmpsearch;
    my $icanbypass = checkUserLockBypass();
    for my $i ( 0 .. ( @messages - 1 ) ) {
        (
            $board, $tnum,    $msgnum, $tusername, $tname, $msub,
            $mname, $memail,  $mdate,  $musername, $micon, $mattach,
            $mip,   $message, $ns,     $tstate
        ) = @{ $data{ $messages[$i] } };

        $tname = addMemberLink( $tusername, $tname, $tnum );
        $mname = addMemberLink( $musername, $mname, $mdate );

        $mdate = timeformat($mdate);

        if ( !$FORM{'searchyabbtags'} ) {
            wrap();
            ( $message, undef ) = Split_Splice_Move( $message, $tnum );
            if ($enable_ubbc) { DoUBBC(); }
            wrap2();
        }
        ToChars($message);

        $message = Censor($message);
        $msub    = Censor($msub);

        Highlight( \$msub, \$message, \@search, $case );

        ToChars( $catname{$board} );
        ToChars( $boardname{$board} );

        # generate a sub board tree
        my $boardtree   = q{};
        my $parentboard = $board;
        while ($parentboard) {
            my ( $pboardname, undef, undef ) =
              split /\|/xsm, $board{"$parentboard"};
            ToChars($pboardname);
            if ( ${ $uid . $parentboard }{'canpost'} ) {
                $pboardname =
qq~<a href="$scripturl?board=$parentboard"><span class="under">$pboardname</span></a>~;
            }
            else {
                $pboardname =
qq~<a href="$scripturl?boardselect=$parentboard&subboards=1"><u>$pboardname</u></a>~;
            }
            $boardtree   = qq~ / $pboardname$boardtree~;
            $parentboard = ${ $uid . $parentboard }{'parent'};
        }

        ++$counter;

        $yymain .= $mysearch_template6;
        $yymain =~ s/{yabb counter}/$counter/sm;
        $yymain .=
qq~<a href="$scripturl?catselect=$catid{$board}"><span class="under">$catname{$board}</span></a> / <a href="$scripturl?board=$board"><span class="under">$boardname{$board}</span></a> / <a href="$scripturl?num=$tnum/$msgnum#$msgnum"><span class="under">$msub</span></a>&nbsp;<br /><span class="small">$search_txt{'30'}: $mdate</span>~;
        $yymain .= $mysearch_template7;
        $yymain =~ s/{yabb tname}/$tname/sm;
        $yymain =~ s/{yabb mname}/$mname/sm;

        if ( $tstate != 1
            && ( !$iamguest || ( $iamguest && $enable_guestposting ) ) )
        {
            my $notify = q{};
            if ( !$iamguest ) {
                if ( ${ $uid . $username }{'thread_notifications'} =~
                    /\b$tnum\b/xsm )
                {
                    $notify =
qq~$menusep<a href="$scripturl?action=notify3;oldnotify=1;num=$tnum/$msgnum#$msgnum">$img{'del_notify'}</a>~;
                }
                else {
                    $notify =
qq~$menusep<a href="$scripturl?action=notify2;oldnotify=1;num=$tnum/$msgnum#$msgnum">$img{'add_notify'}</a>~;
                }
            }
            $yymain .=
qq~<a href="$scripturl?board=$board;action=post;num=$tnum/$msgnum#$msgnum;title=PostReply">$img{'reply'}</a>$menusep<a href="$scripturl?board=$board;action=post;num=$tnum;quote=$msgnum;title=PostReply">$img{'recentquote'}</a>$notify~;
        }
        if (   $staff
            && ( $icanbypass || $tstate !~ /l/ism )
            && ( !$iammod || is_moderator( $username, $board ) ) )
        {
            LoadLanguage('Display');
            $yymain .=
qq~$menusep<a href="$scripturl?action=multidel;recent=1;thread=$tnum;del$c=$c" onclick="return confirm('~
              . (
                ( $icanbypass && $tstate =~ /l/ism )
                ? qq~$display_txt{'modifyinlocked'}\\n\\n~
                : q{}
              ) . qq~$display_txt{'rempost'}')">$img{'delete'}</a>~;
        }
        if (   $iamadmin
            || $iamfmod
            || $iamgmod && $gmod_access2{'ipban2'} eq 'on' )
        {
            $my_ipfind = $mysearch_template10;
            $ipimg = qq~<img src="$micon_bg{'ip'}" alt="" />~;
            $my_ipfind =~ s/{yabb ipimg}/$ipimg/sm;
            $my_ipfind =~ s/{yabb mip}/$mip/sm;
        }

        $yymain .= $mysearch_template9;
        $yymain =~ s/{yabb message}/$message/sm;
        $yymain =~ s/{yabb my_ipfind}/$my_ipfind/sm;
    }

    if (@messages) {
        $yymain .= qq~
$search_txt{'167'}<hr class="hr" />
<span class="small"><a href="$scripturl">$search_txt{'236'}</a> $search_txt{'237'}<br /></span>~;
    }

    $yynavigation = qq~&rsaquo; $search_txt{'166'}~;
    $yytitle      = $search_txt{'166'};
    template();
    return;
}

## does a search of all member pm files

sub pmsearch {
    $enable_PMsearch ||= 0;
    # generate error if admin has disabled search options
    if ( $enable_PMsearch <= 0 ) { fatal_error('search_disabled'); }

    my $display = $FORM{'numberreturned'} || $enable_PMsearch;
    if ( $display =~ /\D/xsm ) { fatal_error('only_numbers_allowed'); }
    if ( $display > $enable_PMsearch ) { fatal_error('result_too_high'); }

    $searchtype = $FORM{'searchtype'} || $INFO{'searchtype'};
    my $search = $FORM{'search'} || $INFO{'search'};
    my $pmbox  = $FORM{'pmbox'}  || '!all';

    FromChars($search);
    if    ( $searchtype eq 'anywords' )  { $searchtype = 2; }
    elsif ( $searchtype eq 'asphrase' )  { $searchtype = 3; }
    elsif ( $searchtype eq 'aspartial' ) { $searchtype = 4; }
    elsif ( $searchtype eq 'user' ) {
        $searchtype = 5;
        ManageMemberinfo('load');
        my $username;
        foreach ( keys %memberinf ) {
            ( $memrealname, undef ) = split /\|/xsm, $memberinf{$_}, 2;
            if ( $memrealname eq $search ) { $username = $_; }
        }
        $search = $username;
    }
    else { $searchtype = 1; }

    if ( $searchtype != 5 ) {
        $search =~ s/\A\s+//xsm;
        $search =~ s/\s+\Z//xsm;
        if ( $searchtype != 3 ) { $search =~ s/\s+/ /gsm; }
        if ( $search eq q{} || $search eq q{ } ) { fatal_error('no_search'); }
        if ( $search =~ m{/}xsm )  { fatal_error('no_search_slashes'); }
        if ( $search =~ m{\\}xsm ) { fatal_error('no_search_slashes'); }
        ToHTML($search);
        $search =~ s/\t/ \&nbsp; \&nbsp; \&nbsp;/gsm;
        $search =~ s/\cM//gxsm;
        $search =~ s/\n/<br \/>/gxsm;
    }

    my $pmboxesCount = 1;
    if ( $pmbox eq '!all' ) { $pmboxesCount = 3; }
    if ( $searchtype == 5 ) { @search = ($search); }
    elsif ( $searchtype != 3 ) { @search = split /\s+/xsm, lc $search; }
    else                       { @search = ( lc $search ); }

    my (
        $curboard,  @threads,      $curthread,  $tnum,      $tsub,
        $tname,     $temail,       $treplies,   $tusername, $ticon,
        $tstate,    $musername,    $micon,      $mattach,   $userfound,
        $subfound,  $msgfound,     $numfound,   %data,      $i,
        $board,     $curcat,       @categories, %catname,   %cataccess,
        %openmemgr, @membergroups, %cats,       @boardinfo, %boardinfo,
        @boards,    $counter,      @scanthreads
    );
    my $oldestfound = 9_999_999_999;

    if ( $pmbox eq '!all' || $pmbox eq '1' ) {
        if ( -e "$memberdir/$username.msg" ) {
            fopen( FILE, "$memberdir/$username.msg" );
            @msgthreads = <FILE>;
            fclose(FILE);
        }
    }

    if ( $pmbox eq '!all' || $pmbox eq '2' ) {
        if ( -e "$memberdir/$username.outbox" ) {
            fopen( FILE, "$memberdir/$username.outbox" );
            @outthreads = <FILE>;
            fclose(FILE);
        }
    }

    if ( $pmbox eq '!all' || $pmbox eq '3' ) {
        if ( -e "$memberdir/$username.imstore" ) {
            fopen( FILE, "$memberdir/$username.imstore" );
            @storethreads = <FILE>;
            fclose(FILE);
        }
    }

    if ($enable_ubbc) { require Sources::YaBBC; }

    for my $boxCount ( 1 .. $pmboxesCount ) {

        if ( $boxCount == 1 || $pmbox == 1 ) {
            @scanthreads = @msgthreads;
            $pmboxName   = 1;
        }
        if ( $boxCount == 2 || $pmbox == 2 ) {
            @scanthreads = @outthreads;
            $pmboxName   = 2;
        }
        if ( $boxCount == 3 || $pmbox == 3 ) {
            @scanthreads = @storethreads;
            $pmboxName   = 3;
        }
        chomp @scanthreads;

        ## reverse through messages
      POSTCHECK: foreach my $msgnum ( reverse 0 .. $#scanthreads ) {
            my (
                $messageid,  $mfromuser,    $mtouser, $mccuser,
                $mbccuser,   $msub,         $mdate,   $savedmessage,
                $mparentmid, $mreply,       $mip,     $mmessagestatus,
                $mflags,     $mstorefolder, $mattachment
            ) = split /\|/xsm, $scanthreads[$msgnum];

            ## if either max to display or outside of filter, next
            if ( $numfound >= $display && $mdate <= $oldestfound ) {
                next POSTCHECK;
            }

            ToChars($msub);

            ToChars($savedmessage);
            $message = $savedmessage;
            if ( $message =~ /\[\w[^\[]*?\]/xsm ) {
                wrap();
                if ($enable_ubbc) { DoUBBC(); }
                wrap2();
                $savedmessage = $message;
                $message =~ s/<.+?>//gxsm;
            }

            if ( $searchtype == 5 ) {
                $userfound = 0;
                foreach (@search) {
                    if ( $mfromuser eq $_ || $mtouser eq $_ ) {
                        $userfound = 1;
                    }
                }

            }
            elsif ( $searchtype == 2 || $searchtype == 4 ) {
                $subfound = 0;
                foreach (@search) {
                    if ( $searchtype == 4 && $msub =~ m{\Q$_\E}ixsm ) {
                        $subfound = 1;
                        last;
                    }
                    elsif ( $msub =~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm ) {
                        $subfound = 1;
                        last;
                    }
                }
            }
            else {
                $subfound = 1;
                foreach (@search) {
                    if ( $msub !~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm ) {
                        $subfound = 0;
                        last;
                    }
                }
            }
            ## nothing found? message
            if ( !$subfound ) {
                if ( $searchtype == 2 || $searchtype == 4 ) {
                    $msgfound = msgfnd( $searchtype, $message );
                }
                else {
                    $msgfound = msgfnd2($message);
                }
            }
            ## blank? try next = else => build list from found mess/sub
            if ( !$msgfound && !$subfound && !$userfound ) {
                next POSTCHECK;
            }

            $data{$mdate} = [
                $pmboxName,    $msgnum,      $msub,
                $mname,        $memail,      $mdate,
                $mfromuser,    $mtouser,     $mccuser,
                $mbccuser,     $mattachment, $mip,
                $savedmessage, $messageid,   $mstorefolder,
                $mmessagestatus
            ];
            if ( $mdate < $oldestfound ) { $oldestfound = $mdate; }
            $numfound++;
        }
    }

    ## sort result
    @messages = reverse sort { $a <=> $b } keys %data;
    if (@messages) {
        if ( @messages > $display ) { $#messages = $display - 1; }
        LoadCensorList();
    }
    else {
        $yysearchmain .=
          qq~<hr class="hr" />&nbsp; <b>$search_txt{'170'}</b><hr />~;
    }
    if ( $searchtype == 5 ) {
        $search = $FORM{'search'} || $INFO{'search'};
        @search = ($search);
    }    # not to display username
    $search = Censor($search);

    # Search for censored or uncencored search string and remove duplicate words
    my @tmpsearch;
    if ( $searchtype != 5 ) {
        if   ( $searchtype == 3 ) { @tmpsearch = ( lc $search ); }
        else                      { @tmpsearch = split /\s+/xsm, lc $search; }
    }
    push @tmpsearch, @search;
    undef %found;
    @search = grep { !$found{$_}++ } @tmpsearch;

    ## output results
    for my $i ( 0 .. ( @messages - 1 ) ) {
        my (
            $thispmbox, $msgnum,    $msub,         $mname,
            $memail,    $mdate,     $mfromuser,    $mtouser,
            $mccuser,   $mbccuser,  $mattachment,  $mip,
            $message,   $messageid, $mstorefolder, $mstatus
        ) = @{ $data{ $messages[$i] } };
        my ( $MemberFromLink, $MemberToLink, $MemberCCLink, $MemberBCCLink );
        my ( $fromTitle, $toTitle, $toTitleCC, $toTitleBCC, $FolderName );

        if ($mfromuser) {
            foreach my $uname ( split /\,/xsm, $mfromuser ) {
                my ( $guestName, $guestEmail ) = split / /sm, $uname;
                if ($guestEmail) { $uname = 'Guest'; }
                $MemberFromLink .=
                  addMemberLink( $uname, $guestName, $mdate ) . q{, };
            }
            $MemberFromLink =~ s/, \Z//sm;
            $MemberFromLink =~ s/%20/ /gsm;
            $fromTitle = qq~$search_txt{'pmfrom'}: $MemberFromLink<br />~;
        }

        if ($mtouser) {
            if ( $mstatus ne 'sb' ) {
                foreach my $uname ( split /\,/xsm, $mtouser ) {
                    $MemberToLink .=
                      addMemberLink( $uname, $uname, $mdate ) . q{, };
                }
                $MemberToLink =~ s/, \Z//sm;
                $toTitle = qq~$search_txt{'pmto'}: $MemberToLink<br />~;
            }
            else {
                require Sources::InstantMessage;
                foreach my $uname ( split /\,/xsm, $mtouser ) {
                    $MemberToLink .= links_to($uname);
                }
                $MemberToLink =~ s/, \Z//sm;
                $toTitle = qq~$search_txt{'pmto'}: $MemberToLink<br />~;
            }
        }

        if ( $mccuser && $mfromuser eq $username ) {
            foreach my $uname ( split /\,/xsm, $mccuser ) {
                $MemberCCLink .=
                  addMemberLink( $uname, $uname, $mdate ) . q{, };
            }
            $MemberCCLink =~ s/, \Z//sm;
            $toTitleCC = qq~$search_txt{'pmcc'}: $MemberCCLink<br />~;
        }

        if ( $mbccuser && $mfromuser eq $username ) {
            foreach my $uname ( split /\,/xsm, $mbccuser ) {
                $MemberBCCLink .=
                  addMemberLink( $uname, $uname, $mdate ) . q{, };
            }
            $MemberBCCLink =~ s/, \Z//sm;
            $toTitleBCC = qq~$search_txt{'pmbcc'}: $MemberBCCLink<br />~;
        }

        if ( $thispmbox == 1 ) {
            $FolderName = $pmboxes_txt{'inbox'};
        }
        elsif ( $thispmbox == 2 ) {
            $FolderName = $pmboxes_txt{'outbox'};
        }
        elsif ( $thispmbox == 3 ) {
            if ( $mstorefolder eq 'in' ) { $FolderName = $pmboxes_txt{'in'}; }
            elsif ( $mstorefolder eq 'out' ) {
                $FolderName = $pmboxes_txt{'out'};
            }
            else { $FolderName = $mstorefolder; }
            $FolderName = qq~$pmboxes_txt{'store'} &raquo; $FolderName~;
        }

        $mdate = timeformat($mdate);

        Highlight( \$msub, \$message, \@search, 0 );
        if ( $enable_ubbc && $message !~ /#nosmileys/isgm ) { MakeSmileys(); }

        $message = Censor($message);
        $msub    = Censor($msub);

        ++$counter;

        $yysearchmain .= $mysearch_PM;
        $yysearchmain =~ s/{yabb counter}/$counter/sm;
        $yysearchmain =~ s/{yabb FolderName}/$FolderName/sm;
        $yysearchmain =~ s/{yabb msub}/$msub/sm;
        $yysearchmain =~ s/{yabb mdate}/$mdate/sm;
        $yysearchmain =~ s/{yabb thispmbox}/$thispmbox/gsm;
        $yysearchmain =~ s/{yabb messageid}/$messageid/gsm;
        $yysearchmain =~ s/{yabb message}/$message/sm;
        $yysearchmain =~ s/{yabb fromTitle}/$fromTitle/sm;
        $yysearchmain =~ s/{yabb toTitle}/$toTitle/sm;
        $yysearchmain =~ s/{yabb toTitleCC}/$toTitleCC/sm;
        $yysearchmain =~ s/{yabb toTitleBCC}/$toTitleBCC/sm;

    }

    if (@messages) {
        $yysearchmain .= qq~
        &nbsp;&nbsp;$search_txt{'167'}
        <hr class="hr" />
    ~;
    }

    $yynavigation = qq~&rsaquo; $search_txt{'166'}~;
    $yytitle      = $search_txt{'166'};
    return;
}

sub addMemberLink {
    my ( $user, $displayname, $mdate ) = @_;
    if ( -e "$memberdir/$user.vars" ) { LoadUser($user); }
    if ( ${ $uid . $user }{'regdate'}
        && $mdate >= ( ${ $uid . $user }{'regtime'} || $date ) )
    {
        if ( $iamguest) {
            $mname = $format_unbold{$user};
        }
        else {
            $mname =
qq~<a href="$scripturl?action=viewprofile;username=$useraccount{$user}">$format_unbold{$user}</a>~;
        }
    }
    elsif ($user !~ m/Guest/sm
        && $mdate < ( ${ $uid . $user }{'regtime'} || $date ) )
    {
        $mname = qq~$displayname - $maintxt{'470a'}~;
    }
    else {
        $mname = $displayname . " ($maintxt{'28'})";
    }
    return $mname;
}

sub Highlight {
    my ( $msub, $message, $search, $case ) = @_;
    my $i = 0;
    my @HTMLtags;
    my $HTMLtag = 'HTML';
    while ( ${$message} =~ /\[$HTMLtag\d+\]/sm ) { $HTMLtag .= '1'; }
    while ( ${$message} =~ s/(<.+?>)/[$HTMLtag$i]/sm ) {
        push @HTMLtags, $1;
        $i++;
    }

    foreach my $tmp ( @{$search} ) {
        if ($case) {
            if ( $searchtype == 4 ) {
                ${$msub}    =~ s/(\Q$tmp\E)/<span class="highlight">$1<\/span>/gsm;
                ${$message} =~ s/(\Q$tmp\E)/<span class="highlight">$1<\/span>/gsm;
            }
            else {
                ${$msub}    =~ s/(^|\W|_)(\Q$tmp\E)(?=$|\W|_)/$1<span class="highlight">$2<\/span>$3/gsm;
                ${$message} =~ s/(^|\W|_)(\Q$tmp\E)(?=$|\W|_)/$1<span class="highlight">$2<\/span>$3/gsm;
            }
        }
        else {
            if ( $searchtype == 4 ) {
                ${$msub}    =~ s/(\Q$tmp\E)/<span class="highlight">$1<\/span>/igsm;
                ${$message} =~ s/(\Q$tmp\E)/<span class="highlight">$1<\/span>/igsm;
            }
            else {
                ${$msub}    =~ s/(^|\W|_)(\Q$tmp\E)(?=$|\W|_)/$1<span class="highlight">$2<\/span>$3/igsm;
                ${$message} =~ s/(^|\W|_)(\Q$tmp\E)(?=$|\W|_)/$1<span class="highlight">$2<\/span>$3/igsm;
            }
        }
    }

    $i = 0;
    while ( ${$message} =~ s/\[$HTMLtag$i\]/$HTMLtags[$i]/xsm ) { $i++; }
    return;
}

sub case_subfound {
    my ( $case, $searchtype, $msub ) = @_;
    $subfound = 0;
    foreach (@search) {
        if (   $case
            && $searchtype == 4
            && $msub =~ m{\Q$_\E}xsm )
        {
            $subfound = 1;
            last;
        }
        elsif ( !$case
            && $searchtype == 4
            && $msub =~ m{\Q$_\E}ixsm )
        {
            $subfound = 1;
            last;
        }
        if (   $case
            && $msub =~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}xsm )
        {
            $subfound = 1;
            last;
        }
        elsif ( !$case
            && $msub =~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm )
        {
            $subfound = 1;
            last;
        }
    }
    return $subfound;
}

sub case_subfound2 {
    my ( $case, $msub ) = @_;
    $subfound = 1;
    foreach (@search) {
        if (   $case
            && $msub !~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}xsm )
        {
            $subfound = 0;
            last;
        }
        elsif ( !$case
            && $msub !~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm )
        {
            $subfound = 0;
            last;
        }
    }
    return $subfound;
}

sub msgfnd {
    my ( $searchtype, $message ) = @_;
    $msgfound = 0;
    foreach (@search) {
        if ( $searchtype == 4 && $message =~ m{\Q$_\E}ixsm ) {
            $msgfound = 1;
            last;
        }
        elsif ( $message =~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm ) {
            $msgfound = 1;
            last;
        }
    }
    return $msgfound;
}

sub msgfnd2 {
    my ($message) = @_;
    $msgfound = 1;
    foreach (@search) {
        if ( $message !~ m{(^|\W|_)\Q$_\E(?=$|\W|_)}ixsm ) {
            $msgfound = 0;
            last;
        }
    }
    return $msgfound;
}
1;
