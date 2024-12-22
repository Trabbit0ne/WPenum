#!/usr/bin/env bash

# Check if the domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Fetch URLs from the Wayback Machine using waybackurls
waybackurls $DOMAIN | grep 'wp-json' | sed 's|\(.*\)/wp-json.*|&/wp-json/wp/v2/users|'
