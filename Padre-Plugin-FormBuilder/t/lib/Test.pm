package t::lib::Test;

use strict;
use warnings;
use Test::Builder;
use Test::LongString;
use Exporter ();

our $VERSION = '0.68';
our @ISA     = 'Exporter';
our @EXPORT  = qw{ code compiles slurp };

sub code {
	my $left    = shift;
	my $right   = shift;
	if ( ref $left ) {
		$left = join '', map { "$_\n" } @$left;
	}
	if ( ref $right ) {
		$right = join '', map { "$_\n" } @$right;
	}
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is_string( $left, $right, $_[0] );
}

sub compiles {
	my $code = shift;
	if ( ref $code ) {
		$code = join '', map { "$_\n" } @$code;
	}
	SKIP: {
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		my $Test = Test::Builder->new;
		if ( $ENV{ADAMK_RELEASE} ) {
			$Test->ok( 1, "Skipped $_[0]" );
		} else {
			local $@;
			my $rv = do { eval "return 1;\n$code"; };
			$Test->diag( $@ ) if $@;
			$Test->ok( $rv, $_[0] );
		}
	}
}

# Provide a simple slurp implementation
sub slurp {
	my $file = shift;
	local $/ = undef;
	local *FILE;
	open( FILE, '<:utf8', $file ) or die "open($file) failed: $!";
	binmode( FILE, ':crlf' );
	my $text = <FILE>;
	close( FILE ) or die "close($file) failed: $!";
	return $text;
}

1;
