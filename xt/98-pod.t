use strict;
BEGIN {
	$^W = 1;
}
use Test::More;

# plan( skip_all => 'Author test. Set TEST_AUTHOR to a true value to run.' )
#     unless $ENV{TEST_AUTHOR};

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();


