package Padre::Plugin::XS;

use 5.010001;
use strictures 1;

# use warnings;
# use strict;

use Padre::Unload;
use Padre::Wx ();
use Padre::Current;
use Padre::Logger;
use constant DEBUG => 1;
use Modern::Perl;
use Try::Tiny;

our $VERSION = '0.11_01';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::XS
	Padre::Plugin::XS::C
	Padre::Plugin::XS::Document
	Perl::APIReference
};

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('XS Support');
}

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		'Padre::Plugin'   => '0.94',
		'Padre::Document' => '0.94',
		'Padre::Wx'       => '0.94',
		'Padre::Logger'   => '0.94',
	);
}


#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {
	my $self         = shift;
	my $perl_api_ref = 0;

	# Tests for externals used
	try {
		if ( require Perl::APIReference ) {
			$perl_api_ref = 1;
		}
	};

	return $perl_api_ref;
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About...') => sub { $self->plugin_about },
	];
}

#######
# Called by padre to know which document to register for this plugin
#######
sub registered_documents {
	return (
		'text/x-perlxs' => 'Padre::Plugin::XS::Document',
	);
}

######
# new api 
######
sub registered_highlighters {
	'Padre::Plugin::XS::C' => {
		name => _T('XS HighLighter'),
		mime => [
			qw{
				text/x-csrc
				text/x-c++src
				text/x-perlxs
				}
		],
		},
		;
}

######
# old api
######
# sub provided_highlighters {
	# return (
		# [ 'Padre::Plugin::XS', 'XS highlighter', 'Scintilla C lexer with additional XS keywords' ],
	# );
# }

######
# old api
######
# sub highlighting_mime_types {
	# return (
		# 'Padre::Plugin::XS' => [
			# 'text/x-perlxs',
		# ],
	# );
# }

sub colorize {
	my $self = shift;
	my $module = $self->highlighter;

	# these are arguments: (maybe use for from/to?)
	#$current->editor->GetEndStyled,
	#$event->GetPosition
TRACE("Call $module") if DEBUG;

	my $doc = Padre::Current->document;

	#my $mime_type = $doc->get_mimetype;
	my $editor = $doc->editor;

	# TODO we might need not remove all the color, just from a certain section
	# TODO reuse the $first passed to the method
	#$doc->remove_color;

	my $c_keywords = join(
		' ', qw(
			auto break case char const continue default do
			double else enum extern float for goto if
			int long register return short signed sizeof static
			struct switch typedef union unsigned void volatile while
			)
	);
	my $pp_keywords = join(
		' ',
		'#define', '#include', '#if', '#ifdef', '#endif', '#undef',
		qw(
			__FILE__ __LINE__ __DATE__ __TIME__
			__STDC__ __STDC_VERSION__ __STDC_HOSTED__
			__cplusplus __OBJC__ __ASSEMBLER__
			__GNUC__ __COUNTER__ __GFORTRAN__
			__GNUC_MINOR__ __GNUC_PATCHLEVEL__
			__GNUG__ __STRICT_ANSI__ __ELF__ __VERSION__
			__OPTIMIZE__ __OPTIMIZE_SIZE__ __NO_INLINE__
			__GNUC_PATCHLEVEL__
			)
	);

	# TODO: there are lots more gnu specific pp keywords...

	my $perl_simple_types = join(
		' ', qw(
			I32 U32 STRLEN
			)
	);
	my $perlapi_structs = join(
		' ', qw(
			SV AV HV HE IV NV PV OP
			)
	);

	# TODO: Add colon where appropriate? Does that work at all?
	my $xs_keywords = join(
		' ', qw(
			MODULE PACKAGE ALIAS
			OUTPUT RETVAL
			CODE PPCODE PREFIX
			INIT NO_INIT PREINIT
			POSTCALL NO_OUTPUT CLEANUP
			INPUT SCOPE C_ARGS
			OUTLIST IN IN_OUTLIST IN_OUT
			BOOT REQUIRE VERSIONCHECK
			PROTOTYPES ENABLE DISABLE
			OVERLOAD FALLBACK INTERFACE
			INTERFACE_MACRO INCLUDE CASE
			THIS NO_INIT DESTROY
			)
	);

	my $c_keywords_docs = 'FIXME TODO';

	# TODO: cache
	my $perlapi_keywords = join( ' ', keys %{ $doc->keywords } );

	$editor->SetLexer(Wx::wxSTC_LEX_CPP);
	$editor->SetProperty( "styling.within.preprocessor", 1 );

	# normal keywords (here: C)
	$editor->SetKeyWords( 0, $c_keywords . ' ' . $pp_keywords . ' ' . $perl_simple_types );

	# perlapi stuff and xs stuff
	$editor->SetKeyWords( 1, $perlapi_structs . ' ' . $xs_keywords . ' ' . $perlapi_keywords );
	$editor->SetKeyWords( 2, $c_keywords_docs );
	$editor->SetProperty( "braces.cpp.style", 10 );

	return ();
}

#######
# Add icon to Plugin
#######
# Core plugins may reuse the page icon
sub plugin_icon {
	require Padre::Wx::Icon;
	Padre::Wx::Icon::find('logo');
}



#######
# plugin_about
#######
sub plugin_about {
	my $self = shift;

	# my $share = $self->plugin_directory_share or return;
	# my $file = File::Spec->catfile( $share, 'icons', '48x48', 'git.png' );
	# return unless -f $file;
	# return unless -r $file;

	my $info = Wx::AboutDialogInfo->new;

	# $info->SetIcon( Wx::Icon->new( $file, Wx::wxBITMAP_TYPE_PNG ) );
	$info->SetName('Padre::Plugin::XS');
	$info->SetVersion($VERSION);
	$info->SetDescription( Wx::gettext('Padre XS and perlapi support') );
	$info->SetCopyright('(c) 2008-2013 The Padre development team');
	$info->SetWebSite('http://padre.perlide.org/trac/wiki/PadrePluginXS');
	$info->AddDeveloper('Steffen Mueller <smueller@cpan.org>');
	$info->AddDeveloper('Ahmad M. Zawawi <ahmad.zawawi@gmail.com>');
	$info->AddDeveloper('Kevin Dawson <bowtie@cpan.org>');

	# $info->SetArtists(
	# [   'Scott Chacon <https://github.com/github/gitscm-next>',
	# 'Licence <http://creativecommons.org/licenses/by/3.0/>'
	# ]
	# );
	Wx::AboutBox($info);
	return;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}


1;

__END__


=pod

=head1 NAME

Padre::Plugin::XS - Padre support for perl XS (and perlapi)

=head1 SYNOPSIS

This plugin is intended to extend Padre's support for editing XS
and C-using-perlapi.

Currently the plugin implements limited syntax highlighting and
calltips using a configurable version of the perlapi. After installing
this plugin, you can enable XS calltips in the C<View> menu of Padre
and enjoy the full perlapi of various releases of perl while writing
XS code. You can configure the version of perlapi you write against in
the padre.yml of your project (key C<xs_calltips_perlapi_version>).
By default, the newest available perlapi will be used.

Once this plug-in is installed the user can switch the highlighting of
XS files to use the highlighter via the Preferences menu of L<Padre>.
The default XS syntax highlighting of Padre is abysmal. You're very
encouraged to enable the C<XS highlighter> feature.

=head1 AUTHORS

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 CONTRIBUTORS

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>
Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

Many thanks to Gabor Szabo, who wrote the Kate plugin upon this is based.
I'm grateful to Herbert Breunung for writing Kephra and getting STC syntax highlighting more
right that us. Looking at his code has helped me write this.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2013 by Steffen Mueller

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
