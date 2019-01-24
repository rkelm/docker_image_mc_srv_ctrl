#!/bin/bash

errchk() {
  if [ ! $1 == 0 ] ; then
    echo '*** ERROR ***' 1>&2
    echo $2 1>&2
    echo 'Exiting.' 1>&2
    exit 1
  fi
}

print_usage() {
    echo 'usage: run_map.sh <map_id> [--dontrun]';
    echo
    echo '  --dontrun  Only load new map, do not run it.'
}

path=$(dirname $0)

if [ ! -e ${path}/config.sh ] ; then
  echo Configuration file ${path}/config.sh not found.
  exit 1
fi

set -a
. $path/config.sh
set +a

myinstanceid=$(/opt/aws/bin/ec2-metadata --instance-id | cut -d\  -f2)

# *** Check parameters / show usage. ***
map_id=$1
if [ -z "$map_id" ] ; then
    print_usage
    exit 1
fi

if [ "$map_id" == '-h' ] ; then
    print_usage
    exit 1
fi

if [ -n "$2" ] ; then
    if [ "$2" == "--dontrun" ] ; then
	dontrun='--dontrun'
    else 
	print_usage
	exit 1
    fi
fi

# Check if map already active.
if [ -e "${data_store}/map_id.txt" ] ; then
    old_map_id=$(cat "${data_store}/map_id.txt")
    if [ "$map_id" == "$old_map_id" ] ; then
	echo "Map $map_id already active."
	exit 0
    fi
fi

# Is map_id valid? Get subdomain from tag.
echo "Looking for map_id in map repository."
output=$(aws s3api --region "$region" list-objects-v2 --bucket "$bucket" --prefix "${bucket_map_dir}/${map_id}.tgz" --query 'Contents[*].[Key]' --output text) 
errchk $? 'aws s3api list-objects-v2 call failed.'

if [ "${output}" == "None" ] ; then
  errchk 1 "Map with map_id $map_id not found in map repository."
fi
echo "Found map with map_id $map_id in map repository."

echo "Getting subdomain for map_id ${map_id}."
subdomain=$(aws s3api --region "$region" get-object-tagging --bucket "$bucket" --key "${bucket_map_dir}/${map_id}.tgz" --query "TagSet[?Key=='subdomain'].Value" --output text )
errchk $? 'aws get-object-tagging call failed.'

if [[ -z $subdomain || $subdomain == 'None' ]] ; then
    errchk 1 "$map_id is invalid or no subdomain specified in s3 object tags."
fi
echo "Retrieved subdomain name $subdomain."

# *** Check if map is in use by any other ec2 instance. ***
instanceid=$(aws ec2 describe-instances --region "$region" --filters Name=instance-state-name,Values=running,shutting-down Name=tag:${instance_tagkey}=${instance_tagvalue} Name=tag:subdomain=${subdomain} --query Reservations[*].Instances[*].InstanceId --output text )
errchk $? 'aws describe-instances call failed.'

if [ ! -z $instanceid ] ; then
  errchk 1 "Die Subdomain $subdomain von Map $map_id wird noch von EC2 Instance $instanceid verwendet. Die andere EC2 Instanz muss die Map erst beenden, bevor die Map auf dieser gestartet werden kann."
fi

# *** Save currently running map. ***
# Check if this is a different subdomain than the current active subdomain.
if [ -e ${data_store}/subdomain.txt ] ; then
    old_subdomain=$(cat ${data_store}/subdomain.txt)
fi
if [ "$subdomain" == "$old_subdomain" ] ; then
    echo "Subdomain is unchanged. Skipping DNS update."
    dont_clear_dns='--dont_clear_dns'
fi
${bin_dir}/stop_map.sh $dont_clear_dns
errchk $? 'Could not stop and save map.'

# *** Mark new map as in use now. ***
aws ec2 --region "$region" create-tags --resources $myinstanceid --tags Key=subdomain,Value=$subdomain 
errchk $? 'aws create-tags call failed.'

# Check if this is a different subdomain than the current active subdomain.
# *** Setup DNS ***
if [ -e $dns_setup ] ; then
    ipaddr=$(/opt/aws/bin/ec2-metadata --public-ipv4 | cut -d\  -f2)
    echo Aktualisiere Subdomain $subdomain auf $ipaddr.
    $dns_setup $subdomain $ipaddr
fi

# Remember new subdomain.
echo $subdomain > "${data_store}/subdomain.txt"

# Retrieve map files.
aws s3 --region "$region" cp "s3://${bucket}/${bucket_map_dir}/${map_id}.tgz" "${tmp_dir}"
errchk $? "aws s3 cp call failed for s3://${bucket}/${bucket_map_dir}/${map_id}.tgz."

# Untar world files.
echo "Unpacking map files to $map_data_dir."
tar xzf "${tmp_dir}/${map_id}.tgz" -C "$map_data_dir"
errchk $? "untar failed for ${tmp_dir}/${map_id}.tgz."

# Remember map_id in use.
echo $map_id > ${data_store}/map_id.txt

# Run app in docker container, unless --dontrun specified.
if [ -z "$dontrun" ] ; then
    ${bin_dir}/compose_up.sh
fi
