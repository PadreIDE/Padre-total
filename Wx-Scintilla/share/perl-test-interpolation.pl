#--------------------------------------------------------------------------
# perl-test-interpolation.pl
#--------------------------------------------------------------------------
# This is mainly interpolation-related notes and tests.
#
# Primary documentation (version 5.14.1, 20110809):
#	http://perldoc.perl.org/perlop.html
#
# Tests done on Perl 5.10.1 (Cygwin)
#
# NOTE: If highlighting does not work or work partially, it means that
#       the implementation has not covered those cases yet.
#
#--------------------------------------------------------------------------
# Kein-Hong Man <keinhong@gmail.com> Public Domain 20110810
#--------------------------------------------------------------------------
# 20110810	initial document
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# Overview notes for variable interpolation (digested from perlop, untested)
#--------------------------------------------------------------------------

# types of 'blocks' needing variable interpolation:
# -------------------------------------------------
"";	# literal			SCE_PL_STRING		SCE_PL_STRING_VAR
qq{};	# 				SCE_PL_STRING_QQ	SCE_PL_STRING_QQ_VAR
``;	# command			SCE_PL_BACKTICKS	SCE_PL_BACKTICKS_VAR
qx{};	# 		[1]		SCE_PL_STRING_QX	SCE_PL_STRING_QX_VAR
//;	# pattern match    [2]		SCE_PL_REGEX		SCE_PL_REGEX_VAR
m{};	# 		[1][2]		SCE_PL_REGEX		SCE_PL_REGEX_VAR
qr{};	# pattern 	[1][2]		SCE_PL_STRING_QR	SCE_PL_STRING_QR_VAR
s{}{};	# substitution	[1][2]		SCE_PL_REGSUBST		SCE_PL_REGSUBST_VAR
<<EOF;	# here-doc	[1]   [3]	                                                         ;
EOF
	#	"EOF" or EOF	->	SCE_PL_HERE_QQ		SCE_PL_HERE_QQ_VAR
	#	`EOF`		->	SCE_PL_HERE_QX		SCE_PL_HERE_QX_VAR

# [1] no interpolation if '' delimiter pair used
#     a $$ delimiter pair has priority over $var usage
#     a @@ delimiter pair has priority over @var usage
# [2] issues with $ in pattern, documentation specifically mentions
#     that $( $) $| are not interpolated
# [3] "EOF", `EOF` or EOF interpolates, 'EOF' or \EOF doesn't
#     therefore, SCE_PL_HERE_Q is not interpolated

# these are NOT interpolated, for reference:
# ------------------------------------------
'';	# literal			SCE_PL_CHARACTER
q{};	#				SCE_PL_STRING_Q
qw{};	# word list			SCE_PL_STRING_QW
tr{}{};	# transliteration [4]		SCE_PL_REGSUBST
y{}{};	# transliteration [4]		SCE_PL_REGSUBST

# [4] interpolated only if wrapped in an eval() e.g. eval("tr{}{}")
#     i.e. using "string" interpolation, so no special treatment necessary

#--------------------------------------------------------------------------
# Limitations of preliminary variable interpolation implementation:
# * Under consideration for future implementation.
# * IMPORTANT:
#   For (2),(3) the best way is to scan until the end of the block, to
#   the ending delimiter, then process the entire string for interpolations.
#   Perl parses them in much the same way. With the endpoint known, any
#   incomplete interpolation {} [] brackets is easily found.
#
# (1) whitespace not allowed (but in reality, perl allows whitespace
#     in various places, especially within [] {} subscripts)
#	VT does not work, FF work, rest of whitespace chars work
#	multiple lines also work, but users unlikely to code this way
#	(but there seems to be various exceptions...)
#
# (2) ${bareword} style not detected
#	related to (1), a common idiom used when variable is adjacent
#       to identifier chars, the bareword is promoted if valid
#	not many though in lib/perl5 modules
#
# (3) subscription elements not detected
#	{} [] -> (or a combination)
#	heuristics likely to be greedy matching
#
# (4) special variables not detected, except for $_ @_
#	@_ @+ @- was specifically mentioned to not require braces like @{+}
#	$-type special vars is problematic within s{}{} (see [2] above)
#
# (5) 'e'/'ee' modifiers for s{}{} causes evaluation of the REPLACEMENT
#	this is related to eval() which evaluates a string as a Perl expr
#	won't touch this with a ten-yard stick...
#
#--------------------------------------------------------------------------

$foo = "baz";	# FOR REFERENCE: example variables to be interpolated
$boo = 'boo';	# in the tests that follows
@boo = ("one", "two", "three");

#--------------------------------------------------------------------------
# "" double-quoted literal (mostly tested samples)
#--------------------------------------------------------------------------

"basic";	# FOR REFERENCE: basic
"multiline string
second line";	# multiline

"\$";		# escaped $
"text\$text";
"$";		# ERROR, perl says $name expected or escape with \$
"$$";		# pid
"text$$text";	# perl recognizes $$text

"$foo";		# simple var
"text$foo;;";
"$foo\n";	# terminated by \
"$$foo";	# reference $foo = \"baz";
"text$$foo;;";
"$$$foo";	# reference $foo = \\"baz"; and so on...
"text$$$foo;;";
"$$$$$$$$$$$$$$$$$$$foo";	# still legal...

"$ 	foo";	# still works with additional spaces and tabs
		# also with multiple newlines (and CR too)
		# VT failed, FF worked (consider this unreliable)

"${foo}";	# bareword style
"text${foo}text";
"$ {  foo  }";	# whitespace behaviour same as above

