#!/bin/sh

# In order to run this example the following files must be downloaded in unpacked
# in the data folder

mkdir data
cd data 
wget https://trac.neo4j.org/export/2067/laboratory/users/andersn/imdb-app/src/test/data/test-actors.list.gz --no-check-certificate
wget https://trac.neo4j.org/export/2067/laboratory/users/andersn/imdb-app/src/test/data/test-movies.list.gz --no-check-certificate
gunzip test-actors.list.gz
gunzip test-movies.list.gz

