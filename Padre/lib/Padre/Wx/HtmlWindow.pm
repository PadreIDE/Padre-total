package Padre::Wx::HtmlWindow;

=pod

=head1 NAME

Padre::Wx::HtmlWindow - Padre-enhanced version of L<Wx::HtmlWindow>

=head1 DESCRIPTION

C<Padre::Wx::HtmlWindow> provides a Padre-specific subclass of
L<Wx::HtmlWindow> that adds some additional features, primarily
default support for L<pod2html> functionality.

=head1 METHODS

C<Padre::Wx::HtmlWindow> implements all the methods described in
the documentation for L<Wx::HtmlWindow>, and adds some additional
methods.

=cut

use 5.008;
use strict;
use warnings;
use Padre::Role::Task   ();
use Padre::Wx ();
use Padre::Wx 'Html';

our $VERSION    = '0.93';
our $COMPATIBLE = '0.93';
our @ISA        = qw{
	Padre::Role::Task
	Wx::HtmlWindow
};

use constant LOADING => <<'END_HTML';
<html>
<body>
Loading...
</body>
</html>
END_HTML

use constant ERROR => <<'END_HTML';
<html>
<body>
Failed to render page
</body>
</html>
END_HTML





#####################################################################
# Foreground Loader Methods

=pod

=head2 load_file

  $html_window->load_file('my.pod');

The C<load_file> method takes a file name, loads the file, transforms
it to HTML via the default Padre::Pod2HTML processor, and then loads
the HTML into the window.

Returns true on success, or throws an exception on error.

=cut

sub load_file {
	my $self = shift;
	my $file = shift;

	# Spawn the rendering task
	$self->task_reset;
	$self->task_request(
		task      => 'Padre::Task::Pod2HTML',
		on_finish => '_finish',
		file      => $file,
	);

	# Place a temporary message in the HTML window
	$self->SetPage( LOADING );
}

=pod

=head2 load_file

  $html_window->load_pod( "=head1 NAME\n" );

The C<load_file> method takes a string of POD content, transforms
it to HTML via the default Padre::Pod2HTML processor, and then loads
the HTML into the window.

Returns true on success, or throws an exception on error.

=cut

sub load_pod {
	my $self = shift;
	my $text = shift;

	# Spawn the rendering task
	$self->task_reset;
	$self->task_request(
		task      => 'Padre::Task::Pod2HTML',
		on_finish => '_finish',
		text      => $text,
	);

	# Place a temporary message in the HTML window
	$self->SetPage( LOADING );
}

sub _finish {
	my $self = shift;
	my $task = shift;

	if ( $task->errstr ) {
		$self->SetPage( $task->errstr );
	} elsif ( $task->html ) {
		$self->SetPage( $task->html );
	} else {
		$self->SetPage( ERROR );
	}

	return 1;
}

1;

__END__

=pod

=head1 SUPPORT

See the main L<Padre> documentation.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008-2012 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
