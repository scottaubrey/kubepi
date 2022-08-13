#!/bin/bash
set -e

generate_config.sh $1

# use cached version if available
if [ -f $WORKDIR/cached.img ]; then
    image=$WORKDIR/cached.img
else
    image=$IMAGE_URL
fi

echo "image=$image"

#flash it!
flash   -u $WORKDIR/$hostname/user-data \
        -F $WORKDIR/$hostname/network-config \
        $image
