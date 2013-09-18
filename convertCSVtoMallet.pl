#!/bin/perl -w 

# This is a script that converts a CSV file for WEKA into an input file for Mallet
# It contains an instance ID, followed by a tab, then the class, then a tab, followed
# by the feature values
#
# Marieke van Erp
# September 17 2013

use strict ; 

open FILE, $ARGV[0] ;

while (my $input = <FILE>)
	{
	chomp $input ;
	my @fields = split/,/,$input ;
	my $lineno = $. ; 
	$fields[0] =~ s/"//g ; 
	my $docid = $fields[0]."_".$lineno ; 	
	my $class = $fields[scalar(@fields)-1] ;
	$class =~ s/"//g ; 
	print $docid."\t".$class."\t" ;
	for (my $x = 9 ; $x < (scalar(@fields)-1) ; $x++) 
		{
		$fields[$x] =~ s/"//g ; 
		print $fields[$x]." " ;
		}
	print "\n" ;
	}
