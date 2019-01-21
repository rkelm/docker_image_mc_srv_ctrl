#!/usr/bin/python

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
if len(sys.argv) > 2 :
  Hostname = sys.argv[1]
  IpAddress = sys.argv[2]
else:
    showusage()
    raise Exception("Missing command line parameters.")

# Load configuration
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

# bla.blubber.de
except FileNotFoundError:
    print("Configuration file " + config_file_path + " not found.")
    print("Exiting.")
    exit(1)


# Load aws credentials
route53 = boto3.client(
    "route53",
    aws_access_key_id = aws_secret_key_id,
    aws_secret_access_key = aws_secret_access_key)

response = route53.change_resource_record_sets(
    HostedZoneId=HostedZoneId,
    ChangeBatch={
     'Comment': 'string',
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': Hostname,
                    'Type': 'A',
                    'TTL': 60,
                    'ResourceRecords': [
                        {
                            'Value': IpAddress                        },
                    ],
                }
            },
        ]
    }
)

# Check response
print("Setting \"" + Hostname + "\" to \"" + IpAddress + "\" and TTL = 60.")
