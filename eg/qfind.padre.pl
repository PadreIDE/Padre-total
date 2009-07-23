require Padre::Wx::DocBrowser::QuickDialog;

my $d = Padre::Wx::DocBrowser::QuickDialog->new( Padre->ide->wx->main );
$d->Show;