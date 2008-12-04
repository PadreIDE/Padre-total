#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 25+25;
use threads;
use threads::shared;
use Padre::Task;
use lib '.';
use t::lib::Padre::Task::Test;

use vars '$TestClass'; # secret class name

# TODO: test with real threads

sub fake_execute_task {
	my $class = shift;
	ok($class->can('new'), "task can be constructed");
	my $task = $class->new( main_thread_only => "not in sub thread" );
	isa_ok($task, 'Padre::Task');
	isa_ok($task, $class);
	ok($task->can('prepare'), "can prepare");
	
	$task->prepare();
	my $string;
	$task->serialize(\$string);
	ok(defined $string, "serialized form defined");

	my $recovered = Padre::Task->deserialize( \$string );
	ok(defined $recovered, "recovered form defined");
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

