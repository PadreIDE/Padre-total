use inc::Module::Install 0.91;

die "OS unsupported\n" unless win32;

# Create README file.
if (author_context) {
	print "Creating README file\n";
	require Pod::Readme;
	my $readme = Pod::Readme->new();
	$readme->parse_from_file('lib/Perl/Dist/Padre.pm', 'README');
}

all_from      'lib/Perl/Dist/Padre.pm';
requires      'Perl::Dist::Strawberry' => '1.1114';
requires      'Perl::Dist::WiX'        => '1.000';
requires      'URI::file'              => '4.20'; # From URI 1.36 or better.
requires      'parent'                 => '0.221';
test_requires 'Test::More'             => '0.61';
test_requires 'LWP::Online'            => '1.07';
resources     'repository'             => 'https://svn.perlide.org/padre/trunk/Perl-Dist-Padre';
resources     'bugtracker'             => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre';
resources     'homepage'               => 'http://padre.perlide.org/';
resources     'IRC'                    => 'irc://irc.perl.org/#padre';
resources     'WebIRC'                 => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23padre';
install_share;
# Requires Module::Install::AutoLicense on the author end.
auto_license;

WriteAll;
