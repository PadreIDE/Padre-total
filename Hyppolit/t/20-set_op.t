use Test::More tests => 3;

use Hyppolit;

package TestSpace;

sub mode {
	my $self = shift;
	$self{key} = shift; # channel
	$self{action} = shift; # +o nick
}

sub debug {
	my $self = shift;
	$self{debug} = shift;
}

package main;

my $object = bless {}, 'TestSpace';

Hyppolit::set_op($object,'foo','bar');
ok(ref($object->{key}) eq '','foo: Check channel ref');
ok($object->{key} eq 'foo','foo: Check channel');
ok($object->{action} eq '+o bar','foo: Check action');
ok($object->{debug} =~ /op bar foo/,'foo: Check debug');

Hyppolit::set_op($object,['testchan'],'cafe');
ok(ref($object->{key}) eq '','testchan: Check channel ref');
ok($object->{key} eq 'testchan','testchan: Check channel');
ok($object->{action} eq '+o cafe','testchan: Check action');
ok($object->{debug} =~ /op cafe testchan/,'testchan: Check debug');
