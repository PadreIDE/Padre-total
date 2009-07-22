package Padre::Plugin::Parrot;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.23';

use Padre::Wx ();

use base 'Padre::Plugin';

my $parrot;

# TODO get documentation from parrot/src/ops/*.ops and parrot/docs/pdds/pdd19_pir.pod

=head1 NAME

Padre::Plugin::Parrot - Experimental Padre plugin that runs on Parrot

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Parrot
with several submenues.

About is just some short explanation

The other menu options will count the number of characters in the current document
using the current Perl 5 interpreter or PASM running on top of Parrot.
Later we add other implementations running on top of Parrot.

=head1 Parrot integration

This is an experimental feature.

Download Parrot (or check it out from its version control)

Configure PARROT_DIR to point to the root of parrot

Configure LD_LIBRARY_PATH

  export LD_LIBRARY_PATH=$PARROT_DIR/blib/lib/
 
=head2 Build Parrot

  cd $PARROT_DIR
  svn up
  make realclean
  perl Configure.pl
  make
  make test

=head2 Build languages

After building Parrot you can run

 make languages

to build all the languages or cd to the directory of
the individual languages and type C<make>.

=over 4

=item Perl 6 (Rakudo)

In order to be able to run code written in Perl 6,
after building Parrot do the following:

 cd languages/
 git clone http://github.com/rakudo/rakudo.git
 cd rakudo
 perl Configure.pl
 make

Configure RAKUDO_DIR to point to the directory where rakudo was checked out.
In the above case RAKUDO_DIR=$PARROT_DIR/language/rakudo 

See L<https://trac.parrot.org/parrot/ticket/77>

=item Lua

 cd languages/lua
 make 
 
Currently Lua cannot be embedded. See L<https://trac.parrot.org/parrot/ticket/74>


=item PHP (Pipp)

 cd languages/pipp
 make
 
See L<https://trac.parrot.org/parrot/ticket/76>

=item Pynie (Python)

See L<https://trac.parrot.org/parrot/ticket/79>

=item Cardinal (Ruby)

In order to support Ruby highlighting one needs to configure the CARDINAL_DIR 
environment variable to point to the place where the cardinal.pbc can be located.

  $ cd $HOME
  $ git clone git://github.com/cardinal/cardinal.git
  $ export CARDINAL_DIR=$HOME/cardinal
  $ cd $PARROD_DIR
  $ mkdir languages
  $ cd language
  $ ln -s $CARDINAL_DIR
  $ cd cardinal
  $ perl Configure.pl
  $ make
  
See L<https://trac.parrot.org/parrot/ticket/77>

=back

=head2 Build Parrot::Embed

  cd ext/Parrot-Embed/
  ./Build realclean
  perl Build.PL
  ./Build
  ./Build test

The test will give a warning like this, but will pass:

 Parrot VM: Can't stat no file here, code 2.
 error:imcc:syntax error, unexpected IDENTIFIER
	in file 'EVAL_2' line 1

Now if you run Padre and enable Padre::Plugin::Parrot 
it will have an embedded Parrot interpreter that can run
code written in PASM.


=head1 COPYRIGHT

Copyright 2008-2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

my $pod = <<"POD";

=head1 Parrot

Some text
L</home/gabor/work/parrot/docs/intro.pod>

=cut

POD

sub padre_interfaces {
	return 'Padre::Plugin' => 0.26;
}

sub plugin_name {
	'Parrot';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },

		#'Help'                                        => \&show_help,

		"Count characters using Perl5"                  => \&on_try_perl5,
		"Count characters using PIR in embedded Parrot" => \&on_try_pir,
	];
}

sub registered_documents {
	'application/x-pasm' => 'Padre::Document::PASM', 'application/x-pir' => 'Padre::Document::PIR',;
}

# TODO, Planning the syntax highlighting feature:
# -------------------------------
# let the user regiser 
# mime-type, Path/to/language.pge, Name, Description?
# or
# mime-type, Path/to/language.exe, Name, Description?

# Though as this is only for personal use on the users own computer
# for now, we don't really need a description field but maybe the user
# wants to add comments.
# Name must be ASCII string without 
# We can recognize if this is a .pge file or an executable 
# (.exe on windows nothing on Unix) but we might also provide a check-box
# so the user can configure this.

# We ave this information in a database or config file
# We read this information at load time and based on this change the 
# provided_highlighters and highlighting_mime_types functions
#
# With the module name being Padre::Plugin::HL::Name  (using the Name the user gave us)
# the module is virtual, only exists in memory

my @highlighters = (
	['Padre::Document::PIR', 'Parrot in Perl 5', 'PIR syntax highlighting with Perl 5 regular expressions'],
	['Padre::Plugin::Parrot', 'Parrot PGE', 'Using the PGE engine for highlighting'],
);

my %highlighter_mimes = (
	'Padre::Document::PIR' => ['application/x-pir'],
);

