package Perl::Dist::Padre;

#<<<
use 5.008001;
use strict;
use warnings;
use Perl::Dist::Strawberry 1.11139 qw(); # To allow 1.11_14 for right now.
use URI::file                      qw();
use English                        qw( -no_match_vars );
use File::Spec::Functions          qw( catfile        );

our $VERSION = '0.270';
our @ISA     = 'Perl::Dist::Strawberry';
#>>>




######################################################################
# Configuration

sub new {
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Padre');


	shift->SUPER::new(
		app_id            => 'padre',
		app_name          => 'Padre Standalone Plus Six',
		app_publisher     => 'Padre',
		app_publisher_url => 'http://padre.perlide.org/',
		image_dir         => 'C:\strawberry',

		# Set e-mail to something Padre-specific.
		perl_config_cf_email => 'padre-dev@perlide.org',

		msi_product_icon => catfile( $dist_dir, 'padre.ico' ),
		msi_help_url     => undef,
		msi_banner_top   => catfile( $dist_dir, 'PadreBanner.bmp' ),
		msi_banner_side  => catfile( $dist_dir, 'PadreDialog.bmp' ),

		# Program version.
		build_number => 1,

		# Trace level.
		trace => 1,

		# Build both exe and zip versions
		msi => 1,
		zip => 1,

		# Tell it what additions to the directory tree to use.
		msi_directory_tree_additions => [ qw (
			  perl\site\lib\Algorithm
			  perl\site\lib\App
			  perl\site\lib\Class
			  perl\site\lib\Class\XSAccessor
			  perl\site\lib\CPAN\Mini
			  perl\site\lib\Data
			  perl\site\lib\Devel
			  perl\site\lib\File\Find
			  perl\site\lib\File\Find\Rule
			  perl\site\lib\Module
			  perl\site\lib\ORLite
			  perl\site\lib\Text
			  perl\site\lib\Wx
			  perl\site\lib\Wx\Perl
			  perl\site\lib\Padre
			  perl\site\lib\Padre\Plugin
			  perl\site\lib\Perl
			  perl\site\lib\Perl6
			  perl\site\lib\Perl6\Perldoc
			  perl\site\lib\Perl6\Perldoc\To
			  perl\site\lib\Sub
			  perl\site\lib\YAML\Dumper
			  perl\site\lib\YAML\Loader
			  perl\site\lib\auto\Algorithm
			  perl\site\lib\auto\Class
			  perl\site\lib\auto\Class\XSAccessor
			  perl\site\lib\auto\Data
			  perl\site\lib\auto\Devel
			  perl\site\lib\auto\File\Find
			  perl\site\lib\auto\File\Find\Rule
			  perl\site\lib\auto\File\ShareDir
			  perl\site\lib\auto\Module
			  perl\site\lib\auto\ORLite
			  perl\site\lib\auto\Padre
			  perl\site\lib\auto\Perl
			  perl\site\lib\auto\Perl6
			  perl\site\lib\auto\Perl6\Perldoc
			  perl\site\lib\auto\Readonly
			  perl\site\lib\auto\Sub
			  perl\site\lib\auto\Test\Pod
			  perl\site\lib\auto\Text
			  perl\site\lib\auto\Wx
			  perl\site\lib\auto\Wx\Perl
			  perl\site\lib\auto\share\dist
			  perl\site\lib\auto\share\dist\Padre
			  perl\site\lib\auto\share\dist\Padre\icons
			  perl\site\lib\auto\share\dist\Padre\icons\padre
			  perl\site\lib\auto\share\dist\Padre\icons\padre\16x16
			  perl\site\lib\auto\share\dist\Perl6-Doc
			  perl\site\lib\auto\share\module
			  )
		],

		@_,
	);

	return;
} ## end sub new

sub app_ver_name {
	return $_[0]->{app_ver_name}
	  or $_[0]->app_name . q{ }
	  . $_[0]->perl_version_human . q{.}
	  . $_[0]->build_number
	  . ( $_[0]->beta_number ? ' Beta ' . $_[0]->beta_number : q{} );
}

sub output_base_filename {

#	$_[0]->{output_base_filename} or
#	'padre-standalone'
#		. '-' . $_[0]->perl_version_human
#		. '.' . $_[0]->build_number
#		. ($_[0]->beta_number ? '-beta-' . $_[0]->beta_number : '')
	return 'almost-six-0.41';
}





#####################################################################
# Customisations for Perl assets

sub install_perl_588 {
	my $self = shift;
	PDWiX->throw('Perl 5.8.8 is not available in Padre Standalone');
	return;
}

sub install_perl_589 {
	my $self = shift;
	PDWiX->throw('Perl 5.8.9 is not available in Padre Standalone');
	return;
}

