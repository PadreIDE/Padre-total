package Padre::Plugin::Nopaste::Preferences;

use v5.10;
use warnings;
use strict;

use Try::Tiny;
use Padre::Logger;
use Padre::Util                              ();
use Padre::Locale                            ();
use Padre::Unload                            ();
use Padre::Plugin::Nopaste::Services         ();
use Padre::Plugin::Nopaste::FBP::Preferences ();

our $VERSION = '0.04';
use parent qw(
	Padre::Plugin::Nopaste::FBP::Preferences
	Padre::Plugin
);
use Data::Printer {
	caller_info => 1,
	colored     => 1,
};
#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialogue
	my $self = $class->SUPER::new($main);

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle( sprintf Wx::gettext('Nopaste-Preferences v%s'), $VERSION );
	$self->_set_up;

	return $self;
}

#######
# Method _set_up
#######
sub _set_up {
	my $self      = shift;
	my $main      = $self->main;
	my $config    = $main->config;
	my $config_db = $self->config_read;

	my $services = Padre::Plugin::Nopaste::Services->new;
	$self->{nopaste_services} = $services;

	#Set nickname
	$self->{config_nickname}->SetLabel( $config->identity_nickname );

	#get nopaste prefered server and channel from config db
	$self->{prefered_server}  = $config_db->{Services};
	$self->{prefered_channel} = $config_db->{Channel};

	# update dialogue
	$self->_display_servers;
	$self->_display_channels;

	return;
}





#######
# Method _display_servers
#######
sub _display_servers {
	my $self = shift;

	my $servers = $self->{nopaste_services}->servers;

	# set local_server_index to zero in case predefined not found
	my $local_server_index = 0;

	for ( 0 .. $#{$servers} ) {
		if ( $servers->[$_] eq $self->{prefered_server} ) {
			$local_server_index = $_;
		}
	}

	$self->{nopaste_server}->Clear;
	$self->{nopaste_server}->Append($servers);
	$self->{nopaste_server}->SetSelection($local_server_index);

	return;
}

#######
# Method _display_channels
#######
sub _display_channels {
	my $self = shift;

	my $channels = $self->{nopaste_services}->{ $self->{prefered_server} };

	# set local_server_index to zero in case predefined not found
	my $local_channel_index = 0;

	for ( 0 .. $#{$channels} ) {
		if ( $channels->[$_] eq $self->{prefered_channel} ) {
			$local_channel_index = $_;
		}
	}

	$self->{nopaste_channel}->Clear;
	$self->{nopaste_channel}->Append($channels);
	$self->{nopaste_channel}->SetSelection($local_channel_index);

	return;
}

#######
# event handler on_button_ok_clicked
#######
sub on_button_save_clicked {
	my $self      = shift;
	my $config_db = $self->config_read;

	$config_db->{Services} = $self->{nopaste_services}->servers->[ $self->{nopaste_server}->GetSelection() ];
	$config_db->{Channel} =
		$self->{nopaste_services}->{ $self->{prefered_server} }->[ $self->{nopaste_channel}->GetSelection() ];

	# p $config_db->{Services};
	# p $config_db->{Channel};

	$self->config_write($config_db);

	$self->Hide;
	return;
}

#######
# event handler on_button_ok_clicked
#######
sub on_button_reset_clicked {
	my $self      = shift;
	my $config_db = $self->config_read;

	$config_db->{Services} = 'Shadowcat';
	$config_db->{Channel}  = '#padre';
	$self->config_write($config_db);
	
	$self->{prefered_server} = 'Shadowcat';
	$self->{prefered_channel} = '#padre';
	
	$self->refresh;
	return;
}

#######
# event handler on_server_chosen, save choices and close
#######
sub on_server_chosen {
	my $self = shift;

	# p $self->{nopaste_server}->GetSelection();

	# p $self->{nopaste_services}->servers->[ $self->{nopaste_server}->GetSelection() ];

	$self->{prefered_server} = $self->{nopaste_services}->servers->[ $self->{nopaste_server}->GetSelection() ];

	$self->{prefered_channel} = 0;

	$self->refresh;

	return;
}

#######
# refresh dialog with choices
#######
sub refresh {
	my $self = shift;

	$self->_display_servers;
	$self->_display_channels;

	return;
}





#######
# Method _local_aspell_dictionaries
#######
# sub z_local_hunspell_dictionaries {
# my $self = shift;

