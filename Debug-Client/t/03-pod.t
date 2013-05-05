#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use version;
use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;

my $requied_version_string = version->parse(1.46);

eval 'use Test::Pod';
my $found_version_string  = version->parse( $Test::Pod::VERSION );

my $comp = $found_version_string  <=> $requied_version_string ;

if ( $comp == -1 ){
	plan skip_all => "Test::Pod $requied_version_string required for testing POD I only found $found_version_string ";
}

all_pod_files_ok();

done_testing();

__END__

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;
use Test::Requires { 'Test::Pod' => 1.46 };

all_pod_files_ok();

done_testing();

__END__