use inc::Module::Install 1.00;

name          'Madre-Sync';
all_from      'lib/Madre/Sync.pm';
requires      'Catalyst::Runtime' => '5.80018';
requires      'Catalyst::Plugin::ConfigLoader';
requires      'Catalyst::Plugin::Static::Simple';
requires      'Catalyst::Action::RenderView';
requires      'Moose';
requires      'namespace::autoclean';
requires      'Config::General'; 
requires      'CatalystX::SimpleLogin';
requires      'Catalyst::Controller::REST';
test_requires 'Test::More' => '0.88';

catalyst;
install_script glob('script/*.pl');
auto_install;

WriteAll;
