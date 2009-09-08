package Padre::Plugin::Perl6::Perl6OutlineTask;

use strict;
use warnings;

our $VERSION = '0.59';

use base 'Padre::Task::Outline';

=pod

=head1 NAME

Padre::Plugin::Perl6::Perl6OutlineTask - Perl6 document outline structure info 
gathering in the background

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Plugin::Perl6::Perl6OutlineTask->new;
  $task->schedule;
  
  my $task2 = Padre::Plugin::Perl6::Perl6OutlineTask->new(
	text          => Padre::Current->document->text_get,
	editor        => Padre::Current->editor,
  );
  $task2->schedule;

=head1 DESCRIPTION

This class implements structure info gathering of Perl6 documents in
the background.
Also the updating of the GUI is implemented here, because other 
languages might have different outline structures.
It inherits from L<Padre::Task::Outline>.
Please read its documentation!

=cut

sub run {
	my $self = shift;
	$self->_get_outline;
	return 1;
}

sub _get_outline {
	my $self = shift;

	my $outline = [];

	if ( $self->{tokens} ) {
		my $cur_pkg        = {};
		my @tokens         = @{ $self->{tokens} };
		my $symbol_type    = 'package';
		my $symbol_name    = '';
		my $symbol_line    = -1;
		my $symbol_suffix  = '';
		my $symbol_context = '';
		my $context        = 'GLOBAL';
		for my $htoken (@tokens) {
			my %token = %{$htoken};
			my $tree  = $token{tree};
			if ($tree) {
				my $buffer = $token{buffer};
				my $lineno = $token{lineno};
				if ( $tree
					=~ /package_declarator__S_\d+(class|grammar|module|package|role|knowhow|slang) package_def.+def_module_name/
					)
				{

					# (classes, grammars, modules, packages, roles) or main are always parent nodes
					$symbol_type = $1;
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree
					=~ /(package_declarator__S_\d+require module_name)|(statement_control__S_\d+use module_name)/ )
				{

					# require/use a module
					$symbol_type = "modules";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__S_\d+sub routine_def deflongname/ ) {

					# a subroutine
					$symbol_type = "subroutines";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+method method_def (longname|$)/ ) {

					# a method
					if ( $buffer eq '!' ) {

						# private method...
						$symbol_suffix = " (private)";
					} elsif ( $buffer eq '^' ) {

						# class or .HOW method
						$symbol_suffix = " (class)";
					}
					$symbol_type = "methods";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+submethod method_def longname/ ) {

					# a submethod
					$symbol_type = "submethods";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+macro macro_def deflongname/ ) {

					# a macro
					$symbol_type = "macros";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /regex_declarator__\w+_\d+(regex|token|rule) regex_def deflongname/ ) {

					# a regex, token or rule declaration
					$symbol_type = "regexes";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree
					=~ /scope_declarator__\w+_\d+(our|my|has|state|constant) scoped declarator variable_declarator variable/
					)
				{

					# a start for an attribute declaration
					$symbol_type = "attributes";
					$symbol_name .= $buffer;
					$symbol_line   = $lineno;
					$symbol_suffix = $1;
				} else {
					if ( $symbol_name ne '' ) {
						if (   $symbol_type eq 'class'
							|| $symbol_type eq 'grammar'
							|| $symbol_type eq 'module'
							|| $symbol_type eq 'package'
							|| $symbol_type eq 'role'
							|| $symbol_type eq 'knowhow'
							|| $symbol_type eq 'slang' )
						{
							$context = $symbol_name;
							if ( not $cur_pkg->{name} ) {
								$cur_pkg->{name} = 'GLOBAL';
							}
							push @{$outline}, $cur_pkg;
							$cur_pkg         = {};
							$cur_pkg->{name} = $symbol_name . " ($symbol_type)";
							$cur_pkg->{line} = $symbol_line;
						} else {
							if ( $symbol_type eq 'attributes' ) {
								if ( $symbol_name !~ /\./ ) {
									$symbol_suffix = " (private, $symbol_suffix)";
								} else {
									$symbol_suffix = " ($symbol_suffix)";
								}
							}
							$symbol_name .= $symbol_suffix;
							push @{ $cur_pkg->{$symbol_type} },
								{
								name => $symbol_name,
								line => $symbol_line,
								};
						}
						$symbol_type   = '';
						$symbol_name   = '';
						$symbol_line   = -1;
						$symbol_suffix = '';
					}
				}
			}
		}

		if ( not $cur_pkg->{name} ) {
			$cur_pkg->{name} = 'GLOBAL';
		}
		push @{$outline}, $cur_pkg;

	}

	$self->{outline} = $outline;
	return;
}

