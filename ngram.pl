
use strict;
use warnings;

use feature 'say';


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

# The number of sentences to generate.
my $m = 10;

# Constants to represent the start and end of sentences when storing in the hash table.
my $START_TAG = chr(219);
my $STOP_TAG = chr(220);

say 'START';

# Open the file
my $inputFile = 'aviation-in-canada.txt';
my $outputFile = 'log.txt';
open(my $fh, '<:encoding(UTF-8)', $inputFile)
  or die "Could not open file '$inputFile' $!";
open(my $fhOut, '>', $outputFile)
  or die "Could not open file '$outputFile' $!";


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
  if($token =~ m/[.!?]/) {
    $token = $STOP_TAG;
    $reset = 1;
  }

  # Get a concatenated string of the history to store as as a key in "hash".
  my $history = join(' ', @history);

  # Check if the history is already contained in the hash. If it is, increment it. If it is not, add it.
  if( exists $hash{$history} ) {
    if( exists $hash{$history}{$token} ) {
      # Exists, so increment
      $hash{$history}{$token}++;
    }
    else {
      # Does not exist, so add the entry initialized to 1.
      $hash{$history}{$token} = 1;
    }
  }
  else {
    # Does not exist, so add the entry initialized to 1.
    $hash{$history}{$token} = 1;
  }

  # If reset is set to 1, we have reached the end of the sentence. Rset the history, and set reset = 0.
  if( $reset == 1 ) {
    @history = ($START_TAG);
    $reset = 0;
  } else {
    push(@history, $token);
  }
}

# Print out hash for testing
foreach my $historyKey (sort keys %hash) {
  foreach my $tokenKey (keys %{ $hash{$historyKey} }) {
    my $huhlength = length $historyKey;
    print $fhOut "$historyKey -> $tokenKey: $hash{$historyKey}{$tokenKey}\n";
  }
}

# Generate sentences.
while($m > 0) {

  # For each new sentence, start with just the START_TAG.
  @history = ($START_TAG);
  
  # Loop until we come to a STOP_TAG.
  while(1) {

    # Get the concatenated string of history to use as a key.
    my $historyKey = join(' ', @history);

    # Loop through all the tokens which follow the history, and tally up total frequency.
    my $historyFrequency = 0;
    foreach my $tokenKey (keys %{ $hash{$historyKey} } ) {
      $historyFrequency += $hash{$historyKey}{$tokenKey};
    }

    # Pick a random number, less than or equal to the frequency, to choose which word to use next.
    my $randomIndex = int(rand($historyFrequency)) + 1;

    # Iterate through the tokens and counts until we find the correct word.
    my $word = "";
    foreach my $tokenKey ( keys %{ $hash{$historyKey} } ) {
      $randomIndex -= $hash{$historyKey}{$tokenKey};
        #print "hello $randomIndex \n";

      if($randomIndex <= 0) {
        $word = $tokenKey;
        last;
      }
    }

    # if( $word eq $STOP_TAG ) {
    #   print ".\n";
    # }
    # else {
    #   print "$word ";
    # }

      print "hello $m \n";
    $m--;
  }

}

my $length = scalar @tokenArray;
print "size: $length";