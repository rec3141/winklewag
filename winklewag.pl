#! /usr/bin/perl -w
use strict;

# this is a flashcard program
# it shows a word in a language (depending on which dictionary you load)
# and you have to type the corresponding word in an alternate language (depending on which dictionary you load)
# case insensitive
# licensed under GPLv3 by RE Collins

use List::Util 'shuffle';

my $dictionary = 'dictionary.dic';
my %dicthash;
my $right=0;
my $wrong=0;
my $firstlang=0;
my $secondlang='newlanguage';
my $skipped=0;

my @savewrong;
my @saveright;
my @saveskipped;

print "\nWelcome to Winklewag, a flashcard program\nType 'quit' to quit early\n";

print "\nWhat do you want to do?\n[0] Learn a new language\n[1] Teach a new language\n";
my $choice = <STDIN>;
chomp $choice;
$choice = 0 if length($choice) == 0;

print "\nWhich dictionary would you like to use?\n";
my $dictlist = `ls -1 *.dic`;
my @dicts = split("\n",$dictlist);
# my $catlist = join(' ', @dicts);
# `cat $catlist > alldictionaries.dic`;
# push(@dicts,"alldictionaries.dic");

for (my $i=0; $i < @dicts; $i++) {
print "[$i] $dicts[$i]\n";
}

my $dictchoice = <STDIN>;
chomp $dictchoice;
(length($dictchoice) == 0) ? ($dictionary = "dictionary.dic") : ($dictionary = $dicts[$dictchoice]);

open(FILE, $dictionary) || die "can't open file: $dictionary\n";
my $languageline = readline(FILE);
chomp $languageline;
my @languages = split("\t",$languageline);

print "\nThe languages in your dictionary are:\n";
for (my $i=0; $i < @languages; $i++) {
print "[$i] $languages[$i]\n";
}


if ($choice == 1) {&teach()}
else {&learn()}

# print "[" . scalar(@languages) . "] random\n";

sub teach {

print "\nWhich language to show? [$languages[0]]\n";
$firstlang = <STDIN>;
chomp $firstlang;
$firstlang = 0 if length($firstlang) == 0;

print "\nWhat language to add?\n";
$secondlang = <STDIN>;
chomp $secondlang;
$secondlang = 'newlanguage' if length($secondlang) == 0;
$secondlang = $languages[$secondlang] if ($secondlang =~ m/\d/);
print "$secondlang\n\n";


print "\nWhat would you like to do?\n";
print "[0] Add new pairs\n[1] Add new translations?\n";
my $newchoice = <STDIN>;
chomp $newchoice;
if ($newchoice == 0) {&newpairs}
else {&newtranslations}

}

sub newpairs {

while (1>0) {
print "\nNew word in $languages[$firstlang]: ";
my $newfirst = <STDIN>;
chomp $newfirst;
goto END if $newfirst =~ m/^quit$/i;

print "Translation in $secondlang: ";
my $newsecond = <STDIN>;
chomp $newsecond;
goto END if $newsecond =~ m/^quit$/i;
$dicthash{$newfirst} = $newsecond;
}


END:
print "\n\nThanks\n";
open (FILE, ">>$languages[$firstlang]-$secondlang.dic") || die "couldn't open file";
print FILE "$languages[$firstlang]\t$secondlang\n";

foreach my $key (keys %dicthash) {
print FILE "$key\t$dicthash{$key}\n";
}
close FILE

}

