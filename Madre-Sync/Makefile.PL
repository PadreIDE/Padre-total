use inc::Module::Install::DSL 1.00;

name           Madre-Sync
all_from       lib/Madre/Sync.pm
requires       JSON::XS                         2.29
requires       Config::General                  2.49
requires       Email::Valid                     0.184
requires       namespace::autoclean             0.11
requires       Class::C3                        0.23
requires       Moose                            1.08
requires       DBIx::Class                      0.08123
requires       DBIx::Class::Timestamp           0.13
requires       Catalyst::Runtime                5.80018
requires       Catalyst::Plugin::ConfigLoader   0.28
requires       Catalyst::Plugin::Static::Simple 0.29
requires       Catalyst::Action::RenderView     0.14
requires       Catalyst::Controller::REST       0.85
requires       Catalyst::View::TT               0.34
requires       CatalystX::SimpleLogin           0.12
test_requires  Test::More                       0.88
install_script script/madre_make_schema.pl
install_script script/madre_sync_cgi.pl
install_script script/madre_sync_create.pl
install_script script/madre_sync_fastcgi.pl
install_script script/madre_sync_server.pl
install_script script/madre_sync_test.pl

catalyst
