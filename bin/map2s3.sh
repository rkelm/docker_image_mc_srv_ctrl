#!/bin/bash
# Packs a map and stores it in s3.

errchk() {
  if [ ! $1 == 0 ] ; then
    echo '*** ERROR ***' 1>&2
    echo $2 1>&2
    echo 'Exiting.' 1>&2
    exit 1
  fi
}

path=$(dirname $0)

if [ ! -e ${path}/config.sh ] ; then
  echo Configuration file ${path}/config.sh not found.
  exit 1
fi

set -a
. $path/config.sh
set +a

# Load map id if not specified as parameter.
map_id="$1"
if [ -z "${map_id}" ] ; then
    if [ ! -e "${data_store}/map_id.txt" ] ; then
        echo "No map active."
        exit 1
    fi
fi
map_id=$(cat "${data_store}/map_id.txt")

subdomain="$2"
if [ -z "${subdomain}" ] ; then
    if [ ! -e "${data_store}/subdomain.txt" ] ; then
        echo "No map active."
        exit 1
    fi
fi
subdomain=$(cat "${data_store}/subdomain.txt")

if [ -e "${tmp_dir}/${map_id}.tgz" ] ; then
    rm "${tmp_dir}/${map_id}.tgz"
fi
tar czf "${tmp_dir}/${map_id}.tgz" -C "${map_data_dir}" .

echo "Uploading ${map_id}.tgz"
aws s3 --region "$region" cp "${tmp_dir}/${map_id}.tgz" "s3://${bucket}/${bucket_map_dir}/"
errchk $? "aws s3 cp call failed for s3://${bucket}/${bucket_map_dir}/${map_id}.tgz."

echo "Setting subdomain"
echo "Marking as 'do-not-archive' (keep=false)."
versionid=$( aws s3api --region "$region" put-object-tagging --bucket "$bucket" --key "${bucket_map_dir}/${map_id}.tgz" --tagging "TagSet=[{Key=subdomain,Value=${subdomain}},{Key=keep,Value=false}]" --output text )
errchk $? 'aws put-object-tagging call failed.'

echo "Created s3 object s3://${bucket}/${bucket_map_dir}/${map_id}.tgz has version id ${versionid}."
rm "${tmp_dir}/${map_id}.tgz"
