package Padre::Plugin::Perl6;

use 5.010;
use strict;
use warnings;
use Carp;
use Padre::Wx   ();
use base 'Padre::Plugin';

# exports and version
our $VERSION   = '0.54';
our @EXPORT_OK = qw(plugin_config);

# constants for html exporting
my $FULL_HTML    = 'full_html';
my $SIMPLE_HTML  = 'simple_html';
my $SNIPPET_HTML = 'snippet_html';

use Class::XSAccessor accessors => {
	config         => 'config',           # plugin configuration object
};

# static field to contain reference to current plugin configuration
my $config;

sub plugin_config {
	return $config;
}

# private subroutine to return the current share directory location
sub _sharedir {
	return Cwd::realpath(
		File::Spec->join(File::Basename::dirname(__FILE__),'Perl6/share')
	);
}

# Returns the plugin name to Padre
sub plugin_name {
	return Wx::gettext("Perl 6");
}

# directory where to find the translations
sub plugin_locale_directory {
	return File::Spec->catdir( _sharedir(), 'locale' );
}

sub padre_interfaces {
	'Padre::Plugin' => 0.41,
}

# plugin icon
sub plugin_icon {
	# find resource path
	my $iconpath = File::Spec->catfile( _sharedir(), 'icons', 'camelia.png');

	# create and return icon
	return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# called when the plugin is enabled
sub plugin_enable {
	my $self = shift;

	# Read the plugin configuration, and create it if it is not there
	$config = $self->config_read;
	if(not $config) {
		# no configuration, let us write some defaults
		$config = {};
	}
	
	# make sure defaults are respected if they are undefined.
	if(not defined $config->{colorizer}) {
		$config->{colorizer} = 'STD';
	}
	if(not defined $config->{p6_highlight}) {
		$config->{p6_highlight} = 1;
	}

	# and write the plugin's configuration
	$self->config_write($config);

	# update configuration attribute
	$self->config( $config );
	
	return 1;
}

sub menu_plugins {
	my $self = shift;
	my $main = shift;

	# plugin menu
	$self->{menu} = Wx::Menu->new;

	# New Perl 6... menu
	my $file_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Create Perl 6..."), $file_menu),
		sub {},
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Script"), ),
		sub { $self->_create_from_template('p6_script','p6') },
	);	
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Class"), ),
		sub { $self->_create_from_template('p6_class','p6') },
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Grammar"), ),
		sub { $self->_create_from_template('p6_grammar', 'p6') },
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Package"), ),
		sub { $self->_create_from_template('p6_package', 'p6') },
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Module"), ),
		sub { $self->_create_from_template('p6_module', 'p6') },
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Role"), ),
		sub { $self->_create_from_template('p6_role', 'p6') },
	);
	Wx::Event::EVT_MENU(
		$main,
		$file_menu->Append( -1, Wx::gettext("Inlined in Perl 5"), ),
		sub { $self->_create_from_template('p6_inline_in_p5', 'p5') },
	);

	# Refactor sub menu
	my $refactor_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Refactor..."), $refactor_menu),
		sub {  },
	);

	# Find variable declaration
	Wx::Event::EVT_MENU(
		$main,
		$refactor_menu->Append( -1, Wx::gettext("Find variable declaration"), ),
		sub { 
			Wx::MessageBox(
				Wx::gettext('Perl 6 refactoring support is coming soon...'),
				Wx::gettext('Error'),
				Wx::wxOK,
				$main, 
			);
		},
	);
	
	# Rename variable
	Wx::Event::EVT_MENU(
		$main,
		$refactor_menu->Append( -1, Wx::gettext("Rename variable"), ),
		sub { 
			Wx::MessageBox(
				Wx::gettext('Perl 6 refactoring support is coming soon...'),
				Wx::gettext('Error'),
				Wx::wxOK,
				$main, 
			);
		},
	);

	# Rakudo sub menu
	my $rakudo_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Rakudo"), $rakudo_menu),
		sub {},
	);
	# Generate Perl 6 Executable
	Wx::Event::EVT_MENU(
		$main,
		$rakudo_menu->Append( -1, Wx::gettext("Perl 6 Executable"), ),
		sub { $self->generate_p6_exe; },
	);

	# Generate Perl 6 PIR
	Wx::Event::EVT_MENU(
		$main,
		$rakudo_menu->Append( -1, Wx::gettext("Perl 6 PIR"), ),
		sub { $self->generate_p6_pir; },
	);

	# Export sub menu
	my $export_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Export..."), $export_menu),
		sub {},
	);
	# Export into HTML
	Wx::Event::EVT_MENU(
		$main,
		$export_menu->Append( -1, Wx::gettext("Full html"), ),
		sub { $self->export_html($FULL_HTML); },
	);
	Wx::Event::EVT_MENU(
		$main,
		$export_menu->Append( -1, Wx::gettext("Simple html"), ),
		sub { $self->export_html($SIMPLE_HTML); },
	);
	Wx::Event::EVT_MENU(
		$main,
		$export_menu->Append( -1, Wx::gettext("Snippet html"), ),
		sub { $self->export_html($SNIPPET_HTML); },
	);

	$self->{menu}->AppendSeparator;

	# Perl6 grok-based Help dialog doc reader
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Perl 6 Help\tF2"), ),
		sub { $self->show_perl6_doc; },
	);

	# More Help? sub menu
	my $more_help_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("More Help?"), $more_help_menu),
		sub { },
	);

	# Goto #padre link
	Wx::Event::EVT_MENU(
		$main,
		$more_help_menu->Append( -1, Wx::gettext("#padre for Padre Help"), ),
		sub { Wx::LaunchDefaultBrowser("http://padre.perlide.org/irc.html?channel=padre" ); },
	);

	# Goto #perl6 link
	Wx::Event::EVT_MENU(
		$main,
		$more_help_menu->Append( -1, Wx::gettext("#perl6 for Perl 6 Help"), ),
		sub { Wx::LaunchDefaultBrowser("http://padre.perlide.org/irc.html?channel=perl6" ); },
	);

	# Perl 6 projects link
	Wx::Event::EVT_MENU(
		$main,
		$more_help_menu->Append( -1, Wx::gettext("Perl 6 Projects"), ),
		sub { Wx::LaunchDefaultBrowser("http://perl6-projects.org" ); },
	);

	$self->{menu}->AppendSeparator;

	# Maintenance
	my $maintenance_menu = Wx::Menu->new();
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Maintenance"), $maintenance_menu),
		sub { Wx::LaunchDefaultBrowser("http://padre.perlide.org/irc.html?channel=padre" ); },
	);

	# Cleanup STD.pm lex cache
	Wx::Event::EVT_MENU(
		$main,
		$maintenance_menu->Append( -1, Wx::gettext("Cleanup STD.pm Lex Cache"), ),
		sub { $self->cleanup_std_lex_cache; },
	);

	# Preferences
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("Preferences"), ),
		sub { $self->show_preferences; },
	);

	# the famous about menu item...
	Wx::Event::EVT_MENU(
		$main,
		$self->{menu}->Append( -1, Wx::gettext("About"), ),
		sub { $self->show_about },
	);

	# Return our plugin with its label
	return ( $self->plugin_name => $self->{menu} );
}

