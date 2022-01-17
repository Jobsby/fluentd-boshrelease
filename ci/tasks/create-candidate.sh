#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

cd fluentd-boshrelease
rm config/private.yml # Breaks dev releases

bosh create-release --tarball="${ROOT_PATH}/release/fluentd-dev-release.tgz" --timestamp-version --force
