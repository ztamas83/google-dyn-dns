#!/bin/bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <path-to-service-account-json> <hostname> <gcf-url>"
    exit 1
fi

SA_KEY_FILE=$1
HOST=$2
GCF_URL=$3

# The audience for the token should be the URL of the function being called.
token=$(./get-token.sh "$SA_KEY_FILE" "$GCF_URL")

echo "Token acquired."
echo "Sending update request for host: ${HOST}"

#curl -X POST "${GCF_URL}" \
#  -H "Authorization: Bearer ${token}" \
#  -H "Content-Type: application/json" \
#  -d "{\"host\": \"${HOST}\"}"

echo -e "\nUpdate request sent."