sub install_perl_5101 {
	my $self = shift;
	PDWiX->throw('Perl 5.10.1 is not available in Padre Standalone');
	return;
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);

	# Manually install our non-Wx dependencies first to isolate
	# them from the Wx problems
	$self->install_modules( qw{
		  File::Glob::Windows
		  File::Next
		  App::Ack
		  Class::Adapter
		  Class::Inspector
		  Class::Unload
		  AutoXS::Header
		  Class::XSAccessor
		  Devel::Dumpvar
		  File::Copy::Recursive
		  File::ShareDir
		  File::ShareDir::PAR
		  Test::Object
		  Config::Tiny
		  Test::ClassAPI
		  Clone
		  Hook::LexWrap
		  Test::SubCalls
		  List::MoreUtils
		  Task::Weaken
		  PPI
		  Module::Refresh
		  Devel::Symdump
		  Pod::Coverage
		  Test::Pod::Coverage
		  Test::Pod
		  Module::Starter
		  ORLite
		  ORLite::Migrate
		  Algorithm::Diff
		  Text::Diff
		  Test::Differences
		  File::Slurp
		  Pod::POM
		  Parse::ErrorString::Perl
		  Text::FindIndent
		  Pod::Abstract
		  Devel::StackTrace
		  Class::Data::Inheritable
		  Exception::Class
		  Test::Most
		  Class::XSAccessor::Array
		  Parse::ExuberantCTags
		  CPAN::Mini
		  Portable
		  Win32API::File
		  Capture::Tiny
		  prefork
		  PPIx::EditorTools
	} );

	# Install the dependencies for Padre::Plugin::Perl6
	$self->install_modules( qw{
		  Locale::Msgfmt
		  Perl6::Perldoc
		  Perl6::Perldoc::To::Ansi
		  Perl6::Doc
		  Log::Trace
		  Test::Assertions::TestScript
		  Pod::Xhtml
		  Pod::Text::Ansi
		  IO::Interactive
		  App::Grok
		  Sub::Install
		  Data::OptList
		  Sub::Exporter
		  Scope::Guard
		  Devel::GlobalDestruction
		  Sub::Name
		  Algorithm::C3
		  Class::C3
		  MRO::Compat
		  YAML::Syck
		  Class::MOP
		  Moose
		  Syntax::Highlight::Perl6
		  Perl6::Refactor
	} );

	# The rest of the modules are order-specific,
	# for reasons maybe involving CPAN.pm but not fully understodd.

	# Install the Alien module
	if ( defined $ENV{PERL_DIST_PADRE_ALIENWXWIDGETS_PAR_LOCATION} ) {
		my $filelist = $self->install_par(
			name => 'Alien_wxWidgets',
			url  => URI::file->new(
				$ENV{PERL_DIST_PADRE_ALIENWXWIDGETS_PAR_LOCATION}
			  )->as_string(),
		);
		$self->insert_fragment( 'Alien_wxWidgets', $filelist->files );
	} else {
		$self->install_module( name => 'Alien::wxWidgets' );
	}

	# Install the Wx module over the top of alien module
	$self->install_module( name => 'Wx' );

	# Install modules that add more Wx functionality
	$self->install_module( name => 'Wx::Perl::ProcessStream' );

	# And finally, install Padre itself
	$self->install_module(
		name  => 'Padre',
		force => 1,
	);

	# Last, but least, install Padre::Plugin::Perl6
	$self->install_module( name => 'Padre::Plugin::Perl6' );

	return 1;
} ## end sub install_perl_modules

sub install_win32_extras {
	my $self = shift;

	# Add the rest of the extras
	$self->SUPER::install_win32_extras(@_);

	$self->install_launcher(
		name => 'Padre',
		bin  => 'padre',
	);

	return 1;
} ## end sub install_win32_extras

sub dist_dir {
	my $self = shift;

	my $dir;

	if ( not eval { $dir = File::ShareDir::dist_dir('Perl-Dist-Padre'); 1; }
	  )
	{
		PDWiX::Caught->throw(
			message =>
			  'Could not find distribution directory for Perl::Dist::Padre',
			info => ( defined $EVAL_ERROR ) ? $EVAL_ERROR : 'Unknown error',
		);
	}

	return $dir;
} ## end sub dist_dir

sub install_custom {
	my $self = shift;

	$self->install_six();

	return 1;
}

1;                                     # Magic true value required at end of module

__END__

=pod

=begin readme text

Perl::Dist::Padre version 0.270

=end readme

=for readme stop

=head1 NAME

Perl::Dist::Padre - Padre Standalone for Win32 builder

=head1 VERSION

This document describes Perl::Dist::Padre version 0.270.

=for readme continue

=head1 DESCRIPTION

This is the distribution builder used to create Padre Standalone for Win32.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=end readme

=for readme stop

=head1 SYNOPSIS

	# This module is only used to build Padre Standalone. 
	# See below if you want to try it yourself.

=head2 Building Padre Standalone

Unlike Strawberry, Padre Standalone does not have a standalone build script.

To build Padre Standalone, run the following.

	perldist Padre

You may wish to view the BUILDING.txt file in the distribution for more 
information.

=head1 DIAGNOSTICS

The diagnostics that are specifically returned by this module are 
C<< PDWiX >> classes or subclasses ( subclasses of 
L<Exception::Class::Base|Exception::Class::Base>. )

=over

=item C<< Could not find distribution directory for Perl::Dist::Padre >>

L<File::ShareDir|File::ShareDir> could not find the share directory for this module.

(returned as a C<PDWiX::Caught> object.)

=item C<< Perl %s is not available in Padre Standalone >>

You can only build Padre Standalone on Perl 5.10.0.

=back

=head1 CONFIGURATION AND ENVIRONMENT

File::List::Object requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.8.1 (which is the 
minimum version of Perl required) include 
L<Perl::Dist::Strawberry|Perl::Dist::Strawberry> version 1.11_14, and 
L<URI::file|URI::file>.

=for readme stop

=head1 INCOMPATIBILITIES

This module cannot be used from a perl installed in C:\strawberry.

=head1 SUPPORT

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-Padre@rt.cpan.orgE<gt> if you do not.

Please note that B<only> bugs in the distribution itself or the CPAN
configuration should be reported to RT. Bugs in individual modules
should be reported to their respective distributions.

For other issues not mentioned above, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt> and Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 Adam Kennedy and Curtis Jewell.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop
