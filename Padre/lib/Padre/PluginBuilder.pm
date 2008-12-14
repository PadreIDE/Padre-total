package Padre::PluginBuilder;
use strict;
use warnings;
use Module::Build ();
our @ISA = ('Module::Build');

our $VERSION = '0.21';

=pod

=head1 NAME

Padre::PluginBuilder - Module::Build subclass for building Padre plugins

=head1 DESCRIPTION

This is a Module::Build subclass that can be used in place of L<Module::Build>
for the C<Build.PL> of Padre plugins. It adds two new build targets for
the plugins:

=head1 ADDITIONAL BUILD TARGETS

=head2 plugin

Generates a C<.par> file that contains all the plugin code. The name of the file
will be according to the plugin class name: C<Padre::Plugin::Foo> will result
in C<Foo.par>.

Installing the plugin (for the current architecture) will be as simple as copying
the generated C<.par> file into the C<plugins> directory of the user's Padre
configuration directory (which defaults to C<~/.padre> on Unixy systems).

=cut

sub ACTION_plugin {
	my ($self) = @_;

	# Need PAR::Dist
	if ( not eval { require PAR::Dist; PAR::Dist->VERSION(0.17) } ) {
		$self->log_warn( "In order to create .par files, you need to install PAR::Dist first." );
		return();
	}
	$self->depends_on( 'build' );
	my $module = $self->module_name();
	$module =~ s/^Padre::Plugin:://;
	$module =~ s/::/-/g;

	return PAR::Dist::blib_to_par(
		name => $self->dist_name,
		version => $self->dist_version,
		dist => "$module.par",
	);
}


=head2 installplugin

Generates the plugin C<.par> file as the C<plugin> target, but also installs it
into the user's Padre plugins directory.

=cut

sub ACTION_installplugin {
	my ($self) = @_;

	$self->depends_on( 'plugin' );

	my $module = $self->module_name();
	$module =~ s/^Padre::Plugin:://;
	$module =~ s/::/-/g;
	my $plugin = "$module.par";

	require Padre;
	my $plugin_dir = Padre::Config->default_plugin_dir;

	return $self->copy_if_modified(from => $plugin, to_dir => $plugin_dir);
}



1;

__END__

=pod

=head1 SEE ALSO

L<Padre>, L<Padre::Config>

L<Module::Build>

L<PAR> for more on the plugin system.

=head1 COPYRIGHT

Copyright 2008 Gabor Szabo.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

