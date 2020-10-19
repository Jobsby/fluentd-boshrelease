#!/usr/bin/env bash

set -e

export ROOT_PATH=$PWD

cd fluentd-boshrelease

bosh create-release --tarball=../release/fluentd-dev-release.tgz --timestamp-version --force
