package Perl::Dist::Padre;

=pod

=head1 NAME

Perl::Dist::Padre - Padre Standalone for Win32 (EXPERIMENTAL)

=head1 DESCRIPTION

This is the distribution builder used to create Padre Standalone for Win32.

=head1 Building Padre Standalone

Unlike Strawberry, Padre Standalone does not have a standalone build script.

To build Padre Standalone, run the following.

  perldist Padre

=cut

use 5.008;
use strict;
use warnings;
use Perl::Dist::Strawberry ();

our $VERSION = '0.25';
our @ISA     = 'Perl::Dist::Strawberry';





######################################################################
# Configuration

sub new {
	shift->SUPER::new(
		app_id            => 'padre',
		app_name          => 'Padre Standalone Win32',
		app_publisher     => 'Padre',
		app_publisher_url => 'http://padre.perlide.org/',
		image_dir         => 'C:\\padre',

		# Build both exe and zip versions
		exe               => 1,
		zip               => 1,
		@_,
	);
}

sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name . ' ' . $_[0]->perl_version_human . ' Alpha 1';
}

sub output_base_filename {
	$_[0]->{output_base_filename} or
	'padre-standalone-' . $_[0]->perl_version_human . '-alpha-1';
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	die "Perl 5.8.8 is not available in Chocolate Perl";
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		App::Ack
		Class::Adapter
		Class::Autouse
		Class::Unload
		Class::XSAccessor
		Devel::Dumpvar
		Encode
		File::Copy::Recursive
		File::ShareDir
		File::ShareDir::PAR
		IPC::Cmd
		IPC::Run
		Module::Inspector
		Module::Refresh
		Module::Starter
		ORLite
		ORLite::Migrate
		PPI
		Parse::ErrorString::Perl
		Pod::POM
		Pod::Simple
		Pod::Simple::XHTML
		Text::Diff
		Text::FindIndent
		threads
		threads::shared
		Thread::Queue
		Clone
		List::MoreUtils
		Task::Weaken
		Test::Object
		Class::Inspector
		Config::Tiny
		Hook::LexWrap
	} );

	# The rest of the modules are order-specific,
	# for reasons maybe involving CPAN.pm but not fully understodd.

	# Install the Alien module
	$self->install_module( name => 'Alien::wxWidgets'        );

	# Install the Wx module over the top of alien module
	$self->install_module( name => 'Wx'                      );

	# Install modules that add more Wx functionality
	$self->install_module( name => 'Wx::Perl::ProcessStream' );
	$self->install_module( name => 'Wx::Perl::Dialog'        );

	# And finally, install Padre itself
	$self->install_module( name => 'Padre'                   );

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre>

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
