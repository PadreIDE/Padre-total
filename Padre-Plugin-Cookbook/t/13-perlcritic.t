#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);
use Data::Printer;
use Carp;

eval { require Test::Perl::Critic; };
if ($EVAL_ERROR) {
	my $msg = 'Test::Perl::Critic required to criticise code';
	plan( skip_all => $msg );
}

use Test::Perl::Critic (
	-severity => 3,
	-verbose  => 4,
	-exclude  => [ 'RequireRcsKeywords', ],
);

# use Test::More tests => 1;

my @DIRECTORIES = qw(
	lib/Padre/Plugin/Cookbook/Recipe01
	lib/Padre/Plugin/Cookbook/Recipe02
	lib/Padre/Plugin/Cookbook/Recipe03
);

# p @DIRECTORIES;

# all_critic_ok( );
all_critic_ok(@DIRECTORIES);

# my $file = 'lib/Padre/Plugin/Cookbook/Cookbook.pm';
# p $file;
#
# carp qq{"$file" does not exist} if not -f $file;

# critic_ok( $file );

# [     -severity => 1,
# -verbose  => 4,
# -exclude  => [ 'RequireRcsKeywords', ],]);



done_testing();




