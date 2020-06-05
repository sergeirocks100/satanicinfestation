###############################################################################
# AntispamQuestions.pm                                                        #
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

$antispamquestionspmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

my $questions_language = $FORM{'questions_language'} || $INFO{'questions_language'} || $lang;

sub SpamQuestions {

    is_admin_or_gmod();

    if ($en_spam_questions)   { $chk_spam_question = q~ checked="checked"~; }
    if ($spam_questions_send) { $chk_spam_question_send = q~ checked="checked"~; }
    if ($spam_questions_gp)   { $chk_spam_question_gp = q~ checked="checked"~; }
    opendir LNGDIR, $langdir;
    my @lfilesanddirs = readdir LNGDIR;
    closedir LNGDIR;

    foreach my $fld (sort {lc($a) cmp lc $b} @lfilesanddirs) {
        if (-e "$langdir/$fld/Main.lng") {
            my $displang = $fld;
            $displang =~ s/(.+?)\_(.+?)$/$1 ($2)/gism;
            if ($questions_language eq $fld) { $drawnldirs .= qq~<option value="$fld" selected="selected">$displang</option>~; }
            else { $drawnldirs .= qq~<option value="$fld">$displang</option>~; }
        }
    }

    if (-e "$langdir/$questions_language/spam.questions") {
        fopen(SPAMQUESTIONS, "<$langdir/$questions_language/spam.questions") || fatal_error('cannot_open',"$langdir/$questions_language/spam.questions", 1);
    @spam_questions = <SPAMQUESTIONS>;
    fclose(SPAMQUESTIONS);
    }

    $total_questions = @spam_questions || 0;

    if ($total_questions) {
        $header_row = q~ colspan="5"~;
        $show_questions =
          qq~<tr class="catbg">
    <td><b>$spam_question_txt{'question'}</b></td>
    <td><b>$spam_question_txt{'answer'}</b></td>
    <td><b>$spam_question_txt{'image'}</b></td>
    <td><b>$admin_txt{'edit'}</b></td>
    <td><b>$admin_txt{'delete'}</b></td>
</tr>~;

        foreach my $question ( sort { $a <=> $b } @spam_questions ) {
            chomp $question;
            ( $spam_question_id, $spam_question, $spam_answer, undef, $spam_image ) = split /\|/xsm,
              $question;
              $spam_image = $spam_image ? qq~<a href="$defaultimagesdir/Spam_Img/$spam_image" target="_blank">$spam_image</a>~ : $spam_question_txt{'na'};
            $show_questions .= qq~<tr class="windowbg2">
    <td>$spam_question</td>
    <td>$spam_answer</td>
    <td>$spam_image</td>
    <td>
    <form action="$adminurl?action=spam_questions_edit" method="post">
      <input type="hidden" name="spam_question_id" value="$spam_question_id" />
      <input class="button" type="submit" value="$admin_txt{'edit'}" />
      <input type="hidden" name="questions_language" value="$questions_language" />
    </form>
    </td>
    <td>
    <form action="$adminurl?action=spam_questions_delete" method="post">
      <input type="hidden" name="spam_question_id" value="$spam_question_id" />
      <input class="button" type="submit" value="$admin_txt{'delete'}" onclick="return confirm('$spam_question_txt{'confirm'}');"/>
      <input type="hidden" name="questions_language" value="$questions_language" />
    </form>
    </td>
</tr>~;
        }
    }
    else {
        $header_row     = q~ colspan="5"~;
        $show_questions = qq~<tr class="windowbg2">
    <td colspan="5">$spam_question_txt{'no_questions'}</td>
</tr>~;
    }

    $yymain = qq~
<form action="$adminurl?action=spam_questions2" method="post">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col span="2" style="width: 50%" />
    </colgroup>
    <tr>
        <th class="titlebg" colspan="2">$admin_img{'prefimg'} $spam_question_txt{'question_settings'}</th>
    </tr><tr class="windowbg2 vtop">
        <td><label for="en_spam_questions">$spam_question_txt{'enable_question'}</label></td>
        <td><input type="checkbox" name="en_spam_questions" id="en_spam_questions" value="1"$chk_spam_question /></td>
    </tr><tr class="windowbg2 vtop">
        <td><label for="spam_questions_send">$spam_question_txt{'enable_question_send'}</label></td>
        <td><input type="checkbox" name="spam_questions_send" id="spam_questions_send" value="1"$chk_spam_question_send /></td>
    </tr><tr class="windowbg2 vtop">
        <td><label for="spam_questions_gp">$spam_question_txt{'enable_question_gp'}</label></td>
        <td><input type="checkbox" name="spam_questions_gp" id="spam_questions_gp" value="1"$chk_spam_question_gp /></td>
    </tr>
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input class="button" type="submit" value="$admin_txt{'10'}" />
            <input type="hidden" name="questions_language" value="$questions_language" />
        </td>
    </tr>
</table>
</div>
</form>
<div class="bordercolor rightboxdiv" style="margin-bottom: .5em;">
<table class="border-space pad-cell">
    <colgroup>
        <col span="2" style="width: 30%;" />
        <col span="1" style="width: 26%;" />
        <col span="2" style="width: 7%" />
    </colgroup>
    <tr>
        <th class="titlebg"$header_row>$admin_img{'prefimg'} $spam_question_txt{'questions'} ($total_questions)
            <div style="display: inline; float: right;">
            <form action="$adminurl?action=spam_questions" method="post" enctype="application/x-www-form-urlencoded">
                <select name="questions_language" id="questions_language" size="1">
                    $drawnldirs
                </select>
                <input type="submit" value="$admin_txt{'462'}" class="button" />
            </form>
            </div>
        </th>
    </tr>
$show_questions
</table>
</div>
<form action="$adminurl?action=spam_questions_add" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width: 25%" />
        <col style="width: 75%" />
    </colgroup>
    <tr>
        <th class="titlebg" colspan="2">$admin_img{'prefimg'} $spam_question_txt{'new_question'}</th>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_question">$spam_question_txt{'question'}:</label></td>
        <td><input type="text" name="spam_question" id="spam_question" size="60" maxlength="100" /></td>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_answer">$spam_question_txt{'answer'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'answer_desc'}</span></label></td>
        <td><input type="text" name="spam_answer" id="spam_answer" size="60" maxlength="50" /></td>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_case">$spam_question_txt{'case_sensitive'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'case_sensitive_desc'}</span></label></td>
        <td><input type="checkbox" name="spam_case" id="spam_case" value="1" /></td>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_image">$spam_question_txt{'image'} $spam_question_txt{'optional'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'image_desc'}</span></label></td>
        <td><input type="file" name="spam_image" id="spam_image" size="35" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('spam_image').value='';">X</span></td>
    </tr>
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input class="button" type="submit" value="$spam_question_txt{'add_question'}" />
            <input type="hidden" name="questions_language" value="$questions_language" />
        </td>
    </tr>
</table>
</div>
</form>
~;

    $yytitle     = $admintxt{'a3_sub6'};
    $action_area = 'spam_questions';
    AdminTemplate();
    exit;
}

