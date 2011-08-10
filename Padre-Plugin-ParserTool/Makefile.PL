use inc::Module::Install::DSL 1.01;

all_from      lib/Padre/Plugin/ParserTool.pm
requires      Devel::Dumpvar 0.04
requires      Data::Dumper   2.101
requires      PPI::Dumper    1.213
test_requires Test::More     0.88
