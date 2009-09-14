package Padre::Plugin::GUITest;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Current;

use base 'Padre::Plugin';

use Win32::GuiTest qw(:ALL);

=head1 NAME

Padre::Plugin::GUITest - a GUI to wrap the Win32::GUITest module


=head1 SYNOPSIS

This plugin provides an interface to the L<Win32::GuiTest> for 
analysing applications running on Windows.

At one point we should also look into connecting with L<Win32::GUIRobot>.

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.10 itself.

=cut



sub padre_interfaces {
	return 'Padre::Plugin' => 0.41;
}

sub plugin_name {
	'GUI Testing';
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
		'Spy'   => sub { $self->spy },
	];
}

sub about {
	my ($self) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Wrapper around Win32::GuiTest\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

# TODO move to be object variable
my %seen;
my $root    = 0;
my $format = "%-10s %-10s, '%-25s', %-10s, Rect:%-3s,%-3s,%-3s,%-3s   '%s'\n";
sub spy {
	my ($self) = @_;
	# need to configure either to do all or a certain title.

	my $main = Padre->ide->wx->main;

	$main->show_output(1);
	$main->output->clear;

	# Based on the spy.pl from the Win32::GuiTest distributions
	# Parse a subtree of the whole windoing systme and print as much information as possible
	# about each window and each object.
	my %opts; 
	# title => 'some title'
	$opts{all} = 1;
	# "id=i"
	#"class=s"

	my $desktop = GetDesktopWindow();
	my $start;

	$start = 0 if $opts{all};
	$start = $opts{id} if $opts{id};
	if ($opts{title} or $opts{class}) {
		my @windows = FindWindowLike(0, $opts{title}, $opts{class});
		#my @windows = FindWindowLike(0, $opts{title}) if $opts{title};
		#@windows = FindWindowLike(0, '', $opts{class}) if $opts{class};
		if (@windows > 1) {
			_myprint("There are more than one window that fit:\n");
			foreach my $w (@windows) {
				_myprint(sprintf("%s | %s | %s\n", $w,  GetClassName($w), GetWindowText($w)));
			}
			exit;
		}
		die "Did not find such a window." if not @windows;
		$start = $windows[0];
	}
	#usage() if not defined $start;
	_myprint(sprintf($format,
		"Depth",
		"WindowID",
		"ClassName",
		"ParentID",
		"WindowRect","","","",
		"WindowText"));
	parse_tree($start);
}

sub GetImmediateChildWindows {
	my $WinID = shift;
	grep {GetParent($_) eq $WinID} GetChildWindows $WinID;
}
    
sub parse_tree {
	my $w = shift;
	if ($seen{$w}++) {
		_myprint("loop $w\n");
		return;
	}

	prt($w);
	#foreach my $child (GetChildWindows($w)) {
	#       parse_tree($child);
	#}
	foreach my $child (GetImmediateChildWindows($w)) {
		_myprint("------------------\n") if $w == 0;
		parse_tree($child);
	}
}

# GetChildDepth is broken so here is another version, this might work better.

# returns the real distance between two windows
# returns 0 if the same windows were provides
# returns -1 if one of the values is not a valid window
# returns -2 if the given "ancestor" is not really an ancestor of the given "descendant"
sub MyGetChildDepth {
	my ($ancestor, $descendant) = @_;
	return -1 if $ancestor and (not IsWindow($ancestor) or not IsWindow($descendant));
	return 0 if $ancestor == $descendant;
	my $depth = 0;
	while ($descendant = GetParent($descendant)) {
		$depth++;
		last if $ancestor == $descendant;
	}
	return $depth + 1 if $ancestor == 0;
}


sub prt {
	my $w = shift;
	my $depth = MyGetChildDepth($root, $w);
	_myprint(sprintf($format,
		(0 <= $depth ? "+" x $depth : $depth),
		$w, 
		($w ? GetClassName($w) : ""),
		($w ? GetParent($w) : "n/a"),
		($w ? GetWindowRect($w) : ("n/a", "", "", "")),
		($w ? GetWindowText($w) : ""))); 
}

sub _myprint {
	my ($txt) = @_;
	my $main = Padre->ide->wx->main;
	$main->output->AppendText($txt)
}

1;

# Copyright 2009 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5.10 itself.

