#!/bin/bash

PROJECT_DIR=${HOME}/Dev/Catmandu-Meercat
WORKDIR="${HOME}/Dev/apache-solr-3.6.0-src/solr/example"

cd ${WORKDIR}

#java -d64 -server -Xmx1024m -Xms512m -XX:+AggressiveOpts -XX:NewRatio=5 -Dsolr.solr.home=${PROJECT_DIR}/multicore -Djava.util.logging.config.file=etc/logging.properties -jar start.jar
java -d64 -server -Xmx1024m -Xms512m -XX:+AggressiveOpts -XX:NewRatio=5 -Dsolr.solr.home=${PROJECT_DIR}/multicore -jar start.jar
