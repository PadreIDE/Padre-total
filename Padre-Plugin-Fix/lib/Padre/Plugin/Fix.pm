package Padre::Plugin::Fix;

use Modern::Perl;
use Padre::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Fix
};

# Called when Padre wants to check what package versions this
# plugin needs
sub padre_interfaces {
	'Padre::Plugin'               => 0.94,
		'Padre::Document'         => 0.94,
		'Padre::Wx::Main'         => 0.94,
		'Padre::Wx::Editor'       => 0.94,
		'Padre::Wx::Role::Main'   => 0.94,
		'Padre::Wx::Role::Dialog' => 0.94,
		;
}

# Called when Padre wants a name for the plugin
sub plugin_name {
	Wx::gettext('Fix');
}

#######
# Called by padre to build the menu in a simple way
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Simplify') => sub { $self->show_simplify },
		Wx::gettext('About')    => sub { $self->show_about },
	];
}

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName( Wx::gettext('Fix Plug-in') );
	my $authors     = 'Ahmad M. Zawawi';
	my $description = Wx::gettext( <<'END' );
Fix code support for Padre

Copyright 2012 %s
This plug-in is free software; you can redistribute it and/or modify it under the same terms as Padre.
END
	$about->SetDescription( sprintf( $description, $authors ) );

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

sub show_simplify {
	my $self = shift;

	my $editor = $self->current->editor or return;

	my $pos    = $editor->GetCurrentPos;
	my $source = $editor->GetText;

	# Pick an action
	my @actions = (
		Wx::gettext('Simplify quotes'),
		Wx::gettext('Remove null statements'),
	);
	my $action = $self->main->multi_choice(
		Wx::gettext('Choose Action'),
		Wx::gettext('Choose Action'),
		[ @actions ],
	);


	require PPI;
	my $doc = PPI::Document->new( \$source );

	my @changes = ();
	if ($action == 0) {
		$self->main->error("Please select an action");
		return;
	} 
	
	if ( $action == 1 ) {
		push @changes, @{$self->simplify_quotes($editor, $doc)};
	} else {
		$self->main->error("The following " . $actions[$action] . " is not currently supported");
	}

	if ( scalar @changes ) {
		require Padre::Plugin::Fix::Preview;
		my $preview = Padre::Plugin::Fix::Preview->new( $self->main );
		use Data::Printer; p(@changes);
		$preview->run( \@changes );
	} else {
		$self->main->error("No changes to fix");
	}

	return;
}

sub simplify_quotes {
	my $self   = shift;
	my $editor = shift;
	my $doc    = shift;

	my $quotes  = $doc->find('PPI::Token::Quote');
	my @changes = ();
	foreach my $quote (@$quotes) {
		my $line    = $quote->location->[0];
		my $col     = $quote->location->[1];
		my $content = $quote->content;

		# Try a simplify it (if possible)
		my $simplified_form;
		if ( $quote->can('simplify') ) {
			$simplified_form = $quote->simplify;
		}

		# Can be replaced by simpler thing?
		next
			unless ( defined $simplified_form
			and $simplified_form ne $content );

		my $start = $editor->PositionFromLine( $line - 1 ) + $col - 1;

		push @changes,
			{
			name  => Wx::gettext('Simplify quote'),
			start => $start,
			end   => $start + length($content),
			}

			# # Replace with simplified form
			# $editor->SetTargetStart($start);
			# $editor->SetTargetEnd( $start + length($content) );
			# $editor->ReplaceTarget($simplified_form);

			# # Restore current position
			# $editor->SetSelection( $pos, $pos );

	}

	return \@changes;
}

# Called when the plugin is enabled by Padre
sub plugin_enable {
	my $self = shift;

	# Read the plugin configuration, and
	my $config = $self->config_read;
	unless ( defined $config ) {

		# No configuration, let us create it
		$config = {};
	}

	#TOD some configuration defaults

	# Write the plugin's configuration
	$self->config_write($config);

	# Update configuration attribute
	$self->{config} = $config;

	return 1;
}

# Called when the plugin is disabled by Padre
sub plugin_disable {
	my $self = shift;

	# TODO: Switch to Padre::Unload once Padre 0.96 is released
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	return;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Fix - Provides Fix Code in Padre

=head1 SYNOPSIS

    cpan Padre::Plugin::Fix

Then use it via L<Padre>, The Perl IDE.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you will be fix code with Simplify
shortcut

=head1 BUGS

Please report any bugs or feature requests to
C<bug-padre-plugin-fix at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-Fix>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Padre::Plugin::Fix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Padre-Plugin-Fix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Padre-Plugin-Fix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Padre-Plugin-Fix>

=item * Search CPAN

L<http://search.cpan.org/dist/Padre-Plugin-Fix/>

=back

=head1 SEE ALSO

L<Padre>, L<PPI>

=head1 AUTHORS

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ahmad M. Zawawi

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
