use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set AUTHOR_TESTS to enable this test' unless $ENV{AUTHOR_TESTS};

all_pod_coverage_ok();
