package Padre::Wx::Dialog::PluginManager2;

# Second-generation plugin manager

use strict;
use warnings;
use Carp                    ();
use URI::file               ();
use Params::Util            qw{_INSTANCE};
use Padre::Util             ();
use Padre::Wx               ();
use Padre::Wx::Dialog::HTML ();

our $VERSION = '0.27';
our @ISA     = 'Padre::Wx::Dialog::HTML';

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new( @_,
		title => Wx::gettext('Plugin Manager'),
	);

	unless ( _INSTANCE($self->{manager}, 'Padre::PluginManager') ) {
		Carp::croak("Missing or invalid Padre::PluginManager object");
	}

	return $self;
}

# Render the content of the dialog based on the plugins
sub html {
	my $self    = shift;
	my $manager = $self->{manager};

	my @rows = ();
	my $file = Padre::Util::sharefile('plugin.gif');
	unless ( -f $file ) {
		die "Failed to find $file";
	}
	my $icon = URI::file->new( $file )->as_string;
	foreach my $name ( $manager->plugin_names ) {
		my $plugin   = $manager->_plugin($name);
		my $namehtml = "<b>"  . $plugin->plugin_name . "</b>";
		my $cellhtml = "<td bgcolor='#FFFFFF'>"
			. $namehtml
			. "&nbsp;&nbsp;&nbsp;"
			. $plugin->version
			. "</td>";
		my $rowhtml  = "<tr>"
			. "<td width='52'><img src='$icon' height='32' width='32'></td>"
			. $cellhtml
			. "</tr>";
		push @rows, $rowhtml;
	}

	# Wrap in the overall page
	my $rowshtml = join( "\n", @rows );
	return <<"END_HTML";
<html>
<head>
</head>
<body bgcolor="#CCCCCC">
<table border="1" cellpadding="10" cellspacing="0" width="100%">
$rowshtml
</table>
</body>
</html>
END_HTML
}

1;
# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
