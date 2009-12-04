package Padre::Plugin::Catalyst::Panel;

use strict;
use warnings;

our $VERSION = '0.06';

use Padre::Wx ();
use Padre::Util ('_T');
use Wx ();
use base 'Wx::Panel';

sub new {
	my $class      = shift;
	my $main       = shift;
	my $self       = $class->SUPER::new( Padre::Current->main->bottom );
	my $box        = Wx::BoxSizer->new(Wx::wxVERTICAL);

    require Padre::Wx::Output;
    my $output = Padre::Wx::Output->new($self);
    
	$box->Add( $output, 2, Wx::wxGROW );

	$self->SetSizer($box);
	Padre::Current->main->bottom->show($self);

    return $output;
}

sub gettext_label {	return _T('Catalyst Dev Server') }


# dirty hack to allow seamless use of Padre::Wx::Output
sub bottom { return $_[0] }


1;

