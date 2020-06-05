###############################################################################
# YaBBC.pm                                                                    #
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

$yabbcpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

LoadLanguage('Post');

$yyYaBBCloaded = 1;

sub MakeSmileys {
    my ($inp) = @_;
    my $message = join q{}, $inp;
    my $i = 0;
    my @HTMLtags;
    while ( $message =~ s/(<.+?>)/[HTML$i]/sm ) { push @HTMLtags, $1; $i++; }

    $message =~ s~(\W|^)\[smil(ie|ey)=(\S+?\.(gif|jpg|png|bmp))\]~$1<img class="smil" data-rel="\[smil$2=$3\]" src="$yyhtml_root/Smilies/$3" alt="$post_txt{'287'}" title="$post_txt{'287'}" />~gism;
    $message =~ s~(\W|^);-?\)~$1<img class="smil" data-rel=";&#45;&#41;" src="$defaultimagesdir/wink.gif" alt="$post_txt{'292'}" title="$post_txt{'292'}" />~gsm;
    $message =~ s~(\W|^);D~$1<img class="smil" data-rel=";D" src="$defaultimagesdir/grin.gif" alt="$post_txt{'293'}" title="$post_txt{'293'}" />~gsm;
    $message =~ s~(\W|^):'\(~$1<img class="smil" data-rel="&#58;'&#40;" src="$defaultimagesdir/cry.gif" alt="$post_txt{'530'}" title="$post_txt{'530'}" />~gsm;
    $message =~ s~(\W|^):-/~$1<img class="smil" data-rel="&#58;&#45;/" src="$defaultimagesdir/undecided.gif" alt="$post_txt{'528'}" title="$post_txt{'528'}" />~gsm;
    $message =~ s~(\W|^):-X~$1<img class="smil" data-rel="&#58;&#45;X" src="$defaultimagesdir/lipsrsealed.gif" alt="$post_txt{'527'}" title="$post_txt{'527'}" />~gsm;
    $message =~ s~(\W|^):-\[~$1<img class="smil" data-rel="&#58;&#45;\[" src="$defaultimagesdir/embarassed.gif" alt="$post_txt{'526'}" title="$post_txt{'526'}" />~gsm;
    $message =~ s~(\W|^):-\*~$1<img class="smil" data-rel="&#58;&#45;\*" src="$defaultimagesdir/kiss.gif" alt="$post_txt{'529'}" title="$post_txt{'529'}" />~gsm;
    $message =~ s~(\W|^)&gt;:\(~$1<img class="smil" data-rel="&gt;:&#40;" src="$defaultimagesdir/angry.gif" alt="$post_txt{'288'}" title="$post_txt{'288'}" />~gsm;
    $message =~ s~(\W|^)::\)~$1<img class="smil" data-rel="&#58;&#58;&#41;" src="$defaultimagesdir/rolleyes.gif" alt="$post_txt{'450'}" title="$post_txt{'450'}" />~gsm;
    $message =~ s~(\W|^):P~$1<img class="smil" data-rel=":P" src="$defaultimagesdir/tongue.gif" alt="$post_txt{'451'}" title="$post_txt{'451'}" />~gsm;
    $message =~ s~(\W|^):-?\)~$1<img class="smil" data-rel="&#58;&#45;&#41;" src="$defaultimagesdir/smiley.gif" alt="$post_txt{'287'}" title="$post_txt{'287'}" />~gsm;
    $message =~ s~(\W|^):D~$1<img class="smil" data-rel="&#58;D" src="$defaultimagesdir/cheesy.gif" alt="$post_txt{'289'}" title="$post_txt{'289'}" />~gsm;
    $message =~ s~(\W|^):-?\(~$1<img class="smil" data-rel="&#58;&#45;&#40;" src="$defaultimagesdir/sad.gif" alt="$post_txt{'291'}" title="$post_txt{'291'}" />~gsm;
    $message =~ s~(\W|^):o~$1<img class="smil" data-rel="&#58;o" src="$defaultimagesdir/shocked.gif" alt="$post_txt{'294'}" title="$post_txt{'294'}" />~gism;
    $message =~ s~(\W|^)8-\)~$1<img class="smil" data-rel="8-&#41;" src="$defaultimagesdir/cool.gif" alt="$post_txt{'295'}" title="$post_txt{'295'}" />~gsm;
    $message =~ s~(\W|^):-\?~$1<img class="smil" data-rel="&#58;-\?" src="$defaultimagesdir/huh.gif" alt="$post_txt{'296'}" title="$post_txt{'296'}" />~gsm;
    $message =~ s~(\W|^)\^_\^~$1<img class="smil" data-rel="\^_\^" src="$defaultimagesdir/happy.gif" alt="$post_txt{'801'}" title="$post_txt{'801'}" />~gsm;
    $message =~ s~(\W|^):thumb~$1<img class="smil" data-rel="&#58;thumb" src="$defaultimagesdir/thumbup.gif" alt="$post_txt{'282'}" title="$post_txt{'282'}" />~gsm;
    $message =~ s~(\W|^)&gt;:-D~$1<img class="smil" data-rel="&gt;&#58;-D" src="$defaultimagesdir/evil.gif" alt="$post_txt{'802'}" title="$post_txt{'802'}" />~gsm;

    my $count = 0;
    while ($SmilieURL[$count]) {
        if ( $SmilieURL[$count] =~ /\//ixsm ) { $tmpurl = $SmilieURL[$count]; }
        else { $tmpurl = qq~$imagesdir/$SmilieURL[$count]~; }
        $tmpcode = $SmilieCode[$count];
        $tmpcode =~ s/&#36;/\$/gxsm;
        $tmpcode =~ s/&#64;/\@/gxsm;
        $message =~ s/\Q$tmpcode\E/<img class="smil" data-rel="$SmilieCode[$count]" src="$tmpurl" alt="$SmilieDescription[$count]" title="$SmilieDescription[$count]" \/>/gsm;
        $count++;
    }

    $i = 0;
    while ( $message =~ s/\[HTML$i\]/$HTMLtags[$i]/xsm ) { $i++; }

    return $message;
}

