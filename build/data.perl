## Brutal but effective, add your data as perl to the template stash
# if you get it wrong - simple syntax mistakes are caught early.

my $stash = {
	navigation => [
		{'Home' => '/index.html'},
		{'Developers' => '/developers.html'},
		{'Translators'=> '/translators.html'},
		{'Trac' => 'trac/'},
		{'Blogs' => 'http://blogs.padre.perlide.org'},
		{'About'=> '/about.html'},
	],
};