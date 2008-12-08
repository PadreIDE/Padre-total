#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
use Wx ':everything';

use lib 'lib';
use Wx::Perl::Dialog;

my $win = Wx::Frame->new;

my $page_1 = [
	[
		[ 'Wx::StaticText', undef,       "A checkbox" ],
		[ 'Wx::TextCtrl',   'checkbox',  "1" ]
	],
	[
		[ 'Wx::StaticText', undef,       "A text field" ],
		[ 'Wx::TextCtrl',   'textfield', "qwertz" ]
	],
];

my $page_2 = [
    [
        [ 'Wx::StaticText',     undef,     "A font picker" ],
        [ 'Wx::FontPickerCtrl', 'fntpick', undef ]
    ],
    [
        [ 'Wx::StaticText',       undef,     "A colour picker" ],
        [ 'Wx::ColourPickerCtrl', 'colpick', undef ]
    ],
];


my $dialog = Wx::Perl::Dialog->new(
	parent => $win,
	title  => "A dialog",
	layout => [ $page_1, $page_2 ],
	width  => [200, 200],
	multipage => { auto_ok_cancel => 1, ok_widgetid => '_ok_', cancel_widgetid => '_cancel_', pagenames => [ 'Basic', 'Advanced' ] },
);

$dialog->ShowModal;

exit;

