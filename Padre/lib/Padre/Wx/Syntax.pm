package Padre::Wx::Syntax;

use 5.008;
use strict;
use warnings;
use Params::Util          ();
use Padre::Feature        ();
use Padre::Role::Task     ();
use Padre::Wx::Role::View ();
use Padre::Wx::Role::Main ();
use Padre::Wx             ();
use Padre::Wx::Icon       ();
use Padre::Wx::TreeCtrl   ();
use Padre::Wx::HtmlWindow ();
use Padre::Logger;

our $VERSION = '0.91';
our @ISA     = qw{
	Padre::Role::Task
	Padre::Wx::Role::View
	Padre::Wx::Role::Main
	Wx::Panel
};

# perldiag error message classification
my %MESSAGE = (

	# (W) A warning (optional).
	'W' => {
		label  => Wx::gettext('Warning'),
		marker => Padre::Wx::MarkWarn(),
	},

	# (D) A deprecation (enabled by default).
	'D' => {
		label  => Wx::gettext('Deprecation'),
		marker => Padre::Wx::MarkWarn(),
	},

	# (S) A severe warning (enabled by default).
	'S' => {
		label  => Wx::gettext('Severe Warning'),
		marker => Padre::Wx::MarkWarn(),
	},

	# (F) A fatal error (trappable).
	'F' => {
		label  => Wx::gettext('Fatal Error'),
		marker => Padre::Wx::MarkError(),
	},

	# (P) An internal error you should never see (trappable).
	'P' => {
		label  => Wx::gettext('Internal Error'),
		marker => Padre::Wx::MarkError(),
	},

	# (X) A very fatal error (nontrappable).
	'X' => {
		label  => Wx::gettext('Very Fatal Error'),
		marker => Padre::Wx::MarkError(),
	},

	# (A) An alien error message (not generated by Perl).
	'A' => {
		label  => Wx::gettext('Alien Error'),
		marker => Padre::Wx::MarkError(),
	},
);

sub new {
	my $class = shift;
	my $main  = shift;
	my $panel = shift || $main->bottom;
	my $self  = $class->SUPER::new($panel);

	# Create the underlying object
	$self->{tree} = Padre::Wx::TreeCtrl->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TR_SINGLE | Wx::TR_FULL_ROW_HIGHLIGHT | Wx::TR_HAS_BUTTONS
	);

	$self->{help} = Padre::Wx::HtmlWindow->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::BORDER_STATIC,
	);
	$self->{help}->Hide;

	my $sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$sizer->Add( $self->{tree}, 3, Wx::ALL | Wx::EXPAND, 0 );
	$sizer->Add( $self->{help}, 2, Wx::ALL | Wx::EXPAND, 0 );
	$self->SetSizer($sizer);

	# Additional properties
	$self->{model}  = {};
	$self->{length} = -1;

	# Prepare the available images
	my $images = Wx::ImageList->new( 16, 16 );
	$self->{images} = {
		error       => $images->Add( Padre::Wx::Icon::icon('status/padre-syntax-error') ),
		warning     => $images->Add( Padre::Wx::Icon::icon('status/padre-syntax-warning') ),
		ok          => $images->Add( Padre::Wx::Icon::icon('status/padre-syntax-ok') ),
		diagnostics => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_GO_FORWARD',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
		root => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_HELP_FOLDER',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
	};
	$self->{tree}->AssignImageList($images);

	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self,
		$self->{tree},
		sub {
			shift->on_tree_item_activated(@_);
		},
	);

	Wx::Event::EVT_TREE_SEL_CHANGED(
		$self,
		$self->{tree},
		sub {
			shift->on_tree_item_selection_changed(@_);
		},
	);

	$self->Hide;

	if (Padre::Feature::STYLE_GUI) {
		$self->recolour;
	}

	return $self;
}





######################################################################
# Padre::Wx::Role::View Methods

sub view_panel {
	return 'bottom';
}

sub view_label {
	shift->gettext_label(@_);
}

sub view_close {
	$_[0]->main->show_syntaxcheck(0);
}

sub view_start {
	my $self = shift;

	# Add the margins for the syntax markers
	foreach my $editor ( $self->main->editors ) {

		# Margin number 1 for symbols
		$editor->SetMarginType( 1, Wx::wxSTC_MARGIN_SYMBOL );

		# Set margin 1 16 px wide
		$editor->SetMarginWidth( 1, 16 );
	}
}

sub view_stop {
	my $self = shift;
	my $main = $self->main;
	my $lock = $main->lock('UPDATE');

	# Clear out any state and tasks
	$self->task_reset;
	$self->clear;

	# Remove the editor margins
	foreach my $editor ( $main->editors ) {
		$editor->SetMarginWidth( 1, 0 );
	}

	return;
}





