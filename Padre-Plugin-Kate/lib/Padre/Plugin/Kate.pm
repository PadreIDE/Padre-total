package Padre::Plugin::Kate;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Current;

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Kate - Using the Kate syntax highlighter

=head1 SYNOPSIS

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub padre_interfaces {
	return 'Padre::Plugin' => 0.26;
}

sub plugin_name {
	'Kate';
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
	];
}

sub provided_highlighters { 
	return (
		['Padre::Plugin::Kate', 'Kate', 'Using Syntax::Highlight::Engine::Kate based on the Kate editor'],
	);
}

sub highlighting_mime_types {
	return (
		'Padre::Plugin::Kate' => ['application/x-php'],
	);
}

# TODO shall we create a module for each mime-type and register it as a highlighter
# or is our dispatching ok?
# Shall we create a module called Pudre::Plugin::Kate::Colorize that will do the dispatching ?
my %d = (
	'application/x-php' => 'PHP',
);
sub colorize {
	my $self = shift;
	my $doc = Padre::Current->document;
	my $mime_type = $doc->get_mimetype;
	
	if ( $d{$mime_type} ) {
		my $module = 'Padre::Plugin::Kate::' . $d{$mime_type};
print "M '$module'\n";
		eval "use $module";
		if ($@) {
			warn $@;
			return;
		}
		$module->colorize(@_);
	} else {
		warn("Invalid mime-type ($mime_type) passed to the Kate highlighter");
	}
	return;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Trying to use Syntax::Highlight::Engine::Kate for syntax highlighting\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


