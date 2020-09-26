#!/bin/sh

set -e

mm_aws_accountid=$(aws sts get-caller-identity --query Account --output text)
mm_aws_region=$(aws configure get region)
mm_container_name="mythicalmysfits/service"
mm_ecr_url=$mm_aws_accountid.dkr.ecr.$mm_aws_region.amazonaws.com

echo "(1/4) Building Container"
docker build -t $mm_container_name $(dirname $0)/../assets/app

echo "(2/4) Tagging Container"
docker tag $mm_container_name:latest $mm_ecr_url/$mm_container_name:latest

echo "(3/4) Logging in to ecr"
aws ecr get-login-password --region $mm_aws_region | docker login --username AWS --password-stdin $mm_ecr_url

echo "(4/4) Pushing container"
docker push $mm_ecr_url/$mm_container_name:latest

echo "Done"