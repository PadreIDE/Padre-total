package Padre::Plugin::Moose::Method;

use namespace::clean;
use Moose;

our $VERSION = '0.13';

extends 'Padre::Plugin::Moose::ClassMember';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'modifier' => ( is => 'rw', isa => 'Str' );

sub generate_code {
	my $self     = shift;
	my $comments = shift;

	my $code;
	my $name     = $self->name;
	my $modifier = $self->modifier;
	if ( defined $modifier && $modifier eq 'around' ) {
		$code = "around '$name' => sub {\n";
		$code .= "\tmy \$orig = shift;\n";
		$code .= "\tmy \$self = shift;\n";
		$code .= "\n";
		$code .= "\t# before calling $name\n" if $comments;
		$code .= "\t\$self->\$orig(\@_)\n";
		$code .= "\t# after calling $name\n" if $comments;
		$code .= "};\n";
	} elsif ( defined $modifier && $modifier =~ /^(before|after)$/ ) {
		$code = $self->modifier . " '$name' => sub {\n\tmy \$self = shift;\n};\n";
	} else {
		$code = "sub $name {\n\tmy \$self = shift;\n}\n";
	}

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext('A method is a subroutine within a class that defines behavior at runtime');
}

sub read_from_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name modifier)) {
		$self->$field( $grid->GetCellValue( $row++, 1 ) );
	}
}

sub write_to_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name modifier)) {
		$grid->SetCellValue( $row++, 1, $self->$field );
	}
}

sub get_grid_data {
	require Wx;
	return [
		{ name => Wx::gettext('Name:') },
		{ name => Wx::gettext('Modifier:'), choices => [qw(around after before)] },
	];
}

__PACKAGE__->meta->make_immutable;

1;
