package Padre::Plugin::Moose::Document;

use 5.008;
use strict;
use warnings;
use Padre::Document::Perl ();

our $VERSION = '0.18';

our @ISA = 'Padre::Document::Perl';

# Override SUPER::set_editor to hook up the key down event
sub set_editor {
	my $self   = shift;
	my $editor = shift;

	$self->SUPER::set_editor($editor);

	# TODO Padre should fire event_key_down instead of this hack :)
	# Register keyboard event handler for the current editor
	Wx::Event::EVT_KEY_DOWN( $editor, undef );
	Wx::Event::EVT_KEY_DOWN( $editor, sub { $self->on_key_down(@_); } );

	return;
}

# Load snippets from file according to code generation type
sub _load_snippets {
	my $self   = shift;
	my $config = shift;

	eval {
		require YAML;
		require File::ShareDir;
		require File::Spec;

		# Determine the snippets filename
		my $file;
		my $type = $config->{type};
		if ( $type eq 'Mouse' ) {

			# Mouse snippets
			$file = 'mouse.yml';
		} elsif ( $type eq 'MooseX::Declare' ) {

			# MooseX::Declare snippets
			$file = 'moosex_declare.yml';
		} else {

			# Moose by default
			$file = 'moose.yml';
		}

		# Shortcut if that snippet type is already loaded in memory
		return if defined( $self->{_snippets_type} ) and ( $type eq $self->{_snippets_type} );

		# Determine the full share/${snippets_filename}
		my $filename = File::ShareDir::dist_file( 'Padre-Plugin-Moose', File::Spec->catfile( 'snippets', $file ) );

		# Read it via standard YAML
		$self->{_snippets} = YAML::LoadFile($filename);

		# Record loaded snippet type
		$self->{_snippets_type} = $type;
	};

	return;
}

sub get_indentation_style {
	my $self = shift;

	# Workaround to get moose plugin configuration... :)
	require Padre::Plugin::Moose;
	my $config = Padre::Plugin::Moose::_plugin_config();

	# Syntax highlight Moose keywords after get_indentation_style is called :)
	# TODO remove hack once Padre supports a better way
	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self, $config->{type} );

	return $self->SUPER::get_indentation_style;
}

# Called when the a key is pressed
sub on_key_down {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	# Workaround to get moose plugin configuration... :)
	require Padre::Plugin::Moose;
	my $config = Padre::Plugin::Moose::_plugin_config();

	# Shortcut if snippets feature is disabled
	unless ( $config->{snippets} ) {

		# Keep processing and exit
		$event->Skip(1);
		return;
	}

	# Load snippets everything since it be changed by the user at runtime
	$self->_load_snippets($config);

	# Syntax highlight Moose keywords here also :)
	# TODO remove hack once Padre supports a better way
	require Padre::Plugin::Moose::Util;
	Padre::Plugin::Moose::Util::add_moose_keywords_highlighting( $self, $config->{type} );

	#TODO TAB to other variables
	#TODO draw a box around values
	if ( defined $self->{_snippets} && $event->GetKeyCode == Wx::WXK_TAB ) {
		if ( $self->_insert_snippet($editor) ) {

			# consume the <TAB>-triggerred snippet event
			return;
		}
	}

	# Keep processing events
	$event->Skip(1);

	return;
}

sub _insert_snippet {
	my $self   = shift;
	my $editor = shift;

	my $pos  = $editor->GetCurrentPos;
	my $line = $editor->GetTextRange(
		$editor->PositionFromLine( $editor->LineFromPosition($pos) ),
		$pos
	);

	my $snippet_obj = $self->_find_snippet($line);
	return unless defined $snippet_obj;

	my $trigger = $snippet_obj->{trigger};
	my $snippet = $snippet_obj->{snippet};

	# If it is tab key down event, we cycle through snippets
	# to find a ^match.
	my $cursor = '${1:property}';

	# Collect and highlight all variables in the snippet
	$self->{variables} = [];
	my $snippet_pattern = qr/
		\${(\d+)(\:(.+?))?}  # ${1:property name} or ${1}
		| (\$\d+)            # $1
	/x;
	while ( $snippet =~ /$snippet_pattern/g ) {
		my $var = {
			index => $1,
			value => $2,
			start => pos($snippet),
		};
		push @{ $self->{variables} }, $var;
		if ( $var->{index} eq '1' ) {

			# Found the first cursor
			$self->{_cursor} = $var;
		}
	}

	# Find the first cursor
	#my $cursor = $self->{_cursor} or return;


	# Prepare to replace variables
	my $len  = length($trigger);
	my $text = $snippet;

	for my $var ( @{ $self->{variables} } ) {
		my $index = $var->{index};
		my $value = $var->{value};
		$text =~ s/\${$index\:(.+?)}/$value/;
	}

	# We paste the snippet and position the cursor to
	# the first variable (e.g ${1:xyz})
	$editor->SetTargetStart( $pos - $len );
	$editor->SetTargetEnd($pos);
	$editor->ReplaceTarget($text);

	if ( $snippet =~ /(\Q$cursor\E)/g ) {
		my $start = $pos - $len + pos($snippet) - length($cursor);
		$editor->GotoPos($start);
		$editor->SetSelection( $start, $start + length 'property' );
	}

	# Snippet inserted
	return 1;
}

# Returns the snippet template or undef
sub _find_snippet {
	my $self = shift;
	my $line = shift;

	my %snippets = %{ $self->{_snippets} };
	for my $trigger ( keys %snippets ) {
		if ( $line =~ /\b\Q$trigger\E$/ ) {
			return {
				trigger => $trigger,
				snippet => $snippets{$trigger},
			};
		}
	}

	return;
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Document - Padre Perl document with Moose highlighting

=cut
