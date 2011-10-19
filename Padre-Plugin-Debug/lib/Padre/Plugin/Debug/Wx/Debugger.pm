package Padre::Plugin::Debug::Wx::Debugger;

=pod

=head1 NAME

Padre::Wx::Debugger - Interface to the Perl debugger.

=head1 DESCRIPTION

Padre::Wx::Debugger provides a wrapper for the generalised L<Debug::Client>.

It should really live at Padre::Debugger, but does not currently have
sufficient abstraction from L<Wx>.

=head1 METHODS

=cut

use 5.010;
use strict;
use warnings;
use Padre::Constant ();
use Padre::Current  ();
use Padre::Wx       ();

# use Padre::Wx::Role::View ();
use Padre::Logger qw(TRACE DEBUG);
use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.91';

# our @ISA     = qw{ Padre::Wx::Role::View };

=pod

=head2 new

Simple constructor.

=cut

sub new { # todo use a better object constructor
	my $class = shift; # What class are we constructing?
	my $self  = {};    # Allocate new memory
	bless $self, $class; # Mark it of the right type
	$self->_init(@_);    # Call _init with remaining args
	return $self;
} #new

sub _init {
	my ( $self, @args ) = @_;

	$self->{client} = undef;
	$self->{file}   = undef;
	$self->{save}   = {};

	return $self;
} #_init

# sub new {
# my $class = shift;

# # 	my $self = bless {
# client => undef,
# file   => undef,
# save   => {},
# }, $class;
# return $self;
# }

sub message {
	Padre::Current->main->message( $_[1] );
}

sub error {
	Padre::Current->main->error( $_[1] );
}

=pod

=head2 debug_perl

  $main->debug_perl;

Run current document under Perl debugger. An error is reported if
current is not a Perl document.

Returns true if debugger successfully started.

=cut

sub debug_perl {
	my $self     = shift;
	my $current  = Padre::Current->new;
	my $main     = $current->main;
	my $document = $current->document;
	my $editor   = $current->editor;

	$main->show_debug(1);
	$self->show_debug_output(1);
	$self->show_debug_variable(1);

	if ( $self->{client} ) {
		$main->error( Wx::gettext('Debugger is already running') );
		return;
	}
	unless ( $document->isa('Padre::Document::Perl') ) {
		$main->error( Wx::gettext('Not a Perl document') );
		return;
	}

	# Apply the user's save-on-run policy
	# TO DO: Make this code suck less
	my $config = $main->config;
	if ( $config->run_save eq 'same' ) {
		$main->on_save;
	} elsif ( $config->run_save eq 'all_files' ) {
		$main->on_save_all;
	} elsif ( $config->run_save eq 'all_buffer' ) {
		$main->on_save_all;
	}

	# Get the filename
	my $filename = defined( $document->{file} ) ? $document->{file}->filename : undef;

	# TODO: improve the message displayed to the user
	# If the document is not saved, simply return for now
	return unless $filename;

	# Set up the debugger
	my $host = 'localhost';
	my $port = 12345 + int rand(1000); # TODO make this configurable?
	SCOPE: {
		local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
		$main->run_command( $document->get_command( { debug => 1 } ) );
	}

	# Bootstrap the debugger
	require Debug::Client;
	$self->{client} = Debug::Client->new(
		host => $host,
		port => $port,
	);
	$self->{client}->listen;

	$self->{file} = $filename;

	# we can use this to extract bp against
	# p $self->{file};

	my ( $module, $file, $row, $content ) = $self->{client}->get;

	# p $module;
	# p $file;
	# p $row;
	# say 'content';
	# p $content;

	my $save = ( $self->{save}->{$filename} ||= {} );
	#######
	#TODO add write breakpoints to $self->{client}->set_breakpoint
	# require Padre::Plugin::Debug::Breakpoints;
	# Padre::Plugin::Debug::Breakpoints::test();

	$self->_get_bp_db();

	#######
	# if ( $save->{breakpoints} ) {
	# foreach my $file ( keys %{ $save->{breakpoints} } ) {
	# foreach my $row ( keys %{ $save->{breakpoints}->{$file} } ) {

	# # 				# TODO what if this fails?
	# # TODO find the editor of that $file first!
	# $self->{client}->set_breakpoint( $file, $row );
	# }
	# }
	# }
	#######

	unless ( $self->_set_debugger ) {
		$main->error( Wx::gettext('Debugging failed. Did you check your program for syntax errors?') );
		$self->debug_perl_quit;
		return;
	}

	return 1;
}

