#!/bin/bash
set -euo pipefail

if [ -z "$GEMFURY_PUSH_TOKEN" ]; then
    echo 'Environment variable GEMFURY_PUSH_TOKEN must be specified. Aborting.'
    exit 1
fi

for file in `ls *.gemspec`; do
    gem build $file
done

# Publish to Gemfury (based on: https://gemfury.com/help/upload-packages/#cURL)
for file in `ls *.gem`; do
    echo "Publishing new package version: ${file}"
    curl --fail -F package=@${file} https://${GEMFURY_PUSH_TOKEN}@push.fury.io/doctorondemand/
done

