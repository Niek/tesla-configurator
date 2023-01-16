#!/usr/bin/env bash

echo "Starting updater..."

# Function to check if command is installed
command_exists() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: $1 is not installed - can not run update script"
        exit 1
    fi
}

# Check if essential commands are installed
command_exists curl
command_exists jq
command_exists parallel

# Get rid of the annoying parallel citation warning
echo 'will cite' | parallel --citation 1>/dev/null 2>/dev/null

# Define the car models
models=(models model3 modelx modely cybertruck)

# Define the countries
countries=(en_us en_ca es_mx en_pr nl_be cs_cz da_dk de_de el_gr es_es fr_fr hr_hr hu_hu en_ie is_is it_it fr_lu nl_nl no_no de_at pl_pl pt_pt ro_ro sl_si fr_ch sv_se fi_fi en_gb he_il en_ae en_jo zh_cn zh_hk en_mo zh_tw ja_jp en_sg ko_kr en_au en_nz)

# Create a tmp file containing the list of all the URLs to download
tmpfile=$(mktemp)

# Loop over models/countries and fetch the data
for cnt in "${countries[@]}"; do
    for m in "${models[@]}"; do
        mkdir -p "${cnt}"
        echo "curl -sf 'https://www.tesla.com/${cnt}/${m}/design' | grep '\"DSServices\"' | sed 's/^/{/; s/.$//; s/$/}/' | jq '{info: .DSServices | del(.date) | del(.responseTime)}' >| ${cnt}/${m}.json" >>"${tmpfile}"
    done
done

# Run the commands in parallel
parallel --retries 3 --jobs 2 --delay 2 <"${tmpfile}"

# Delete empty files
find . -name '*.json' -empty -type f -delete

# Delete the tmp file
rm "${tmpfile}"
