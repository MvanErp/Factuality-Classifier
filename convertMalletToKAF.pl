#!/usr/bin/perl -w 

use strict ; 
use XML::LibXML ;
use XML::LibXML::PrettyPrint;
use Data::Dumper ;  
use utf8::all ;
use Scalar::MoreUtils qw(empty);

open FILE, $ARGV[1] ;
my %predictions ; 
my %confidence ; 
while(my $input = <FILE>)
	{
	chomp $input ; 
	my @fields = split/\t/,$input ;
	my @ids = split/_/,$fields[0] ;
	my $wid = "w".$ids[1] ; 
	$predictions{$wid} = $fields[1] ;
	$confidence{$wid} = $fields[2] ;
	}

my $parser = XML::LibXML->new();

#my $doc = $parser->parse_file( 'newsreader_testset_20130409/100054B2-BBY1-JD34-P1B5.xml' );
#my $doc = $parser->parse_file( $ARGV[0] );
my $doc = $parser->parse_file($ARGV[0]) ;

# insert a new element in the term layer 
for my $sample( $doc->findnodes('/KAF') ) 
	{
	my $factlayer = $doc->createElement( 'factualitylayer' );
	$sample->addChild($factlayer) ;
	foreach my $key (keys %predictions)
		{
		my $factvalue = $doc->createElement( 'factvalue' );
		$factlayer->addChild($factvalue) ; 
		$factvalue->setAttribute('wid', $key) ; 
		$factvalue->setAttribute('prediction', $predictions{$key}) ; 
		$factvalue->setAttribute('confidence', $confidence{$key}) ; 
		}
	}


print XML::LibXML::PrettyPrint
    -> new ( element => { compact => [qw/label/] } )
    -> pretty_print($doc)
    -> toString;