use inc::Module::Install::DSL 1.00;

all_from      lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder.pm
requires      Class::Unload    0.04
requires      FBP              0.07
requires      FBP::Perl        0.04
requires      Mouse            0.61
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
