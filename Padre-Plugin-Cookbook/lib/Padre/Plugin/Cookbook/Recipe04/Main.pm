package Padre::Plugin::Cookbook::Recipe04::Main;

use 5.010;
use strict;
use warnings;
use diagnostics;
use utf8;
use autodie;

# Avoids regex performance penalty
use English qw( -no_match_vars );

use Padre::Wx             ();
use Padre::Wx::Role::Main ();

use version; our $VERSION = qv(0.22);

use Moose;
use namespace::autoclean;
extends qw( Padre::Plugin::Cookbook::Recipe04::FBP::MainFB );

# use Try::Tiny;
use Data::Printer;
use Carp;

sub BUILD {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	return $self;
}

my $item = Wx::ListItem->new;
my @tuples;
my $card_limit = 127;

has [qw/ relation_name config_db sql_select /] => (
	isa     => 'Str',
	is      => 'rw',
	default => undef,
	lazy    => 1,
);

has [qw/ cardinality degree previous_column /] => (
	isa     => 'Int',
	is      => 'rw',
	default => 0,
	lazy    => 1,
);

has [qw/ attributes /] => (
	isa => 'ArrayRef',
	is  => 'rw',
);

has [qw/ dialog_width /] => (
	isa     => 'Bool',
	is      => 'rw',
	default => '0',
);

