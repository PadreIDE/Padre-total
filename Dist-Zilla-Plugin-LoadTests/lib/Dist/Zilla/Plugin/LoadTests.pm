package Dist::Zilla::Plugin::LoadTests;

# ABSTRACT: Common tests to test whether your module loads or not

use 5.008;
use strict;
use warnings;

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with 'Dist::Zilla::Role::FileMunger';


# -- attributes

has module => ( is => 'ro', predicate => 'has_module' );

# -- public methods

# called by the filemunger role
sub munge_file {
	my ( $self, $file ) = @_;

	return unless $file->name eq 't/00-load.t';

	
	my ($module, $ok, $fail) = ('', '## ', '');
	if( $self->has_module && $self->module ) {
		$module = $self->module;
		$ok = '';
		$fail = '## ';
	}

	# replace strings in the file
	my $content = $file->content;
	$content =~ s/LOADTESTS_MODULE/$module/g;
	$content =~ s/LOADTESTS_OK/$ok/g;
	$content =~ s/LOADTESTS_FAIL/$fail/g;
	$file->content($content);
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

In your dist.ini:

    [LoadTests]
    module = Your::Module

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * t/00-load.t - a standard test to check whether your module loads or not

This test will find check the module specified by C<module> and try to load it.

=back


This plugin accepts the following options:

=over 4

=item * module: a string of the module to check whether it loads or not. 
Required otherwise it will fail.

=back

=head1 SEE ALSO

L<Test::NeedsDisplay>
L<Dist::Zilla>

=cut

__DATA__
___[ t/00-load.t ]___
#!perl

use strict;
use warnings;

use Test::NeedsDisplay;
use Test::More;

plan tests => 1;

LOADTESTS_FAIL fail 'No module is specified!';
LOADTESTS_OK   use_ok('LOADTESTS_MODULE');
LOADTESTS_OK   diag("Testing $LOADTESTS_MODULE::VERSION, Perl $], $^X");