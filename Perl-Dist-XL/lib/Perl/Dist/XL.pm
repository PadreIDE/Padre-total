package Perl::Dist::XL;
use strict;
use warnings;
use 5.010;

use Cwd            qw(cwd);
use CPAN::Mini     ();
use Data::Dumper   qw(Dumper);
use File::Copy     qw(copy);
use File::HomeDir  ();
use File::Path     qw(rmtree);
#use File::Temp     qw(tempdir);
use LWP::Simple    qw(getstore mirror);

=head1 NAME

Perl::Dist::XL - Perl distribution for Linux

=head1 SYNOPSIS

The primary objective is to generate an already compiled perl distribution 
that Padre was already installed in so people can download it, unzip it
and start running Padre.

=head1 DESCRIPTION

=head2 Process plan

1] Download
  1) check if the version numbers listed in the file are the latest from cpan and report the differences
  2) Download the additional files needed (e.g. wxwidgets)

2] Building in steps and on condition
  1) build perl - if it is not built yet
  2) foreach module
     if it is not yet in the distribution
     unzip it
     run perl Makefile.PL or perl Build.PL and check for errors
     make; make test; make install

   have special case for Alien::wxWidgets to build from a downloaded version of wxwidgets
     
=head2 Building on Ubuntu 9.10

  sudo aptitude install subversion vim libfile-homedir-perl libmodule-install-perl 
  sudo aptitude install libcpan-mini-perl perl-doc


  svn co http://svn.perlide.org/padre/trunk/Perl-Dist-XL/
  cd Perl-Dist-XL
  perl script/perldist_xl.pl --download 
  perl script/perldist_xl.pl --clean
  perl script/perldist_xl.pl --build --release 0.01

TODO: set perl version number (and allow command line option to configure it)


=head2 Plans

Once the primary objective is reached we can consider adding more modules
to include all the Padre Plugins, the EPO recommendations and all the 
none-windows specific modules that are in Strawberry Perl.

We can also consider including the C level libraries and tool to make sure
further CPAN modules can be installed without additional configuration.


Version control: Currently we just install the latest version of
each module in XLPerl. We could make sure we know exactly which version
of each module we install and upgrade only under control.

=cut

sub new {
	my ($class, %args) = @_;

	my @steps = qw(perl);
	if ($args{build}) {
		my $build = $args{build};
		my %b = map {$_ => 1} @$build;
		$args{build} = \%b;
		if ($args{build}{all}) {
			$args{build}{$_} = 1 for @steps;
		}
	}

	my $self = bless \%args, $class;

	$self->{cwd} = cwd;

	if (not $self->{dir}) {
		my $home    = File::HomeDir->my_home;
		$self->{dir} = "$home/.perldist_xl";
	}
	mkdir $self->{dir} if not -e $self->{dir};
	debug("directory: $self->{dir}");

	$self->{perl_install_dir} = $self->dir . '/perl/' . $self->release_name;
	return $self;
}
DESTROY {
	my ($self) = @_;
	chdir $self->{cwd};
	debug("Done");
}

sub run {
	my ($self) = @_;

	$self->download    if $self->{download};
	$self->clean       if $self->{clean};

	$self->build_perl  if $self->{build}{perl};
	# wxperl
	# cpan

	return;
}

#	$self->configure_cpan;
#	$self->install_modules;
#	$self->remove_cpan_dir;

	# TODO: run some tests
#	$self->create_zip;
	# TODO: unzip and in some other place and run some more tests

sub build_perl {
	my ($self) = @_;

	my $build_dir = $self->dir_build;
	mkdir $build_dir if not -e $build_dir;
	my $dir       = $self->dir;

	chdir $build_dir;
	my $perl = $self->perl_file;
	$self->{perl_source_dir} = substr("$build_dir/$perl", 0, -7);
	debug("Perl source dir: $self->{perl_source_dir}");

	if (not -e $self->{perl_source_dir}) {
		_system("tar xzf $dir/$perl");
	}

	chdir $self->{perl_source_dir};
	my $cmd = "sh Configure -Dusethreads -Duserelocatableinc -Dprefix='$self->{perl_install_dir}' -de";
	_system($cmd);
	_system("make");
	_system("make test");
	_system("make install");

	return;
}


