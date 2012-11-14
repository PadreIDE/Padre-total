package Padre::Plugin::Autodia;

# ABSTRACT: Autodia UML creator plugin for Padre
use v5.10;

use strict;
use warnings;
our $VERSION = '0.02';

use Padre::Wx       ();
use Padre::Constant ();
use Padre::Current  ();
use Try::Tiny;

use Cwd;
use Autodia;
use GraphViz;

use File::Find qw(find);
use File::Spec;

use parent qw(
	Padre::Plugin
	Padre::Role::Task
);

use Data::Printer {
	caller_info => 1,
	colored     => 1,
};





#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('Autodia UML Support');
}

#########
# We need plugin_enable
# as we have an external dependency autodia
#########
sub plugin_enable {
	my $self           = shift;
	my $autodia_exists = 0;

	try {
		if ( File::Which::which('dia') ) {
			$autodia_exists = 1;
		}
	};

	return $autodia_exists;
}

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin' => '0.96',
		'Padre::Task'   => '0.96',
		'Padre::Unload' => '0.96',
		'Padre::Util'   => '0.97',
		'Padre::Wx'     => '0.96',
	);
}

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Autodia
	Padre::Plugin::Autodia::Task::Autodia_cmd
};

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About') => sub {
			$self->show_about;
		},
		Wx::gettext('UML jpg') => [
			Wx::gettext('Class Diagram (Current File jpg)') => sub {
				$self->draw_this_file;
			},
			Wx::gettext('Class Diagram (select file jpg)') => sub {
				$self->draw_all_files;
			},
		],
		Wx::gettext('UML dia') => [
			Wx::gettext('Project Class Diagram (jpg)') => sub {
				$self->project_jpg;
			},
			Wx::gettext('Project Class Diagram (dia)') => sub {
				$self->project_dia;
			},
		],
	];
}

my @files_found = ();

# http://docs.wxwidgets.org/stable/wx_wxfiledialog.html
my $orig_wildcards = join(
	'|',
	Wx::gettext("JavaScript Files"),
	"*.js;*.JS",
	Wx::gettext("Perl Files"),
	"*.pm;*.PM;*.pl;*.PL",
	Wx::gettext("PHP Files"),
	"*.php;*.php5;*.PHP",
	Wx::gettext("Python Files"),
	"*.py;*.PY",
	Wx::gettext("Ruby Files"),
	"*.rb;*.RB",
	Wx::gettext("SQL Files"),
	"*.slq;*.SQL",
	Wx::gettext("Text Files"),
	"*.txt;*.TXT;*.yml;*.conf;*.ini;*.INI",
	Wx::gettext("Web Files"),
	"*.html;*.HTML;*.htm;*.HTM;*.css;*.CSS",
);

# get language and wildcard
my $languages = {
	Javascript => [qw/.js .JS/],
	Perl       => [qw/.pm .PM .pl .PL .t/],
	PHP        => [qw/.php .php3 .php4 .php5 .PHP/],
};

my $wildcards = join(
	'|',
	map { sprintf( Wx::gettext("%s Files"), $_ ) => join( ';', map ( "*$_", @{ $languages->{$_} } ) ) }
		sort keys %$languages
);

$wildcards .= (Padre::Constant::WIN32) ? Wx::gettext("All Files") . "|*.*|" : Wx::gettext("All Files") . "|*|";


sub draw_this_file {
	my $self = shift;

	my $document = $self->current->document or return;

	my $filename = $document->filename || $document->tempfile;

	my $outfile = "${filename}.draw_this_file.jpg";

	( my $language = lc( $document->mimetype ) ) =~ s|application/[x\-]*||;

	my $autodia_handler =
		$self->_get_handler( { filenames => [$filename], outfile => $outfile, graphviz => 1, language => $language } );

	my $processed_files = $autodia_handler->process();

	$autodia_handler->output();

	Padre::Wx::launch_browser("file://$outfile");

	return;
}

sub draw_all_files {
	my $self = shift;

	my $directory = Cwd::getcwd();

	# show dialog, get files
	my $dialog = Wx::FileDialog->new(
		Padre->ide->wx->main, Wx::gettext('Open File'),
		$directory, '', $wildcards, Wx::wxFD_MULTIPLE,
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}

	$directory = $dialog->GetDirectory;
	my @filenames = map {"$directory/$_"} $dialog->GetFilenames;
	p @filenames;

	# get language for first file
	my $language = 'perl';
	foreach my $this_language ( keys %$languages ) {
		if ( grep { $filenames[0] =~ m/$_$/ } @{ $languages->{$this_language} } ) {
			$language = lc($this_language);
			last;
		}
	}

	# run autodia on files
	my $outfile = Cwd::getcwd() . "/padre.draw_these_files.jpg";
	my $autodia_handler =
		$self->_get_handler( { filenames => \@filenames, outfile => $outfile, graphviz => 1, language => $language } );

	my $processed_files = $autodia_handler->process();
	$autodia_handler->output();

	# display generated output in browser
	Padre::Wx::launch_browser("file://$outfile");

	return;
}

