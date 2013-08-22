#!/usr/bin/env perl
# The above shebang is for "perlbrew", otherwise use /usr/bin/perl
#
# Please refer to the Plain Old Documentation (POD) at the end of this Perl Script for further information

use strict;
use Carp;
use Pod::Usage;
use Getopt::Long;
use LW2;    # http://sourceforge.net/projects/whisker/ v2.2.5

my $VERSION = "0.0_2"; # May be required to upload script to CPAN i.e. http://www.cpan.org/scripts/submitting.html

print "\n\"Speculum\" Alpha v$VERSION\n";
print "\n";
print "Copyright 2013 Christian Heinrich\n";
print "Licensed under the Apache License, Version 2.0\n\n";

# Command line meta-options
my $usage;
my $man;
my $update;

# Command line arguments for web server
my $www;
my $disallow;

# TODO Display -usage if command line argument(s) are incorrect
GetOptions(
    "www=s"    => \$www,
    "disallow" => \$disallow,

	# Command line meta-options
	# version is excluded as it is printed prior to processing the command line arguments
	# verbose is excluded as output is less then 25 lines
    "usage"  => \$usage,
    "man"    => \$man,
    "update" => \$update
);

if ( ( $usage eq 1 ) or ( $man eq 1 ) ) {
    pod2usage( -verbose => 2 );
    die();
}

if ( $update eq 1 ) {
    print "Please execute \"git pull\" from the command line\n";
    die();
}

my $response_code;
my $html_data;

# TODO Replace "stage" numbering i.e. Line #54 of https://github.com/cmlh/Speculum/commit/182a07a969d8e669fb4db4ad4633c519e9e3221d#L52
print "Downloading http://$www/robots.txt\n";

( $response_code, $html_data ) = LW2::get_page("http://$www/robots.txt");

if ( $response_code != 200 ) {
    print "There was an error\n";
    print "$www HTTP Status Code: $response_code\n";
    exit;
}

my @Allow;
my @Disallow;
my @Sitemap;
my @Useragent;

foreach my $line ( split /\n/, $html_data ) {
    if ( $line =~ "Allow:" ) {
        push( @Allow, $line );
    }
    if ( $line =~ "Disallow:" ) {
        push( @Disallow, $line );
    }
    if ( $line =~ "Sitemap:" ) {
        push( @Sitemap, $line );
    }

    if ( $line =~ "User-agent:" ) {
        push( @Useragent, $line );
    }

# TODO Raise exception if $line is not Allow:, Disallow:, Sitemap or User_agent:
}

my $robots_dot_txt_file = "$www-robots.txt";

$response_code =
  LW2::get_page_to_file( "http://$www/robots.txt", $robots_dot_txt_file );

print "\"robots.txt\" saved as $robots_dot_txt_file\n";

proxy_requests( "Allow:", \@Allow, $www );

if ( $disallow != "0" ) {
    proxy_requests( "Disallow:", \@Disallow, $www );
}

print "Done\n";

sub proxy_requests {
    my %_request;
    LW2::http_init_request( \%_request );
    $_request{'whisker'}->{'host'}       = "$www";
    $_request{'whisker'}->{'proxy_host'} = "127.0.0.1";
    $_request{'whisker'}->{'proxy_port'} = "8080";
    my $_www = $_[2];
    print "Sending $_[0] URIs of $_www to web proxy i.e. 127.0.0.1:8080\n";

    # TODO refactor as sub()
    my @_uris = @{ $_[1] };
    foreach my $_uri (@_uris) {
        my @_uri = split( / /, $_uri );
        $_request{'whisker'}->{'uri'} = "$_uri[1]";
        LW2::http_fixup_request( \%_request );
        my %_response;
        if ( LW2::http_do_request( \%_request, \%_response ) ) {
            ##error handling
            print 'ERROR: ', $_response{'whisker'}->{'error'}, "\n";
            print $_response{'whisker'}->{'data'}, "\n";
        }
        print "\t $_uri[1] sent\n";
    }
}

=head1 NAME

speculum.pl

=head1 VERSION

This documentation refers to speculum.pl Alpha v$VERSION

=head1 CONFIGURATION

=head1 USAGE

speculum.pl -www [Fully Qualified Domain Name (FQDN)]

=head1 REQUIRED ARGUEMENTS

-www [(FQDN)]  Fully Qualified Domain Name (FQDN) of web server.
 				
=head1 OPTIONAL ARGUEMENTS

-disallow      Make HTTP Request based on Disallow: directive(s)

-man           Displays POD and exits.
-usage         Displays POD and exits.
-update        Displays the git command to retrieve the latest update from @GitHub

=head1 DESCRIPTION

Makes HTTP Requests via an (intercepting) proxy based on the directives of webroot/robots.txt  

=head1 DEPENDENCIES

LW2 i.e. http://sourceforge.net/projects/whisker/ 

=head1 PREREQUISITES

=head1 COREQUISITES

=head1 OSNAMES

osx

=head1 SCRIPT CATEGORIES

Web

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please refer to the comments beginning with "TODO" in the Perl Code.

=head1 AUTHOR

Christian Heinrich

=head1 CONTACT INFORMATION

http://cmlh.id.au/contact

=head1 MAILING LIST

=head1 REPOSITORY

https://github.com/cmlh/speculum

=head1 FURTHER INFORMATION AND UPDATES

http://cmlh.id.au/tagged/speculum
http://del.icio.us/cmlh/speculum

=head1 LICENSE AND COPYRIGHT

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 

Copyright 2013 Christian Heinrich
