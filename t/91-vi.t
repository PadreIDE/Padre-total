#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use Padre::Plugin::Vi;
use Padre::Plugin::Vi::Editor;
use t::lib::Padre::Editor;

ok(1);
BEGIN { $tests += 1; }

my $e = t::lib::Padre::Editor->new;

my $text = <<"END_TEXT";
This is the first line
A second line
and there is even a third line
END_TEXT


{
	diag "Testing the t::lib::Padre::Editor a bit";
	$e->SetText($text);
	is($e->GetText($text), $text);

	is($e->GetCurrentPos, 0);
	
	is($e->LineFromPosition(0), 0);
	is($e->LineFromPosition(20), 0);
	is($e->LineFromPosition(22), 0);
	is($e->LineFromPosition(23), 1);
	is($e->LineFromPosition(24), 1);
	
	is($e->GetLineEndPosition(0), 23);
	
	is($e->PositionFromLine(0), 0);
	is($e->PositionFromLine(1), 23);
	
	is($e->GetColumn(0), 0);
	is($e->GetColumn(5), 5);
	is($e->GetColumn(22), 22);
	is($e->GetColumn(23), 0);
	is($e->GetColumn(24), 1);
	BEGIN { $tests += 1+1+5+1+2+5; }
}

my $editor = Padre::Plugin::Vi::Editor->new($e);
isa_ok($editor, 'Padre::Plugin::Vi::Editor');
BEGIN { $tests += 1; }

# TODO: what should happen when ESC pressed with Ctrl or other modifier?
{
	is($editor->key_down(0, Wx::WXK_ESCAPE), 0);
	BEGIN { $tests += 1; }
}

{
	is($editor->key_down(0, ord('L')), 0);
	is($e->GetCurrentPos, 1);
	BEGIN { $tests += 2; }
}

{
	is($editor->key_down(0, ord('3')), 0);
	is($editor->key_down(0, ord('L')), 0);
	is($e->GetCurrentPos, 4);
	BEGIN { $tests += 3; }
}

{
	is($editor->key_down(0, ord('2')), 0);
	is($editor->key_down(0, ord('H')), 0);
	is($e->GetCurrentPos, 2);
	BEGIN { $tests += 3; }
}

{
	is($editor->key_down(0, ord('5')), 0);
	is($editor->key_down(0, ord('H')), 0);
	is($e->GetCurrentPos, 0);
	BEGIN { $tests += 3; }
}

{
	is($editor->key_down(0, ord('J')), 0);
	is($e->GetCurrentPos, 23);
	BEGIN { $tests += 2; }
}
{
	is($editor->key_down(0, ord('K')), 0);
	is($e->GetCurrentPos, 0);
	BEGIN { $tests += 2; }
}

# code: Wx::WXK_ESCAPE

# mode:  Wx::wxMOD_META  (Num Lock being pressed on Linux)
# (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());

