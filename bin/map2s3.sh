#!/bin/bash
# Packs a map and stores it in s3.

# Copy stdout and stderr via named pipe to stdout of container for logging.
_fifo="/container_stdout"
exec >  >(tee -ia "$_fifo")
exec 2> >(tee -ia "$_fifo" >&2)

# Log call and parameters.
echo "[DEBUG] \"$0 $@\" called" > "$_fifo"

_timing_sec_start=${SECONDS}

errchk() {
  if [ ! $1 == 0 ] ; then
    echo '*** ERROR ***' 1>&2
    echo "[ERROR]" $2 1>&2
    echo 'Exiting.' 1>&2
    exit 1
  fi
}

path=$(dirname $0)

if [ ! -e ${path}/config.sh ] ; then
  echo "[ERROR] Configuration file ${path}/config.sh not found."
  exit 1
fi

set -a
. $path/config.sh
set +a

# Load map id if not specified as parameter.
map_id="$1"
if [ -z "${map_id}" ] ; then
    if [ ! -e "${data_store}/map_id.txt" ] ; then
        echo "[ERROR] No map active."
        exit 1
    fi
fi
map_id=$(cat "${data_store}/map_id.txt")

subdomain="$2"
if [ -z "${subdomain}" ] ; then
    if [ ! -e "${data_store}/subdomain.txt" ] ; then
        echo "[ERROR] No map active."
        exit 1
    fi
fi
subdomain=$(cat "${data_store}/subdomain.txt")

if [ -e "${tmp_dir}/${map_id}.tgz" ] ; then
    rm "${tmp_dir}/${map_id}.tgz" > /dev/nul
fi
tar czf "${tmp_dir}/${map_id}.tgz" -C "${map_data_dir}" . > /dev/nul

echo "[DEBUG] Uploading ${map_id}.tgz"
aws s3 --region "$region" cp "${tmp_dir}/${map_id}.tgz" "s3://${bucket}/${bucket_map_dir}/" > /dev/nul
errchk $? "aws s3 cp call failed for s3://${bucket}/${bucket_map_dir}/${map_id}.tgz."

echo "[DEBUG] Setting subdomain and marking as 'do-not-archive' (keep=false)."
versionid=$( aws s3api --region "$region" put-object-tagging --bucket "$bucket" --key "${bucket_map_dir}/${map_id}.tgz" --tagging "TagSet=[{Key=subdomain,Value=${subdomain}},{Key=keep,Value=false}]" --output text )
errchk $? 'aws put-object-tagging call failed.'

echo "[DEBUG] Created s3 object s3://${bucket}/${bucket_map_dir}/${map_id}.tgz has version id ${versionid}."
rm "${tmp_dir}/${map_id}.tgz" > /dev/nul
echo "[DEBUG] $0 ending, exec time:" $(( SECONDS - _timing_sec_start )) "seconds"
