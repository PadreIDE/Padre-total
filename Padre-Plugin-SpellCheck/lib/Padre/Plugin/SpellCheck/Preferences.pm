package Padre::Plugin::SpellCheck::Preferences;

# ABSTRACT: Preferences dialog for padre spell check

use warnings;
use strict;
use Padre::Logger;

use Padre::Locale                               ();
use Padre::Unload                               ();
use Padre::Plugin::SpellCheck::FBP::Preferences ();
# use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '1.22';
our @ISA     = qw{
	Padre::Plugin::SpellCheck::FBP::Preferences
};


#######
# Method new
#######
sub new {
	my $class   = shift;
	my $main    = shift; # Padre $main window integration
	my $_plugin = shift; # parent $self

	# Create the dialog
	my $self = $class->SUPER::new($main);

	#TODO there must be a better way
	$self->{_plugin} = $_plugin;

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

	# get local_dictionary info
	$self->_local_dictionaries;

	# update dialog with locally install dictionaries;
	$self->display_dictionaries;

	return;
}

#######
# Method display_dics
#######
sub display_dictionaries {
	my $self = shift;
	my $main = $self->main;

	#TODO sort out 'get config read'
	# my $config = $self->get_config->{dictionary};
	# my $config = $self->config->{dictionary};
	# p $config;

	# my $prefered_dictionary = $self->get_config->{dictionary};
	# my $prefered_dictionary = 'en_GB';
	# my $prefered_dictionary = $self->{_plugin}->config->{dictionary};
	my $prefered_dictionary = $self->{_plugin}->get_config->{dictionary};
	# p $prefered_dictionary;

	# my $lc_prefered_dictionary = lc $prefered_dictionary;
	# $lc_prefered_dictionary =~ s/_/-/;
	# p $lc_prefered_dictionary;

	# my $prefered_dictionary = $config->dictionary;
	TRACE("iso prefered_dictionary = $prefered_dictionary ") if DEBUG;

	# set local_dictionaries_index to zero incase prefered_dictionary not found
	my $local_dictionaries_index = 0;
	require Padre::Locale;
	for ( 0 .. $#{ $self->{local_dictionaries_names} } ) {
		# if ( $self->{local_dictionaries_names}->[$_] eq $self->{dictionary_names}->{$prefered_dictionary} ) {
		# if ( $self->{local_dictionaries_names}->[$_] eq Padre::Locale::label($lc_prefered_dictionary) ) {
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
sub _on_button_ok_clicked {
	my $self = shift;

	my $select_dictionary_name = $self->{local_dictionaries_names}->[ $self->language->GetSelection() ];
	TRACE("selected dictionary name = $select_dictionary_name ") if DEBUG;
	# p $select_dictionary_name;
	my $select_dictionary_iso = 0;
	# require Padre::Locale;
	for my $iso ( keys %{ $self->{dictionary_names} } ) {
		# p $iso;
		# my $lc_iso = lc $iso;
		# $lc_iso =~ s/_/-/;

		# if ( Padre::Locale::label( $lc_iso ) eq $select_dictionary_name ) {
		# if ( Padre::Locale::label( $lc_iso ) eq $select_dictionary_name ) {
		# if ( $self->{dictionary_names}->{$iso} eq $select_dictionary_name ) {		
		if ( $self->padre_locale_label( $iso ) eq $select_dictionary_name ) {
			$select_dictionary_iso = $iso;
		}
	}
	TRACE("selected dictionary iso = $select_dictionary_iso ") if DEBUG;
	# p $select_dictionary_iso;

	#TODO 'set config write' store plugin preferences
	$self->{_plugin}->config_write( { dictionary => $select_dictionary_iso, } );

	# $self->config_write( { dictionary => $select_dictionary_iso, } );
	# $self->set_config( { dictionary => $select_dictionary_iso, } );

	# remove dialog nicely
	$self->{_plugin}->clean_dialog;

	# $self->Hide;
	# $self->Destroy;

	return;
}

#######
# Method _local_dictionaries
#######
sub _local_dictionaries {
	my $self = shift;

	#TODO this should be done via engine

	require Text::Aspell;
	my $speller = Text::Aspell->new;

	my @local_dictionaries = grep { $_ =~ /^\w+$/ } map { $_->{name} } $speller->dictionary_info;
	$self->{local_dictionaries} = \@local_dictionaries;
	TRACE( "locally installed dictionaries found = " . Dumper $self->{local_dictionaries} ) if DEBUG;

	#TODO should we be using Padre::Locale instead?
	# $self->{dictionary_names} = {
		# ar    => 'ARABIC',
		# cs    => 'CZECH',
		# de    => 'GERMAN',
		# de_DE => 'GERMANY',
		# en    => 'ENGLISH',
		# en_AU => 'AUSTRALIA_ENGLISH',
		# en_CA => 'CANADA_ENGLISH',
		# en_GB => 'BRITISH_ENGLISH',    # en_GB => 'UK'
		# en_US => 'AMERICAN_ENGLISH',   # en_US => 'US'
		# es    => 'SPANISH',
		# fr    => 'FRENCH',
		# fr_FR => 'FRANCE',
		# fr_CA => 'CANADA_FRENCH',
		# he    => 'HEBREW',
		# hu    => 'HUNGARIAN',
		# it    => 'ITALIAN',
		# it_IT => 'ITALY',
		# ja    => 'JAPANESE',
		# ja_JP => 'JAPAN',
		# ko    => 'KOREAN',
		# ko_KR => 'KOREA',
		# nb    => 'NORWEGIAN BOKMAL',
		# nl    => 'DUTCH',
		# pl    => 'POLISH',
		# pt    => 'PORTUGUESE',
		# pt_BR => 'BRAZILIAN',
		# ru    => 'RUSSIAN',
		# tr    => 'TURKISH',
		# zh    => 'CHINESE',
		# zh_CN => 'SIMPLIFIED_CHINESE', # zh_CN => 'CHINA',

	# };

	# p $self->{dictionary_names};
	TRACE( "iso to dictionary names = " . Dumper $self->{dictionary_names} ) if DEBUG;
	
	my @local_dictionaries_names;

	for (@local_dictionaries) {
		push( @local_dictionaries_names, $self->padre_locale_label( $_ ) );
		$self->{dictionary_names}{$_} = $self->padre_locale_label( $_ );
		# p $self->padre_locale_label( $_ );
		# push( @local_dictionaries_names, $self->{dictionary_names}{$_} );
		

		# my $lc_local_dictionary = lc $_;
		# $lc_local_dictionary =~ s/_/-/;
		# p $lc_local_dictionary;
		# require Padre::Locale;
		# my $label = Padre::Locale::label( $lc_local_dictionary );
		# p $label;
		# push( @local_dictionaries_names, Padre::Locale::label( $lc_local_dictionary ) );
		# push( @local_dictionaries_names, $self->padre_locale_label( $_ ) );
		# push( @local_dictionaries_names, $self->{dictionary_names}{$_} . " ( $_ )" );
	}
	# p $self->{dictionary_names};
	# p @local_dictionaries_names;

	@local_dictionaries_names = sort @local_dictionaries_names;

	$self->{local_dictionaries_names} = \@local_dictionaries_names;

	# p $self->{local_dictionaries_names};
	TRACE( "local dictionaries names = " . Dumper $self->{local_dictionaries_names} ) if DEBUG;
	return;
}

#######
# Composed Method padre_local_label
# aspell to padre local label
#######
sub padre_locale_label {
	my $self = shift;
	my $local_dictionary = shift;
	my $lc_local_dictionary = lc $local_dictionary;
	$lc_local_dictionary =~ s/_/-/;
	# p $lc_local_dictionary;
	require Padre::Locale;
	my $label = Padre::Locale::label( $lc_local_dictionary );
	# p $label;
	return $label;
}


1;

__END__

=head1 DESCRIPTION

This module implements the dialog window that will be used to set the
spell check preferences.



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $dialog = P-P-S::Preferences->new( %params );

Create and return a new dialog window.


=back




=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.

=cut
