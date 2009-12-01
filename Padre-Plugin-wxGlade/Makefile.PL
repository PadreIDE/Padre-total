use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Plugin/wxGlade.pm
requires      File::Slurp  9999.12
requires      Padre        0.45
requires      Params::Util 1.00
requires      XML::Tiny    1.11
test_requires Test::More   0.82
