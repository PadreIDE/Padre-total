package Vimper::GraphUtil;

package Graph;
use strict;
use warnings;

sub get_label       { $_[0]->get_vertex_attribute($_[1], 'label') }
sub set_label       { $_[0]->set_vertex_attribute($_[1], 'label', $_[2]) }
sub append_to_label { $_[0]->set_label($_[1], $_[0]->get_label($_[1]). $_[2]) }

1;
