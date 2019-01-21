#!/bin/bash
# Check for curl.
curl_bin=$(which curl)
if [ ! -e $curl_bin ] ; then
    echo $curl_bin not found 
    exit 1
fi

# Check call parameters.
subdomain=$1
ipaddr=$2
if [ -z $subdomain ] ; then
    echo 'Usage: setup_dns_twodns.sh <hostname> <ipaddr>'
    exit 1
fi

if [ -z $ipaddr ] ; then 
    echo 'Usage: setup_dns_twodns.sh <hostname> <ipaddr>'
    exit 1
fi

# Set environment variables for call to update dynDNS service.
directory=$( dirname "${BASH_SOURCE[0]}" )
auth_file="$directory/twodns_config.sh"
if [ ! -z $auth_file ] ; then 
  source $auth_file
else
  echo 'setup_dns_twodns.sh: Missing authentication file $auth_file.'
  exit 1 
fi

echo "$(date -Iseconds) updating $subdomain to ip $ipaddr (twodns service)"
# $curl_bin -s -k "https://www.goip.de/setip?username=$dns_user&password=$dns_pw&subdomain=$subdomain&ip=$ipaddr&shortResponse=true"
$curl_bin -s -k -X PUT -u "${dns_user}:${api_token}" -d '{"'"ip_address"'": "'"${ipaddr}"'", "'"ttl"'": "'"300"'"}' https://api.twodns.de/hosts/${subdomain} 

