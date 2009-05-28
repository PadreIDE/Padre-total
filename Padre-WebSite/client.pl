use strict;
use warnings;

use LWP;
use HTTP::Request;
use YAML::Tiny;
use URI::Escape qw(uri_escape);


my %data = (
   hostid => 123,
   version => 3.12,
   OS => "Windows & co",
);
my $content = "hostid=$data{hostid}&data=" . uri_escape(YAML::Tiny::Dump(\%data));


my $request = HTTP::Request->new('POST', 'http://padre.local/cgi/collector.pl');
$request->header('Content-Type' => 'application/x-www-form-urlencoded');
$request->header('Content-Length' => length($content));
#print $content;
#__END__
$request->content($content);

#print $request->as_string;
#__END__
my $ua = LWP::UserAgent->new;
#my $response = $ua->get('http://padre.local/cgi/collector.pl?hostid=456');
my $response = $ua->request($request);
print $response->decoded_content; 