# almost every operator is used for $-style special variables
# not implemented for now, but checked some cases:

"-$\-";		# outputs "--" where $\ == $OUTPUT_RECORD_SEPARATOR
		# but "$\" fails to parse! perl needs a trailing char
"${";		# ERROR, no closing brace (future TODO)
"$}";		# not a special variable, works, probably undef var
"$"";		"# ERROR, string's delimiter char has priority

"$#";		# ERROR, special var $# was removed in Perl 5.10
"$#boo";	# prints 2, last index of @boo array
"text$#boo;;";
"$# boo";	# warning, then 'boo' (no space allowed in between)

# basic variables, these follow identifier rules
"$foo"; "$abc123"; "$_"; "$_abc"; "$_123"; "$a_1";
"$foo $foo	$foo-$foo+$foo;";	# non-word char terminates
"$foo $foo	$foo
$foo+$foo;";			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
"$foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]";

"\@";		# escaped @
"text\@text";
"@";		# no error! prints as '@'
"@@";		# prints as '@@'
"text@@text";	# perl recognizes @text

"@boo";		# simple array
"text@boo;;";
"@boo\n";	# terminated by \
"@bo";		# empty string, probably undef array
"@@boo";	# the @boo is valid, prints '@one two three'
"@$boo";	# valid, prints 'one two three' if $boo='boo';
"@$$$boo";	# valid, same output
"text@$$$boo;;;";
"@$$$$$$$$$$$$$$$$$$$boo";	# still legal...

"@$";		# empty string, probably undef array
"$@boo";	# nope, prints 'boo' where $@ is a special variable
"@  	boo";	# nope, prints '@  	boo'! whitespace not allowed!

"@{boo}";	# bareword style
"@{ boo }";	# whitespace within {} works, including newlines
"@ {boo}";	# nope, prints '@ {boo}'

# the special variables for @ are:
@_ @F @INC @+ @- @ARGV
# only @_ @+ @- uses operators as second char
"-@\-";		# nope, prints '-@-', not a special var
"@{";		# ERROR, no closing brace (future TODO)
"@}";		# all other bracket chars print as literal chars

# basic variables, these follow identifier rules
"@boo"; "@abc123"; "@_"; "@_abc"; "@_123"; "@a_1";
"@boo @boo	@boo-@boo+@boo;";	# non-word char terminates
"@boo @boo	@boo
@boo+@boo;";			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
"@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]";

# mixture of adjacent interpolated vars (untested)
"$foo$foo"; "$foo$$$foo"; "$foo$#boo"; "$foo@boo"; "$foo@$$boo";
"@boo$foo"; "@boo$$$foo"; "@boo$#boo"; "@boo@boo"; "@boo@$$boo";
"$foo$"; "$foo$$$"; "$foo$#"; "$foo@"; "$foo@$$";	# adjacent non-vars

#--------------------------------------------------------------------------
# qq{} literal (mostly tested samples)
#--------------------------------------------------------------------------

# FOR REFERENCE:
qq!stuff!; qq mstuffm; qq 1stuff1;	# various delimiters
qq(foo); qq[foo]; qq{foo}; qq<foo>;	# 4 kinds of opposite pairs
qq\stuff\; qq\\;			# backslash delimiter

qq|\$|;		# escaped $
qq.text\$text.;
qq*$*;		# ERROR, perl says $name expected or escape with \$
qq~$$~;		# pid
qq~text$$text~;	# perl recognizes $$text

qq+$foo+;	# simple var
qq _text$foo;;_;
qq@$foo\n@;	# terminated by \
qq($$foo);	# reference $foo = \"baz";
qq<text$$foo;;>;
qq[$$$foo];	# reference $foo = \\"baz"; and so on...
qq{text$$$foo;;};
qq%$$$$$$$$$$$$$$$$$$$foo%;	# still legal...

qq:$ 	foo:;	# still works with additional spaces and tabs
		# also with multiple newlines (and CR too)
		# VT failed, FF worked (consider this unreliable)

qq#${foo}#;	# bareword style
qq&text${foo}text&;
qq/$ { foo }/;	# this sample legal (not fully checked)

qq;-$\-;;	# outputs "--" where $\ == $OUTPUT_RECORD_SEPARATOR
		# but "$\" fails to parse! perl needs a trailing char

# almost every operator is used for $-style special variables
# not implemented for now, but checked some cases:

qq(${);		# ERROR, no closing brace (future TODO)
qq($});		# not a special variable, works, probably undef var

