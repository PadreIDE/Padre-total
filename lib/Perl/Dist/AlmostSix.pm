package Perl::Dist::AlmostSix;

#<<<
use 5.008001;
use strict;
use warnings;
use Perl::Dist::Padre       0.500  qw();
use URI::file                      qw();
use English                        qw( -no_match_vars    );
use File::Spec::Functions          qw( catfile           );
use parent                         qw( Perl::Dist::Padre );

# http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
our $VERSION = '0.500';
$VERSION =~ s/_//ms;
#>>>


######################################################################
# Configuration

sub new {
	my $dist_dir = File::ShareDir::dist_dir('Perl-Dist-Padre');

	my $self = shift->SUPER::new(
		app_name     => 'Padre Standalone Plus Six',
		app_ver_name => 'Padre Standalone Plus Six 0.50-PDX',

		# Tasks to complete to create Padre Standalone Plus Six
		tasklist => [
			'final_initialization',
			'install_c_toolchain',
			'install_strawberry_c_toolchain',
			'install_c_libraries',
			'install_strawberry_c_libraries',
			'install_perl',
			'install_perl_toolchain',
			'install_cpan_upgrades',
			'install_strawberry_modules_1',
			'install_strawberry_modules_2',
			'install_strawberry_modules_3',
			'install_padre_prereq_modules_1',
			'install_padre_prereq_modules_2',
			'install_padre_modules',
			'install_six_modules',
			'install_win32_extras',
			'install_strawberry_extras',
			'install_padre_extras',
			'remove_waste',
			'install_six',
			'add_forgotten_files',
			'regenerate_fragments',
			'write',
		],

		@_,

	);

	return $self;
} ## end sub new

sub output_base_filename {
	return 'almost-six-0.50';
}





#####################################################################
# Customisations for Perl assets

sub install_six_modules {
	my $self = shift;

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

	# Last, but least, install Padre::Plugin::Perl6
	$self->install_module( name => 'Padre::Plugin::Perl6' );

	return 1;
} ## end sub install_six_modules

#=pod
#
#=head2 install_six
#
#  $dist->install_six
#
#The C<install_six> method installs (via a ZIP file) an experimental parrot
#and rakudo conglomeration codenamed "six" that is utterly unlike whatever
#the final packaged binary of Perl 6 will look like.
#
#This method should only be called after all Perl 5 components are installed.
#
#=cut

sub install_six {
	my $self = shift;

	# Install Gabor's crazy Perl 6 blob
	my $filelist = $self->install_binary(
		name       => 'six',
		url        => $self->binary_url('six-20090724-gabor.zip'),
		install_to => q{.}
	);
	$self->insert_fragment( 'six', $filelist );
	$self->add_env_path('six');

	return 1;
} ## end sub install_six

1;                                     # Magic true value required at end of module

__END__

=pod

=begin readme text

Perl::Dist::AlmostSix version 0.500

=end readme

=for readme stop

=head1 NAME

Perl::Dist::AlmostSix - Padre Standalone Plus Six for Win32 builder

=head1 VERSION

This document describes Perl::Dist::AlmostSix version 0.500.

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

	# This module is only used to build Padre Standalone Plus Six. 
	# See below if you want to try it yourself.

=head2 Building Padre Standalone

Unlike Strawberry, Padre Standalone Plus Six does not have a standalone build script.

To build Padre Standalone Plus Six, run the following.

	perldist AlmostSix

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

You can only build Padre Standalone on Perl 5.10.1.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Perl::Dist::AlmostSix requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.8.1 (which is the 
minimum version of Perl required) include 
L<Perl::Dist::Strawberry|Perl::Dist::Strawberry> version 2.01, and 
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