@ycssvalues  = qw ( quote quote2 );
$ycssnum     = 2;
$ycsscounter = 2;
$qid_cnt     = 0;

sub quotemsg {
    my ( $qauthor, $qlink, $qdate, $qmessage ) = @_;
    my ( $testauthor, $fqauthor );

    $qid = $qauthor . $qid_cnt;
    $qid_cnt++;

    if ($qauthor) {
        $usernames_life_quote{'temp_quote_autor'} =
          $qauthor;    # for display names in Quotes in LivePreview
        ToChars($qauthor);
        if ( !-e "$memberdir/$qauthor.vars" )
        {              # if the file is there it is an unencrypted user ID
            $qauthor = decloak($qauthor);

            # if not, decrypt it and see if it is a registered user
            if ( !-e "$memberdir/$qauthor.vars" )
            {          # if still not found probably the author is a screen name
                $testauthor = MemberIndex( 'check_exist', "$qauthor" );

                # check if this name exists in the memberlist
                if ( $testauthor ne q{} )
                {      # if it is, load the user id returned
                    $qauthor = $testauthor;
                    LoadUser($qauthor);
                    $fqauthor = ${ $uid . $qauthor }{'realname'};

                    # set final author var to the current users screen name
                }
                else {
                    $fqauthor = decloak($qauthor);

 # if all fails it is a non-existent real name so decode and assign as screenname
                }
            }
            else {
                LoadUser($qauthor);

# after encoding the user ID was found and loaded, setting the current real name
                $fqauthor = ${ $uid . $qauthor }{'realname'};
            }
        }
        else {
            LoadUser($qauthor);

# it was an old style user id which could be loaded and screen name set to final author
            $fqauthor = ${ $uid . $qauthor }{'realname'};
        }
        $qmessage =~ s/\/me\s+(.*?)(\n|\Z)(.*?)/<i><span class="my_me">* $fqauthor<\/span> $1<\/i>$2$3/igsm;
    }

    # next 2 lines: for display names in Quotes in LivePreview
    $usernames_life_quote{ $usernames_life_quote{'temp_quote_autor'} } =
      $fqauthor;
    delete $usernames_life_quote{'temp_quote_autor'};

    $qmessage = parseimgflash($qmessage);
    $qdate = timeformat($qdate,0,0,0,1);    # generates also the global variable $daytxt
    $cssbg = $ycssvalues[ ( $ycsscounter % $ycssnum ) ];
    $ycsscounter++;
    if ( $fqauthor eq q{} || $qlink eq q{} || $qdate eq q{} ) {
        $_ = $post_txt{'601'};
    }
    elsif ( $qlink eq 'impost' ) {
        $_ = $daytxt ? $post_txt{'600a_d'} : $post_txt{'600a'};
        $_ =~ s/AUTHOR2/$scripturl?action=viewprofile;username=$useraccount{$qauthor}/gxsm;
    }
    elsif ( $action ne 'imshow' && $action ne 'imsend' && $action ne 'imsend2' )
    {
        $_ = $daytxt ? $post_txt{'600_d'} : $post_txt{'600'};
    }
    else { $_ = $daytxt ? $post_txt{'599_d'} : $post_txt{'599'}; }
    $_ =~ s/AUTHOR/$fqauthor/gxsm;
    $_ =~ s/QUOTELINK/$scripturl?num=$qlink/gxsm;
    $_ =~ s/DATE/$qdate/gxsm;
    $_ =~ s/QUOTE/$qmessage/gxsm;
    $_ =~ s/QID/$qid/gxsm;
    $_ =~ s/QEND/<!--$qid-->/gxsm;
    return $_;
}

