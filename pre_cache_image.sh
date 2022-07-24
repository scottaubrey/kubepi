#!/bin/bash
source  kubepi.conf

if [ -f $WORKDIR/cached.img ]; then
    exit 0
fi

curl $IMAGE_URL | xz -d > $WORKDIR/cached.img