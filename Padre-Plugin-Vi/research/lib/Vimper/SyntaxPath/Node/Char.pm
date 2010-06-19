package Vimper::SyntaxPath::Node::Char;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Method::Signatures;
use MooseX::Has::Sugar;

extends 'Vimper::SyntaxPath::Node';

method to_string      { 'char' }
method must_not_merge { 1 }

1;
