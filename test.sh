#!/usr/bin/env bash

MODULENAME="pe"

docker build -t ${MODULENAME} .

docker run \
    -v "$(pwd)/input":/mnt/input \
    -v "$(pwd)/output":/mnt/output \
    -v "/data_mlsploit/data_malwarelab":/mnt/malwarelab \
    -v "/data_mlsploit/data_binary":/mnt/binary \
    -v "/data_mlsploit/data_ember":/mnt/ember \
    -v "/data_mlsploit/data_tmp":/mnt/tmp \
    --rm -it ${MODULENAME}
