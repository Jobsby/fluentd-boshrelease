#!/bin/bash

pushd $(dirname $0)/../src/fluentd

rm -rf vendor
bundle package

popd
