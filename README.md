# Fluentd Boshrelease

A bosh release for deploying [fluentd](https://www.fluentd.org/).

This release has been designed specifically for the usecase of shipping logs
from syslog to S3. It should be fairly easy to adapt it for other usecases by
adding more plugins in the future though.

## Building the release

The
[Concourse pipeline](https://ci.engineerbetter.com/teams/main/pipelines/fluentd-boshrelease)
updates the blobs from [the Gemfile](fluentd.Gemfile) and vendors new Ruby
versions. To include a new version of `fluentd` or a dependency, change the
version in [fluentd.Gemfile](fluentd.Gemfile) and run
`bundle install --gemfile fluentd.Gemfile` to recreate the lock file.

Job templates have some spec tests in [spec](spec). New job properties and/or
template files _should_ have new spec tests added.

To build a dev release locally, run:

```bash
bosh create-release --force
# or with tarball
bosh create-release --force --tarball fluentd-boshrelease.tgz
```

Final releases are built from the `master` branch and uploaded automatically by
[the pipeline](https://ci.engineerbetter.com/teams/main/pipelines/fluentd-boshrelease).
Changes that should be built into a final release should (ideally) be merged
into `master` first and released via this method. If you have changes that you
require a final release for that are not suitable for the `master` branch, a
final release can be built locally with:

```bash
bosh create-release --final --tarball fluentd-boshrelease.tgz
```

## Usage

```yaml
releases:
- name: fluentd
  version: 0.0.13
  url:     https://github.com/EngineerBetter/fluentd-boshrelease/releases/download/0.0.13/fluentd-final-release-0.0.13.tgz
  sha1:    affd49680cdc99a5a158d68bda63cd6547939acf
- name: "bpm"
  version: "1.1.13"
  url: "https://bosh.io/d/github.com/cloudfoundry/bpm-release?v=1.1.13"
  sha1: "82322898b2393951108617caac43752e498632a2"

stemcells:
- alias: default
  os: ubuntu-bionic
  version: "1.22"

instance_groups:
- name: fluentd
  stemcell: default
  vm_type: small
  networks:
  - name: default
  azs: [z1]
  instances: 1
  jobs:
  - name: bpm
    release: bpm
  - name: fluentd
    release: fluentd
    properties:
      fluent:
        conf: |
          <source>
            @type syslog
            port 5140
            bind 0.0.0.0
            tag concourse
            <transport tcp>
            </transport>
            <parse>
              message_format rfc5424
            </parse>
          </source>

          <label @FLUENT_LOG>
            <match fluent.*>
              @type stdout
            </match>
          </label>

          <match **>
            @type s3
            s3_bucket $SOME_BUCKET
            s3_region eu-west-1

            path concourse/%Y-%m-%d/
            include_time_key true

            <buffer tag,time>
              @type file
              path /var/vcap/data/fluentd/tmp/s3-buffer

              timekey 30m
              timekey_wait 5m
              chunk_limit_size 64m
              flush_at_shutdown true
              total_limit_size 256m
              overflow_action block
            </buffer>

            <format>
              @type json
            </format>

            <instance_profile_credentials>
              ip_address 169.254.169.254
              port 80
            </instance_profile_credentials>
          </match>

update:
  canaries: 1
  max_in_flight: 10
  canary_watch_time: 1000-30000
  update_watch_time: 1000-30000
  initial_deploy_az_update_strategy: serial
```

### Configure TLS

You can configure tls by adding the certificates to the properties section

```yaml
      properties:
        cert:
          ca: |
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
          crt: |
            -----BEGIN CERTIFICATE-----
            ...
            -----END CERTIFICATE-----
          key: |
            -----BEGIN PRIVATE KEY-----
            ...
            -----END PRIVATE KEY-----
```

and configure the path of the certificates as described below:

```yaml
              <transport tls>
                version TLSv1_2
                ciphers ALL:!aNULL:!eNULL:!SSLv2
                insecure false

                # For Cert signed by public CA
                ca_path /var/vcap/jobs/fluentd/certs/ca.crt
                cert_path /var/vcap/jobs/fluentd/certs/cert.crt
                private_key_path /var/vcap/jobs/fluentd/certs/cert.key
                client_cert_auth false
              </transport>
```

## Tests

You can run the tests with bundle:

```bash
bundle install
bundle exec rspec spec/
```
