# Steps to undertake to create and run the Factuality Classifier
# Marieke van Erp
# 8 September 2013 

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
head -n 1 NWRFactualityFeatureVectors.csv > NWRFactualityFeatureVectors.header
grep "RELSOURCELEVEL1" < NWRFactualityFeatureVectors.csv > NWRFactualityFeatureVectorsOnlyRelSourceLevel1.csv
cat NWRFactualityFeatureVectors.header NWRFactualityFeatureVectorsOnlyRelSourceLevel1.csv > NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeaders.csv

# Generate an ARFF File for WEKA to use
# Be sure to use WEKA 3-6-9 and not 3-7-9, the CSV Loader in the later version
# reads the file incrementally by default and will throw an error if the buffer
# size is too small (after 100 lines) 
# java.io.IOException: nominal value not declared in header, read Token[?]
# This is a pain!
# optional: $ export CLASSPATH=/path/to/your/weka-3-6-9/weka.jar
 
java weka.core.converters.CSVLoader NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeaders.csv > NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeaders.arff
 
# I found out that results improve if you remove the words following the event 
java weka.filters.unsupervised.attribute.Remove -R 14-16 -i NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeaders.arff -o NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeadersWOWordsAfterEvent.arff 

# This is the command to run a quick 10-fold cross-validation experiment to see how the classifier is doing
# Your "Correctly Classified Instances" should be: 7348 (77.486%) 
# if you followed the exact same steps 
java weka.classifiers.bayes.NaiveBayes -t NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeadersWOWordsAfterEvent.arff -x 10 -i

# But what we really want is to store the model and reuse it for new predictions
# so we are going to create a model from all the training data and store that
java weka.classifiers.bayes.NaiveBayes -t NWRFactualityFeatureVectorsOnlyRelSourceLevel1WithHeadersWOWordsAfterEvent.arff -d NaiveBayesModel-8-september.model
