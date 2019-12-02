#!/usr/bin/env bash

MODULENAME="pe"

docker build -t ${MODULENAME} .

docker run \
    -v "$(pwd)/input":/mnt/input \
    -v "$(pwd)/output":/mnt/output \
    -v "/data_malwarelab":/mnt/malwarelab \
    -v "/data_binary":/mnt/binary \
    --rm -it ${MODULENAME}
