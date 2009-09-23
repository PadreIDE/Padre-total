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
		indexer=>'indexer',
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
	$self->{index} = $index;	
	if ( $self->runmode eq 'clobber' ) {
		$self->{indexer} = $index->indexer( clobber=>1 );
	}
	else {
		$self->{indexer} = $index->indexer;
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
	my $idx = $self->indexer;

	my $file = shift @{ $self->{incoming_buffer} };
	return $self->shutdown() unless $file;

	my $doc;
	if ( $self->runmode eq 'clobber' ) {
		$doc = $self->generate_document($file);
	}
	else {

		my $modified = eval {  (stat($file))[9]  };
		my $lookup = $self->index->search($file);
		warn "File $file - modified $modified - $lookup", $/;
		my $doc;

		unless ($lookup->total_hits)  {
			# no lookup for this file - new!
			$doc = $self->generate_document($file);
		}
		else {
			my $hit = $lookup->next ;
			my $fields = $hit->get_fields;
			if ( $fields->{file} eq $file 
			&& $fields->{modified} < $modified ) {
				warn "Replace doc - Modified! " , $fields->{modified}, $/;
				$idx->delete_by_term( field=>'file',term => $file );
				$doc = $self->generate_document( $file );
			}
			elsif ( $fields->{file} eq $file ) {
				# "No changes to $file",$/;
			}
		}
	}
	$self->{progress}++;
	
	if ( $doc ) {
		$idx->add_doc( $doc );
		$self->post_event( $self->{PROGRESS_EVENT} , 
			sprintf( '%4f;%s' , (100*$self->{progress} / $total), $doc->{title})
		) if $self->{PROGRESS_EVENT};
	}
	else { 
		$self->post_event( $self->{PROGRESS_EVENT} ,
			sprintf( '%4f;%s', (100*$self->{progress}/$total), "Skip: $file" )
		) if $self->{PROGRESS_EVENT};
		#warn "SKIP: $file\n";
	}
	
	return;
}

sub shutdown {
	my $self = shift;
	$self->indexer->commit if $self->indexer;
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


