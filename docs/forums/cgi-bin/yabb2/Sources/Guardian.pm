###############################################################################
# Guardian.pm                                                                 #
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
# use strict;
# use warnings;
no warnings qw(uninitialized once redefine);
use CGI::Carp qw(fatalsToBrowser);
our $VERSION = '2.6.11';

$guardianpmver = 'YaBB 2.6.11 $Revision: 1611 $';

$not_from   = qq~$webmaster_email~;
$not_to     = qq~$webmaster_email~;

sub guard {
    if ( !$use_guardian ) { return; }

    # Proxy Blocker
    $proxy0 = get_remote_addr();
    $proxy1 = get_x_ip_client();
    $proxy2 = get_x_forwarded();
    $proxy3 = get_http_via();

    @white_list = split /\|/xsm, $whitelist;
    foreach (@white_list) {
        chomp $_;
        if (
            (
                   $proxy0 =~ m/$_/xsm
                || $proxy1 =~ m/$_/xsm
                || $proxy2 =~ m/$_/xsm
                || $proxy3 =~ m/$_/xsm
                || $username eq $_
            )
            && $_ ne q{}
          )
        {
            $whitelisted = 1;
            last;
        }
    }
    if (   $disallow_proxy_on
        && !$whitelisted
        && !$iamadmin
        && ( $proxy1 ne 'empty' || $proxy2 ne 'empty' || $proxy3 ne 'empty' ) )
    {
        if ($disallow_proxy_notify) {
            LoadLanguage('Guardian');
			$abuse_time = timeformat($date, 1, 'rfc', 1);
            $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'proxy_abuse'} $guardian_txt{'abuse'}~;
            $not_body =
qq~$guardian_txt{'proxy_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
            $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
            $not_body .=
qq~$guardian_txt{'abuse_ip'}: (REMOTE_ADDR)->$proxy0, (X_IP_CLIENT)->$proxy1, (HTTP_X_FORWARDED_FOR)->$proxy2, (HTTP_VIA)->$proxy3\n~;
            if (   $use_htaccess
                && $disallow_proxy_htaccess
                && !$iamadmin
                && !$iamgmod )
            {
                $not_body .= qq~$guardian_txt{'htaccess_added'}: $user_ip,\n\n~;
            }
            $not_body .= qq~$mbname, $guardian_txt{'main'}~;
            $not_subject =~ s/\&trade\;//gxsm;
            $not_body    =~ s/\&trade\;//gxsm;
            $not_body = qq~<pre>$not_body</pre>~;
            guardian_notify( $not_to, $not_subject, $not_body, $not_from );
        }
        if (   $use_htaccess
            && $disallow_proxy_htaccess
            && !$iamadmin
            && !$iamgmod )
        {
            update_htaccess( 'add', $user_ip );
        }
        fatal_error('proxy_reason');
    }

    # Basic Value Setup
    $remote = get_ip();
    if ( index $remote, q{, } ) {
        @remotes = split /\, /sm, $remote;
        if (   $remotes[0] ne 'unknown'
            && $remotes[0] ne 'empty'
            && $remotes[0] ne '127.0.0.1'
            && $remotes[0] ne q{} )
        {
            $remote = $remotes[0];
        }
        else {
            $remote = $remotes[1];
        }
    }
    $querystring = get_query_string();

    # Check for Referer
    if ($referer_on) {
        @refererlist = split /\|/xsm, lc $banned_referers;
        $streferer = lc get_referer();
        foreach (@refererlist) {
            chomp $_;
            if ( $streferer =~ m/$_/xsm && $_ ne q{} ) {
                LoadLanguage('Guardian');
				$abuse_time = timeformat($date, 1, 'rfc', 1);
                if ($referer_notify) {
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'referer_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'referer_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $referer_htaccess
                        && !$iamadmin
                        && !$iamgmod )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .=
                      qq~$guardian_txt{'abuse_referer'}: $streferer\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $referer_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error('referer_reason');
            }
        }
    }

    # Check for Harvester
    if ($harvester_on) {
        @harvesterlist = split /\|/xsm, lc $banned_harvesters;
        $agent = lc get_user_agent();
        foreach (@harvesterlist) {
            chomp $_;
            if ( $agent =~ m/$_/xsm && $_ ne q{} ) {
                if ($harvester_notify) {
                    LoadLanguage('Guardian');
					$abuse_time = timeformat($date, 1, 'rfc', 1);
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'harvester_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'harvester_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $harvester_htaccess
                        && !$iamadmin
                        && !$iamgmod )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .=
                      qq~$guardian_txt{'abuse_harvester'}: $agent\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $harvester_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error('harvester_reason');
            }
        }
    }

    # Check for Request
    if ($request_on) {
        @requestlist = split /\|/xsm, lc $banned_requests;
        $method = lc get_request_method();
        foreach (@requestlist) {
            chomp $_;
            if ( $method =~ m/$_/xsm && $_ ne q{} ) {
                if ($request_notify) {
                    LoadLanguage('Guardian');
					$abuse_time = timeformat($date, 1, 'rfc', 1);
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'request_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'request_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $request_htaccess
                        && !$iamadmin
                        && !$iamgmod )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .=
                      qq~$guardian_txt{'abuse_request'}: $method\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $request_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error('request_reason');
            }
        }
    }

    # Check for Strings
    if ($string_on) {
        require Sources::SubList;
        my ( $temp_query, $testkey );
        $temp_query = lc $querystring;
        @stringlist = split /\|/xsm, lc $banned_strings;
        foreach (@stringlist) {
            chomp $_;
            foreach my $testkey ( keys %director )
            { ## strip off all existing command strings from the temporary query ##
                chomp $testkey;
                $temp_query =~ s/$testkey//gxsm;
            }
            if ( $temp_query =~ m/$_/xsm && $_ ne q{} ) {
                if ($string_notify) {
                    LoadLanguage('Guardian');
					$abuse_time = timeformat($date, 1, 'rfc', 1);
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'string_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'string_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $string_htaccess
                        && !$iamadmin
                        && !$iamgmod
                        && $action ne 'downloadfile' )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .= qq~$guardian_txt{'abuse_string'}: $_\n~;
                    $not_body .=
                      qq~$guardian_txt{'abuse_environment'}: $querystring\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $string_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error( 'string_reason', "($_)" );
            }
        }
    }

    # Check for UNION attack (for MySQL database protection only)
    if ($union_on) {
        if (   $querystring =~ m/%20union%20/xsm
            || $querystring =~ m/\*\/union\/\*/xsm )
        {
            if ($union_notify) {
                LoadLanguage('Guardian');
				$abuse_time = timeformat($date, 1, 'rfc', 1);
                $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'union_abuse'} $guardian_txt{'abuse'}~;
                $not_body =
qq~$guardian_txt{'union_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                if (   $use_htaccess
                    && $union_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    $not_body .=
                      qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                }
                $not_body .=
                  qq~$guardian_txt{'abuse_environment'}: $querystring\n\n~;
                $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                $not_subject =~ s/\&trade\;//gxsm;
                $not_body    =~ s/\&trade\;//gxsm;
                guardian_notify( $not_to, $not_subject, $not_body, $not_from );
            }
            if ( $use_htaccess && $union_htaccess && !$iamadmin && !$iamgmod ) {
                update_htaccess( 'add', $user_ip );
            }
            fatal_error('union_reason');
        }
    }

    # Check for CLIKE attack (for MySQL database protection only)
    if ($clike_on) {
        if ( $querystring =~ m/\/\*/xsm ) {
            if ($clike_notify) {
                LoadLanguage('Guardian');
				$abuse_time = timeformat($date, 1, 'rfc', 1);
                $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'clike_abuse'} $guardian_txt{'abuse'}~;
                $not_body =
qq~$guardian_txt{'clike_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                if (   $use_htaccess
                    && $clike_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    $not_body .=
                      qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                }
                $not_body .=
                  qq~$guardian_txt{'abuse_environment'}: $querystring\n\n~;
                $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                $not_subject =~ s/\&trade\;//gxsm;
                $not_body    =~ s/\&trade\;//gxsm;
                guardian_notify( $not_to, $not_subject, $not_body, $not_from );
            }
            if ( $use_htaccess && $clike_htaccess && !$iamadmin && !$iamgmod ) {
                update_htaccess( 'add', $user_ip );
            }
            fatal_error('clike_reason');
        }
    }

    # Check for SCRIPTING attack
    if ($script_on) {
        while ( ( $key, $secvalue ) = each %INFO ) {
            $secvalue = lc $secvalue;
            str_replace( '%3c', '<', $secvalue );
            str_replace( '%3e', '>', $secvalue );
            if (   ( $secvalue =~ m/<[^>]script*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*object*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*iframe*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*applet*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*meta*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*style*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]*form*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/\([^>]*\"?[^)]*\)/xsm )
                || ( $secvalue =~ m/\"/xsm ) )
            {    #";
                if ($script_notify) {
                    LoadLanguage('Guardian');
					$abuse_time = timeformat($date, 1, 'rfc', 1);
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'script_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'script_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $script_htaccess
                        && !$iamadmin
                        && !$iamgmod )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .=
                      qq~$guardian_txt{'abuse_url_environment'}: $secvalue\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $script_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error('script_reason');
            }
        }
        while ( ( $key, $secvalue ) = each %FORM ) {
            $secvalue = lc $secvalue;
            if (    $key eq 'message'
                and $action =~ /^(post|modify|imsend|eventcal)2$/xsm )
            {
                $secvalue =~ s/\[code.*?\/code\]//gsxm;
            }
            if (    $key eq 'message'
                and $action =~ /^(ajxmessage|ajximmessage|ajxcal)$/xsm )
            {
                $secvalue =~ s/\[code.*?\/code\]//gsxm;
            }
            str_replace( '%3c', '<', $secvalue );
            str_replace( '%3e', '>', $secvalue );
            if (   ( $secvalue =~ m/<[^>]script*\"?[^>]*>/xsm )
                || ( $secvalue =~ m/<[^>]style*\"?[^>]*>/xsm ) )
            {
                if ($script_notify) {
                    LoadLanguage('Guardian');
					$abuse_time = timeformat($date, 1, 'rfc', 1);
                    $not_subject =
qq~$guardian_txt{'main'}-($mbname): $guardian_txt{'script_abuse'} $guardian_txt{'abuse'}~;
                    $not_body =
qq~$guardian_txt{'script_abuse'} $guardian_txt{'abuse'} $maintxt{'30'} $abuse_time\n\n~;
                    $not_body .=
qq~$guardian_txt{'abuse_user'}: $username -> (${$uid.$username}{'realname'})\n~;
                    $not_body .= qq~$guardian_txt{'abuse_ip'}: $user_ip\n~;
                    if (   $use_htaccess
                        && $script_htaccess
                        && !$iamadmin
                        && !$iamgmod )
                    {
                        $not_body .=
                          qq~$guardian_txt{'htaccess_added'}: $user_ip,\n~;
                    }
                    $not_body .=
qq~$guardian_txt{'abuse_form_environment'}: $secvalue\n\n~;
                    $not_body .= qq~$mbname, $guardian_txt{'main'}~;
                    $not_subject =~ s/\&trade\;//gxsm;
                    $not_body    =~ s/\&trade\;//gxsm;
                    guardian_notify( $not_to, $not_subject, $not_body,
                        $not_from );
                }
                if (   $use_htaccess
                    && $script_htaccess
                    && !$iamadmin
                    && !$iamgmod )
                {
                    update_htaccess( 'add', $user_ip );
                }
                fatal_error('script_reason');
            }
        }
    }
    return;
}

sub guardian_notify {
    my ( $to, $subject, $body, $from ) = @_;
    require Sources::Mailer;
    my $result = sendmail( $to, $subject, $body, $from );
    return;
}

sub get_remote_port {
    if ( $ENV{'REMOTE_PORT'} ) {
        return $ENV{'REMOTE_PORT'};
    }
    else {
        return 'empty';
    }
}

sub get_request_method {
    if ( $ENV{'REQUEST_METHOD'} ) {
        return $ENV{'REQUEST_METHOD'};
    }
    else {
        return 'empty';
    }
}

sub get_script_name {
    if ( $ENV{'SCRIPT_NAME'} ) {
        return $ENV{'SCRIPT_NAME'};
    }
    else {
        return 'empty';
    }
}

sub get_http_host {
    if ( $ENV{'HTTP_HOST'} ) {
        return $ENV{'HTTP_HOST'};
    }
    else {
        return 'empty';
    }
}

sub get_query_string {
    if ( $ENV{'QUERY_STRING'} ) {
        my $tempstring = str_replace( '%09', '%20', $ENV{'QUERY_STRING'} );
        return str_replace( '%09', '%20', $ENV{'QUERY_STRING'} );
    }
    else {
        return 'empty';
    }
}

sub get_user_agent {
    if ( $ENV{'HTTP_USER_AGENT'} ) {
        return $ENV{'HTTP_USER_AGENT'};
    }
    else {
        return 'empty';
    }
}

sub get_referer {
    if ( $ENV{'HTTP_REFERER'} ) {
        return $ENV{'HTTP_REFERER'};
    }
    else {
        return 'empty';
    }
}

sub get_ip {
    $client_ip   = get_client_ip();      ## HTTP_CLIENT_IP
    $x_forwarded = get_x_forwarded();    ## HTTP_X_FORWARDED_FOR
    $x_ip_client = get_x_ip_client();    ## X_IP_CLIENT
    $http_via    = get_http_via();       ## HTTP_VIA
    $remote_addr = get_remote_addr();    ## REMOTE_ADDR
    if (   $client_ip
        && $client_ip !~ m/empty/sm
        && $client_ip !~ m/unknown/sm )
    {
        return $client_ip;
    }
    elsif ($x_forwarded
        && $x_forwarded !~ m/empty/sm
        && $x_forwarded !~ m/unknown/sm )
    {
        return $x_forwarded;
    }
    elsif ($x_ip_client
        && $x_ip_client !~ m/empty/sm
        && $x_ip_client !~ m/unknown/sm )
    {
        return $x_ip_client;
    }
    elsif ($http_via
        && $http_via !~ m/empty/sm
        && $http_via !~ m/unknown/sm )
    {
        return $http_via;
    }
    elsif ($remote_addr
        && $remote_addr !~ m/empty/sm
        && $remote_addr !~ m/unknown/sm )
    {
        return $remote_addr;
    }
    else {
        return 'empty';
    }
}

sub get_client_ip {
    if ( $ENV{'HTTP_CLIENT_IP'} && $ENV{'HTTP_CLIENT_IP'} ne '127.0.0.1' ) {
        return $ENV{'HTTP_CLIENT_IP'};
    }
    else {
        return 'empty';
    }
}

sub get_x_ip_client {
    if ( $ENV{'X_CLIENT_IP'} && $ENV{'X_CLIENT_IP'} ne '127.0.0.1' ) {
        return $ENV{'X_CLIENT_IP'};
    }
    else {
        return 'empty';
    }
}

sub get_http_via {
    if ( $ENV{'HTTP_VIA'} && $ENV{'HTTP_VIA'} ne '127.0.0.1' ) {
        return $ENV{'HTTP_VIA'};
    }
    else {
        return 'empty';
    }
}

sub get_x_forwarded {
    if (   $ENV{'HTTP_X_FORWARDED_FOR'}
        && $ENV{'HTTP_X_FORWARDED_FOR'} ne '127.0.0.1' )
    {
        return $ENV{'HTTP_X_FORWARDED_FOR'};
    }
    else {
        return 'empty';
    }
}

sub get_remote_addr {
    if ( $ENV{'REMOTE_ADDR'} ) {
        return $ENV{'REMOTE_ADDR'};
    }
    else {
        return 'empty';
    }
}

sub str_replace {
    my ( $org, $repl, $target ) = @_;
    $target =~ s/$org/$repl/igxsm;
    return $target;
}

sub update_htaccess {
    my ( $action, $value ) = @_;
    my ( $htheader, $htfooter, @denies, @htout );
    if ( !$action ) { return 0; }
    fopen( HTA, '.htaccess' );
    my @htlines = <HTA>;
    fclose(HTA);

# header to determine only who has access to the main script, not the admin script
    $htheader = q~<Files YaBB*>~;
    $htfooter = q~</Files>~;
    $start    = 0;
    foreach (@htlines) {
        chomp $_;
        if ( $_ eq $htheader ) { $start = 1; }
        if ( $start == 0 && $_ !~ m/#/xsm && $_ ne q{} ) {
            push @htout, "$_\n";
        }
        if ( $_ eq $htfooter ) { $start = 0; }
        if ( $start == 1 && $_ =~ s/Deny from //gsm ) {
            push @denies, $_;
        }
    }
    if ( $use_htaccess && $action eq 'add' ) {
        fopen( HTA, '>.htaccess' );
        print {HTA} '# Last modified by The Guardian: '
          . timeformat( $date, 1 )
          . " #\n\n"
          or croak "$croak{'print'} HTA";
        print {HTA} @htout or croak "$croak{'print'} HTA";
        if ($value) {
            print {HTA} "\n$htheader\n" or croak "$croak{'print'} HTA";
            push @denies, $value;
            foreach (@denies) {
                print {HTA} "Deny from $_\n"
                      or croak "$croak{'print'} HTA";
            }
            print {HTA} "$htfooter\n" or croak "$croak{'print'} HTA";
        }
        fclose(HTA);
    }
    return;
}

1;
