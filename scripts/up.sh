#!/bin/bash

set -e

./deploy.sh
./postinstall.sh
./load_test_env.sh

./info.sh