# Cmder adds aliases to its aliases file without caring for duplicates.
# This can result in the aliases file becoming bloated. This script cleans
#the aliases file.
use Env;

my %aliases;
my $alias_file = $CMDER_ROOT . "/config/aliases";

# First step
# Read the aliases file line by line, and put every entry in
# a dictionary. The newer aliases being the last, the new will
# always be kept over the old.
open (my $file_handle, '<', $alias_file) or die "cannot open '$alias_file' $!";
while(my $line = <$file_handle>) 
{
    if ($line =~ /([^=\s<>]+)=(.*)/) 
    {
        $aliases{ $1 } = $2;
    }
    else
    {
        print "Invalid alias:   $line"
    }
}
close($file_handle);


# Second step
# Write back the aliases. Sort them to make the file look nice.
open(my $file_handle, '>', $alias_file) or die "cannot open '$alias_file' $!";
foreach my $key (sort keys %aliases)
{
    print $file_handle "$key=$aliases{ $key }\n";
}
close($file_handle);

