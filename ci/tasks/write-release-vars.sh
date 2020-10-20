#!/usr/bin/env bash

set -euo pipefail

version=$(cat version/version)
name="fluentd-boshrelease v${version}"

echo "${name}" > release-vars/name

pushd fluentd-boshrelease
  commit=$(git rev-parse HEAD)
popd

echo "$commit" > release-vars/commit

cat << EOF > release-vars/body
Auto-generated release
EOF
