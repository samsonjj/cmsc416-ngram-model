
use strict;
use warnings;

my @tokenArray = ();
my %hash = ();
my $n = 3;

my $START = 12437890;

print 'START';

my $filename = 'aviation-in-canada.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";

while (my $row = <$fh>) {
  chomp $row;

  $row = lc($row);
  $row =~ s/[^a-zA-Z0-9,.!?]/ /g;
  $row =~ s/([,.!?])/ $1 /g;
  $row =~ s/\s+/ /g;

  my @tokens = split(/\s+/, $row);

  push (@tokenArray, @tokens);

  print "$row\n";
}

my @history = ($START);
for my $token (@tokenArray) {
  
  if($token =~ m/^[.!?]$/) {
    @history = ($START);
    next;
  }

  my $historyLength = scalar @history;
  if($historyLength >= $n-1) {
    splice @history, 0, 1;
  }

  push(@history, $token);

  my $history = join(' ', @history);

  print $history."\n";





}

my $length = scalar @tokenArray;
print "size: $length";