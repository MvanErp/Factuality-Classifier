#!/usr/bin/perl -w 

use strict ; 
use XML::LibXML ;
use Data::Dumper ;  
#use utf8::all ;
use Scalar::MoreUtils qw(empty);
#use XML::LibXML::PrettyPrint ; 

binmode STDOUT, ":utf8";

my $parser = XML::LibXML->new();
	
#my $doc = $parser->parse_file( 'newsreader_testset_20130409/100054B2-BBY1-JD34-P1B5.xml' );
my $doc = $parser->parse_file( "-");

# Print a temporary NAF file 
open TEMP, ">temp.naf" ; 
print TEMP $doc->toString(1);
# print TEMP XML::LibXML::PrettyPrint
#     -> new ( element => { compact => [qw/label/] } )
#     -> pretty_print($doc)
#     -> toString;

my %words ; 
my %sentWids ;
my %sentences ; 	
# First go through the text layer and store the words and word ids in sentences  	
for my $sample( $doc->findnodes('/NAF/text') ) 
	{
	foreach my $child ( $sample->getChildnodes ) 
		{
       	if ( $child->nodeType() == XML_ELEMENT_NODE ) 
       		{
       		my $sentid = $child->getAttribute('sent') ; 
       		$sentid =~ s/s// ; 
       		my $wid = $child->getAttribute('id') ; 
       		$wid =~ s/w//g ; 
       		$words{$wid} = $child->textContent(); 
   #       	print $child->nodeName(), ":", $child->getAttribute('sent')."\n" ;
    #       	print $child->nodeName(), ":", $child->getAttribute('wid')."\n" ;
     #      	print $child->nodeName(), ":", $child->textContent()."\n" ; 
           	if(exists($sentWids{$sentid}))
           		{
           		$sentWids{$sentid} = $sentWids{$sentid}." ".$wid ;
           		$sentences{$sentid} =  $sentences{$sentid}." ".$child->textContent() ; 
           		}
           	else
           		{
           		$sentWids{$sentid} = $wid ; 
           		$sentences{$sentid} = $child->textContent() ;
           		}
           	}
        }
    }

my %pos ; 
my %lemma ;
my %tids ; 

for my $sample( $doc->findnodes('/NAF/terms') ) 
	{
	foreach my $child ( $sample->getChildnodes ) 
		{
       	if ( $child->nodeType() == XML_ELEMENT_NODE ) 
       		{
			foreach my $grandchild ( $child->getChildnodes ) 
				{
       			if ( $grandchild->nodeType() == XML_ELEMENT_NODE ) 
       				{
       				 foreach my $greatgrandchild ( $grandchild->getChildnodes ) 
						{
       					if ( $greatgrandchild->nodeName() =~ "target" )
       						{ 
       						my $id = $greatgrandchild->getAttribute('id') ; 
       						$id =~ s/w//g ; 
       						$pos{$id} = $child->getAttribute('pos') ; 
       						$lemma{$id} = $child->getAttribute('lemma') ;
       				#		print $child->getAttribute('tid')." " ;
      				# 		print $greatgrandchild->nodeName(). ":", $id." ".$pos{$id}." ".$lemma{$id}."\n" ;
       				 		}
       				 	}
            		}
             	}
         	}
     	}
     }


# This is where the magic happens:
#   First we're going to find the event in the sentence
#   	For version 0.0.1 I'm using the verb as an event 
#	Once we have the event index, we're going to select 4 words
# 	preceding the event and 2 words following the event 
for my $sentence (sort {$a <=> $b } keys %sentWids)
	{
	# Remember that I made a big string that contains all Wids for words in particular sentence
	# I'm going to split that up again
	my $value = $sentWids{$sentence} ;
	my @wids = split/ /,$value ; 
	my @tids ; 
	# Now loop through the wids and look up the pos tag
	# if the pos tag starts with a V we're dealing with a verb
	my %event_index ;
	for(my $x = 0 ; $x < @wids ; $x++)
		{
		if(exists($pos{$wids[$x]}) && $pos{$wids[$x]} =~ /^V/)
			{
			$event_index{$x} = $wids[$x] ; 
			}
		}
	for my $events (sort {$a <=> $b } keys %event_index)
		{
		my $window ;
		if($events < 1)	{ $window = $words{$wids[$events]} ;}
		elsif($events < 2) { $window = $words{$wids[$events-1]}." ".$words{$wids[$events]} ;}
		elsif($events < 3) { $window = $words{$wids[$events-2]}." ".$words{$wids[$events-1]}." ".$words{$wids[$events]} ;	}
		elsif($events < 4) { $window = $words{$wids[$events-3]}." ".$words{$wids[$events-2]}." ".$words{$wids[$events-1]}." ".$words{$wids[$events]} ;	}
		else { $window = $words{$wids[$events-4]}." ".$words{$wids[$events-3]}." ".$words{$wids[$events-2]}." ".$words{$wids[$events-1]}." ".$words{$wids[$events]} ; }
		if($events == (scalar(@wids) - 2 )) { $window = $window." ".$words{$wids[$events+1]} ;}
		elsif($events != (scalar(@wids) - 1 )) { $window = $window." ".$words{$wids[$events+1]}." ".$words{$wids[$events+2]} ;}
		$window =~ s/\s+/ /g; 
		print $sentence."_".$wids[$events]."\tBOGUS\t".$window."\n" ;
		}
	}
	
	
