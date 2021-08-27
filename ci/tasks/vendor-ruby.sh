#!/usr/bin/env bash

set -euo pipefail

export ROOT_PATH=$PWD
VENDORED_REPO=$PWD/vendored-fluentd-boshrelease

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"

git clone ./fluentd-boshrelease "${VENDORED_REPO}"

pushd ruby-release
  latest_ruby_version="$(bosh blobs | grep ruby-3 | cut -d . -f 1-3 | sort | tail -1)"
  # I wanted to do `grep name packages/ruby-${latest_ruby_version}-r*/spec`
  # but globbing didn't seem to work in the container
  latest_ruby_version_full="$(find packages -type d | awk -F/ -v ruby_version="${latest_ruby_version}" '($0 ~ ruby_version){print $2}')"
popd

pushd "${VENDORED_REPO}"
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

  bosh vendor-package "${latest_ruby_version_full}" ../ruby-release

  status="$(git status --porcelain)"
  if [ -n "$status" ]; then
    date >> vendored-ruby-log
    git add -A
    git commit -m "Vendoring ruby"
  fi
popd
