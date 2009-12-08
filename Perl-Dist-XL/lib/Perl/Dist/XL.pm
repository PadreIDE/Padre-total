package Perl::Dist::XL;
use strict;
use warnings;
use 5.008;

use Cwd            qw(cwd);
use CPAN::Mini     ();
use Data::Dumper   qw(Dumper);
use File::Basename qw(dirname);
use File::Copy     qw(copy);
use File::HomeDir  ();
use File::Path     qw(rmtree mkpath);
#use File::Temp     qw(tempdir);
use LWP::Simple    qw(getstore mirror);

our $VERSION = '0.02';

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

TODO: create snapsshots at the various steps of the build process so
      we can restart from there

TODO: eliminate the need for Module::Install or reduce the dependency to 0.68 
as only that is available in 8.04.3
     
=head2 Building on Ubuntu 8.04.3 or 9.10

  sudo aptitude install subversion vim libfile-homedir-perl libmodule-install-perl 
  sudo aptitude install libcpan-mini-perl perl-doc libgtk2.0-dev g++

  svn co http://svn.perlide.org/padre/trunk/Perl-Dist-XL/
  cd Perl-Dist-XL
  perl script/perldist_xl.pl --download 
  perl script/perldist_xl.pl --clean
  perl script/perldist_xl.pl --build all

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

	my @steps = qw(perl cpan wx padre);
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
	mkpath("$self->{dir}/src") if not -e "$self->{dir}/src";
	debug("directory: $self->{dir}");

	$self->{perl_install_dir} = $self->dir . '/' . $self->release_name  . '/perl/';
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
	$self->configure_cpan if $self->{build}{cpan};
	$self->build_wx    if $self->{build}{wx};
	$self->install_modules($self->padre_modules) if $self->{build}{padre};



	# TODO: run some tests
	$self->create_zip  if $self->{zip};
	# TODO: unzip and in some other place and run some more tests

	return;
}

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
		_system("tar xzf $dir/src/$perl");
	}

	chdir $self->{perl_source_dir};
	my $cmd = "sh Configure -Dusethreads -Duserelocatableinc -Dprefix='$self->{perl_install_dir}' -de";
	_system($cmd);
	_system("make");
	_system("make test");
	_system("make install");

	return;
}

sub build_wx {
	my ($self) = @_;

	my $dir = $self->dir . "/src";
	$ENV{AWX_URL} = "file:///$dir";
	$self->install_modules($self->wx_modules);

	return;
}
	
sub configure_cpan {
	my ($self) = @_;
	
	# TODO not from cwd ?
	# TODO eliminate this horrible patch!
	#for my $from ("$self->{cwd}/share/files/mycpan.pl", "$self->{cwd}/share/files/mycpan_core.pl") {
	#for my $from ("$self->{cwd}/share/files/mycpan.pl") {
	#	my $to   = $self->{perl_install_dir} . '/bin/';
	#	debug("copy '$from', '$to'");
	#	copy $from, $to;
	#}

	process_template (
		"$self->{cwd}/share/files/mycpan.pl.tmpl", 
		"$self->{perl_install_dir}/bin/mycpan.pl",
	);

	# TODO: make this a template, replace perl version number in file!
	process_template (
		"$self->{cwd}/share/files/padre.sh.tmpl",
		"$self->{perl_install_dir}/bin/padre.sh",
		PERL_VERSION => $self->perl_version,
	);
	chmod 0755, "$self->{perl_install_dir}/bin/padre.sh";

	process_template(
		"$self->{cwd}/share/files/Config.pm.tmpl",
		"$self->{perl_install_dir}.cpan/CPAN/Config.pm",

		URL => 'file://' . $self->minicpan,
	);
}

sub process_template {
	my ($from, $to, %map) = @_;
	
	mkpath dirname($to);
	open my $in,  '<', $from  or die "Could not open source '$from' $!";
	open my $out, '>', $to    or die "Could not open target '$to' $!";
	local $/ = undef;
	my $content = <$in>;
	foreach my $k (sort {length $b <=> length $a} keys %map) {
		$content =~ s{$k}{$map{$k}}g; 
	}
	print $out $content;

	close $in;
	close $out;

	return;
}

sub perl_version { return '5.10.1'; }
sub perl_file { return 'perl-' . $_[0]->perl_version() . '.tar.gz'; }
sub all_modules {
	my ($self) = @_;
	my $pm = $self->padre_modules;
	my $wx = $self->wx_modules;

	return [ @$pm, @$wx];
}

sub wx_modules {
	return [
		['YAML'    => '0'],
		['ExtUtils::CBuilder'       => '0.24'],
		['Alien::wxWidgets'         => '0.46'],
	];
}
#sub padre_modules {
#	return [ 
#		['Padre'             => '0'],
#	];
#}

