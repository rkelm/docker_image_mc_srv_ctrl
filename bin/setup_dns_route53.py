#!/usr/bin/python3

import sys
import boto3
import os
import toml

if os.getenv("USERPROFILE") :
    config_file_path = os.environ["USERPROFILE"] + "\\route53_config.toml"
else:
    config_file_path = "route53_config.toml"

def showusage():
    print("setup_dns_route53.py <subdomain> <ip-adress>")
    return

# Check parameters
if len(sys.argv) > 1 :
    Hostname = sys.argv[1]
else:
    showusage()
    raise Exception("Missing command line parameters.")

if len(sys.argv) > 2 :
    IpAddress = sys.argv[2]
else:
    IpAddress = None

# Load configuration
ConfigLoaded = False
HostedZoneId = None
try: 
    config = toml.load(open(config_file_path))
    if not "credentials" in config: 
        raise Exception("Missing ""credentials"" section in toml configuration file.")
    
    if not "aws_access_key_id" in config["credentials"]:
        raise Exception("Missing ""aws_access_key_id"" key in toml configuration file.")

    if not "aws_secret_access_key" in config["credentials"]:
        raise Exception("Missing ""aws_secret_access_key"" key in toml configuration file.")

    aws_secret_key_id = config["credentials"]["aws_access_key_id"]
    aws_secret_access_key = config["credentials"]["aws_secret_access_key"]

    # Lookup HostedzoneId.
    if not "hostedzoneids" in config:
        raise Exception("Missing ""hostedzoneids"" section in toml configuration file.")

    found = False
    HostedZone = Hostname
    HostedZoneId = ""
    while not HostedZoneId:
        if HostedZone in config["hostedzoneids"]:
            HostedZoneId = config["hostedzoneids"][HostedZone]
        i = HostedZone.find(".") 
        if i < 0 :
            raise Exception("No Hosted Zone ID configured for \"" + Hostname + "\".")
        HostedZone = HostedZone[i+1:]

    ConfigLoaded = True
except FileNotFoundError:
    print("Configuration file " + config_file_path + " not found.")

# Try to load configuration from environment    
if not ConfigLoaded and os.getenv('AWS_ACCESS_KEY_ID') :
    print("Loading aws credentials from environment.")
    aws_access_key_id = os.environ['AWS_ACCESS_KEY_ID']
    aws_secret_access_key = os.environ['AWS_SECRET_ACCESS_KEY']
    ConfigLoaded = True

# Pass aws credentials if given.
if ConfigLoaded :
    route53 = boto3.client(
        "route53",
        aws_access_key_id = aws_access_key_id,
        aws_secret_access_key = aws_secret_access_key)
else:
    route53 = boto3.client(
        "route53")

# Discover hostedzone id if not known.
if HostedZoneId is None :
    HostedZone = Hostname
    HostedZoneId = ""
    while not HostedZoneId:
        response = route53.list_hosted_zones_by_name(
            DNSName=HostedZone)
        if len(response['HostedZones']) > 0 :
            HostedZoneId = response['HostedZones'][0]['Id']
            break;
        
        i = HostedZone.find(".") 
        if i < 0 :
            raise Exception("Hosted Zone ID not configured and not listed in AWS account for \"" + Hostname + "\".")
        HostedZone = HostedZone[i+1:]

        
# Update Hostename

if not IpAddress is None:
    # This is a UPSERT operation.
    response = route53.change_resource_record_sets(
        HostedZoneId=HostedZoneId,
        ChangeBatch={
            "Comment": "string",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": Hostname,
                        "Type": "A",
                        "TTL": 60,
                        "ResourceRecords": [
                            {
                                "Value": IpAddress                        },
                        ],
                    }
                },
            ]
        }
    )
    print("Setting \"" + Hostname + "\" to \"" + IpAddress + "\" and TTL = 60.")
else:
    # This is a DELETE operation.
    # Discover existing values for Hostname
    response = route53.list_resource_record_sets(
        HostedZoneId=HostedZoneId,
        StartRecordName=Hostname,
        StartRecordType='A',
        MaxItems='1')
    
    if len(response['ResourceRecordSets']) > 0 and response['ResourceRecordSets'][0]['Name']==Hostname+'.' :
        CBatch={
            "Changes": [
                {
                    "Action": "DELETE",
                    "ResourceRecordSet": {
                        "Name": Hostname,
                        "Type": "A",
                        "TTL" : response['ResourceRecordSets'][0]['TTL'],
                    "ResourceRecords": [
                        {  "Value": response['ResourceRecordSets'][0]['ResourceRecords'][0]['Value']                  },
                    ],
                    }
                }
            ]
        }
        response = route53.change_resource_record_sets(
            HostedZoneId=HostedZoneId,
            ChangeBatch=CBatch
        )
        print("Deleting \"" + Hostname + "\" .")
    else:
        print('Resource record of type A not found for "' + Hostname + '".')
        