sub newtranslations {

while ( <FILE> ) {

my @words = split("\t",$_);
#get rid of kooky latex characters
foreach (@words) {chomp; s/\\.{1}//g}
# fix this to be able to add translations to existing lists
# $dicthash{$words[$firstlang]}{$secondlang} = $words[$secondlang];
$dicthash{$words[$firstlang]}{$secondlang} = ();
}

my @allwords = shuffle(keys %dicthash);
my @wordkeys = sort{$a cmp $b} @allwords;

# print "Hit <enter> to skip a word if it is already correct\n";

LINE: foreach (@wordkeys) {
my $firstword = $_;

WORD: 
my @syns = split('/',$firstword);
print "\n" . join(' or ',@syns) . "\t";

my $line = <STDIN>;
chomp $line;
goto END if $line =~ m/^quit$/i;
$dicthash{$firstword}{$secondlang} = $line;

if (length($line) == 0) {
 $skipped++;
 print "\tSkipped!";
next LINE;
}

}

END: 
print "\n\nThanks\n";
open (FILE, ">>$languages[$firstlang]-$secondlang.dic") || die "couldn't open file";
print FILE "$languages[$firstlang]\t$secondlang\n";
foreach my $key (keys %dicthash) {
next if defined($dicthash{$key}{$secondlang}) == 0;
print FILE "$key\t$dicthash{$key}{$secondlang}\n";
}
close FILE


}

sub learn {
print "\nWhich language to show? [0: $languages[0]]\n";
$firstlang = <STDIN>;
chomp $firstlang;
$firstlang = 0 if length($firstlang) == 0;

print "Which language to guess? [1: $languages[1]]\n";
$secondlang = <STDIN>;
chomp $secondlang;
$secondlang = 1 if length($secondlang) == 0;

print "How many words? [0 for all]?\n";
my $wordnumber = <STDIN>;
chomp $wordnumber;
$wordnumber = 10 if length($wordnumber) == 0;

# print "Alphabetical [0] or random [1] order?  ";
# my $order = <STDIN>;
my $order = 1;

while ( <FILE> ) {

my @words = split("\t",$_);
#get rid of kooky latex characters
foreach (@words) {chomp; s/\\.{1}//g}
$dicthash{$words[$firstlang]}{$languages[$secondlang]} = $words[$secondlang];
$dicthash{$words[$firstlang]}{'correct'} = 0;
}

my @allwords = shuffle(keys %dicthash);
my @wordkeys;
($wordnumber == 0) ? (@wordkeys = @allwords and $wordnumber = scalar(@wordkeys)) : (@wordkeys = @allwords[0..$wordnumber-1]);
($order == 0) ? (@wordkeys = sort{$a cmp $b} @wordkeys) : (@wordkeys = shuffle(@wordkeys));


my $time = time;

LINE: foreach (@wordkeys) {
my $firstword = $_;
my $secondword = $dicthash{$firstword}{$languages[$secondlang]};

next LINE if $dicthash{$firstword}{'correct'} == 1;
next LINE unless ($firstword and $secondword); 

my $repeat = 0;

WORD: 
my @syns = split('/',$firstword);
print "\n" . join(' or ',@syns) . "\t";

my @transyns = split('/',$secondword);
my @hiddensyns = @transyns;
foreach (@hiddensyns) {s/[a-zA-Z]/\./g}
print join(' or ',@hiddensyns) . "\t";

my $line = <STDIN>;
chomp $line;
goto END if $line =~ m/^quit$/i;

if (length($line) == 0) {
 $skipped++;
 print "\tSkipped! " . join(' or ',@transyns) . "\t($right/$wrong/$skipped)\n";
next LINE;
}

my @match = grep(lc($_) eq lc($line),@transyns);
if (@match) {
if ($repeat == 0) {
  $right++;
  $dicthash{$firstword}{'correct'} = 1;
}
  print "\tCorrect! " . join(' or ',@transyns) ."\t($right/$wrong/$skipped)\n";
#if you get it wrong you have to repeat it correctly at least the number of times you got it wrong
 ($repeat > 1) ? (($repeat--) and goto WORD) : (next LINE); 
}

else {
  print "\tWrong! " . join(' or ',@transyns);
  $wrong++ if ($repeat == 0);
  $repeat=2;
  print "\t($right/$wrong/$skipped)\n";
  goto WORD;
}

}

if ($wrong > 0) {
  push(@savewrong, $wrong);
  push(@saveright, $right);
  push(@saveskipped, $skipped);
  print "\n-------- Redoing wrong answers --------\n";
  $wrong = 0; $skipped = 0;
  goto LINE
}

END: 
print join(' ',@saveright);

  push(@savewrong, $wrong);
  push(@saveright, $right);
  push(@saveskipped, $skipped);

print "\n\n-------- You got $right words in " . (time - $time) . " seconds (@saveright/@savewrong/@saveskipped) --------\n";
open (FILE, '>>records.txt') || die "couldn't open file";
my $date = `date`;
chomp $date;
print FILE "$date\t$right words ($languages[$firstlang]/$languages[$secondlang]) in " . (time - $time) . " seconds (@saveright/@savewrong/@saveskipped)\n";
close FILE
}

# `rm alldictionaries.dic`;

