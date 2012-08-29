package Padre::Plugin::Nopaste::Task;

use v5.10;
use strictures 1;

use Carp qw( croak );
our $VERSION = '0.04';

use Padre::Task   ();
use Padre::Unload ();
use App::Nopaste 'nopaste';
use parent qw{ Padre::Task };


#######
# Default Constructor from Padre::Task POD
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Assert required command parameter
	if ( not defined $self->{text} ) {
		croak "Failed to provide any text to the Nopaste task\n";
	}

	return $self;
}

#######
# Default run re: Padre::Task POD
#######
sub run {
	my $self = shift;

	my $url = nopaste(

		# text => "Full text to paste (the only mandatory argument)",
		text => $self->{text},

		# desc => "This is a test no-paste",
		nick => $self->{nick},
		lang => 'perl',

		# chan => '#padre',
		chan => $self->{channel},

		# private       => 1,                        # default: 0
		# # this is the default, but maybe you want to do something different
		
		error_handler => sub {
			my ( $error, $service ) = @_;
			$self->{error}   = 1;
			$self->{message} = "$service: $error";
		},
		warn_handler => sub {
			my ( $warning, $service ) = @_;
			$self->{error}   = 1;
			$self->{message} = "$service: $warning";
		},

		# you may specify the services to use - but you don't have to
		services => [ $self->{services}, ],
	);

	# show result in output section
	if ( defined $url ) {
		my $text_output = "Text successfully nopasted at: $url\n";
		$self->{error}   = 0;
		$self->{message} = $text_output;
	}

	return;
}

1;

__END__


=pod

=head1 NAME

Padre::Plugin::Nopaste::Task - Padre, The Perl IDE.

=head1 VERSION

version  0.04

=head1 SYNOPSIS

Perform the Nopaste Task as a background Job, help to keep Padre sweet.

=head1 DESCRIPTION

Async thread that does real nopaste

=head1 Standard Padre::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by L<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=head1 METHODS

=over 4

=item * new()

default Padre Task constructor, see Padre::Task POD

=item * run()

This is where all the work is done.

=back

=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre::Task, App::Nopaste

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::Nopaste>.

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Alexandr Ciornii,

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2012 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
