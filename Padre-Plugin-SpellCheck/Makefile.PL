use inc::Module::Install::DSL 1.04;

name             Padre-Plugin-SpellCheck
author           Fayland Lam <fayland at gmail.com>
author           Jerome Quelin <jquelin@gmail.com>
author           Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

license          Perl_5
# version          1.21
# copyright_holder Fayland Lam, Jerome Quelin


all_from      lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck.pm

requires      Padre        0.93
requires Module::Util      0
requires Text::Aspell      0
requires Class::XSAccessor 0

homepage         http://padre.perlide.org
repository       http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck/