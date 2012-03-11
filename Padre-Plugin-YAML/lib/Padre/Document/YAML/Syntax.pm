package Padre::Document::YAML::Syntax;

# ABSTRACT: YAML document support for Padre
use 5.010001;
use strict;
use warnings;

use Padre::Task::Syntax ();
use Padre::Wx           ();

our $VERSION = '0.02';
use parent qw(Padre::Task::Syntax);


#######
# new
#######
sub new {
	my $class = shift;   # What class are we constructing?
	my $self  = {};      # Allocate new memory
	bless $self, $class; # Mark it of the right type
	$self->_init(@_);    # Call _init with remaining args
	return $self;
}

#######
# Method _init
#######
sub _init {
	my ( $self, @args ) = @_;

	return;
}


# our @ISA = 'Padre::Document';

# sub task_functions {
	# return '';
# }

# sub task_outline {
	# return '';
# }

# sub task_syntax {
	# return '';
# }

# sub comment_lines_str {
	# return '#';
# }

1;

__END__

sub new {
	my $class = shift;

	my %args = @_;
	my $self = $class->SUPER::new(%args);

	warn "Create XML syntax checker\n";

	return $self;
}


sub _valid {
	my $base_uri = shift;
	my $text     = shift;

	my $validator = XML::LibXML->new;
	$validator->validation(0);
	$validator->line_numbers(1);
	$validator->base_uri($base_uri);
	$validator->load_ext_dtd(1);
	$validator->expand_entities(1);

	my $doc = '';
	eval { $doc = $validator->parse_string( $text, $base_uri ); };

	if ($@) {

		# parser error
		return _parse_msg( $@, $base_uri );
	} else {
		if ( $doc->internalSubset() ) {
			$validator->validation(1);
			eval { $doc = $validator->parse_string( $text, $base_uri ); };
			if ($@) {

				# validation error
				return _parse_msg( $@, $base_uri );
			} else {
				return [];
			}
		} else {
			return [];
		}
	}

}

sub _parse_msg {
	my ( $error_msg, $base_uri ) = @_;

	$error_msg =~ s/${base_uri}:/:/g;
	$error_msg =~ s/\sat\s.+?LibXML.pm\sline.+//go;

	my @messages = split( /\n:/, $error_msg );

	my @issues = ();

	my $m = shift @messages;

	if ( $m =~ m/^:(\d+):\s+(.+)/o ) {
		push @issues, { message => $2, line => $1, file => '', type => 'F' };
	} else {
		push @issues, { message => $m, line => $error_msg, file => '', type => 'F' };
	}

	foreach my $m (@messages) {
		$m =~ m/^(\d+):\s+(.+)/o;
		push @issues, { message => $2, line => $1, file => '', type => 'F' };
	}

	return \@issues;
}

sub syntax {
	my $self = shift;
	my $text = shift;

	my $base_uri = $self->{filename};
	warn 'No filename' if not $base_uri;

	warn "check ...\n";

	return _valid( $base_uri, $text );
}

1;

__END__



=pod

=head1 NAME

Padre::Document::XML::Syntax - XML document syntax-checking in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Document::XML::Syntax->new();
  $task->schedule;

  my $task2 = Padre::Document::XML::Syntax->new(
    text          => Padre::Documents->current->text_get,
    filename      => Padre::Documents->current->editor->{Document}->filename,
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements syntax checking of XML documents in
the background. It inherits from L<Padre::Task::Syntax>.
Please read its documentation!

=head1 SEE ALSO

This class inherits from L<Padre::Task::Syntax> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Heiko Jansen, C<< <heiko_jansen@web.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Heiko Jansen
Copyright 2010 Alexandr Ciornii
Copyright 2011 Zeno Gantner

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut
