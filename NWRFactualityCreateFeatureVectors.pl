#!/usr/bin/perl -w 

###
# This is a script that takes as output a tab separated values file 
# containing factuality annotations from FactBank and generates a csv-file
# to use to train a machine learning classifier to predict factuality
#
# Author: Marieke van Erp
#
# September 8 2013
#####

use strict ; 
use List::MoreUtils qw(uniq);
use Lingua::EN::Tokenizer::Offsets qw/token_offsets get_tokens/; 

# Print the CSV header line for Weka
#print "My_id,event text,eventType,tense,aspect,pos,polarity,RelSource,RelSourceLevel,w-4,w-3,w-2,w-1,e,w+1,w+2,factvalue\n" ; 
 
# Open the factuality annotations file and loop through it 
open FILE, "factuality.csv" ;

# Here's a little reminder of what's in the factuality.csv file 
# Fields: 0sentences.file, 1sentences.sentId, 2tml_event.eId, 3tml_event.eClass, 4fb_factValue.eText, 5fb_factValue.eId, 6tml_instance.tense, 7tml_instance.aspect, 8tml_instance.pos, 9tml_instance.polarity, 10fb_factValue.relSourceText, 11sentences.sent, 12fb_factValue.factValue


while(my $input = <FILE>)
	{
	chomp $input ;
	# Separate the fields 
	my @fields = split/\t/, $input ;
	# Do some cleanup 
	$fields[0] =~ s/"//g ;
	$fields[4] =~ s/"//g ;
	$fields[4] =~ s/\$/DOLLAR/g ;
	$fields[11] =~ s/\$/DOLLAR/g ;
	$fields[4] =~ s/\\/backslash/g ;
	$fields[11] =~ s/\\/backslash/g ;
	$fields[4] =~ s/\%/percentagesign/g ;
	$fields[11] =~ s/\%/percentagesign/g ;
	$fields[11] =~ s/,/COMMA/g ;
	$fields[11] =~ s/n't/ not /g ; 
	$fields[4] =~ s/'/SQUOTE/g ;
	$fields[11] =~ s/'/SQUOTE/g ;
	$fields[11] =~ s/"//g ;
	$fields[4] = lc($fields[4]) ;
	# Generate an ID that contains the file and sentence number and print it 
	my $id = $fields[0]."_".$fields[1] ;
	print "\"$id\"," ; 
	# We also want to tokenize the sentence
	my $words = get_tokens($fields[11]) ;  
	# And we're going to identify the events in there 
	my $event_index ;
	# print event text 
	print $fields[4] ."," ; 
	# print event type, tense, aspect, part of speech tag and polarity 
	print  $fields[3] .",".$fields[6] .",".$fields[7] .",".$fields[8] .",".$fields[9] ."," ;
	# print relSourceText indicating the source holding the factuality opinion and whether it's nested 
	my $relSourceText ; 
	my $relSourceLevel ;
	# Doing some cleanup from weird FactBank values  
	$fields[10] =~ s/[A-Za-z].*=//g ; 
	# Since in FactBank sources can be nested, we want to find out the depth of the nesting
	if($fields[10] =~ /_/)
		{
		$fields[10] =~ s/"//g ; 
		# nesting is indicated by sources concatenated by _ 
		my @relSourceLevels = split/_/,$fields[10] ;
		$relSourceText = '"'.$relSourceLevels[0].'"' ;
		# A little bit of normalisation to make it easier on the classifier 
		if($relSourceText !~ /AUTHOR/)
			{
			$relSourceText = "OTHER" ; 
			}
		# I'm also adding a tag here to make it easy to identify these values in the file 
		$relSourceLevel = "RELSOURCELEVEL".scalar(@relSourceLevels) ; 
		}
	else # if it's not nested then our level is 1 
		{
		$relSourceText = $fields[10] ;
		if($relSourceText !~ /AUTHOR/)
			{
			$relSourceText = "OTHER" ; 
			}
		$relSourceLevel = "RELSOURCELEVEL1" ; 
		}
	# print 
	print $relSourceText.",".$relSourceLevel."," ;
	# now let's loop through our tokenised sentence and identify the index of the word indicating the event  
	for(my $x = 0 ; $x < @$words ; $x++)
		{
		$words->[$x] = lc($words->[$x]) ; 
		if($words->[$x] =~ /$fields[4]/)
			{
			$event_index = $x ; 
			} 	
		}
	# and let's generate an event window of 4 words before the event and 2 words after 	
	my $event_window ; 	
	if($event_index == 3)
		{
		$event_window = "\"_\",\"".$words->[$event_index-3]."\",\"".$words->[$event_index-2]."\",\"".$words->[$event_index-1]."\",\"".$words->[$event_index]."\"" ; 
		} 
	elsif($event_index == 2)
		{
		$event_window = "\"_\",\"_\",\"".$words->[$event_index-2]."\",\"".$words->[$event_index-1]."\",\"".$words->[$event_index]."\"" ; 
		}
	elsif($event_index == 1)
		{
		$event_window = "\"_\",\"_\",\"_\",\"".$words->[$event_index-1]."\",\"".$words->[$event_index]."\"" ; 
		}
	elsif($event_index == 0)
		{
		$event_window = "\"_\",\"_\",\"_\",\"_\",\"".$words->[$event_index]."\"" ;  
		}	
	else
		{
		$event_window = "\"".$words->[$event_index-4]."\",\"".$words->[$event_index-3]."\",\"".$words->[$event_index-2]."\",\"".$words->[$event_index-1]."\",\"".$words->[$event_index]."\"" ;
		}
	if($event_index == (scalar(@$words) - 1))
		{
		$event_window = $event_window.",\"_\",\"_\"" ;
		}
	elsif($event_index == (scalar(@$words) - 2))
		{
		$event_window = $event_window.",\"".$words->[$event_index+1]."\",\"_\"" ; 
		}
	else
		{
		$event_window = $event_window.",\"".$words->[$event_index+1]."\",\"".$words->[$event_index+2]."\"" ; 
		}
	# print the event window and finally print the factvalue 
	print $event_window."," ; 
	print $fields[12]."\n" ; 
	}	
	

