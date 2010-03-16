#!/usr/bin/perl -l

use CGI;

my $q = CGI->new;

open my $logfile,'>','padre_wherefrom.log';
print $logfile join("\t",time,$ENV{'HTTP_X_PADRE'},$q->param('from'));
close $logfile;

print <<_EOT_;
Content-type: text/plain

OK
_EOT_