sub registered_documents {
	'application/x-perl6' => 'Padre::Plugin::Perl6::Perl6Document',
}

sub provided_highlighters { 
	return (
		['Padre::Plugin::Perl6::Perl6StdColorizer', 'STD.pm', 'Larry Wall\'s Perl 6 reference grammar'],
#		['Padre::Plugin::Perl6::Perl6PgeColorizer', 'PGE/Rakudo', 'Parrot Grammar Engine via Rakudo Perl 6'],
	);
}

sub highlighting_mime_types {
	return (
		'Padre::Plugin::Perl6::Perl6StdColorizer' => ['application/x-perl6'],
#		'Padre::Plugin::Perl6::Perl6PgeColorizer' => ['application/x-perl6'],
	);
}

# create a Perl 6 file from the template
sub _create_from_template {
	my ( $self, $template, $extension ) = @_;
	
	$self->main->on_new;
	
	my $editor = $self->current->editor or return;
	my $file   = File::Spec->catdir( _sharedir(), "templates/$template.$extension" );
	$editor->insert_from_file($file);

	my $document = $editor->{Document};
	my $mime_type = ($extension eq 'p6') ? 
		'application/x-perl6' : 'application/x-perl'; 
	$document->set_mimetype( $mime_type );
	$document->editor->padre_setup;
	$document->rebless;

	return;
}

sub show_preferences {
	my $self = shift;
	
	require Padre::Plugin::Perl6::Preferences;
	my $prefs  = Padre::Plugin::Perl6::Preferences->new($self);
	$prefs->Show;
}