#####################################################################
# Event Handlers

sub on_tree_item_selection_changed {
	my $self  = shift;
	my $event = shift;
	my $item  = $event->GetItem or return;
	my $issue = $self->{tree}->GetPlData($item);

	if ( $issue and $issue->{diagnostics} ) {
		my $diag = $issue->{diagnostics};
		$self->_update_help_page($diag);
	} else {
		$self->_update_help_page;
	}
}

sub on_tree_item_activated {
	my $self   = shift;
	my $event  = shift;
	my $item   = $event->GetItem or return;
	my $issue  = $self->{tree}->GetPlData($item) or return;
	my $editor = $self->current->editor or return;
	my $line   = $issue->{line};

	# Does it point to somewhere valid?
	return unless defined $line;
	return if $line !~ /^\d+$/o;
	return if $editor->GetLineCount < $line;

	# Select the problem after the event has finished
	Wx::Event::EVT_IDLE(
		$self,
		sub {
			$self->select_problem( $line - 1 );
			Wx::Event::EVT_IDLE( $self, undef );
		},
	);
}





#####################################################################
# General Methods

sub bottom {
	TRACE("DEPRECATED") if DEBUG;
	shift->main->bottom;
}

sub gettext_label {
	Wx::gettext('Syntax Check');
}

# Remove all markers and empty the list
sub clear {
	my $self = shift;
	my $lock = $self->main->lock('UPDATE');

	# Remove the margins and indicators for the syntax markers
	foreach my $editor ( $self->main->editors ) {
		$editor->MarkerDeleteAll(Padre::Wx::MarkError);
		$editor->MarkerDeleteAll(Padre::Wx::MarkWarn);

		my $len = $editor->GetTextLength;
		if ( $len > 0 ) {
			if ( $editor->can('SetIndicatorCurrent') and $editor->can('IndicatorClearRange') ) {

				# Using modern indicator API if available
				$editor->SetIndicatorCurrent( Padre::Wx::Editor::INDICATOR_WARNING() );
				$editor->IndicatorClearRange( 0, $len );
				$editor->SetIndicatorCurrent( Padre::Wx::Editor::INDICATOR_ERROR() );
				$editor->IndicatorClearRange( 0, $len );
			} else {

				# Or revert to the old deprecated method
				$editor->StartStyling( 0, Wx::wxSTC_INDICS_MASK );
				$editor->SetStyling( $len - 1, 0 );
			}
		}

		# Clear all annotations if it is available and the feature is enabled
		if(Padre::Feature::SYNTAX_CHECK_ANNOTATIONS && $editor->can('AnnotationClearAll')) {
			$editor->AnnotationClearAll;
		}
	}

	# Remove all items from the tool
	$self->{tree}->DeleteAllItems;

	# Clear the help page
	$self->_update_help_page;

	return;
}

# Pick up colouring from the current editor style
sub recolour {
	my $self   = shift;
	my $config = $self->config;

	# Load the editor style
	require Padre::Wx::Editor;
	my $data = Padre::Wx::Editor::data( $config->editor_style ) or return;

	# Find the colours we need
	my $foreground = $data->{padre}->{colors}->{PADRE_BLACK}->{foreground};
	my $background = $data->{padre}->{background};

	# Apply them to the widgets
	if ( defined $foreground and defined $background ) {
		$foreground = Padre::Wx::color($foreground);
		$background = Padre::Wx::color($background);

		$self->{tree}->SetForegroundColour($foreground);
		$self->{tree}->SetBackgroundColour($background);
	}

	return 1;
}

# Nothing to implement here
sub relocale {
	return;
}

sub refresh {
	my $self     = shift;
	my $current  = shift or return;
	my $document = $current->document;
	my $tree     = $self->{tree};
	my $lock     = $self->main->lock('UPDATE');

	# Abort any in-flight checks
	$self->task_reset;

	# Hide the widgets when no files are open
	unless ($document) {
		$self->clear;
		$tree->Hide;
		return;
	}

	# Is there a syntax check task for this document type
	my $task = $document->task_syntax;
	unless ($task) {
		$self->clear;
		$tree->Hide;
		return;
	}

	# Ensure the widget is visible
	$tree->Show(1);

	# Clear out the syntax check window, leaving the margin as is
	$self->{tree}->DeleteAllItems;
	$self->_update_help_page;

	# Shortcut if there is nothing in the document to compile
	if ( $document->is_unused ) {
		return;
	}

	# Fire the background task discarding old results
	$self->task_request(
		task     => $task,
		document => $document,
	);

	return 1;
}

