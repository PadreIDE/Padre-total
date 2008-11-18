package Padre::Plugin::Devel;

use strict;
use warnings;

our $VERSION = '0.17';

use Padre::Wx ();

use Wx         ':everything';
use Wx::Menu   ();
use Wx::Locale qw(:default);

use File::Basename ();
use File::Spec     ();
use Data::Dumper   ();
use Padre::Util    ();

sub menu_name { 'Development Tools' }

# TODO fix this
# we need to create anonymous subs in order to makes
# sure reloading the module changes the call as well
# A better to replace the whole Plugins/ menu when we
# reload plugins.
my @menu = (
	['Show %INC',      sub {show_inc(@_)}       ],
	['Info',           sub {info(@_)}           ],
	['About',          sub {about(@_)}          ],
);

sub menu {
    my ($self) = @_;
	return @menu;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Devel");
	$about->SetDescription(
		"A set of unrelated tools used by the Padre developers\n" .
		"Some of these might end up in core Padre or in oter plugins"
	);
	#$about->SetVersion($Padre::VERSION);
	Wx::AboutBox( $about );
	return;
}

sub info {
	my ($main) = @_;
	my $doc = Padre::Documents->current;
	if (not $doc) {
		$main->message( 'No file is open', 'Info' );

		return;
	}
	my $msg = '';
	$msg   .= "Doc: $doc\n";
	$main->message( $msg, 'Info' );

	return;
}

sub show_inc {
	my ($main) = @_;

	Wx::MessageBox( Data::Dumper::Dumper(\%INC), '%INC', Wx::wxOK|Wx::wxCENTRE, $main );
	
}

1;

__END__

=head1 NAME

Padre::Plugin::Development::Tools - tools used by the Padre developers

=head1 DESCRIPTION

=head2 Show %INC

Dumper %INC

=head2 Info

=head2 About

=head1 AUTHOR

Gabor Szabo

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