sub padre_modules {
	return [ 
		['CPAN::Inject' =>  '0.07'],
		['LWP::Online'  =>  '1.06'],
		['LWP::Simple'  => '0'],
		['libwww::perl' => '0'],
		['Spiffy'                => '0.30'],
		['Test::Simple'             => '0.88'],
		['Test::Base'        => '0.59'],
		['Devel::Refactor'          => '0.05'],
		['Sub::Uplevel'             => '0.2002'],
		['Moose'  => '0'],
		#['Array::Compare'           => '1.17'],
		['Data::Compare'            => '1.2101'],
		['File::chmod'              => '0.32'],
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
		['CPAN::Checksums'          => '2.04'],
		['Compress::Bzip2'          => '2.09'],
		['Probe::Perl'              => '0.01'],
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
		['File::Which'              => '1.08'],
		['Format::Human::Bytes'     => '0'],
		['Locale::Msgfmt'           => '0.14'],
		['HTML::Tagset'             => '3.20'],
		['HTML::Entities'           => '3.61'],
		['HTML::Parser'             => '3.61'], # the same pacakge as HTML::Entities
		['IO::Socket'               => '1.30'], # IO 1.25
		['IO::String'               => '1.08'],
		['IPC::Cmd'                 => '0.46'],
		['List::Util'               => '1.18'], # Scalar-List-Utils-1.21
		['List::MoreUtils'          => '0.22'],
		['File::Temp'               => '0.21'],
		['File::Remove'             => '1.42'],
		['File::Find::Rule::Perl'   => '0'],
		['File::Find::Rule::VCS'    => '1.02'],
		['Module::Extract'          => '0.01'],
		['Module::Manifest'         => '0.01'],
		['Module::Math::Depends'    => '0.02'],
		['ORLite'                   => '1.23'],
		['ORLite::Migrate'          => '0.03'],
		['File::pushd'              => '1.00'],
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
		['Pod::Perldoc'             => '3.15'],
		['Storable'                 => '2.20'],
		['URI'                      => '1.38'],
		['YAML::Tiny'               => '1.39'],
		['Text::FindIndent'         => '0.03'],
		['pip'                      => '0.13'],
		['Class::MOP'               => '0.94'],
		['Data::OptList'            => '0'],
		['Sub::Install'             => '0.92'],
		['MRO::Compat'              => '0.11'],
		['Sub::Exporter'            => '0.980'],
		['Sub::Name'                => '0'],
		['Try::Tiny'                => '0.02'],
		['Test::Object'             => '0.07'],
		['Devel::GlobalDestruction' => '0.02'],
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

		['ExtUtils::XSpp'           => '0'],
		['Wx'                       => '0.91'],
		['Wx::Perl::ProcessStream'  => '0.11'],
		['Padre'                    => '0.38'],

		['Padre::Plugin::Perl6'     => '0'],

	];
}

sub install_modules {
	my ($self, $modules) = @_;

	foreach my $m (@$modules) {
		local $ENV{PATH} = "$self->{perl_install_dir}/bin:$ENV{PATH}";
		local $ENV{HOME} = $self->{perl_install_dir};
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		#my $cmd0 = $m->[0] eq 'Pod::Simple' ? 'mycpan_core.pl' : 'mycpan.pl';
		my $cmd0 = 'mycpan.pl';
		my $cmd = "$self->{perl_install_dir}/bin/perl $self->{perl_install_dir}/bin/$cmd0 $m->[0]";
		debug("system $cmd");
		_system($cmd);
		# check for
		# Result: FAIL
	}
}

sub remove_cpan_dir {
	my ($self) = @_;
	rmtree($self->{perl_install_dir} . '/.cpan/build');
	rmtree($self->{perl_install_dir} . '/.cpan/sources');
	rmtree($self->{perl_install_dir} . '/.cpan/Metadata');
	rmtree($self->{perl_install_dir} . '/.cpan/FTPstats.yml');
	return;
}


sub create_zip {
	my ($self) = @_;

	$self->remove_cpan_dir;

	chdir $self->dir;
	my $file = "$self->{cwd}/" . $self->release_name . '.tar.gz';
	if (-e $file) {
		print "File '$file' already exists\n";
		return;
	}
	_system("tar czf $file " . $self->release_name); # . ' --exclude .cpan');
	return;
}	


#### helper subs

sub dir       { return $_[0]->{dir};         }
sub minicpan  { return "$_[0]->{dir}/cpan_mirror";  }
sub dir_build { return "$_[0]->{dir}/build"; }

sub release_name {
	my ($self) = @_;
	my $perl = substr($self->perl_file(), 0, -7);
	return "$perl-xl-$VERSION";
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

See get_other and get_cpan for the actual code.

=cut

sub download {
	my ($self) = @_;

	$self->get_cpan;
	$self->get_other;

	return;
}


sub get_other {
	my ($self) = @_;

	my $perl = $self->perl_file;
	# TODO: allow building with development version as well 5.11.2
	my @resources = (
		"http://www.cpan.org/src/$perl",
		'http://prdownloads.sourceforge.net/wxwindows/wxWidgets-2.8.10.tar.gz',

	);

	my $src = $self->dir . "/src";
	foreach my $url (@resources) {
		my $filename = (split "/", $url)[-1];
		debug("getting $url to   $src/$filename");
		mirror($url, "$src/$filename"); 
	}
	return;
}

sub get_cpan {
	my ($self) = @_;
	
	debug("Get CPAN");
	my $cpan = 'http://cpan.hexten.net/';
	my $minicpan = $self->minicpan;
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
			foreach my $pair (@{ $self->all_modules }) {
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


