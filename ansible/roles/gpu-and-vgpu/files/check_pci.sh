#!/bin/bash

# WHITELIST=("vendor_id:product_id" "vendor_id:")
WHITELIST=("10de:") # Filter all nvidia (/!\ unsafe for other vendors)

command -v lspci &> /dev/null || exit 2
command -v awk &> /dev/null || exit 2

PCI=$(lspci -n | awk '{print $3}')

for var in "${WHITELIST[@]}"
do
        echo "$PCI" | grep "$var" &> /dev/null
        returncode=$?
        # Found a compliant gpu
        if [ "$returncode" == "0" ]; then
                exit 0
        fi
        # Grep failed
        if [ "$returncode" == "2" ]; then
                exit 2
        fi
done
# No compliant gpu found
exit 1