sub parseimgflash {
    my ($tmp_message) = @_;
    $tmp_message =~
s/\[flash\=(\S+?),(\S+?)](\S+?)\[\/flash\]/<b>$display_txt{'769'} ($1 x $2):<\/b> <a href="$3" target="_blank" onclick="window.open('$3', 'flash', 'resizable,width=$1,height=$2'); return false;">>$3<\/a>/gxsm;
    my $char_160  = chr 160;
    my $hardspace = q~&nbsp;~;
     if ( !$showimageinquote || ( ${ $uid . $username }{'hide_img'} && $user_hide_img ) ) {
        $tmp_message =~ s/\[img (.+?)\]/[img\]/igsm;
        $tmp_message =~ s/\[img\](?:\s|\t|\n|$hardspace|$char_160)*(http\:\/\/)*(.+?)(?:\s|\t|\n|$hardspace|$char_160)*\[\/img\]/\[url\]$1$2\[\/url\]/igsm;
    }
    return $tmp_message;
}

{
    my %killhash = (
        q{;}  => '&#059;',
        q{!}  => '&#33;',
        q{(}  => '&#40;',
        q{)}  => '&#41;',
        q{-}  => '&#45;',
        q{.}  => '&#46;',
        q{/}  => '&#47;',
        q{:}  => '&#58;',
        q{?}  => '&#63;',
        q{[}  => '&#91;',
        q{\\} => '&#92;',
        q{]}  => '&#93;',
        q{^}  => '&#94;',
        'D'   => '&#068;',
    );

    $codecnt = 0;

    sub codemsg {
        my ( $code, $class ) = @_;
        my @codeclass = (
            [
                'c++',        'css',    'html', 'java',
                'javascript', 'pascal', 'perl', 'php',
                'sql',
            ],
            [
                'sh_cpp',        'sh_css',    'sh_html', 'sh_java',
                'sh_javascript', 'sh_pascal', 'sh_perl', 'sh_php',
                'sh_sql',
            ],
            [
                ' (C++)',
                ' (CSS)',
                ' (HTML)',
                ' (Java)',
                ' (Javascript)',
                ' (Pascal)',
                ' (Perl)',
                ' (PHP)',
                ' (SQL)'
            ],
        );
        my $insclass = 'code';
        my $prclass  = q{};
        foreach my $i ( 0 .. 8 ) {
            my $img0 = $codeclass[0]->[$i];
            my $img1 = $codeclass[1]->[$i];
            my $img2 = $codeclass[2]->[$i];
            if ( lc $class eq $img0 ) {
                $insclass = $img1;
                $prclass  = $img2;
            }
        }
        ToChars($code);
        if ( $code !~ /&\S*;/gsm ) { $code =~ s/;/&#059;/gsm; }
        $code =~ s/([\(\)\-\:\\\/\?\!\]\[\.\^\.D])/$killhash{$1}/gxsm;
        $code =~ s/\&\#91\;highlight\&\#93\;(.*?)\&\#91\;\&\#47\;highlight\&\#93\;/<span class="highlight">$1<\/span>/isgxsm;
        $_ = $post_txt{'602'};

        # Thx. to Michael Prager for the improved Code boxes
        # count lines in code
        $linecount = () = $code =~ /\n/gxsm;

        # if more that 20 lines then limit code box height
        if ( $linecount > 20 ) {
            $height = 'height: 300px;';
        }
        else {
            $height = q{};
        }

        # try to display text as it was originally intended
        $code =~ s/ \&nbsp; \&nbsp; \&nbsp;/\t/igsm;
        $code =~ s/\&nbsp;/ /igxsm;
        $code =~ s/\s*?\n\s*?/\[code_br\]/igxsm;

        # we need to keep normal linebreaks inside <pre> tag
        $code =~ s/&quot;&gt;/\[code_qgt\]/igxsm;
        $codecnt++;
        if ( $guest_media_disallowed && $iamguest ) {
            $prselect = q{};
        }
        else {
            $prselect =
qq~<a href="javascript:selectAllCode($codecnt)"><img src="$imagesdir/codeselect.png" alt="$post_txt{'selectall'}" title="$post_txt{'selectall'}" /></a>~;
        }

        $code =
qq~<pre class="$insclass" id="code$codecnt" style="margin: 0px; width: 90%; $height overflow: scroll;">$code\[code_br][code_br]</pre>~;
        $_ =~ s/XSELECTX/$prselect/gxsm;
        $_ =~ s/XLANGX/$prclass/gxsm;
        $_ =~ s/CODE/$code/gxsm;
        return $_;
    }

    sub noparse {
        my ($noubbc) = @_;
        $noubbc =~ s/([!\(\)\-\.\/:\?\[\\\]\^D])/$killhash{$1}/gxsm;
        return $noubbc;
    }
}

sub imagemsg {
    my ( $rest, $attribut, $url, $type ) = @_;

    # use or kill urls
    $url =~ s/\[url\](.*?)\[\/url\]/$1/igxsm;
    $url =~ s/\[link\](.*?)\[\/link\]/$1/igxsm;
    $url =~ s/\[url\s*=\s*(.*?)\s*.*?\].*?\[\/url\]/$1/igxsm;
    $url =~ s/\[link\s*=\s*(.*?)\s*.*?\].*?\[\/link\]/$1/igxsm;
    $url =~ s/\[url.*?\/url\]//igxsm;
    $url =~ s/\[link.*?\/link\]//igxsm;

    my $char_160 = chr 160;
    $url =~ s/\s|\?|&nbsp;|$char_160//gxsm;

    if ( $url !~ /^http.+\.(gif|jpg|jpeg|png|bmp)$/ixsm ) {
        return $rest . $url;
    }

    my %parameter;
    FromHTML($attribut);
    $attribut =~ s/(\s|$char_160)+/ /gxsm;

    *altconv = sub {
        my ( $attfirst, $attalt, $attlast ) = @_;
        $attalt =~ s/\s/_/gxsm;
        $attfirst . qq~ alt=$attalt $attlast~;
    };
    $attribut =~ s/(.*?)alt=(.+?)(\s\S+=|\Z)/ altconv($1,$2,$3)/eisgxm;
    foreach ( split / +/sm, $attribut ) {
        my ( $key, $value ) = split /=/sm, $_;
        $value =~ s/["']//gxsm;    #" make my text editor happy;
        $parameter{$key} = $value;
    }

    my $use_greybox = $img_greybox;
    if (   $action eq 'ajxmessage'
        || $action eq 'ajximmessage'
        || $action eq 'ajxcal' )
    {
        $parameter{'name'} = q~class="liveimg" name="post_liveimg_resize"~;
        $use_greybox = 0;
    }
    elsif ( $action eq 'eventcal' ) {
        $parameter{'name'} = q~id="post_img_resize"~;
    }
    else {
        $parameter{'name'} =
          $type ? q~id="signat_img_resize"~ : q~id="post_img_resize"~;
    }

    $parameter{'alt'} =~ s/[<>"]/*/gxsm;
    $parameter{'alt'} =~ s/_/ /gxsm;
    if ( $url =~ /([^\/]+?)$/xsm ) {
        $parameter{'alt'} ||= $1;
    }
    $parameter{'align'}  =~ s/[^a-z]//igxsm;
    $parameter{'width'}  =~ s/\D//gxsm;
    $parameter{'height'} =~ s/\D//gxsm;
    if ( $parameter{'align'} ) {
        $parameter{'align'} = qq~ style="vertical-align:$parameter{'align'}"~;
    }
    if ( $parameter{'width'} ) {
        $parameter{'width'} = qq~ width="$parameter{'width'}"~;
    }
    if ( $parameter{'height'} ) {
        $parameter{'height'} = qq~ height="$parameter{'height'}"~;
    }

    my $linkedimg = $rest =~ /\[url[^\[]*\]\s*$/ism ? 1 : 0;
    return $rest
      . (
        ( !$linkedimg && $use_greybox )
        ? qq~<a href="$url" data-rel="gb_image[nice_pics]" title="$parameter{'alt'}">~
        : q{}
      )
      . qq~<img src="$url" $parameter{'name'} alt="$parameter{'alt'}" title="$parameter{'alt'}"$parameter{'align'}$parameter{'width'}$parameter{'height'} style="display:none" />~
      . ( ( !$linkedimg && $img_greybox ) ? '</a>' : q{} );
}

#greybox image bug fixed;
sub DoUBBC {
    my ($image_type) = @_;
    $ycsscounter = 2;
    if ( $ns eq 'NS' || $message =~ s/#nosmileys//isgm ) { return $message; }
    if ( ${ $uid . $username }{'hide_img'} && $user_hide_img ) { $message = parseimgflash($message); }
    $message =~ s/\[noparse\](.*?)(\[\/noparse\]|$)/noparse($1)/eisgm;
    $message =~ s/\[reason\](.+?)\[\/reason\]//igsm;
    $message =~ s/\[code\]/ \[code\]/igsm;
    $message =~ s/\[\/code\]/ \[\/code\]/igsm;
    $message =~ s/\[quote\]/ \[quote\]/igsm;
    $message =~ s/\[\/quote\]/ \[\/quote\]/igsm;
    $message =~ s/\[glow\]/ \[glow\]/igsm;
    $message =~ s/\[\/glow\]/ \[\/glow\]/igsm;
    $message =~ s/<br>|<br \/>/\n/igsm;
    $message =~ s/<br>\x1f|<br \/>\x1f/\n/igsm;
    $message =~ s/\[code\s*(.*?)\]\n*(.+?)\n*\[\/code\]/codemsg($2,$1)/eisgm;

    # [code] must come at first! At least before image transformation!
    $message =~ s/\[([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[$1$2\]/gsm;
    $message =~ s/\[\/([^\]\[]{0,30})\n([^\]\[]{0,30})\]/\[\/$1$2\]/gsm;

    #$message =~ s~(\w+://[^<>\s\n\"\]\[]+)\n([^<>\s\n\"\]\[]+)~$1\n$2~g;
    $message =~ s/\[b\](.*?)\[\/b\]/<b>$1<\/b>/isgm;
    $message =~ s/\[i\](.*?)\[\/i\]/<i>$1<\/i>/isgm;
    $message =~
      s/\[u\](.*?)\[\/u\]/<span class="u">$1<\/span><!--underline-->/isgm;
    $message =~
s/\[s\](.*?)\[\/s\]/<span style="text-decoration: line-through">$1<\/span><!--linethrough-->/isgm;
    $message =~ s/\[glb\](.*?)\[\/glb\]/<div class="glb">$1<\/div>/isgm;

#    $message =~
#s/( |&nbsp;)*\[move\](.*?)\[\/move\]/<div style="overflow: auto; overflow-style: marquee-line; white-space:nowrap">$2<\/div>/isg;
    $message =~
      s/( |&nbsp;)*\[move\](.*?)\[\/move\]/<marquee>$2<\/marquee>/isgm;
    # Quote message
    while ( $message =~
s/\[quote(\s+author=(.*?)\s+link=(.*?)\s+date=(.*?)\s*)?\]\n*(.*?)\n*\[\/quote\]/ quotemsg($2,$3,$4,$5) /eisgm ){}

# Images in message. Must come behind "Quote message" due to $showimageinquote in &quotemsg -> &parseimgflash
    while ( $message =~
s/(\[url[^\[]*\]\s*)?\[img(.*?)\](.*?)\[\/img\]/ imagemsg($1,$2,$3,$image_type) /eisgm ) { }

    $message =~
s/\[color=([A-Za-z0-9# ]+)\](.+?)\[\/color\]/<span style="color: $1;">$2<\/span><!--color-->/isgm;
    $message =~
      s/\[black\](.*?)\[\/black\]/<span style="color:#000000;">$1<\/span>/isgm;
    $message =~
      s/\[white\](.*?)\[\/white\]/<span style="color:#FFFFFF;">$1<\/span>/isgm;
    $message =~
      s/\[red\](.*?)\[\/red\]/<span style="color:#FF0000;">$1<\/span>/isgm;
    $message =~
      s/\[green\](.*?)\[\/green\]/<span style="color:#00FF00;">$1<\/span>/isgm;
    $message =~
      s/\[blue\](.*?)\[\/blue\]/<span style="color:#0000FF;">$1<\/span>/isgm;
    $message =~ s/\[timestamp\=([\d]{9,10})\]/timeformat($1)/eisgm;
    $message =~
s/\[font=([A-Za-z0-9# -]+)\](.+?)\[\/font\]/<span style="font-family: $1;">$2<\/span><!--font-->/isgm;

    while ( $message =~
        s/\[size=([A-Za-z0-9# ]+)\](.+?)\[\/size\]/sizefont($1,$2)/eisgm ) { }

    $message =~
      s/\[tt\](.*?)\[\/tt\]/<span style="font-family:monospace">$1<\/span>/isgm;
    $message =~
s/\[left\](.*?)\[\/left\]/<div style="text-align: left;">$1<\/div><!--left-->/isgm;
    $message =~
s/\[center\](.*?)\[\/center\]/<div style="text-align:center">$1<\/div>/isgm;
    $message =~
s/\[right\](.*?)\[\/right\]/<div style="text-align: right;">$1<\/div><!--right-->/isgm;
    $message =~
s/\[justify\](.*?)\[\/justify\]/<div style="text-align: justify">$1<\/div><!--justify-->/isgm;
    $message =~ s/\[sub\](.*?)\[\/sub\]/<sub>$1<\/sub>/isgm;
    $message =~ s/\[sup\](.*?)\[\/sup\]/<sup>$1<\/sup>/isgm;
    $message =~
s/\[fixed\](.*?)\[\/fixed\]/<span style="display:inline; font-family: Courier New;">$1<\/span>/isgm;

    $message =~ s/\[hr\]\n/<hr class="hr_s" \/>/gsm;
    $message =~ s/\[hr\]/<hr class="hr_s" \/>/gsm;
    $message =~ s/\[br\]/\n/igsm;
    $message =~
s/\s$YaBBversion\s/ \<a style\=\"font-weight: bold;\" href\=\"http\:\/\/www\.yabbforum\.com\/downloads\.php\"\>$YaBBversion Forum Software\<\/a\> /gxsm;

    $message =~
s/\[highlight\](.*?)\[\/highlight\]/<span class="highlight">$1<\/span><!--highlight-->/isgm;

    $message =~
      s/\[url=\s*(.+?)\s*\]\s*(.+?)\s*\[\/url\]/format_url2($1, $2)/eisgm;
    $message =~ s/\[url\]\s*(\S+?)\s*\[\/url\]/format_url3($1)/eisgm;

    if ($autolinkurls) {
        $message =~ s/\[url\]\s*([^\[]+)\s*\[\/url\]/[url]$1\[\/url]/gsm;
        $message =~ s/\[link\]\s*([^\[]+)\s*\[\/link\]/[link]$1\[\/link]/gsm;
        $message =~ s/\[news\](\S+?)\[\/news\]/<a href="$1">$1<\/a>/isgm;
        $message =~ s/\[gopher\](\S+?)\[\/gopher\]/<a href="$1">$1<\/a>/isgm;
        $message =~ s/&quot;&gt;/">/gxsm;                                     #"
        $message =~ s/(\[\*\])/ $1/gsm;
        $message =~ s/(\[\/list\])/ $1/gsm;
        $message =~ s/(\[\/td\])/ $1/gsm;
        $message =~ s/(\[\/td\])/ $1/gsm;
        $message =~ s/\<span style\=/\<span_style\=/gsm;
        $message =~ s/\<div style\=/\<div_style\=/gsm;
        $message =~
s/([^\w\"\=\[\]]|[\n\b]|\&quot\;|\[quote.*?\]|\[edit\]|\[highlight\]|\[\*\]|\[td\]|\A)\\*(\w+?\:\/\/(?:[\w\~\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\](?:\<\S+?\>\S+?\<\/\S+?\>)]+?)\.(?:[\w\~\.\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\]\x80-\xFF]{1,})+?)/format_url($1,$2)/eisgm;
        $message =~
s/([^\"\=\[\]\/\:\.\-(\:\/\/\w+)]|[\n\b]|\&quot\;|\[quote.*?\]|\[edit\]|\[highlight\]|\[\*\]|\[td\]|\A|\()\\*(www\.[^\.](?:[\w\~\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\](?:\<\S+?\>\S+?\<\/\S+?\>)]+?)\.(?:[\w\~\.\;\:\,\$\-\+\!\*\?\/\=\&\@\#\%\(\)\[\]\x80-\xFF]{1,})+?)/format_url($1,$2)/eisgm;
        $message =~ s/\<span_style\=/\<span style\=/gsm;
        $message =~ s/\<div_style\=/\<div style\=/gsm;
    }

    if ($stealthurl) {
        $message =~ s/\[url=\s*(\w+\:\/\/.+?)\](.+?)\s*\[\/url\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1" target="_blank">$2<\/a>/isgm;
        $message =~ s/\[url=\s*(.+?)\]\s*(.+?)\s*\[\/url\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/$1" target="_blank">$2<\/a>/isgm;
        $message =~ s/\[link\]\s*www\.\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/www.$1">www.$1<\/a>/isgm;
        $message =~ s/\[link=\s*(\w+\:\/\/.+?)\](.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1">$2<\/a>/isgm;
        $message =~ s/\[link=\s*(.+?)\]\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=http:\/\/$1">$2<\/a>/isgm;
        $message =~ s/\[link\]\s*(.+?)\s*\[\/link\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1">$1<\/a>/isgm;
        $message =~ s/\[ftp\]\s*(.+?)\s*\[\/ftp\]/<a href="$boardurl\/$yyexec.$yyext?action=dereferer;url=$1" target="_blank">$1<\/a>/isgm;
    }
    else {
        $message =~ s/\[url=\s*(\S\w+\:\/\/\S+?)\s*\](.+?)\[\/url\]/<a href="$1" target="_blank">$2<\/a>/isgm;
        $message =~ s/\[url=\s*(\S+?)\](.+?)\s*\[\/url\]/<a href="http:\/\/$1" target="_blank">$2<\/a>/isgm;
        $message =~ s/\[link\]\s*www\.(\S+?)\s*\[\/link\]/<a href="http:\/\/www.$1">www.$1<\/a>/isgm;
        $message =~ s/\[link=\s*(\S\w+\:\/\/\S+?)\s*\](.+?)\[\/link\]/<a href="$1">$2<\/a>/isgm;
        $message =~ s/\[link=\s*(\S+?)\](.+?)\s*\[\/link\]/<a href="http:\/\/$1">$2<\/a>/isgm;
        $message =~ s/\[link\]\s*(\S+?)\s*\[\/link\]/<a href="$1">$1<\/a>/isgm;
        $message =~ s/\[ftp\]\s*(ftp:\/\/)?(.+?)\s*\[\/ftp\]/<a href="ftp:\/\/$2">$1$2<\/a>/isgm;
    }

    $message =~ s/(dereferer\;url\=http\:\/\/.*?)#(\S+?\")/$1;anch=$2/isgm;
    $message =~ s/\[email\]\s*(\S+?\@\S+?)\s*\[\/email\]/<a href="mailto:$1">$1<\/a>/isgm;
    $message =~ s/\[email=\s*(\S+?\@\S+?)\](.*?)\[\/email\]/<a href="mailto:$1">$2<\/a>/isgm;

    *editsmsg = sub {
        my ($edittext) = @_;
        $formedit = qq~<b>$post_txt{'603'}: </b><br /><div class="editbg" style="overflow: auto;">$1</div><!--edit-->~;
        return $formedit;
    };
    while ( $message =~ s/\[edit\]\n*(.*?)\n*\[\/edit\]/editsmsg($1)/eisgm ) { }

    $message =~ s/\/me\s+(.*)/<span class="my_me">* $displayname<\/span> $1/igxsm;

    if ( $message =~ /\[media/sm || $message =~ /\[flash/sm ) {
        require Sources::MediaCenter;
        $message =~ s/\[flash\](.*?)\[\/flash\]/\[media\]$1\[\/media\]/isgm;

        # convert old flash tags to media tags
        while ( $message =~ s/\[flash\s*(.*?)\]\n*(.*?)\n*\[\/flash\]/flashconvert($2,$1)/eisgm ) { }
        # convert old flash tags to media tags
        while ( $message =~ s/\[media\]\n*(.*?)\n*\[\/media\]/embed($1)/eisgm ) { }
        while ( $message =~ s/\[media\s*(.*?)\]\n*(.*?)\n*\[\/media\]/embed($2,$1)/eisgm ){ }
        $message =~ s/media:/http:/igxsm;
    }

    if ( $guest_media_disallowed && $iamguest ) {
        if   ($action) { $act = qq~;sesredir=action\~$action~; }
        else           { $act = qq~;sesredir=num\~$curnum~; }
        my $oops =
qq~ <i>$maintxt{'41'} <a href="$scripturl?action=login$act"><b><i>$maintxt{'34'}</i></b></a></i>~;
       if ( $regtype ) {
           $oops .=
qq~<i> $maintxt{'42'} <a href="$scripturl?action=register"><b><i>$maintxt{'97'}</i></b></a></i>~;
        }
        $oops .= qq~<i> $maintxt{'42a'}</i>~;

        $showattach   = q{};
        $showattachhr = q{};
        $attachment =~ s/<a href=".+?<\/a>/[oops]/gsm;
        $attachment =~ s/<img src=".+?>/[oops]/gsm;
        $attachment =~ s/\[oops\]/$oops/gsm;
        if ( !$movedflag ) { $message =~ s/<a href=".+?<\/a>/[oops]/gsm; }
        $message =~ s/<img src=".+?>/[oops]/gsm;
        $message =~ s/\[oops\]/$oops/gsm;
    }

    $message = MakeSmileys($message);

    $message =~ s/\s*\[\*\]/<\/li><li>/isgm;
    $message =~ s/\[olist\]/<ol>/isgm;
    $message =~ s/\s*\[\/olist\]/<\/li><\/ol>/isgm;
    $message =~ s/<\/li><ol>/<ol>/isgm;
    $message =~ s/<ol><\/li>/<ol>/isgm;
    $message =~ s/\[list\]/<ul>/isgm;
    $message =~
s/\[list (.+?)\]/<ul style="list-style-image\: url($defaultimagesdir\/$1\.gif)">/isgm;
    $message =~ s/\s*\[\/list\]/<\/li><\/ul>/isgm;
    $message =~ s/<\/li><ul>/<ul>/isgm;
    $message =~ s/<ul><\/li>/<ul>/isgm;
    $message =~ s/<\/li><ul (.+?)>/<ul $1>/isgm;
    $message =~ s/<ul (.+?)><\/li>/<ul $1>/isgm;

    $message =~ s/\[pre\](.+?)\[\/pre\]/'<pre>' . dopre($1) . '<\/pre>'/isegm;

    if ( $message =~ m/\[table\](?:.*?)\[\/table\]/ism ) {
        while ( $message =~
s/<marquee>(.*?)\[table\](.*?)\[\/table\](.*?)<\/marquee>/<marquee>$1<table>$2<\/table>$3<\/marquee>/sm ) { }
        while ( $message =~
s/<marquee>(.*?)\[table\](.*?)<\/marquee>(.*?)\[\/table\]/<marquee>$1\[\/\/table\]$2<\/marquee>$3\[\/\/table\]/sm ) { }
        while ( $message =~
s/\[table\](.*?)<marquee>(.*?)\[\/table\](.*?)<\/marquee>/\[\/\/table\]$1<marquee>$2\[\/\/table\]$3<\/marquee>/sm ) { }
        $message =~
s/\n{0,1}\[table\]\n*(.+?)\n*\[\/table\]\n{0,1}/<table>$1<\/table>/isgm;
        while ( $message =~
s/\<table\>(.*?)\n*\[tr\]\n*(.*?)\n*\[\/tr\]\n*(.*?)\<\/table\>/<table>$1<tr>$2<\/tr>$3<\/table>/ism ) { }

        while ( $message =~
s/\<tr\>(.*?)\n*\[td\]\n{0,1}(.*?)\n{0,1}\[\/td\]\n*(.*?)\<\/tr\>/<tr>$1<td>$2<\/td>$3<\/tr>/ism ) { }
        $message =~
s/<table>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<tr>/<table><tr>/isgm;
        $message =~
s/<tr>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<td>/<tr><td>/isgm;
        $message =~
s/<\/td>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<td>/<\/td><td>/isgm;
        $message =~
s/<\/td>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<\/tr>/<\/td><\/tr>/isgm;
        $message =~
s/<\/td>((?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).*?)<td>/<\/td><td>/isgm;
        $message =~
s/<\/td>((?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).*?)<\/tr>/<\/td><\/tr>/isgm;
        $message =~
s/<\/tr>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<tr>/<\/tr><tr>/isgm;
        $message =~
s/<\/tr>((?:(?!<tr>|<\/tr>|<td>|<\/td>|<table>|<\/table>).)*)<\/table>/<\/tr><\/table>/isgm;
    }

    while ( $message =~ s/<a([^>]*?)\n([^>]*)>/<a$1$2>/sm ) { }
    while ( $message =~ s/<a([^>]*)>([^<]*?)\n([^<]*)<\/a>/<a$1>$2$3<\/a>/sm ) { }
    while ( $message =~ s/<a([^>]*?)&amp;([^>]*)>/<a$1&$2>/sm ) { }

    $message =~ s/\[\&table(.*?)\]/<table$1>/gsm;
    $message =~ s/\[\/\&table\]/<\/table>/gsm;
    $message =~ s/\n/<br \/>/igsm;
    $message =~ s/\[code_br\]/\n/igsm;
    $message =~ s/\[code_qgt\]/&quot;&gt;/igsm;

    return $message;
}

sub DoUBBCTo {

    # Does UBBC to $_[0] using DoUBBC and keeps $message the same
    ($message) = @_;
    my $messagecopy = $message;
    DoUBBC();
    my $returnthis = $message;
    $message = $messagecopy;
    return $returnthis;
}

1;
