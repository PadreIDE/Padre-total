package Padre::Plugin::SpellCheck;

# ABSTRACT: Check spelling in Padre
use 5.008005;
use strict;
use warnings;

use Padre::Plugin;
use Padre::Locale ();
use Padre::Unload ();

# use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '1.22';
our @ISA     = 'Padre::Plugin';


# use Padre::Plugin::SpellCheck::Engine;


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
		'Padre::Locale' => '0.94',

		# used by my sub packages
		'Padre::Logger'         => '0.94',
		'Padre::Wx'             => '0.94',
		'Padre::Wx::Role::Main' => '0.94',
		'Padre::Util'           => '0.94',

		# 'Padre::Task'       => 0.93,
		# 'Padre::Document'   => 0.93,
		# 'Padre::Project'    => 0.93,
		# 'Padre::Wx::Main'   => 0.93,
		# 'Padre::Wx::Editor' => 0.93,
		# 'Padre::Current'    => '0.93',
		# 'Padre::Wx::Main'   => '0.92',
		# 'Padre::DB'         => '0.92',
		# 'Padre::Logger'     => '0.92',
	);
}

# DO NOT REMOVE
#######
# Add icon to Plugin
#######
# sub plugin_icon {
# my $self = shift;

# # find resource path
# my $iconpath = catfile( $self->plugin_directory_share, 'icons', 'spellcheck.png' );

# # create and return icon
# return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
# }

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

	my $aspell_exists = 0;

	# Tests for external file in Path...
	if ( File::Which::which('aspell') ) {
		$aspell_exists = 1;
	}
	return $aspell_exists;
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

### -- public methods

#######
# config
# store's language in DB
#######
# sub config1 {
# my $self = shift;

# $self->{config} = $self->config_read;

# if ( $self->{config}->{dictionary} ) {

# # print "Loaded existing configuration\n";
# # p $self->{config}->{dictionary};

# # $self->config_write( { dictionary => 'en', } );
# # my $lang_iso = $self->{config}->{dictionary};
# # $self->lang_iso = $lang_iso;

# } else {
# print "No existing configuration";
# $self->config_write( { dictionary => 'en_GB', } );
# $self->{config}->{dictionary} = 'en_GB';
# # $self->lang_iso = 'en_GB';
# }

# return $self->config_read || $self->{config};

# }

# sub config {
	# my $self   = shift;
	# my $config = {
		# dictionary => 'en_GB',
	# };
	# return $self->config_read || $config;
# }

#######
# spell_check
#######
sub spell_check {
	my $self = shift;
	# my $main = $self->main;

	# my $lang_iso = $self->config->{dictionary};

	# p $lang_iso;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	require Padre::Plugin::SpellCheck::Checker;
	# $self->{dialog} = Padre::Plugin::SpellCheck::Checker->new( $main, $lang_iso );
	$self->{dialog} = Padre::Plugin::SpellCheck::Checker->new( $self );
	$self->{dialog}->Show;

	return;
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
# accessor get_config
#######
# sub get_config {
	# my $self = shift;

	# my $config = {
		# dictionary => 'en_GB',
	# };

	# my $config_read = $self->config_read;

	# if ( defined $config_read->{dictionary} ) {

		# # p $config_read->{dictionary};
		# # if ( $config_read->{dictionary} ){
		# require Padre::Locale;
		# my $thing = Padre::Locale->rfc4646_exists( $config_read->{dictionary} );

		# # p $thing;

		# #for me this allways returns 'en_gb'
		# # my $code    = Padre::Locale::rfc4646();
		# my $code = Padre::Locale::rfc4646( $config_read->{dictionary} );

		# # p $code;

		# my %language = Padre::Locale::menu_view_languages();

		# # p %language;
		# my $iso    = $config_read->{dictionary};
		# my $lc_iso = lc $iso;
		# $lc_iso =~ s/_/-/;

		# # p $lc_iso;
		# my $label = Padre::Locale::label($lc_iso);

		# # p $label;

		# # print "rfc4646_exists\n";
		# # }
		# return $self->config_read;
	# } else {
		# return $config;
	# }
# }
#######
# accessor set_config
#######
# sub set_config {
	# my $self = shift;

	# #TODO this should check before commiting
	# $self->config_write(@_);
# }

1;

__END__

=head1 NAME

Padre::Plugin::SpellCheck - Check spelling in Padre The Perl IDE

=head1 DESCRIPTION

This plugins allows one to check there text spelling within Padre using
C<F7> (standard spelling shortcut across text processors). 

One can change the dictionary language used (based upon install languages) in the preferences window via Plug-in Manager. 
Preferences are persistent.

This plugin is using C<Text::Aspell> default at present, You can also use C<Text::Hunspell> under-development, so check these module's
pod for more information.

Of course, you need to have the relevant Dictionary binary, dev and dictionary installed.


=head1 SYNOPSIS

    $ padre file-with-spell-errors
    F7


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::SpellCheck> defines a plugin which follows
C<Padre::Plugin> API. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interfaces()

=item plugin_icon()

=item plugin_name()

=back


=head2 Spell checking methods

=over 4

=item * config()

Return the plugin's configuration, or a suitable default one if none
exist previously.

=item * spell_check()

Spell checks the current selection (or the whole document).

=item * plugin_preferences()

Open the check spelling preferences window.

=back

=head1 BUGS

Spell-checking non-ascii files has bugs: the selection does not
match the word boundaries, and as the spell checks moves further in
the document, offsets are totally irrelevant. This is a bug in
C<Wx::StyledTextCtrl> that has some unicode problems... So
unfortunately, there's nothing that I can do in this plugin to
tackle this bug.

Please report any bugs or feature requests to C<padre-plugin-spellcheck
at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-
SpellCheck>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.




=head1 SEE ALSO

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

Our svn repository is located at L<http://svn.perlide.org/padre/trunk/Padre-Plugin-
SpellCheck>, and can be browsed at L<http://padre.perlide.org/browser/trunk/Padre-Plugin-
SpellCheck>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-SpellCheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-SpellCheck>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-SpellCheck>

=back

Everything aspell related: L<http://aspell.net>.

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
