package Padre::Plugin::PerlTidy;
use strict;
use warnings;
use Perl::Tidy;

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.01';

=head1 NAME

Padre::Plugin::PerlTidy - Format perl files using Perl::Tidy

=head1 SYNOPIS

This is an experimental version of the plugin using the experimental
plugin interface of Padre 0.03_02 

After installation there should be a menu item Perl Tidy

Clicking on that menu item while a .pl or pm file is in view will reformat the file
using PerlTidy

=cut


my @menu = (
    ["Perl Tidy", \&on_run],
);

sub menu {
    my ($self) = @_;
    return @menu;
}

sub on_run {
    my ($self, $event) = @_;
    
    my $src = $self->get_page_text;

    my $output;
    do {
        local @ARGV;
        perltidy( source => \$src, destination => \$output);
    };
    
    $self->set_page_text($output);
    
    return;
}

=head1 COPYRIGHT

(c) 2008 Patrick Donelan http://www.patspam.com

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=cut

1;