# [mime-type,    path-to-pbc-or-exe,  'NameWithoutSpace', 'Description'] 
my @config;
if ($ENV{RAKUDO_DIR}) {
	push @config, ['application/x-perl6', "$ENV{RAKUDO_DIR}/perl6.pbc",       'Perl6', 'Perl 6 via Parrot and perl6.pbc'];
}
if ($ENV{CARDINAL_DIR}) {
	push @config, ['application/x-ruby',  "$ENV{CARDINAL_DIR}/cardinal.pbc",  'Ruby',  'Ruby via Cardinal on Parrot and cardinal.pbc'];
}

use Padre::Plugin::Parrot::HL;
foreach my $e (@config) {
	my ($mime_type, $path, $name, $description) = @$e;
	next if not -e $path;
	# TODO check other values as well

	my $pbc	= ($path =~ /\.pbc$/ ? 1 : 0);
	my $module = 'Parrot::Plugin::HL::' . ($pbc ? 'PBC::' : '') . $name;
	my $display_name = "Parrot/" . ($pbc ? 'PBC' : 'EXE') . "/$name";
	{
		# create virtual namespace and colorize() function.
		# maybe I only need to create 
		
		my $sub = sub { return ($pbc, $path) };
		my $isa = $module . '::ISA';
		my $function = $module . '::pbc_path';
		no strict 'refs';
		@$isa = ('Padre::Plugin::Parrot::HL');
		*{$function} = $sub;
	}
	push @highlighters, [$module, $display_name, $description];
	$highlighter_mimes{$module} = [$mime_type];
}

sub provided_highlighters {
	return @highlighters;
}

sub highlighting_mime_types {
	return %highlighter_mimes;
}

sub plugin_enable {
	my $self = shift;

	return if not $ENV{PARROT_DIR};

	return 1 if $main::parrot;    # avoid crash when duplicate calling

	local @INC = (
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/lib",
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/arch",
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/_build/lib",
		@INC
	);

	# for now we keep the parrot interpreter in a script-global
	# in $main as if we try to reload the Plugin the embedded parrot will
	# blow up. TODO: we should be able to shut down the Parrot interpreter
	# when the plugin is disabled.
	eval {
		require Parrot::Embed;
		$main::parrot = Parrot::Interpreter->new;
	};
	if ($@) {
		warn $@;
		return;
	}

	return 1;
}

sub on_try_perl5 {
	my ($main) = @_;

	my $doc = Padre::Current->document;
	my $str = "No file is open";
	if ($doc) {
		$str = "Number of characters in the current file: " . length( $doc->text_get );
	}

	Wx::MessageBox( "From Perl 5. $str", "Worksforme", Wx::wxOK | Wx::wxCENTRE, $main );
	return;
}

sub on_try_pir {
	my ($main) = @_;

	my $parrot = $main::parrot;
	if ( not $parrot ) {
		Wx::MessageBox( "Parrot is not available", "No luck", Wx::wxOK | Wx::wxCENTRE, $main );
		return;
	}

	my $code = <<END_PIR;
.sub on_try_pir
	.param string code

	.local int count
	count = length code

	.return( count )
.end
END_PIR

	my $eval = $parrot->compile($code);
	my $sub  = $parrot->find_global('on_try_pir');

	my $doc = Padre::Current->document;
	my $str = "No file is open";
	if ($doc) {
		my $pmc = $sub->invoke( 'PS', $doc->text_get );
		$str = "Number of characters in the current file: " . $pmc->get_string;
	}

	Wx::MessageBox( "From Parrot using PIR: $str", "Worksforme", Wx::wxOK | Wx::wxCENTRE, $main );
	return;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription( "This plugin currently provides a naive syntax highlighting for PASM files\n"
			. "If you have Parrot compiled on your system it can also provide execution of\n"
			. "PASM files\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

sub show_help {
	my $main = Padre->ide->wx->main;

	#print "$main->{help}\n";
	if ( $ENV{PARROT_DIR} ) {
		my $path = File::Spec->catfile( $ENV{PARROT_DIR}, 'docs' );
		my $doc = Padre::Document->new;
		$doc->{original_content} = $pod;

		#my $doc = Padre::Document->new( filename => $path );
		$doc->set_mimetype('application/x-pod');
		$main->{help}->help($doc);
	} else {
		$main->{help}->help('Padre::Plugin::Parrot');
	}

	$main->{help}->SetFocus;
	$main->{help}->Show(1);
}

package Px;

use constant {
	PASM_KEYWORD  => 1,
	PASM_REGISTER => 2,
	PASM_LABEL    => 3,
	PASM_STRING   => 4,
	PASM_COMMENT  => 5,
	PASM_POD      => 6,
};

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

#pasm:
# brace_highlight: 00ffff
# colors:
#  PASM_KEYWORD:     7f0000
#  PASM_REGISTER:    7f0044
#  PASM_LABEL:       aa007f
#  PASM_STRING:      00aa7f
#  PASM_COMMENT:     0000aa
#  PASM_POD:         0000ff
#