#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	# add package name to main dialog #fails as min size naff
	my @pkg_name = split /::/smx, __PACKAGE__,;
	$self->package_name->SetLabel( $pkg_name[3] );

	$self->list_ctrl->InsertColumn( 0, Wx::gettext('index') );
	$self->list_ctrl->SetColumnWidth( 0, '50' );
	$self->list_ctrl->InsertColumn( 1, Wx::gettext('information') );
	$self->list_ctrl->SetColumnWidth( 1, '400' );

	## inserting the file in the list
	# my $item = Wx::ListItem->new;
	$item->SetId(0);
	$item->SetColumn(0);
	$item->SetText('0');
	my $idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 1, 'Pick a relation and click UPDATE' );

	$item->SetId(1);
	$item->SetBackgroundColour( Wx::Colour->new('MEDIUM SEA GREEN') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem(
		$idx, 1,
		'MEDIUM SEA GREEN for an old school look'
	);

	$item->SetId(2);
	$item->SetBackgroundColour( Wx::Colour->new('WHITE') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem(
		$idx, 1,
		'use SHOW to peek inside after Update; tip start with SyntaxHighlight'
	);

	$item->SetId(3);
	$item->SetBackgroundColour( Wx::Colour->new('MEDIUM SEA GREEN') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem(
		$idx, 1,
		'CLEAN works with History, Session & Session Files; Update first'
	);

	$item->SetId(4);
	$item->SetBackgroundColour( Wx::Colour->new('WHITE') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem(
		$idx, 1,
		'clicking on Session tuple displays children'
	);

	$item->SetId(5);
	$item->SetBackgroundColour( Wx::Colour->new('MEDIUM SEA GREEN') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1, 'COLUMN heading for sorting' );

	$item->SetId(6);
	$item->SetBackgroundColour( Wx::Colour->new('WHITE') );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1, 'Ajust Width is a toggle: have fun' );

	return;
}

#######
# Event Handler Button Update Clicked
#######
sub update_clicked {
	my $self = shift;
	my $main = $self->main;

	$self->clean->Disable;
	$self->show->Enable;
	$self->width_ajust->Enable;
	$main->info(' ');

	# get your selectd relation
	$self->relation_name( $self->relations->GetStringSelection() );

	# set padre db relation
	$self->config_db( 'Padre::DB::' . $self->relation_name );

	# get cardinality
	_get_cardinality($self);

	# get degree
	eval { $self->config_db->table_info; };
	if ($EVAL_ERROR) {
		say "Opps failed to get table info for $self->config_db ";
		carp($EVAL_ERROR);
	} else {
		$self->attributes( $self->config_db->table_info );
		$self->degree( scalar( @{ $self->attributes } ) );
	}

	# update dialog title
	$self->relation_title->SetLabel( $self->relation_name );
	$self->previous_column(0);
	$self->sql_select("ORDER BY ${@{ $self->attributes}[0]}{name} ASC LIMIT $card_limit");

	_display_relation($self);

	return;
}

#######
# Event Handler Button Show Clicked
#######
sub show_clicked {
	my $self = shift;

	_show_relation_data($self);

	return;
}

#######
# Event Handler Button Warning Clicked
#######
sub clean_clicked {
	my $self = shift;

	given ( $self->relation_name ) {
		when ('Session') {
			clean_session($self);
		}
		when ('SessionFile') {
			clean_session_files($self);
		}
		when ('History') {
			clean_history($self);
		}
		default {
			return;
		}
	}

	return;
}

########
# Event Handler Button Output Clicked
#######
sub width_ajust_clicked {
	my $self = shift;

	if ( !$self->dialog_width ) {

		# say 'wd: +';
		$self->SetSize( 1008, -1 );
		$self->dialog_width('1');
	} else {

		# say 'wd: -';
		$self->SetSize( 560, -1 );
		$self->dialog_width('0');
	}

	# $self->list_ctrl->Refresh();
	$self->list_ctrl->Update();

	return;
}

########
# Event Handler _on_list_item_activated (Session only)
#######
sub _on_list_item_activated {
	my ( $self, $list_element ) = @ARG;

	if ( $self->relation_name ne 'Session' ) {
		say 'quit';
		return;
	}

	my $session_id = $tuples[ $list_element->GetIndex ]['0'];
	say $tuples[ $list_element->GetIndex ]['1'];

	# redefine tuples
	my @tuples = Padre::DB::SessionFile->select("WHERE session = $session_id");

	for ( 0 .. ( @tuples - 1 ) ) {
		say $tuples[$_][1];
	}

	return;
}

########
# Event Handler _on_list_col_clicked
#######
sub _on_list_col_clicked {
	my ( $self, $list_event ) = @ARG;

	my $main = $self->main;
	my $sql_order;
	my $col_num;

	eval { $list_event->GetColumn };
	if ($EVAL_ERROR) {
		say 'column info';
		carp($EVAL_ERROR);
	} else {
		$col_num = $list_event->GetColumn();
		if ( $col_num eq '0' ) {
			say "I don't work on index";
			return;
		}
	}

	if ( $col_num ne $self->previous_column ) {
		$sql_order = 'ASC';
		$self->previous_column($col_num);
	} else {
		$sql_order = 'DESC';

		# RESET previous_column
		$self->previous_column(0);
	}

	eval { $main->info( 'sort on: ' . ${ @{ $self->attributes }[ $col_num - 1 ] }{name} . ' ' . $sql_order ); };

	$self->sql_select("ORDER BY ${ @{ $self->attributes }[ $col_num - 1 ] }{name} $sql_order LIMIT $card_limit");

	_display_relation($self);

	return;
}

########
# Composed Method,
# clean history
#######
sub clean_history {
	my $self = shift;
	my $main = $self->main;

	my @events = $self->config_db->select('ORDER BY name ASC');

	$main->info('Cleaning History relation');
	my $progressbar = _setup_progressbar($self);

	# say $self->cardinality;
	my $count = 0;
	for ( 0 .. ( @events - 2 ) ) {
		if ( $events[$_][1] . $events[$_][2] eq $events[ $_ + 1 ][1] . $events[ $_ + 1 ][2] ) {
			say $events[$_][1] . $events[$_][2];
			say $events[ $_ + 1 ][1] . $events[ $_ + 1 ][2];
			say "$count: $_: found duplicate id: $events[$_][0]";
			eval { $self->config_db->delete("WHERE id = \"$events[$_][0]\""); };
			if ($EVAL_ERROR) {
				say "Opps $self->config_db tuple $events[$_][0] is missing";
				carp($EVAL_ERROR);
			}
			$count++;
		}
		$progressbar->update( $_, "Cleaning $self->relation_name" );

		# get cardinality
		_get_cardinality($self);
	}

	$main->info('finished cleaning hisory');
	_display_relation($self);

	return;
}

########
# Composed Method,
# clean session
#######
sub clean_session {
	my $self = shift;
	my $main = $self->main;

	$main->info('Cleaning Session relation');
	for ( 0 .. ( @tuples - 1 ) ) {

		my @children = Padre::DB::SessionFile->select("WHERE session = $tuples[$_][0]");

		if ( @children eq 0 ) {
			say 'id :' . $tuples[$_][1] . ' empty, deleating';
			eval { $self->config_db->delete("WHERE id = $tuples[$_][0]"); };
			if ($EVAL_ERROR) {
				say "Opps $self->config_db is damaged";
				carp($EVAL_ERROR);
			}

			# get cardinality
			_get_cardinality($self);
		}
	}
	$main->info('Finished Cleaning Session relation');
	_display_relation($self);
	return;
}

########
# Composed Method,
# clean session files
#######
sub clean_session_files {
	my $self = shift;
	my $main = $self->main;

	$main->info('Cleaning Session_Files relation');
	my @session_files = $self->config_db->select( $self->sql_select );
	my @files;

	for ( 0 .. ( @session_files - 1 ) ) {
		push @files, $session_files[$_][1];
	}
	foreach (@files) {
		unless ( -e $_ ) {
			say 'warning warning';
			say $_;
			say 'warning warning';
			eval { $self->config_db->delete("WHERE file = \"$_\""); };
			if ($EVAL_ERROR) {
				say "Opps $self->config_db is damaged";
				carp($EVAL_ERROR);
			}

			# get cardinality
			_get_cardinality($self);
		}
	}

	$main->info('Finished Cleaning Session_Files');
	_display_relation($self);
	return;
}

########
# Composed Method,
# display any relation db
#######
sub _display_any_relation {
	my $self = shift;

	_display_attribute_names($self);

	eval { $self->config_db->select; };
	if ($EVAL_ERROR) {
		say "Opps $self->config_db is damaged";
		carp($EVAL_ERROR);
	} else {
		@tuples = $self->config_db->select( $self->sql_select );

		my $progressbar = _setup_progressbar($self);
		my $idx         = 0;
		my $ddx         = 0;

		foreach (@tuples) {
			$item->SetId($idx);
			if ( $idx % 2 ) {
				$item->SetBackgroundColour( Wx::Colour->new('MEDIUM SEA GREEN') );
			} else {
				$item->SetBackgroundColour( Wx::Colour->new('WHITE') );
			}

			# our display index
			$self->list_ctrl->InsertItem($item);
			$self->list_ctrl->SetItem( $idx, 0, $idx );

			for ( 0 .. ( $self->degree - 1 ) ) {
				$ddx = ( $_ + 1 );

				# test for attributes with {null} values
				if ( !defined( $tuples[$idx][$_] ) ) {
					say "Opps found a {null} in relation $self->{relation_name} ";
				} else {
					$self->list_ctrl->SetItem( $idx, $ddx, ( $tuples[$idx][$_] ) );
				}
				$progressbar->update(
					$idx,
					"Loading $self->relation_name tuples"
				);
			}
			$idx++;
			_tidy_display($self);
		}
	}
	return;
}

########
# Composed Method,
# display session data from db
#######
sub _display_session_db {
	my $self = shift;

	_display_attribute_names($self);

	eval { $self->config_db->select; };
	if ($EVAL_ERROR) {
		say "Opps $self->config_db is damaged";
		carp($EVAL_ERROR);
	} else {
		@tuples = $self->config_db->select( $self->sql_select );

		# TODO this is naff sortout
		my $progressbar = _setup_progressbar($self);
		my $idx         = 0;

		foreach (@tuples) {

			# p @{$self->tuples};
			$item->SetId($idx);

			if ( $idx % 2 ) {
				$item->SetBackgroundColour( Wx::Colour->new('MEDIUM SEA GREEN') );
			} else {
				$item->SetBackgroundColour( Wx::Colour->new('WHITE') );
			}
			$self->list_ctrl->InsertItem($item);
			$self->list_ctrl->SetItem( $idx, 0, $idx );
			$self->list_ctrl->SetItem( $idx, 1, $tuples[$idx][0] );
			$self->list_ctrl->SetItem( $idx, 2, $tuples[$idx][1] );
			$self->list_ctrl->SetItem( $idx, 3, $tuples[$idx][2] );

			my $update = POSIX::strftime(
				'%Y-%m-%d %H:%M:%S',
				localtime $tuples[$idx][3],
			);

			# p $tuples[$idx];
			# p( ${ @{ $self->attributes }[3] }{name} );

			$self->list_ctrl->SetItem( $idx, 4, $update );
			$progressbar->update(
				$idx,
				"Loading $self->relation_name tuples"
			);
			$idx++;
			_tidy_display($self);
		}
	}

	return;

}

########
# Composed Method,
# _display_attribute_names
#######
sub _display_attribute_names {
	my $self = shift;

	my $idx = 0;

	# clear ListCtrl
	$self->list_ctrl->ClearAll;

	# List the columns in the underlying table
	$self->list_ctrl->InsertColumn( $idx, Wx::gettext('index') );

	$idx++;

	foreach my $attribute ( @{ $self->attributes } ) {
		my $column_title;
		if ( $attribute->{pk} ) {
			$column_title = "$attribute->{name} $attribute->{type} *";
		} else {
			$column_title = "$attribute->{name} $attribute->{type}";
		}
		$self->list_ctrl->InsertColumn( $idx, Wx::gettext($column_title) );
		$self->list_ctrl->SetColumnWidth(
			$idx,
			Wx::wxLIST_AUTOSIZE_USEHEADER
		);
		$idx++;
	}
	return;
}

#######
# Composed Method
# _display_relation
#######
sub _display_relation {
	my $self = shift;

	given ( $self->relation_name ) {
		when ('History') {
			$self->clean->Enable;
			_display_any_relation( $self, $_ );
		}
		when ('Session') {
			$self->clean->Enable;
			_display_session_db( $self, $_ );
		}
		when ('SessionFile') {
			$self->clean->Enable;
			_display_any_relation( $self, $_ );
		}
		default {
			_display_any_relation( $self, $_ );
		}
	}
	return;
}

#######
# Composed Method
# _get_cardinality
#######
sub _get_cardinality {

	my $self = shift;
	eval { $self->config_db->count; };
	if ($EVAL_ERROR) {
		say "Opps failed to get cardinality for $self->config_db ";
		carp($EVAL_ERROR);
	} else {
		$self->cardinality( $self->config_db->count );
		$self->display_cardinality->SetLabel( "Cardinality: " . $self->cardinality );
	}

	return;
}
########
# Composed Method,
# _show_relation_data
#######
sub _show_relation_data {
	my $self = shift;

	my $info;

	eval { $self->config_db->table_info; };
	if ($EVAL_ERROR) {
		say "Opps no info for $self->config_db ";
		carp($EVAL_ERROR);
	} else {
		$info = $self->config_db->table_info;
		p @{$info};
	}

	eval { $self->config_db->select; };
	if ($EVAL_ERROR) {
		say "Opps $self->config_db is damaged";
		carp($EVAL_ERROR);
	} else {
		$info = $self->config_db->select;
		p @{$info};
	}

	# try { $self->config_db->select; }
	# catch {
	# say "Opps $self->config_db is damaged";
	# carp($_);
	# return;
	# }
	#
	# $info = $self->config_db->select;
	# p @$info;

	return;
}

########
# Composed Method,
# _tidy_display
#######
sub _tidy_display {
	my $self = shift;

	for ( 1 .. $self->degree ) {
		$self->list_ctrl->SetColumnWidth( $_, Wx::wxLIST_AUTOSIZE_USEHEADER );
		my $col_head_size = $self->list_ctrl->GetColumnWidth($_);

		# say "wxLIST_AUTOSIZE_USEHEADER  :" . $col_head_size;
		$self->list_ctrl->SetColumnWidth( $_, Wx::wxLIST_AUTOSIZE );
		my $col_data_size = $self->list_ctrl->GetColumnWidth($_);

		# say "wxLIST_AUTOSIZE :" . $col_data_size;
		if ( $col_head_size >= $col_data_size ) {
			$self->list_ctrl->SetColumnWidth( $_, $col_head_size );
		} else {
			$self->list_ctrl->SetColumnWidth( $_, $col_data_size );
		}
	}
	return;
}

########
# Composed Method,
# _setup_progressbar
#######
sub _setup_progressbar {
	my $self = shift;

	# Set modal to true to lock other application windows while the progress
	# box is displayed. Default is 0 (non-modal).
	#
	# Set lazy to true to show the progress dialog only if the whole process
	# takes long enough that the progress box makes sense. Default if 1 (lazy-mode).
	require Padre::Wx::Progress;
	my $progress = Padre::Wx::Progress->new(
		$self,
		$self->relation_name,
		$self->cardinality,
		modal => 0,
		lazy  => 1,
	);
	return $progress;
}

#######
# Event Handler Button About Clicked
#######
sub about_clicked {
	my $self = shift;

	load_dialog_about($self);
	return;
}

#######
# Clean up our Classes, Padre::Plugin, POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	require Class::Unload;
	$self->unload('Padre::Plugin::Cookbook::Recipe04::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');
	return 1;
}

########
# Composed Method,
# Load About Dialog, only once
#######
sub load_dialog_about {
	my $self = shift;
	my $main = $self->main;

	# Clean up any previous existing about
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new about
	require Padre::Plugin::Cookbook::Recipe04::About;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe04::About->new($main);
	$self->{dialog}->Show;

	return;
}

# dose not work with Wx, BP :(
# __PACKAGE__->meta->make_immutable();
no Moose;

1;

__END__

=head1 NAME

Padre::Plugin::Cookbook::Recipe04::Main

=head1 VERSION

This document describes Padre::Plugin::Cookbook::Recipe04::Main version 0.21

=head1 DESCRIPTION

Recipe04 - ConfigDB

Main is the event handler for MainFB, it's parent class.

It displays a Main dialog with an about button.
It's a basic example of a Padre plug-in using a WxDialog.

=head1 SUBROUTINES/METHODS

=over 4

=item new ()

Constructor. Should be called with $main by CookBook->load_dialog_main().

=item about_clicked

=item BUILD

=item clean_clicked

=item clean_history

=item clean_session

=item clean_session_files

=item load_dialog_about ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe04::About;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe04::About->new( $main );
    $self->{dialog}->Show;

=item plugin_disable ()

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Recipe04::About');
    $self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

=item set_up

=item show_clicked

=item update_clicked

=item width_ajust_clicked


=back

=head1 DEPENDENCIES

Padre::Plugin::Cookbook, Padre::Plugin::Cookbook::Recipe04::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe04::About, Padre::Plugin::Cookbook::Recipe0::FBP::AboutFB

=head1 AUTHOR

bowtie

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
