package Padre::Plugin::SQL::MessagePanel;

# panel for the database stuff.
# stolen completely from the Catalyst plugin

use strict;
use warnings;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Util ('_T');
use Wx ();

use base 'Wx::Panel';

sub new {
	my $class      = shift;
	my $main       = shift;
	my $self       = $class->SUPER::new( Padre::Current->main->bottom );

	

	require Scalar::Util;
	$self->{main} = $main;
	Scalar::Util::weaken($self->{main});
	
	my $box = Wx::BoxSizer->new(Wx::wxVERTICAL);
	# output panel for server
	require Padre::Wx::Output;
	my $output = Padre::Wx::Output->new($main, $self);
	$box->Add( $output, 1, Wx::wxGROW );	
	
	$self->SetSizer($box);
	$self->{output} = $output;
	
	
	#Padre::Current->main->bottom->hide($self);
	
	#$self->show;
	return $self;
	
}


sub output { return shift->{output}; }
sub gettext_label { return _T('SQL Messages'); }

# dirty hack to allow seamless use of Padre::Wx::Output
sub bottom { return $_[0] }

sub update_messages {
	my $self = shift;
	my $message = shift;
	
	my $msg_output = $self->output;
	$msg_output->Remove( 0, $msg_output->GetLastPosition );
	
	$msg_output->style_neutral;	
	$msg_output->AppendText($message);
	
}

sub append_messages {
	my $self = shift;
	my $message = shift;
	
	$self->output->AppendText($message);
	
}


1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.