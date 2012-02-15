package Padre::Plugin::SpellCheck::Preferences;

# ABSTRACT: Preferences dialog for padre spell check

use warnings;
use strict;

use Padre::Logger;
use Padre::Wx                                   ();
use Padre::Wx::Role::Main                       ();
use Padre::Unload                               ();
use Padre::Plugin::SpellCheck::FBP::Preferences ();

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

	# this don't work
	# my $config = $self->get_config->{dictionary};
	# my $config = $self->config->{dictionary};
	# p $config;



	# my $prefered_dictionary = $self->get_config->{dictionary};
	# my $prefered_dictionary = 'en_GB';
	my $prefered_dictionary = $self->{_plugin}->config->{dictionary};


	# my $prefered_dictionary = $config->dictionary;
	TRACE("iso prefered_dictionary = $prefered_dictionary ") if DEBUG;

	# set local_dictionaries_index to zero incase prefered_dictionary not found
	my $local_dictionaries_index = 0;

	for ( 0 .. $#{ $self->{local_dictionaries_names} } ) {
		if ( $self->{local_dictionaries_names}->[$_] eq $self->{dictionary_names}->{$prefered_dictionary} ) {
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

	#TODO should use Padre::Config
	# my $config = Padre::Config->read;

	my $select_dictionary_name = $self->{local_dictionaries_names}->[ $self->language->GetSelection() ];
	TRACE("selected dictionary name = $select_dictionary_name ") if DEBUG;

	my $select_dictionary_iso;
	for my $iso ( keys %{ $self->{dictionary_names} } ) {

		if ( $self->{dictionary_names}->{$iso} eq $select_dictionary_name ) {
			$select_dictionary_iso = $iso;
		}
	}
	TRACE("selected dictionary iso = $select_dictionary_iso ") if DEBUG;

	#TODO sortout
	# my $config = Padre::Config->read;
	# $config->set( identity_nickname => $new_nick );
	# $config->write;

	# store plugin preferences
	$self->{_plugin}->config_write( { dictionary => $select_dictionary_iso, } );

	#

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
	$self->{dictionary_names} = {
		ar    => 'ARABIC',
		cs    => 'CZECH',
		de    => 'GERMAN',
		de_DE => 'GERMANY',
		en    => 'ENGLISH',
		en_AU => 'AUSTRALIA_ENGLISH',
		en_CA => 'CANADA_ENGLISH',
		en_GB => 'BRITISH_ENGLISH',    # en_GB => 'UK'
		en_US => 'AMERICAN_ENGLISH',   # en_US => 'US'
		es    => 'SPANISH',
		fr    => 'FRENCH',
		fr_FR => 'FRANCE',
		fr_CA => 'CANADA_FRENCH',
		he    => 'HEBREW',
		hu    => 'HUNGARIAN',
		it    => 'ITALIAN',
		it_IT => 'ITALY',
		ja    => 'JAPANESE',
		ja_JP => 'JAPAN',
		ko    => 'KOREAN',
		ko_KR => 'KOREA',
		nb    => 'NORWEGIAN BOKMAL',
		nl    => 'DUTCH',
		pl    => 'POLISH',
		pt    => 'PORTUGUESE',
		pt_BR => 'BRAZILIAN',
		ru    => 'RUSSIAN',
		tr    => 'TURKISH',
		zh    => 'CHINESE',
		zh_CN => 'SIMPLIFIED_CHINESE', # zh_CN => 'CHINA',

	};

	# p $self->{dictionary_names};
	TRACE( "iso to dictionary names = " . Dumper $self->{dictionary_names} ) if DEBUG;

	my @local_dictionaries_names;

	for (@local_dictionaries) {
		push( @local_dictionaries_names, $self->{dictionary_names}{$_} );

		# push( @local_dictionaries_names, $self->{dictionary_names}{$_} . " ( $_ )" );
	}

	# p @local_dictionaries_names;

	@local_dictionaries_names = sort @local_dictionaries_names;

	$self->{local_dictionaries_names} = \@local_dictionaries_names;

	# p $self->{local_dictionaries_names};
	TRACE( "local dictionaries names = " . Dumper $self->{local_dictionaries_names} ) if DEBUG;
	return;
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
