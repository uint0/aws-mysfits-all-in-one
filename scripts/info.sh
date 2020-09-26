#!/bin/bash

set -e

source $(dirname $0)/_lib.sh

url=$(get_mm_stack_output $(get_mm_stack_arn Website) CloudFrontURL)

echo "Site is avaliable at $url"