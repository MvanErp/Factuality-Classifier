#!/bin/bash

# Convert NAF file to Mallet input file 
perl NAFToMalletInputFactuality.pl > malletinput.tab

# Run the mallet classifier 
mallet-2.0.7/bin/csv2classify --input malletinput.tab --output malletoutput.txt --classifier MyMaxEntFactuality.classifier

# Sort the output in order to be able to select the best prediction and its confidence
perl sortMalletOutput.pl malletoutput.txt > malletoutput.sorted

# Write back to NAF 
perl convertMalletToNAF.pl temp.naf malletoutput.sorted 

# Clean up
rm temp.naf malletinput.tab malletoutput.txt  malletoutput.sorted