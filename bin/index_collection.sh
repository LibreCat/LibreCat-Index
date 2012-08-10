#!/bin/bash

for db in rug01 rug02 rug03 dbs01 bkt01 ebk01 pug01 ser01 ejn01; do
  if [ $db == "ejn01" ]; then
    zcat /vol/indexes/incoming/${db}.export.gz | ./marcxml_aleph.pl - | ./meercat_index.pl -v --clear ${db} -
  else
    zcat /vol/indexes/incoming/${db}.export.gz | ./meercat_index.pl -v --clear ${db} -
  fi
done
