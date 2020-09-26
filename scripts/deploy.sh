#!/bin/bash

set -e

function wait_build() {
    aws cloudformation wait stack-exists --stack-name MythicalMysfits-ECR > /dev/null
    aws cloudformation wait stack-create-complete --stack-name MythicalMysfits-ECR > /dev/null
    ./build_container.sh > /dev/null
}

echo "[1] Initializing deployment"
wait_build &

cd $(dirname $0)/../cdk
cdk deploy --profile $AWS_PROFILE --require-approval never '*'
cd $OLDPWD