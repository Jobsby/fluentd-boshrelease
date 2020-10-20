#!/usr/bin/env bash

set -euo pipefail

VERSION=$(cat version/number)
cp version/number bumped-version/number

export ROOT_PATH=$PWD
PROMOTED_REPO=$PWD/final-fluentd-boshrelease

export FINAL_RELEASE_PATH="${ROOT_PATH}/final-release/*.tgz"

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

git clone ./fluentd-boshrelease "${PROMOTED_REPO}"

pushd "${PROMOTED_REPO}"
  git status

  git checkout master
  git status

  cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF

  bosh finalize-release --version "${VERSION}" "${FINAL_RELEASE_PATH}"

  git add -A
  git status

  git commit -m "Adding final release $VERSION via concourse"
popd
