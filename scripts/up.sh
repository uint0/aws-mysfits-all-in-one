#!/bin/bash

set -e

$(dirname $0)/deploy.sh
$(dirname $0)/postinstall.sh
$(dirname $0)/load_test_env.sh

$(dirname $0)/info.sh