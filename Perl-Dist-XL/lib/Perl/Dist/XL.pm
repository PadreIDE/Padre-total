package Perl::Dist::XL;
use strict;
use warnings;

use Cwd            qw(cwd);
use File::Copy     qw(copy);
use File::HomeDir  ();
use File::Temp     qw(tempdir);
use LWP::Simple    qw(getstore);

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
	$self->remove_cpan_dir;

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
		['Test::Simple'     => '0.88'],
		['Sub::Uplevel'     => '0.2002'],
		['Array::Compare'   => '1.17'],
		['Tree::DAG_Node'   => '1.06'],
		['Test::Exception'  => '0.27'],
		['Test::Warn'       => '0.11'],
		['Test::Tester'     => '0'],
		['Test::NoWarnings' => '0'],
		['Test::Deep'       => '0'],
		['IO::Scalar'       => '0'],
	);
	foreach my $m (@modules) {
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
	_system("tar czf $file " . $self->{perl_install_dir});
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


