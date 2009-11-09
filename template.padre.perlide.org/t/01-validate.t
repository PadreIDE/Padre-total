#!perl
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use Capture::Tiny qw(capture);
use File::Next qw();
use File::Which qw(which);
use Test::More;

# Skip means sweep bugs under the rug.
# I want this test to be actually run.
BAIL_OUT 'xmllint (part of the libxml2 package) not installed.'
  unless which 'xmllint';

my $destdir;
{
    my $runtime_params_file = '_build/runtime_params';
    my $runtime_params      = do $runtime_params_file;
    die "Could not load $runtime_params_file. Run Build.PL first.\n"
      unless $runtime_params;
    $destdir = $runtime_params->{destdir};
}

my $iter = File::Next::files({
        file_filter => sub {/\.html \z/msx},
        sort_files  => 1,
    },
    $destdir
);

my $file_counter;
while (defined(my $html_file = $iter->())) {
    $file_counter++;
    my (undef, $stderr) = capture {
        system qw(xmllint --noout), $html_file;
    };
    ok !$stderr, "$html_file validates";
    diag $stderr if $stderr;
}

done_testing($file_counter);
