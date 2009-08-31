package Local::Padre::Website::Builder;
use 5.008008;
use utf8;
use strict;
use warnings FATAL => 'all';
use parent 'Module::Build';
use File::Copy qw(copy);
use File::Next qw();
use HTML::TreeBuilder::XPath qw();
use List::Util qw(reduce);
use LWP::Simple qw(get);
use Path::Class qw(dir file);
use Template qw();
use Text::Unaccent::PurePerl qw(unac_string);
use Time::Piece qw(localtime);
use YAML::Tiny qw(LoadFile);
use autodie qw(:all copy);

{
    our %nerfed_methods =    # not applicable for building a website
      map { "ACTION_$_" => 1 },
      qw(code dist distcheck distclean distdir distmeta distsign disttest docs
      html manifest manpages pardist ppd ppmdist skipcheck testcover testpod
      testpodcoverage versioninstall);
    eval "sub $_ {}" for keys %nerfed_methods;

    sub known_actions {
        my ($self) = @_;
        my %actions;
        no strict 'refs';
        foreach my $class ($self->super_classes) {
            foreach (keys %{$class . '::'}) {
                next
                  if $nerfed_methods{$_};   # so ACTION_help works as intended
                $actions{$1}++ if /^ACTION_(\w+)/;
            }
        }
        return wantarray ? sort keys %actions : \%actions;
    }
}

sub dist_name    {return 'Padre website'}
sub dist_version {return localtime->ymd}

sub ACTION_build {
    my ($self) = @_;
    $self->depends_on(qw(copy_static_files process_templates));
    print "You can run ./Build test now.\n";
}

sub ACTION_copy_static_files {
    my ($self) = @_;
    my $documentroot = dir($self->config_data('sourcedir'), 'documentroot');

    my $iter = File::Next::files({
            descend_filter => sub {$_ ne '.svn'}
        },
        $documentroot
    );

    while (defined(my $fullpath = $iter->())) {
        my $target_dir = dir($self->destdir,
            file($fullpath)->relative($documentroot)->parent);
        $target_dir->mkpath;
        copy $fullpath, $target_dir;
    }
}

sub ACTION_process_templates {
    my ($self) = @_;

    my $include_path = dir($self->config_data('sourcedir'), 'tt');
    my $tt = Template->new({
            INCLUDE_PATH => $include_path,
            POST_CHOMP   => 1,                # cleanup whitespace
            EVAL_PERL    => 0,                # evaluate Perl code blocks
            OUTPUT_PATH  => $self->destdir,
            FILTERS      => {
                'id_attr' => sub {
                    my ($text)    = @_;
                    my ($rewrite) = unac_string $text;    # list context pls!
                    $rewrite =~ s/\s+/_/g;
                    $rewrite;
                },
            },
        });

    # older version of YAML::Tiny return list ??
    my ($stash) = LoadFile file($self->config_data('sourcedir'), qw(data stash.yml));

    $stash->{screenshots_xml} = '<div/>';    # FIXME $self->_scrape_screenshots;
    $stash->{build_date} = $self->dist_version;
    $stash->{developers}
      = $self->_read_people($stash->{developers}, 'developers');
    $stash->{translators}
      = $self->_read_people($stash->{translators}, 'translators');

    # recursive templates structure now supported
    {
        my $templates_dir = dir($include_path, 'pages');
        my $iter = File::Next::files({
                file_filter => sub {/\.html \z/msx}
            },
            $templates_dir
        );
        while (defined(my $template_file = $iter->())) {
            $tt->process(
                file($template_file)->relative($include_path)->stringify,
                $stash,
                file($template_file)->relative($templates_dir)->stringify,
                {binmode => ':utf8'},
            ) or die $tt->error;
        }
    }
}

sub ACTION_install {
    my ($self) = @_;
    print "./Build install does nothing yet. Fix me!\n";

    # system qw(rsync -a), $self->destdir, 'padre.perlide.org:';
    # or something like that.
}

sub _scrape_screenshots {

    # scrape the wiki page to keep screenshots in sync
    my $screenshots_xml;
    unless ($screenshots_xml
        = get 'http://padre.perlide.org/trac/wiki/Screenshots') {
        die "could not get the screenshots wiki page\n";
    }
    my $tree = HTML::TreeBuilder::XPath->new_from_content($screenshots_xml);
    my @result_nodes;
    my %seen_version;
    for my $node (
        $tree->findnodes('/html/body/div[3]/div[2]/div/*')->get_nodelist) {
        next if 'h1' eq $node->tag;    # skip page header
        if ('h2' eq $node->tag) {
            my ($version) = [$node->content_list]->[0] =~ /(\d+\.\d+)/;
            if ($version && !exists $seen_version{$version}) {
                $node->attr('id', "v$version");    # must start with letter
                $seen_version{$version} = undef;
            } else {
                $node->attr('id', undef);
            }
            push @result_nodes, $node;
            next;
        }
        if ('p' eq $node->tag) {
            if (ref [$node->content_list]->[0]) {    # has children
                my ($img) = [$node->content_list]->[0]->content_list; # /p/a/img
                $img->attr('title', undef);
                $img->attr('alt',   '');
                push @result_nodes, $img;
            } else {    # has only text
                push @result_nodes, $node;    # /p
            }
        }
    }
    no warnings 'once';    # stupid Perl forgets about $a $b exemption
    return reduce {$a . $b} map {$_->as_XML} @result_nodes;    # XML string
}

# TODO: add some error checking and data validation (correct sections? correct fields ?)
sub _read_people {
    my ($self, $list, $dir) = @_;

    my @developers;
    foreach my $f (@$list) {
        my $file = file($self->config_data('sourcedir'), 'data', $dir, "$f.ini");
        open my $fh, '<:utf8', $file;
        my $section;
        my %data;
        $data{nickname} = $f;
        while (my $line = <$fh>) {
            if ($line =~ /^\[([^\]]+)\]/) {
                $section = $1;
                next;
            }
            next if not $section;
            if ($section eq 'data') {
                if ($line =~ /\S/) {
                    chomp $line;
                    my ($k, $v) = split /=/, $line, 2;
                    $data{$k} = $v;
                }
            } else {
                $data{$section} .= $line;
            }
        }
        push @developers, \%data;
    }
    return \@developers;
}

1;
