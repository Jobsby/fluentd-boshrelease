#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

VERSION=$(cat version/number)

cd fluentd-boshrelease

bosh create-release \
  --final \
  "--tarball=../final-release/fluentd-final-release-${VERSION}.tgz"
