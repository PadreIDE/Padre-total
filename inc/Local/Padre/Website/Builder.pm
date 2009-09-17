package Local::Padre::Website::Builder;
use 5.008008;
use utf8;
use strict;
use warnings FATAL => 'all';
use parent 'Module::Build';
use File::Copy qw(copy);
use File::Basename qw(basename);
use File::Next qw();
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
    $self->depends_on(qw(copy_static_files process_templates build_docs));
    print "You can run ./Build test now.\n";
}

sub ACTION_build_docs {
    my ($self) = @_;
    my $root = dir($self->config_data('sourcedir'), '..');
    my $dir  = dir($root, 'Padre', 'lib');

    my $iter = File::Next::files({
            descend_filter => sub {$_ ne '.svn'}
        },
        $dir
    );

    while (defined(my $fullpath = $iter->())) {
        my $target_dir = dir($self->destdir, 'docs', 'Padre',
            file($fullpath)->relative($dir)->parent);
        $target_dir->mkpath;
		#print file($fullpath)->relative, "\n";
		my $outfile = substr(dir($target_dir, basename($fullpath)), 0, -2) . 'html';

		#print "$fullpath    $outfile\n";
		# TODO: this is a really basic first version, we need to make it nicer
		# TODO we might also want to generate the docs of all the Padre plugins
		system "pod2html --htmlroot=http://padre.perlide.org/docs/Padre --infile $fullpath --outfile=$outfile 2>/dev/null";
	}
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
            my $Source = file($template_file)->relative($include_path)->stringify;
            $tt->process(
                $Source,
                $stash,
                file($template_file)->relative($templates_dir)->stringify,
                {binmode => ':utf8'},
            ) or die $tt->error.' in '.$Source;
        }
    }
}

sub ACTION_install {
    my ($self) = @_;
    print "./Build install does nothing yet. Fix me!\n";

    # system qw(rsync -a), $self->destdir, 'padre.perlide.org:';
    # or something like that.
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
