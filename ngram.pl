
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

# Look through command line arguments for a verbose tag.
my $verbose = 0;
my $argCount = scalar @ARGV;
for( my $i=0; $i<$argCount; $i++) {
  if( $ARGV[$i] eq "-v" ) {
    $verbose = 1;
    splice @ARGV, $i, 1;
  }
}

# Get the number of command line arguments.
$argCount = scalar @ARGV;

# The size of the ngram model. If n=3 then the next word is based on the last 2 (n-1) words.
my $n = 4;
if($argCount > 0) {
  $n = $ARGV[0];
}

# The number of sentences to generate.
my $m = 10;
if($argCount > 1) {
  $m = $ARGV[1];
}

# Constants to represent the start and end of sentences when storing in the hash table.
my $START_TAG = chr(219);
my $STOP_TAG = chr(220);

say '
   _   _         _____ _____            __  __ 
  | \ | |       / ____|  __ \     /\   |  \/  |
  |  \| |______| |  __| |__) |   /  \  | \  / |
  | . ` |______| | |_ |  _  /   / /\ \ | |\/| |
  | |\  |      | |__| | | \ \  / ____ \| |  | |
  |_| \_|       \_____|_|  \_\/_/    \_\_|  |_|                                              
';

say '  Written by Jonathan Samson';
say "  For CMSC 416-001 VCU Spring 2019\n\n";

say "Command line settings : ngram.pl @ARGV";

print "\n";

# Open the log file.
my $outputFile = 'log.txt';
open(my $fhOut, '>', $outputFile)
  or die "Could not open file '$outputFile' $!";


print "Reading text files...\n" if $verbose ;

my $numLines = 0;

for (my $i=2; $i<$argCount; $i++) {
  open(my $fh, '<:encoding(UTF-8)', $ARGV[$i])
    or die "Could not open file '$ARGV[$i]' $!";

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
    $numLines++;
  }

  # We have to make sure the token list ends in a sentence terminator, or BAD THINGS can happen.
  my $numTokens = scalar @tokenArray;
  if( $numTokens == 0) {
    die "No tokens were able to be read from the corpus.";
  }
  elsif( $tokenArray[-1] !~ /[.!?]/g ) {
    push(@tokenArray, ".");
  }

}

# Print out information about the tokenization process.
my $numTokens = scalar @tokenArray;
print "\t$numLines lines read.\n" if $verbose;
print "\t$numTokens tokens found.\n" if $verbose;


print "Building n-gram model...\n" if $verbose;

# This variable contains the history as we go through the tokens. Since the list of tokens starts with a new sentence, history is first intialized with START_TAG.
my @history = ($START_TAG);
my $reset = 0;

# Iterate through each token, and add entries into the hash table.
for my $token (@tokenArray) {

  # History must be n-1 words or less in order to continue.
  my $historyLength = scalar @history;
  if($historyLength > $n-1){
    splice @history, 0, 1;
  }

  # If token is empty string, we don't want it.
  if($token eq "") {
    next;
  }

  # If the current token is a sentence terminator (. ! ?), change token to STOP_TAG, and indicate that we must reset the history, by setting reset = 1.
  if($token =~ m/^[.!?]$/) {
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

  # If reset is set to 1, we have reached the end of the sentence. Reset the history, and set reset = 0.
  if( $reset == 1 ) {
    @history = ($START_TAG);
    $reset = 0;
  } else {
    push(@history, $token);
  }
}


my $hashSize = scalar %hash;
print "\t$hashSize entries in the hash table.\n" if $verbose;

# Store the number of sentences we will need total.
my $sentenceId = 1;

print "Generating sentences...\n\n" if $verbose;

# Generate sentences.
while($sentenceId <= $m) {

  print "$sentenceId) ";

  # For each new sentence, start with just the START_TAG.
  @history = ($START_TAG);
  
  # Tag to indicate that we are on the first word of the sentence.
  my $first = 1;

  # Loop until we come to a STOP_TAG.
  while(1) {

    # History must be n-1 words or less in order to continue.
    my $historyLength = scalar @history;
    if($historyLength > $n-1) {
      splice @history, 0, 1;
    }

    # Get the concatenated string of history to use as a key.
    my $historyKey = join(' ', @history);

    # Loop through all the tokens which follow the history, and tally up total frequency.
    my $historyFrequency = 0;
    foreach my $tokenKey (keys %{ $hash{$historyKey} } ) {
      $historyFrequency += $hash{$historyKey}{$tokenKey};
    }

    # Pick a random number, less than or equal to the frequency, to choose which word to use next.
    my $randomIndex = int(rand($historyFrequency)) + 1;

    my $word = "";
        
    # Iterate through the tokens and counts until we find the correct word. We calculate this
    # by decrementing randomIndex by the frequency of each token of the hash until randomIndex <= 0;
    foreach my $tokenKey ( keys %{ $hash{$historyKey} } ) {
      $randomIndex -= $hash{$historyKey}{$tokenKey};

      if($randomIndex <= 0) {
        $word = $tokenKey;
        last;
      }
    }

    # If we have reached the end of the sentence ($STOP_TAG) then end with a period, and newline.
    if( $word eq $STOP_TAG ) {
      print ".\n";
      last;
    }
    # Otherwise, print out the word. Special cases of spacing for commas and capitalization for the first word.
    else {
      if($first == 1) {
        $first = 0;
        my $something = ucfirst $word;
        print "$something";
      }
      elsif($word eq ",") {
        print "$word";
      }
      else {
        print " $word";
      }
    }

    # Append the word to the history.
    push(@history, $word);
  }

  $sentenceId++;
}

print "\n";
