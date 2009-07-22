package Padre::Service::Indexer;

use strict;
use warnings;
use File::Find;
use Padre::Util;

use Padre::Service;
our @ISA = qw( Padre::Service );

use Padre::Wx ();


use Class::XSAccessor
	constructor => 'new',
	accessors => {
		index_class => 'index_class',
		index_args => 'index_args',
		index => 'index',
		runmode => 'runmode',
		directory_list => 'directory_list',
		match_regex   => 'match_regex',
	};

sub prepare {
	my $self = shift;
	
	my $PROGRESS_EVENT  : shared = Wx::NewEventType();
	$self->{PROGRESS_EVENT} = $PROGRESS_EVENT ;
	$self->task_warn( "Prepared $PROGRESS_EVENT" );
	
	if ( $self->{main_thread_only} ) {
		Wx::Event::EVT_COMMAND(
			Padre->ide->wx->main ,
		-1,
		$PROGRESS_EVENT,
		$self->{main_thread_only}{callback} ,
		);
		
	}
	
	return;
}

sub finish {
	my $self = shift;
	if ( $self->{main_thread_only} ) {	
		# EVIL - let the caller provide the object to
		# notify and the callback.
		$self->{main_thread_only}{notify}->Destroy;
		
	
	}
	return 1;
	
}




sub start {
	my ($self) = shift;
	
	my $index_class = $self->index_class;
	eval "require $index_class" ;
	if ($@ ) {
		Padre::Util::debug "Failed to load $index_class : $@";
		return;
	}
	
	unless ( ref $self->index_args eq 'ARRAY' ) {
		Padre::Util::debug "index_args must be an arrayref";
		return;
	}
	my $index = $index_class->new( @{ $self->index_args } );
	
	if ( $self->runmode eq 'clobber' ) {
		$self->{index} = $index->indexer( clobber=>1 );
	}
	else {
		$self->{index} = $index->indexer;
	}
	
	
	
	my $files = $self->_find_files;
	Padre::Util::debug "Got files : " . @$files;
	$self->{incoming_buffer} = $files;
	$self->{progress_total} = scalar @$files;
	$self->{progress} = 0;
	$self->{started} = 1;
	
}

sub service_loop {
	my $self = shift;
	
	my $total = $self->{progress_total};
	my $idx = $self->index;

	my $file = shift @{ $self->{incoming_buffer} };
	return $self->shutdown() unless $file;
	
	my $doc = $self->generate_document( $file );
	$idx->add_doc( $doc ) if $doc;
	
	$self->{progress}++;
	$self->post_event( $self->{PROGRESS_EVENT} , 
		sprintf( '%4f;%s' , (100*$self->{progress} / $total), $doc->{title} )
	);
	
	
	return;
}

sub shutdown {
	my $self = shift;
	$self->index->commit if $self->index;
	$self->SUPER::shutdown(@_);	
}

sub generate_document {
	my ($self,$file) = @_;
	
	my $modified = (stat $file)[9];	
	open( my $fh  , $file ) or die "Failed to open $file : $!";
	my $title = File::Basename::basename( $file );
	my $content;
	{local $/;$content = <$fh>;}
	
	my $doc = {
		file => $file ,
		modified => $modified , 
		title => $title ,
		content=> $content,
	};
		
	return $doc;
}

sub _find_files {
	my $self = shift;
	my $dirs = $self->directory_list;
	my @files;
	File::Find::find( {
		wanted => sub {
			return unless -f $_;
			return unless $_ =~ /\.(pod|pm)$/;
			#$self->match_regex;
			push @files,$_;
		},
		no_chdir=>1 
	}, @$dirs );
	return \@files;
}

1;


