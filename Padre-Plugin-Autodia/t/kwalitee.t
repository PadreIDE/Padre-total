require Test::Kwalitee;

Test::Kwalitee->import( tests => [qw/
				      has_readme has_manifest has_changelog has_tests
				      proper_libs no_symlinks
				      has_test_pod has_test_pod_coverage
				    /] );
# TODO: use_strict coverage

