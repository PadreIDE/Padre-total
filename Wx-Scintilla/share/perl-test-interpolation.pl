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
qq{};	# 		[1]		SCE_PL_STRING_QQ	SCE_PL_STRING_QQ_VAR
``;	# command			SCE_PL_BACKTICKS	SCE_PL_BACKTICKS_VAR
qx{};	# 		[1]		SCE_PL_STRING_QX	SCE_PL_STRING_QX_VAR
//;	# pattern match    [2]		SCE_PL_REGEX		SCE_PL_REGEX_VAR
m{};	# 		[1][2]		      "
qr{};	# pattern 	[1]		SCE_PL_STRING_QR	SCE_PL_STRING_QR_VAR
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
qw{};	# word list			SCE_PL_STRING_QW
tr{}{};	# transliteration [4]		SCE_PL_REGSUBST
y{}{};	# transliteration [4]		SCE_PL_REGSUBST

# [4] interpolated only if wrapped in an eval() e.g. eval("tr{}{}")
#     i.e. using "string" interpolation, so no special treatment necessary

#--------------------------------------------------------------------------
# Limitations of preliminary variable interpolation implementation:
# ((1)-(4) may be considered for future implementation)
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
# "" double-quoted literal (tested samples)
#--------------------------------------------------------------------------

"basic"		# FOR REFERENCE: basic
"multiline string
second line"	# multiline

"\$"		# escaped $
"text\$text"
"$"		# ERROR, perl says $name expected or escape with \$
"$$"		# pid
"text$$text"	# perl recognizes $$text

"$foo"		# simple var
"text$foo;;"
"$foo\n"	# terminated by \
"$$foo"		# reference $foo = \"baz";
"text$$foo;;"
"$$$foo"	# reference $foo = \\"baz"; and so on...
"text$$$foo;;"
"$$$$$$$$$$$$$$$$$$$foo"	# still legal...

"$ 	foo"	# still works with additional spaces and tabs
		# also with multiple newlines (and CR too)
		# VT failed, FF worked (consider this unreliable)

"${foo}"	# bareword style
"text${foo}text"
"$ {  foo  }"	# whitespace behaviour same as above

# almost every operator is used for $-style special variables
# not implemented for now, but checked some cases:

"-$\-"		# outputs "--" where $\ == $OUTPUT_RECORD_SEPARATOR
		# but "$\" fails to parse! perl needs a trailing char
"${"		# ERROR, no closing brace (future TODO)
"$}"		# not a special variable, works, probably undef var
"$""		"# ERROR, string's delimiter char has priority

"$#"		# ERROR, special var $# was removed in Perl 5.10
"$#boo"		# prints 2, last index of @boo array
"text$#boo;;"
"$# boo"	# ERROR, no space allowed in between

# basic variables, these follow identifier rules
"$foo" "$abc123" "$_" "$_abc" "$_123" "$a_1"
"$foo $foo	$foo-$foo+$foo;"	# non-word char terminates
"$foo $foo	$foo
$foo+$foo;"			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
"$foo[0]$foo{key}$foo->{k}$foo{k}[i]$foo->{k}[i]"

"\@"		# escaped @
"text\@text"
"@"		# no error! prints as '@'
"@@"		# prints as '@@'
"text@@text"	# perl recognizes @text

"@boo"		# simple array
"text@boo;;"
"@boo\n"	# terminated by \
"@bo"		# empty string, probably undef array
"@@boo"		# the @boo is valid, prints '@one two three'
"@$boo"		# valid, prints 'one two three' if $boo='boo';
"@$$$boo"	# valid, same output
"text@$$$boo;;;"
"@$$$$$$$$$$$$$$$$$$$boo"	# still legal...

"@$"		# empty string, probably undef array
"$@boo"		# nope, prints 'boo' where $@ is a special variable
"@  	boo"	# nope, prints '@  	boo'! whitespace not allowed!

"@{boo}"	# bareword style
"@{ boo }"	# whitespace within {} works, including newlines
"@ {boo}"	# nope, prints '@ {boo}'

# the special variables for @ are:
@_ @F @INC @+ @- @ARGV
# only @_ @+ @- uses operators as second char
"-@\-"		# nope, prints '-@-', not a special var
"@{"		# ERROR, no closing brace (future TODO)
"@}"		# all other bracket chars print as literal chars

# basic variables, these follow identifier rules
"@boo" "@abc123" "@_" "@_abc" "@_123" "@a_1"
"@boo @boo	@boo-@boo+@boo;"	# non-word char terminates
"@boo @boo	@boo
@boo+@boo;"			# multiline

# subscripted variable samples (untested)
# highlighting of subscript portion not implemented yet
"@boo[0]@boo{key}@boo->{k}@boo{k}[i]@boo->{k}[i]"

# mixture of adjacent interpolated vars (untested)
"$foo$foo" "$foo$$$foo" "$foo$#boo" "$foo@boo" "$foo@$$boo"
"@boo$foo" "@boo$$$foo" "@boo$#boo" "@boo@boo" "@boo@$$boo"

#--------------------------------------------------------------------------
# qq{} literal (tested samples)
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
qq($# boo);	# ERROR, no space allowed in between

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

# nested delimiters
qq((text)$foo(text));	# var terminated by paired delimiter
qq<<>$foo<>>;
qq{${foo{bar}}};	# legal syntax, dunno meaning

# char delimiters
qq _$foo_;		# space separator after 'qq' mandatory
qq 1$foo1;		# delimiter is not consumed by interpolated var
qq m$foom;

#--------------------------------------------------------------------------
#
#--------------------------------------------------------------------------




#--------------------------------------------------------------------------
# end of test file
#--------------------------------------------------------------------------