# my @local_dictionaries_names;
# my @local_dictionaries;

# # if ( require Text::Hunspell ) {
# try {
# require Text::Hunspell;
# require Padre::Util;

# my $speller = Padre::Util::run_in_directory_two( cmd => 'hunspell -D </dev/null', option => '0' );
# TRACE("hunspell speller = $speller") if DEBUG;

# #TODO this is yuck must do better
# my @speller_raw = grep { $_ =~ /\w{2}_\w{2}$/m } split /\n/, $speller->{error};
# my %temp_speller;
# foreach (@speller_raw) {
# if ( $_ !~ m/hyph/ ) {
# m/(\w{2}_\w{2})$/;
# my $tmp = $1;
# $temp_speller{$tmp}++;
# }
# }

# while ( my ( $key, $value ) = each %temp_speller ) {
# push @local_dictionaries, $key;
# }

# $self->{local_dictionaries} = \@local_dictionaries;
# TRACE("Hunspell locally installed dictionaries found = $self->{local_dictionaries}") if DEBUG;
# TRACE("Hunspell iso to dictionary names = $self->{dictionary_names}")                if DEBUG;

# for (@local_dictionaries) {
# push( @local_dictionaries_names, $self->padre_locale_label($_) );
# $self->{dictionary_names}{$_} = $self->padre_locale_label($_);
# }

# @local_dictionaries_names = sort @local_dictionaries_names;
# $self->{local_dictionaries_names} = \@local_dictionaries_names;
# TRACE("Hunspell local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
# return;

# }
# catch {
# $self->{local_dictionaries_names} = \@local_dictionaries_names;
# $self->main->info( Wx::gettext('Text::Hunspell is not installed') );
# return;
# };
# return;
# }



#######
# Method _local_aspell_dictionaries
#######
# sub z_local_aspell_dictionaries {
# my $self = shift;

# my @local_dictionaries_names = ();

# try {
# require Text::Aspell;
# my $speller = Text::Aspell->new;

# my @local_dictionaries = grep { $_ =~ /^\w+$/ } map { $_->{name} } $speller->dictionary_info;
# $self->{local_dictionaries} = \@local_dictionaries;
# TRACE("Aspell locally installed dictionaries found = @local_dictionaries") if DEBUG;
# TRACE("Aspell iso to dictionary names = $self->{dictionary_names}")        if DEBUG;

# for (@local_dictionaries) {
# push @local_dictionaries_names, $self->padre_locale_label($_);
# $self->{dictionary_names}{$_} = $self->padre_locale_label($_);
# }

# @local_dictionaries_names = sort @local_dictionaries_names;
# $self->{local_dictionaries_names} = \@local_dictionaries_names;

# TRACE("Aspell local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
# }
# catch {
# $self->{local_dictionaries_names} = \@local_dictionaries_names;
# $self->main->info( Wx::gettext('Text::Aspell is not installed') );
# };
# return;
# }



#######
# Composed Method padre_local_label
# aspell to padre local label
#######
# sub z_padre_locale_label {
# my $self = shift;

# my $local_dictionary = shift;

# my $lc_local_dictionary = lc( $local_dictionary ? $local_dictionary : 'en_GB' );
# $lc_local_dictionary =~ s/_/-/;
# require Padre::Locale;
# my $label = Padre::Locale::label($lc_local_dictionary);

# return $label;
# }

1;

__END__

=pod

=head1 NAME

Padre::Plugin::SpellCheck::Preferences - Check spelling in Padre, The Perl IDE.

=head1 VERSION

version  0.04

=head1 DESCRIPTION

This module handles the Preferences dialogue window that is used to set your 
chosen dictionary and preferred language.


=head1 METHODS

=over 2

=item * new

	$self->{dialog} = Padre::Plugin::SpellCheck::Preferences->new( $self );

Create and return a new dialogue window. 

=item * on_server_chosen
event handler

=item * on_button_save_clicked
event handler

=item * on_button_reset_clicked
event handler, reset for #padre

=item * refresh

refresh dialog

=back

=head2 INTERNAL METHODS

=over 2

=item * _display_channels
=item * _display_servers
=item * _setup

=back

=head1 BUGS AND LIMITATIONS

Throws an info on the status bar if you try to select a language if dictionary not installed

=head1 DEPENDENCIES

Padre, Padre::Plugin::Nopaste::FBP::Preferences

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::Nopaste>.

=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 kevin dawson, all rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

