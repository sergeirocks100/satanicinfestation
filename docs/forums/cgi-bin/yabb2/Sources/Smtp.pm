###############################################################################
# Smtp.pm                                                                     #
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
use English '-no_match_vars';
our $VERSION = '2.6.11';

$smtppmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }

eval q{
    use IO::Socket::INET;
    use Digest::HMAC_MD5 qw(hmac_md5_hex);
};

LoadLanguage('Smtp');

sub use_smtp {
    my ($smtpaddr);
    $OUTPUT_AUTOFLUSH = 1;
    my ($proto) = ( getprotobyname 'tcp' )[2];
    my ($port) = ( getservbyname 'smtp', 'tcp' )[2] || 25;
    if ( $smtp_server =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/xsm ) {
        $smtpaddr =
          ( $smtp_server =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/xsm )
          ? pack( 'C4', $1, $2, $3, $4 )
          : ( gethostbyname $smtp_server )[4];
    }
    $sendlog = q{};
    $auth_ok = 0;

    # Connect to the SMTP server.
    $sock = IO::Socket::INET->new(
        PeerAddr => $smtp_server,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5
      )

      # Check if the service is available and parse any errors
      or fatal_error('smtp_unavail');

    get_line();
    say_hello($smtp_server) or exit 1;

    if ( defined( $features{'AUTH'} ) && $smtp_auth_required ) {

        # Try CRAM-MD5 if supported by the server
        if (
            $auth_ok == 0
            && (   $features{'AUTH'} =~ /CRAM-MD5/ixsm
                || $smtp_auth_required == 3
                || $smtp_auth_required == 4 )
          )
        {
            send_line("AUTH CRAM-MD5\r\n");
            ( $code, $text, $more ) = get_line();
            if ( $code != 334 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );

            }
            my $response = encode_cram_md5( $text, $authuser, $authpass );
            send_line( "%s\r\n", $response );
            ( $code, $text, $more ) = get_line();
            if ( $code != 235 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );
            }
            $auth_ok = 1;
        }

        # Or try LOGIN method
        elsif (
            $auth_ok == 0
            && (   $features{'AUTH'} =~ /LOGIN/ism
                || $smtp_auth_required == 2
                || $smtp_auth_required == 4 )
          )
        {
            send_line("AUTH LOGIN\r\n");
            ( $code, $text, $more ) = get_line();
            if ( $code != 334 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );
            }
            send_line( "%s\r\n", encode_smtp64( $authuser, q{} ) );

            ( $code, $text, $more ) = get_line();
            if ( $code != 334 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );
            }
            send_line( "%s\r\n", encode_smtp64( $authpass, q{} ) );
            ( $code, $text, $more ) = get_line();
            if ( $code != 235 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );
            }
            $auth_ok = 1;
        }

        # Or finally PLAIN if nothing else was supported.
        elsif (
            $auth_ok == 0
            && (   $features{'AUTH'} =~ /PLAIN/ism
                || $smtp_auth_required == 1
                || $smtp_auth_required == 4 )
          )
        {
            send_line( "AUTH PLAIN %s\r\n",
                encode_smtp64( "$authuser\0$authuser\0$authpass", q{} ) );
            ( $code, $text, $more ) = get_line();
            if ( $code != 235 && $smtp_auth_required != 4 ) {
                fatal_error( 'smtp_error',
"[$code]: $smtp_txt{$code}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
                );
            }
            $auth_ok = 1;
        }

        # Decide to complain about advertised methods not supported.
        else {
            fatal_error( 'smtp_error',
"$smtp_txt{'notsupported'}<br /><br /><b>$smtp_txt{'5'}</b><br />$sendlog"
            );
        }
    }

    # build the Date per RFC822 - uses gmtime to create date & time stamp
    (
        $smtpsec,  $smtpmin,  $smtphour, $smtpmday, $smtpmon,
        $smtpyear, $smtpwday, $smtpyday, $smtpisdst
    ) = gmtime( $date );
    $smtpyear = sprintf '%02d', ( $smtpyear - 100 );
    $smtphour = sprintf '%02d', $smtphour;
    $smtpmin  = sprintf '%02d', $smtpmin;
    $smtpsec  = sprintf '%02d', $smtpsec;
    my @months2 = qw(
      Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
    );
    $smtpyear = qq~20$smtpyear~;
    $smtptimestring =
