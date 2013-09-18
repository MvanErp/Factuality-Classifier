#!/usr/bin/perl -w 

use strict ; 

open FILE, $ARGV[0] ; 

while(my $input = <FILE>)
	{
	chomp $input ; 
	my %hash ; 
	my @fields = split/\t/, $input ;
	print $fields[0]."\t" ; 
	for(my $x = 1 ; $x < @fields ; $x = $x + 2)
		{
		$hash{$fields[$x]} = $fields[$x+1] ; 
		}
	my $first =  (sort { ($hash{$b} <=> $hash{$a}) } keys %hash)[0] ;
	print $first."\t".$hash{$first}."\n" ;
	#	{
   	#	 print "$_: $hash{$_}\t";
   	#	 printf "%.3f\t", $hash{$_} ;
	#	}	
	#print "\n------\n"
	}