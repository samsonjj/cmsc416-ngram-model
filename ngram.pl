
use strict;
use warnings;




# Stores the tokens from the corpus, before inserting into the hash.
my @tokenArray = ();

# Uses the past history as the key, and stores as the value a hash of word/frequency pairs.
# The hash table is structured as follows:
#
# HASH (  key STRING history,
#         value HASH ( key STRING token, value NUMBER count )
# )
# So "hash" contains word histories as keys, and a hash of word/count pairs as values, which show the frequency of words occuring after a certain history.
my %hash = ();

# The size of the ngram model. If n=3 then the next word is based on the last 2 (n-1) words.
my $n = 3;

# Constants to represent the start and end of sentences when storing in the hash table.
my $START_TAG = chr(219);
my $STOP_TAG = chr(220);

print 'START';

# Open the file
my $filename = 'aviation-in-canada.txt';
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";

# Main loop to build the ngram model. Iterates through each row in the line in the file. Stop when we reach the end of the input file.
while (my $row = <$fh>) {

  # Perform cleanup for each line.

  # Remove white space at edges.
  chomp $row;

  # Set everything to lower case.
  $row = lc($row);

  # Remove anything that is not a letter, number, or punctuation (, . ! ?). Accomplishes this by replacing other characters with a space.
  $row =~ s/[^a-zA-Z0-9,.!?]/ /g;

  # Make sure that punctuation is seperated from words by a space.
  $row =~ s/([,.!?])/ $1 /g;

  # Replace all white space with a single space. This is done so we can split the line into tokens by spaces, then append tokens to the tokenArray.
  $row =~ s/\s+/ /g;
  my @tokens = split(/\s+/, $row);
  push (@tokenArray, @tokens);
}


# This variable contains the history as we go through the tokens. Since the list of tokens starts with a new sentence, history is first intialized with START_TAG.
my @history = ($START_TAG);
my $reset = 0;
# Iterate through each token, and add entries into the hash table.
for my $token (@tokenArray) {

  # History must be n-1 words or less in order to continue.
  my $historyLength = scalar @history;
  if($historyLength > $n-1) {
    splice @history, 0, 1;
  }

  # If the current token is a sentence terminator (. ! ?), change token to STOP_TAG, and indicate that we must reset the history, by setting reset = 1.
  if($token =~ m/^[.!?]$/) {
    $token = $STOP_TAG;
    reset = 1;
  }

  # Get a concatenated string of the history to store as as a key in "hash".
  my $history = join(' ', @history);

  # Check if the history is already contained in the hash. If it is not, add it.
  if( exists $hash{$history} ) {
    $hash{$history}{$token}++;
  }
  else {
    $hash{$history}{$token} = 1;
  }

  if( reset == 1 ) {
    @history = ($START_TAG);
    reset = 0;
  } else {
    push(@history, $token);
  }
}

# Print out hash for testing
foreach my $history (sort keys %hash) {
    foreach my $token (keys %{ $hash{$history} }) {
        print "$history, $token: $hash{$history}{$token}\n";
    }
}

my $length = scalar @tokenArray;
print "size: $length";