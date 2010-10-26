package Dist::Zilla::Plugin::LoadTests;

# ABSTRACT: Common tests to test whether your module loads or not

use 5.008;
use strict;
use warnings;

use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';
with    'Dist::Zilla::Role::FileMunger';


# -- attributes

has module_name => ( is=>'ro', predicate=>'has_module_name' );

# -- public methods

# called by the filemunger role
sub munge_file {
    my ($self, $file) = @_;

    return unless $file->name eq 't/00-load.t';

    my $module_name = ( $self->has_module_name && $self->module_name )
        ? ''
        : '# no fake requested ##';

    # replace strings in the file
    my $content = $file->content;
    $content =~ s/LoadTests_MODULE_NAME/$module_name/;
    $file->content( $content );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

=head1 SYNOPSIS

In your dist.ini:

    [LoadTests]
    module_name      = Your::Module

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing
the following files:

=over 4

=item * t/00-load.t - a standard test to check whether your module loads or not

This test will find check the module specified by C<module_name> and try to load it.

=back


This plugin accepts the following options:

=over 4

=item * module_name: a string of the module to check whether it loads or not. No default.

=back

=cut

__DATA__
___[ t/00-load.t ]___
#!perl

use strict;

use Test::More;
use Test::NeedsDisplay;

plan tests => 1;

use_ok('LOAD_TESTS_MODULE_NAME');

diag("Testing LOAD_TESTS_MODULE_NAME $LOAD_TESTS_MODULE_NAME::VERSION, Perl $], $^X");