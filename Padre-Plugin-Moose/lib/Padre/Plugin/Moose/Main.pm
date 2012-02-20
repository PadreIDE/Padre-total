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
	my $main  = shift;

	my $self = $class->SUPER::new($main);
	$self->CenterOnParent;

	# Defaults
	$self->{namespace_autoclean_checkbox}->SetValue(1);
	$self->{make_immutable_checkbox}->SetValue(1);
	$self->{add_comments_checkbox}->SetValue(1);
	$self->{add_main_checkbox}->SetValue(1);

	# Setup preview editor
	my $preview = $self->{preview};
	$preview->{Document} = Padre::Document->new( mimetype => 'application/x-perl', );
	$preview->{Document}->set_editor($preview);
	$preview->Show(1);

	$preview->SetLexer('application/x-perl');
	$preview->SetText("\n# Generated Perl code is shown here");

	# Apply the current theme
	my $style = $main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply($preview);

	$preview->SetReadOnly(1);

	return $self;
}

sub on_cancel_button_clicked {
	$_[0]->EndModal(Wx::ID_CANCEL);
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

sub on_add_class_button {
	my $self = shift;
	
	my $class = $self->{class_text}->GetValue;
	my $superclass = $self->{superclass_text}->GetValue;
	my $roles = $self->{roles_text}->GetValue;
	my $namespace_autoclean = $self->{namespace_autoclean_checkbox}->IsChecked;
	my $make_immutable = $self->{make_immutable_checkbox}->IsChecked;
	my $add_comments = $self->{add_comments_checkbox}->IsChecked;
	my $add_main = $self->{add_main_checkbox}->IsChecked;

	$class =~ s/^\s+|\s+$//g;
	$superclass =~ s/^\s+|\s+$//g;
	$roles =~ s/^\s+|\s+$//g;
	my @roles = split /,/, $roles;

	if($class eq '') {
		$self->main->error(Wx::gettext('Class name cannot be empty'));
		$self->{class_text}->SetFocus();
		return;
	}

	my $code = "package $class;\n";

	if($namespace_autoclean) {
		$code .= "\nuse namespace::clean;";
		$code .= $add_comments
			? " # Keep imports out of your namespace\n"
			: "\n";
	}

	$code .= "\nuse Moose;";
	$code .= $add_comments
		? " # automatically turns on strict and warnings\n"
		: "\n";
	$code .= "\nextends '$superclass';\n" if $superclass ne '';

	$code .= "\n" if scalar @roles;
	for my $role (@roles) {
		$code .= "with '$role';\n";
	}

	if($make_immutable) {
		$code .= "\n__PACKAGE__->meta->make_immutable;";
		$code .= $add_comments
			? " # Makes it faster\n"
			: "\n";
	}
	$code .= "\n1;\n";

	if($add_main) {
		$code .= "\n\npackage main;\n";
		$code .= "\nuse $class;\n";
		$code .= "\nmy \$o = $class->new;\n";
	}

	my $preview = $self->{preview};
	$preview->SetReadOnly(0);
	$preview->SetText($code);
	$preview->SetReadOnly(1);
}

sub on_add_role_button {
	my $self = shift;
	
	my $role = $self->{role_text}->GetValue;
	my $requires = $self->{requires_text}->GetValue;

	$role =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

	if($role eq '') {
		$self->main->error(Wx::gettext('Role name cannot be empty'));
		$self->{role_text}->SetFocus();
		return;
	}
	
	if(scalar @requires == 0) {
		$self->main->error(Wx::gettext('Requires list cannot be empty'));
		$self->{requires_text}->SetFocus();
		return;
	}

	my $code = "package $role;\n";
	$code .= "\nuse Moose::Role;\n";

	$code .= "\n" if scalar @requires;
	for my $require (@requires) {
		$code .= "with '$require';\n";
	}
	$code .= "\n1;\n";

	my $preview = $self->{preview};
	$preview->SetReadOnly(0);
	$preview->SetText($code);
	$preview->SetReadOnly(1);
}

sub on_add_attribute_button {
	my $self = shift;
	
	print "on_add_attribute_button\n";
}

sub on_add_subtype_button {
	my $self = shift;
	
	print "on_add_subtype_button\n";
}

sub on_insert_button_clicked {
	my $self = shift;

	$self->main->on_new;
	my $editor = $self->current->editor or return;
	$editor->insert_text($self->{preview}->GetText);
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
