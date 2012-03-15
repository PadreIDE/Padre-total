package Padre::Plugin::Fix::Document;

use 5.008;
use Moose;
use Padre::Wx ();

our $VERSION = '0.01';

use Moose::Util::TypeConstraints;

class_type 'FixPerlDocument', { class => 'Padre::Document::Perl' };
class_type 'FixEditor',       { class => 'Padre::Wx::Editor' };

has 'config'   => ( is => 'rw', isa => 'HashRef',         required => 1 );
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

	Wx::Event::EVT_KEY_DOWN( $editor, undef );

	return;
}

# Register key up event
sub _register_events {
	my $self   = shift;
	my $editor = $self->editor;

	Wx::Event::EVT_KEY_DOWN(
		$editor,
		sub {
			$self->_on_key_down(@_);

			# Keep processing
			$_[1]->Skip(1);
		},
	);

	return;
}

# Called when the a key is pressed
sub _on_key_down {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	if ( $event->ControlDown && $event->GetKeyCode == ord('2') ) {

		# Control-2
		my $pos  = $editor->GetCurrentPos;
		my $line = $editor->LineFromPosition($pos);
		my $col  = $pos - $editor->PositionFromLine($line) + 1;
		$line++;

		my $source = $editor->GetText;

		require PPI;
		my $doc = PPI::Document->new( \$source );

		my $quotes = $doc->find('PPI::Token::Quote');
		foreach my $quote (@$quotes) {
			my $_line   = $quote->location->[0];
			my $_col    = $quote->location->[1];
			my $content = $quote->content;

			if (   ( $line == $_line )
				&& ( $col >= $_col )
				&& ( $col <= $_col + length($content) ) )
			{
				my $start = $editor->PositionFromLine( $_line - 1 ) + $_col - 1;
				$editor->SetSelection( $start, $start + length($content) );
				if ( $content =~ /^('|q|qq|")(.+?)\1$/ ) {
					my ( $type, $text ) = ( $1, $2 );
					if ( $type eq q{"} or $type eq 'qq' ) {

						# No escape sequences?
						if ( $text !~ /\\(n|r|t)/ ) {

							# Can be replaced by simpler thing
							if ( Padre->ide->wx->main->yes_no("Convert to '$text'?") ) {
								last;
							}
						}
					}


				}
			}
		}

	}

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