sub _set_debugger {
	my $self    = shift;
	my $current = Padre::Current->new;
	my $main    = $current->main;
	my $editor  = $current->editor or return;
	my $file    = $self->{client}->{filename} or return;
	my $row     = $self->{client}->{row} or return;

	# Open the file if needed
	if ( $editor->{Document}->filename ne $file ) {
		$main->setup_editor($file);
		$editor = $main->current->editor;
		$self->_show_bp_autoload();
	}

	$editor->goto_line_centerize( $row - 1 );

	#### TODO this was taken from the Padre::Wx::Syntax::start() and  changed a bit.
	# They should be reunited soon !!!! (or not)

	# $editor->SetMarginWidth( Padre::Constant::MARGIN_MARKER, 16 );
	$editor->MarkerDeleteAll( Padre::Constant::MARKER_LOCATION() );
	$editor->MarkerAdd( $row - 1, Padre::Constant::MARKER_LOCATION() );

	my $debugger = $main->debugger;
	my $count    = $debugger->GetItemCount;
	foreach my $c ( 0 .. $count - 1 ) {
		my $variable = $debugger->GetItemText($c);
		my $value = eval { $self->{client}->get_value($variable); };
		if ($@) {

			#$main->error(sprintf(Wx::gettext("Could not evaluate '%s'"), $text));
			#return;
		} else {
			$debugger->SetItem( $c, 1, $value );
		}
	}

	return 1;
}

sub running {
	my $self = shift;

	unless ( $self->{client} ) {
		Padre::Current->main->message(
			Wx::gettext(
				"The debugger is not running.\nYou can start the debugger using one of the commands 'Step In', 'Step Over', or 'Run till Breakpoint' in the Debug menu."
			),
			Wx::gettext('Debugger not running')
		);
		return;
	}

	return !!Padre::Current->editor;
}

# sub debug_perl_remove_breakpoint {
# my $self = shift;
# $self->running or return;

# # 	my $editor = Padre::Current->editor;
# my $file   = $editor->{Document}->filename;
# my $row    = $editor->GetCurrentLine + 1;
# $self->{client}->remove_breakpoint( $file, $row );
# delete $self->{save}->{ $self->{file} }->{breakpoints}->{$file}->{$row};

# # 	return;
# }

# sub debug_perl_set_breakpoint {
# my $self = shift;
# $self->running or return;

# # 	my $editor = Padre::Current->editor;
# my $file   = $editor->{Document}->filename;
# my $row    = $editor->GetCurrentLine + 1;

# # 	# TODO ask for a condition
# # TODO allow setting breakpoints even before the script and the debugger runs
# # (by saving it in the debugger configuration file?)
# if ( not $self->{client}->set_breakpoint( $file, $row ) ) {
# $self->error( sprintf( Wx::gettext("Could not set breakpoint on file '%s' row '%s'"), $file, $row ) );
# return;
# }

# # 	# $editor->MarkerAdd( $row - 1, Padre::Constant::MARKER_BREAKPOINT );

# # 	# TODO: This should be the condition I guess
# $self->{save}->{ $self->{file} }->{breakpoints}->{$file}->{$row} = 1;

# # 	return;
# }

# sub debug_perl_list_breakpoints {
# my $self = shift;
# $self->running or return;

# # 	# LIST context crashes in Debug::Client 0.10
# $self->message( scalar $self->{client}->list_break_watch_action );

# # 	return;
# }

sub debug_perl_jumpt_to {
	my $self = shift;
	$self->running or return;
	$self->_set_debugger;
	return;
}

sub debug_perl_quit {
	my $self = shift;
	$self->running or return;

	# Clean up the GUI artifacts
	my $current = Padre::Current->new;
	$current->main->show_debug(0);
	$self->show_debug_output(0);
	$self->show_debug_variable(0);
	$current->editor->MarkerDeleteAll( Padre::Constant::MARKER_LOCATION() );

	# Detach the debugger
	$self->{client}->quit;
	delete $self->{client};

	return;
}

sub step_in {
	my $self = shift;

	# p $self->{client};

	unless ( $self->{client} ) {
		unless ( $self->debug_perl ) {
			Padre::Current->main->error( Wx::gettext('Debugger not running') );
			return;
		}

		# No need to make first step
		return;
	}

	my ( $module, $file, $row, $content ) = $self->{client}->step_in;
	if ( $module eq '<TERMINATED>' ) {
		TRACE('TERMINATED') if DEBUG;
		$self->debug_perl_quit;
		return;
	}

	# p $self->{client}->buffer;
	# p $self->{client}->get_yvalue(0);
	# $self->{panel_debug_output}->debug_output( $self->{client}->get_yvalue(0) );
	# p $self->{client}->get_yvalue(1);
	my $output = $self->{client}->buffer;
	$output .= "\n" . $self->{client}->get_yvalue(0);
	$self->{panel_debug_output}->debug_output($output);

	$self->_set_debugger;

	return;
}

