use strict;
use warnings;

use File::Spec ();

foreach my $plugin_dir ( glob("Padre-Plugin-*") ) {
    my $locale = File::Spec->catdir( $plugin_dir, 'share', 'locale' );
    if ( -d $locale ) {
        ( my $plugin_name = $plugin_dir ) =~ s/Padre-Plugin-(\w+)/$1/;
        foreach my $pofile ( glob( File::Spec->catfile( $locale, '*.po' ) ) ) {
            if ( $pofile =~ /Padre__Plugin__$plugin_name-(.+?)\.po/ ) {
                if ( open( my $fh, $pofile ) ) {
                    while ( my $line = <$fh> ) {
                        if ( $line =~ /^"Project-Id-Version:\s+(.+?)\\n"/ ) {
                            my $project_id_version = $1;
                            unless ( $project_id_version =~ /$plugin_dir/i ) {
                                print
                                  "Project-Id-Version Mismatch at $pofile\n";
                            }
                            last;
                        }
                    }
                    close $fh;
                }
                else {
                    print "Could not open $pofile for reading\n";
                }
            }
            else {
                print "Found mismatched filename $pofile\n";
            }
        }
    }
}

__END__

=head1 NAME

check_translations - Checks Padre plugin translations for problems

=head1 DESCRIPTION

Checks Padre plugin translations for the following:

=over 4

=item * A PO file must have the format Padre__Plugin__PluginName.po

=item * "Project-Id-Version" should be the same as the Plugin project dir

=back

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