qq($#);		# ERROR, special var $# was removed in Perl 5.10
qq($#boo);	# prints 2, last index of @boo array
qq(text$#boo;;);
qq($# boo);	# warning, then 'boo' (no space allowed in between)

# basic variables, these follow identifier rules
qq($foo); qq($abc123); qq($_); qq($_abc); qq($_123); qq($a_1);
qq($foo $foo	$foo-$foo+$foo;);	# non-word char terminates
qq($foo $foo	$foo
$foo+$foo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qq($foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]);

qq|\@|;		# escaped @
qq.text\@text.;
qq*@*;		# no error! prints as '@'
qq~@@~;		# prints as '@@'
qq~text@@text~;	# perl recognizes @text

qq+@boo+;	# simple array
qq _text@boo;;_;
qq^@boo\n^;	# terminated by \
qq,@bo,;	# empty string, probably undef array
qq?@@boo?;	# the @boo is valid, prints '@one two three'
qq(@$boo);	# valid, prints 'one two three' if $boo='boo';
qq<@$$$boo>;	# valid, same output
qq{text@$$$boo;;;};
qq%@$$$$$$$$$$$$$$$$$$$boo%;	# still legal...

qq:@$:;		# empty string, probably undef array
qq:$@boo:;	# nope, prints 'boo' where $@ is a special variable
qq:@  	boo:;	# nope, prints '@  	boo'! whitespace not allowed!

qq#@{boo}#;	# bareword style
qq&@{ boo }&;	# this sample legal (not fully checked)
qq/@ {boo}/;	# nope, prints '@ {boo}'

# only @_ @+ @- uses operators as second char
qq;-@\-;;	# nope, prints '-@-', not a special var
qq(@{);		# ERROR, no closing brace (future TODO)
qq(@});		# all other bracket chars print as literal chars

# basic variables, these follow identifier rules
qq(@boo); qq(@abc123); qq(@_); qq(@_abc); qq(@_123); qq(@a_1);
qq(@boo @boo	@boo-@boo+@boo;);	# non-word char terminates
qq(@boo @boo	@boo
@boo+@boo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qq(@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]);

# mixture of adjacent interpolated vars (untested)
qq($foo$foo); qq($foo$$$foo); qq($foo$#boo); qq($foo@boo); qq($foo@$$boo);
qq(@boo$foo); qq(@boo$$$foo); qq(@boo$#boo); qq(@boo@boo); qq(@boo@$$boo);
qq($foo$); qq($foo$$$); qq($foo$#); qq($foo@); qq($foo@$$);	# adjacent non-vars

# nested delimiters
qq((text)$foo(text));	# var terminated by paired delimiter
qq<<>$foo<>>;
qq{${foo{bar}}};	# legal syntax, dunno meaning

# wordchar delimiters
qq _$foo_;		# space separator after 'qq' mandatory
qq 1$foo1;		# delimiter is not consumed by interpolated var
qq m$foom;

# single quote delimiter for qq{} still enables interpolation
# (for the others, using '' disables interpolation, see details at top)
qq'$foo'; qq'@boo'; qq'$#boo';

#--------------------------------------------------------------------------
# `` command (mostly tested samples)
# NOTE: `` uses the same codepath as "" so its behaviour should be
#       identical, the following is more about testing valid syntax
#--------------------------------------------------------------------------

`echo basic`;	# FOR REFERENCE: basic
`echo multiline string
second line`;	# multiline

`echo \$`;	# escaped $
`echo text\$text`;
`echo $`;	# ERROR, perl says $name expected or escape with \$
`echo $$`;	# pid
`echo text$$text`;	# perl recognizes $$text

`echo $foo`;		# simple var
`echo text$foo;`;
`echo $foo\n`;	# terminated by \
`echo $$foo`;	# reference $foo = \"baz";
`echo text$$foo;`;
`echo $$$foo`;	# reference $foo = \\"baz"; and so on...
`echo text$$$foo;`;
`echo $$$$$$$$$$$$$$$$$$$foo`;	# still legal...

`echo $ 	foo`;	# still works with additional spaces and tabs
			# also with multiple newlines (and CR too)
			# VT failed, FF worked (consider this unreliable)

`echo ${foo}`;		# bareword style
`echo text${foo}text`;
`echo $ {  foo  }`;	# whitespace behaviour same as above

# almost every operator is used for $-style special variables
# not implemented for now, but checked some cases:

`echo -$\-`;	# outputs "--" where $\ == $OUTPUT_RECORD_SEPARATOR
		# but "$\" fails to parse! perl needs a trailing char
`echo ${`;	# ERROR, no closing brace (future TODO)
`echo $}`;	# not a special variable, works, probably undef var
`echo $``;	`# ERROR, string's delimiter char has priority

`echo $#`;	# ERROR, special var $# was removed in Perl 5.10
`echo $#boo`;	# prints 2, last index of @boo array
`echo text$#boo;`;
`echo $# boo`;	# warning, then 'boo' (no space allowed in between)

# basic variables, these follow identifier rules
`$foo`; `$abc123`; `$_`; `$_abc`; `$_123`; `$a_1`;
`$foo $foo	$foo-$foo+$foo;`;	# non-word char terminates
`$foo $foo	$foo
$foo+$foo;`;			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
`$foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]`;

`echo \@`;		# escaped @
`echo text\@text`;
`echo @`;		# no error! prints as '@'
`echo @@`;		# prints as '@@'
`echo text@@text`;	# perl recognizes @text

`echo @boo`;		# simple array
`echo text@boo;`;
`echo @boo\n`;		# terminated by \
`echo @bo`;		# empty string, probably undef array
`echo @@boo`;		# the @boo is valid, prints '@one two three'
`echo @$boo`;		# valid, prints 'one two three' if $boo='boo';
`echo @$$$boo`;		# valid, same output
`echo text@$$$boo;`;
`echo @$$$$$$$$$$$$$$$$$$$boo`;	# still legal...

`echo @$`;		# empty string, probably undef array
`echo $@boo`;		# nope, prints 'boo' where $@ is a special variable
`echo @  	boo`;	# nope, prints '@  	boo'! whitespace not allowed!

`echo @{boo}`;		# bareword style
`echo @{ boo }`;	# whitespace within {} works, including newlines
`echo @ {boo}`;		# nope, prints '@ {boo}'

# only @_ @+ @- uses operators as second char
`echo -@\-`;		# nope, prints '-@-', not a special var
`echo @{`;		# ERROR, no closing brace (future TODO)
`echo @}`;		# all other bracket chars print as literal chars

# basic variables, these follow identifier rules
`@boo`; `@abc123`; `@_`; `@_abc`; `@_123`; `@a_1`;
`@boo @boo	@boo-@boo+@boo;`;	# non-word char terminates
`@boo @boo	@boo
@boo+@boo;`;			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
`@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]`;

# mixture of adjacent interpolated vars (untested)
`$foo$foo`; `$foo$$$foo`; `$foo$#boo`; `$foo@boo`; `$foo@$$boo`;
`@boo$foo`; `@boo$$$foo`; `@boo$#boo`; `@boo@boo`; `@boo@$$boo`;
`$foo$`; `$foo$$$`; `$foo$#`; `$foo@`; `$foo@$$`;	# adjacent non-vars

#--------------------------------------------------------------------------
# qx{} command (mostly tested samples)
# NOTE: qx{} uses the same codepath as qq{}, the difference is that qx{}
#       does not interpolate when a '' delimiter pair is used
#--------------------------------------------------------------------------

# FOR REFERENCE:
qx!stuff!; qx mstuffm; qx 1stuff1;	# various delimiters
qx(foo); qx[foo]; qx{foo}; qx<foo>;	# 4 kinds of opposite pairs
qx\stuff\; qx\\;			# backslash delimiter

qx|echo \$|;		# escaped $
qx.echo text\$text.;	# prints 'text', that's funny...
qx*echo $*;		# ERROR, perl says $name expected or escape with \$
qx~echo $$~;		# pid
qx~echo text$$text~;	# perl recognizes $$text

qx+echo $foo+;		# simple var
qx _echo text$foo;_;
qx@echo $foo\n@;	# terminated by \
qx(echo $$foo);		# reference $foo = \"baz";
qx<echo text$$foo;>;
qx[echo $$$foo];	# reference $foo = \\"baz"; and so on...
qx{echo text$$$foo;};
qx%echo $$$$$$$$$$$$$$$$$$$foo%;	# still legal...

qx:echo $ 	foo:;	# still works with additional spaces and tabs
			# also with multiple newlines (and CR too)
			# VT failed, FF worked (consider this unreliable)

qx#echo ${foo}#;	# bareword style
qx&echo text${foo}text&;
qx/echo $ { foo }/;	# this sample legal (not fully checked)

qx;echo -$\-;;		# outputs "--" where $\ == $OUTPUT_RECORD_SEPARATOR
			# but "$\" fails to parse! perl needs a trailing char

# almost every operator is used for $-style special variables
# not implemented for now, but checked some cases:

qx(echo ${);		# ERROR, no closing brace (future TODO)
qx(echo $});		# not a special variable, works, probably undef var

qx(echo $#);		# ERROR, special var $# was removed in Perl 5.10
qx(echo $#boo);		# prints 2, last index of @boo array
qx(echo text$#boo;);
qx(echo $# boo);	# warning, then 'boo' (no space allowed in between)

# basic variables, these follow identifier rules
qx($foo); qx($abc123); qx($_); qx($_abc); qx($_123); qx($a_1);
qx($foo $foo	$foo-$foo+$foo;);	# non-word char terminates
qx($foo $foo	$foo
$foo+$foo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qx($foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]);

qx|echo \@|;		# escaped @
qx.echo text\@text.;
qx*echo @*;		# no error! prints as '@'
qx~echo @@~;		# prints as '@@'
qx~echo text@@text~;	# perl recognizes @text

qx+echo @boo+;		# simple array
qx _echo text@boo;_;
qx^echo @boo\n^;	# terminated by \
qx,echo @bo,;		# empty string, probably undef array
qx?echo @@boo?;		# the @boo is valid, prints '@one two three'
qx(echo @$boo);		# valid, prints 'one two three' if $boo='boo';
qx<echo @$$$boo>;	# valid, same output
qx{echo text@$$$boo;};
qx%echo @$$$$$$$$$$$$$$$$$$$boo%;	# still legal...

qx:echo @$:;		# empty string, probably undef array
qx:echo $@boo:;		# nope, prints 'boo' where $@ is a special variable
qx:echo @  	boo:;	# nope, prints '@  	boo'! whitespace not allowed!

qx#echo @{boo}#;	# bareword style
qx&echo @{ boo }&;	# this sample legal (not fully checked)
qx/echo @ {boo}/;	# nope, prints '@ {boo}'

# only @_ @+ @- uses operators as second char
qx;-echo @\-;;		# nope, prints nothing, unclear what echo is doing
qx(echo @{);		# ERROR, no closing brace (future TODO)
qx(echo @});		# all other bracket chars print as literal chars

# basic variables, these follow identifier rules
qx(@boo); qx(@abc123); qx(@_); qx(@_abc); qx(@_123); qx(@a_1);
qx(@boo @boo	@boo-@boo+@boo;);	# non-word char terminates
qx(@boo @boo	@boo
@boo+@boo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qx(@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]);

# mixture of adjacent interpolated vars (untested)
qx($foo$foo); qx($foo$$$foo); qx($foo$#boo); qx($foo@boo); qx($foo@$$boo);
qx(@boo$foo); qx(@boo$$$foo); qx(@boo$#boo); qx(@boo@boo); qx(@boo@$$boo);
qx($foo$); qx($foo$$$); qx($foo$#); qx($foo@); qx($foo@$$);	# adjacent non-vars

# nested delimiters
qx((text)$foo(text));	# var terminated by paired delimiter
qx<<>$foo<>>;
qx{${foo{bar}}};	# legal syntax, dunno meaning

# wordchar delimiters
qx _echo $foo_;		# space separator after 'qx' mandatory
qx 1echo $foo1;		# delimiter is not consumed by interpolated var
qx mecho $foom;

# qx{} does not interpolate when a '' delimiter pair is used
qx'echo $foo';		# prints nothing, $foo used by echo
qx'echo @boo';		# prints '@boo' as expected
qx'echo $#boo';		# prints '0boo', $# used by echo

#--------------------------------------------------------------------------
# // pattern match (mostly tested samples)
#--------------------------------------------------------------------------

# Example test:
print ($foo =~ /$foo/);	# scalar 1 for the match
# - if something 'matches' in the following, it means that the regex
#   matched something in a given string and returned scalar 1

/stuff/c;	# FOR REFERENCE: basic
/multiline string
second line/;	# multiline

/\$/;		# escaped $, matches '$'
/text\$text/;	# matches 'text$text'
/$/;		# regex end of line
/$$/;		# matches $$ (pid)
/text$$text/;	# minimum match 'text', $$text interpolated

/$foo/;		# simple var, matches 'baz'
/text$foo;;/;	# matches 'textbaz;;'
/$foo\n/;	# terminated by \, matches "baz\n"
/$$foo/;	# reference $foo = \"baz";, minimum match 'baz'
/text$$foo;;/;	# minimum match 'textbaz;;'
/$$$foo/;	# reference $foo = \\"baz";, minimum match 'baz'
/text$$$foo;;/;	# minimum match 'textbaz;;'
/$$$$$$$$$$$$$$$$$$$foo/;	# still legal...
				# won't generate an error if $foo = "baz";, but
				# the resulting regex seems to match ''

/$ 	foo/;	# legal, but does not match 'baz'
		# probably not interpolated

/${foo}/;		# bareword style, matches 'baz'
/text${foo}text/;	# matches 'textbaztext'
/$ {  foo  }/;		# no match, probably not interpolated
/${  foo  }/;		# but whitespace within {} works
			# spaces, tabs, multiple lines, VT, FF all work!

# no checking behaviour of special vars in regexes
# not implemented for now, only checked braces:

/${/;		# ERROR, no closing brace (future TODO)

/$#/;		# ERROR, syntax error, no mention of special var $#
/$#boo/;	# matches '2', last index of @boo array
/text$#boo;;/;	# matches 'text2;;'
/$# boo/;	# $# unsupported warning, unlike the syntax error for /$#/
		# matches ' boo'

# basic variables, these follow identifier rules
/$foo/; /$abc123/; /$_/; /$_abc/; /$_123/; /$a_1/;
/$foo $foo	$foo-$foo+$foo;/;	# non-word char terminates
/$foo $foo	$foo
$foo+$foo;/;			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
/$foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]/;

/\@/;		# escaped @, matches '@'
/text\@text/;	# matches 'text@text'
/@/;		# matches '@'
/@@/;		# matches '@@'
/text@@text/;	# minimum match 'text@', @text interpolated

/@boo/;		# simple array, matches 'one two three'
/text@boo;;/;	# matches 'textone two three;;'
/@boo\n/;	# terminated by \, matches "one two three\n"
/@bo/;		# matches anything, probably undef array
/@@boo/;	# the @boo is valid, matches '@one two three'
/@$boo/;	# valid, matches 'one two three' if $boo='boo';
/@$$$boo/;	# valid, same result
/text@$$$boo;;;/;
/@$$$$$$$$$$$$$$$$$$$boo/;	# still legal...

/@$/;		# matches empty string, probably undef array
/$@boo/;	# nope, minimum match 'boo' where $@ is a special variable
/@  	boo/;	# matches '@  	boo', not interpolated

/@{boo}/;	# bareword style, matches 'one two three'
/@{ boo }/;	# whitespace within {} works (barely tested)
/@ {boo}/;	# matches '@ {boo}', not interpolated

/@{/;		# ERROR, no closing brace (future TODO)

# basic variables, these follow identifier rules
/@boo/; /@abc123/; /@_/; /@_abc/; /@_123/; /@a_1/;
/@boo @boo	@boo-@boo+@boo;/;	# non-word char terminates
/@boo @boo	@boo
@boo+@boo;/;			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
/@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]/;

# mixture of adjacent interpolated vars (untested)
/$foo$foo/; /$foo$$$foo/; /$foo$#boo/; /$foo@boo/; /$foo@$$boo/;
/@boo$foo/; /@boo$$$foo/; /@boo$#boo/; /@boo@boo/; /@boo@$$boo/;
/$foo$/; /$foo$$$/; /$foo$#/; /$foo@/; /$foo@$$/;	# adjacent non-vars

# tests for modifier handling in interpolation code
/$foo/c; /@boo/c;

#--------------------------------------------------------------------------
# m{} command (mostly tested samples)
#--------------------------------------------------------------------------

# FOR REFERENCE:
m!stuff!; m mstuffm; m 1stuff1;	# various delimiters
m(foo); m[foo]; m{foo}; m<foo>;	# 4 kinds of opposite pairs
m\stuff\; m\\;			# backslash delimiter

m|\$|;		# escaped $, matches '$'
m.text\$text.;	# matches 'text$text'
m*$*;		# regex end of line
m~$$~;		# matches $$ (pid)
m~text$$text~;	# minimum match 'text', $$text interpolated

m+$foo+;	# simple var, matches 'baz'
m _text$foo;;_;	# matches 'textbaz;;'
m@$foo\n@;	# terminated by \, matches "baz\n"
m($$foo);	# reference $foo = \"baz";, minimum match 'baz'
m<text$$foo;;>;	# minimum match 'textbaz;;'
m[$$$foo];	# reference $foo = \\"baz";, minimum match 'baz'
m{text$$$foo;;};	# minimum match 'textbaz;;'
m%$$$$$$$$$$$$$$$$$$$foo%;	# still legal...
			# won't generate an error if $foo = "baz";, but
			# the resulting regex seems to match ''

m:$ 	foo:;	# legal, but does not match 'baz'
		# probably not interpolated

m#${foo}#;		# bareword style, matches 'baz'
m&text${foo}text&;	# matches 'textbaztext'
m/$ {  foo  }/;		# no match, probably not interpolated
m;${  foo  };;		# but whitespace within {} works
			# spaces, tabs, multiple lines, VT, FF all work!

# no checking behaviour of special vars in regexes
# not implemented for now, only checked braces:

m(/${);		# ERROR, no closing brace (future TODO)

m($#);		# ERROR, syntax error, no mention of special var $#
m($#boo);	# matches '2', last index of @boo array
m(text$#boo;;);	# matches 'text2;;'
m($# boo);	# $# unsupported warning, unlike the syntax error for /$#/
		# matches ' boo'

# basic variables, these follow identifier rules
m($foo); m($abc123); m($_); m($_abc); m($_123); m($a_1);
m($foo $foo	$foo-$foo+$foo;);	# non-word char terminates
m($foo $foo	$foo
$foo+$foo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
m($foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]);

m|\@|;		# escaped @, matches '@'
m.text\@text.;	# matches 'text@text'
m*@*;		# matches '@'
m~@@~;		# matches '@@'
m~text@@text~;	# minimum match 'text@', @text interpolated

m+@boo+;	# simple array, matches 'one two three'
m _text@boo;;_;	# matches 'textone two three;;'
m^@boo\n^;	# terminated by \, matches "one two three\n"
m,@bo,;		# matches anything, probably undef array
m?@@boo?;	# the @boo is valid, matches '@one two three'
m(@$boo);	# valid, matches 'one two three' if $boo='boo';
m<@$$$boo>;	# valid, same result
m{text@$$$boo;;;};
m%@$$$$$$$$$$$$$$$$$$$boo%;	# still legal...

m:@$:;		# matches empty string, probably undef array
m:$@boo:;	# nope, minimum match 'boo' where $@ is a special variable
m:@  	boo:;	# matches '@  	boo', not interpolated

m#@{boo}#;	# bareword style, matches 'one two three'
m&@{ boo }&;	# whitespace within {} works (barely tested)
m/@ {boo}/;	# matches '@ {boo}', not interpolated

m!@{!;		# ERROR, no closing brace (future TODO)

# basic variables, these follow identifier rules
m(@boo); m(@abc123); m(@_); m(@_abc); m(@_123); m(@a_1);
m(@boo @boo	@boo-@boo+@boo;);	# non-word char terminates
m(@boo @boo	@boo
@boo+@boo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
m(@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]);

# mixture of adjacent interpolated vars (untested)
m($foo$foo); m($foo$$$foo); m($foo$#boo); m($foo@boo); m($foo@$$boo);
m(@boo$foo); m(@boo$$$foo); m(@boo$#boo); m(@boo@boo); m(@boo@$$boo);
m($foo$); m($foo$$$); m($foo$#); m($foo@); m($foo@$$);	# adjacent non-vars

# nested delimiters
m((text)$foo(text));	# var terminated by paired delimiter
m<<>$foo<>>;
m{${foo{bar}}};		# legal syntax, dunno meaning

# wordchar delimiters
m _$foo_;		# space separator after 'm' mandatory
m 1$foo1;		# delimiter is not consumed by interpolated var
m m$foom;

# m{} does not interpolate when a '' delimiter pair is used
m'$foo';		# dunno what can match this
m'@boo';		# '@boo'
m'$#boo';		# dunno what can match this

# tests for modifier handling in interpolation code
m!$foo!c; m!@boo!c; m($foo)c; m(@boo)c;

#--------------------------------------------------------------------------
# qr{} command (UNTESTED, BEHAVIOUR IS ASSUMED TO BE IDENTICAL TO m{})
#--------------------------------------------------------------------------

# FOR REFERENCE:
qr!stuff!; qr mstuffm; qr 1stuff1;	# various delimiters
qr(foo); qr[foo]; qr{foo}; qr<foo>;	# 4 kinds of opposite pairs
qr\stuff\; qr\\;			# backslash delimiter

qr|\$|;		# escaped $, matches '$'
qr.text\$text.;	# matches 'text$text'
qr*$*;		# regex end of line
qr~$$~;		# matches $$ (pid)
qr~text$$text~;	# minimum match 'text', $$text interpolated

qr+$foo+;		# simple var, matches 'baz'
qr _text$foo;;_;	# matches 'textbaz;;'
qr@$foo\n@;		# terminated by \, matches "baz\n"
qr($$foo);		# reference $foo = \"baz";, minimum match 'baz'
qr<text$$foo;;>;	# minimum match 'textbaz;;'
qr[$$$foo];		# reference $foo = \\"baz";, minimum match 'baz'
qr{text$$$foo;;};	# minimum match 'textbaz;;'
qr%$$$$$$$$$$$$$$$$$$$foo%;	# still legal...
				# won't generate an error if $foo = "baz";, but
				# the resulting regex seems to match ''

qr:$ 	foo:;	# legal, but does not match 'baz'
		# probably not interpolated

qr#${foo}#;		# bareword style, matches 'baz'
qr&text${foo}text&;	# matches 'textbaztext'
qr/$ {  foo  }/;	# no match, probably not interpolated
qr;${  foo  };;		# but whitespace within {} works
			# spaces, tabs, multiple lines, VT, FF all work!

# no checking behaviour of special vars in regexes
# not implemented for now, only checked braces:

qr(/${);	# ERROR, no closing brace (future TODO)

qr($#);			# ERROR, syntax error, no mention of special var $#
qr($#boo);		# matches '2', last index of @boo array
qr(text$#boo;;);	# matches 'text2;;'
qr($# boo);		# $# unsupported warning, unlike the syntax error for /$#/
			# matches ' boo'

# basic variables, these follow identifier rules
qr($foo); qr($abc123); qr($_); qr($_abc); qr($_123); qr($a_1);
qr($foo $foo	$foo-$foo+$foo;);	# non-word char terminates
qr($foo $foo	$foo
$foo+$foo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qr($foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]);

qr|\@|;		# escaped @, matches '@'
qr.text\@text.;	# matches 'text@text'
qr*@*;		# matches '@'
qr~@@~;		# matches '@@'
qr~text@@text~;	# minimum match 'text@', @text interpolated

qr+@boo+;		# simple array, matches 'one two three'
qr _text@boo;;_;	# matches 'textone two three;;'
qr^@boo\n^;		# terminated by \, matches "one two three\n"
qr,@bo,;		# matches anything, probably undef array
qr?@@boo?;		# the @boo is valid, matches '@one two three'
qr(@$boo);		# valid, matches 'one two three' if $boo='boo';
qr<@$$$boo>;		# valid, same result
qr{text@$$$boo;;;};
qr%@$$$$$$$$$$$$$$$$$$$boo%;	# still legal...

qr:@$:;		# matches empty string, probably undef array
qr:$@boo:;	# nope, minimum match 'boo' where $@ is a special variable
qr:@  	boo:;	# matches '@  	boo', not interpolated

qr#@{boo}#;	# bareword style, matches 'one two three'
qr&@{ boo }&;	# whitespace within {} works (barely tested)
qr/@ {boo}/;	# matches '@ {boo}', not interpolated

qr!@{!;		# ERROR, no closing brace (future TODO)

# basic variables, these follow identifier rules
qr(@boo); qr(@abc123); qr(@_); qr(@_abc); qr(@_123); qr(@a_1);
qr(@boo @boo	@boo-@boo+@boo;);	# non-word char terminates
qr(@boo @boo	@boo
@boo+@boo;);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
qr(@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]);

# mixture of adjacent interpolated vars (untested)
qr($foo$foo); qr($foo$$$foo); qr($foo$#boo); qr($foo@boo); qr($foo@$$boo);
qr(@boo$foo); qr(@boo$$$foo); qr(@boo$#boo); qr(@boo@boo); qr(@boo@$$boo);
qr($foo$); qr($foo$$$); qr($foo$#); qr($foo@); qr($foo@$$);	# adjacent non-vars

# nested delimiters
qr((text)$foo(text));	# var terminated by paired delimiter
qr<<>$foo<>>;
qr{${foo{bar}}};	# legal syntax, dunno meaning

# wordchar delimiters
qr _$foo_;		# space separator after 'qr' mandatory
qr 1$foo1;		# delimiter is not consumed by interpolated var
qr m$foom;

# qr{} does not interpolate when a '' delimiter pair is used
qr'$foo';		# dunno what can match this
qr'@boo';		# '@boo'
qr'$#boo';		# dunno what can match this

# tests for modifier handling in interpolation code
qr!$foo!c; qr!@boo!c; qr($foo)c; qr(@boo)c;

#--------------------------------------------------------------------------
# s{}{} substitution (mostly tested samples)
# NOTE: Interpolation is done in the first (PATTERN) section.
#	The second section (REPLACEMENT) is problematic, since it can
#	either use $1 etc kind of references, or it can be whole Perl
#	expressions with the e/ee modifiers
#--------------------------------------------------------------------------

# Example test (if matched, entire match is substituted, and prints 'doh'):
$_ = '$';
s|\$|doh|;
print "$_\n";

# FOR REFERENCE:
s!stuff!stuff!g; s sstuffsstuffsg; s 1stuff1stuff1g;	# various delimiters
s(stuff)(stuff); s[stuff][stuff];			# 4 kinds of opposite pairs
s{stuff}{stuff}; s<stuff><stuff>;
s(stuff)[stuff]; s{stuff}<stuff>; s[stuff]!stuff!;	# mixed delimiters
s\stuff\stuff\; s\\\;					# backslash delimiter

s|\$|doh|;		# escaped $, matches '$'
s.text\$text.doh.;	# matches 'text$text'
s*$*doh*;		# regex end of line
s~$$~doh~;		# matches $$ (pid)
s~text$$text~doh~;	# minimum match 'text', $$text interpolated

s+$foo+doh+;		# simple var, matches 'baz'
s _text$foo;;_doh_;	# matches 'textbaz;;'
s@$foo\n@doh@;		# terminated by \, matches "baz\n"
s($$foo)(doh);		# reference $foo = \"baz";, minimum match 'baz'
s<text$$foo;;><doh>;	# minimum match 'textbaz;;'
s[$$$foo][doh];		# reference $foo = \\"baz";, minimum match 'baz'
s{text$$$foo;;}{doh};	# minimum match 'textbaz;;'
s%$$$$$$$$$$$$$$$$$$$foo%doh%;	# still legal...
				# won't generate an error if $foo = "baz";, but
				# the resulting regex seems to match ''

s:$ 	foo:doh:;	# legal, but does not match 'baz'
			# probably not interpolated

s#${foo}#doh#;		# bareword style, matches 'baz'
s&text${foo}text&doh&;	# matches 'textbaztext'
s/$ {  foo  }/doh/;	# no match, probably not interpolated
s;${  foo  };doh;;	# but whitespace within {} works
			# spaces, tabs, multiple lines, VT, FF all work!

# no checking behaviour of special vars in regexes
# not implemented for now, only checked braces:

s(/${)(doh);		# ERROR, no closing brace (future TODO)

s($#)(doh);		# ERROR, syntax error, no mention of special var $#
s($#boo)(doh);		# matches '2', last index of @boo array
s(text$#boo;;)(doh);	# matches 'text2;;'
s($# boo)(doh);		# $# unsupported warning, unlike the syntax error for /$#/
			# matches ' boo'

# basic variables, these follow identifier rules
s($foo)(doh); s($abc123)(doh); s($_)(doh); s($_abc)(doh); s($_123)(doh); s($a_1)(doh);
s($foo $foo	$foo-$foo+$foo;)(doh);	# non-word char terminates
s($foo $foo	$foo
$foo+$foo;)(doh);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
s($foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i])(doh);

s|\@|doh|;		# escaped @, matches '@'
s.text\@text.doh.;	# matches 'text@text'
s*@*doh*;		# matches '@'
s~@@~doh~;		# matches '@@'
s~text@@text~doh~;	# minimum match 'text@', @text interpolated

s+@boo+doh+;		# simple array, matches 'one two three'
s _text@boo;;_doh_;	# matches 'textone two three;;'
s^@boo\n^doh^;		# terminated by \, matches "one two three\n"
s,@bo,doh,;		# matches anything, probably undef array
s?@@boo?doh?;		# the @boo is valid, matches '@one two three'
s(@$boo)(doh);		# valid, matches 'one two three' if $boo='boo';
s<@$$$boo><doh>;	# valid, same result
s{text@$$$boo;;;}{doh};
s%@$$$$$$$$$$$$$$$$$$$boo%doh%;	# still legal...

s:@$:doh:;		# matches empty string, probably undef array
s:$@boo:doh:;		# nope, minimum match 'boo' where $@ is a special variable
s:@  	boo:doh:;	# matches '@  	boo', not interpolated

s#@{boo}#doh#;		# bareword style, matches 'one two three'
s&@{ boo }&doh&;	# whitespace within {} works (barely tested)
s/@ {boo}/doh/;		# matches '@ {boo}', not interpolated

s!@{!doh!;		# ERROR, no closing brace (future TODO)

# basic variables, these follow identifier rules
s(@boo)(doh); s(@abc123)(doh); s(@_)(doh); s(@_abc)(doh); s(@_123)(doh); s(@a_1)(doh);
s(@boo @boo	@boo-@boo+@boo;)(doh);	# non-word char terminates
s(@boo @boo	@boo
@boo+@boo;)(doh);			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
s(@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i])(doh);

# mixture of adjacent interpolated vars (untested)
s($foo$foo)(doh); s($foo$$$foo)(doh); s($foo$#boo)(doh); s($foo@boo)(doh); s($foo@$$boo)(doh);
s(@boo$foo)(doh); s(@boo$$$foo)(doh); s(@boo$#boo)(doh); s(@boo@boo)(doh); s(@boo@$$boo)(doh);
s($foo$)(doh); s($foo$$$)(doh); s($foo$#)(doh); s($foo@)(doh); s($foo@$$)(doh);	# adjacent non-vars

# nested delimiters
s((text)$foo(text))(doh);	# var terminated by paired delimiter
s<<>$foo<>><doh>;
s{${foo{bar}}}{doh};		# legal syntax, dunno meaning

# wordchar delimiters
s _$foo_doh_;		# space separator after 'm' mandatory
s 1$foo1doh1;		# delimiter is not consumed by interpolated var
s m$foomdohm;

# m{} does not interpolate when a '' delimiter pair is used
s'$foo'doh';		# dunno what can match this
s'@boo'doh';		# '@boo'
s'$#boo'doh';		# dunno what can match this

# tests for modifier handling in interpolation code
s!$foo!doh!c; s!@boo!doh!c;
s($foo)(doh)c; s(@boo)(doh)c;
s{$foo}  {doh}c; s{@boo}  {doh}c;

# REPLACEMENT segment should not have any interpolation highlighting
s!stuff!$foo!; s!stuff!$#foo!; s!stuff!@boo!;

#--------------------------------------------------------------------------
# <<EOF here-doc (TODO)
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# non-interpolated checks: these should NOT have any interpolation!
#--------------------------------------------------------------------------

'foo $foo $#bar @boo boo';		# literal
q{foo $foo $#bar @boo boo};
q"foo $foo $#bar @boo boo";
qw{foo $foo $#bar @boo boo};		# word list
qw"foo $foo $#bar @boo boo";
tr{foo $foo $#bar @boo boo}{baz};	# transliteration
tr"foo $foo $#bar @boo boo"baz";
y{foo $foo $#bar @boo boo}{baz};
y"foo $foo $#bar @boo boo"baz";

<<'EOF';	# single quoted HEREDOC
foo $foo $#bar @boo boo
EOF
<<\EOF;		# backslashed HEREDOC
foo $foo $#bar @boo boo
EOF

#--------------------------------------------------------------------------
# end of test file
#--------------------------------------------------------------------------
