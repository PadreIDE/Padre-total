package Task::Padre::Plugins;

use warnings;
use strict;

our $VERSION = '0.14';

1;
__END__

=head1 NAME

Task::Padre::Plugins - Get many Plugins of Padre at once

=head1 SYNOPSIS

Most plugins will just run with the text you selected if there is any selection.

If not, they run with the whole text from selected document.

=head1 MODULES

=head2 Padre::Plugin::AcmePlayCode

This is a simple plugin to run Acme::PlayCode on your source code.

=head2 Padre::Plugin::Alarm

Alarm Clock (Audio::Beep)

=head2 Padre::Plugin::CommandLine

vi and emacs in Padre?

=head3 Edit Config

Edit CPAN/Config.pm

=head3 Install Module

Run cpan $mod inside Padre. behaves like:

 perl −MCPAN −e "install $mod"

=head3 Upgrade All Padre Plugins

Upgrade all plugin in one hit

=head2 Padre::Plugin::CSS

=head3 CSS Minifier

use CSS::Minifier::XS to minify css

=head3 Validate CSS

use WebService::Validator::CSS::W3C to validate the CSS

=head2 Padre::Plugin::Encode

convert file to different encoding in Padre

=head2 Padre::Plugin::Encrypt

Encrypt/Decrypt by Crypt::CBC

=head2 Padre::Plugin::HTML

=head3 Validate HTML

use WebService::Validator::HTML::W3C to validate the HTML

=head3 Tidy HTML

use HTML::Tidy to tidy HTML

=head2 Padre::Plugin::HTMLExport

Export a HTML page by using Syntax::Highlight::Engine::Kate

=head2 Padre::Plugin::JavaScript

=head3 JavaScript Beautifier

use JavaScript::Beautifier to beautify js

=head3 JavaScript Minifier

use JavaScript::Minifier::XS to minify js

=head2 Padre::Plugin::PAR

Padre::Plugin::PAR − PAR generation from Padre

=head2 Padre::Plugin::PerlCritic

This is a simple plugin to run Perl::Critic on your source code.

=head2 Padre::Plugin::PerlTidy

This is a simple plugin to run Perl::Tidy on your source code.

=head2 Padre::Plugin::Pip

=head2 Padre::Plugin::SVK

Simple SVK interface for Padre

=head2 Padre::Plugin::ViewInBrowser

View selected doc in browser for Padre. Basically it’s a shortcut for Wx::LaunchDefaultBrowser( $self−>selected_filename );

=head2 Padre::Plugin::XML

Use XML::Tidy to tidy XML.

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 SUPPORT

You can find documentation for Padre on L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

