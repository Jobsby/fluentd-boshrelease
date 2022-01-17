#!/bin/bash
set -euo pipefail
fluentd_path=$(cat fluentd.version)
tarball="${fluentd_path##*/}.tgz"
tar czvpf "$tarball" vendor fluentd.Gemfile fluentd.Gemfile.lock
bosh add-blob $tarball fluentd.tgz
cat >> config/private.yml <<EOF
---
blobstore:
  provider: s3
  options:
    credentials_source: env_or_profile
EOF
bosh upload-blobs

git config --global user.email "ci@localhost"
git config --global user.name "CI Bot"
status="$(git status --porcelain)"
if [ -n "$status" ]; then
    git add config/blobs.yml
    git commit -m "Updating fluentd.tgz blob with versions from fluentd.Gemfile"
fi
