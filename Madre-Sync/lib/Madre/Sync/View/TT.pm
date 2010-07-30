package Madre::Sync::View::TT;

use strict;
use warnings;
use Catalyst::View::TT ();

our $VERSION = '0.01';
our @ISA     = 'Catalyst::View::TT';

__PACKAGE__->config( TEMPLATE_EXTENSION => '.tt' );

1;

__END__

=pod

=head1 NAME

Madre::Sync::View::TT - TT View for Madre::Sync

=head1 DESCRIPTION

TT View for Madre::Sync.

=head1 SEE ALSO

L<Madre::Sync>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Matthew Phillips E<lt>mattp@cpan.orgE<gt>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
