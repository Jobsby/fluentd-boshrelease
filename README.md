# Fluentd Boshrelease

A bosh release for deploying [fluentd](https://www.fluentd.org/).

This release has been designed specifically for the usecase of shipping logs from syslog to S3. It should be fairly easy to adapt it for other usecases by adding more plugins in the future though.

## Usage

```yaml
releases:
- name: fluentd
  version: 0.0.8
  url: https://github.com/EngineerBetter/fluentd-boshrelease/releases/download/0.0.8/fluentd-final-release-0.0.8.tgz
  sha1: 5fa32aa732ada61d14ce7f054fe08bd1bc8ac57e
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
