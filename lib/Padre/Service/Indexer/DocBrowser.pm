package Padre::Service::Indexer::DocBrowser;

use strict;
use warnings;

use Padre::Service::Indexer;
our @ISA  ='Padre::Service::Indexer';

use Class::XSAccessor
	accessors => {
		docprovider_class => 'docprovider_class' ,
		hints => 'hints',
		_provider => '_provider',
		
	};
	
sub start {
	my $self = shift;
	$self->SUPER::start();
	my $provider = $self->docprovider_class;
	eval "require $provider" ;
	if ($@ ) {
		Padre::Util::debug "Failed to load $provider : $@";
		die;
	}
	$self->{_provider} = $provider->new;
	
}

use Data::Dumper;
use Pod::Abstract;

sub generate_document {
	my ($self,$file) = @_;
	
	my $pa = Pod::Abstract->load_file($file);
	my @keywords;
	my @h2 = $pa->select('/head2');
	my @x  = $pa->select('/X');
	#warn Dumper \@h2;
	warn "@x" if @x;
	
	unless ($pa->select('/pod') || $pa->select('/head1') ) {
		#warn "Skipped $file , no pod";
		return;
	}
	my $title = File::Basename::basename( $file );
	my $name ;
	if (   ($name) = $pa->select("/head1[\@heading =~ {NAME}]")
		or ($name) = $pa->select("/head1") )
	{
		my $text = $name->text;
		my ($module) = $text =~ /([^\s]+)/g;
		$title = $module;
	} 
#	elsif ( ($name) = $pa->select("//item") ) {
#		my $text = $name->pod;
#		my ($item) = $text =~ /=item\s+([^\s]+)/g;
#		$title = $item ;
#	}	
	warn "Document, $title\n";
	
eval {	
	push @keywords,$_
		for map { (ref $_) ? $_->heading : $_ } @h2;
		
	push @keywords,$_
		for map { (ref $_) ? $_->pod : $_ } @x;
};
if ($@) { warn "Problems with $file . " . Dumper \@h2; }

	
	my $modified = (stat($file))[9];

	my $doc = {
		file => $file,
		modified => $modified,
		title => $title,
		content => $pa->text,
		#payload => $pa->pod,
		keywords => join ( ' ' , @keywords ),
	};

	
}


1;