sub debug_perl_step_over {
	my $self = shift;

	unless ( $self->{client} ) {
		unless ( $self->debug_perl ) {
			Padre::Current->main->error( Wx::gettext('Debugger not running') );
			return;
		}
	}

	my ( $module, $file, $row, $content ) = $self->{client}->step_over;
	if ( $module eq '<TERMINATED>' ) {
		TRACE('TERMINATED') if DEBUG;
		$self->debug_perl_quit;
		return;
	}
	$self->_set_debugger;

	return;
}

# sub debug_perl_run_to_cursor {
# my $self = shift;
# Padre::Current->main->error("Not implemented");

# # 	# Commented our for critic:
# #	my $file = $current->filename;
# #	my $row  = '';
# #
# #	# put a breakpoint to the cursor and then run till there
# #	$self->debug_perl_run;
# }

sub debug_perl_run_till {
	my $self  = shift;
	my $param = shift;

	unless ( $self->{client} ) {
		unless ( $self->debug_perl ) {
			Padre::Current->main->error( Wx::gettext('Debugger not running') );
			return;
		}
	}

	my ( $module, $file, $row, $content ) = $self->{client}->run($param);
	if ( $module eq '<TERMINATED>' ) {
		TRACE('TERMINATED') if DEBUG;
		$self->debug_perl_quit;
		return;
	}

	# say 'inside run till';
	# p $self->{client};
	# p $self->{client}->show_line;
	# p $self->{client}->buffer;
	my $output = $self->{client}->buffer;

	# p $self->{client}->get_yvalue(0);
	$output .= "\n" . $self->{client}->get_yvalue(0);
	$self->{panel_debug_output}->debug_output($output);

	# p $self->{client}->get_yvalue(1);
	# p @stack_trace;

	$self->_set_debugger;

	return;
}

sub debug_perl_step_out {
	my $self = shift;

	unless ( $self->{client} ) {
		Padre::Current->main->error( Wx::gettext('Debugger not running') );
		return;
	}

	my ( $module, $file, $row, $content ) = $self->{client}->step_out;
	if ( $module eq '<TERMINATED>' ) {
		TRACE('TERMINATED') if DEBUG;
		$self->debug_perl_quit;
		return;
	}
	$self->_set_debugger;

	return;
}

sub debug_perl_show_stack_trace {
	my $self = shift;
	$self->running or return;

	my $trace = $self->{client}->get_stack_trace;
	my $str   = $trace;
	if ( ref($trace) and ref($trace) eq 'ARRAY' ) {
		$str = join "\n", @$trace;
	}
	$self->message($str);

	return;
}

sub debug_perl_show_value {
	my $self = shift;
	$self->running or return;

	my $text = $self->_debug_get_variable or return;

	my $value = eval { $self->{client}->get_value($text) };
	if ($@) {
		$self->error( sprintf( Wx::gettext("Could not evaluate '%s'"), $text ) );
		return;
	}
	say "text: $text => value: $value";
	$self->message("$text = $value");

	return;
}

sub _debug_get_variable {
	my $self = shift;
	my $document = Padre::Current->document or return;

	#my $text = $current->text;
	my ( $location, $text ) = $document->get_current_symbol;
	p $location;
	p $text;
	if ( not $text or $text !~ m/^[\$@%\\]/smx ) {
		Padre::Current->main->error(
			sprintf(
				Wx::gettext(
					"'%s' does not look like a variable. First select a variable in the code and then try again."),
				$text
			)
		);
		return;
	}
	return $text;
}

sub display_value {
	my $self = shift;
	$self->running or return;

	my $text = $self->_debug_get_variable or return;

	# p $text;
	my $debugger = Padre::Current->main->debugger;

	# p $debugger;
	my $count = $debugger->GetItemCount;

	# p $count;
	my $idx = $debugger->InsertStringItem( $count + 1, $text );

	# p $idx;

	#	my $value = eval { $self->{client}->get_value($text) };
	#	if ($@) {
	#		$main->error(sprintf(Wx::gettext("Could not evaluate '%s'"), $text));
	#		return;
	#	} else {
	#		$debugger->SetItem( $idx, 1, $value );
	#	}
}

sub debug_perl_evaluate_expression {
	my $self = shift;
	$self->running or return;

	my $expression = Padre::Current->main->prompt(
		Wx::gettext("Expression:"),
		Wx::gettext("Expr"),
		"EVAL_EXPRESSION"
	);
	$self->{client}->execute_code($expression);

	return;
}

