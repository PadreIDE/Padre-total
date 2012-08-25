package Padre::Plugin::Nopaste::Task;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.4_1';

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
	unless ( defined $self->{text} ) {
		die "Failed to provide any text to the Nopaste task\n";
	}

	return $self;
}

#######
# Default run re: Padre::Task POD
#######
sub run {
	my $self = shift;

	# say 'start task process';

	my $url = nopaste(

		# text => "Full text to paste (the only mandatory argument)",
		text => $self->{text},

		# desc          => "This is a test no-paste",
		nick => $self->{nick},

		lang => "perl",
		chan => "#padre",

		# private       => 1,                        # default: 0
		# # this is the default, but maybe you want to do something different
		error_handler => sub {
			my ( $error, $service ) = @_;
			$self->{error}   = 1;
			$self->{message} = "$service: $error";

			# warn "$service: $error";
		},
		warn_handler => sub {
			my ( $warning, $service ) = @_;
			$self->{error}   = 1;
			$self->{message} = "$service: $warning";

			# warn "$service: $warning";
		},

		# you may specify the services to use - but you don't have to
		services => [ "Shadowcat", ],

		# services => ["Shadowcat", "Gist"],
	);

	# show result in output section
	if ( defined $url ) {
		my $text_output = "Text successfully nopasted at: $url\n";
		$self->{error}   = 0;
		$self->{message} = $text_output;
	}

	# else {
	# my $text_output = "Error while nopasting text\n";
	# $self->{err}     = 1;
	# $self->{message} = $text_output;
	# }

	# say 'end of task process';

	return;
}

1;

__END__

#####################

nopaste -L
Codepeek
Debian
Gist
PastebinCom
Pastie
Shadowcat
Snitch
Ubuntu
ssh


######################

=pod

=head1 NAME

Padre::Plugin::Nopaste::Task - Padre::Task subclass doing nopaste job

=head1 SYNOPSIS


=head1 DESCRIPTION

Async thread that does real nopaste

=head1 Standard Padre::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by C<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item * prepare()

=item * process()

=item * run()

=back

=head1 AUTHOR

Alexandr Ciornii, Jerome Quelin, C<< <jquelin@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