sub task_finish {
	my $self = shift;
	my $task = shift;
	$self->{model} = $task->{model};

	# Properly validate and warn about older deprecated syntax models
	if(Params::Util::_HASH0($self->{model})) {
		# We are using the new syntax object model
	} else {
		# Warn about the old array object from syntax task in debug mode
		TRACE q{Syntax checker tasks should now return a hash containing an 'issues' array reference and 'stderr' string keys instead of the old issues array reference} if DEBUG;

		# TODO remove compatibility for older syntax checker model
		$self->{model} = {
			issues => $self->{model},
			stderr => undef,
		};
	}

	$self->render;
}

sub render {
	my $self     = shift;
	my $model    = $self->{model} || {};
	my $current  = $self->current;
	my $editor   = $current->editor;
	my $document = $current->document;
	my $filename = $current->filename;
	my $lock     = $self->main->lock('UPDATE');

	# NOTE: Recolor the document to make sure we do not accidentally
	# remove syntax highlighting while syntax checking
	$document->colourize;

	# Flush old results
	$self->clear;

	my $root = $self->{tree}->AddRoot('Root');

	# If there are no errors or warnings, clear the syntax checker pane
	unless ( Params::Util::_HASH($model) ) {

		# Relative-to-the-project filename.
		# Check that the document has been saved.
		if ( defined $filename ) {
			my $project_dir = $document->project_dir;
			if ( defined $project_dir ) {
				$project_dir = quotemeta $project_dir;
				$filename =~ s/^$project_dir[\\\/]?//;
			}
			$self->{tree}->SetItemText(
				$root,
				sprintf( Wx::gettext('No errors or warnings found in %s.'), $filename )
			);
		} else {
			$self->{tree}->SetItemText( $root, Wx::gettext('No errors or warnings found.') );
		}
		$self->{tree}->SetItemImage( $root, $self->{images}->{ok} );
		return;
	}

	$self->{tree}->SetItemText(
		$root,
		defined $filename
		? sprintf( Wx::gettext('Found %d issue(s) in %s'), scalar @{$model->{issues}}, $filename )
		: sprintf( Wx::gettext('Found %d issue(s)'),       scalar @{$model->{issues}} )
	);
	$self->{tree}->SetItemImage( $root, $self->{images}->{root} );

	# TODO no hardcoding this should configurable in default.yml
	my $WARNING_STYLE = 126;
	my $ERROR_STYLE = $WARNING_STYLE + 1;
	$editor->StyleSetForeground( $WARNING_STYLE, Wx::Colour->new(0xAF, 0x80, 0x00) );
	$editor->StyleSetBackground( $WARNING_STYLE, Wx::Colour->new(0xFF, 0xFF, 0xF0) );
	$editor->StyleSetItalic( $WARNING_STYLE, 1 );
	$editor->StyleSetForeground( $ERROR_STYLE, Wx::Colour->new(0xAF, 0x00, 0x00) );
	$editor->StyleSetBackground( $ERROR_STYLE, Wx::Colour->new(0xFF, 0xF0, 0xF0) );
	$editor->StyleSetItalic( $ERROR_STYLE, 1 );

	my %annotations = ();
	my $i = 0;
	ISSUE:
	foreach my $issue ( sort { $a->{line} <=> $b->{line} } @{$model->{issues}} ) {

		my $line       = $issue->{line} - 1;
		my $type       = exists $issue->{type} ? $issue->{type} : 'F';
		my $marker     = $MESSAGE{$type}{marker};
		my $is_warning = $marker == Padre::Wx::MarkWarn();
		$editor->MarkerAdd( $line, $marker );

		# Underline the syntax warning/error line with an orange or red squiggle indicator
		my $start  = $editor->PositionFromLine($line);
		my $indent = $editor->GetLineIndentPosition($line);
		my $end    = $editor->GetLineEndPosition($line);

		# Change only the indicators
		if ( $editor->can('SetIndicatorCurrent') and $editor->can('IndicatorFillRange') ) {

			# Using modern indicator API if available
			$editor->SetIndicatorCurrent(
				$is_warning ? Padre::Wx::Editor::INDICATOR_WARNING() : Padre::Wx::Editor::INDICATOR_ERROR() );
			$editor->IndicatorFillRange( $indent, $end - $indent );
		} else {

			# Or revert to the old deprecated method
			$editor->StartStyling( $indent, Wx::wxSTC_INDICS_MASK );
			$editor->SetStyling( $end - $indent, $is_warning ? Wx::wxSTC_INDIC1_MASK : Wx::wxSTC_INDIC2_MASK );
		}

		# Collect annotations for later display
		# One annotated line contains multiple errors/warnings
		if(Padre::Feature::SYNTAX_CHECK_ANNOTATIONS) {
			my $message = $issue->message;
			my $char_style = $is_warning ? sprintf('%c', $WARNING_STYLE) : sprintf('%c', $ERROR_STYLE);
			unless($annotations{$line}) {
				$annotations{$line} = {
					message => $message,
					style => $char_style x  length($message),
				};
			} else {
				$annotations{$line}{message} .= "\n$message";
				$annotations{$line}{style} .= $char_style x (length($message) + 1);
			}
		}

		my $item = $self->{tree}->AppendItem(
			$root,
			sprintf(
				Wx::gettext('Line %d:   (%s)   %s'),
				$line + 1,
				$MESSAGE{$type}{label},
				$issue->{message}
			),
			$is_warning ? $self->{images}{warning} : $self->{images}{error}
		);
		$self->{tree}->SetPlData( $item, $issue );
	}

	if(Padre::Feature::SYNTAX_CHECK_ANNOTATIONS) {
		# Add annotations
		foreach my $line (sort keys %annotations) {
			if($editor->can('AnnotationSetText') and $editor->can('AnnotationSetStyles')) {
				my $annotation = $annotations{$line};
				$editor->AnnotationSetText($line, $annotation->{message});
				$editor->AnnotationSetStyles($line, $annotation->{style});
			}
		}

		my $wxSTC_ANNOTATION_BOXED = 2; #TODO use Wx::wxSTC_ANNOTATION_BOXED once it is there
		$editor->AnnotationSetVisible( $wxSTC_ANNOTATION_BOXED );
	}

	$self->{tree}->Expand($root);
	$self->{tree}->EnsureVisible($root);

	return 1;
}

