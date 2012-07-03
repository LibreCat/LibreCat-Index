#!/bin/bash

PROJECT_DIR=${HOME}/Dev/Catmandu-Meercat/multicore
WORKDIR="${HOME}/Dev/apache-solr-3.6.0-src/solr/example"

cd ${WORKDIR}

java -Xmx1048m -Dsolr.solr.home=${PROJECT_DIR} -jar start.jar
