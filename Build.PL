use strict;
use warnings;

use Module::Build ();

my $class = Module::Build->subclass(
  class => 'Padre::Plugin::Builder',
  code => <<'HEREDOC',
sub ACTION_plugin {
  my ($self) = @_;

  # Need PAR::Dist
  if ( not eval { require PAR::Dist; PAR::Dist->VERSION(0.17) } ) {
    $self->log_warn( "In order to create .par files, you need to install PAR::Dist first." );
    return();
  }
  $self->depends_on( 'build' );
  my $module = $self->module_name();
  $module =~ s/^Padre::Plugin:://;

  return PAR::Dist::blib_to_par(
    name => $self->dist_name,
    version => $self->dist_version,
    dist => "$module.par",
  );
}

sub ACTION_installplugin {
  my ($self) = @_;

  $self->depends_on( 'plugin' );

  my $module = $self->module_name();
  $module =~ s/^Padre::Plugin:://;
  my $plugin = "$module.par";

  require Padre;
  my $plugin_dir = Padre::Config->default_plugin_dir;

  return $self->copy_if_modified(from => $plugin, to_dir => $plugin_dir);
}
HEREDOC
);

my $builder = $class->new(
    module_name          => 'Padre::Plugin::PerlTidy',
    license              => 'perl',
    dist_author          => 'Brian Cassidy <bricas@cpan.org>',
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    recursive_test_files => 0,

    requires => {
        'perl'       => '5.008',
        'Perl::Tidy' => 0,
        'Padre'      => '0.12',
    },
    build_requires => { 'Test::More' => '0.47', },
);

$builder->create_build_script();

