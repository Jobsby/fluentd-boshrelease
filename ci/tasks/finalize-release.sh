#!/usr/bin/env bash

set -euo pipefail

VERSION=$(cat version/number)
cp version/number bumped-version/number

export ROOT_PATH=$PWD
PROMOTED_REPO=$PWD/final-fluentd-boshrelease

export FINAL_RELEASE_PATH=$ROOT_PATH/final-release/*.tgz

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

pushd ./fluentd-boshrelease
  tag_name="v${VERSION}"

  tag_annotation="Final release ${VERSION} tagged via concourse"

  git tag -a "${tag_name}" -m "${tag_annotation}"
popd

git clone ./fluentd-boshrelease $PROMOTED_REPO

pushd $PROMOTED_REPO
  git status

  git checkout master
  git status

  bosh finalize-release --version $VERSION $FINAL_RELEASE_PATH

  git add -A
  git status

  git commit -m "Adding final release $VERSION via concourse"
popd
