#!/bin/bash

path=$(dirname $0)

if [ ! -e ${path}/../config.sh ] ; then
  echo Configuration file ${path}/../config.sh not found.
  exit 1
fi

. ${path}/../config.sh

_dont_clear_dns="$1"

if [ -z "$map_data_dir" ] ; then
  echo "Variable map_data_dir not set!"
  exit 1
fi

if [ ! -d "$map_data_dir" ] ; then
  echo "$map_data_dir is not a directory"
  exit 1
fi

if [ -z "$map_logs_dir" ] ; then
  echo "Variable map_logs_dir not set!"
  exit 1
fi

if [ ! -d "$map_logs_dir" ] ; then
  echo "$map_logs_dir is not a directory"
  exit 1
fi

if [ -z "$data_store" ] ; then
  echo "Variable data_store is not set"
  exit 1
fi

if [ -z "$render_output" ] ; then
  echo "Variable render_output is not set"
  exit 1
fi


# Clear map data directory?.
echo Clearing map directory.
sudo rm -fr ${map_data_dir}/*
sudo rm -f ${data_store}/map_id.txt

echo Clearing logs.
sudo rm -fr ${map_logs_dir}/*

echo Clearing render output.
sudo rm -fr ${render_output}/*

if [ "$_dont_clear_dns" == "--dont_clear_dns" ] ; then
    echo "Skipping unsetting subdomain in DNS."
else
    if [ -e ${data_store}/subdomain.txt ] ; then
	subdomain=$(cat ${data_store}/subdomain.txt)
	if [ -e $dns_setup ] ; then
	    # Unset old DNS
	    echo Unsetting subdomain $subdomain
	    $dns_setup $subdomain 127.0.0.1
	    subdomain=""
	fi
	# Remove stored subdomain.
	rm -f ${data_store}/subdomain.txt
    fi
fi
