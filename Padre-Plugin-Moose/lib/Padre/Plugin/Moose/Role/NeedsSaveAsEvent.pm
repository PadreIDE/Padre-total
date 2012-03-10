package Padre::Plugin::Moose::Role::NeedsSaveAsEvent;
use Moose::Role;

requires 'on_save_as';
after 'on_save_as' => sub {
	my $self = shift;
	return unless $self->isa('Padre::Wx::Main');
	my $manager = $self->{ide}->plugin_manager;
	$manager->plugin_event('editor_changed');
};

no Moose::Role;
1;