# Updates the help page. It shows the text if it is defined otherwise clears and hides it
sub _update_help_page {
	my $self = shift;
	my $text = shift;

	# load the escaped HTML string into the shown page otherwise hide
	# if the text is undefined
	my $help = $self->{help};
	if ( defined $text ) {
		require CGI;
		$text = CGI::escapeHTML($text);
		$text =~ s/\n/<br>/g;
		my $WARN_TEXT = $MESSAGE{'W'}{label};
		if ( $text =~ /^\((W\s+(\w+)|D|S|F|P|X|A)\)/ ) {
			my ( $category, $warning_category ) = ( $1, $2 );
			my $category_label = ( $category =~ /^W/ ) ? $MESSAGE{'W'}{label} : $MESSAGE{$1}{label};
			my $notes =
				defined($warning_category)
				? "<code>no warnings '$warning_category';    # disable</code><br>"
				. "<code>use warnings '$warning_category';   # enable</code><br><br>"
				: '';
			$text =~ s{^\((W\s+(\w+)|D|S|F|P|X|A)\)}{<h3>$category_label</h3>$notes};
		}
		$help->SetPage($text);
		$help->Show;
	} else {
		$help->SetPage('');
		$help->Hide;
	}

	# Sticky note light-yellow background
	$self->{help}->SetBackgroundColour( Wx::Colour->new( 0xFD, 0xFC, 0xBB ) );

	# Relayout to actually hide/show the help page
	$self->Layout;
}

# Selects the problemistic line :)
sub select_problem {
	my $self   = shift;
	my $line   = shift;
	my $editor = $self->current->editor or return;
	$editor->EnsureVisible($line);
	$editor->goto_pos_centerize( $editor->GetLineIndentPosition($line) );
	$editor->SetFocus;
}

# Selects the next problem in the editor.
# Wraps to the first one when at the end.
sub select_next_problem {
	my $self         = shift;
	my $editor       = $self->current->editor or return;
	my $current_line = $editor->LineFromPosition( $editor->GetCurrentPos );

	# Start with the first child
	my $root = $self->{tree}->GetRootItem;
	my ( $child, $cookie ) = $self->{tree}->GetFirstChild($root);
	my $first_line = undef;
	while ($cookie) {

		# Get the line and check that it is a valid line number
		my $issue = $self->{tree}->GetPlData($child) or return;
		my $line = $issue->{line};

		if (   not defined($line)
			or ( $line !~ /^\d+$/o )
			or ( $line > $editor->GetLineCount ) )
		{
			( $child, $cookie ) = $self->{tree}->GetNextChild( $root, $cookie );
			next;
		}
		$line--;

		if ( not $first_line ) {

			# record the position of the first problem
			$first_line = $line;
		}

		if ( $line > $current_line ) {

			# select the next problem
			$self->select_problem($line);

			# no need to wrap around...
			$first_line = undef;

			# and we're done here...
			last;
		}

		# Get the next child if there is one
		( $child, $cookie ) = $self->{tree}->GetNextChild( $root, $cookie );
	}

	# The next problem is simply the first (wrap around)
	$self->select_problem($first_line) if $first_line;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
