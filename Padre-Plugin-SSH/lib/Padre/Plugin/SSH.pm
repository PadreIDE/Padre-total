package Padre::Plugin::SSH;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.02';

# use Padre::Wx ();
# use Padre::File;

use parent qw(
	Padre::Plugin
);


our $ProtocolRegex        = qr/^ssh:\/\//;
our $ProtocolHandlerClass = 'Padre::Plugin::SSH::File';



#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		'Padre::Plugin' => '0.96',
		'Padre::File'   => '0.96', # lie until 0.51 is released
		'Padre::Util'   => '0.97',
		'Padre::Wx'     => '0.96'
	);
}

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::SSH
	Padre::Plugin::SSH::File
};

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('SSH');
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->plugin_about },
	];
}

#########
# We need plugin_enable
# as we have an external dependency autodia
#########
sub plugin_enable {
	my $self = shift;
	require Padre::File;
	require Padre::Plugin::SSH::File;
	Padre::File->RegisterProtocol( $ProtocolRegex, $ProtocolHandlerClass );
	return 1;
}

# sub plugin_disable {
	# my $self = shift;
	# Padre::File->DropProtocol( $ProtocolRegex, $ProtocolHandlerClass );
	# return 1;
# }
########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;
	
	Padre::File->DropProtocol( $ProtocolRegex, $ProtocolHandlerClass );
	# Close the dialog if it is hanging around
	# $self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

#######
# plugin_about
#######
sub plugin_about {
	my $self = shift;

	# my $share = $self->plugin_directory_share or return;
	# my $file = File::Spec->catfile( $share, 'icons', '48x48', 'dia.png' );
	# return unless -f $file;
	# return unless -r $file;

	my $info = Wx::AboutDialogInfo->new;

	# $info->SetIcon( Wx::Icon->new( $file, Wx::wxBITMAP_TYPE_PNG ) );
	$info->SetName('Padre::Plugin::SSH');
	$info->SetVersion($VERSION);    
	# $info->SetDescription( Wx::gettext('Generate UML Class documentation for Dia') );
    $info->SetCopyright( '(c) 2008-2012 The Padre development team' );
    $info->SetWebSite('http://padre.perlide.org/');
    $info->AddDeveloper( 'Steffen Mueller <smueller@cpan.org>' );	
    $info->AddDeveloper('Kevin Dawson <bowtie@cpan.org>');
    # $info->AddDeveloper( 'Aaron Trevena <teejay@cpan.org>' );
	# $info->SetArtists(
		# [   'Scott Chacon <https://github.com/github/gitscm-next>',
			# 'Licence <http://creativecommons.org/licenses/by/3.0/>'
		# ]
	# );
	Wx::AboutBox($info);
	return;
}

1;



__END__


=pod

=head1 NAME

Padre::Plugin::SSH - Padre support for SSH remote files

=head1 SYNOPSIS

TODO

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>


=head2 CONTRIBUTORS

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2009 Steffen Mueller.
Copyright E<copy> 2008-2012 The Padre development team as listed in Padre.pm in the
Padre distribution all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2009 Steffen Mueller.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.