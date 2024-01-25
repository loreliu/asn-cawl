#!/usr/bin/env bash
# This script is used to continuously fetch and process ASN (Autonomous System Number) information from a CSV file.
# It downloads a file, retrieves ASN information using an API, and runs a FOFA (Find Open Files and Addresses) hack for each ASN.
# The script runs in an infinite loop, periodically fetching and processing ASN information.

# Function to download a file and check for errors
download_file() {
    local url="$1"
    local output_file="$2"

    if wget -q "$url" -O "$output_file"; then
        chmod +x "$output_file"
    else
        echo "Failed to download $url" >&2
        exit 1
    fi
}

asn_info() {
    # Declare variables as global using the 'declare' command with the '-g' option
    declare -g asn_value
    declare -g name_value
    declare -g country_value
    declare -g allocated_value
    declare -g domain_value
    declare -g num_ips_value
    declare -g type_value

    local asn="$1"
    local max_retries=3
    local retries=0

    while [ "$retries" -lt "$max_retries" ]; do
        local json_data=$(curl -s https://ip.3k.free.hr/api/AS$asn)

        # Check if there was an error in the API response
        if [ $? -eq 0 ]; then
            # Extract JSON data into variables
            asn_value=$(echo "$json_data" | jq -r '.asn')
            name_value=$(echo "$json_data" | jq -r '.name')
            country_value=$(echo "$json_data" | jq -r '.country')
            allocated_value=$(echo "$json_data" | jq -r '.allocated')
            domain_value=$(echo "$json_data" | jq -r '.domain')
            num_ips_value=$(echo "$json_data" | jq -r '.num_ips')
            type_value=$(echo "$json_data" | jq -r '.type')

            # Break out of the loop if the API request was successful
            break
        else
            # Increment the retry counter and wait before the next attempt
            retries=$((retries + 1))
            sleep 1
        fi
    done
}

run_fofa_hack() {
    local asn="$1"
    local handle="$2"
    ./fofa-asn -e 500 -f -l 2 -o json --proxy '127.0.0.1:7890' -w 10 -a $asn
}

if [ -f current_asn.txt ]; then
    current_asn=$(cat current_asn.txt)
else
    current_asn=$(tail -n +2 asn-full.csv | head -n 1 | cut -d',' -f1)
fi

while true; do
    while IFS=, read -r asn name; do
        if [ "$asn" = "$current_asn" ]; then
            found_current_asn=true
        fi

        if [ "$found_current_asn" = true ]; then
            description="${description//\"/}"
            echo "================================================================"
            echo "ASN: $asn"
            echo "Name: $name"
            echo "================================================================"
            # asn_info "$asn"
            run_fofa_hack "$asn" "$name"
            sleep 10
        fi

        echo "$asn" >current_asn.txt
    done <asn-full.csv

    sleep 1800
done
