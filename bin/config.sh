#!/bin/bash
# Values from ENVIRONMENT.
instance_tagkey="$AWS_TAGKEY"
instance_tagvalue="$AWS_TAGVALUE"
bucket="$MAP_BUCKET"
bucket_map_dir="${BUCKET_MAP_DIR:-maps}"
bucket_logs_dir="${BUCKET_LOGS_DIR:-logs}"
region="${REGION}"

# Constants.
bin_dir="${INSTALL_DIR}/bin"
data_store="${INSTALL_DIR}"
map_data_dir="${data_store}/map_data"
# worlds_dir="${map_data_dir}/worlds"
map_logs_dir="${data_store}/map_logs"
# dns_setup="${bin_dir}/setup_dns_twodns.sh"
dns_setup="${bin_dir}/setup_dns_route53.py"
tmp_dir='/tmp'
docker_compose='/usr/local/bin/docker-compose'
