package Local::Pod::Xhtml;
use 5.008008;
use parent 'Pod::Xhtml';

sub textblock {
    my ($parser, $paragraph, $line_num, $pod_para) = @_;
    {
        my @children = $parser->parse_tree->children;
        my $last = pop @children;
        $paragraph =~ s[\A (\S+)][C<$1>]msx if $last->raw_text =~ /\A=head1 NAME/ms;
        # wraps module name in a formatting code (helps spellchecking), thus:
        #       =head1 NAME
        #
        #       Foo::Bar - quux
        # becomes
        #       =head1 NAME
        #
        #       C<Foo::Bar> - quux
    }
    my $ptree = $parser->parse_text( $paragraph, $line_num );
    $pod_para->parse_tree( $ptree );
    $parser->parse_tree->append( $pod_para );
}

sub _setTitle {
    my ($self, $paragraph) = @_;

    {
        $paragraph =~ s|\A <code>(\S+)</code>|$1|msx;
        # undo the first <code/> wrapper for the <title/> element content
    }

    if ($paragraph =~ m/^(.+?) - /) {
        $self->{doctitle} = $1;
    } elsif ($paragraph =~ m/^(.+?): /) {
        $self->{doctitle} = $1;
    } elsif ($paragraph =~ m/^(.+?)\.pm/) {
        $self->{doctitle} = $1;
    } else {
        $self->{doctitle} = substr($paragraph, 0, 80);
    }
    $self->{titleflag} = 0;
}

1;
