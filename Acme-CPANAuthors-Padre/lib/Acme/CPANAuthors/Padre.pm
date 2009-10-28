package Acme::CPANAuthors::Padre;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.02';


use Acme::CPANAuthors::Register (
	TEEJAY     => "Aaron Trevena",
	AZAWAWI    => "Ahmad M. Zawawi أحمد محمد زواوي",
	# Adam K refuses to take part in Acme::CPANAuthors
	# ADAMK      => "Adam Kennedy",
	GARU       => "Breno G. de Oliveira",
	BRICAS     => "Brian Cassidy",
	THEREK     => "Cezary Morga",
	CHRISDOLAN => "Chris Dolan",
	CLAUDIO    => "Claudio Ramirez",
	FAYLAND    => "Fayland Lam",
	GABRIELMAD => "Gabriel Vieira",
	SZABGAB    => "Gábor Szabó - גאבור סבו",
	HJANSEN    => "Heiko Jansen",
	JQUELIN    => "Jérôme Quelin",
	KAARE      => "Kaare Rasmussen",
	KEEDI      => "Keedi Kim - 김도형",
	ISHIGAKI   => "Kenichi Ishigaki",
	CORION     => "Max Maischein",
	PATSPAM    => "Patrick Donelan",
	PMURIAS    => "Paweł Murias",
	PSHANGOV   => "Petar Shangov",
	RSN        => "Ryan Niebur",
	SEWI       => "Sebastian Willing",
	TSEE       => "Steffen Müller",
	MGRIMES    => "Mark Grimes",
);

1; # End of Acme::CPANAuthors::Padre

__END__

=head1 NAME

Acme::CPANAuthors::Padre - We are the Padre CPAN authors

=head1 SYNOPSIS

   use Acme::CPANAuthors;

   my $authors  = Acme::CPANAuthors->new("Padre");

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions("sewi");
   my $url      = $authors->avatar_url("szabgab");
   my $kwalitee = $authors->kwalitee("fayland");
   my $name     = $authors->name("azawawi");

=head1 DESCRIPTION

This class provides a hash of Padre CPAN authors' PAUSE ID and name to 
the C<Acme::CPANAuthors> module.

=head1 MAINTENANCE

If you are a Padre CPAN author not listed here, please send me your ID/name 
via email or RT so we can always keep this module up to date. If there's a 
mistake and you're listed here but are not Padre (or just don't want to be 
listed), sorry for the inconvenience: please contact me and I'll remove the 
entry right away.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-cpanauthors-padre at 
rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Padre>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Acme::CPANAuthors::Padre


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-Padre>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-Padre>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-Padre>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-Padre/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Ahmad M. Zawawi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
