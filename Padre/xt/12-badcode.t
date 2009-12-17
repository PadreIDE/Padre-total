#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan( skip_all => 'Needs DISPLAY' );
		exit(0);
	}
}
use File::Find::Rule;
use PPI::Document;

# Calculate the plan
my %modules = map {
	my $class = $_;
	$class =~ s/\//::/g;
	$class =~ s/\.pm$//;
	$class => "lib/$_"
} File::Find::Rule->relative->name('*.pm')->file->in('lib');
plan( tests => scalar( keys %modules ) * 8 );

# Compile all of Padre
use File::Temp;
use POSIX qw(locale_h);
$ENV{PADRE_HOME} = File::Temp::tempdir( CLEANUP => 1 );
foreach my $module ( sort keys %modules ) {
	require_ok($module);
	$module->import();
	ok( $module->VERSION, "$module: Found \$VERSION" );
}

# list of non-Wx modules still having Wx code
my %TODO = map {$_ => 1} qw(
	Padre::Action::Plugins
	Padre::Action::Queue
	Padre::Action::Refactor
	Padre::Action::Search
	Padre::Document
	Padre::Locale
	Padre::MimeTypes
	Padre::Plugin
	Padre::Plugin::Devel
	Padre::Plugin::My
	Padre::PluginManager
	Padre::Service
	Padre::Splash
	Padre::Task::LaunchDefaultBrowser
	Padre::Task::Outline
	Padre::Task::PPI::FindUnmatchedBrace
	Padre::Task::PPI::FindVariableDeclaration
	Padre::Task::PPI::IntroduceTemporaryVariable
	Padre::Task::PPI::LexicalReplaceVariable
	Padre::Task::SyntaxChecker
	Padre::TaskManager

	Padre::Task::Examples::WxEvent
);

foreach my $module ( sort keys %modules ) {

	my $content = read_file($modules{$module});

	# checking if only modules with Wx in their name depend on Wx
	if ($module =~ /^Padre::Wx/ or $module =~ /^Wx::/) {
		my $Test = Test::Builder->new;
		$Test->skip("$module is a Wx module");
	} else {
		my ($error) = $content =~ m/^use\s+.*Wx.*;/gmx;
		my $Test = Test::Builder->new;
		if ($TODO{$module}) {
			$Test->todo_start("$module should not contain Wx but it still does");
		}
		ok(!$error, "$module does not use Wx") or diag $error;
		if ($TODO{$module}) {
			$Test->todo_end;
		}
	}

	ok($content !~ /\$DB\:\:single/,$module.' uses $DB::Single - please remove before release');

	# Load the document
	my $document = PPI::Document->new(
		$modules{$module},
		readonly => 1,
	);
	ok( $document, "$module: Parsable by PPI" );
	unless ($document) {
		diag( PPI::Document->errstr );
	}

	# If a method has a current method, never use Padre::Current directly
	SKIP: {
		unless (eval { $module->can('current') }
			and $module ne 'Padre::Current'
			and $module ne 'Padre::Wx::Role::MainChild' )
		{
			skip( "No ->current method", 1 );
		}
		my $good = !$document->find_any(
			sub {
				$_[1]->isa('PPI::Token::Word') or return '';
				$_[1]->content eq 'Padre::Current' or return '';
				my $arrow = $_[1]->snext_sibling or return '';
				$arrow->isa('PPI::Token::Operator') or return '';
				$arrow->content eq '->' or return '';
				my $method = $arrow->snext_sibling or return '';
				$method->isa('PPI::Token::Word') or return '';
				$method->content ne 'new' or return '';
				return 1;
			}
		);
		ok( $good, "$module: Don't use Padre::Current when ->current is possible" );
	}

	# If a method has an ide or main method, never use Padre->ide directly
	SKIP: {
		unless (
			eval { $module->can('ide') or $module->can('main') }

			#			and $module ne 'Padre::Wx::Dialog::RegexEditor'
			and $module ne 'Padre::Current'
			)
		{
			skip( "$module: No ->ide or ->main method", 1 );
		}
		my $good = !$document->find_any(
			sub {
				$_[1]->isa('PPI::Token::Word') or return '';
				$_[1]->content eq 'Padre' or return '';
				my $arrow = $_[1]->snext_sibling or return '';
				$arrow->isa('PPI::Token::Operator') or return '';
				$arrow->content eq '->' or return '';
				my $method = $arrow->snext_sibling or return '';
				$method->isa('PPI::Token::Word') or return '';
				$method->content eq 'ide' or return '';
				return 1;
			}
		);
		ok( $good, "$module: Don't use Padre->ide when ->ide or ->main is possible" );
	}

	# Advoid expensive regexp result variables
	SKIP: {
		if ( $module eq 'Padre::Wx::Dialog::RegexEditor' ) {
			skip( q($' or $` or $& is in the pod of this module), 1 );
		}
		ok( $document->serialize !~ /[^\$\'\"]\$[\&\'\`]/, $module . ': Uses expensive regexp-variable $&, $\' or $`' );
	}
}

sub read_file {
	my $file = shift;
	open my $fh, '<', $file or die "Could not read '$file': $!";
	local $/ = undef;
	return <$fh>;
}

1;
