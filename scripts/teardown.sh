#!/bin/bash

cd $(dirname $0)/../cdk
yes | cdk destroy --profile $AWS_PROFILE --require-approval never '*'
cd $OLDPWD

$(dirname $0)/teardown_extra.sh
