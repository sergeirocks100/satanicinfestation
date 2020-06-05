###############################################################################
# Settings_Antispam.pm                                                        #
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
use CGI::Carp qw(fatalsToBrowser);
use English qw(-no_match_vars);
our $VERSION = '2.6.11';

$settings_antispampmver = 'YaBB 2.6.11 $Revision: 1611 $';
if ( $action eq 'detailedversion' ) { return 1; }


# TSC
if ( -e "$vardir/spamrules.txt" ) {
    fopen( SPAM, "$vardir/spamrules.txt" )
      || fatal_error( 'cannot_open', 'spamrules.txt', 1 );

    $spamlist = do { local $INPUT_RECORD_SEPARATOR = undef; <SPAM> };
    fclose(SPAM);
}

# Email Domain Filter
if ( -e "$vardir/email_domain_filter.txt" ) {
    require "$vardir/email_domain_filter.txt";
}
$adomains =~ s/,/\n/gsxm;
$bdomains =~ s/,/\n/gxsm;

if ($min_reg_time eq q{}) {$min_reg_time = 15 ;}

# List of settings
our @settings = (
    {
        name  => $settings_txt{'generalspam'},
        id    => 'spam',
        items => [
            {
                description =>
qq~<label for="post_speed_count">$admin_txt{'91'}<br /><span class="small">$admin_txt{'91a'}</span></label>~,
                input_html =>
qq~<input type="text" name="post_speed_count" id="post_speed_count" size="5" value="$post_speed_count" />~,
                name     => 'post_speed_count',
                validate => 'number',
            },
            {
                description =>
qq~<label for="minlinkpost">$admin_txt{'minlinkpost'}<br /><span class="small">$admin_txt{'minlinkpost_exp'}</span></label>~,
                input_html =>
qq~<input type="text" name="minlinkpost" id="minlinkpost" size="5" value="$minlinkpost" />~,
                name     => 'minlinkpost',
                validate => 'number',
            },
            {
                description =>
qq~<label for="minlinksig">$admin_txt{'minlinksig'}<br /><span class="small">$admin_txt{'minlinksig_exp'}</span></label>~,
                input_html =>
qq~<input type="text" name="minlinksig" id="minlinksig" size="5" value="$minlinksig" />~,
                name     => 'minlinksig',
                validate => 'number',
            },
            {
                description =>
qq~<label for="minlinkweb">$admin_txt{'minlinkweb'}<br /><span class="small">$admin_txt{'minlinkweb_exp'}</span></label>~,
                input_html =>
qq~<input type="text" name="minlinkweb" id="minlinkweb" size="5" value="$minlinkweb" />~,
                name     => 'minlinkweb',
                validate => 'number',
            },
            {
                description =>
qq~<label for="spd_detention_time">$admin_txt{'92'}<br /><span class="small">$admin_txt{'93'}</span></label>~,
                input_html =>
qq~<input type="text" name="spd_detention_time" id="spd_detention_time" size="5" value="$spd_detention_time" />~,
                name     => 'spd_detention_time',
                validate => 'number',
            },
            {
                description =>
                  qq~<label for="timeout">$admin_txt{'408'}</label>~,
                input_html =>
qq~<input type="text" name="timeout" id="timeout" size="4" value="$timeout" />~,
                name     => 'timeout',
                validate => 'number',
            },
            {
                description => qq~<label for="min_reg_time">$admin_txt{'min_reg_time'}</label>~,
                input_html => qq~<input type="text" name="min_reg_time" id="min_reg_time" size="4" value="$min_reg_time" />~,
                name => 'min_reg_time',
                validate => 'number',
            },
            { header => $settings_txt{'speedban'}, },
            {
                description =>
                  qq~<label for="speedpostdetection">$admin_txt{'89'}</label>~,
                input_html =>
qq~<input type="checkbox" name="speedpostdetection" id="speedpostdetection" value="1" ${ischecked($speedpostdetection)}/>~,
                name     => 'speedpostdetection',
                validate => 'boolean',
            },
            {
                description =>
                  qq~<label for="min_post_speed">$admin_txt{'90'}</label>~,
                input_html =>
qq~<input type="text" name="min_post_speed" id="min_post_speed" size="5" value="$min_post_speed" />~,
                name       => 'min_post_speed',
                validate   => 'number',
                depends_on => ['speedpostdetection'],
            },
            { header => $settings_txt{'spambot'}, },
            {
                description =>
                  qq~<label for="honeypot">$admin_txt{'honeypot'}</label>~,
                input_html =>
qq~<input type="checkbox" name="honeypot" id="honeypot" value="1"${ischecked($honeypot)} />~,
                name     => 'honeypot',
                validate => 'boolean',
            },
            {
                description =>
                  qq~<label for="spamfruits">$admin_txt{'spamfruits'}</label>~,
                input_html =>
qq~<input type="checkbox" name="spamfruits" id="spamfruits" value="1"${ischecked($spamfruits)} />~,
                name     => 'spamfruits',
                validate => 'boolean',
            },
        ],
    },
    {
        name  => $tsc_txt{'2'},
        id    => 'tsc',
        items => [
            {
                description =>
qq~<label for="spamrules"><b>$tsc_txt{'4'}</b><br /><span class="small">$tsc_txt{'3'}</span></label>~,
                input_html =>
qq~<textarea cols="60" rows="35" name="spamrules" id="spamrules" style="width: 95%">$spamlist</textarea>~,
                two_rows => 1,
                name     => 'spamrules',
                validate => 'fulltext,null',
            },
        ],
    },
    {
        name  => $domain_filter_txt{'2'},
        id    => 'emailfilter',
        items => [
            {
                description =>
qq~<label for="adomains"><b>$domain_filter_txt{'4'}</b><br /><span class="small">$domain_filter_txt{'3'}</span></label>~,
                input_html =>
qq~<textarea cols="60" rows="35" name="adomains" id="adomains" style="width: 95%">$adomains</textarea>~,
                two_rows => 1,
                name     => 'adomains',
                validate => 'fulltext,null',
            },
            {
                description =>
qq~<label for="bdomains"><b>$domain_filter_txt{'6'}</b><br /><span class="small">$domain_filter_txt{'7'}</span></label>~,
                input_html =>
qq~<textarea cols="60" rows="35" name="bdomains" id="bdomains" style="width: 95%">$bdomains</textarea>~,
                two_rows => 1,
                name     => 'bdomains',
                validate => 'fulltext,null',
            },
        ],
    },
);

# Routine to save them
sub SaveSettings {
    my %settings = @_;

    # TSC
    $settings{'spamrules'} =~ s/\r(?=\n*)//gxsm;
    fopen( SPAM, ">$vardir/spamrules.txt" );
    print {SPAM} delete $settings{'spamrules'} or croak "$croak{'print'} SPAM";
    fclose(SPAM);

    # email domain filter
    my @domains =
      ( delete $settings{'adomains'}, delete $settings{'bdomains'} );
    foreach (@domains) {
        s/\n/,/gxsm;
        s/\s+//gxsm;
        s/(^,+|,+$)//gxsm;
        s/,+/,/gxsm;
        s/\@/\\@/gxsm;
    }
    fopen( FILE, ">$vardir/email_domain_filter.txt" );
    print {FILE} qq~\$adomains = "$domains[0]";\n~ or croak "$croak{'print'} emain_domain";
    print {FILE} qq~\$bdomains = "$domains[1]";\n~ or croak "$croak{'print'} email_domain";
    print {FILE} q~1;~                             or croak "$croak{'print'} email_domain";
    fclose(FILE);

    # Settings.pm
    SaveSettingsTo( 'Settings.pm', %settings );
    return;
}

1;
