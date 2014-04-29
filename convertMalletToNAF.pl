#!/usr/bin/perl -w 

use strict ; 
use XML::LibXML ;
#use XML::LibXML::PrettyPrint;
use Data::Dumper ;  
#use utf8::all ;
use Scalar::MoreUtils qw(empty);

open FILE, $ARGV[1] ;
binmode FILE, ":utf8";
open BEGINTIME, "begintimestamp.txt" ;

my $begintime ; 
while(my $input = <BEGINTIME>)
	{
	chomp $input ; 
	$begintime = $input ; 
	} 

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
my $doc = $parser->parse_file($ARGV[0]) ;

# insert a new element in the term layer 
for my $sample( $doc->findnodes('/NAF') ) 
	{
	my $factlayer = $doc->createElement( 'factualitylayer' );
	$sample->addChild($factlayer) ;
	foreach my $key (keys %predictions)
		{
		my $factvalue = $doc->createElement( 'factvalue' );
		$factlayer->addChild($factvalue) ; 
		my $factspan = $doc->createElement( 'span' );
		$factvalue->addChild($factspan) ;
		$factspan->setAttribute('id', $key) ; 
		$factspan->setAttribute('prediction', $predictions{$key}) ; 
		$factspan->setAttribute('confidence', $confidence{$key}) ; 
		}
	}

# insert factuality info in the header 
my $timestamp = localtime(time);
for my $sample ($doc->findnodes('/NAF/nafHeader') )
	{
    my $factheader = $doc->createElement('linguisticProcessor');
	$sample->addChild($factheader);
	$factheader->setAttribute('layer', 'factuality');
	my $factlayerstats = $doc->createElement('lp');
	$factheader->addChild($factlayerstats);
	$factlayerstats->setAttribute('name', 'vua-factuality');
	$factlayerstats->setAttribute('beginTimestamp', $begintime);
	$factlayerstats->setAttribute('endTimestamp', &get_datetime());
	$factlayerstats->setAttribute('version', '1.1');	
	}

print $doc->toString(1);
# print XML::LibXML::PrettyPrint
#     -> new ( element => { compact => [qw/label/] } )
#     -> pretty_print($doc)
#     -> toString;

sub get_datetime {

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
return sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}