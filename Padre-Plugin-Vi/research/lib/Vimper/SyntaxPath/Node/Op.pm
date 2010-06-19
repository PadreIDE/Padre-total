package Vimper::SyntaxPath::Node::Op;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;

extends 'Vimper::SyntaxPath::Node';

method to_string  { 'op' }
method must_merge { 1 }

1;
