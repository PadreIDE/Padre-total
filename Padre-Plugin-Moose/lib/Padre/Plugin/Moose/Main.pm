package Padre::Plugin::Moose::Main;

use 5.008;
use strict;
use warnings;
use Padre::Plugin::Moose::FBP::Main ();

our $VERSION = '0.02';
our @ISA     = qw{
  Padre::Plugin::Moose::FBP::Main
};

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->CenterOnParent;
    return $self;
}

sub on_cancel_button_clicked {
    $_[0]->Destroy;
}

sub on_about_button_clicked {
    require Moose;
    require Padre::Unload;
    my $about = Wx::AboutDialogInfo->new;
    $about->SetName('Padre::Plugin::Moose');
    $about->SetDescription(
        Wx::gettext('Moose support for Padre') . "\n\n"
          . sprintf(
            Wx::gettext('This system is running Moose version %s'),
            $Moose::VERSION
          )
    );
    $about->SetVersion($Padre::Plugin::Moose::VERSION);
    Padre::Unload->unload('Moose');
    Wx::AboutBox($about);

    return;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
