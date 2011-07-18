use inc::Module::Install::DSL 1.01;

all_from      lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder/Perl.pm
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
test_requires Test::LongString 0.10
test_requires Class::Unload    0.07
install_share
