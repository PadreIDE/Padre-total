#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 25+25;
use threads;
use threads::shared;
use Padre::Task;
use vars '$TestClass'; # secret class name

sub fake_execute_task {
	my $class = shift;
	ok($class->can('new'), "task can be constructed");
	my $task = $class->new();
	isa_ok($task, 'Padre::Task');
	isa_ok($task, $class);
	ok($task->can('prepare'));
	
	$task->prepare();
	my $string;
	$task->serialize(\$string);
	ok(defined $string);

	my $recovered = Padre::Task->deserialize( \$string );
	ok(defined $recovered);
	isa_ok($recovered, 'Padre::Task');
	isa_ok($recovered, $class);
	is_deeply($recovered, $task);
	
	$recovered->run();
	$string = undef;
	$recovered->serialize(\$string);
	ok(defined $string);

	my $final = Padre::Task->deserialize( \$string );
	ok(defined $final);
	isa_ok($recovered, 'Padre::Task');
	isa_ok($recovered, $class);
	is_deeply($final, $recovered);
	$final->finish();
}

package Padre::Task::Test;
use base 'Padre::Task';

sub prepare {
	my $self = shift;
	Test::More::isa_ok( $self, "Padre::Task" );
	Test::More::isa_ok( $self, $main::TestClass );
	$self->{msg} = "query";
}

sub run {
	my $self = shift;
	Test::More::isa_ok( $self, "Padre::Task" );
	Test::More::isa_ok( $self, $main::TestClass );
	Test::More::is( $self->{msg}, "query", "message received in worker" );
	Test::More::ok( !exists $self->{_process_class}, "_process_class was cleaned" );
	$self->{answer} = 'succeed';
}

sub finish {
	my $self = shift;
	Test::More::isa_ok( $self, "Padre::Task" );
	Test::More::isa_ok( $self, $main::TestClass );
	Test::More::is( $self->{msg}, "query", "message survived worker" );
	Test::More::is( $self->{answer}, "succeed", "message from worker" );
	Test::More::ok( !exists $self->{_process_class}, "_process_class was cleaned" );
}

package main;
$TestClass = "Padre::Task::Test";
fake_execute_task($TestClass);

my $subclass = Padre::Task->subclass(
	class => 'Padre::Task::OnTheFlyTest',
	methods => {
		run     => \&Padre::Task::Test::run,
		prepare => \&Padre::Task::Test::prepare,
		finish  => \&Padre::Task::Test::finish,
	},
);

$TestClass = $subclass;
fake_execute_task($subclass);




__END__

