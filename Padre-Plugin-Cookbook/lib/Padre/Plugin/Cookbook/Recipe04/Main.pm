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

use version; our $VERSION = qv(0.21);

# use parent qw( Padre::Plugin::Cookbook::Recipe04::FBP::MainFB );

use Moose;
use namespace::autoclean;
extends qw( Padre::Plugin::Cookbook::Recipe04::FBP::MainFB );
use Data::Dumper;
use Data::Printer;
use Carp;

#sub new {
sub BUILD {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);

	return $self;
}

my $item = Wx::ListItem->new;

has [qw/ relation_name config_db sql_select /] => ( isa     => 'Str',
													is      => 'rw',
													default => undef,
													lazy    => 1,
);

has [qw/ cardinality degree previous_column /] => ( isa     => 'Int',
													is      => 'rw',
													default => 0,
													lazy    => 1,
);

has [qw/ attributes tuples /] => ( isa => 'ArrayRef',
								   is  => 'rw', );

has [qw/ dialog_width /] => ( isa     => 'Bool',
							  is      => 'rw',
							  default => '0',
);

#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	# add package name to main dialog #fails as min size naff
	my @pkg_name = split /::/x, __PACKAGE__,;
	$self->package_name->SetLabel( $pkg_name[3] );

	$self->list_ctrl->InsertColumn( 0, Wx::gettext('index') );
	$self->list_ctrl->SetColumnWidth( 0, 50 );
	$self->list_ctrl->InsertColumn( 1, Wx::gettext('information') );
	$self->list_ctrl->SetColumnWidth( 1, 400 );

	## inserting the file in the list
	my $item = Wx::ListItem->new;
	$item->SetId(0);
	$item->SetColumn(0);
	$item->SetText('0');
	my $idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 1, 'Pick a relation and click UPDATE' );

	$item->SetId(1);
	$item->SetBackgroundColour( Wx::Colour->new("MEDIUM SEA GREEN") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1,
							   'MEDIUM SEA GREEN for an old school look' );

	$item->SetId(2);
	$item->SetBackgroundColour( Wx::Colour->new("WHITE") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem(
		$idx,
		1,
		'use SHOW to peek inside after Update; tip start with SyntaxHighlight'
	);

	$item->SetId(3);
	$item->SetBackgroundColour( Wx::Colour->new("CORAL") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1, 'CORAL highlight warnnings' );

	$item->SetId(4);
	$item->SetBackgroundColour( Wx::Colour->new("WHITE") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1,
					  'WARNING only works with Session Files; Update first' );

	$item->SetId(5);
	$item->SetBackgroundColour( Wx::Colour->new("MEDIUM SEA GREEN") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1, 'Ajust Width is a toggle: have fun' );

	$item->SetId(6);
	$item->SetBackgroundColour( Wx::Colour->new("WHITE") );
	$idx = $self->list_ctrl->InsertItem($item);
	$self->list_ctrl->SetItem( $idx, 0, $idx );
	$self->list_ctrl->SetItem( $idx, 1, '#TODO WARNING, improve sort' );

	return;
}

