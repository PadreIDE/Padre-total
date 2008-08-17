package Padre::Demo;

use 5.008;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(prompt print_out promp_input_file);

sub prompt {
   my $frame = $Padre::Demo::App::frame;
   $frame->prompt(@_);
}

sub print_out {
   my $frame = $Padre::Demo::App::frame;
   $frame->print_out(@_);
}

sub promp_input_file {
   my $frame = $Padre::Demo::App::frame;
   $frame->promp_input_file(@_);
}

$| = 1;

my $main;

sub run {
   my ($class, $cb) = @_;
   $main = $cb;
   my $app = Padre::Demo::App->new();
   
   $app->MainLoop;
}

1;
