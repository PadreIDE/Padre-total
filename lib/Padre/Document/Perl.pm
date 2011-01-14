package Padre::Document::Perl;

use 5.008;
use strict;
use warnings;
use Carp              ();
use Encode            ();
use File::Spec        ();
use File::Temp        ();
use File::Find::Rule  ();
use Params::Util      ();
use YAML::Tiny        ();
use Padre::Util       ();
use Padre::Perl       ();
use Padre::Document   ();
use Padre::File       ();
use Padre::Role::Task ();
use Padre::Logger;

our $VERSION = '0.78';
our @ISA     = qw{
	Padre::Role::Task
	Padre::Document
};





#####################################################################
# Task Integration

sub task_functions {
	return 'Padre::Document::Perl::FunctionList';
}

sub task_outline {
	return 'Padre::Document::Perl::Outline';
}

sub task_syntax {
	return 'Padre::Document::Perl::Syntax';
}





#####################################################################
# Padre::Document::Perl Methods

# Ticket #637:
# TO DO watch out! These PPI methods may be VERY expensive!
# (Ballpark: Around 1 Gigahertz-second of *BLOCKING* CPU per 1000 lines)
# Check out Padre::Task::PPI and children instead!
sub ppi_get {
	my $self = shift;
	my $text = $self->text_get;
	require PPI::Document;
	PPI::Document->new( \$text );
}

sub ppi_set {
	my $self = shift;
	my $document = Params::Util::_INSTANCE( shift, 'PPI::Document' );
	unless ($document) {
		Carp::croak("Did not provide a PPI::Document");
	}

	# Serialize and overwrite the current text
	$self->text_set( $document->serialize );
}

sub ppi_find {
	shift->ppi_get->find(@_);
}

sub ppi_find_first {
	shift->ppi_get->find_first(@_);
}

sub ppi_transform {
	my $self = shift;
	my $transform = Params::Util::_INSTANCE( shift, 'PPI::Transform' );
	unless ($transform) {
		Carp::croak("Did not provide a PPI::Transform");
	}

	# Apply the transform to the document
	my $document = $self->ppi_get;
	unless ( $transform->document($document) ) {
		Carp::croak("Transform failed");
	}
	$self->ppi_set($document);

	return 1;
}

sub ppi_select {
	my $self     = shift;
	my $location = shift;
	my $editor   = $self->editor or return;
	my $start    = $self->ppi_location_to_character_position($location);
	$editor->SetSelection( $start, $start + 1 );
}

# Convert a ppi-style location [$line, $col, $apparent_col]
# to an absolute document offset
sub ppi_location_to_character_position {
	my $self     = shift;
	my $location = shift;
	if ( Params::Util::_INSTANCE( $location, 'PPI::Element' ) ) {
		$location = $location->location;
	}
	my $editor = $self->editor or return;
	my $line   = $editor->PositionFromLine( $location->[0] - 1 );
	my $start  = $line + $location->[1] - 1;
	return $start;
}

# Convert an absolute document offset to
# a ppi-style location [$line, $col, $apparent_col]
# FIX ME: Doesn't handle $apparent_col right
sub character_position_to_ppi_location {
	my $self     = shift;
	my $position = shift;

	my $ed   = $self->editor;
	my $line = 1 + $ed->LineFromPosition($position);
	my $col  = 1 + $position - $ed->PositionFromLine( $line - 1 );

	return [ $line, $col, $col ];
}

sub set_highlighter {
	my $self   = shift;
	my $module = shift;

	# These are hard coded limits because the PPI highlighter
	# is slow. Probably there is not much use in moving this back to a
	# configuration variable
	my $limit;
	if ( $module eq 'Padre::Document::Perl::PPILexer' ) {
		$limit = $self->current->config->perl_ppi_lexer_limit;
	} elsif ( $module eq 'Padre::Document::Perl::Lexer' ) {
		$limit = 4000;
	} elsif ( $module eq 'Padre::Plugin::Kate' ) {
		$limit = 4000;
	}

	my $length = $self->{original_content} ? length $self->{original_content} : 0;
	my $editor = $self->editor;
	if ($editor) {
		$length = $editor->GetTextLength;
	}

	TRACE( "Setting highlighter for Perl 5 code. length: $length" . ( $limit ? " limit is $limit" : '' ) ) if DEBUG;

	if ( defined $limit and $length > $limit ) {
		TRACE("Forcing STC highlighting") if DEBUG;
		$module = 'stc';
	}

	return $self->SUPER::set_highlighter($module);
}





#####################################################################
# Padre::Document Document Analysis

sub guess_filename {
	my $self = shift;

	# Don't attempt a content-based guess if the file already has a name.
	if ( $self->filename ) {
		return $self->SUPER::guess_filename;
	}

	# Is this a script?
	my $text = $self->text_get;
	if ( $text =~ /^\#\![^\n]*\bperl\b/s ) {

		# It's impossible to predict the name of a script in
		# advance, but lets default to a standard "script.pl"
		return 'script.pl';
	}

	# Is this a module
	if ( $text =~ /\bpackage\s*([\w\:]+)/s ) {

		# Take the last section of the package name, and use that
		# as the file.
		my $name = $1;
		$name =~ s/.*\://;
		return "$name.pm";
	}

	# Otherwise, no idea
	return undef;
}

sub guess_subpath {
	my $self = shift;

	# Don't attempt a content-based guess if the file already has a name.
	if ( $self->filename ) {
		return $self->SUPER::guess_subpath;
	}

	# Is this a script?
	my $text = $self->text_get;
	if ( $text =~ /^\#\![^\n]*\bperl\b/s ) {

		# Is this a test?
		if ( $text =~ /use Test::/ ) {
			return 't';
		} else {
			return 'script';
		}
	}

	# Is this a module?
	if ( $text =~ /\bpackage\s*([\w\:]+)/s ) {

		# Take all but the last section of the package name,
		# and use that as the file.
		my $name = $1;
		my @dirs = split /::/, $name;
		pop @dirs;

		# The use of a module name beginning with t:: is a common
		# pattern for declaring test-only classes.
		if ( $dirs[0] and $dirs[0] eq 't' ) {
			return @dirs;
		}

		return ( 'lib', @dirs );
	}

	# Otherwise, no idea
	return;
}

my $keywords;

sub keywords {
	unless ( defined $keywords ) {
		$keywords = YAML::Tiny::LoadFile( Padre::Util::sharefile( 'languages', 'perl5', 'perl5.yml' ) );
	}
	return $keywords;
}

