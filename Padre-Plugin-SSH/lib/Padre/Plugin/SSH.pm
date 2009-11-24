package Padre::Plugin::SSH;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();

use base 'Padre::Plugin';

our $ProtocolRegex = qr/^ssh:\/\//;
our $ProtocolHandlerClass = 'Padre::Plugin::SSH::File';


=head1 NAME

Padre::Plugin::SSH - Padre support for SSH remote files

=head1 SYNOPSIS

TODO

=cut

sub padre_interfaces {
	return(
		'Padre::Plugin' => 0.41,
		'Padre::File'   => 0.50, # lie until 0.51 is released
	);
}

sub plugin_name {
	'SSH';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
	];
}

sub plugin_enable {
	my $self = shift;
	require Padre::File;
	require Padre::Plugin::SSH::File;
	Padre::File->RegisterProtocol($ProtocolRegex, $ProtocolHandlerClass);
	return 1;
}

sub plugin_disable {
	my $self = shift;
	Padre::File->DropProtocol($ProtocolRegex, $ProtocolHandlerClass);
	return 1;
}



1;

# Copyright 2009 Steffen Mueller.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

__END__

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

