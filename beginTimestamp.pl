#!/usr/bin/perl -w 

use strict ;

my $timestamp = &get_datetime();
open FILE, ">begintimestamp.txt" ; 
print FILE $timestamp ;

sub get_datetime {

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
return sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec;
}