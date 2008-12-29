use strict;
use warnings;
use IO::File;
use Carp;

sub get_version {
    my $file = shift;
    my $version = undef;
    my $fh = IO::File->new($file)
        or croak "Could not open $file";
    my $line;
    while($line = <$fh>) {
        if($line =~ /\$VERSION\s*=\s*'(.+)'/) {
            $version = $1;
            last;
        }
    }
    close $fh
        or croak "Could not close $file";
    
    return $version;
}

my $line;
my $filename = 'Makefile.PL';
my $fh = IO::File->new($filename)
    or croak "Could not open $filename";
while($line = <$fh>) {
    chomp $line;
    if($line =~ /'(.+)'\s*=>\s*'(.+)'/) {
        my ($module_name,$version) = ($1,$2);
        my $module_path = $module_name;
        $module_path =~ s/::/-/g;
        my $module_file = (join '/', split /::/, $module_name) . '.pm';
        my $file = File::Spec->catfile("../$module_path/lib/",$module_file);
        if(-f $file) {
            my $current_version = get_version($file);
            if($current_version ne $version) {
                print "$current_version ne $version at $file\n";
            }
        }
    }
}
close $fh
    or croak "Could not close $filename";