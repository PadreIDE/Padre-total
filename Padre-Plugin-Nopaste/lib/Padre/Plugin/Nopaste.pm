#
# This file is part of Padre::Plugin::Nopaste.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::Nopaste;

use strict;
use warnings;

use File::Basename        qw{ fileparse };
use File::Spec::Functions qw{ catfile };
use Module::Util          qw{ find_installed };

#use Padre::Task;
#our @ISA     = qw{
#	Padre::Role::Task
#	Padre::Plugin
#};
use parent qw{ Padre::Plugin
Padre::Role::Task
}; #
#

our $VERSION = '0.3.0';


# -- padre plugin api, refer to Padre::Plugin

# plugin name
sub plugin_name { 'Nopaste' }

# plugin icon
sub plugin_icon {
    # find resource path
    my $pkgpath = find_installed(__PACKAGE__);
    my (undef, $dirname, undef) = fileparse($pkgpath);
    my $iconpath = catfile( $dirname,
        'Nopaste', 'share', 'icons', 'paste.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# padre interface
sub padre_interfaces {
    'Padre::Plugin' => 0.65,
    'Padre::Task'   => 0.65,
}

# plugin menu.
sub menu_plugins_simple {
    my ($self) = @_;
    'Nopaste' => [
        "Nopaste\tCtrl+Shift+V" => 'nopaste',  # launch thread, see Padre::Task
    ];
}

require Padre::Plugin::Nopaste::Task;
sub nopaste {
	#TRACE("nopaste") if DEBUG;
	my $self = shift;

	# Fire the task
	$self->task_request(
		task     => 'Padre::Plugin::Nopaste::Task',
		document => $self,
		callback => 'task_response',
	);

	return;
}

sub task_response {
	#TRACE("nopaste_response") if DEBUG;
	my $self = shift;
	my $task = shift;
	# Found what we were looking for
	if ( $task->{location} ) {
		#$self->ppi_select( $task->{location} );
		#return;
	}

	my $main = $self->current->main;

	# Generate the dump string and set into the output window
	$main->output->SetValue( $task->{message} );
	$main->output->SetSelection( 0, 0 );
	$main->show_output(1);

	# Must have been a clean result
	# TO DO: Convert this to a call to ->main that doesn't require
	# us to use Wx directly.
#	Wx::MessageBox(
#		$task->{message},
#		$task->{message},
#		Wx::wxOK,
#		$self->current->main,
#	);
}



# -- public methods


# -- private methods



1;
__END__

=head1 NAME

Padre::Plugin::Nopaste - send code on a nopaste website from padre



=head1 SYNOPSIS

    $ padre
    Ctrl+Shift+V



=head1 DESCRIPTION

This plugin allows one to send stuff from Padre to a nopaste website
with Ctrl+Shift+V, allowing for easy code / whatever sharing without
having to open a browser.

It is using C<App::Nopaste> underneath, so check this module's pod for
more information.


=head1 PUBLIC METHODS

=head2 Standard Padre::Plugin API

C<Padre::Plugin::Nopaste> defines a plugin which follows C<Padre::Plugin>
API. Refer to this module's documentation for more information.

The following methods are implemented:

=over 4

=item menu_plugins_simple()

=item padre_interfaces()

=item plugin_icon()

=item plugin_name()

=back



=head2 Standard Padre::Role::Task API

In order not to freeze Padre during web access, nopasting is done in a thread,
as implemented by C<Padre::Task>. Refer to this module's documentation for more
information.

The following methods are implemented:

=over 4

=item * nopaste()

=item * task_response()

Callback for task runned by nopaste().

=back



=head1 BUGS

Please report any bugs or feature requests to C<padre-plugin-nopaste at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Nopaste>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SEE ALSO

Plugin icon courtesy of Mark James, at
L<http://www.famfamfam.com/lab/icons/silk/>.

Our git repository is located at L<git://repo.or.cz/padre-plugin-nopaste.git>,
and can be browsed at L<http://repo.or.cz/w/padre-plugin-nopaste.git>.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Nopaste>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Nopaste>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Nopaste>

=back



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
