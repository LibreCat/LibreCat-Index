#!/bin/bash

echo -n "Start: "
date

for db in rug01 rug02 rug03 dbs01 bkt01 ebk01 pug01 ser01 ejn01 cgw01 cgw02 cgw03 cgw04 ath01 ovk01; do
        zcat ../multicore/exampledocs/${db}.sample.gz | ./meercat_index.pl -v --clear ${db} -
done

echo -n " End: "
date