sub get_perl {
	my ($self) = @_;
	debug("Downloading perl");
	my $dir = $self->dir;
	my $url = 'http://www.cpan.org/src';
	# TODO: allow building with development version as well 5.11.2
	my $perl = $self->perl_file;
	if (not -e "$dir/$perl") {
		debug("Getting $url/$perl");
		mirror("$url/$perl", "$dir/$perl");
	} else {
		debug("Skipped");
	}
	die "Could not find $perl\n" if not -e "$dir/$perl";

	return;
}

	
sub configure_cpan {
	my ($self) = @_;
	
	# TODO not from cwd ?
	# TODO eliminate this horrible patch!
	for my $from ("$self->{cwd}/share/files/mycpan.pl", "$self->{cwd}/share/files/mycpan_core.pl") {
		my $to   = $self->{perl_install_dir} . '/bin/';
		debug("copy '$from', '$to'");
		copy $from, $to;
	}
	return;
}

sub perl_file { return 'perl-5.10.1.tar.gz'; }
sub modules {
	return [ 
		['Test::Simple'             => '0.88'],
		['Sub::Uplevel'             => '0.2002'],
		['Array::Compare'           => '1.17'],
		['Tree::DAG_Node'           => '1.06'],
		['Test::Exception'          => '0.27'],
		['Test::Warn'               => '0.11'],
		['Test::Tester'             => '0'],
		['Test::NoWarnings'         => '0'],
		['Test::Deep'               => '0'],
		['IO::Scalar'               => '2.110'],
		['File::Next'               => '1.02'],
		['App::Ack'                 => '1.86'],
		['Class::Adapter'           => '1.05'],
		['Class::Inspector'         => '1.24'],
		['Class::Unload'            => '0.03'],
		['AutoXS::Header'           => '1.02'],
		['Class::XSAccessor'        => '1.02'],
		['Class::XSAccessor::Array' => '1.02'],
		['Cwd'                      => '3.2701'], # PathTools-3.30
		['DBI'                      => '1.609'],
		['DBD::SQLite'              => '1.10'],
		['Devel::Dumpvar'           => '1.05'],
		['Encode'                   => '2.33'],
		['IPC::Run3'                => '0.043'],
		['Test::Script'             => '1.03'],
		['Test::Harness'            => '3.17'],
		['Devel::StackTrace'        => '1.20'],
		['Class::Data::Inheritable' => '0.08'],
		['Exception::Class'         => '1.29'],
		['Algorithm::Diff'          => '1.1902'],
		['Text::Diff'               => '0.35'],
		['Test::Differences'        => '0.4801'],
		['Test::Most'               => '0.21'],
		['File::Copy::Recursive'    => '0.38'],
		['Text::Glob'               => '0.08'],
		['Number::Compare'          => '0.01'],
		['File::Find::Rule'         => '0.30'],
		['File::HomeDir'            => '0.86'],
		['Params::Util'             => '1.00'],
		['File::ShareDir'           => '1.00'],
#		['File::Spec'               => '3.2701'], # was already installed
		['File::Which'              => '0.05'],
		['HTML::Tagset'             => '3.20'],
		['HTML::Entities'           => '3.61'],
		['HTML::Parser'             => '3.61'], # the same pacakge as HTML::Entities
		['IO::Socket'               => '1.30'], # IO 1.25
		['IO::String'               => '1.08'],
		['IPC::Cmd'                 => '0.46'],
		['List::Util'               => '1.18'], # Scalar-List-Utils-1.21
		['List::MoreUtils'          => '0.22'],
		['File::Temp'               => '0.21'],
		['ORLite'                   => '1.23'],
		['ORLite::Migrate'          => '0.03'],
		['File::pushd'              => '1.00'],
		['Probe::Perl'              => '0.01'],
		['File::Slurp'              => '9999.13'],
		['Pod::POM'                 => '0.25'],
		['Parse::ErrorString::Perl' => '0.11'],
		['Module::Refresh'          => '0.13'],
		['Devel::Symdump'           => '2.08'],
		['Test::Pod'                => '1.26'],
		['Pod::Coverage'            => '0.20'],
		['Test::Pod::Coverage'      => '1.08'],
		['Module::Starter'          => '1.50'],
		['Parse::ExuberantCTags'    => '1.00'],
		['Pod::Simple'              => '3.07'],
#		['Pod::Simple::XHTML'       => '3.04'], # supplied by Pod::Simple
		['Task::Weaken'             => '1.03'],
		['Pod::Abstract'            => '0.19'],
		['Storable'                 => '2.20'],
		['URI'                      => '1.38'],
		['YAML::Tiny'               => '1.39'],
		['Text::FindIndent'         => '0.03'],

		['File::Remove'             => '1.42'],
		['Test::Object'             => '0.07'],
		['Config::Tiny'             => '2.12'],
		['Test::ClassAPI'           => '1.05'],
		['Clone'                    => '0.31'],
		['Hook::LexWrap'            => '0.22'],
		['Test::SubCalls'           => '1.09'],
		['PPI'                      => '1.203'],
		['PPIx::EditorTools'        => '0.04'],
		['Module::Inspector'        => '0.04'],


		['PAR::Dist'                => '0.45'],
		['Archive::Zip'             => '1.28'],
		['Compress::Raw::Zlib'      => '2.020'],
		['AutoLoader'               => '5.68'],
		['PAR'                      => '0.992'],
		['File::ShareDir::PAR'      => '0.05'],

		['threads'                  => '1.73'],
		['threads::shared'          => '1.29'],
		['Thread::Queue'            => '2.11'],

		['ExtUtils::CBuilder'       => '0.24'],

		['Alien::wxWidgets'         => '0.43'],
		['Wx'                       => '0.91'],
		['Wx::Perl::ProcessStream'  => '0.11'],
		['Padre'                    => '0.38'],

	];
}


