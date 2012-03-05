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
	if ($@) {

		# TODO what to do here to make it useful
		warn $@ . "\n";
	}

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

	my $key_code = $event->GetKeyCode;

	if (   $key_code == Wx::WXK_UP
		|| $key_code == Wx::WXK_DOWN
		|| $key_code == Wx::WXK_RIGHT
		|| $key_code == Wx::WXK_LEFT
		|| $key_code == Wx::WXK_HOME
		|| $key_code == Wx::WXK_END
		|| $key_code == Wx::WXK_DELETE
		|| $key_code == Wx::WXK_PAGEUP
		|| $key_code == Wx::WXK_PAGEDOWN
		|| $key_code == Wx::WXK_NUMPAD_UP
		|| $key_code == Wx::WXK_NUMPAD_DOWN
		|| $key_code == Wx::WXK_NUMPAD_RIGHT
		|| $key_code == Wx::WXK_NUMPAD_LEFT
		|| $key_code == Wx::WXK_NUMPAD_HOME
		|| $key_code == Wx::WXK_NUMPAD_END
		|| $key_code == Wx::WXK_NUMPAD_DELETE
		|| $key_code == Wx::WXK_NUMPAD_PAGEUP
		|| $key_code == Wx::WXK_NUMPAD_PAGEDOWN )
	{

		if(defined $self->{variables}) {
			$self->{variables} = undef;
		}
	} elsif ( defined $self->{_snippets} && ( $key_code == Wx::WXK_TAB || $key_code == Wx::WXK_NUMPAD_TAB ) ) {
		if ( $self->_insert_snippet( $editor, $event->ShiftDown ) ) {

			# consume the <TAB>-triggerred snippet event
			return;
		}
	}

	# Keep processing events
	$event->Skip(1);

	return;
}

sub _insert_snippet {
	my $self       = shift;
	my $editor     = shift;
	my $shift_down = shift;

	my $pos;
	my $snippet;
	my $trigger;
	if(defined $self->{variables}) {
		$pos     = $self->{_pos};
		$snippet = $self->{_snippet};
		$trigger = $self->{_trigger};
	} else {
		$pos  = $editor->GetCurrentPos;
		my $line = $editor->GetTextRange(
			$editor->PositionFromLine( $editor->LineFromPosition($pos) ),
			$pos
		);

		my $snippet_obj = $self->_find_snippet($line);
		return unless defined $snippet_obj;
		
		$self->{_pos} = $pos;
		$snippet = $self->{_snippet} = $snippet_obj->{snippet};
		$trigger = $self->{_trigger} = $snippet_obj->{trigger};
	}


	# Collect and highlight all variables in the snippet
	my $vars;
	my $first_time;
	my $last_time;
	if(defined $self->{variables}) {
		# Already in snippet mode
		$vars = $self->{variables};
		if($shift_down) {
			$self->{selected_index}--;
		} else {
			$self->{selected_index}++;
		}
		
		if($self->{selected_index} > $self->{last_index}) {
			# exit snippet mode and position at end
			$self->{variables} = undef;
			$last_time = 1;
		} elsif($self->{selected_index} < 1) {
			# Shift-tabbing to traverse them in circular fashion
			$self->{selected_index} = $self->{last_index};
		}

	} else {
		# Not defined, create an empty one
		$vars = $self->{variables} = [];
		$self->{selected_index}    = 1;
		$first_time = 1;

		# Build snippet variables array
		my $last_index = 0;
		my $snippet_pattern = qr/
			(			# int is integer
			\${(\d+)(\:(.*?))?}     # ${int:default value} or ${int}
			|  \$(\d+)              # $int
			)
		/x;
		while ( $snippet =~ /$snippet_pattern/g ) {
			my $index = defined $5 ? int($5) : int($2);
			if($last_index < $index) {
				$last_index = $index;
			}
			my $var = {
				index => $index,
				text  => $1,
				value => $4,
				start => pos($snippet) - length($1),
			};
			push @$vars, $var;
		}
		$self->{last_index} = $last_index;
	}


	# Prepare to replace variables
	my $len  = length($trigger);
	my $text = $snippet;

	# Find the next cursor
	my $cursor;
	my $count = 0;
	for my $var (@$vars) {
		unless ( defined $var->{value} ) {
			my $index = $var->{index};
			for my $v (@$vars) {
				my $value = $v->{value};
				if ( ( $v->{index} == $index ) && defined $value ) {
					my $before_length = length $text;
					$v->{start} += $count;
					substr($text, $v->{start}, length $v->{text}) = $value;
					my $after_length = length $text;
					$count += $after_length - $before_length;
					last;
				}
			}
		} else {
			my $before_length = length $text;
			$var->{start} += $count;
			substr($text, $var->{start}, length $var->{text}) = $var->{value};
			my $after_length = length $text;
			$count += $after_length - $before_length;
			
			if ( $var->{index} == $self->{selected_index} ) {
				$cursor = $var;
			}
		}

	}

	# We paste the snippet and position the cursor to
	# the first variable (e.g ${1:xyz})
	if($first_time) {
		$editor->SetTargetStart( $pos - $len );
		$editor->SetTargetEnd($pos);
		$editor->ReplaceTarget($text);
		
		my $start = $pos - $len + $cursor->{start};
		$editor->GotoPos($start);
		$editor->SetSelection( $start, $start + length $cursor->{value} );
	} else {
		if($last_time) {
			$editor->GotoPos($pos - $len + length $text);
		} else {
			$editor->SetTargetStart( $pos - $len );
			$editor->SetTargetEnd( $pos - $len + length $text );
			$editor->ReplaceTarget($text);

			my $start = $pos - $len + $cursor->{start};	
			$editor->GotoPos($start);
			$editor->SetSelection( $start, $start + length $cursor->{value} );
		}
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