sub _get_handler {
	my $self = shift;
	my $args = shift;

	my $config = {
		language => $args->{language}, graphviz => $args->{graphviz} || 0,
		use_stdout => 0, filenames => $args->{filenames}
	};
	$config->{templatefile} = $args->{template} || undef;
	$config->{outputfile}   = $args->{outfile}  || "autodia-plugin.out";

	# unless ($language_handlers) {
	my $language_handlers = Autodia->getHandlers();

	# }
	my $handler_module = $language_handlers->{ lc( $args->{language} ) };
	eval "require $handler_module" or die "can't run '$handler_module' : $@\n";
	my $handler = "$handler_module"->new($config);
	p $handler;
	return $handler;
}

sub show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Padre::Plugin::Autodia');
	$about->SetDescription( Wx::gettext('Integrating automated documentation into Padre IDE') );
	$about->SetVersion($Padre::Plugin::Autodia::VERSION);
	$about->SetCopyright( Wx::gettext('Copyright 2010') . ' Aaron Trevena' );

	# Only Unix/GTK native about box supports websites
	if (Padre::Constant::UNIX) {
		$about->SetWebSite('http://padre.perlide.org/');
	}

	$about->AddDeveloper('Aaron Trevena: teejay at cpan dot org');

	Wx::AboutBox($about);
	return;
}

sub class_dia {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	# $document->filename
}

sub project_jpg {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	my $action   = shift;
	my $location = shift;


	my @directories_to_search = File::Spec->catfile( $document->project_dir, 'lib' );
	find( \&project_files, @directories_to_search );
	p @files_found;
	my @filenames = @files_found;

	# get language for first file
	my $language = 'perl';

	say 'Project ' . __PACKAGE__;
	p $document->project_dir;
	$document->project_dir =~ /\W(?<project>\w+)$/;
	p $+{project};


	# run autodia on files
	# my $outfile = Cwd::getcwd() . "/padre.draw_these_files.jpg";
	# my $outfile = File::Spec->catfile( $document->project_dir, 'padre.draw_this.jpg' );

	my $outfile = File::Spec->catfile( $document->project_dir, "$+{project}.jpg" );
	p $outfile;

	require Padre::Plugin::Autodia::Task::Autodia_cmd;

	# # Fire the task
	$self->task_request(
		task        => 'Padre::Plugin::Autodia::Task::Autodia_cmd',
		action      => 'autodia.pl -d lib -r -z ',
		outfile     => $outfile,
		language    => $language,
		project_dir => $document->project_dir,
		on_finish   => 'on_finish',
	);


	# display generated output in browser
	# Padre::Wx::launch_browser("file://$outfile");

	say 'done';


	return;

	# $document->project_dir
}

sub project_dia {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	my $action   = shift;
	my $location = shift;


	my @directories_to_search = File::Spec->catfile( $document->project_dir, 'lib' );
	find( \&project_files, @directories_to_search );
	p @files_found;
	my @filenames = @files_found;

	# get language for first file
	my $language = 'perl';

	say 'Project ' . __PACKAGE__;
	p $document->project_dir;
	$document->project_dir =~ /\W(?<project>\w+)$/;
	p $+{project};


	# run autodia on files
	# my $outfile = Cwd::getcwd() . "/padre.draw_these_files.jpg";
	# my $outfile = File::Spec->catfile( $document->project_dir, 'padre.draw_this.jpg' );

	my $outfile = File::Spec->catfile( $document->project_dir, "$+{project}.dia" );
	p $outfile;

	require Padre::Plugin::Autodia::Task::Autodia_cmd;

	# # Fire the task
	$self->task_request(
		task        => 'Padre::Plugin::Autodia::Task::Autodia_cmd',
		action      => 'autodia.pl -d lib -r ',
		outfile     => $outfile,
		language    => $language,
		project_dir => $document->project_dir,
		on_finish   => 'on_finish',
	);

	say 'done';

	return;
}

sub project_files {
	my $self = shift;

	my $file = $File::Find::name;
	return if $file =~ /\.[svn|git]/;
	return if $file !~ /\.p[lm]$/;

	push @files_found, $file;

	return;
}


#######
# on compleation of task do this
#######
sub on_finish {
	my $self   = shift;
	my $task   = shift;
	my $main   = $self->main;
	my $output = $main->output;

	# p $task->{outfile};


	$main->show_output(1);
	$output->clear;
	$output->AppendText( $task->{output} );
	$output->AppendText( "Ouput written to -> $task->{outfile}" );


	given ( $task->{outfile} ) {
		when (/.jpg$/) { Padre::Wx::launch_browser("file://$task->{outfile}") }
		when (/.dia$/) { system "dia", $task->{outfile} }
	}


	# p $task;
	# p $task->{output};
	# p $task->{error};

	return;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

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

1;

__END__

=pod

=head1 DESCRIPTION

Note: Before installing this plugin, you need to install L<GraphViz>
(C<apt-get install graphviz> or get a binary from http://www.graphviz.org/).

Padre plugin to integrate Autodia.

Provides an Autodia menu under 'plugins' with options to create UML diagrams for the current or selected files.

=head1 METHODS

=head2 plugin_name

=head2 padre_interfaces

Declare the Padre interfaces this plugin uses

=head2 menu_plugins_simple

The command structure to show in the Plugins menu

=head2 show_about

show 'about' dialog

=head2 draw_this_file

parse and diagram this file, displaying the UML Chart in a new window

=head2 draw_all_files

parse and diagram selected files from dialog, displaying the UML Chart in a new window

=head1 SEE ALSO

L<Autodia>, L<GraphViz>, L<Padre>

=head1 CREDITS

Development sponsered by Connected-uk

=cut
