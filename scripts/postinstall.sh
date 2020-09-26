#!/bin/bash

set -e

source $(dirname $0)/_lib.sh

echo "Getting stack information"
stack_cognito=$(get_mm_stack_arn Cognito)
stack_web=$(get_mm_stack_arn Website)
stack_api=$(get_mm_stack_arn APIGateway)

echo "Fetching stack outputs"
webbucket=$(get_mm_stack_resource $stack_web AWS::S3::Bucket Bucket)
apigateway=$(get_mm_stack_output $stack_api APIID)
cognitouserpool=$(get_mm_stack_output $stack_cognito CognitoUserPool)
cognitoclient=$(get_mm_stack_output $stack_cognito CognitoUserPoolClient)
cloudfront=$(get_mm_stack_resource $stack_web AWS::CloudFront::Distribution CloudFrontCFDistribution)
awsregion=$(aws configure get region)

apiendpoint="https://$apigateway.execute-api.$awsregion.amazonaws.com/prod"

echo "Building config.js"
cp $(dirname $0)/../templates/web/config.template.js config.js

sed -i "s/REPLACE_ME_API_ENDPOINT/${apiendpoint//\//\\/}/g"  config.js
sed -i "s/REPLACE_ME_COGNITO_USER_POOL/$cognitouserpool/g" config.js
sed -i "s/REPLACE_ME_COGNITO_CLIENT_ID/$cognitoclient/g"   config.js
sed -i "s/REPLACE_ME_AWS_REGION/$awsregion/g"      config.js

aws s3 cp config.js s3://$webbucket/web/js/config.js
aws cloudfront create-invalidation --distribution-id $cloudfront --paths /js/config.js
rm config.js