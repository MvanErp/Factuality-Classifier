# Steps to undertake to create and run the Factuality Classifier
# This is a full report of the steps done, to classify a new document
# skip to line 34. 
#
# Author: Marieke van Erp
# Date: 18 September 2013 

# Generate factuality.csv from the FactBank 1.0 database:
SELECT DISTINCT sentences.file, sentences.sentId, tml_event.eId, tml_event.eClass, fb_factValue.eText, fb_factValue.eId, tml_instance.tense, tml_instance.aspect, tml_instance.pos, tml_instance.polarity, fb_factValue.relSourceText, sentences.sent, fb_factValue.factValue INTO OUTFILE '/tmp/factuality.csv'
FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n' FROM sentences JOIN tml_event ON (sentences.file = tml_event.file AND sentences.sentId = tml_event.sentId) JOIN fb_relSource ON (sentences.file = fb_relSource.file AND sentences.sentId = fb_relSource.sentId) JOIN fb_factValue ON (tml_event.file = fb_factValue.file AND tml_event.sentId = fb_factValue.sentId AND tml_event.eId = fb_factValue.eId) JOIN tml_instance ON (tml_event.file = tml_instance.file AND tml_event.eId = tml_instance.eId)

# copy to your working directory
cp '/tmp/factuality.csv' . 

# Generate the feature vectors:
# Note: factuality.csv is not included due to the FactBank data license.
perl NWRFactualityCreateFeatureVectors.pl > NWRFactualityFeatureVectors.csv

# You get better results without the nested sources
# to only consider unnested factuality values do: 
grep "RELSOURCELEVEL1" < NWRFactualityFeatureVectors.csv > NWRFactualityFeatureVectorsOnlyRelSourceLevel1.csv

# Mallet doesn't take csv, so we're converting to ID	LABEL	DATA
# format, also for version 0.01 we're only using a window around the event
perl convertCSVtoMallet.pl NWRFactualityFeatureVectorsOnlyRelSourceLevel1.csv > FactBank.tab 

# Generate a suitable input file for Mallet
# This command assumes that Mallet is located in the working directory
mallet-2.0.7/bin/mallet import-file --input FactBank.tab --output FactBank.vectors  

# Train a MaxEnt classifier on the FactBank data
mallet-2.0.7/bin/mallet train-classifier --trainer MaxEnt --input FactBank.vectors --output-classifier MyMaxEntFactuality.classifier

################
#
# This is where the classification begins
#
################

# Take a kaf file as input and generate the Mallet format (ID	LABEL	DATA)
perl KAFToMalletInputFactuality.pl FILE.kaf > FILE.tab

# Classify the instances from the input file  
mallet-2.0.7/bin/csv2classify --input FILE.tab --output FILE.output --classifier MyMaxEntFactuality.classifier

# Sort Mallet output and select the highest score
# Output the id, prediction and confidence
perl sortMalletOutput.pl FILE.output > FILE.sorted

# Read in output file as well as original KAF file and insert a factuality layer with factuality score, confidence and word (or term?) ID. 
perl convertMalletToKAF.pl FILE.kaf FILE.sorted > FILE.factuality.kaf
