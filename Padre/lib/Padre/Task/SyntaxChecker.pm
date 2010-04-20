package Padre::Task::SyntaxChecker;

use 5.008;
use strict;
use warnings;
use Carp           ();
use Params::Util   (qw{_CODE _INSTANCE});
use Padre::Task    ();
use Padre::Current ();
use Padre::Wx      ();

our $VERSION = '0.60';
our @ISA     = 'Padre::Task';

=pod

=head1 NAME

Padre::Task::SyntaxChecker - Generic syntax-checking background processing task

=head1 SYNOPSIS

  package Padre::Task::SyntaxChecker::MyLanguage;
  use base 'Padre::Task::SyntaxChecker';
  
  sub run {
          my $self = shift;
          my $doc_text = $self->{text};
          # black magic here
          $self->{syntax_check} = ...;
          return 1;
  };
  
  1;
  
  # elsewhere:
  
  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task::SyntaxChecker::MyLanguage->new();
  $task->schedule;
  
  my $task2 = Padre::Task::SyntaxChecker::MyLanguage->new(
    text   => Padre::Current->document->text_get,
    editor => Padre::Current->editor,
  );
  $task2->schedule;

=head1 DESCRIPTION

This is a base class for all tasks that need to do
expensive syntax checking in a background task.

You can either let C<Padre::Task::SyntaxChecker> fetch the
Perl code for parsing from the current document
or specify it as the "C<text>" parameter to
the constructor.

To create a syntax checker for a given document type C<Foo>,
you create a subclass C<Padre::Task::SyntaxChecker::Foo> and
implement the C<run> method which uses the C<$self-E<gt>{text}>
attribute of the task object for its nefarious syntax checking
purposes and then stores the result in the C<$self-E<gt>{syntax_check}>
attribute of the object. The result should be a data structure of the
form defined in the documentation of the C<Padre::Document::check_syntax>
method. See L<Padre::Document>.

This base class implements all logic necessary to update the GUI
with the syntax check results in a C<finish()> hook. If you want
to implement your own C<finish()>, make sure to call C<$self-E<gt>SUPER::finish>
for this reason.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	unless ( defined $self->{text} ) {
		$self->{text} = Padre::Current->document->text_get;
	}

	# Put notebook page and callback into main-thread-only storage
	$self->{main_thread_only} ||= {};
	my $editor    = $self->{editor}    || $self->{main_thread_only}->{editor};
	my $on_finish = $self->{on_finish} || $self->{main_thread_only}->{on_finish};
	delete $self->{editor};
	delete $self->{on_finish};
	unless ( defined $editor ) {
		$editor = Padre::Current->editor;
	}
	return () if not defined $editor;
	$editor = Scalar::Util::refaddr($editor);
	$self->{main_thread_only}->{on_finish} = $on_finish if $on_finish;
	$self->{main_thread_only}->{editor} = $editor;
	return bless $self => $class;
}

sub run {
	my $self = shift;
	return 1;
}

sub prepare {
	my $self = shift;
	unless ( defined $self->{text} ) {
		Carp::croak("Could not find the document's text for syntax checking.");
	}
	unless ( defined $self->{main_thread_only}->{editor} ) {
		Carp::croak("Could not find the reference to the notebook page for GUI updating.");
	}
	return 1;
}

sub finish {
	my $self     = shift;
	my $callback = $self->{main_thread_only}->{on_finish};
	if ( _CODE($callback) ) {
		$callback->($self);
	} else {
		$self->update_gui;
	}
}

sub update_gui {
	my $self     = shift;
	my $messages = $self->{syntax_check};
	my $current  = Padre::Current->new;
	my $main     = $current->main;
	my $editor   = $current->editor;
	my $syntax   = $main->syntax;
	my $addr     = delete $self->{main_thread_only}->{editor};

	if ( not $addr or not $editor or $addr ne Scalar::Util::refaddr($editor) ) {

		# Editor reference is not valid any more
		return 1;
	}

	# Clear out the existing stuff
	$syntax->clear;

	# If there are no errors, clear the synax checker pane and return.
	if ( ( !defined($messages) ) or ( $#{$messages} == -1 ) ) {
		my $idx = $syntax->InsertStringImageItem( 0, '', 2 );
		$syntax->SetItemData( $idx, 0 );
		$syntax->SetItem( $idx, 1, Wx::gettext('Info') );

		# Relative-to-the-project filename
		my $document = $current->document;
		if ( defined( $document->file ) ) { # check that the document has been saved
			my $filename = $document->file->{filename};
			if ( defined( $document->project_dir ) ) {
				my $project_dir = quotemeta $document->project_dir;
				$filename =~ s/^$project_dir//;
			}
			$syntax->SetItem( $idx, 2, sprintf( Wx::gettext('No errors or warnings found in %s.'), $filename ) );
		} else {
			$syntax->SetItem( $idx, 2, Wx::gettext('No errors or warnings found.') );
		}
		return;
	}

	# Update the syntax checker pane
	if ( scalar( @{$messages} ) > 0 ) {
		my $i = 0;
		delete $editor->{synchk_calltips};
		my $last_hint = '';

		# eliminate some warnings
		foreach my $m ( @{$messages} ) {
			$m->{line} = 0  unless defined $m->{line};
			$m->{msg}  = '' unless defined $m->{msg};
		}
		foreach my $hint ( sort { $a->{line} <=> $b->{line} } @{$messages} ) {
			my $l = $hint->{line} - 1;
			if ( $hint->{severity} eq 'W' ) {
				$editor->MarkerAdd( $l, Padre::Wx::MarkWarn() );
			} else {
				$editor->MarkerAdd( $l, Padre::Wx::MarkError() );
			}
			my $idx = $syntax->InsertStringImageItem( $i++, $l + 1, ( $hint->{severity} eq 'W' ? 1 : 0 ) );
			$syntax->SetItemData( $idx, 0 );
			$syntax->SetItem( $idx, 1, ( $hint->{severity} eq 'W' ? Wx::gettext('Warning') : Wx::gettext('Error') ) );
			$syntax->SetItem( $idx, 2, $hint->{msg} );

			if ( exists $editor->{synchk_calltips}->{$l} ) {
				$editor->{synchk_calltips}->{$l} .= "\n--\n" . $hint->{msg};
			} else {
				$editor->{synchk_calltips}->{$l} = $hint->{msg};
			}
			$last_hint = $hint;
		}

		$syntax->set_column_widths($last_hint);
	}

	return 1;
}

1;

__END__

=pod

=head1 SEE ALSO

This class inherits from C<Padre::Task> and its instances can be scheduled
using C<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