sub show_about {
	my $main = shift;

	require Syntax::Highlight::Perl6;
	require App::Grok;
	
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Perl6");
	$about->SetDescription(
		Wx::gettext("This plugin enables useful Perl 6 features on Padre IDE.") . "\n" .
		Wx::gettext("It integrates coloring and easy access to Perl 6 help documents.") . "\n\n" .
		Wx::gettext("The following modules are used:") . "\n" .
		"Syntax::Highlight::Perl6 " . $Syntax::Highlight::Perl6::VERSION . "\n" .
		"App::Grok " . $App::Grok::VERSION . "\n"
	);
	$about->SetVersion($VERSION);

	# create and return the camelia icon
	my $camelia_path = File::Spec->catfile( _sharedir(), 'icons', 'camelia-big.png');
	my $camelia_bmp = Wx::Bitmap->new( $camelia_path, Wx::wxBITMAP_TYPE_PNG );
	my $camelia_icon = Wx::Icon->new();
	$camelia_icon->CopyFromBitmap($camelia_bmp);
	$about->SetIcon($camelia_icon);
	
	Wx::AboutBox( $about );
	return;
}

#
# Cleans up STD lex cache after confirming with the user
#
sub cleanup_std_lex_cache {
	my $self = shift;

	my $main   = $self->main;

	my $tmp_dir = File::Spec->catfile( 
		Padre::Constant::PLUGIN_DIR, 
		'Padre-Plugin-Perl6' );
	my $LEX_STD_DIR = "$tmp_dir/lex/STD";
	if(not -d $LEX_STD_DIR) {
		Wx::MessageBox(
			Wx::gettext("Cannot find STD.pm lex cache"),
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}


	#find files in lex cache along with its total size;
	use File::Find;
	our @files_to_delete = ();
	my $lex_cache_size = 0;
	find(sub {
		my $file = $_;
		if(-f $file) {
			$lex_cache_size += -s $file;
			push @files_to_delete, $File::Find::name;
		 }
	}, $LEX_STD_DIR);
	$lex_cache_size = sprintf("%0.3f", $lex_cache_size / (1024 * 1024));

	# ask the user if he/she wants to open it in the default browser
	my $num_files_to_delete = scalar @files_to_delete;
	if($num_files_to_delete > 0) {
		my $ret = Wx::MessageBox(
			"STD.pm lex cache has $num_files_to_delete file(s) and $lex_cache_size MB.\n" .
			"Do you want to clean it up now?",
			"Confirmation",
			Wx::wxYES_NO|Wx::wxCENTRE,
			$main,
		);
		if ( $ret == Wx::wxYES ) {
			#clean it up...
			my $deleted_count = unlink @files_to_delete;
			Wx::MessageBox(
				"STD.pm lex cache should be clean now.\n" .
				"Deleted $deleted_count out of $num_files_to_delete file(s).",
				'Information',
				Wx::wxOK,
				$main,
			);
		}
	} else {
		Wx::MessageBox(
			'STD.pm lex cache is already clean.',
			'Information',
			Wx::wxOK,
			$main,
		);
	}

	return;
}

sub show_perl6_doc {
	my $self = shift;

	# find the word under the current cursor position
	my $topic = '';
	my $doc = $self->current->document;
	if($doc && $doc->get_mimetype eq q{application/x-perl6}) {
		# make sure it is a Perl6 document
		my $editor = $doc->editor;
		$topic = $editor->GetSelectedText;
		if (not $topic) {
			my $lineno = $editor->GetCurrentLine();
			my $line = $editor->GetLine($lineno);
			my $current_pos = $editor->GetCurrentPos() - $editor->PositionFromLine($lineno);
			my $current_word = '';
			while( $line =~ m/\G.*?(\S+)/g ) {
				if(pos($line) >= $current_pos) {
					$current_word = $1;
					last;
				}
			}
			if($current_word =~ /^.*?(\S+)/) {
				$topic = $1;
			}
		}
	}

	require Padre::Plugin::Perl6::Perl6HelpDialog;
	my $dialog = Padre::Plugin::Perl6::Perl6HelpDialog->new($self, topic => $topic);
	$dialog->ShowModal();

}

sub highlight {
	my $self = shift;
	my $doc = Padre::Current->document or return;

	if ($doc->can('colorize')) {
		my $text = $doc->text_get;
		$doc->{_text} = $text;
		$doc->{force_p6_highlight} = 1;
		$doc->colorize;
		$doc->{force_p6_highlight} = 0;
	}
}

sub text_with_one_nl {
	my $self = shift;
	my $doc = shift;
	my $text = $doc->text_get // '';

	my $nlchar = "\n";
	if ( $doc->get_newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	}
	elsif ( $doc->get_newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}
	$text =~ s/$nlchar/\n/g;
	return $text;
}

sub export_html {
	my ($self, $type) = @_;

	my $main = $self->main;

	my $doc = $main->current->document;
	if(not defined $doc) {
		Wx::MessageBox( Wx::gettext('No document'), Wx::gettext('Error'), Wx::wxOK, $main, );
		return;
	}
	
	if($doc->get_mimetype ne q{application/x-perl6}) {
		Wx::MessageBox(
			Wx::gettext('Not a Perl 6 file'),
			Wx::gettext('Operation cancelled'),
			Wx::wxOK,
			$main,
		);
		return;
	}

	my $text = $self->text_with_one_nl($doc);

	require File::Temp;
	my $tmp_in = File::Temp->new( SUFFIX => '.p6_in.txt' );
	binmode( $tmp_in, ":utf8" );
	print $tmp_in $text;
	close $tmp_in or warn "cannot close $tmp_in\n";
	
	my $tmp_out = File::Temp->new( SUFFIX => '.p6_out.txt' );
	binmode( $tmp_out, ":utf8" );
	close $tmp_out or warn "cannot close $tmp_out\n";;

	my $tmp_err = File::Temp->new( SUFFIX => '.p6_err.txt' );
	binmode( $tmp_err, ":utf8" );
	close $tmp_err or warn "cannot close $tmp_err\n";;

	# construct the command
	require File::Which;
	my $hilitep6 = File::Which::which('hilitep6');
	my @cmd = (
		$hilitep6,
		$tmp_in,
	);

	given($type) {
		when ($FULL_HTML) { push @cmd, "--full-html=$tmp_out 2>$tmp_err"; }
		when ($SIMPLE_HTML) { push @cmd, "--simple-html=$tmp_out 2>$tmp_err"; }
		when ($SNIPPET_HTML) { push @cmd, "--snippet-html=$tmp_out 2>$tmp_err"; }
		default {
			# default is full html
			push @cmd, "--full-html=$tmp_out 2>$tmp_err";
		}
	}

	
	# execute the command...
	my $cmd = join ' ', @cmd;
	`$cmd`;
	 
	# and read its output...
	my ($out, $err);
	{
		local $/ = undef;   #enable localized slurp mode

		# slurp the process output...
		open CHLD_OUT, $tmp_out	or warn "Could not open $tmp_out";
		$out = <CHLD_OUT>;
		close CHLD_OUT or warn "Could not close $tmp_out\n";
		
		open CHLD_ERR, $tmp_err or warn "Could not open $tmp_err\n";
		$err = <CHLD_ERR>;
		close CHLD_ERR or warn "Could not close $tmp_err\n";
	}
	
	my $html;
	if($err) {
		# remove ANSI color escape sequences...
		$err =~ s/\033\[(\d+)(?:;(\d+)(?:;(\d+))?)?m//g;
		Wx::MessageBox(
			qq{STD.pm warning/error:\n$err},
			'Operation cancelled',
			Wx::wxOK,
			$main,
		);
		print "\nSTD.pm Parsing error\n" . $err . "\n";
		return;
	} else {
		$html = $out;
	}

	# create a temporary HTML file
	my $tmp = File::Temp->new(SUFFIX => '.html');
	$tmp->unlink_on_destroy(0);
	my $filename = $tmp->filename;
	print $tmp $html;
	close $tmp
		or croak "Could not close $filename";

	# try to open the HTML file
	$main->setup_editor($filename);

	# ask the user if he/she wants to open it in the default browser
	my $ret = Wx::MessageBox(
		"Saved to $filename. Do you want to open it now?",
		"Done",
		Wx::wxYES_NO|Wx::wxCENTRE,
		$main,
	);
	if ( $ret == Wx::wxYES ) {
		# launch the HTML file in your default browser
		require URI::file;
		my $file_url = URI::file->new($filename);
		Wx::LaunchDefaultBrowser($file_url);
	}

	return;
}

# Generate a Perl6 executable 
# The idea came from:
# "My first executable from Perl 6" by Moritz Lenz
# http://perlgeek.de/blog-en/perl-6/my-first-executable.writeback
sub generate_p6_exe {
	my $self = shift;

	my $main = $self->main;

	my $doc = $main->current->document;
	if(not defined $doc) {
		Wx::MessageBox( Wx::gettext('No document'), Wx::gettext('Error'), Wx::wxOK, $main, );
		return;
	}
	if($doc->get_mimetype ne q{application/x-perl6}) {
		Wx::MessageBox(
			'Not a Perl 6 file',
			'Operation cancelled',
			Wx::wxOK,
			$main,
		);
		return;
	}


	# Check for perl6 existance and that it is executable.
	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::get_perl6();
	unless($perl6 && -x $perl6) {
		Wx::MessageBox(
			'Cannot find a perl6 executable',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	# Check for -e parrot existance and that it is executable.
	my $parrot = Padre::Plugin::Perl6::Util::get_parrot_command('parrot');
	unless($parrot && -x $parrot) {
		Wx::MessageBox(
			'Cannot find a parrot executable',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	# Check for -e pbc_to_exe existance and that it is executable.
	my $pbc_to_exe = Padre::Plugin::Perl6::Util::get_parrot_command('pbc_to_exe');
	unless($pbc_to_exe && -x $pbc_to_exe) {
		Wx::MessageBox(
			'Cannot find a parrot executable',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	# Check for libparrot existance
	my $libparrot = Padre::Plugin::Perl6::Util::get_libparrot();
	unless($libparrot) {
		Wx::MessageBox(
			'Cannot find a libparrot shared library',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	
	require File::Temp;
	#XXX- CLEANUP must be enabled once testing is finished...
	my $tmp_dir = File::Temp->newdir( CLEANUP => 0 );
	
	my $hello_pl = File::Spec->catfile($tmp_dir, 'hello.pl');
	my $hello_pir = File::Spec->catfile($tmp_dir, 'hello.pir');
	my $hello_pbc = File::Spec->catfile($tmp_dir, 'hello.pbc');
	my $hello_exe = File::Spec->catfile($tmp_dir, $^O eq 'MSWin32' ? 'hello.exe' : 'hello');

	#XXX- quote all those files in win32
	my $perl6_to_pir_cmd = "$perl6 --target=PIR --output=$hello_pir $hello_pl";
	my $pir_to_pbc_cmd = "$parrot -o $hello_pbc $hello_pir";
	my $pbc_to_perl6_exe = "$pbc_to_exe $hello_pbc";
	# Tell the user about the commands that are going to be executed.
	Wx::MessageBox(
		"The following commands are going to be executed:\n\n$perl6_to_pir_cmd\n\n$pir_to_pbc_cmd\n\n$pbc_to_perl6_exe\n",
		'Error',
		Wx::wxOK,
		$main,
	);
	
	
	open HELLO_PL, ">$hello_pl"
		or die "Cannot open $hello_pl\n";
	binmode HELLO_PL, ":utf8";
	my $text = $doc->text_get;
	#XXX- check text_get return value
	print HELLO_PL $text;
	close HELLO_PL
		or die "Cannot close $hello_pl\n";

	my $cmd_1_output = "output_1.txt";
	my $cmd_2_output = "output_2.txt";
	my $cmd_3_output = "output_3.txt";

	# Prepare the output window for the output
	$main->show_output(1);
	my $outpanel = $main->output;
	$outpanel->Remove( 0, $outpanel->GetLastPosition );
	
	#enable localized slurp mode
	local $/ = undef;   
	my $out;
	
	# Run command:
	# perl6 --target=PIR --output=hello.pir hello.pl
	print "Executing:\n $perl6_to_pir_cmd\n";
	`$perl6_to_pir_cmd 1>$cmd_1_output 2>&1`;
	$outpanel->style_neutral;
	
	# slurp the process output...
	open OUTPUT, $cmd_1_output or warn "Could not open $cmd_1_output\n";
	$out = <OUTPUT>;
	close OUTPUT or warn "Could not close $cmd_1_output\n";
	$outpanel->AppendText( $out );
	
	# Run command:
	# parrot/parrot -o hello.pbc hello.pir
	print "Executing:\n $pir_to_pbc_cmd\n";
	`$pir_to_pbc_cmd 1>$cmd_2_output 2>&1`;

	open OUTPUT, $cmd_2_output or warn "Could not open $cmd_2_output\n";
	$out = <OUTPUT>;
	close OUTPUT or warn "Could not close $cmd_2_output\n";
	$outpanel->AppendText( $out );

	# Run command 3.
	# parrot/pbc_to_exe hello.pbc
	print "Executing:\n $pbc_to_perl6_exe\n";
	`$pbc_to_perl6_exe 1>$cmd_3_output 2>&1`;
	
	open OUTPUT, $cmd_3_output or warn "Could not open $cmd_3_output\n";
	$out = <OUTPUT>;
	close OUTPUT or warn "Could not close $cmd_3_output\n";
	$outpanel->AppendText( $out );

	unless(-x $hello_exe) {
		Wx::MessageBox(
			'Operation failed. Please check the output.',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	# Copy the executable to your current folder
	# Copy libparrot.dll or libparrot.so into current folder
	my $current_dir = Cwd::getcwd();
	my $libparrot_name = File::Basename::fileparse($libparrot);
	my $hello_exe_name = File::Basename::fileparse($hello_exe);
	my $dest_libparrot = File::Spec->catfile( $current_dir, $libparrot_name );
	my $dest_hello_exe = File::Spec->catfile( $current_dir, $hello_exe_name);
	print "Copying $libparrot into $dest_libparrot\n";
	File::Copy::copy( $libparrot, $dest_libparrot );
	print "Copying $hello_exe into $dest_hello_exe\n";
	File::Copy::copy( $hello_exe, $dest_hello_exe );

	#
	# Check if the executable is there and tell the user if it succeeded or not
	# and give out statistics about it if possible (size, permissions, ...)
}

# Generates Parrot PIR code from rakudo
# and displays it to the user
sub generate_p6_pir {
	my $self = shift;
	
	
	my $main = $self->main;

	my $doc = $main->current->document;
	if(not defined $doc) {
		Wx::MessageBox( Wx::gettext('No document'), Wx::gettext('Error'), Wx::wxOK, $main, );
		return;
	}
	if($doc->get_mimetype ne q{application/x-perl6}) {
		Wx::MessageBox(
			'Not a Perl 6 file',
			'Operation cancelled',
			Wx::wxOK,
			$main,
		);
		return;
	}


	# Check for perl6 existance and that it is executable.
	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::get_perl6();
	unless($perl6 && -x $perl6) {
		Wx::MessageBox(
			'Cannot find a perl6 executable',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	require File::Temp;
	my $tmp_dir = File::Temp->newdir( CLEANUP => 0 );
	
	my $hello_pl = File::Spec->catfile($tmp_dir, 'hello.pl');
	my $hello_pir = File::Spec->catfile($tmp_dir, 'hello.pir');

	#XXX- quote all those files in win32
	my $perl6_to_pir_cmd = "$perl6 --target=PIR --output=$hello_pir $hello_pl";
	# Tell the user about the commands that are going to be executed.
	Wx::MessageBox(
		"The following command is going to be executed:\n\n$perl6_to_pir_cmd\n",
		'Error',
		Wx::wxOK,
		$main,
	);
	
	
	open HELLO_PL, ">$hello_pl"
		or die "Cannot open $hello_pl\n";
	binmode HELLO_PL, ":utf8";
	my $text = $doc->text_get;
	#XXX- check text_get return value
	print HELLO_PL $text;
	close HELLO_PL
		or die "Cannot close $hello_pl\n";

	my $cmd_output = File::Spec->catfile($tmp_dir, "output.txt");

	# Prepare the output window for the output
	$main->show_output(1);
	my $outpanel = $main->output;
	$outpanel->Remove( 0, $outpanel->GetLastPosition );
	
	#enable localized slurp mode
	local $/ = undef;   
	my $out;
	
	# Run command:
	# perl6 --target=PIR --output=hello.pir hello.pl
	print "Executing:\n $perl6_to_pir_cmd\n";
	`$perl6_to_pir_cmd 1>$cmd_output 2>&1`;
	$outpanel->style_neutral;
	
	# slurp the process output...
	open OUTPUT, $cmd_output or warn "Could not open $cmd_output\n";
	$out = <OUTPUT>;
	close OUTPUT or warn "Could not close $cmd_output\n";
	$outpanel->AppendText( $out );

	unless(-f $hello_pir) {
		Wx::MessageBox(
			'Operation failed. Please check the output.',
			'Error',
			Wx::wxOK,
			$main,
		);
		return;
	}
	
	# try to open the HTML file
	$main->setup_editor($hello_pir);
	
}

1;

__END__

=head1 NAME

Padre::Plugin::Perl6 - Padre plugin for Perl 6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perl 6.

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

The Camelia image is copyright 2009 by Larry Wall.  Permission to use
is granted under the Artistic License 2.0, or any subsequent version
of the Artistic License.