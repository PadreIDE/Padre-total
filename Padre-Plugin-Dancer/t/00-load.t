use Test::More tests => 1;

BEGIN {
    use_ok( 'Padre::Plugin::Dancer' );
}

diag("Info: Testing Padre::Plugin::Dancer $Padre::Plugin::Dancer::VERSION");

done_testing();

1;

__END__