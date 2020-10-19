#!/usr/bin/env bash

set -euo pipefail

export ROOT_PATH=$PWD
VENDORED_REPO=$PWD/vendored-fluentd-boshrelease

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

git clone ./fluentd-boshrelease $VENDORED_REPO

pushd $VENDORED_REPO
  git status

  git checkout master
  git status

  bosh vendor-package ruby-2.7.2-r0.38.0 ../ruby-release

  status="$(git status --porcelain)"
  if [ -n "$status" ]; then
    git add -A
    git commit -m "Vendoring ruby"
  fi
popd
