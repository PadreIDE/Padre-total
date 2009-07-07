package Module::Install::Msgfmt;

use strict;
use File::Spec;
use Module::Install::Base ();
use Module::Install::Share;

our $VERSION = '0.12';
our @ISA     = 'Module::Install::Base';

sub install_share_with_mofiles {
	my @orig      = (@_);
	my $self      = shift;
	my $class     = ref($self);
	my $inc_class = join( '::', @{ $self->_top }{qw(prefix name)} );
	my $dir       = @_ ? pop : 'share';
	my $type      = @_ ? shift : 'dist';
	my $module    = @_ ? shift : '';
	$self->build_requires( 'Locale::Msgfmt' => '0.09' );
	install_share(@orig);
	my $distname = "";

	if ( $type eq 'dist' ) {
		$distname = $self->name;
	} else {
		$distname = Module::Install::_CLASS($module);
		$distname =~ s/::/-/g;
	}
	my $path = File::Spec->catfile( 'auto', 'share', $type, $distname );
	$self->postamble(<<"END_MAKEFILE");
config ::
\t\$(NOECHO) \$(PERL) "-M$inc_class" -e "do_msgfmt(q(\$(INST_LIB)), q($path))"

END_MAKEFILE
}

# blib/lib/auto/share/dist/Padre/locale/he.po
sub do_msgfmt {
	my $self      = shift;
	my $lib       = shift;
	my $sharepath = shift;
	my $fullpath  = File::Spec->catfile( $lib, $sharepath, 'locale' );
	if ( !-d $fullpath ) {
		die("$fullpath isn't a directory");
	}
	require Locale::Msgfmt;
	Locale::Msgfmt::msgfmt( { in => $fullpath, verbose => 1, remove => 1 } );
}
