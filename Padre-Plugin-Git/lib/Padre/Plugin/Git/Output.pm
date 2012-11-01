package Padre::Plugin::Git::Output;

use v5.10;
use strictures 1;

use Padre::Unload                            ();
use Padre::Plugin::Git::FBP::Output ();

our $VERSION = '0.06';
use parent qw(
	Padre::Plugin::Git::FBP::Output
	Padre::Plugin
);

#######
# Method new
#######
sub new {
	my $class = shift;
	my $main  = shift;
	my $title = shift || '';
	my $text  = shift || '';
	
	# Create the dialogue
	my $self = $class->SUPER::new($main);

	# define where to display main dialogue
	$self->CenterOnParent;
	$self->SetTitle( $title );
	$self->text->SetValue( $text );

	return $self;
}


1;

__END__

=pod

=head1 NAME

Padre::Plugin::Git::Output - Git plugin for Padre, The Perl IDE.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This module handles the Preferences dialogue window that is used to set your 
chosen Nopaste Server and #Channel.


=head1 METHODS

=over 4

=item * new

	$self->{dialog} = Padre::Plugin::Git::Output->new( $main, "Git $action -> $location", $git_cmd->{output} );


=back


=head1 BUGS AND LIMITATIONS

None known.

=head1 DEPENDENCIES

Padre, Padre::Plugin::Git::FBP::Output

=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::Git>.

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

