#!/bin/bash

# Copy stdout and stderr via named pipe to stdout of container for logging.
_fifo="/container_stdout"
exec >  >(tee -ia "$_fifo")
exec 2> >(tee -ia "$_fifo" >&2)

_timing_sec_start=${SECONDS}
# Log call and parameters.
echo "[DEBUG] \"$0 $@\" called" > "$_fifo"

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
  echo "[ERROR] Configuration file ${path}/config.sh not found."
  exit 1
fi

set -a
. $path/config.sh
set +a

# myinstanceid=$(/opt/aws/bin/ec2-metadata --instance-id | cut -d\  -f2)

myinstanceid=$( curl -s http://169.254.169.254/latest/meta-data/instance-id )

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
	echo "[ERROR] Map $map_id already active."
	exit 0
    fi
fi

# Is map_id valid? Get subdomain from tag.
echo "[DEBUG] Looking for map_id in map repository."
output=$(aws s3api --region "$region" list-objects-v2 --bucket "$bucket" --prefix "${bucket_map_dir}/${map_id}.tgz" --query 'Contents[*].[Key]' --output text) 
errchk $? 'aws s3api list-objects-v2 call failed.'

if [ "${output}" == "None" ] ; then
  errchk 1 "Map with map_id $map_id not found in map repository."
fi
echo "[DEBUG] Found map with map_id $map_id in map repository."

echo "[DEBUG] Getting subdomain for map_id ${map_id}."
subdomain=$(aws s3api --region "$region" get-object-tagging --bucket "$bucket" --key "${bucket_map_dir}/${map_id}.tgz" --query "TagSet[?Key=='subdomain'].Value" --output text )
errchk $? 'aws get-object-tagging call failed.'

if [[ -z $subdomain || $subdomain == 'None' ]] ; then
    errchk 1 "$map_id is invalid or no subdomain specified in s3 object tags."
fi

# *** Check if map is in use by any other ec2 instance. ***
# instanceid=$(aws ec2 describe-instances --region "$region" --filters Name=instance-state-name,Values=running,shutting-down Name=tag:${instance_tagkey}=${instance_tagvalue} Name=tag:subdomain=${subdomain} --query Reservations[*].Instances[*].InstanceId --output text )
instanceid=$(aws ec2 describe-instances --region "$region" --filters Name=instance-state-name,Values=running,shutting-down Name=tag:${instance_tagkey} Name=tag:subdomain=${subdomain} --query Reservations[*].Instances[*].InstanceId --output text )
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
    echo "[DEBUG] Subdomain is unchanged. Skipping DNS update."
    dont_clear_dns='--dont_clear_dns'
fi
${bin_dir}/stop_map.sh $dont_clear_dns
errchk $? 'Could not stop and save map.'
echo '[DEBUG] Stopped prior running world.'

# *** Mark new map as in use now. ***
aws ec2 --region "$region" create-tags --resources $myinstanceid --tags Key=subdomain,Value=$subdomain > /dev/nul
errchk $? 'aws create-tags call failed.'

# Check if this is a different subdomain than the current active subdomain.
# *** Setup DNS ***
if [ -e $dns_stup ] ; then
    #     ipaddr=$(/opt/aws/bin/ec2-metadata --public-ipv4 | cut -d\  -f2)
    ipaddr=$( curl -s http://169.254.169.254/latest/meta-data/public-ipv4 )
    echo "[DEBUG] Aktualisiere Subdomain $subdomain auf $ipaddr."
    $dns_setup $subdomain $ipaddr > "$_fifo"
fi

# Remember new subdomain.
echo $subdomain > "${data_store}/subdomain.txt"

echo "[INFO] +++"
echo "[INFO] Server address: '${subdomain}:${HOST_MCPORT}'"
echo "[INFO] +++"

# Retrieve map files.
echo "[DEBUG] Downloading new map."
aws s3 --region "$region" cp "s3://${bucket}/${bucket_map_dir}/${map_id}.tgz" "${tmp_dir}" > /dev/nul
errchk $? "aws s3 cp call failed for s3://${bucket}/${bucket_map_dir}/${map_id}.tgz."

# Untar world files.
echo "[DEBUG] Unpacking map files to $map_data_dir."
tar xzf "${tmp_dir}/${map_id}.tgz" -C "$map_data_dir" > "$_fifo"
errchk $? "untar failed for ${tmp_dir}/${map_id}.tgz."

# Remember map_id in use.
echo $map_id > ${data_store}/map_id.txt

# Run app in docker container, unless --dontrun specified.
if [ -z "$dontrun" ] ; then
    echo "[DEBUG] Starting world."
    ${bin_dir}/compose_up.sh &>/dev/null
    errchk $? '[ERROR] Could not start container in compose_up.sh'
    echo "[INFO] World $map_id started."
fi
echo "[DEBUG] $0 ending, exec time:" $(( SECONDS - _timing_sec_start )) "seconds"
