#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 15;
use Test::NoWarnings;
use File::Spec::Functions ':ALL';
use t::lib::Test;
use FBP;
use Padre::Plugin::FormBuilder::Perl;

# Find the sample files
my $input  = 'Padre-Plugin-FormBuilder.fbp';
ok( -f $input,  "Found test file $input"  );

# Load the sample file
my $fbp = FBP->new;
isa_ok( $fbp, 'FBP' );
ok( $fbp->parse_file($input), '->parse_file ok' );

# Create the generator object
my $project = $fbp->find_first(
	isa => 'FBP::Project',
);
isa_ok( $project, 'FBP::Project' );

# Test with default options
compile_all(
	project => $project,
);

# Test with nocritic on
compile_all(
	project  => $project,
	nocritic => 1,
);

# Test with encapsulate on
compile_all(
	project     => $project,
	encapsulate => 1,
);





######################################################################
# Support Functions

my $counter = 0;

sub compile_all {
	my %args = ( @_, package => 'My::Form::Name' . ++$counter );
	my $code = Padre::Plugin::FormBuilder::Perl->new(%args);
	isa_ok( $code, 'Padre::Plugin::FormBuilder::Perl' );

	foreach my $form ( $args{project}->forms ) {
		my $name = $form->name;
		my $code = $code->form_class($form);
		compiles( $code, 'Project class compiled' );
	}	
}
