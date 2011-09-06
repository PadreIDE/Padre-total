package Padre::Plugin::PerlTidy::Dialog;

use strict;
use warnings;
use File::Temp        ();
use Padre::Wx::Dialog ();
use Perl::Tidy;

my %conf = (
	'add-newlines'           => 'checkbox',
	'add-semicolons'         => 'checkbox',
	'add-whitespace'         => 'checkbox',
	'blanks-before-blocks'   => 'checkbox',
	'blanks-before-comments' => 'checkbox',
	'blanks-before-subs'     => 'checkbox',
	'maximum-line-length'    => 'free',
	'space-for-semicolon'    => 'checkbox',
);

sub new {
	my $class = shift;
	my $self  = bless {}, $class;
	my $layout = get_view_layout();
	my $dialog = dialog($layout);
	$dialog->Show(1);
	return $self;
}

sub get_view_layout {

	# %option_range from Perl::Tidy could be use to show the parameters in a better way

	my ($roption_string,   $rdefaults, $rexpansion,
		$roption_category, $roption_range
	) = Perl::Tidy::generate_options();

	#print Data::Dumper::Dumper $roption_range;
	# This code generates a 3 column table of all the parameters
	# but probably it is better to group them together based on their meaning
	# than showing them in abc order
	# based on Perl-Tidy-20101217/examples/perltidyrc_dump.pl
	my $stderr     = ""; # try to capture error messages
	my $argv       = ""; # do not let perltidy see our @ARGV
	                     # we are going to make two calls to perltidy...
	                     # first with an empty .perltidyrc to get the default parameters
	my $empty_file = ""; # this will be our .perltidyrc file
	my %defaults;        # this will receive the default options hash
	my %abbreviations_default;
	Perl::Tidy::perltidy(
		perltidyrc         => \$empty_file,
		dump_options       => \%defaults,
		dump_options_type  => 'full',                 # 'full' gives everything
		dump_abbreviations => \%abbreviations_default,
		stderr             => \$stderr,
		argv               => \$argv,
	);

	my @layout;

	sub _dd {
		my $name = shift;
		if ( not exists $conf{$name} ) {
			warn "Unknown option '$name'";
			return;
		}
		if ( $conf{$name} eq 'free' ) {
			my $current_value = '';
			return (
				[ 'Wx::StaticText', undef, $name ],
				[ 'Wx::TextCtrl',   $name, $current_value ]
			);
		}
		if ( $conf{$name} eq 'checkbox' ) {
			return ( [ 'Wx::CheckBox', $name, $name, 0 ], [] );
		}
		if ( ref $conf{$name} and 'ARRAY' eq ref $conf{$name} ) {
			return (
				[ 'Wx::StaticText', undef, $name ],
				[ 'Wx::Choice',     $name, $conf{$name} ],
			);
		}
		warn "Could not handle option '$name'";
		return;
	}

	push @layout,
		(
		[ _dd('maximum-line-length'),    _dd('space-for-semicolon') ],
		[ _dd('add-newlines'),           _dd('add-semicolons') ],
		[ _dd('add-whitespace'),         _dd('blanks-before-blocks') ],
		[ _dd('blanks-before-comments'), _dd('blanks-before-subs') ],
		);

	push @layout,
		(
		[   [ 'Wx::Button', '_tidy_all_',       'Tidy all' ],
			[ 'Wx::Button', '_tidy_selection_', 'Tidy selection' ],
			[ 'Wx::Button', '_cancel_',         Wx::wxID_CANCEL ],
		],
		);
	return \@layout;
}

sub dialog {
	my $layout = shift;
	my $main   = Padre->ide->wx->main;
	my $config = Padre->ide->config;
	my $dialog = Padre::Wx::Dialog->new(
		parent => $main,
		title  => Wx::gettext('Create New Component'),
		layout => $layout,
		width  => [ 200, 200, 200 ],
		bottom => 20,
	);

	Wx::Event::EVT_BUTTON(
		$dialog, $dialog->{_widgets_}->{_tidy_all_},
		\&tidy_all
	);
	Wx::Event::EVT_BUTTON(
		$dialog,
		$dialog->{_widgets_}->{_tidy_selection_},
		\&tidy_selection
	);
	Wx::Event::EVT_BUTTON(
		$dialog, $dialog->{_widgets_}->{_cancel_},
		\&cancel_clicked
	);

	return $dialog;
}

sub tidy_all {
	my ( $dialog, $event ) = @_;
	my $data = $dialog->get_widgets_values;

	my $dir        = File::Temp::tempdir( CLEANUP => 1 );
	my $perltidyrc = "$dir/perltidy";
	my $opts       = '';
	foreach my $key ( keys %conf ) {
		next if not exists $data->{$key};
		next if not defined $data->{$key};
		if ( $conf{$key} eq 'checkbox' ) {
			$opts .= "--$key" if $data->{$key};
		} else {
			$opts .= "--$key=$data->{$key}\n";
		}
	}
	warn "Options: $opts";
	my $main = Padre->ide->wx->main;

	if ( open my $fh, '>', $perltidyrc ) {
		print $fh $opts;
		close $fh;
		Padre::Plugin::PerlTidy::tidy_document( $main, $perltidyrc );
	} else {
		warn "Could not create temporary rc file for perltidy ($perltidyrc) $!";
	}
}

sub tidy_selection {
}

sub cancel_clicked {
	my $dialog = shift;
	$dialog->Destroy;
	return;
}

# TODO: open dialog window with configuration options
# have buttons or menu items for
# "load rc file" and "load project rc file"
# "save rc file" and "save project rc file"
# lots of checkboxes and other fields for every option of Perltidy
# with explanation which one does what
# option to tidy immediately upon click of option (or when Tidy button is clicked

1;
