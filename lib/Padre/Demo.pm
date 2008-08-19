package Padre::Demo;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
use Padre::Demo::App;

our @EXPORT = qw(prompt print_out promp_input_file close_app);

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

sub close_app {
   my $frame = $Padre::Demo::App::frame;
   $frame->Close;
}

sub get_frame {
   return $Padre::Demo::App::frame;
}

$| = 1;

our $main;
our $app;

sub run {
   my ($class, $cb) = @_;
   $main = $cb;
   $app = Padre::Demo::App->new();
   
   $app->MainLoop;
}

1;
