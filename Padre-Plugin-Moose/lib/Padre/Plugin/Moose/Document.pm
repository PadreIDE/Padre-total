package Padre::Plugin::Moose::Document;

use 5.008;
use strict;
use warnings;
use Padre::Document::Perl ();

our $VERSION = '0.14';

our @ISA = 'Padre::Document::Perl';

sub set_editor {
	my $self = shift;
	my $editor = shift;

	$self->SUPER::set_editor($editor);

	Wx::Event::EVT_KEY_DOWN($editor, undef);
	Wx::Event::EVT_KEY_DOWN($editor, sub {
		my $event = $_[1];

		if($event->GetKeyCode == Wx::WXK_TAB) {
			print "Tab pressed\n";
		}

		$event->Skip(1);
	});
}
1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Document - Padre Perl document with Moose highlighting

=cut
