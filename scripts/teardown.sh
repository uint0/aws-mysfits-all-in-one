#!/bin/bash

cd $(dirname $0)/../cdk
yes | cdk destroy --profile $AWS_PROFILE --require-approval never '*'
cd $OLDPWD

./teardown_extra.sh
