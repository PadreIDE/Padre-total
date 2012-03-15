package Padre::Plugin::Fix::Document;

use 5.008;
use Moose;
use Padre::Wx ();

our $VERSION = '0.01';

use Moose::Util::TypeConstraints;

class_type 'FixPerlDocument', { class => 'Padre::Document::Perl' };
class_type 'FixEditor',       { class => 'Padre::Wx::Editor' };

has 'config'   => ( is => 'rw', isa => 'HashRef',             required => 1 );
has 'document' => ( is => 'rw', isa => 'FixPerlDocument', required => 1 );
has 'editor'   => ( is => 'rw', isa => 'FixEditor',       required => 1 );

# Called when the document is created
sub BUILD {
	my $self = shift;

	# Register events for the editor
	$self->_register_events;

	return;
}

# Called when the document is destroyed
sub cleanup {
	my $self   = shift;
	my $editor = $self->editor;

	Wx::Event::EVT_LEFT_UP( $editor, undef );

	return;
}

# Register key up event
sub _register_events {
	my $self   = shift;
	my $editor = $self->editor;

	# Called by when a key up event occurs
	Wx::Event::EVT_KEY_UP(
		$editor,
		sub {
			$self->_on_key_up($editor);

			# Keep processing
			$_[1]->Skip(1);
		},
	);

	return;
}

# Called when the a key is released
sub _on_key_up {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	# Keep processing events
	$event->Skip(1);

	return;
}

no Moose::Util::TypeConstraints;
no Moose;

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Fix::Document - A Perl document that understands how to fix code :)

=cut
