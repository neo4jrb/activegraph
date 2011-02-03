#!/bin/sh

# In order to run this example the following files must be downloaded in unpacked
# in the data folder

mkdir data
cp *.gz data
cd data 

gunzip test-actors.list.gz
gunzip test-movies.list.gz