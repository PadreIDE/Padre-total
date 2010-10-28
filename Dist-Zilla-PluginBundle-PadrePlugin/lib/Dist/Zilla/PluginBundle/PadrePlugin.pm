package Dist::Zilla::PluginBundle::PadrePlugin;

# ABSTRACT: Dist::Zilla plugin bundle for PadrePlugin

use Moose;
use Moose::Autobox;
use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::Plugin::CheckChangeLog;
use Dist::Zilla::Plugin::CheckChangesTests;
use Dist::Zilla::Plugin::CompileTests;
use Dist::Zilla::Plugin::LoadTests;
use Dist::Zilla::Plugin::EOLTests;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::PkgVersion;
use Dist::Zilla::Plugin::MetaResources;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::ModuleBuild;
use Dist::Zilla::Plugin::LocaleMsgfmt;

# Meta resource repository
has repository => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { $_[0]->payload->{repository} || '' },
);

# Meta resource homepage
has homepage => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { $_[0]->payload->{homepage} || '' },
);

# Release date format
has format => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub { $_[0]->payload->{format} || '%-6v %{yyyy.MM.dd}d' },
);

sub configure {
	my ($self) = @_;


	# filter the @Basic bundle and remove [MakeMaker]
	$self->add_bundle(
		'@Filter' => {
			bundle => '@Basic',
			remove => [qw(MakeMaker)],
		}
	);

	# Start adding plugins
	$self->add_plugins(qw( CheckChangeLog CheckChangesTests ));

	# TODO: no_display should be removed once CompileTests supports it
	my $needs_display = [ 'needs_display' => '1', 'no_display' => '1' ];
	$self->add_plugins( [ 'CompileTests' => $needs_display ] );
	$self->add_plugins( [ 'LoadTests'    => $needs_display ] );

	$self->add_plugins(qw(EOLTests PkgVersion PodWeaver));

	$self->add_plugins(
		[   'MetaResources' => {

				repository => $self->repository,
				homepage   => $self->homepage,
			}
		]
	);

	$self->add_plugins(qw( MetaConfig MetaJSON ));

	$self->add_plugins(
		[   'NextRelease' => {
				format => $self->format,
			}
		]
	);

	$self->add_plugins(qw( PodSyntaxTests ModuleBuild LocaleMsgfmt ));


	# Add test dependencies
	$self->add_plugins(
		[   Prereqs => 'TestMoreDeps' => {
				-phase       => 'test',
				-type        => 'requires',
				'Test::More' => '0'
			}
		],
	);
	$self->add_plugins(
		[   Prereqs => 'LocaleMsgfmtDeps' => {
				-phase           => 'test',
				-type            => 'requires',
				'Locale::Msgfmt' => '0.14'
			}
		],
	);

	# Add runtime dependencies
	$self->add_plugins(
		[   Prereqs => 'PadreDeps' => {
				-phase  => 'runtime',
				-type   => 'requires',
				'Padre' => '0.57'
			}
		],
	);


}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 DESCRIPTION

Putting the following in your Padre::Plugin::PluginName dist.ini file:

	[@PadrePlugin]

is equivalent to:

	[@Filter]
	bundle = @Basic
	remove = MakeMaker

	needs_display  = 1
	no_display     = 1	; will be removed once CompileTests supports it

	[CheckChangeLog]
	[CheckChangesTests]
	[CompileTests]
	[LoadTests]
	[EOLTests]
	[PodWeaver]
	[PkgVersion]
	[MetaResources]
	[MetaConfig]
	[MetaJSON]
	[NextRelease]
	format = %-6v %{yyyy.MM.dd}d
	[PodSyntaxTests]
	[ModuleBuild]
	[LocaleMsgfmt]

You can specify the following options:
	homepage
	repository
	format
