#!/bin/bash

source $(dirname $0)/_lib.sh

set -e

echo "Populating Data"
aws dynamodb batch-write-item \
  --request-items file://$(dirname $0)/../data/populate-dynamodb.json

echo "Relaxing cognito perms"
aws cognito-idp update-user-pool \
  --user-pool-id $(get_mm_stack_output $(get_mm_stack_arn Cognito) CognitoUserPool) \
  --admin-create-user-config AllowAdminCreateUserOnly=False