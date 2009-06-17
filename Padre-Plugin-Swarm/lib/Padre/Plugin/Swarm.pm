package Padre::Plugin::Swarm;

use 5.008;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Wx       ();
use Padre::Plugin   ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.24;
}

sub plugin_name {
	'Swarm!';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },
	];
}





#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Swarm Plugin');
	$about->SetDescription( <<"END_MESSAGE" );
Surrender to the Swarm!
END_MESSAGE

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Swarm - Experimental plugin for collaborative editing

=head1 DESCRIPTION

This is Swarm!

Swarm is a Padre plugin for experimenting with remote inspection,
peer programming and collaborative editing functionality.

Within this plugin all rules are suspended. No security, no efficiency,
no scalability, no standards compliance, remote code execution,
everything is allowed. The only goal is things that work, and things
that look shiny in a demo :)

Lessons learned here will be applied to more practical plugins later.

=head1 COPYRIGHT

Copyright 2009 The Padre develoment team as listed in Padre.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
