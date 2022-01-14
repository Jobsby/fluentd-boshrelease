#!/bin/bash
set -euo pipefail
export BUNDLE_GEMFILE=fluentd.Gemfile
bundle package
fluentd_path=$(bundle info fluentd --path)
tarball="${fluentd_path##*/}.tgz"
tar czvpf "$tarball" vendor fluentd.Gemfile fluentd.Gemfile.lock
bosh add-blob $tarball fluentd.tgz

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"
status="$(git status --porcelain)"
if [ -n "$status" ]; then
    git add -A
    git commit -m "Updating fluentd.tgz blob with versions from $BUNDLE_GEMFILE"
fi
