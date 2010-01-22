package Padre::Plugin::BadCode;

use 5.008;
use strict;
use warnings;
use utf8;
use Padre::Constant ();
use Padre::Plugin   ();
use Padre::Wx       ();
use Padre::Logger;

our $VERSION = '0.54';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub plugin_name {
	'Padre Developer BadCode Tools';
}

sub padre_interfaces {
	'Padre::Plugin' => 0.43;
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}

sub plugin_enable {
	my $self = shift;

	# Preload all of Padre
	require Padre;
	Padre->import(':everything');

	# Load Aspect support
	require Aspect;
	Aspect->import;

	# Create the aspect hooks
	my $self->{hook} = before {
		TRACE($_[0]->sub_name)
	} call qr/^Padre:.*:_?on_\w+\z/;

	return 1;
}

sub plugin_disable {
	my $self = shift;

	# Remove the aspect hooks
	delete $self->{hook};

	return 1;
}





#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Locate this plugin
	my $path = File::Spec->catfile(
		Padre::Constant::CONFIG_DIR,
		qw{ plugins Padre Plugin My.pm }
	);

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Padre Developer BadCode Tools');
	$about->SetDescription( <<"END_MESSAGE" );
Pay no attention to this plugin for now.

I'm just stashing this code here to prevent myself
accidentally leaving it somewhere by mistake

--ADAMK
END_MESSAGE

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::BadCode - Aspect-based plugin to detect badcode at run-time

=head1 DESCRIPTION

  Pay no attention to this plugin for now.
  
  I'm just stashing this code here to prevent myself
  accidentally leaving it somewhere by mistake
  
  --ADAMK

=head1 COPYRIGHT

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
