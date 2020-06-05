###############################################################################
# Mailer.pm                                                                   #
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

$mailerpmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

$pre = q~style="padding:5px 40px; box-sizing:border-box; -moz-box-sizing:border-box; -webkit-box-sizing:border-box; display:block; white-space: pre-wrap; white-space: -moz-pre-wrap; white-space: -pre-wrap; white-space: -o-pre-wrap; word-wrap: break-word; width:100%; overflow-x:auto;"~;

sub sendmail {
    my ( $to, $subject, $message, $from, $mailcharset ) = @_;

    # Do a FromHTML here for $to, and for $mbname
    # Just in case has special chars like & in addresses
    FromHTML($to);
    FromHTML($mbname);

# Change commas to HTML entity - ToHTML doesn't catch this
# It's only a problem when sending emails, so no change to ToHTML.
# Changed to dash - &#144; misread in mail clients that use semi-colons as a delimiter
    $mbname =~ s/,/-/igsm;

    $charsetheader = $mailcharset ? $mailcharset : $yymycharset;

    if ( !$from ) {
        $from       = $webmaster_email;
        $fromheader = qq~"$mbname" <$from>~;
    }
    else {
        $fromheader = "$from";
    }

    if ( !$to ) {
        $to       = $webmaster_email;
        $toheader = "$mbname $smtp_txt{'555'} <$to>";
    }
    else {
        $to =~ s/[ \t]+/, /gsm;
        $toheader = $to;
    }

    $message =~ s/^\./../sm;
    $message =~ s/[\r\n]/\n/gsm;

    if ( $mailtype == 0 ) {
        my $mailprogram = qq~$mailprog -t~;
        open my $MAIL, q{|-}, $mailprogram or croak "$croak{'open'} MAIL";
        @mailout =
          ( $fromheader, $toheader, $subject, $message, $charsetheader );
        tomail( $MAIL, \@mailout );
        close $MAIL;    # or croak "$croak{'close'} MAIL";

        return 1;
    }
    elsif ( $mailtype == 1 ) {
        $smtp_to      = $to;
        $smtp_from    = $from;
        $smtp_message = qq~<pre $pre>$message</pre>~;
        $smtp_subject = $subject;
        $smtp_charset = $charsetheader;
        require Sources::Smtp;
        use_smtp();

    }
    elsif ( $mailtype == 2 || $mailtype == 3 ) {
        my @arg = ( "$smtp_server", Hello => "$smtp_server", Timeout => 30 );
        if ( $mailtype == 2 ) {
            eval q^
                use Net::SMTP;
                push @arg, Debug => 0;
                $smtp = Net::SMTP->new(@arg) || croak "Unable to create Net::SMTP object. Server: '$smtp_server'\n\n" . $OS_ERROR;
            ^;
        }
        else {
            eval q^
                use Net::SMTP::TLS;
                my $port = 25;
                if ($smtp_server =~ s/:(\d+)$//sm) { $port = $1; }
                push @arg, Port => $port;
                if ($authuser) { push @arg, User => "$authuser" ;}
                if ($authpass) { push @arg, Password => "$authpass" ;}
                $smtp = Net::SMTP::TLS->new(@arg) || croak "Unable to create Net::SMTP::TLS object. Server: '$smtp_server', port '$port'\n\n" . $OS_ERROR;
            ^;
        }
        if ($EVAL_ERROR) {
            fatal_error( 'net_fatal',
                "$error_txt{'error_verbose'}: $EVAL_ERROR" );
        }

        eval q^
            $smtp->mail($from);
            foreach (split /, /sm, $to) { $smtp->to($_); }
            $smtp->data();
            $smtp->datasend("To: $toheader\r\n");
            $smtp->datasend("From: $fromheader\r\n");
            $smtp->datasend("X-Mailer: YaBB Net::SMTP\r\n");
            $smtp->datasend("Subject: $subject\r\n");
            $smtp->datasend("Content-Type: text/html\; charset=$charsetheader\r\n");
            $smtp->datasend("\r\n");
            $smtp->datasend("<pre $pre>$message</pre>");
            $smtp->dataend();
            $smtp->quit();
        ^;
        if ($EVAL_ERROR) {
            fatal_error( 'net_fatal',
                "$error_txt{'error_verbose'}: $EVAL_ERROR" );
        }
        return 1;

    }
    elsif ( $mailtype == 4 ) {

        # Dummy mail engine
        fopen( MAIL, ">>$vardir/mail.log" );
        print {MAIL} 'Mail sent at ' . scalar gmtime() . "\n"
          or croak "$croak{'print'} mail";
        print {MAIL} "To: $toheader\n"     or croak "$croak{'print'} mail";
        print {MAIL} "From: $fromheader\n" or croak "$croak{'print'} mail";
        print {MAIL} "X-Mailer: YaBB Sendmail\n"
          or croak "$croak{'print'} mail";
        print {MAIL} "Subject: $subject\n\n" or croak "$croak{'print'} mail";
        $message =~ s/\r\n/\n/gsm;
        print {MAIL} "<pre $pre>$message</pre>\n"         or croak "$croak{'print'} mail";
        print {MAIL} "End of Message\n\n" or croak "$croak{'print'} mail";
        fclose(MAIL);
        return 1;
    }
    return;
}

# Before &sendmail is called, the message MUST be run through here.
# First argument is the message
# Second argument is a hashref to the replacements
# Example:
#  $message = qq~Hello, {yabb username}! The answer is {yabb answer}!~;
#  $message = &template_email($message, {username => $username, answer => 42});
# Result (with $username being the actual username):
#  Hello, $username! The answer is 42!
sub template_email {
    my ( $message, $info ) = @_;
    foreach my $key ( keys %{$info} ) {
        $message =~ s/{yabb $key}/$info->{$key}/gsm;
    }
    $message =~ s/{yabb scripturl}/$scripturl/gsm;
    $message =~ s/{yabb adminurl}/$adminurl/gsm;
    $message =~ s/{yabb mbname}/$mbname/gsm;
    return $message;
}

sub tomail {
    my ( $MAIL, $mailout ) = @_;
    my ( $fromheader, $toheader, $subject, $message, $charsetheader ) =
      @{$mailout};
    print {$MAIL} "To: $toheader\n"           or croak "$croak{'print'} mail";
    print {$MAIL} "From: $fromheader\n"       or croak "$croak{'print'} mail";
    print {$MAIL} "X-Mailer: YaBB Sendmail\n" or croak "$croak{'print'} mail";
    print {$MAIL} "Subject: $subject\n"       or croak "$croak{'print'} mail";
    print {$MAIL} "Content-Type: text/html\; charset=$charsetheader\n\n"
      or croak "$croak{'print'} mail";
    $message =~ s/\r\n/\n/gsm;
    print {$MAIL} "<pre $pre>$message</pre>\n" or croak "$croak{'print'} mail";
    return;
}

1;
