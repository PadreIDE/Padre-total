package Padre::Plugin::SpellCheck;

use 5.008005;
use strict;
use warnings;

use Padre::Plugin ();
use Padre::Unload ();
use File::Which   ();

our $VERSION = '1.23';
our @ISA     = 'Padre::Plugin';
# use Data::Printer {
	# caller_info => 1,
	# colored     => 1,
# };

#######
# Define Plugin Name Spell Checker
#######
sub plugin_name {
	return Wx::gettext('Spell Checker');
}

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (
		'Padre::Plugin' => '0.94',
		'Padre::Unload' => '0.94',

		# used by my sub packages
		'Padre::Locale'         => '0.94',
		'Padre::Logger'         => '0.94',
		'Padre::Wx'             => '0.94',
		'Padre::Wx::Role::Main' => '0.94',
		'Padre::Util'           => '0.94',
	);
}

#######
# plugin menu
#######
sub menu_plugins {
	my $self = shift;
	my $main = $self->main;

	# Create a manual menu item
	my $item = Wx::MenuItem->new( undef, -1, $self->plugin_name . "...\tF7 ", );
	Wx::Event::EVT_MENU(
		$main, $item,
		sub {
			local $@;
			eval { $self->spell_check($main); };
		},
	);

	return $item;
}

#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self                       = shift;
	my $local_dictonary_bin_exists = 0;

	# Tests for externals used by Preference's
	if ( eval { require Text::Aspell } ) {
		$local_dictonary_bin_exists = 1;
	}
	if ( File::Which::which('hunspell') ) {
		$local_dictonary_bin_exists = 1;
	}

	#Set/ReSet Config data
	$self->_config if $local_dictonary_bin_exists;

	# p $self->_config_read;

	return $local_dictonary_bin_exists;
}

#######
# Composed Method _config
# called on enable in plugin manager, bit like run/setup for a Plugin
#######
sub _config {
	my $self   = shift;
	my $config = $self->config_read;

	###
	#	Info P-P-SpellCheck 	< 1.21
	#	$config->{dictionary}   = iso
	#
	#	Info P-P-SpellCheck     = 1.22
	#	- $config->{dictionary} = iso
	#	+ $config->{Aspell}     = en_GB
	#	+ $config->{Hunspell}   = en_AU
	#	+ $config->{Version}    = $VERSION
	#
	#	Info P-P-SpellCheck    >= 1.23
	#	+ $config->{Engine}     = 'Aspell'
	###
	if ( eval { $config->{Version} >= 1.23; } ) {
		return;
	} elsif (
		eval {
			$config->{Version} < 1.23;
		}
		)
	{
		$config->{Version} = $VERSION;
		$config->{Engine}  = 'Aspell';
		$self->config_write($config);
		return;
	} elsif (
		eval {
			$config->{dictionary};
		}
		)
	{
		my $tmp_iso = $config->{dictionary};
		$self->config_write( {} );
		$config             = $self->config_read;
		$config->{Aspell}   = $tmp_iso;
		$config->{Hunspell} = $tmp_iso;
		$config->{Version}  = $VERSION;
		$config->{Engine}   = 'Aspell';
		$self->config_write($config);
		return;
	} else {
		$self->config_write( {} );
		$config->{Aspell}   = 'en_GB';
		$config->{Hunspell} = 'en_GB';
		$config->{Version}  = $VERSION;
		$config->{Engine}   = 'Aspell';
		$self->config_write($config);
	}

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

	require Padre::Unload;
	Padre::Unload->unload(
		qw{
			Padre::Plugin::SpellCheck
			Padre::Plugin::SpellCheck::Checker
			Padre::Plugin::SpellCheck::FBP::Checker
			Padre::Plugin::SpellCheck::Engine
			Padre::Plugin::SpellCheck::Preferences
			Padre::Plugin::SpellCheck::FBP::Preferences
			Text::Aspell
			}
	);

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


#######
# plugin_preferences
#######
sub plugin_preferences {
	my $self = shift;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	require Padre::Plugin::SpellCheck::Preferences;
	$self->{dialog} = Padre::Plugin::SpellCheck::Preferences->new($self);
	$self->{dialog}->ShowModal;

	return;
}

#######
# spell_check
#######
sub spell_check {
	my $self = shift;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	require Padre::Plugin::SpellCheck::Checker;
	$self->{dialog} = Padre::Plugin::SpellCheck::Checker->new($self);
	$self->{dialog}->Show;

	return;
}


1;

__END__

# DO NOT REMOVE
#######
# Add icon to Plugin
#######
sub plugin_icon {
		my $self = shift;

		# find resource path
		my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'spellcheck.png' );

		# create and return icon
		return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

sub menu_plugins_simple {
	my $self = shift;
	return Wx::gettext('Spell Check') => [
		Wx::gettext("Check spelling...\tF7") => sub { $self->spell_check },
		Wx::gettext('Preferences')           => sub { $self->plugin_preferences },
	];
}


=head1 NAME

Padre::Plugin::SpellCheck - Check spelling in Padre The Perl IDE

=head1 DESCRIPTION

This plug-in allows one to check there spelling within Padre using
C<F7> (standard spelling short-cut across text processors). 

One can change the dictionary language used (based upon install languages) in the preferences window via Plug-in Manager. 
Preferences are persistent. You need to Save your preferred language.

This plug-in is using C<Text::Aspell> default (legacy). You can also use C<Text::Hunspell>, so check these module's
pod for more information and install the one for you.

Of course, you need to have the relevant Dictionary binary, dev and dictionary installed.


=head1 SYNOPSIS

    Check your file or selected text for spelling errors in your preferred language.
    F7

=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::SpellCheck> defines a plug-in which follows
C<Padre::Plugin> API. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 7

=item clean_dialog()

=item menu_plugins()

=item padre_interfaces()

=item plugin_disable()

=item plugin_enable()

Return the plug-in's configuration, or a suitable default one if none exist previously.

=item plugin_name()

=item plugin_preferences()

Open the check spelling preferences window.

=back


=head2 Spell checking methods

=over 1

=item * spell_check()

Spell checks the current selection (or the whole document).


=back

=head1 BUGS

Spell-checking non-ascii files has bugs: the selection does not
match the word boundaries, and as the spell checks moves further in
the document, offsets are totally irrelevant. This is a bug in
C<Wx::StyledTextCtrl> that has some Unicode problems... So
unfortunately, there's nothing that I can do in this plug-in to
tackle this bug.

Please report any bugs or feature requests to C<padre-plugin-spellcheck
at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-
SpellCheck>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.




=head1 SEE ALSO

Plug-in icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

=over 2

=item * Padre-Plugin-SpellCheck web page

L<http://padre.perlide.org/trac/wiki/PadrePluginSpellCheck>

=item * Our svn repository 

L<http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck>, 
and can be browsed at 
L<http://padre.perlide.org/browser/trunk/Padre-Plugin-SpellCheck>.

=back

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-SpellCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-SpellCheck>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-SpellCheck>

=back

Everything Aspell related: L<http://aspell.net>.

Everything Hunspell related: L<http://hunspell.sourceforge.net/>.

=head1 AUTHORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

Fayland Lam E<lt>fayland at gmail.comE<gt>

Jerome Quelin E<lt>jquelin@gmail.comE<gt>


=head1 COPYRIGHT

This software is copyright (c) 2010 by Fayland Lam, Jerome Quelin.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
=cut
