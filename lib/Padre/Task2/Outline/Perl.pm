package Padre::Task2::Outline::Perl;

=pod

=head1 NAME

Padre::Task2::Outline::Perl - Background task for generating Perl content structure

=head1 SYNOPSIS

  # By default the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Task::Outline::Perl->new;
  $task->schedule;
  
  my $task2 = Padre::Task2::Outline::Perl->new(
      text => Padre::Current->document->text_get
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements structure info gathering of Perl documents in
the background.

Also the updating of the GUI is implemented here, because other
languages might have different outline structures.

It inherits from L<Padre::Task::Outline>.

Please read its documentation!

=cut

use 5.008;
use strict;
use warnings;
use version;
use Padre::Current        ();
use Padre::Task2::Outline ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2::Outline';

sub run {
	my $self = shift;
	$self->_get_outline;
	return 1;
}

sub _get_outline {
	my $self    = shift;
	my $outline = [];

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Parse the document
	require PPI::Document;
	my $ppi = PPI::Document->new( \$text );
	return {} unless defined $ppi;
	$ppi->index_locations;

	# Execute the search
	require PPI::Find;
	my $find = PPI::Find->new(
		sub {
			return 1 if ref $_[0] eq 'PPI::Statement::Package';
			return 1 if ref $_[0] eq 'PPI::Statement::Include';
			return 1 if ref $_[0] eq 'PPI::Statement::Sub';
			return 1 if ref $_[0] eq 'PPI::Statement';
		}
	);

	my @things        = $find->in($ppi);
	my $cur_pkg       = {};
	my $not_first_one = 0;
	foreach my $thing (@things) {
		if ( ref $thing eq 'PPI::Statement::Package' ) {
			if ($not_first_one) {
				if ( not $cur_pkg->{name} ) {
					$cur_pkg->{name} = 'main';
				}
				push @$outline, $cur_pkg;
				$cur_pkg = {};
			}
			$not_first_one   = 1;
			$cur_pkg->{name} = $thing->namespace;
			$cur_pkg->{line} = $thing->location->[0];
		} elsif ( ref $thing eq 'PPI::Statement::Include' ) {
			next if $thing->type eq 'no';
			if ( $thing->pragma ) {
				push @{ $cur_pkg->{pragmata} }, { name => $thing->pragma, line => $thing->location->[0] };
			} elsif ( $thing->module ) {
				push @{ $cur_pkg->{modules} }, { name => $thing->module, line => $thing->location->[0] };
			}
		} elsif ( ref $thing eq 'PPI::Statement::Sub' ) {
			push @{ $cur_pkg->{methods} }, { name => $thing->name, line => $thing->location->[0] };
		} elsif ( ref $thing eq 'PPI::Statement' ) {

			# last resort, let's analyse further down...
			my $node1 = $thing->first_element;
			my $node2 = $thing->child(2);
			next unless defined $node2;

			# Moose attribute declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'has' ) {
				push @{ $cur_pkg->{attributes} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}

			# MooseX::POE event declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'event' ) {
				push @{ $cur_pkg->{events} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}
		}
	}

	if ( not $cur_pkg->{name} ) {
		$cur_pkg->{name} = 'main';
	}
	push @{$outline}, $cur_pkg;

	$self->{outline} = $outline;

	return;
}

sub update_gui {
	my $self     = shift;
	my $data     = $self->{outline};
	my $current  = Padre::Current->new;
	my $outline  = $current->main->outline;
	my $document = $current->document;
	my $filename = $current->filename;
	unless ( defined $filename ) {
		$filename = $document->get_title;
	}

	# Only update the outline pane if we still have the same filename
	if ( $self->{filename} eq $filename ) {
		$outline->update_data( $data, $self->{filename}, \&_on_tree_item_right_click );

		# Store data for further use by other components
		$document->set_outline_data($data);
	} else {
		$outline->store_in_cache( $self->{filename}, [ $data, \&_on_tree_item_right_click ] );
	}
}

sub _on_tree_item_right_click {
	my ( $outline, $event ) = @_;
	my $showMenu = 0;

	my $menu     = Wx::Menu->new;
	my $itemData = $outline->GetPlData( $event->GetItem );

	if ( defined($itemData) && defined( $itemData->{line} ) && $itemData->{line} > 0 ) {
		my $goTo = $menu->Append( -1, Wx::gettext('&Go to Element') );
		Wx::Event::EVT_MENU(
			$outline, $goTo,
			sub { $outline->on_tree_item_set_focus($event); },
		);
		$showMenu++;
	}

	if (   defined($itemData)
		&& defined( $itemData->{type} )
		&& ( $itemData->{type} eq 'modules' || $itemData->{type} eq 'pragmata' ) )
	{
		my $pod = $menu->Append( -1, Wx::gettext('Open &Documentation') );
		Wx::Event::EVT_MENU(
			$outline,
			$pod,
			sub {

				# TO DO Fix this wasting of objects (cf. Padre::Wx::Menu::Help)
				require Padre::Wx::DocBrowser;
				my $help = Padre::Wx::DocBrowser->new;
				$help->help( $itemData->{name} );
				$help->SetFocus;
				$help->Show(1);
				return;
			},
		);
		$showMenu++;
	}

	if ( $showMenu > 0 ) {
		my $x = $event->GetPoint->x;
		my $y = $event->GetPoint->y;
		$outline->PopupMenu( $menu, $x, $y );
	}
	return;
}

1;

__END__

=pod

=head1 SEE ALSO

This class inherits from L<Padre::Task2::Outline> which
in turn is a L<Padre::Task2> and its instances can be scheduled
using L<Padre::TaskManager2>.

=head1 AUTHOR

Heiko Jansen C<heiko_jansen@web.de>, Zeno Gantner

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
