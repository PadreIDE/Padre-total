package Padre::Plugin::SpellCheck::Preferences;

use warnings;
use strict;

use Padre::Logger;
use Padre::Util                                 ();
use Padre::Locale                               ();
use Padre::Unload                               ();
use Padre::Plugin::SpellCheck::FBP::Preferences ();

our $VERSION = '1.23';
our @ISA     = qw{
	Padre::Plugin::SpellCheck::FBP::Preferences
};
# use Data::Printer {
	# caller_info => 1,
	# colored     => 1,
# };

#######
# Method new
#######
sub new {
	my $class   = shift;
	my $_parent = shift; # parent $self

	# Create the dialog
	my $self = $class->SUPER::new( $_parent->main );

	# for access to P-P-SpellCheck DB config
	$self->{_parent} = $_parent;

	# define where to display main dialog
	$self->CenterOnParent;

	$self->set_up;

	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	# $self->{dictionary} = 'Aspell';
	$self->{dictionary} = $self->{_parent}->config_read->{Engine};

	# print " dictionary/engine = $self->{dictionary}\n";

	if ( $self->{dictionary} eq 'Aspell' ) {

		# use Aspell as default, as the aspell engine works
		$self->chosen_dictionary->SetSelection(0);
		$self->_local_aspell_dictionaries;
	} else {
		$self->chosen_dictionary->SetSelection(1);
		$self->_local_hunspell_dictionaries;
	}

	# update dialog with locally install dictionaries;
	$self->display_dictionaries;

	return;
}

#######
# Method _local_aspell_dictionaries
#######
sub _local_aspell_dictionaries {
	my $self = shift;

	my @local_dictionaries_names = ();

	eval { require Text::Aspell; };
	if ($@) {
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		print "Text::Aspell is not installed\n";
		return;
	} else {
		my $speller = Text::Aspell->new;

		my @local_dictionaries = grep { $_ =~ /^\w+$/ } map { $_->{name} } $speller->dictionary_info;
		$self->{local_dictionaries} = \@local_dictionaries;
		TRACE("locally installed dictionaries found = @local_dictionaries") if DEBUG;
		TRACE("iso to dictionary names = $self->{dictionary_names}")        if DEBUG;

		#TODO compose method local iso to padre names
		for (@local_dictionaries) {
			push( @local_dictionaries_names, $self->padre_locale_label($_) );
			$self->{dictionary_names}{$_} = $self->padre_locale_label($_);
		}

		@local_dictionaries_names = sort @local_dictionaries_names;
		$self->{local_dictionaries_names} = \@local_dictionaries_names;

		TRACE("local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
		return;
	}
}

#######
# Method _local_aspell_dictionaries
#######
sub _local_hunspell_dictionaries {
	my $self = shift;

	my @local_dictionaries_names;
	my @local_dictionaries;
	eval { require Text::Hunspell; };
	if ($@) {
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		print "Text::Hunspell is not installed\n";

		return;
	} else {

		require Padre::Util;
		my $speller = Padre::Util::run_in_directory_two('hunspell -D </dev/null');
		chomp $speller;

		#TODO this is yuck must do better
		my @speller_raw = grep { $_ =~ /\w{2}_\w{2}$/m } split /\n/, $$speller;

		my %temp_speller;
		foreach (@speller_raw) {
			if ( $_ !~ m/hyph/ ) {
				m/(\w{2}_\w{2})$/;
				my $tmp = $1;

				$temp_speller{$tmp}++;
			}
		}

		my @speller;
		while ( my ( $key, $value ) = each %temp_speller ) {
			push @local_dictionaries, $key;
		}

		$self->{local_dictionaries} = \@local_dictionaries;
		TRACE("locally installed dictionaries found = $self->{local_dictionaries}") if DEBUG;
		TRACE("iso to dictionary names = $self->{dictionary_names}")                if DEBUG;

		for (@local_dictionaries) {
			push( @local_dictionaries_names, $self->padre_locale_label($_) );
			$self->{dictionary_names}{$_} = $self->padre_locale_label($_);
		}

		@local_dictionaries_names = sort @local_dictionaries_names;
		$self->{local_dictionaries_names} = \@local_dictionaries_names;
		TRACE("local dictionaries names = $self->{local_dictionaries_names}") if DEBUG;
		return;
	}
}

#######
# Method display_dictionaries
#######
sub display_dictionaries {
	my $self = shift;
	my $main = $self->main;

	my $prefered_dictionary = $self->{_parent}->config_read->{ $self->{dictionary} };

	TRACE("iso prefered_dictionary = $prefered_dictionary ") if DEBUG;

	# set local_dictionaries_index to zero in case prefered_dictionary not found
	my $local_dictionaries_index = 0;
	require Padre::Locale;
	for ( 0 .. $#{ $self->{local_dictionaries_names} } ) {
		if ( $self->{local_dictionaries_names}->[$_] eq $self->padre_locale_label($prefered_dictionary) ) {
			$local_dictionaries_index = $_;
		}
	}

	TRACE("local_dictionaries_index = $local_dictionaries_index ") if DEBUG;

	$self->language->Clear;

	# load local_dictionaries_names
	$self->language->Append( $self->{local_dictionaries_names} );

	# highlight prefered_dictionary
	$self->language->SetSelection($local_dictionaries_index);

	return;
}

#######
# event handler _on_button_ok_clicked
#######
sub _on_button_save_clicked {
	my $self = shift;

	my $select_dictionary_name = $self->{local_dictionaries_names}->[ $self->language->GetSelection() ];
	TRACE("selected dictionary name = $select_dictionary_name ") if DEBUG;

	my $select_dictionary_iso = 0;

	# require Padre::Locale;
	for my $iso ( keys %{ $self->{dictionary_names} } ) {
		if ( $self->padre_locale_label($iso) eq $select_dictionary_name ) {
			$select_dictionary_iso = $iso;
		}
	}
	TRACE("selected dictionary iso = $select_dictionary_iso ") if DEBUG;

	# save config info
	my $config = $self->{_parent}->config_read;
	$config->{ $self->{dictionary} } = $select_dictionary_iso;
	$config->{Engine} = $self->{dictionary};
	$self->{_parent}->config_write($config);

	#this is naff
	# TRACE("Saved P-P-SpellCheck config DB = $self->{_parent}->config_read ") if DEBUG;

	# p $self->{_parent}->config_read;

	$self->{_parent}->clean_dialog;
	return;
}

#######
# event handler on_dictionary_chosen
#######
sub on_dictionary_chosen {
	my $self = shift;

	if ( $self->chosen_dictionary->GetSelection() == 0 ) {
		$self->{dictionary} = 'Aspell';
		$self->_local_aspell_dictionaries;
	} else {
		$self->{dictionary} = 'Hunspell';
		$self->_local_hunspell_dictionaries;
	}

	$self->display_dictionaries;

	return;
}

#######
# Composed Method padre_local_label
# aspell to padre local label
#######
sub padre_locale_label {
	my $self             = shift;
	my $local_dictionary = shift;

	my $lc_local_dictionary = lc( $local_dictionary ? $local_dictionary : 'en_GB' );

	# my $lc_local_dictionary = lc $local_dictionary;
	$lc_local_dictionary =~ s/_/-/;
	require Padre::Locale;
	my $label = Padre::Locale::label($lc_local_dictionary);

	return $label;
}


1;

__END__

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.