use inc::Module::Install::DSL 1.00;

all_from      lib/Parser/Plugin/ParserTool.pm
requires      Padre          0.83
requires      PPI            1.213
requires      Devel::Dumpvar 0.04
requires      Data::Dumper   2.101
test_requires Test::More     0.88
