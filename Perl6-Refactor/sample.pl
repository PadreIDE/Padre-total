use v6;

class Foo;

# a comment
my $a = prompt "Please type a number:";
if ($a) {
	if ($a >= 0) {
		say "your number is positive";
	} else {
		say "your number is negative";
	}
} else {
	say "You didnt provide anything";
}