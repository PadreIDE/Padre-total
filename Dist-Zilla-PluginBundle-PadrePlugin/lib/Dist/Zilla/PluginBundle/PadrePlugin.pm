package Dist::Zilla::PluginBundle::PadrePlugin;

# ABSTRACT: Dist::Zilla plugin bundle for PadrePlugin

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

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

sub bundle_config {
	my ( $self, $section ) = @_;
	my $class = ( ref $self ) || $self;

	my $arg = $section->{payload};

	my @plugins = Dist::Zilla::PluginBundle::Filter->bundle_config(
		{   name    => "$class/Basic",
			payload => {
				bundle => '@Basic',
				remove => [qw(MakeMaker)],
			}
		}
	);

	my %meta_resources;
	for my $resource qw(homepage repository) {
		$meta_resources{$resource} = $arg->{$resource} if defined $arg->{$resource};
	}

	my %next_release_format;
	$next_release_format{format} = defined $arg->{format} ? $arg->{format} : '%-6v %{yyyy.MM.dd}d';

	my %needs_display = { 'needs_display' => '1', 'no_display' => '1' };

	# params

	my $prefix = 'Dist::Zilla::Plugin::';
	my @extra = map { [ "$class/$prefix$_->[0]" => "$prefix$_->[0]" => $_->[1] ] } (
		[ CheckChangeLog    => {} ],
		[ CheckChangesTests => {} ],
		[ CompileTests      => \%needs_display ],
		[ LoadTests         => \%needs_display ],
		[ EOLTests          => {} ],
		[ PodWeaver         => {} ],
		[ PkgVersion        => {} ],
		[ MetaResources     => \%meta_resources ],
		[ MetaConfig        => {} ],
		[ MetaJSON          => {} ],
		[ NextRelease       => \%next_release_format ],
		[ PodSyntaxTests    => {} ],
		[ ModuleBuild       => {} ],
		[ LocaleMsgfmt      => {} ],
	);

	push @plugins, @extra;

	eval "require $_->[1]; 1;" or die for @plugins; ## no critic Carp

	return @plugins;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 DESCRIPTION

Putting the following in your Padre::Plugin::PluginName dist.ini file:

	[@PadrePlugin]
	module = Your::Module::Name

is equivalent to:

	[@Filter]
	bundle = @Basic
	remove = MakeMaker

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
