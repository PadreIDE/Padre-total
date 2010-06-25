use inc::Module::Install::DSL 1.00;

all_from      lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder.pm
requires      Class::Unload    0.04
requires      Padre::Plugin    0.64
requires      FBP              0.05
requires      FBP::Perl        0.01
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
