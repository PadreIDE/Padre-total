package Padre::Plugin::Parrot;
use strict;
use warnings;

our $VERSION = '0.16';

use Padre::Wx ();

use base 'Padre::Plugin';

my $parrot;

=head1 NAME

Padre::Plugin::Parrot - Experimental Padre plugin that runs on Parrot

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Parrot.


=head2 Parrot integration

This is an experimentatl feature.

Download Parrot (or check it out from its version control)

Configure PARROT_PATH to point to the root of parrot

Configure LD_LIBRARY_PATH

  export LD_LIBRARY_PATH=$PARROT_PATH/blib/lib/
 
Build Parrot

  cd $PARROT_PATH
  svn up
  make realclean
  perl Configure.pl
  make
  make test

Build Parrot::Embed

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
it will have an embedded Parrot interpreter.


=head1 COPYRIGHT

Copyright 2008 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


sub plugin_name {
	'Parrot';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'                                       => sub { $self->about },
		"Count characters using Perl5"                => \&on_try_perl5,
		"Count characters using PIR embedded Parrot"  => \&on_try_pir,
	];
}

sub registered_documents {
	'application/x-pasm'  => 'Padre::Document::PASM',
	'application/x-pir'   => 'Padre::Document::PIR',
}

sub plugin_enable {
	my $self = shift;
	
	return if not $ENV{PARROT_PATH};
	
	return 1 if $main::parrot; # avoid crash when duplicate calling
	
	local @INC = (
		"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/lib",
		"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/arch",
		"$ENV{PARROT_PATH}/ext/Parrot-Embed/_build/lib",
		@INC);

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
	
	my $doc = Padre::Documents->current;
	my $str = "No file is open";
	if ($doc) {
		$str = "Number of characters in the current file: " . length($doc->text_get);
	}
	
	Wx::MessageBox( "From Perl 5. $str", "Worksforme", Wx::wxOK|Wx::wxCENTRE, $main );
	return;
}

sub on_try_pir {
	my ($main) = @_;

	my $parrot = $main::parrot;
	if (not $parrot) {
		Wx::MessageBox( "Parrot is not available", "No luck", Wx::wxOK|Wx::wxCENTRE, $main );
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

	my $eval = $parrot->compile( $code );
	my $sub  = $parrot->find_global('on_try_pir');

	my $doc = Padre::Documents->current;
	my $str = "No file is open";
	if ($doc) {
		my $pmc  = $sub->invoke( 'PS', $doc->text_get ); 
		$str = "Number of characters in the current file: " . $pmc->get_string;
	}

	Wx::MessageBox( "From Parrot using PIR: $str", "Worksforme", Wx::wxOK|Wx::wxCENTRE, $main );
	return;
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Parrot");
	$about->SetDescription(
		"This plugin currently provides a naive syntax highlighting for PASM files\n" .
		"If you have Parrot compiled on your system in can also provide execution of\n" .
		".. files\n"
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	return;
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
