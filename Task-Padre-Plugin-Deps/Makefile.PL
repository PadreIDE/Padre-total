use inc::Module::Install;

name     'Task-Padre-Plugin-Deps';
all_from 'lib/Task/Padre/Plugin/Deps.pm';
author   'Gabor Szabo';
license  'perl';

requires 'Padre'                   => '0.21';

# Padre::Plugin::AcmePlayCode   0.02,
requires 'Acme::PlayCode';

# Padre::Plugin::Alarm
requires 'Audio::Beep';

# Padre::Plugin::CSS 0.02
requires 'WebService::Validator::CSS::W3C';
requires 'CSS::Minifier::XS';

# Padre::Plugin::CPAN 0.03
requires 'CPAN';

# Padre::Plugin::Encrypt  0.01
requires 'Crypt::CBC';
requires 'Crypt::Blowfish';

# Padre::Plugin::HTML 0.03
requires 'XML::XPath' => 0;
requires 'WebService::Validator::HTML::W3C' => 0;
requires 'HTML::Tidy' => 0;
requires 'HTML::Lint' => 0;

# Padre::Plugin::HTMLExport
requires 'Syntax::Highlight::Engine::Kate' => 0;

# Padre::Plugin::InstallPARDist',
requires 'ExtUtils::InferConfig'   => '0.02';
requires 'ExtUtils::InstallPAR'    => '0.01';
requires 'LWP::Simple';
        
# Padre::Plugin::JavaScript 0.22
requires 'JavaScript::Beautifier'   => '0.03';
requires 'JavaScript::Minifier::XS';

# Padre::Plugin::PAR',
requires 'PAR::Packer';

# Padre::Plugin::PerlCritic 0.03
requires 'Perl::Critic';

# Padre::Plugin::PerlTidy 0.01
requires 'Perl::Tidy';

# Padre::Plugin::Pip 0.13
requires 'pip' => '0.13';

# Padre::Plugin::XML
requires 'XML::Tidy';

feature 'Install experimental Padre plugin that runs on Parrot?',
    -default        => 0,
    'Parrot::Embed' => 0;

feature 'Install Padre plugin for Perl6?',
    -default                   => 0,
    'Syntax::Highlight::Perl6' => '0.02962',
    'URI'                      => '1.37',
    'Readonly'                 => '1.03';

build_requires 'Test::More';
build_requires 'Test::NeedsDisplay' => '1.05';

auto_install;

WriteAll;