qq~$days_short[$smtpwday], $smtpmday $months2[$smtpmon] $smtpyear $smtphour\:$smtpmin\:$smtpsec +0000~;

    # Fill the mail from field
    send_line("MAIL FROM: <$smtp_from>\r\n");
    ( $code, $text, $more ) = get_line();

    # Add as many addressees as needed
    foreach ( split /,\ /xsm, $smtp_to ) {
        send_line("RCPT TO: <$_>\r\n");
        ( $code, $text, $more ) = get_line();
    }

    # Send message data
    send_line("DATA\r\n");
    ( $code, $text, $more ) = get_line();
    send_line("To: $toheader\r\n");
    send_line("Date: $smtptimestring\r\n");
    send_line("From: $fromheader\r\n");
    send_line("X-Mailer: YaBB SMTP\r\n");
    send_line("Subject: $smtp_subject\r\n");
    send_line("Content-Type: text/plain\; charset=$smtp_charset\r\n\r\n");
    send_line("$smtp_message");
    send_line("\r\n.\r\n");

    # It is polite to close the door behind you
    send_line("QUIT\r\n");
    if ( $smtp_from eq q{} ) { $proto_error = "$smtp_txt{'no_from'}<br />"; }
    if ( $smtp_to eq q{} ) { $proto_error .= "$smtp_txt{'no_to'}<br />"; }
    if ($proto_error) {
        fatal_error( 'smtp_error', "<br />$proto_error<br />$sendlog" );
    }
    return 1;
}

# Get one line of response from the server.
sub get_line {
    my ( $code, $sep, $text ) = ( $sock->getline() =~ /(\d+)(.)([^\r]*)/xsm );
    my $more;
    $code =~ s/ //gsm;
    if   ( $sep eq q{-} ) { $more = 1; }
    else                  { $more = 0; }
    $sendlog .= qq~S:$code $text $sep~;
    $sendlog .= q~<br />~;
    return ( $code, $text, $more );
}

# Send one line back to the server
sub send_line (@) {
    my @args = @_;

    #   $args[0] =~ s/\n/\r\n/gsm;
    $sendlog .= qq~C:$args[0]~;
    $sendlog =~ s/\r\n//gxsm;
    $sendlog .= q~<br />~;
    $sock->printf(@args);
    return;
}

# Helper function to encode CRAM-MD5 challenge
sub encode_cram_md5 ($$$) {
    my ( $ticket64, $username, $password ) = @_;
    my $ticket = decode_smtp64($ticket64)
      or die "Unable to decode Base64 encoded string '$ticket64'\n";

    my $password_md5 = hmac_md5_hex( $ticket, $password );
    return encode_smtp64( "$username $password_md5", q{} );
}

sub encode_smtp64 {
    my ( $inp, $eol ) = @_;
    if ( $] >= 5.006 ) {
        require bytes;
        if ( bytes::length($inp) > length($inp)
            || ( $] >= 5.008 && $inp =~ /[^\0-\xFF]/xsm ) )
        {
            require Carp;
            Carp::croak('The Base64 encoding is only defined for bytes');
        }
    }
    require integer;
    import integer;
    if ( !defined $eol ) { $eol = "\n"; }

    my $res = pack 'u', $inp;

    # Remove first character of each line, remove newlines
    $res =~ s/^.//gxsm;
    $res =~ s/\n//gxsm;
    $res =~ tr|` -_|AA-Za-z0-9+/|;    # `# help emacs
                                      # fix padding at the end
    my $padding = ( 3 - length($inp) % 3 ) % 3;
    if ($padding) { $res =~ s/.{$padding}$/q{=} x $padding/exsm; }

    # break encoded string into lines of no more than 76 characters each
    if ( length $eol ) {
        $res =~ s/(.{1,76})/$1$eol/gxsm;
    }
    chomp $res;
    return $res;
}

sub decode_smtp64 ($) {
    local $WARNING = 0;    # unpack("u",...) gives bogus warning in 5.00[123]
    require integer;
    import integer;

    my $str = shift;
    $str =~ tr|A-Za-z0-9+=/||cd;    # remove non-base64 chars
    $str =~ s/=+$//xsm;             # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;    # convert to uuencoded format
    if ( !length $str ) { return q{}; }

    my $uustr = q{};
    my $l     = length($str) - 60;
    foreach my $i ( 0 .. $l ) {
        if ( $i % 60 == 0 ) {
            $uustr .= 'M' . substr $str, $i, 60;
        }
    }
    $str = substr $str, $i;

    # and any leftover chars
    if ( $str ne q{} ) {
        $uustr .= chr( 32 + length($str) * 3 / 4 ) . $str;
    }
    return unpack 'u', $uustr;
}

sub say_hello ($) {
    my ($hello_host) = @_;
    my ( $feat, $param );

    #send RFC2821 compliant identifyer
    send_line("EHLO $hello_host\r\n");
    ( $code, $text, $more ) = get_line();
    if ( $code != 250 ) {

        #try sending an old RFC281 compliant identifyer (older Exchange servers)
        send_line("HELO $hello_host\r\n");
    }
    ( $code, $text, $more ) = get_line();
    if ( $code == 250 ) {
        read_features( \%features );
    }
    return 1;
}

sub read_features ($) {
    my ($featref) = @_;

    # Empty the hash
    %{$featref} = ();
    ( $feat, $param ) = ( $text =~ /^(\w+)[= ]*(.*)$/xsm );
    $featref->{$feat} = $param;

    # Load all features presented by the server into the hash
    while ( $more == 1 ) {
        ( $code, $text, $more ) = get_line();
        ( $feat, $param ) = ( $text =~ /^(\w+)[= ]*(.*)$/xsm );
        $featref->{$feat} = $param;
    }
    return 1;
}

1;