sub update_gui {
	my $self         = shift;
	my $last_outline = shift;
	my $outline      = $self->{outline};
	my $outlinebar   = Padre->ide->wx->main->outline;
	my $editor       = $self->{main_thread_only}->{editor};

	$outlinebar->Freeze;
	$outlinebar->clear;

	require Padre::Wx;

	# If there is no structure, clear the outline pane and return.
	unless ($outline) {
		return;
	}

	# Again, slightly differently
	unless (@$outline) {
		return 1;
	}

	# Add the hidden unused root
	my $root = $outlinebar->AddRoot(
		Wx::gettext('Outline'),
		-1,
		-1,
		Wx::TreeItemData->new('')
	);

	# Update the outline pane
	_update_treectrl( $outlinebar, $outline, $root );

	# Set Perl6 specific event handler
	Wx::Event::EVT_TREE_ITEM_RIGHT_CLICK(
		$outlinebar,
		$outlinebar,
		\&_on_tree_item_right_click,
	);

	$outlinebar->GetBestSize;

	$outlinebar->Thaw;
	return 1;
}

sub _on_tree_item_right_click {
	my ( $outlinebar, $event ) = @_;
	my $showMenu = 0;

	my $menu     = Wx::Menu->new;
	my $itemData = $outlinebar->GetPlData( $event->GetItem );

	if (   defined($itemData)
		&& defined( $itemData->{type} )
		&& $itemData->{type} eq 'modules' )
	{
		my $pod = $menu->Append( -1, Wx::gettext("Open &Documentation") );
		Wx::Event::EVT_MENU(
			$outlinebar,
			$pod,
			sub {
				Padre->ide->wx->main->help( $itemData->{name} );
			},
		);
		$showMenu++;
	}

	if ( $showMenu > 0 ) {
		my $x = $event->GetPoint->x;
		my $y = $event->GetPoint->y;
		$outlinebar->PopupMenu( $menu, $x, $y );
	}
	return;
}

sub _update_treectrl {
	my ( $outlinebar, $outline, $root ) = @_;

	foreach my $pkg ( @{$outline} ) {
		my $branch = $outlinebar->AppendItem(
			$root,
			$pkg->{name},
			-1, -1,
			Wx::TreeItemData->new(
				{   line => $pkg->{line},
					name => $pkg->{name},
					type => 'package',
				}
			)
		);
		foreach my $type (qw(modules attributes subroutines methods submethods macros regexes)) {
			_add_subtree( $outlinebar, $pkg, $type, $branch );
		}
		$outlinebar->Expand($branch);
	}

	return;
}

sub _add_subtree {
	my ( $outlinebar, $pkg, $type, $root ) = @_;

	my $type_elem = undef;
	if ( defined( $pkg->{$type} ) && scalar( @{ $pkg->{$type} } ) > 0 ) {
		$type_elem = $outlinebar->AppendItem(
			$root,
			ucfirst($type),
			-1,
			-1,
			Wx::TreeItemData->new()
		);

		my @sorted_entries = ();
		if (   $type eq 'subroutines'
			|| $type eq 'methods'
			|| $type eq 'submethods'
			|| $type eq 'macros'
			|| $type eq 'attributes' )
		{
			my $config = Padre->ide->config;
			if ( $config->main_functions_order eq 'original' ) {

				# That should be the one we got
				@sorted_entries = @{ $pkg->{$type} };
			} elsif ( $config->main_functions_order eq 'alphabetical_private_last' ) {

				# ~ comes after \w
				my @pre = map { $_->{name} =~ s/^_/~/; $_ } @{ $pkg->{$type} };
				@pre = sort { $a->{name} cmp $b->{name} } @pre;
				@sorted_entries = map { $_->{name} =~ s/^~/_/; $_ } @pre;
			} else {

				# Alphabetical (aka 'abc')
				@sorted_entries = sort { $a->{name} cmp $b->{name} } @{ $pkg->{$type} };
			}
		} else {
			@sorted_entries = sort { $a->{name} cmp $b->{name} } @{ $pkg->{$type} };
		}

		foreach my $item (@sorted_entries) {
			$outlinebar->AppendItem(
				$type_elem,
				$item->{name},
				-1, -1,
				Wx::TreeItemData->new(
					{   line => $item->{line},
						name => $item->{name},
						type => $type,
					}
				)
			);
		}
	}
	if ( defined $type_elem ) {
		if (   $type eq 'subroutines'
			|| $type eq 'methods'
			|| $type eq 'submethods'
			|| $type eq 'macros'
			|| $type eq 'regexes'
			|| $type eq 'attributes' )
		{
			$outlinebar->Expand($type_elem);
		} else {
			$outlinebar->Collapse($type_elem);
		}
	}

	return;
}

1;

__END__

=head1 SEE ALSO

This class inherits from L<Padre::Task::Outline> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
