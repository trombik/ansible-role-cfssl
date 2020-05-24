# `trombik.cfssl`

`ansible` role for `cfssl`. The API server (`cfssl serve`) is not yet
supported. Implements signing only for now.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `cfssl_user` | user name of `cfssl` | `{{ __cfssl_user }}` |
| `cfssl_group` | group name of `cfssl` | `{{ __cfssl_group }}` |
| `cfssl_package` | package name of `cfssl` | `{{ __cfssl_package }}` |
| `cfssl_extra_packages` | list of extra packages to install | `[]` |
| `cfssl_ca_root_dir` | path to root CA directory | `{{ __cfssl_ca_root_dir }}` |
| `cfssl_ca_csr_file` | path to CSR JSON file of the root CA | `{{ cfssl_ca_root_dir }}/ca.csr.json` |
| `cfssl_ca_csr_config` | content of `cfssl_ca_csr_file` | `{}` |
| `cfssl_ca_config_file` | path to `ca-config.json` | `{{ cfssl_ca_root_dir }}/ca-config.json` |
| `cfssl_ca_config` | content of `cfssl_ca_config_file` | `{}` |
| `cfssl_certs_dir` | path to directory to keep signed certificates | `{{ cfssl_ca_root_dir }}/certs` |
| `cfssl_flags` | not yet used | `""` |
| `cfssl_certs` | list of certificates to sign (see below) | `""` |

## `cfssl_certs`

This is a list of dict. An element represents a CSR.

| Key | Description | Mandatory? |
|-----|-------------|------------|
| `name` | relative file name from `cfssl_certs_dir` | yes |
| `SAN` | list of Subject Alternative Name | no |
| `profile` | profile name to use when signing | yes |
| `json` | content of request JSON file in YAML format | yes |

## Debian

| Variable | Default |
|----------|---------|
| `__cfssl_user` | `cfssl` |
| `__cfssl_group` | `cfssl` |
| `__cfssl_package` | `golang-cfssl` |
| `__cfssl_ca_root_dir` | `/etc/ssl` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__cfssl_user` | `cfssl` |
| `__cfssl_group` | `cfssl` |
| `__cfssl_package` | `security/cfssl` |
| `__cfssl_ca_root_dir` | `/usr/local/etc/ssl` |

# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - role: trombik.freebsd_pkg_repo
      when: ansible_os_family == 'FreeBSD'
    - role: ansible-role-cfssl
  vars:
    # this test case follows the same steps described at
    # https://docs.sensu.io/sensu-go/latest/guides/generate-certificates/
    cfssl_certs:
      - name: agent1.example.com.json
        # Subject Alternative Name, or SAN in short
        SAN: []
        profile: agent
        json:
          CN: agent1.example.com
          hosts:
            - ""
          key:
            algo: rsa
            size: 2048
      - name: backend-1.example.com.json
        SAN:
          - localhost
          - 127.0.0.1
          - 10.0.0.1
          - backend-1
        profile: backend
        json:
          CN: backend-1.example.com
          hosts:
            - ""
          key:
            algo: rsa
            size: 2048
      - name: backend-2.example.com.json
        SAN:
          - localhost
          - 127.0.0.1
          - 10.0.0.2
          - backend-2
        profile: backend
        json:
          CN: backend-2.example.com
          hosts:
            - ""
          key:
            algo: rsa
            size: 2048
      - name: backend-3.example.com.json
        SAN:
          - localhost
          - 127.0.0.1
          - 10.0.0.3
          - backend-3
        profile: backend
        json:
          CN: backend-3.example.com
          hosts:
            - ""
          key:
            algo: rsa
            size: 2048
    cfssl_ca_config:
      signing:
        default:
          expiry: 17520h
          usages:
            - signing
            - key encipherment
            - client auth
      profiles:
        backend:
          expiry: 4320h
          usages:
            - signing
            - key encipherment
            - server auth
        agent:
          expiry: 4320h
          usages:
            - signing
            - key encipherment
            - client auth

    cfssl_ca_csr_config:
      CN: Sensu Test CA
      key:
        algo: rsa
        size: 2048
    # __________________________________________package
    freebsd_pkg_repo:

      # disable the default package repository
      FreeBSD:
        enabled: "false"
        state: present

      # enable my own package repository, where the latest package is
      # available
      FreeBSD_devel:
        enabled: "true"
        state: present
        url: "http://pkg.i.trombik.org/{{ ansible_distribution_version | regex_replace('\\.', '') }}{{ansible_architecture}}-default-default/"
        mirror_type: http
        signature_type: none
        priority: 100
```

# License

```
Copyright (c) 2020 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
