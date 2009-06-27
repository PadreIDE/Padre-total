package Perl::Dist::XL;
use strict;
use warnings;

use Cwd            qw(cwd);
use File::Copy     qw(copy);
use File::HomeDir  ();
use File::Temp     qw(tempdir);
use LWP::Simple    qw(getstore);

=head1 NAME

Perl::Dist::XL - Perl distribution for Linux

=head1 SYNOPSIS

The primary objective is to generat an already compiled perl distribution 
that Padre was already installed in so people can download it, unzip it
and start running Padre.


=head1 DESCRIPTION

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
	my $self = bless \%args, $class;

	$self->{cwd} = cwd;

	if ($self->{temp}) {
		die "$self->{temp} does not exist\n" if not -d $self->{temp};
	} else {
		$self->{temp} = tempdir( CLEANUP => 1 );
	}
	$self->{perl_install_dir} = $self->temp_dir . '/' . $self->release_name;
	return $self;
}
DESTROY {
	my ($self) = @_;
	chdir $self->{cwd};
	debug("Done");
}


sub build {
	my ($self) = @_;

	$self->get_perl   unless $self->skip_perl;
	$self->build_perl unless $self->skip_perl;

	$self->configure_cpan;
	$self->install_modules;
#	$self->remove_cpan_dir;

	# TODO: run some tests
	$self->create_zip;
	# TODO: unzip and in some other place and run some more tests

	return;
}


sub get_perl {
	my ($self) = @_;

	my $dir = $self->cache();
	my $url = 'http://www.cpan.org/src';
	my $perl = 'perl-5.10.0.tar.gz';
	if (not -e "$dir/$perl") {
		debug("Getting $url/$perl");
		getstore("$url/$perl", "$dir/$perl");
	}
	die "Could not find $perl\n" if not -e "$dir/$perl";
	
	my $temp = $self->temp_dir;
	chdir $temp;
	debug("temp directory: $temp");
	_system("tar xzf $dir/$perl");

	$self->{perl_source_dir} = substr("$temp/$perl", 0, -7);
	debug("Perl dir: $self->{perl_source_dir}");
	return;
}

sub build_perl {
	my ($self) = @_;

	my $dir = $self->cache;
	my $temp = $self->temp_dir;
	chdir $self->{perl_source_dir};
	my $cmd = "sh Configure -Dusethreads -Duserelocatableinc -Dprefix='$self->{perl_install_dir}' -de";
	_system($cmd);
	_system("make");
	_system("make test");
	_system("make install");

	return;
}

sub configure_cpan {
	my ($self) = @_;
	my $from = "$self->{cwd}/share/files/mycpan.pl"; # TODO not from cwd ?
	my $to   = $self->{perl_install_dir} . '/bin/';
	debug("copy '$from', '$to'");
	copy $from, $to;
	return;
}

sub install_modules {
	my ($self) = @_;
	
	my @modules = (
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

	);
	foreach my $m (@modules) {
		local $ENV{PERL_MM_USE_DEFAULT} = 1;
		_system("$self->{perl_install_dir}/bin/perl $self->{perl_install_dir}/bin/mycpan.pl $m->[0]");
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

sub temp_dir {
	my ($self) = @_;
	return $self->{temp};
}

sub cache {
	my $home    = File::HomeDir->my_home;
	my $dir = "$home/.perldist_xl";
	mkdir $dir if not -e $dir;
	return $dir
}


sub release_name {
	my ($self) = @_;

	return "perl-5.10.0-xl-" . $self->{release};
}
sub _system {
	my @args = @_;
	debug(join " ", @args);
	system(@args) == 0 or die "system failed with $?\n";
}

sub skip_perl {
	return $_[0]->{skipperl};
}

sub debug {
	print "@_\n";
}

1;


