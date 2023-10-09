#!/bin/bash
set -e

if [ ! -f config.yaml ]; then
    echo "ERROR: config file not present"
    exit 1
fi

config=$(cat config.yaml)

config_exists () {
    local value=$(yq "$1" config.yaml)

    if [ "$value" == "null" ]; then
        return 1
    fi
    return 0
}

config_value () {
    echo "$(yq "$1" config.yaml)"
}

work_dir=$(config_value ".workDir")
image_url=$(config_value ".imageUrl")
cache_image=$(config_value ".cacheImage")
token=$(config_value ".token")
echo "work_dir=$work_dir token=$token cache_image=$cache_image"

# Create work_dir if we can
if [ ! -d $work_dir ]; then
    mkdir $work_dir
fi

# get full path to workdir
work_dir=$(realpath $work_dir)




# get network details
network_cidr_suffix=$(config_value ".network.cidrSuffix")
network_gateway=$(config_value ".network.gateway")
network_dns_server=$(config_value ".network.dnsServer")
echo "network_cidr_suffix=$network_cidr_suffix network_gateway=$network_gateway network_dns_server=$network_dns_server"


node_domain=$(config_value ".domain")
echo "node_domain=$node_domain"

# this script requires a node prefix, as configured in the `config.var` file.
nodename="$1";

if ! config_exists ".nodes.$nodename"; then
    echo 'This script requires the first parameter to be a a node prefix defined in the config.yaml file under the "nodes" key, could not find $nodename in config file'
    exit 1;
fi


# set variables for the templates and the workdir
hostname=$(config_value ".nodes.$nodename.hostname")
address=$(config_value ".nodes.$nodename.address")

echo "hostname=$hostname, address=$address"

# create temporary directory and clean up as needed
rm -R $work_dir/$hostname/ 2> /dev/null || true
mkdir -p $work_dir/$hostname

# generate the hosts file addon
hosts_file_encoded="$(config_value '.nodes|to_entries|.[].value|.address + " " + .hostname' | base64)"

dns_command="echo no dns server"
if [ $( config_value '.nodes.'$nodename'.roles|any_c(. == "dns")' ) == "true" ]; then
    dns_command="sudo apt-get install -y dnsmasq"
fi

k3s_url=""
if [ $( config_value '.nodes.'$nodename'.roles|any_c(. == "node")' ) == "true" ]; then
    k3s_url=$( config_value '.k3s_url' )
fi


# User templates
user_ssh_pub_key="$( config_value '.user.sshPubKey' )"
user_username="$( config_value '.user.username' )"
echo "user_username=$user_username user_ssh_pub_key=$user_ssh_pub_key"


flux_cli="echo no flux configured"
if [ $( config_value '.nodes.'$nodename'.roles|any_c(. == "controller")' ) == "true" ]; then
    # gitops (flux) integration
    if config_exists ".flux" && config_exists ".flux.gitProvider"; then
        flux_cli="KUBECONFIG=/etc/rancher/k3s/k3s.yaml GITHUB_TOKEN="$( config_value '.flux.token' )" flux bootstrap $( config_value '.flux.gitProvider' ) $( config_value  '.flux.flags|with_entries(.value = "--"+(.key)+"=\""+(.value)+"\"")|to_entries|[.[].value]|join(" ")')"
    fi
fi
echo "flux_cli=${flux_cli}"

zerotier_cli="echo no zerotier configured"
# gitops (flux) integration
if config_exists ".zerotier_network"; then
    zerotier_cli="zerotier-cli join $( config_value '.zerotier_network' )"
fi
echo "zerotier_cli=${zerotier_cli}"

user_data_template=$(cat templates/user-data)
eval "echo \"${user_data_template}\"" > $work_dir/$hostname/user-data

network_config_template=$(cat templates/network-config)
eval "echo \"${network_config_template}\"" > $work_dir/$hostname/network-config



