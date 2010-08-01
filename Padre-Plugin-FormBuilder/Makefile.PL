use inc::Module::Install::DSL 1.00;

all_from      lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder.pm
requires      FBP::Perl        0.11
requires      Mouse            0.61
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
