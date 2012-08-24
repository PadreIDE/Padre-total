package Padre::Plugin::Nopaste::Task;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.4_1';

use Padre::Task ();
use Padre::Logger;

use App::Nopaste 'nopaste';
use App::Nopaste::Service::Shadowcat;

use parent qw{ Padre::Task };

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};
#######
# Default Constructor from Padre::Task POD
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# my $self = shift->SUPER::new(@_);

	# Assert required command parameter
	unless ( defined $self->{text} ) {
		die "Failed to provide any text to the Nopaste task\n";
	}

	return $self;
}



# sub prepare {
# my $self = @_;
# say 'task prepare';
# my $main    = $self->{document}->main;
# my $current = $main->current;
# my $editor  = $current->editor;
# return unless $editor;

# p $editor->GetSelectedText;
# p $editor->GetText;

# # no selection means send current file
# $self->{text} = $editor->GetSelectedText // $editor->GetText;

# p $self->{text};

# say 'errr';
# }

sub run {
	my $self = shift;

	say 'task run';

	$self->process();

	return 1;
}

sub process {
	my $self = shift;
	say 'start task process';

	# require App::Nopaste;

	# say $self->{text};

	# my $url = App::Nopaste::nopaste( $self->{text} );

	# say $url;

	# # show result in output section
	# if ( defined $url ) {
	# my $text = "Text successfully nopasted at: $url\n";
	# $self->{err}     = 0;
	# $self->{message} = $text;
	# } else {
	# my $text = "Error while nopasting text\n";
	# $self->{err}     = 1;
	# $self->{message} = $text;
	# }




	my $url = nopaste(

		# text => "Full text to paste (the only mandatory argument)",
		text => $self->{text},

		# desc          => "This is a test no-paste",
		nick => $self->{nick},

		# lang          => "perl",
		chan => "#padre",

		# private       => 1,                        # default: 0
		# this is the default, but maybe you want to do something different
		error_handler => sub {
			my ( $error, $service ) = @_;
			warn "$service: $error";
		},
		warn_handler => sub {
			my ( $warning, $service ) = @_;
			warn "$service: $warning";
		},

		# you may specify the services to use - but you don't have to
		services => [ "Shadowcat", ],

		# services => ["Shadowcat", "Gist"],
	);

	my $output;

	# # show result in output section
	if ( defined $url ) {
		$output          = "Text successfully nopasted at: $url\n";
		$self->{err}     = 0;
		$self->{message} = $output;
	} else {
		$output          = "Error while nopasting text\n";
		$self->{err}     = 1;
		$self->{message} = $output;
	}

	say $output;

	say 'end of task process';



	return;
}

1;

__END__

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