sub install_modules {
	my ($self) = @_;

	foreach my $m (@{ $self->modules }) {
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		#my $cmd = $m->[0] eq 'Pod::Simple' ? 'mycpan_core.pl' : 'mycpan.pl';
		my $cmd = 'mycpan.pl';
		_system("$self->{perl_install_dir}/bin/perl $self->{perl_install_dir}/bin/$cmd $m->[0]");
	}
}

sub remove_cpan_dir {
	my ($self) = @_;
	_system("rm -rf " . $self->{perl_install_dir} . '/.cpan');
	return;
}


sub create_zip {
	my ($self) = @_;
	chdir $self->temp_dir;
	my $file = "$self->{cwd}/" . $self->release_name . '.tar.gz';
	_system("tar czf $file " . $self->release_name . ' --exclude .cpan');
	return;
}	


#### helper subs

sub dir {
	my ($self) = @_;
	return $self->{dir};
}
sub dir_build {
	my ($self) = @_;
	return "$self->{dir}/build";
}

sub release_name {
	my ($self) = @_;

	return "perl-5.10.0-xl-" . ($self->{release} || 0);
}
sub _system {
	my @args = @_;
	debug(join " ", @args);
	system(@args) == 0 or die "system failed with $?\n";
}

sub debug {
	print "@_\n";
}

=head2 clean

Remove the directories where perl was unzipped, built and where it was "installed"

=cut

sub clean {
	my ($self) = @_;

	my $dir = $self->dir_build;
	rmtree $dir if $dir;
	return;
}

=head2 download

Downloading the source code of perl, the CPAN modules
and in the future also wxwidgets

See get_perl and get_cpan for the actual code.

=cut

sub download {
	my ($self) = @_;

	$self->get_perl;
	$self->get_cpan;
	#$self->get_other;

	return;
}

sub get_cpan {
	my ($self) = @_;
	
	debug("Get CPAN");
	my $cpan = 'http://cpan.hexten.net/';
	my $minicpan = $self->dir . "/cpan";
	my $verbose = 0;
	my $force   = 1;

	CPAN::Mini->update_mirror(
		remote       => $cpan,
		local        => $minicpan,
		trace        => $verbose,
		force        => $force,
		path_filters => [ sub { $self->filter(@_) } ],
	);

	return;
}

{
	my %modules;
	my %seen;

	sub filter {
		my ($self, $path) = @_;

		return $seen{$path} if exists $seen{$path};

		if (not %modules) {
			foreach my $pair (@{ $self->modules }) {
				my ($name, $version) = @$pair;
				$name =~ s/::/-/g;
				$modules{$name} = $version;
			}
		}
		foreach my $module (keys %modules) {
			if ($path =~ m{/$module-\d}) {
				# TODO cache names and skip if it as already seen?
				#print "Mirror: $path\n";
				return $seen{$path} = 0;
			}
		}
		#die Dumper \%modules;
		#warn "@_\n";
		return $seen{$path} = 1;
	}
}


1;