sub SpamQuestions2 {
    is_admin_or_gmod();

    $en_spam_questions   = $FORM{'en_spam_questions'}   || '0';
    $spam_questions_send = $FORM{'spam_questions_send'} || '0';
    $spam_questions_gp   = $FORM{'spam_questions_gp'}   || '0';

    require Admin::NewSettings;
    SaveSettingsTo('Settings.pm');

    if ( $action eq 'spam_questions2' ) {
        $yySetLocation = qq~$adminurl?action=spam_questions;questions_language=$FORM{'questions_language'}~;
        redirectexit();
    }
    return;
}

sub SpamQuestionsAdd {
    is_admin_or_gmod();

    $spam_question = $FORM{'spam_question'};
    $spam_answer   = $FORM{'spam_answer'};
    $spam_case     = $FORM{'spam_case'} || '0';

    if ( $spam_question eq q{} ) {
        fatal_error( 'invalid_value', "$spam_question_txt{'question'}" );
    }
    if ( $spam_answer eq q{} ) {
        fatal_error( 'invalid_value', "$spam_question_txt{'answer'}" );
    }

    $spam_image = UploadFile('spam_image', 'Templates/Forum/default/Spam_Img', 'png jpg jpeg gif', '250', '0');

    fopen( SPAMQUESTIONS, ">>$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    print {SPAMQUESTIONS} "$date|$spam_question|$spam_answer|$spam_case|$spam_image\n"
      or croak "$croak{'print'} SPAMQUESTIONS";
    fclose(SPAMQUESTIONS);

    if ( $action eq 'spam_questions_add' ) {
        $yySetLocation = qq~$adminurl?action=spam_questions;questions_language=$FORM{'questions_language'}~;
        redirectexit();
    }
    return;
}

sub SpamQuestionsEdit {
    is_admin_or_gmod();

    $id = $FORM{'spam_question_id'};
    my $question_edit = q{};

    fopen( SPAMQUESTIONS, "<$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    @spam_questions = <SPAMQUESTIONS>;
    fclose(SPAMQUESTIONS);

    foreach my $question (@spam_questions) {
        chomp $question;
        if ( $question =~ /$id/xsm ) {
            $question_edit = $question;
            last;
        }
    }
    ( $spam_question_id, $spam_question, $spam_answer, $spam_case, $spam_image ) = split /\|/xsm,
      $question_edit;
    if ($spam_case)   { $chk_spam_case = q~ checked="checked"~; }
    my $spam_image_value = q{};
    if ( $spam_image ) {
        $spam_image_value = qq~<div class="small bold">$admin_txt{'current_img'}: <a href="$defaultimagesdir/Spam_Img/$spam_image" target="_blank">$spam_image</a><br /><input type="checkbox" name="del_spam_image" id="del_spam_image" value="1" /> <label for="del_spam_image">$admin_txt{'remove_img'}</label></div>~;
    }
    $yymain = qq~
<form action="$adminurl?action=spam_questions_edit2" method="post" enctype="multipart/form-data" accept-charset="$yymycharset">
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell" style="margin-bottom: .5em;">
    <colgroup>
        <col style="width: 25%" />
        <col style="width: 75%" />
    </colgroup>
    <tr>
        <th class="titlebg" colspan="2">$admin_img{'prefimg'} $spam_question_txt{'edit_question'}</th>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_question">$spam_question_txt{'question'}:</label></td>
        <td><input type="text" name="spam_question" id="spam_question" size="60" maxlength="100" value="$spam_question" /></td>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_answer">$spam_question_txt{'answer'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'answer_desc'}</span></label></td>
        <td><input type="text" name="spam_answer" id="spam_answer" size="60" maxlength="50" value="$spam_answer" /><input type="hidden" name="spam_question_id" id="spam_question_id" value="$spam_question_id" /></td>
    </tr><tr class="windowbg2 vtop bold">
        <td><label for="spam_case">$spam_question_txt{'case_sensitive'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'case_sensitive_desc'}</span></label></td>
        <td><input type="checkbox" name="spam_case" id="spam_case" value="1"$chk_spam_case /></td>
    </tr />
    <tr class="windowbg2 vtop bold">
        <td><label for="spam_image">$spam_question_txt{'image'} $spam_question_txt{'optional'}:<br /><span class="small" style="font-weight: normal;">$spam_question_txt{'image_desc'}</span></label></td>
        <td><input type="file" name="spam_image" id="spam_image" size="35" /><input type="hidden" name="cur_spam_image" value="$spam_image" /> <span class="cursor small bold" title="$admin_txt{'remove_file'}" onclick="document.getElementById('spam_image').value='';">X</span>$spam_image_value</td>
    </tr>
</table>
</div>
<div class="bordercolor rightboxdiv">
<table class="border-space pad-cell">
    <tr>
        <th class="titlebg">$admin_img{'prefimg'} $admin_txt{'10'}</th>
    </tr><tr>
        <td class="catbg center">
            <input class="button" type="submit" value="$admin_txt{'10'} $spam_question_txt{'question'}" />&nbsp;<input type="button" class="button" value="$admin_txt{'cancel'}" onclick="location.href='$adminurl?action=spam_questions;questions_language=$FORM{'questions_language'}';" />
        <input type="hidden" name="questions_language" value="$questions_language" />
        </td>
    </tr>
</table>
</div>
</form>~;

    $yytitle = $admintxt{'a3_sub6'};
    AdminTemplate();
    exit;
}

sub SpamQuestionsEdit2 {
    is_admin_or_gmod();

    $spam_question_id = $FORM{'spam_question_id'};
    $spam_question    = $FORM{'spam_question'};
    $spam_answer      = $FORM{'spam_answer'};
    $spam_case        = $FORM{'spam_case'} || '0';
    $spam_image       = $FORM{'spam_image'};
    $cur_spam_image   = $FORM{'cur_spam_image'};
    $del_spam_image   = $FORM{'del_spam_image'};

    if ( $spam_question eq q{} ) {
        fatal_error( 'invalid_value', "$spam_question_txt{'question'}" );
    }
    if ( $spam_answer eq q{} ) {
        fatal_error( 'invalid_value', "$spam_question_txt{'answer'}" );
    }

    if ( $spam_image ne q{} ) {
        $spam_image = UploadFile('spam_image', 'Templates/Forum/default/Spam_Img', 'png jpg jpeg gif', '250', '0');
        unlink "$htmldir/Templates/Forum/default/Spam_Img/$cur_spam_image";
    }
    else {
        $spam_image = $cur_spam_image;
    }
    if ( $del_spam_image ) {
        unlink "$htmldir/Templates/Forum/default/Spam_Img/$cur_spam_image";
        $spam_image = q{};
    }

    fopen( SPAMQUESTIONS, "<$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    @spam_questions = <SPAMQUESTIONS>;
    fclose(SPAMQUESTIONS);

    @question = grep { !/$spam_question_id/xsm } @spam_questions;
    push @question, "$spam_question_id|$spam_question|$spam_answer|$spam_case|$spam_image";
    $question = join q{}, @question;

    fopen( SPAMQUESTIONS, ">$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    print {SPAMQUESTIONS} "$question\n" or croak "$croak{'print'} SPAMQUESTIONS";
    fclose(SPAMQUESTIONS);

    if ( $action eq 'spam_questions_edit2' ) {
        $yySetLocation = qq~$adminurl?action=spam_questions;questions_language=$FORM{'questions_language'}~;
        redirectexit();
    }
    return;
}

sub SpamQuestionsDelete {
    is_admin_or_gmod();

    fopen( SPAMQUESTIONS, "<$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    @spam_questions = <SPAMQUESTIONS>;
    fclose(SPAMQUESTIONS);

    fopen( SPAMQUESTIONS, ">$langdir/$questions_language/spam.questions" )
      || fatal_error( 'cannot_open', "$langdir/$questions_language/spam.questions",
        1 );
    print {SPAMQUESTIONS}
      grep { !/$FORM{'spam_question_id'}/xsm } @spam_questions
      or croak "$croak{'print'} SPAMQUESTIONS";
    fclose(SPAMQUESTIONS);

    foreach my $spam_image (@spam_questions) {
        chomp $spam_image;
        if ( $spam_image =~ /$FORM{'spam_question_id'}/xsm ) {
            $spam_image_delete = $spam_image;
            last;
        }
    }
    ( undef, undef, undef, undef, $spam_image ) = split /\|/xsm,
      $spam_image_delete;

    if ( $spam_image ) {
        unlink "$htmldir/Templates/Forum/default/Spam_Img/$spam_image";
    }

    if ( $action eq 'spam_questions_delete' ) {
        $yySetLocation = qq~$adminurl?action=spam_questions;questions_language=$FORM{'questions_language'}~;
        redirectexit();
    }
    return;
}

1;
