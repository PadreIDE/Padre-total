package Wx::Scintilla;

use Wx;
use strict;
use warnings;

our $VERSION = '0.01';

# Add Wx::Scintilla distribution directory to PATH on windows so that Wx can load it
use File::ShareDir ();
local $ENV{PATH} =  File::ShareDir::dist_dir('Wx-Scintilla') . ';' . $ENV{PATH} if ($^O eq 'MSWin32');

# Load scintilla and ask Wx to boot it :)
Wx::load_dll('scintilla');
Wx::wx_boot( 'Wx::Scintilla', $VERSION );

#
# properly setup inheritance tree
#

no strict;

package Wx::ScintillaTextCtrl; @ISA = qw(Wx::Control);

package Wx::ScintillaTextEvent; @ISA = qw(Wx::CommandEvent);

package Wx::Event;

use strict;

# !parser: sub { $_[0] =~ m/sub (EVT_\w+)/ }
# !package: Wx::Event

sub EVT_SCINTILLA_CHANGE($$$)            { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHANGE,            $_[2] ) }
sub EVT_SCINTILLA_STYLENEEDED($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_STYLENEEDED,       $_[2] ) }
sub EVT_SCINTILLA_CHARADDED($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CHARADDED,         $_[2] ) }
sub EVT_SCINTILLA_SAVEPOINTREACHED($$$)  { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTREACHED,  $_[2] ) }
sub EVT_SCINTILLA_SAVEPOINTLEFT($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_SAVEPOINTLEFT,     $_[2] ) }
sub EVT_SCINTILLA_ROMODIFYATTEMPT($$$)   { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ROMODIFYATTEMPT,   $_[2] ) }
sub EVT_SCINTILLA_KEY($$$)               { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_KEY,               $_[2] ) }
sub EVT_SCINTILLA_DOUBLECLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DOUBLECLICK,       $_[2] ) }
sub EVT_SCINTILLA_UPDATEUI($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_UPDATEUI,          $_[2] ) }
sub EVT_SCINTILLA_MODIFIED($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MODIFIED,          $_[2] ) }
sub EVT_SCINTILLA_MACRORECORD($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MACRORECORD,       $_[2] ) }
sub EVT_SCINTILLA_MARGINCLICK($$$)       { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_MARGINCLICK,       $_[2] ) }
sub EVT_SCINTILLA_NEEDSHOWN($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_NEEDSHOWN,         $_[2] ) }
sub EVT_SCINTILLA_POSCHANGED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_POSCHANGED,        $_[2] ) }
sub EVT_SCINTILLA_PAINTED($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_PAINTED,           $_[2] ) }
sub EVT_SCINTILLA_USERLISTSELECTION($$$) { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_USERLISTSELECTION, $_[2] ) }
sub EVT_SCINTILLA_URIDROPPED($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_URIDROPPED,        $_[2] ) }
sub EVT_SCINTILLA_DWELLSTART($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLSTART,        $_[2] ) }
sub EVT_SCINTILLA_DWELLEND($$$)          { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DWELLEND,          $_[2] ) }
sub EVT_SCINTILLA_START_DRAG($$$)        { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_START_DRAG,        $_[2] ) }
sub EVT_SCINTILLA_DRAG_OVER($$$)         { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DRAG_OVER,         $_[2] ) }
sub EVT_SCINTILLA_DO_DROP($$$)           { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_DO_DROP,           $_[2] ) }
sub EVT_SCINTILLA_ZOOM($$$)              { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_ZOOM,              $_[2] ) }
sub EVT_SCINTILLA_HOTSPOT_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_CLICK,     $_[2] ) }
sub EVT_SCINTILLA_HOTSPOT_DCLICK($$$)    { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_HOTSPOT_DCLICK,    $_[2] ) }
sub EVT_SCINTILLA_CALLTIP_CLICK($$$)     { $_[0]->Connect( $_[1], -1, &Wx::wxEVT_STC_CALLTIP_CLICK,     $_[2] ) }

1; # end of Wx::Scintilla

__END__

=pod

=head1 NAME

Wx::Scintilla - Perl wxWidgets XS bindings for Scintilla editor component 

=head1 SYNOPSIS

TODO explain :)

=cut
