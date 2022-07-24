#!/bin/bash
set -e

if [ ! -f kubepi.conf ]; then
    echo "ERROR: config file not present"
    exit 1
fi

# import the config
source kubepi.conf

# this script requires a node prefix, as configured in the `config.var` file.
nodename="$1";
nodename="$(echo "${nodename}" | tr  '[:lower:]' '[:upper:]')";  # uppercase the whole string

hostname_var="${nodename}_HOSTNAME";
address_var="${nodename}_ADDRESS";
data_drive_uuid_var="${nodename}_DATA_DRIVE_UUID";

if [ -z ${!hostname_var} ]; then
    echo "This script requires the first parameter to be a a node prefix defined in the kubepi.conf file, could not find $nodename in config file"
    exit 1;
fi


# set variables for the templates and the workdir
hostname="${!hostname_var}"
address="${!address_var}"
data_drive_uuid="${!data_drive_uuid_var}"

echo "hostname=$hostname, address=$address, data_drive_uuid=$data_drive_uuid"


# create temporary directory and clean up as needed
rm -R $WORKDIR/$hostname/ 2> /dev/null || true
mkdir -p $WORKDIR/$hostname

# generate the hosts file addon
printf "%s %s\n" "${address}" "${hostname}.$NODE_DOMAIN" >> $WORKDIR/$hostname/hosts
hosts_file_encoded=$(cat $WORKDIR/$hostname/hosts | base64)

#generate base64 encoded content from script files
kubepi_script="$( cat scripts/kubepi | base64 )"

# generate (or not) the data drive fstab line
fstab=""
if [ ! -z $data_drive_uuid ]; then
    fstab="UUID=$data_drive_uuid /data ext4 auto,nofail,noatime,rw 0 2"
fi

user_data_template=$(cat templates/user-data)
eval "echo \"${user_data_template}\"" > $WORKDIR/$hostname/user-data

network_config_template=$(cat templates/network-config)
eval "echo \"${network_config_template}\"" > $WORKDIR/$hostname/network-config

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
