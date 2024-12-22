#!/bin/bash

# Check if the domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Fetch URLs from the Wayback Machine using waybackurls
wp_json_urls=$(waybackurls $DOMAIN | grep 'wp-json')

# VARIABLES

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
ORANGE="\e[38;5;208m"
NE="\e[0m"

# Clear the screen
clear

echo "  __    __  ___                           "
echo " / / /\ \ \/ _ \___ _ __  _   _ _ __ ___  "
echo " \ \/  \/ / /_)/ _ \ '_ \| | | | '_ ' _ \ "
echo "  \  /\  / ___/  __/ | | | |_| | | | | | |"
echo "   \/  \/\/    \___|_| |_|\__,_|_| |_| |_|"
echo -e "${ORANGE}                           Enhanced Edition${NE}"
echo

# Check if a URL is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <WordPress URL>${NE}"
    exit 1
fi

# Check and prepend https:// if necessary
INPUT_URL="$1"
if [[ "$INPUT_URL" != http* ]]; then
    INPUT_URL="https://$INPUT_URL"
fi

# Helper function for JSON parsing (updated to explicitly handle null and empty values)
parse_json() {
    echo "$1" | jq -r '.[] | select(.name != null and .name != "") | "ID: \(.id), Username: \(.name)"'
}

# Method 1: WP REST API
rest_api_enum() {
    for url in $wp_json_urls; do
        echo -e "${BLUE}[i] Trying WP REST API at: $url${NE}"
        RESPONSE=$(curl -sL -w "\nHTTP_CODE:%{http_code}" "$url")
        HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d ":" -f 2)
        BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:.*/d')

        if [ "$HTTP_CODE" -eq 200 ]; then
            echo -e "${GREEN}User list from REST API:${NE}"
            parse_json "$BODY"
        else
            echo -e "${RED}REST API enumeration failed (HTTP $HTTP_CODE).${NE}"
        fi
    done
}

# Method 2: Author Archives (only relevant for URLs that have author archives)
author_enum() {
    echo -e "${BLUE}[i] Trying author archives...${NE}"
    for id in {1..10}; do
        AUTHOR_URL="$INPUT_URL/author/$id"
        AUTHOR=$(curl -sL -o /dev/null -w "%{redirect_url}" "$AUTHOR_URL")
        if [[ "$AUTHOR" != "" && "$AUTHOR" != "$AUTHOR_URL" ]]; then
            USERNAME=$(echo "$AUTHOR" | awk -F"/author/" '{print $2}' | sed 's#/.*##')
            echo -e "${GREEN}Found author: $USERNAME (ID: $id)${NE}"
        fi
    done
}

# Method 3: XML-RPC (for XML-RPC detection)
xmlrpc_enum() {
    echo -e "${BLUE}[i] Trying XML-RPC...${NE}"
    XMLRPC_URL="$INPUT_URL/xmlrpc.php"
    RESPONSE=$(curl -sL -X POST -d "<?xml version='1.0'?><methodCall><methodName>system.listMethods</methodName></methodCall>" "$XMLRPC_URL")
    if [[ "$RESPONSE" == *"faultCode"* ]]; then
        echo -e "${RED}XML-RPC is disabled or not found at $XMLRPC_URL.${NE}"
    else
        echo -e "${GREEN}XML-RPC is enabled. Probing usernames...${NE}"
        for id in {1..10}; do
            XML_PAYLOAD="<?xml version='1.0'?><methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value><string>user$id</string></value></param><param><value><string>password</string></value></param></params></methodCall>"
            RESPONSE=$(curl -sL -X POST -d "$XML_PAYLOAD" "$XMLRPC_URL")
            if [[ "$RESPONSE" != *"faultCode"* ]]; then
                echo -e "${GREEN}Found user via XML-RPC: user$id${NE}"
            fi
        done
    fi
}

# Method 4: RSS Feeds
rss_enum() {
    echo -e "${BLUE}[i] Trying RSS feed...${NE}"
    FEED_URL="$INPUT_URL/feed"
    FEED=$(curl -sL "$FEED_URL")
    if [[ "$FEED" != "" ]]; then
        echo -e "${GREEN}User list from RSS feed:${NE}"
        echo "$FEED" | grep -oP '(?<=<dc:creator>).*?(?=</dc:creator>)' | sort -u
    else
        echo -e "${RED}Failed to fetch RSS feed.${NE}"
    fi
}

# Main execution
echo -e "${BLUE}[i] Starting enumeration...${NE}"

# Run REST API method with URLs found by waybackurls
rest_api_enum

# Run Author Archives method
author_enum

# Run XML-RPC method
xmlrpc_enum

# Run RSS Feeds method
rss_enum

exit 0