# This emulates qr/(?<=^|[\012\015])sub\s$name\b/ but without
# triggering a "Variable length lookbehind not implemented" error.
# return qr/(?:(?<=^)\s*sub\s+$_[1]|(?<=[\012\015])\s*sub\s+$_[1])\b/;
sub get_function_regex {
	qr/(?:^|[^# \t])[ \t]*((?:sub|func|method)\s+$_[1])\b/;
}

sub get_functions {
	$_[0]->find_functions( $_[0]->text_get );
}

sub find_functions {
	my $n = "\\cM?\\cJ";
	return grep { defined $_ } $_[1] =~ m/
		(?:
		(?:$n)*__(?:DATA|END)__\b.*
		|
		$n$n=\w+.*?$n$n=cut\b(?=.*?$n$n)
		|
		(?:^|$n)\s*(?:sub|func|method)\s+(\w+(?:::\w+)*)
		)
	/sgx;
}

=pod

=head2 get_command

Returns the full command (interpreter, file name (maybe temporary) and arguments
for both of them) for running the current document.

Optionally accepts a hash reference with the following boolean arguments:
  'debug' - return a command where the debugger is started
  'trace' - activates diagnostic output

=cut

sub get_command {
	my $self = shift;
	my $arg_ref = shift || {};

	my $debug = exists $arg_ref->{debug} ? $arg_ref->{debug} : 0;
	my $trace = exists $arg_ref->{trace} ? $arg_ref->{trace} : 0;

	my $current = Padre::Current->new( document => $self );
	my $config = $current->config;

	# Use a temporary file if run_save is set to 'unsaved'
	my $filename =
		  $config->run_save eq 'unsaved' && !$self->is_saved
		? $self->store_in_tempfile
		: $self->filename;

	# Run with console Perl to prevent unexpected results under wxperl
	# The configuration values is cheaper to get compared to cperl(),
	# try it first.
	my $perl = $self->get_interpreter;

	# Set default arguments
	my %run_args = (
		interpreter => $config->run_interpreter_args_default,
		script      => $config->run_script_args_default,
	);

	# Overwrite default arguments with the ones preferred for given document
	foreach my $arg ( keys %run_args ) {
		my $type = "run_${arg}_args_" . File::Basename::fileparse($filename);
		$run_args{$arg} = Padre::DB::History->previous($type) if Padre::DB::History->previous($type);
	}

	# (Ticket #530) Pack args here, because adding the space later confuses the called Perls @ARGV
	my $script_args = '';
	$script_args = ' ' . $run_args{script} if defined( $run_args{script} ) and ( $run_args{script} ne '' );

	my $dir = File::Basename::dirname($filename);
	chdir $dir;

	my @commands = (qq{"$perl"});
	push @commands, '-d'                        if $debug;
	push @commands, '-Mdiagnostics(-traceonly)' if $trace;
	push @commands, "$run_args{interpreter}";
	push @commands, qq{"$filename"$script_args};

	return join ' ', @commands;
}

=head2 get_interpreter

Returns the Perl interpreter for running the current document.

=cut

sub get_interpreter {
	my $self = shift;
	my $arg_ref = shift || {};

	my $debug = exists $arg_ref->{debug} ? $arg_ref->{debug} : 0;
	my $trace = exists $arg_ref->{trace} ? $arg_ref->{trace} : 0;

	my $current = Padre::Current->new( document => $self );
	my $config = $current->config;

	# The configuration value is cheaper to get compared to cperl(),
	# try it first.
	my $perl = $config->run_perl_cmd;

	# warn if the Perl interpreter is not executable
	if ( defined $perl and $perl ne '' ) {
		if ( !-x $perl ) {
			Padre->ide->wx->main->message(
				Wx::gettext(
					sprintf(
						'%s seems to be no executable Perl interpreter, using the system default perl instead.', $perl
					)
				),
			);
			$perl = Padre::Perl::cperl();
		}
	} else {
		$perl = Padre::Perl::cperl();
	}

	return $perl;
}

sub pre_process {
	my $self = shift;

	if ( Padre->ide->config->editor_beginner ) {
		require Padre::Document::Perl::Beginner;
		my $b = Padre::Document::Perl::Beginner->new( document => $self );
		if ( $b->check( $self->text_get ) ) {
			return 1;
		} else {
			$self->set_errstr( $b->error );
			return;
		}
	}

	return 1;
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Document::Perl::Syntax
sub check_syntax {
	shift->_check_syntax_internals(

		# Passing all arguments is ok, but critic complains
		{   @_, ## no critic (ProhibitCommaSeparatedStatements)
			background => 0
		}
	);
}

sub check_syntax_in_background {
	shift->_check_syntax_internals(

		# Passing all arguments is ok, but critic complains
		{   @_, ## no critic (ProhibitCommaSeparatedStatements)
			background => 1
		}
	);
}

sub _check_syntax_internals {
	my $self = shift;
	my $args = shift;
	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args->{force} ) {
		if ( defined( $self->{last_syncheck_md5} )
			and $self->{last_syncheck_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_syncheck_md5} = $md5;

	require Padre::Document::Perl::Syntax;
	my $task = Padre::Document::Perl::Syntax->new(
		document => $self,
	);

	if ( $args->{background} ) {

		# asynchroneous execution (see on_finish hook)
		$task->schedule;
		return;
	} else {

		# serial execution, returning the result
		$task->prepare or return;
		$task->run;
		$task->finish;
		return $task->{model};
	}
}

=pod

=head2 beginner_check

Run the beginner error checks on the current document.

Shows a pop-up message for the first error.

Always returns 1 (true).

=cut

# Run the checks for common beginner errors
sub beginner_check {
	my $self = shift;

	# TO DO: Make this cool
	# It isn't, because it should show _all_ warnings instead of one and
	# it should at least go to the line it's complaining about.
	# Ticket #534

	require Padre::Document::Perl::Beginner;
	my $beginner = Padre::Document::Perl::Beginner->new(
		document => $self,
		editor   => $self->editor
	);

	$beginner->check( $self->text_get );

	my $error = $beginner->error;

	if ($error) {
		Padre->ide->wx->main->error( Wx::gettext('Error: ') . $error );
	} else {
		Padre->ide->wx->main->message( Wx::gettext('No errors found.') );
	}

	return 1;
}

sub comment_lines_str {
	return '#';
}

sub find_unmatched_brace {
	TRACE("find_unmatched_brace") if DEBUG;
	my $self = shift;

	# Fire the task
	$self->task_request(
		task      => 'Padre::Task::FindUnmatchedBrace',
		document  => $self,
		on_finish => 'find_unmatched_brace_response',
	);

	return;
}

sub find_unmatched_brace_response {
	TRACE("find_unmatched_brace_response") if DEBUG;
	my $self = shift;
	my $task = shift;

	# Found what we were looking for
	if ( $task->{location} ) {
		$self->ppi_select( $task->{location} );
		return;
	}

	# Must have been a clean result
	# TO DO: Convert this to a call to ->main that doesn't require
	# us to use Wx directly.
	Wx::MessageBox(
		Wx::gettext("All braces appear to be matched"),
		Wx::gettext("Check Complete"),
		Wx::wxOK,
		$self->current->main,
	);
}

# finds the start of the current symbol.
# current symbol means in the context something remotely similar
# to what PPI considers a PPI::Token::Symbol, but since we're doing
# it the manual, stupid way, this may also work within quotelikes and regexes.
sub get_current_symbol {
	my $self = shift;
	my $pos  = shift;

	my $editor = $self->editor;
	$pos = $editor->GetCurrentPos if not defined $pos;

	my $line       = $editor->LineFromPosition($pos);
	my $line_start = $editor->PositionFromLine($line);
	my $line_end   = $editor->GetLineEndPosition($line);

	my $cursor_col = $pos - $line_start;
	my $line_content = $editor->GetTextRange( $line_start, $line_end );
	$cursor_col = length($line_content) - 1 if $cursor_col >= length($line_content);
	my $col              = $cursor_col;
	my $symbol_start_pos = $pos;

	# find start of symbol
	# TO DO: This could be more robust, no?
	# Ticket #639
	# if we are at the end of a symbol (maybe we need better detection?), start counting on the previous letter. this should resolve #419 and #654
	$col-- if $col and substr( $line_content, $col - 1, 2 ) =~ /^\w\W$/;
	while (1) {
		last if $col <= 0 or substr( $line_content, $col, 1 ) =~ /^[^#\w:\']$/;
		$col--;
		$symbol_start_pos--;
	}

	return () if $col >= length($line_content);
	if ( substr( $line_content, $col + 1, 1 ) !~ /^[#\w:\']$/ ) {
		return ();
	}

	# Extract the token, too.
	my $token;
	if ( substr( $line_content, $col ) =~ /^\s?(\S+)/ ) {
		$token = $1;
	} else {
		die "This shouldn't happen. The algorithm is wrong";
	}

	# truncate token
	if ( $token =~ /^(\W*[\w:]+)/ ) {
		$token = $1;
	}

	# remove garbage first character from the token in case it's
	# not a variable (Example: ->foo becomes >foo but should be foo)
	$token =~ s/^[^\w\$\@\%\*\&:]//;

	return ( [ $line + 1, $col + 1, $symbol_start_pos + 1 ], $token );
}

sub find_variable_declaration {
	my $self = shift;

	my ( $location, $token ) = $self->get_current_symbol;
	unless ( defined $location ) {
		Wx::MessageBox(
			Wx::gettext("Current cursor does not seem to point at a variable"),
			Wx::gettext("Check cancelled"),
			Wx::wxOK,
			$self->current->main,
		);
		return;
	}

	# Create a new object of the task class and schedule it
	$self->task_request(
		task      => 'Padre::Task::FindVariableDeclaration',
		document  => $self,
		location  => $location,
		on_finish => 'find_variable_declaration_response',
	);

	return;
}

sub find_variable_declaration_response {
	my $self = shift;
	my $task = shift;

	# Found what we were looking for
	if ( $task->{location} ) {
		$self->ppi_select( $task->{location} );
		return;
	}

	# Couldn't find the variable declaration.
	# TO DO: Convert this to a call to ->main that doesn't require
	# us to use Wx directly.
	my $text;
	if ( $self->{error} =~ /no token/ ) {
		$text = Wx::gettext("Current cursor does not seem to point at a variable");
	} elsif ( $self->{error} =~ /no declaration/ ) {
		$text = Wx::gettext("No declaration could be found for the specified (lexical?) variable");
	} else {
		$text = Wx::gettext("Unknown error");
	}
	Wx::MessageBox(
		$text,
		Wx::gettext("Search Canceled"),
		Wx::wxOK,
		$self->current->main,
	);
}

sub find_method_declaration {
	my ($self) = @_;

	my ( $location, $token ) = $self->get_current_symbol;
	unless ( defined $location ) {
		Wx::MessageBox(
			Wx::gettext("Current cursor does not seem to point at a method"),
			Wx::gettext("Check cancelled"),
			Wx::wxOK,
			Padre->ide->wx->main
		);
		return ();
	}
	if ( $token =~ /^\w+$/ ) {

		# check if there is -> before or (  after or shall we look it up in the list of existing methods?
		# search for sub someting in
		#    current file
		#    all the files in the project directory (if in project)
		# cache the list of methods found
	}

	#	Wx::MessageBox(
	#		Wx::gettext("Current '$token' $location"),
	#		Wx::gettext("Check cancelled"),
	#		Wx::wxOK,
	#		Padre->ide->wx->main
	#	);

	# Try to extract class methods' class name
	my $editor       = $self->editor;
	my $line         = $location->[0] - 1;
	my $col          = $location->[1] - 1;
	my $line_start   = $editor->PositionFromLine($line);
	my $token_end    = $line_start + $col + 1 + length($token);
	my $line_content = $editor->GetTextRange( $line_start, $token_end );
	my ($class) = $line_content =~ /(?:^|[^\w:\$])(\w+(?:::\w+)*)\s*->\s*\Q$token\E$/;

	my ( $found, $filename ) = $self->_find_method( $token, $class );
	if ( not $found ) {
		Wx::MessageBox(
			sprintf( Wx::gettext("Current '%s' not found"), $token ),
			Wx::gettext("Check cancelled"),
			Wx::wxOK,
			Padre->ide->wx->main
		);
		return;
	}

	require Padre::Wx::Dialog::Positions;
	Padre::Wx::Dialog::Positions->set_position();

	if ( not $filename ) {

		#print "No filename\n";
		# goto $line in current file

		$self->goto_sub($token);
	} else {
		my $main = Padre->ide->wx->main;

		# open or switch to file
		my $id = $main->find_editor_of_file($filename);
		if ( not defined $id ) {
			$id = $main->setup_editor($filename);
		}

		#print "Filename '$filename' id '$id'\n";
		# goto $line in that file
		return if not defined $id;

		#print "ID $id\n";
		my $editor = $main->notebook->GetPage($id);
		$editor->{Document}->goto_sub($token);
	}


	return ();
}

# Arguments: A method name, optionally a class name
# Returns: Success-Bit, Filename
sub _find_method {
	my ( $self, $name, $class ) = @_;

	# Use tags parser if it's configured, return a match
	my $parser = $self->perltags_parser;
	if ( defined($parser) ) {
		my $tag = $parser->findTag($name);

		# Try to match tag AND class first
		if ( defined $class ) {
			while (1) {
				last if not defined $tag;
				next
					if not defined $tag->{extension}{class}
						or not $tag->{extension}{class} eq $class;
				last;
			} continue {
				$tag = $parser->findNextTag();
			}

			# fall back to the first method name match (bad idea?)
			$tag = $parser->findTag($name)
				if not defined $tag;
		}

		return ( 1, $tag->{file} ) if defined $tag;
	}

	# Fallback: Search for methods in source
	# TO DO: unify with code in Padre::Wx::FunctionList
	# TO DO: lots of improvement needed here
	if ( not $self->{_methods_}{$name} ) {
		my $filename = $self->filename;
		$self->{_methods_}{$_} = $filename for $self->get_functions;
		my $project_dir = Padre::Util::get_project_dir($filename);
		if ($project_dir) {
			my @files = File::Find::Rule->file->name('*.pm')->in( File::Spec->catfile( $project_dir, 'lib' ) );
			foreach my $f (@files) {
				if ( open my $fh, '<', $f ) {
					my $lines = do { local $/ = undef; <$fh> };
					close $fh;
					my @subs = $lines =~ /sub\s+(\w+)/g;
					if ( $lines =~ /use MooseX::Declare;/ ) {
						push @subs, ( $lines =~ /\bmethod\s+(\w+)/g );
					}

					if ( $lines =~ /use (?:MooseX::)?Method::Signatures;/ ) {
						my @subs = $lines =~ /\b(?:method|func)\s+(\w+)/g;
					}


					#use Data::Dumper;
					#print Dumper \@subs;
					$self->{_methods_}{$_} = $f for @subs;
				}
			}

		}
	}

	#use Data::Dumper;
	#print Dumper $self->{_methods_};

	if ( $self->{_methods_}{$name} ) {
		return ( 1, $self->{_methods_}{$name} );
	}
	return;
}

#scan text for sub declaration
sub _find_sub_decl_line_number {
	my ( $name, $text ) = @_;

	my @lines = split /\n/, $text;

	#print "Name '$name'\n";
	foreach my $i ( 0 .. @lines - 1 ) {

		#print "L: $lines[$i]\n";
		if ($lines[$i] =~ /sub \s+ $name\b
		 (?!;)
		 (?! \([\$;\@\%\\]+ \);)
		 /x
			)
		{
			return $i;
		}
	}
	return -1;
}

# Go to the named subroutine
# Uses the outline if there is one (if the user has opened the outline tree)
# If not, falls back to a regex, which is pretty basic at the moment
# Perhaps we could always run the outline task, even if the tree is not open?
sub goto_sub {
	my ( $self, $name ) = @_;

	if ( my $line = $self->get_sub_line_number($name) ) {
		$self->editor->goto_line_centerize($line);
		return;
	}

	# Fall back to regexs if there's no outline
	my $line = _find_sub_decl_line_number( $name, $self->text_get );
	if ( $line > -1 ) {
		$self->editor->goto_line_centerize($line);
		return 1;
	}
	return;
}

# Check the outline data to see if we have a particular sub
sub has_sub {
	my $self = shift;
	my $sub  = shift;

	return $self->get_sub_line_number($sub) ? 1 : 0;
}

# Returns the line number of a sub (or undef if it doesn't exist) based on the outline data
sub get_sub_line_number {
	my $self = shift;
	my $sub  = shift;

	return unless $sub;

	return unless $self->outline_data;

	foreach my $package ( @{ $self->outline_data } ) {
		foreach my $method ( @{ $package->{methods} } ) {
			return $method->{line} if $method->{name} eq $sub;
		}
	}

	return;

}

#####################################################################
# Padre::Document Document Manipulation

sub rename_variable {
	my $self = shift;

	# Can we find something to replace?
	my ( $location, $token ) = $self->get_current_symbol;
	if ( not defined $location ) {
		Wx::MessageBox(
			Wx::gettext('Current cursor does not seem to point at a variable.'),
			Wx::gettext('Rename variable'),
			Wx::wxOK,
			$self->current->main,
		);
		return;
	}

	my $dialog = Wx::TextEntryDialog->new(
		$self->current->main,
		Wx::gettext('New name'),
		Wx::gettext('Rename variable'),
		$token,
	);
	return if $dialog->ShowModal == Wx::wxID_CANCEL;
	my $replacement = $dialog->GetValue;
	$dialog->Destroy;

	# Launch the background task
	$self->task_request(
		task        => 'Padre::Task::LexicalReplaceVariable',
		document    => $self,
		location    => $location,
		replacement => $replacement,
		on_finish   => 'rename_variable_response',
	);

	return;
}

sub change_variable_style {
	my $self = shift;
	my %opt  = @_;
	if ( 0 == grep { defined $_ } @opt{qw(to_camel_case from_camel_case)} ) {
		warn "Need either 'to_camel_case' or 'from_camel_case' options";
		return;
	} elsif (
		2 == grep {
			defined $_
		} @opt{qw(to_camel_case from_camel_case)}
		)
	{
		warn "Need either 'to_camel_case' or 'from_camel_case' options, not both";
		return;
	}

	# Can we find something to replace?
	my ( $location, $token ) = $self->get_current_symbol;
	if ( not defined $location ) {
		Wx::MessageBox(
			Wx::gettext('Current cursor does not seem to point at a variable.'),
			Wx::gettext('Variable case change'),
			Wx::wxOK,
			$self->current->main,
		);
		return;
	}

	# Launch the background task
	$self->task_request(
		%opt, # should contain only keys to_camel_case or from_camel_case and optionally ucfirst
		task      => 'Padre::Task::LexicalReplaceVariable',
		document  => $self,
		location  => $location,
		on_finish => 'rename_variable_response',
	);

	return;
}


sub rename_variable_response {
	my $self = shift;
	my $task = shift;

	if ( defined $task->{munged} ) {

		# GUI update
		# TO DO: What if the document changed? Bad luck for now.
		$self->editor->SetText( $task->{munged} );
		$self->ppi_select( $task->{location} );
		return;
	}

	# Explain why it didn't work
	my $text;
	my $error = $self->{error} || '';
	if ( $error =~ /no token/ ) {
		$text = Wx::gettext("Current cursor does not seem to point at a variable.");
	} elsif ( $error =~ /no declaration/ ) {
		$text = Wx::gettext("No declaration could be found for the specified (lexical?) variable.");
	} else {
		$text = Wx::gettext("Unknown error") . "\n$error";
	}
	Wx::MessageBox(
		$text,
		Wx::gettext("Replace Operation Canceled"),
		Wx::wxOK,
		$self->current->main,
	);
}

sub introduce_temporary_variable {
	my $self   = shift;
	my $name   = shift;
	my $editor = $self->editor;

	# Run the replacement in the background
	$self->task_request(
		task           => 'Padre::Task::IntroduceTemporaryVariable',
		document       => $self,
		varname        => $name,
		start_location => $editor->GetSelectionStart,
		end_location   => $editor->GetSelectionEnd - 1,
		on_finish      => 'introduce_temporary_variable_response',
	);

	return;
}

sub introduce_temporary_variable_response {
	my $self = shift;
	my $task = shift;

	if ( defined $task->{munged} ) {

		# GUI update
		# TO DO: What if the document changed? Bad luck for now.
		$self->editor->SetText( $task->{munged} );
		$self->ppi_select( $task->{location} );
		return;
	}

	# Explain why it didn't work
	my $text;
	my $error = $self->{error} || '';
	if ( $error =~ /no token/ ) {
		$text = Wx::gettext("First character of selection does not seem to point at a token.");
	} elsif ( $error =~ /no statement/ ) {
		$text = Wx::gettext("Selection not part of a Perl statement?");
	} else {
		$text = Wx::gettext("Unknown error");
	}
	Wx::MessageBox(
		$text,
		Wx::gettext("Replace Operation Canceled"),
		Wx::wxOK,
		$self->current->main,
	);
}

# this method takes the new subroutine name
# and extracts the name and sets a call to it
# Uses Devel::Refactor to get the code and create the new subroutine code.
# Uses PPIx::EditorTools when no functions are in the script
# Otherwise locates the entry point after a user has
# provided a function name to insert the new code before.
sub extract_subroutine {
	my ( $self, $newname ) = @_;

	my $editor = $self->editor;

	# get the selected code
	my $code = $editor->GetSelectedText();

	#print "startlocation: " . join(", ", @$start_position) . "\n";
	# this could be configurable
	my $now         = localtime;
	my $sub_comment = <<EOC;
#
# New subroutine "$newname" extracted - $now.
#
EOC

	# get the new code
	require Devel::Refactor;
	my $refactory = Devel::Refactor->new;
	my ( $new_sub_call, $new_code ) = $refactory->extract_subroutine( $newname, $code, 1 );
	my $data = Wx::TextDataObject->new;
	$data->SetText( $sub_comment . $new_code . "\n\n" );

	# we want to get a list of the subroutines to pick where to place
	# the new sub
	my @functions = $self->get_functions;

	# need to check there are functions already defined
	if ( scalar(@functions) == 0 ) {

		# get the current position of the selected text as we need it for PPI
		my $start_position = $self->character_position_to_ppi_location( $editor->GetSelectionStart );
		my $end_position   = $self->character_position_to_ppi_location( $editor->GetSelectionEnd - 1 );

		# use PPI to find the right place to put the new subroutine
		require PPI::Document;
		my $text    = $editor->GetText;
		my $ppi_doc = PPI::Document->new( \$text );

		# /usr/local/share/perl/5.10.0/PPIx/EditorTools/IntroduceTemporaryVariable.pm
		# we have no subroutines to put before, so we
		# really just need to make sure we aren't in a block of any sort
		# and then stick the new subroutine in above where we are.
		# being above the selected text also means we won't
		# lose the location when the change is made to the document
		#require PPI::Dumper;
		#my $dumper = PPI::Dumper->new( $ppi_doc );
		#$dumper->print;
		require PPIx::EditorTools;
		my $token = PPIx::EditorTools::find_token_at_location( $ppi_doc, $start_position );
		return unless $token;
		my $statement = $token->statement();
		my $parent    = $statement;

		#print "The statement is: " . $statement->statement() . "\n";
		my $last_location; # use this to get the last point before the PPI::Document
		while ( !$parent->isa('PPI::Document') ) {

			#print "parent currently: " . ref($parent) . "\n";
			#print "location: " . join(', ', @{$parent->location} ) . "\n";

			$last_location = $parent->location;
			$parent        = $parent->parent;
		}

		#print "location: " . join(', ', @{$parent->location} ) . "\n";
		#print "last location: " . join(', ' ,@$last_location) . "\n";

		my $insert_start_location = $self->ppi_location_to_character_position($last_location);

		#print "Document start location is: $doc_start_location\n";

		# make the change to the selected text
		$editor->BeginUndoAction(); # do the edit atomically
		$editor->ReplaceSelection($new_sub_call);
		$editor->InsertText( $insert_start_location, $data->GetText );
		$editor->EndUndoAction();

		return;
	}

	# Show a list of functions
	require Padre::Wx::Dialog::RefactorSelectFunction;
	my $dialog = Padre::Wx::Dialog::RefactorSelectFunction->new( $editor->main, \@functions );
	$dialog->show();
	if ( $dialog->{cancelled} ) {

		#$dialog->Destroy();
		return ();
	}

	my $subname = $dialog->get_function_name;

	#$dialog->Destroy();

	# make the change to the selected text
	$editor->BeginUndoAction(); # do the edit atomically
	$editor->ReplaceSelection($new_sub_call);

	# with the change made
	# locate the function:
	my ( $start, $end ) = Padre::Util::get_matches(
		$editor->GetText,
		$self->get_function_regex($subname),
		$editor->GetSelection,  # Provides two params
	);
	unless ( defined $start ) {

		# This needs to now rollback the
		# the changes made with the editor
		$editor->Undo();
		$editor->EndUndoAction();

		# Couldn't find it
		# should be dialog
		#print "Couldn't find the sub: $subname\n";
		return;
	}

	# now insert the text into the right location
	$editor->InsertText( $start, $data->GetText );
	$editor->EndUndoAction();

	return ();

}

# This sub handles a cached C-Tags - Parser object which is much faster
# than recreating it on every autocomplete
sub perltags_parser {
	my $self = shift;

	# Don't scan on every char if there is no file
	return if $self->{_perltags_file_none};
	my $perltags_file = $self->{_perltags_file};

	require Parse::ExuberantCTags;
	my $config = Padre->ide->config;

	# Use the configured file (if any) or the old default, reset on config change
	if (   not defined $perltags_file
		or not defined $self->{_perltags_config}
		or $self->{_perltags_config} ne $config->perl_tags_file )
	{

		foreach my $candidate (
			$self->project_tagsfile, $config->perl_tags_file,
			File::Spec->catfile( $ENV{PADRE_HOME}, 'perltags' )
			)
		{

			# project_tagsfile and config value may be undef
			next if !defined($candidate);

			# config value may be defined but empty
			next if $candidate eq '';

			# Check if the tagsfile exists using Padre::File
			# to allow "ftp://my.server/~myself/perltags" in config
			# and remote projects
			my $tagsfile = Padre::File->new($candidate);
			next if !defined($tagsfile);

			next if !$tagsfile->exists;

			# For non-local perltags-files, copy the file to a local tempfile,
			# otherwise the parser won't work or will be very slow.
			if ( $tagsfile->{protocol} ne 'local' ) {

				# Create temporary local file
				$self->{_perltags_temp} = File::Temp->new( UNLINK => 1 );

				# Flush tagsfile content to temporary file
				my $FH = $self->{_perltags_temp};
				$FH->autoflush(1);
				print $FH $tagsfile->read;

				# File should not be closed - it may get deleted on close!

				# Use the local temporary file as tagsfile
				$self->{_perltags_file} = $self->{_perltags_temp}->filename;
			} else {
				$self->{_perltags_file} = $candidate;
			}

			# Use first existing file
			last;
		}

		# Remember current value for later checks
		$self->{_perltags_config} = $config->perl_tags_file;

		$perltags_file = $self->{_perltags_file};

		# Remember that we don't have a file if we don't have one
		if ( defined($perltags_file) ) {
			$self->{_perltags_file_none} = 0;
		} else {
			$self->{_perltags_file_none} = 1;
		}

		# Reset timer for new file
		delete $self->{_perltags_parser_time};

	}

	# If we don't have a file (none specified in config, for example), return undef
	# as the object and noone will try to use it
	return if not defined $perltags_file;

	my $parser;

	# Use the cached parser if
	#  - there is one
	#  - the last check is younger than 5 seconds (don't check the file again)
	#    or the file's mtime matches our cached mtime
	if (    defined $self->{_perltags_parser}
		and defined $self->{_perltags_parser_time}
		and (  $self->{_perltags_parser_last} > time - 5
			or $self->{_perltags_parser_time} == ( stat $perltags_file )[9] )
		)
	{
		$parser = $self->{_perltags_parser};
		$self->{_perltags_parser_last} = time;
	} else {
		$parser                        = Parse::ExuberantCTags->new($perltags_file);
		$self->{_perltags_parser}      = $parser;
		$self->{_perltags_parser_time} = ( stat $perltags_file )[9];
		$self->{_perltags_parser_last} = time;
	}

	return $parser;
}

=pod

=head2 C<autocomplete>

This method is called on two events:

=over

=item Manually using the C<autocomplete-action> (via menu, toolbar, hot key)

=item on every char typed by the user if the C<autocomplete-always> configuration option is active

=back

Arguments: The event object (optional)

Returns the prefix length and an array of suggestions. C<prefix_length> is the
number of characters left to the cursor position which need to be replaced if
a suggestion is accepted.

WARNING: This method runs very often (on each keypress), keep it as efficient
         and fast as possible!

=cut

sub autocomplete {
	my $self  = shift;
	my $event = shift;

	my $config    = Padre->ide->config;
	my $min_chars = $config->perl_autocomplete_min_chars;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# This function is called very often, return asap
	return if ( $pos - $first ) < ( $min_chars - 1 );

	# line from beginning to current position
	my $prefix = $editor->GetTextRange( $first, $pos );

	# Remove any ident from the beginning of the prefix
	$prefix =~ s/^[\r\t]+//;
	return if length($prefix) == 0;

	# One char may be added by the current event
	return if length($prefix) < ( $min_chars - 1 );

	my $suffix = $editor->GetTextRange( $pos, $pos + 15 );
	$suffix = $1 if $suffix =~ /^(\w*)/; # Cut away any non-word chars

	# The second parameter may be a reference to the current event or the next
	# char which will be added to the editor:
	my $nextchar = '';                   # Use empty instead of undef
	if ( defined($event) and ( ref($event) eq 'Wx::KeyEvent' ) ) {
		my $key = $event->GetUnicodeKey;
		$nextchar = chr($key);
	} elsif ( defined($event) and ( !ref($event) ) ) {
		$nextchar = $event;
	}
	return if ord($nextchar) == 27;      # Close on escape
	$nextchar = '' if ord($nextchar) < 32;

	# WARNING: This is totally not done, but Gabor made me commit it.
	# TO DO:
	# a) complete this list
	# b) make the path configurable
	# c) make the whole thing optional and/or pluggable
	# d) make it not suck
	# e) make the types of auto-completion configurable
	# f) remove the old auto-comp code or at least let the user choose to use the new
	#    *or* the old code via configuration
	# g) hack STC so that we can get more information in the autocomp. window,
	# h) hack STC so we can start populating the autocompletion choices and continue to do so in the background
	# i) hack Perl::Tags to be better (including inheritance)
	# j) add inheritance support
	# k) figure out how to do method auto-comp. on objects
	# (Ticket #676)

	# check for variables

	if ( $prefix =~ /([\$\@\%\*])(\w+(?:::\w+)*)$/ ) {
		my $prefix = $2;
		my $type   = $1;
		my $parser = $self->perltags_parser;
		if ( defined $parser ) {
			my $tag = $parser->findTag( $prefix, partial => 1 );
			my @words;
			my %seen;
			while ( defined($tag) ) {

				# TO DO check file scope?
				if ( !defined( $tag->{kind} ) ) {

					# This happens with some tagfiles which have no kind
				} elsif ( $tag->{kind} eq 'v' ) {

					# TO DO potentially don't skip depending on circumstances.
					if ( not $seen{ $tag->{name} }++ ) {
						push @words, $tag->{name};
					}
				}
				$tag = $parser->findNextTag();
			}
			return ( length($prefix), @words );
		}
	}

	# check for hashs
	elsif ( $prefix =~ /(\$\w+(?:\-\>)?)\{([\'\"]?)([\$\&]?\w*)$/ ) {
		my $hashname   = $1;
		my $textmarker = $2;
		my $keyprefix  = $3;

		my $last = $editor->GetLength();
		my $text = $editor->GetTextRange( 0, $last );

		my %words;
		while ( $text =~ /\Q$hashname\E\{(([\'\"]?)\Q$keyprefix\E.+?\2)\}/g ) {
			$words{$1} = 1;
		}

		return (
			length( $textmarker . $keyprefix ),
			sort {
				my $a1 = $a;
				my $b1 = $b;
				$a1 =~ s/^([\'\"])(.+)\1/$2/;
				$b1 =~ s/^([\'\"])(.+)\1/$2/;
				$a1 cmp $b1;
				} ( keys(%words) )
		);

	}

	# check for methods
	elsif ( $prefix =~ /(?![\$\@\%\*])(\w+(?:::\w+)*)\s*->\s*(\w*)$/ ) {
		my $class  = $1;
		my $prefix = $2;
		$prefix = '' if not defined $prefix;
		my $parser = $self->perltags_parser;
		if ( defined $parser ) {
			my $tag = ( $prefix eq '' ) ? $parser->firstTag() : $parser->findTag( $prefix, partial => 1 );
			my @words;

			# TO DO: INHERITANCE!
			while ( defined($tag) ) {
				if ( !defined( $tag->{kind} ) ) {

					# This happens with some tagfiles which have no kind
				} elsif ( $tag->{kind} eq 's'
					and defined $tag->{extension}{class}
					and $tag->{extension}{class} eq $class )
				{
					push @words, $tag->{name};
				}
				$tag = ( $prefix eq '' ) ? $parser->nextTag() : $parser->findNextTag();
			}
			return ( length($prefix), @words );
		}
	}

	# check for packages
	elsif ( $prefix =~ /(?![\$\@\%\*])(\w+(?:::\w+)*)/ ) {
		my $prefix = $1;
		my $parser = $self->perltags_parser;

		if ( defined $parser ) {
			my $tag = $parser->findTag( $prefix, partial => 1 );
			my @words;
			my %seen;
			while ( defined($tag) ) {

				# TO DO check file scope?
				if ( !defined( $tag->{kind} ) ) {

					# This happens with some tagfiles which have no kind
				} elsif ( $tag->{kind} eq 'p' ) {

					# TO DO potentially don't skip depending on circumstances.
					if ( not $seen{ $tag->{name} }++ ) {
						push @words, $tag->{name};
					}
				}
				$tag = $parser->findNextTag();
			}
			return ( length($prefix), @words );
		}
	}

	$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};

	if ( defined($nextchar) ) {
		return if ( length($prefix) + 1 ) < $min_chars;
	} else {
		return if length($prefix) < $min_chars;
	}

	my $last      = $editor->GetLength();
	my $text      = $editor->GetTextRange( 0, $last );
	my $pre_text  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post_text = $editor->GetTextRange( $first, $last );

	my $regex;
	eval { $regex = qr{\b(\Q$prefix\E\w+(?:::\w+)*)\b} };
	if ($@) {
		return ("Cannot build regular expression for '$prefix'.");
	}

	my %seen;
	my @words;
	push @words, grep { !$seen{$_}++ } reverse( $pre_text =~ /$regex/g );
	push @words, grep { !$seen{$_}++ } ( $post_text =~ /$regex/g );

	my $max_length = $config->perl_autocomplete_max_suggestions;
	if ( @words > $max_length ) {
		@words = @words[ 0 .. ( $max_length - 1 ) ];
	}

	# Suggesting the current word as the only solution doesn't help
	# anything, but your need to close the suggestions window before
	# you may press ENTER/RETURN.
	if ( ( $#words == 0 ) and ( $prefix eq $words[0] ) ) {
		return;
	}

	# While typing within a word, the rest of the word shouldn't be
	# inserted.
	if ( defined($suffix) ) {
		for ( 0 .. $#words ) {
			$words[$_] =~ s/\Q$suffix\E$//;
		}
	}

	# This is the final result if there is no char which hasn't been
	# saved to the editor buffer until now
	#	return ( length($prefix), @words ) if !defined($nextchar);

	my $min_length = $config->perl_autocomplete_min_suggestion_len;

	# Finally cut out all words which do not match the next char
	# which will be inserted into the editor (by the current event)
	# and remove all which are too short
	my @final_words;
	for (@words) {

		# Filter out everything which is too short
		next if length($_) < $min_length;

		# Accept everything which has prefix + next char + at least one other char
		# (check only if any char is pending)
		next if defined($nextchar) and ( !/^\Q$prefix$nextchar\E./ );

		# All checks passed, add to the final list
		push @final_words, $_;
	}

	return ( length($prefix), @final_words );
}

sub newline_keep_column {
	my $self = shift;

	my $editor = $self->editor or return;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);
	my $col    = $pos - $first;
	my $text   = $editor->GetTextRange( $first, $pos );

	$editor->AddText( $self->newline );

	$text =~ s/\S/ /g;
	$editor->AddText($text);

	$editor->SetCurrentPos( $pos + $col + 1 );

	return 1;
}

=pod

=head2 event_on_char

This event fires once for every char which should be added to the editor window.

Typing this line fired it about 41 times!

Arguments: Current editor object, current event object

Returns nothing useful.

Notice: The char being typed has not been inserted into the editor at the run
        time of this method. It could be read using C<< $event->GetUnicodeKey >>

WARNING: This method runs very often (on each keypress), keep it as efficient
         and fast as possible!

=cut

sub event_on_char {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;
	my $config = $editor->config;
	my $main   = $editor->main;

	if ( $config->autocomplete_brackets ) {
		$self->autocomplete_matching_char(
			$editor, $event,
			34  => 34,  # " "
			39  => 39,  # ' '
			40  => 41,  # ( )
			60  => 62,  # < >
			91  => 93,  # [ ]
			123 => 125, # { }
		);
	}

	my $selection_exists = 0;
	my $text             = $editor->GetSelectedText;
	if ( defined($text) && length($text) > 0 ) {
		$selection_exists = 1;
	}

	my $key   = $event->GetUnicodeKey;
	my $pos   = $editor->GetCurrentPos;
	my $line  = $editor->LineFromPosition($pos);
	my $first = $editor->PositionFromLine($line);

	# removed the - 1 at the end
	#my $last = $editor->PositionFromLine( $line + 1 );

	my $last = $editor->GetLineEndPosition($line);

	#print "pos,line,first,last: $pos,$line,$first,$last\n";
	#print "$pos == $last\n";
	# This only matches if all conditions are met:
	#  - config option enabled
	#  - none of the following keys pressed: a-z, A-Z, 0-9, _
	#  - cursor position is at end of line
	if (( $config->autocomplete_method or $config->autocomplete_subroutine )
		and (  ( $key < 48 )
			or ( ( $key > 57 ) and ( $key < 65 ) )
			or ( ( $key > 90 ) and ( $key < 95 ) )
			or ( $key == 96 )
			or ( $key > 122 ) )
		and ( $pos == $last )
		)
	{

		# from beginning to current position
		my $prefix = $editor->GetTextRange( 0, $pos );

		# methods can't live outside packages, so ignore them
		my $linetext = $editor->GetTextRange( $first, $last );

		# TODO: Fix picking up the space char so that
		# 	when indenting the cursor isn't one space 'in'.
		if ( $prefix =~ /package / ) {

			# we only match "sub foo" at the beginning of a line
			# but no inline subs (eval, anonymus, etc.)
			# The end-of-subname match is included in the first if
			# which match the last key pressed (which is not part of
			# $linetext at this moment:

			if ( $linetext =~ /^sub[\s\t]+(\w+)$/ ) {
				my $subname = $1;

				my $indent_string = $self->get_indentation_level_string(1);

				# Add the default skeleton of a method
				my $newline            = $self->newline;
				my $text_before_cursor = " {$newline${indent_string}my \$self = shift;$newline$indent_string";
				$text_before_cursor =
					  " {$newline${indent_string}my \$class = shift;$newline$newline"
					. $indent_string
					. "my \$self = bless {\@_}, \$class;$newline$newline"
					. $indent_string
					if $subname eq 'new';
				my $text_after_cursor = "$newline}$newline";
				$text_after_cursor = $newline . $indent_string . "return \$self;" . $text_after_cursor
					if $subname eq 'new';
				$editor->AddText( $text_before_cursor . $text_after_cursor );

				# Ready for typing in the new method:
				$editor->GotoPos( $last + length($text_before_cursor) );
			}
		} elsif ( $linetext =~ /^sub[\s\t]+(\w+)$/ && $config->autocomplete_subroutine ) {

			my $subName       = $1;
			my $indent_string = $self->get_indentation_level_string(1);

			# Add the default skeleton of a subroutine,
			my $newline = $self->newline;
			$editor->AddText(" {$newline$indent_string$newline}");

			# $line is where it starts
			my $starting_line = $line - 1;
			if ( $starting_line < 0 ) {
				$starting_line = 0;
			}

			#print "starting_line: $starting_line\n";
			$editor->GotoPos( $editor->PositionFromLine($starting_line) );

			# TODO Add option for auto pod
			#$editor->AddText( $self->_pod($subName) );

			# $editor->GetLineEndPosition($editor->PositionFromLine(
			# TODO For pod this was 10
			my $end_line = $starting_line + 2;
			$editor->GotoLine($end_line);

			#print "end_line: $end_line\n";
			my $line_end_pos = $editor->GetLineEndPosition($end_line);

			#print "Line_end_pos: " . $line_end_pos . "\n";
			my $last_pos = $editor->GetLineEndPosition($end_line);

			#print "Last pos: $last_pos\n";
			# Ready for typing in the new function:

			$editor->GotoPos($last_pos);

		}
	}

	# Auto complete only when the user selected 'always'
	# and no ALT key is pressed
	if ( $config->autocomplete_always && ( not $event->AltDown ) ) {
		$main->on_autocompletion($event);
	}

	return;
}

sub _pod {
	my ( $self, $method ) = @_;
	my $pod = "\n=pod\n\n=head2 $method\n\n\tTODO: Document $method\n\n=cut\n";
	return $pod;
}


# Our opportunity to implement a context-sensitive right-click menu
# This would be a lot more powerful if we used PPI, but since that would
# slow things down beyond recognition, we use heuristics for now.
sub event_on_right_down {
	my $self   = shift;
	my $editor = shift;
	my $menu   = shift;
	my $event  = shift;

	# Use the editor's current cursor position
	# PLEASE DO NOT use the mouse event position
	# You will get inconsistent results regarding refactor tools
	# when pressing Windows context "right click" key
	my $pos = $editor->GetCurrentPos();

	my $introduced_separator = 0;

	my ( $location, $token ) = $self->get_current_symbol($pos);

	# Append variable specific menu items if it's a variable
	if ( defined $location and $token =~ /^[\$\*\@\%\&]/ ) {
		$menu->AppendSeparator if not $introduced_separator++;

		$menu->add_menu_action(
			$menu,
			'perl.find_variable',
		);

		$menu->add_menu_action(
			$menu,
			'perl.rename_variable',
		);

		# Start variable style sub-menu
		my $style      = Wx::Menu->new;
		my $style_menu = $menu->Append(
			-1,
			Wx::gettext('Change variable style'),
			$style,
		);

		$menu->add_menu_action(
			$style,
			'perl.variable_to_camel_case',
		);

		$menu->add_menu_action(
			$style,
			'perl.variable_to_camel_case_ucfirst',
		);

		$menu->add_menu_action(
			$style,
			'perl.variable_from_camel_case',
		);

		$menu->add_menu_action(
			$style,
			'perl.variable_from_camel_case_ucfirst',
		);

		# End variable style sub-menu
	} # end if it's a variable


	if ( defined $location and $token =~ /^\w+$/ ) {
		$menu->add_menu_action(
			$menu,
			'perl.find_method',
		);
	}


	my $select_start = $editor->GetSelectionStart;
	my $select_end   = $editor->GetSelectionEnd;
	if ( $select_start != $select_end ) { # if something's selected
		$menu->AppendSeparator if not $introduced_separator++;

		$menu->add_menu_action(
			$menu,
			'perl.introduce_temporary',
		);

		$menu->add_menu_action(
			$menu,
			'perl.edit_with_regex_editor',
		);
	} # end if something's selected
}

sub event_on_left_up {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	if ( $event->ControlDown ) {
		my ( $location, $token ) = $self->get_current_symbol;

		# Does it look like a variable?
		if ( defined $location and $token =~ /^[\$\*\@\%\&]/ ) {
			$self->find_variable_declaration();
		}

		# Does it look like a function?
		elsif ( defined $location && $self->has_sub($token) ) {
			$self->goto_sub($token);
		}
	} # end if control-click
}

sub event_mouse_moving {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	if ( $event->Moving && $event->ControlDown ) {

		# Mouse is moving with ctrl pressed. If anything under the cursor looks like it can be
		#  clicked on to take us somewhere, highlight it.
		# TODO: currently only supports subs/methods in the same file
		my $point = $event->GetPosition();
		my $pos   = $editor->PositionFromPoint($point);
		my ( $location, $token ) = $self->get_current_symbol($pos);

		$token ||= '';

		if ( $self->{last_highlight} && $token ne $self->{last_highlight}{token} ) {

			# No longer mousing over the same token, so un-highlight it
			$self->_clear_highlight($editor);
		}

		return unless $self->has_sub($token);

		$editor->StartStyling( $location->[2], Wx::wxSTC_INDICS_MASK );
		$editor->SetStyling( length($token), Wx::wxSTC_INDIC2_MASK );

		$self->{last_highlight} = {
			token => $token,
			pos   => $location->[2],
		};
	}
}

sub event_key_up {
	my $self   = shift;
	my $editor = shift;
	my $event  = shift;

	if ( $event->GetKeyCode == Wx::WXK_CONTROL ) {

		# Ctrl key has been released, clear any highlighting
		$self->_clear_highlight($editor);
	}
}

sub _clear_highlight {
	my $self   = shift;
	my $editor = shift;

	return unless $self->{last_highlight};

	$editor->StartStyling( $self->{last_highlight}{pos}, Wx::wxSTC_INDICS_MASK );
	$editor->SetStyling( length( $self->{last_highlight}{token} ), 0 );
	undef $self->{last_highlight};
}

#
# Returns Perl's Help Provider
#
sub get_help_provider {
	require Padre::Document::Perl::Help;
	return Padre::Document::Perl::Help->new;
}

#
# Returns Perl's Quick Fix Provider
#
sub get_quick_fix_provider {
	require Padre::Document::Perl::QuickFix;
	return Padre::Document::Perl::QuickFix->new;
}

sub autoclean {
	my $self = shift;

	my $editor = $self->editor;
	my $text   = $editor->GetText;

	$text =~ s/[\s\t]+([\r\n]*?)$/$1/mg;
	$text .= "\n" if $text !~ /\n$/;

	$editor->SetText($text);

	return 1;

}

sub menu {
	my $self = shift;

	return [ 'menu.Perl', 'menu.Refactor' ];
}

=pod

=head2 C<project_tagsfile>

No arguments.

Returns the full path and file name of the Perl tags file for the current
document.

=cut

sub project_tagsfile {
	my $self = shift;

	my $project_dir = $self->project_dir;

	return if !defined($project_dir);

	return File::Spec->catfile( $project_dir, 'perltags' );
}

=pod

=head2 C<project_create_tagsfile>

Creates a tags file for the project of the current document. Includes all Perl
source files within the project excluding F<blib>.

=cut

sub project_create_tagsfile {
	my $self = shift;

	# First try is using the perl-tags command, next version should so this
	# internal using Padre::File and should skip at least the "blip" dir.

	#	print STDERR join(' ','perl-tags','-o',$self->project_tagsfile,$self->project_dir)."\n";
	system 'perl-tags', '-o', $self->project_tagsfile, $self->project_dir;

}

sub find_help_topic {
	my $self = shift;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;

	require PPI;
	my $text = $editor->GetText;
	my $doc  = PPI::Document->new( \$text );

	# Find token under the cursor!
	my $line       = $editor->LineFromPosition($pos);
	my $line_start = $editor->PositionFromLine($line);
	my $line_end   = $editor->GetLineEndPosition($line);
	my $col        = $pos - $line_start;

	require Padre::PPI;
	my $token = Padre::PPI::find_token_at_location(
		$doc, [ $line + 1, $col + 1 ],
	);

	return $token->content if defined($token);

	#TODO enable once we figure out what we actually need to accomplish here :)
	#	if ($token) {
	#
	#		#print $token->class . "\n";
	#		if ( $token->isa('PPI::Token::Symbol') ) {
	#			if ( $token->content =~ /^[\$\@\%].+?$/ ) {
	#				return 'perldata';
	#			}
	#		} elsif ( $token->isa('PPI::Token::Operator') ) {
	#			return $token->content;
	#		}
	#	}
	#
	# 	return;
}

sub guess_filename_to_open {
	my $self = shift;
	my $text = shift;

	# Convert a module name to a file name
	my $module = $text;
	$module =~ s{::}{/}g;
	$module .= ".pm";

	# Check within our original startup directory
	SCOPE: {
		my $file = File::Spec->catfile(
			Padre->ide->{original_cwd},
			$module,
		);
		return $file if -e $file;
	}

	# If the file exists somewhere within our project, shortcut to it
	foreach my $dirs ( ['lib'], [] ) {
		my $file = File::Spec->catfile(
			$self->project_dir,
			@$dirs, $module,
		);
		return $file if -e $file;
	}

	# Search for a list of possible module locations in the @INC path
	# TO DO: It should not be our @INC but the @INC of the perl used
	# for script execution
	my @files = grep { -e $_ } map { File::Spec->catfile( $_, $module ) } (
		File::Spec->catdir( $self->project_dir, 'inc' ),
		@INC,
	);
	return @files if @files;

	# Is this an executable in the current PATH
	require File::Which;
	my $filename = File::Which::which($text);
	return $filename if defined $filename;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
