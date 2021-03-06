use 5.008008;
use utf8;
use strict;
use warnings FATAL => 'all';
use lib 'inc';
use Local::Padre::Website::Builder qw(); # about Local:: see perlmodlib

my $self = Local::Padre::Website::Builder->new(
	module_name    => 'Local::Padre::Website::Builder',
	build_requires => {
		'perl'                     => '5.010',
		'autodie'                  => 0,
		'Capture::Tiny'            => 0,
		'Encode'                   => 0,
		'File::Copy'               => 0,
		'File::Next'               => 0,
		'File::Which'              => 0,
		'Module::Build'            => '0.26',
		'Path::Class'              => 0,
		'Pod::Xhtml'               => 0,
		'Template'                 => 0,
		'Test::More'               => '0.87_01',
		'Text::Unaccent::PurePerl' => 0,
		'Time::Piece'              => 0,
		'XML::LibXML'              => 0,
		'XML::LibXSLT'             => 0,
		'YAML::Tiny'               => 0,
	},
	dist_author   => 'Padre team',
	dist_abstract => 'Padre website generator',
);
die "Mandatory parameter --destdir was not specified.\n"   unless $self->destdir;
die "Mandatory parameter --sourcedir was not specified.\n" unless $self->args->{sourcedir};
$self->config_data( sourcedir => $self->args->{sourcedir} );
$self->config_data( base => $self->args->{base} ) if $self->args->{base};
$self->create_build_script;
print "You can run ./Build now.\n";

__END__

=head1 NAME

Build.PL - build the web site at padre.perlide.org

=head1 SYNOPSIS

    perl Build.PL --sourcedir . --destdir ~/public_html/padre.perlide.org
    ./Build
    ./Build test
    ./Build install
    ./Build realclean

=head1 OPTIONS

=over

=item --sourcedir

Mandatory. Specifies the name of the base directory where the web site
templates, static files and source data are located.

This is the checked out local working copy coming from the SVN path
L<http://svn.perlide.org/padre/trunk/template.padre.perlide.org>.

=item --destdir

Mandatory. Specifies the name of the directory where the web site files
are output after the build.

This directory already needs to exists.

=item --base

Optional. Specifies the target of the XHTML base link. Useful for off-line
testing. Sample values are C<http://padre.perlide.org/> or
C<file:///var/tmp/out/> (URI-fied version of L</"--destdir">).
Default is nothing; no C<base> element will be written.

=back

=head1 DESCRIPTION

C<Build.PL>, employing a subclass of Module::Build, creates a F<Build> file.
The F<Build> file is used to build, test and release the files for the web site
at L<http://padre.perlide.org>.

=head1 SEE ALSO

L<Local::Padre::Website::Builder>
