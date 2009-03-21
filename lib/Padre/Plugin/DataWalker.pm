package Padre::Plugin::DataWalker;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::DataWalker - Simple Perl data structure browser Padre

=head1 SYNOPSIS

Use this like any other Padre plugin. To install
Padre::Plugin::DataWalker for your user only, you can
type the following in the extracted F<Padre-Plugin-DataWalker-...>
directory:

  perl Makefile.PL
  make
  make test
  make installplugin

Afterwards, you can enable the plugin from within Padre
via the menu I<Plugins-E<gt>Plugin Manager> and there click
I<enable> for I<DataWalker>.

=head1 DESCRIPTION

TODO to be written

=cut


sub padre_interfaces {
	'Padre::Plugin' => 0.24,
}

sub plugin_name {
	'DataWalker';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'             => sub { $self->show_about },
		'Browse Padre IDE object' => sub { $self->browse_padre },
	];
}

sub browse_padre {
	my $self = shift;
        require Wx::Perl::DataWalker;
        
        my $dialog = Wx::Perl::DataWalker->new(
          {data => Padre->ide},
          undef,
          -1,
          Wx::wxDefaultPosition,
	  [750, 700], # FIXME Why doesn't the damn thing honour this?
        );
        $dialog->Show(1);
        return();
}



sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::DataWalker");
	$about->SetDescription( <<"END_MESSAGE" );
Simple Perl data structure browser for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

1;

__END__


=head1 AUTHOR

Steffen Mueller, C<< <smueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
