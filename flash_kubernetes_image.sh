#!/bin/bash
set -e

source generate_config.sh $1

if [ "$cache_image" == "true" ] && [ ! -f $work_dir/cached.img ]; then
  curl $image_url -o  $work_dir/cached.img.xz
  xz -d $work_dir/cached.img.xz
  # rm $work_dir/cached.img.xz
fi

# use cached version if available
if [ -f $work_dir/cached.img ]; then
    image=$work_dir/cached.img
else
    image=$image_url
fi

echo "image=$image"

#flash it!
flash   -u $work_dir/$nodename/user-data \
        -F $work_dir/$nodename/network-config \
        $image
