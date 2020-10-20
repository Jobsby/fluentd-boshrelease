#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

VERSION=$(cat version/number)

cd fluentd-boshrelease

cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

bosh create-release \
  --final \
  "--tarball=../final-release/fluentd-final-release-${VERSION}.tgz"
