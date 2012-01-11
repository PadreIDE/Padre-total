use Test::More tests => 1;

BEGIN {
	use_ok('Debug::Client');
}

diag("Info: Testing Debug::Client $Debug::Client::VERSION");
diag("Info: Perl version '$]'");

done_testing();

1;

__END__