#######
# Event Handler Button Update Clicked
#######
sub update_clicked {
	my $self = shift;

	$self->warning->Disable;
	$self->show->Enable;
	$self->width_ajust->Enable;

	# get your selectd relation
	$self->relation_name( $self->relations->GetStringSelection() );

	# set padre db relation
	$self->config_db( "Padre::DB::" . $self->relation_name );

	# get cardinality
	eval { $self->config_db->count; };
	if ($EVAL_ERROR) {
		say "Opps failed to get cardinality for $self->config_db ";
		carp($EVAL_ERROR);
	}
	else {
		$self->cardinality( $self->config_db->count );
	}

	# get degree
	eval { $self->config_db->table_info; };
	if ($EVAL_ERROR) {
		say "Opps failed to get table info for $self->config_db ";
		carp($EVAL_ERROR);
	}
	else {
		$self->attributes( $self->config_db->table_info );
		$self->degree( scalar( @{ $self->attributes } ) );
	}

	# update dialog title
	$self->relation_title->SetLabel( $self->relation_name );
	$self->previous_column(0);
	$self->sql_select("ORDER BY ${@{ $self->attributes}[0]}{name} ASC");

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
sub warning_clicked {
	my $self = shift;

	say "warning warning";

	return;
}

########
# Event Handler Button Output Clicked
#######
sub width_ajust_clicked {
	my $self = shift;

	if ( !$self->dialog_width ) {
		say "wd: +";
		$self->SetSize( 1008, -1 );
		$self->dialog_width('1');
	}
	else {
		say "wd: -";
		$self->SetSize( 560, -1 );
		$self->dialog_width('0');
	}

	# $self->list_ctrl->Refresh();
	$self->list_ctrl->Update();

	return;
}

########
# Event Handler on_list_col_clicked
#######
sub on_list_col_clicked {
	my ( $self, $list_event ) = @ARG;

	my $sql_order;
	my $col_num;

	eval { $list_event->GetColumn };
	if ($EVAL_ERROR) {
		say "column info";
		carp($EVAL_ERROR);
	}
	else {
		$col_num = $list_event->GetColumn();
		if ( $col_num eq 0 ) {
			say "I don't work on index";
			return;
		}
	}

	say "col_num: ".$col_num;

	if ( $col_num ne $self->previous_column ) {
		$sql_order = 'ASC';
		$self->previous_column($col_num);
	}
	else {
		$sql_order = 'DESC';
		# RESET previous_column
		$self->previous_column( 0 );
	}
	
	### test code

	eval { say "0: " . @{ $self->attributes }; };

	# p @{ $self->attributes };

	eval { say "1: " . @{ $self->attributes }[$col_num]; };

	# p @{ $self->attributes}[$col_num];

	eval { say "2: " . ${ @{ $self->attributes }[ $col_num - 1 ] }{name}; };
	p ${ @{ $self->attributes }[ $col_num - 1 ] }{name};

# my $sql_att_name = %{@{ $self->attributes}->[$col_num-1]}->{name};
#$self->config_db->select("ORDER BY ${@{ $self->attributes}[$col_num-1]}{name}");#DESC");

	### end test code

	$self->sql_select(
			"ORDER BY ${ @{ $self->attributes }[ $col_num - 1 ] }{name} $sql_order");

	_display_relation($self);

	return;
}

########
# Composed Method,
# display any relation db
#######
sub _display_any_relation {
	my $self = shift;

	my @tuples;

	_display_attribute_names($self);

	eval { $self->config_db->select; };
	if ($EVAL_ERROR) {
		say "Opps $self->config_db is damaged";
		carp($EVAL_ERROR);
	}
	else {
		@tuples = $self->config_db->select( $self->sql_select );

		# TODO this is naff sortout
		my $progressbar = _setup_progressbar($self);

		my $idx = 0;

		foreach (@tuples) {

			$item->SetId($idx);

			if ( $idx % 2 ) {
				$item->SetBackgroundColour(
										Wx::Colour->new("MEDIUM SEA GREEN") );
			}
			else {
				$item->SetBackgroundColour( Wx::Colour->new("WHITE") );
			}

			# our display index
			$self->list_ctrl->InsertItem($item);
			$self->list_ctrl->SetItem( $idx, 0, $idx );

			for ( 1 .. $self->degree ) {
				$self->list_ctrl->SetItem( $idx, $_,
										   $tuples[$idx][ ( $_ - 1 ) ] );
			}
			$progressbar->update( $idx,
								  "Loading $self->relation_name tuples" );
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

	my @PDbList = $self->config_db->select;

	_display_attribute_names($self);

	my $idx = 0;

	foreach (@PDbList) {

		$item->SetId($idx);

		if ( $idx % 2 ) {
			$item->SetBackgroundColour( Wx::Colour->new("MEDIUM SEA GREEN") );
		}
		else {
			$item->SetBackgroundColour( Wx::Colour->new("WHITE") );
		}
		$self->list_ctrl->InsertItem($item);
		$self->list_ctrl->SetItem( $idx, 0, $idx );
		$self->list_ctrl->SetItem( $idx, 1, $PDbList[$idx][0] );
		$self->list_ctrl->SetItem( $idx, 2, $PDbList[$idx][1] );
		$self->list_ctrl->SetItem( $idx, 3, $PDbList[$idx][2] );

		# todo fix
		# require POSIX;
		my $update = POSIX::strftime( '%Y-%m-%d %H:%M:%S',
									  localtime $PDbList[$idx][3], );

		$self->list_ctrl->SetItem( $idx, 4, $update );
		$idx++;
		_tidy_display($self);
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
		}
		else {
			$column_title = "$attribute->{name} $attribute->{type}";
		}
		$self->list_ctrl->InsertColumn( $idx, Wx::gettext($column_title) );
		$self->list_ctrl->SetColumnWidth( $idx,
										  Wx::wxLIST_AUTOSIZE_USEHEADER );
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
		when ("SessionFile") {
			$self->warning->Enable;
			_display_any_relation( $self, $_ );
		}
		when ("Session") {
			_display_session_db( $self, $_ );
		}
		default {
			_display_any_relation( $self, $_ );
		}
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
	}
	else {
		$info = $self->config_db->table_info;
		p @$info;
	}

	eval { $self->config_db->select; };
	if ($EVAL_ERROR) {
		say "Opps $self->config_db is damaged";
		carp($EVAL_ERROR);
	}
	else {
		$info = $self->config_db->select;
		p @$info;
	}

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
		}
		else {
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
	my $progress =
		Padre::Wx::Progress->new( $self,
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
