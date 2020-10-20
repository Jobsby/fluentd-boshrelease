# Fluentd Boshrelease

A bosh release for deploying [fluentd](https://www.fluentd.org/).

This release has been designed specifically for the usecase of shipping logs from syslog to S3. It should be fairly easy to adapt it for other usecases by adding more plugins in the future though.

## Usage

```yaml
releases:
...
- name:    fluentd
  version: 0.0.4
  url:     https://github.com/EngineerBetter/fluentd-boshrelease/releases/download/0.0.4/fluentd-final-release-0.0.4.tgz
  sha1:    cfb082426b2e76a224ee1354fc42f1f66a05a49b

jobs:
- name: web
  jobs:
  - name: web
    release: concourse
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
```
