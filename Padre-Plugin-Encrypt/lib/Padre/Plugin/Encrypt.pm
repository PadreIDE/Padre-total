package Padre::Plugin::Encrypt;

# ABSTRACT: Encrypt/decrypt files in Padre

use warnings;
use strict;

our $VERSION = '0.12';

use Padre::Wx::Dialog ();
use base 'Padre::Plugin';

#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Encrypt <-> Decrypt');
}

sub padre_interfaces {
	return (
		'Padre::Plugin'   => '0.91',
		'Padre::Wx'       => '0.91',
		'Padre::Wx::Main' => '0.91',
	);
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		Wx::gettext('Encrypt <-> Decrypt') => [
			Wx::gettext('Encrypt'), sub { $self->dencrypt('encrypt') },
			Wx::gettext('Decrypt'), sub { $self->dencrypt('decrypt') },
		]
	);
}

sub get_layout {
	my ($type) = @_;

	my @types = ( 'encrypt', 'decrypt' );
	my @layout = (
		[   [ 'Wx::StaticText', undef, 'Type:' ],
			[ 'Wx::ComboBox', '_type_', $type, \@types ],
		],
		[   [ 'Wx::StaticText', undef,           'Private key:' ],
			[ 'Wx::TextCtrl',   '_private_key_', '' ],
		],
		[   [ 'Wx::Button', '_ok_',     Wx::wxID_OK ],
			[ 'Wx::Button', '_cancel_', Wx::wxID_CANCEL ],
		],
	);
	return \@layout;
}

sub dencrypt {
	my ( $self, $type ) = @_;

	my $main = $self->main;

	my $layout = get_layout($type);
	my $dialog = Padre::Wx::Dialog->new(
		parent => $main,
		title  => lcfirst $type,
		layout => $layout,
		width  => [ 100, 100 ],
	);

	$dialog->{_widgets_}{_ok_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_ok_},     \&ok_clicked );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, \&cancel_clicked );
	$dialog->{_widgets_}{_private_key_}->SetFocus;

	$dialog->Show(1);
}

sub cancel_clicked {
	my ( $dialog, $event ) = @_;

	$dialog->Destroy;

	return;
}

sub ok_clicked {
	my ( $dialog, $event ) = @_;

	my $main = Padre->ide->wx->main;

	my $data = $dialog->get_data;
	$dialog->Destroy;

	my $private_key = $data->{_private_key_};
	unless ( length($private_key) ) {
		$main->message( Wx::gettext("Private key is required") );
		return;
	}

	my $type = $data->{_type_};

	my $doc = $main->current->document;
	return unless $doc;
	my $code = $doc->text_get;

	require Crypt::CBC;
	my $cipher = Crypt::CBC->new(
		-key    => $private_key,
		-cipher => 'Blowfish'
	);

	eval {
		if ( $type eq 'encrypt' )
		{

			# Encrypt
			$code = $cipher->encrypt_hex($code);
		} else {

			# Decrypt
			$code = $cipher->decrypt_hex($code);

			# Handle various text encodings properly
			require Padre::Locale;
			my $encoding = Padre::Locale::encoding_from_string($code);
			$code = Encode::decode( $encoding, $code );
		}
		$doc->text_set($code);
	};
	if ($@) {
		$main->error( Wx::gettext("Error while encrypting/decrypting:") . "\n" . $@ );
	}

}

1;
__END__

=head1 SYNOPSIS

	$>padre
	Plugins -> Encrypt ->
						  Encrypt
						  Decrypt

=head1 DESCRIPTION

Encrypt/Decrypt by L<Crypt::CBC>