sub quit {
	my $self = shift;
	if ( $self->{client} ) {
		$self->_quit;
	}
	return;
}


#######
# internal method _setup_db connector
#######
sub _setup_db {
	my $self = shift;

	# set padre db relation
	$self->{debug_breakpoints} = ('Padre::DB::DebugBreakpoints');

	# p $self->{debug_breakpoints};
	# p $self->{debug_breakpoints}->table_info;
	# p $self->{debug_breakpoints}->select;
	return;
}

#######
# Composed Method,
# display any relation db
#######
sub _get_bp_db {
	my $self = shift;

	#TODO should realy test follow someware
	$self->_setup_db();
	my $editor = Padre::Current->editor;

	$self->{project_dir}  = Padre::Current->document->project_dir;
	$self->{current_file} = Padre::Current->document->filename;

	TRACE("current file from _get_bp_db: $self->{current_file}") if DEBUG;

	my $sql_select = 'ORDER BY filename ASC, line_number ASC';
	my @tuples     = $self->{debug_breakpoints}->select($sql_select);

	for ( 0 .. $#tuples ) {

		if ( $tuples[$_][1] =~ m/^ $self->{project_dir} /sxm ) {
			TRACE("show breakpoints autoload: self->{client}->set_breakpoint: $tuples[$_][1] => $tuples[$_][2]")
				if DEBUG;

			$self->{client}->set_breakpoint( $tuples[$_][1], $tuples[$_][2] );

			if ( $tuples[$_][1] =~ m/^$self->{current_file}/ ) {
				$editor->MarkerAdd( $tuples[$_][2] - 1, Padre::Constant::MARKER_BREAKPOINT() );
			}

		}
	}
	return;
}

#######
# Composed Method, _show_bp_autoload
# for an autoloaded file (current) display breakpoints in editor if any
#######
sub _show_bp_autoload {
	my $self = shift;

	#TODO is there a better way
	my $editor = Padre::Current->editor;
	$self->{current_file} = Padre::Current->document->filename;

	my $sql_select = "WHERE filename = \"$self->{current_file}\"";
	my @tuples     = $self->{debug_breakpoints}->select($sql_select);

	for ( 0 .. $#tuples ) {

		TRACE("show breakpoints autoload: self->{client}->set_breakpoint: $tuples[$_][1] => $tuples[$_][2]") if DEBUG;
		$editor->MarkerAdd( $tuples[$_][2] - 1, Padre::Constant::MARKER_BREAKPOINT() );
	}

	return;
}

########
# Panel Controler show debug output
########
sub show_debug_output {
	my $self = shift;

	# my $main = $self->main;
	my $current = Padre::Current->new;
	my $main    = $current->main;
	my $show    = ( @_ ? ( $_[0] ? 1 : 0 ) : 1 );

	# Construct debug output panel if it is not there
	unless ( $self->{panel_debug_output} ) {
		require Padre::Plugin::Debug::DebugOutput;
		$self->{panel_debug_output} = Padre::Plugin::Debug::DebugOutput->new($main);
	}

	$self->_show_debug_output($show);

	$main->aui->Update;

	return;
}

########
# Panel Launcher show debug output
########
sub _show_debug_output {
	my $self = shift;

	# my $main = $self->main;
	my $current = Padre::Current->new;
	my $main    = $current->main;

	if ( $_[0] ) {
		$main->bottom->show( $self->{panel_debug_output} );
	} else {
		$main->bottom->hide( $self->{panel_debug_output} );
		delete $self->{panel_debug_output};
	}

	return;
}

########
# Panel Controler show debug output
########
sub show_debug_variable {
	my $self = shift;
	my $current = Padre::Current->new;
	my $main    = $current->main;
	my $show    = ( @_ ? ( $_[0] ? 1 : 0 ) : 1 );

	# Construct debug output panel if it is not there
	unless ( $self->{panel_debug_variable} ) {
		require Padre::Plugin::Debug::DebugVariable;
		$self->{panel_debug_variable} = Padre::Plugin::Debug::DebugVariable->new($main);
	}

	$self->_show_debug_variable($show);

	$main->aui->Update;

	return;
}

########
# Panel Launcher show debug variable
########
sub _show_debug_variable {
	my $self = shift;

	# my $main = $self->main;
	my $current = Padre::Current->new;
	my $main    = $current->main;

	if ( $_[0] ) {
		$main->right->show( $self->{panel_debug_variable} );
	} else {
		$main->right->hide( $self->{panel_debug_variable} );
		delete $self->{panel_debug_variable};
	}

	return;
}

1;

# TODO:
# Keep the debugger window open even after ending the script

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
