package Padre::Pod::Viewer;
use strict;
use warnings;

our $VERSION = '0.01';

use Wx qw(wxOK wxCENTRE wxVERSION_STRING);
use Wx::Html;

use base 'Wx::HtmlWindow';

use File::Spec::Functions qw(catfile catdir);
use Pod::Simple::HTML;
use Pod::POM;
use Pod::POM::View::HTML;
use Config;

our @pages;


=head2 module_to_path

Given the name of a module (Module::Name) or a pod file without the
.pod extension will try to locate it in @INC and return the full path.

If no file found, returns undef.


=cut
sub module_to_path {
    my ($self, $module) = @_;

    my $file = $module;
    $file =~ s{::}{/}g;
    my $path;

    foreach my $dir (catdir($Config{privlib}, 'pod'), @INC) {
        my $fpath = catfile($dir, $file);
        if (-e "$fpath.pm") {
            $path = "$fpath.pm";
        } elsif (-e "$fpath.pod") {
            $path = "$fpath.pod";
        }
    }

    return $path;
}


sub display {
    my ($self, $module) = @_;

    my $path = $self->module_to_path($module);

#    my $html;
#    my $parser = Pod::Simple::HTML->new;
#    $parser->output_string( \$html );
#    $parser->parse_file($path);

    #my $parser = Pod::POM->new();
    #my $pom = $parser->parse($path);
    #my $html = Pod::POM::View::HTML->print($pom);
    #my $html = Padre::Pod::Viewer::View->print($pom);
    #print $html;

    my $parser = Padre::Pod::Viewer::POD->new;
    $parser->start_html;
    $parser->parse_from_file($path);
    my $html = $parser->get_html;
#    print $html;

    $self->SetPage($html);

    return $self;    
}

sub OnLinkClicked {
    my ( $self, $event ) = @_;
    my $href = $event->GetHref;
    if ($href =~ m{^http://}) {
        # launch real web browser to new page
        return;
    }
    my $path = $self->module_to_path($href);
    if ($path) {
        $main::app->add_to_recent('pod', $href);
        $self->display($href);
    } 

    return;
}


package Padre::Pod::Viewer::View;
use base 'Pod::POM::View::HTML';

sub _view_l {
    my ($self, $item) = @_;
    return '<h1>',
           $item->title->present($self),
           "</h1>\n",
           $item->content->present($self);
}

package Padre::Pod::Viewer::POD;
use base 'Pod::Parser';

my $html;

sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;
    my %h = (
        head1 => 'h1',
        head2 => 'h2',
    );
    $paragraph =~ s/^\s*\n$//gm;
    if ($h{$command}) {
        chomp $paragraph;
        $html .= "<$h{$command}>$paragraph</$h{$command}>\n";
    } elsif ($command eq 'over') {
        $html .= "<ul>\n";
    } elsif ($command eq 'item') {
        $paragraph = _internals($paragraph);
        $html .= "<li>$paragraph</li>\n";
    } elsif ($command eq 'back') {
        $html .= "</ul>\n";
    } else {
        #warn "Unhandled command: '$command'\n";
    }
    # begin
    # end
    # for
    return;
}
sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;
    $paragraph =~ s/^\s*\n$//gm;
    $html .= "<pre>\n$paragraph</pre>\n";
    return;
}
sub textblock {
    my ($parser, $paragraph, $line_num) = @_;
    $paragraph =~ s/^\s*\n$//gm;
    $paragraph = _internals($paragraph);
    $html .= "<p>\n$paragraph</p>\n";
    return;
}
sub _internals {
    my ($paragraph) = @_;
    $paragraph =~ s{B<([^>]*)>}{<b>$1</b>}g;
    $paragraph =~ s{C<([^>]*)>}{<b>$1</b>}g;
    $paragraph =~ s{I<([^>]*)>}{<i>$1</i>}g;
    $paragraph =~ s{L<([^>]*)>}{<a href="$1">$1</a>}g;
    return $paragraph;
}

#sub interior_sequence {
#    my ($parser, $seq_command, $seq_argument) = @_;
#    #return qq(<b>$seq_argument</b>)          if ($seq_command eq 'B');
#    #return qq(<b>$seq_argument</b>)          if ($seq_command eq 'C');
#    #return qq(<i>$seq_argument</i>)          if ($seq_command eq 'I');
#    #return qq(<a href="">$seq_argument</a>)  if ($seq_command eq 'L');
#    warn "Unhandled sequence: '$seq_command'\n";
#    return '';
#}

sub start_html {
    $html = '';
}
sub get_html {
    return $html;
}

1;


