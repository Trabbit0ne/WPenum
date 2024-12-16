#!/bin/bash

# WordPress User Enumerator
# Usage: ./wp_user_enum.sh <URL>

# VARIABLES


# Colors
RED="\e[31m"        # Classic RED
GREEN="\e[32m"      # Classic GREEN
YELLOW="\e[33m"     # Classic YELLOW
BLUE="\e[34m"       # Classic BLUE
PURPLE="\e[35m"     # Classic PURPLE
BG_RED="\e[41m"     # Background RED
BG_GREEN="\e[42m"   # Background GREEN
BG_YELLOW="\e[43m"  # Background YELLOW
BG_BLUE="\e[44m"    # Background BLUE
BG_PURPLE="\e[45m"  # Background PURPLE
NE="\e[0m"          # No color

# clear the screen
clear

echo "  __    __  ___                           ";
echo " / / /\ \ \/ _ \___ _ __  _   _ _ __ ___  ";
echo " \ \/  \/ / /_)/ _ \ '_ \| | | | '_ ' _ \ ";
echo "  \  /\  / ___/  __/ | | | |_| | | | | | |";
echo "   \/  \/\/    \___|_| |_|\__,_|_| |_| |_|";
echo

# Check if a URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <WordPress URL>"
    exit 1
fi

# Set the target URL
TARGET="$1/wp-json/wp/v2/users"

echo "Enumerating users for: $TARGET..."

# Send the HTTP GET request
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$TARGET")

# Extract HTTP status code
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d ":" -f 2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:.*/d')

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}Failed to retrieve user data. HTTP Status: $HTTP_CODE${NE}"
    exit 1
fi

# Parse the JSON response to extract usernames and IDs
echo "User list:"
echo "$BODY" | jq -r '.[] | "ID: \(.id), Username: \(.name)"'

exit 0
