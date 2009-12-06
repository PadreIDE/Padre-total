package Padre::Plugin::DataWalker;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ('_T');

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::DataWalker - Simple Perl data structure browser Padre

=head1 SYNOPSIS

Use this like any other Padre plugin. To install
Padre::Plugin::DataWalker for your user only, you can
type the following in the extracted F<Padre-Plugin-DataWalker-...>
directory:

  perl Makefile.PL
  make
  make test
  make installplugin

Afterwards, you can enable the plugin from within Padre
via the menu I<Plugins-E<gt>Plugin Manager> and there click
I<enable> for I<DataWalker>.

=head1 DESCRIPTION

This plugin uses the L<Wx::Perl::DataWalker> module to
provide facilities for interactively browsing Perl data structures.

At this time, the plugin offers several menu entries
in Padre's I<Plugins> menu:

=over 2

=item Browse YAML dump file

If you dump (almost) any data structure from a running program into
a YAML file, you can use this to open the dump and browse
it within Padre. Dump a data structure like this:

  use YAML::XS; YAML::XS::Dump(...YourDataStructure...);

This menu entry will show a file-open dialog and let you select the YAML
file to load.

Let me know if you need any other input format (like Storable's nstore).

=item Browse current document object

Opens the data structure browser on the current document object.

Like all following menu entries, this is mostly useful for the Padre developers.

=item Browse Padre IDE object

Opens the Padre main IDE object in the data structure browser. Useful for debugging Padre.

=item Browse Padre main symbol table

Opens the C<%main::> symbol table of Padre in the data structure browser.
Certainly only useful for debugging Padre.

=back

=cut


sub padre_interfaces {
	'Padre::Plugin' => 0.24,
}

sub plugin_name {
	'DataWalker';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		_T('About')                          => sub { $self->show_about },
		_T('Browse YAML dump file')          => sub { $self->browse_yaml_file },
		_T('Browse current document object') => sub { $self->browse_current_document },
		_T('Browse Padre IDE object')        => sub { $self->browse_padre },
		_T('Browse Padre main symbol table') => sub { $self->browse_padre_stash },
	];
}

sub browse_yaml_file {
	my $self = shift;
	require YAML::XS;
	my $main = Padre->ide->wx->main;
	my $dialog = Wx::FileDialog->new(
		$main,
		_T('Open file'),
		$main->cwd,
		"",
		"*.*",
		Wx::wxFD_OPEN|Wx::wxFD_FILE_MUST_EXIST,
	);
	unless ( Padre::Util::WIN32() ) {
		$dialog->SetWildcard("*");
	}

	return if $dialog->ShowModal == Wx::wxID_CANCEL;
	my @filenames = $dialog->GetFilenames or return();
	my $file = File::Spec->catfile($dialog->GetDirectory(), shift @filenames);

	if (not (-f $file and -r $file)) {
		Wx::MessageBox(
			sprintf(_T("Could not find the specified file '%s'"), $file),
			_T('File not found'),
			Wx::wxOK,
			$main,
		);
	}

	my $data = eval {YAML::XS::LoadFile($file)};
	if (not defined $data or $@) {
		Wx::MessageBox(
			sprintf(_T("Could not read the YAML file.%s", ($@ ? "\n$@" : ""))),
			_T('Invalid YAML file'),
			Wx::wxOK,
			$main,
		);
	}

	$self->_data_walker($data);
	return();
}

sub browse_padre_stash {
	my $self = shift;
	$self->_data_walker(\%::);
	return();
}


sub browse_current_document {
	my $self = shift;
	my $doc = Padre::Current->document;
	$self->_data_walker($doc);
	return();
}


sub browse_padre {
	my $self = shift;
	$self->_data_walker(Padre->ide);
	return();
}

sub _data_walker {
	my $self = shift;
	my $data = shift;
	require Wx::Perl::DataWalker;
        
	my $dialog = Wx::Perl::DataWalker->new(
		{data => $data},
		undef,
		-1,
		"DataWalker",
	);
	$dialog->SetSize(500, 500);
	$dialog->Show(1);
	return();
}


sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::DataWalker");
	$about->SetDescription( <<"END_MESSAGE" );
Simple Perl data structure browser for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

1;

__END__


=head1 AUTHOR

Steffen Mueller, C<< <smueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
