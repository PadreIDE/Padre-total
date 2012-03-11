package Padre::Plugin::YAML;

# ABSTRACT: YAML support for Padre The Perl IDE.
use 5.010001;
use strict;
use warnings;

use Padre::Plugin ();
use Padre::Unload ();
use Padre::Wx     ();
use File::Spec::Functions qw{ catfile };
use Try::Tiny;

our $VERSION = '0.02';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::YAML
	Padre::Document::YAML
	Padre::Document::YAML::Syntex
};

#######
# Define Plugin Name Spell Checker
#######
sub plugin_name {
	return Wx::gettext('YAML');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'   => 0.94,
		'Padre::Document' => 0.94,
	);
}

#######
# plugin registered_documents
#######
sub registered_documents {
	return (
		'text/x-yaml' => 'Padre::Document::YAML',
	);
}

#######
# plugin menu_plugins_simple
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Check YAML') => sub { $self->check_yaml },
		Wx::gettext('About')      => sub { $self->show_about },
	];
}

#######
# Method check_yaml
#######
sub check_yaml {
	my $self     = shift;
	my $main     = $self->main;
	my $text     = $main->current->text;
	my $document = $main->current->document;

	unless ( $document and $document->isa('Padre::Document::YAML') ) {
		$main->message( Wx::gettext('This is not an YAML document! ') . ref $document );
		return;
	}
	say "here we are";
	require YAML;
	
	try { Load ( $document ) }
	
	catch {
		$self->main->error( sprintf( Wx::gettext('YAML Error: %s'), $_ ) );
		}
	# my $code = ($text) ? $text : $document->text_get;

	# return unless ( defined $code and length($code) );

	# require XML::Tidy;

	# my $tidy_obj = '';
	# my $string   = '';
	# eval {
	# $tidy_obj = XML::Tidy->new( xml => $code );
	# $tidy_obj->tidy();

	# $string = $tidy_obj->toString();
	# };

	# if ( !$@ ) {
	# if ($text) {
	# $string =~ s/\A<\?xml.+?\?>\r?\n?//o;
	# my $editor = $main->current->editor;
	# $editor->ReplaceSelection($string);
	# } else {
	# $document->text_set($string);
	# }
	# } else {
	# $main->message( Wx::gettext("Tidying failed due to error(s):") . "\n\n" . $@ );
	# }

	return;
}


#######
# Method show_about
#######
sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('YAML Plug-in') );
	my $authors     = 'Kevin Dawson, Zeno Gantner';
	my $description = Wx::gettext( <<'END' );
YAML support for Padre

Copyright 2011-2012 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::YAML - YAML support for Padre The Perl IDE


=head1 VERSION

This document describes Padre::Plugin::YAML version 0.02


=head1 DESCRIPTION

YAML support for Padre, the Perl Application Development and Refactoring
Environment.

Syntax highlighting for YAML is supported by Padre out of the box.
This plug-in adds some more features to deal with YAML files.


=head1 DEPENDENCIES

None.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Padre::Plugin::YAML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-YAML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-YAML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-YAML>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-YAML/>

=back


=head1 AUTHOR

Kevin Dawson  E<lt>bowtie@cpan.orgE<gt>

Zeno Gantner E<lt>zenog@cpan.orgE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011-2012, Zeno Gantner E<lt>zenog@cpan.orgE<gt>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=cut


##### junk keep for now

#sub plugin_icon {
#	my $self = shift;

# find resource path
#my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'file.png' );

# create and return icon
#return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
#}
