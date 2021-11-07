# `trombik.cfssl`

`ansible` role for `cfssl`. The API server (`cfssl serve`) is supported.

## For all users

As few distributions support the API server in their packages, `cfssl_db_*`
role variables are subject to change.

To run `cfssl` as a server, your distribution package must provide startup
script, and other modifications to the package. AFAIK, the one from Ubuntu
does not. Thus, API server support is not implemented for Debian-variants.

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
| `cfssl_ca_secret_key_file` | path to root secret key file | `{{ cfssl_ca_root_dir }}/ca-key.pem` |
| `cfssl_ca_public_key_file` | path to root public key file | `{{ cfssl_ca_root_dir }}/ca.pem` |
| `cfssl_ca_csr_file` | path to CSR JSON file of the root CA | `{{ cfssl_ca_root_dir }}/ca.csr` |
| `cfssl_ca_csr_config` | content of `cfssl_ca_csr_config_file` | `{}` |
| `cfssl_ca_config_file` | path to CA's configuration file in JSON | `{{ cfssl_ca_root_dir }}/ca-config.json` |
| `cfssl_ca_csr_config_file` | path to CA's CSR config file in JSON | `"{{ cfssl_ca_root_dir }}/ca-csr.json"` |
| `cfssl_ca_config` | content of `cfssl_ca_config_file` | `{}` |
| `cfssl_certs_dir` | path to directory to keep signed certificates | `{{ cfssl_ca_root_dir }}/certs` |
| `cfssl_service` | Service name of `cfssl` | `cfssl` |
| `cfssl_db_config` | Database configuration in YAML. See [certdb/README.nd](https://github.com/cloudflare/cfssl/tree/master/certdb/README.md) in the upstream source code for more details. | `{}` |
| `cfssl_db_type` | The type of the database. Supported value is `sqlite` only. If specified, the role runs specific tasks for the database, and starts `cfssl` as server. | `""` |
| `cfssl_db_dir` | Path to the database directory | `{{ __cfssl_db_dir }}` |
| `cfssl_db_sqlite_bin` | File name of `sqlite` command | `sqlite3` |
| `cfssl_db_sqlite_database_file` | Path to `sqlite` database file | `{{ cfssl_db_dir }}/certdb.db` |
| `cfssl_db_sqlite_sql_file_dir` | Path to a directory where SQL files are stored. | `{{ __cfssl_db_sqlite_sql_file_dir }}` |
| `cfssl_db_migration_dir` | Path to database migration directory | `{{ cfssl_ca_root_dir }}/goose/{{ cfssl_db_type }}` |
| `cfssl_db_migration_config` | Configuration for database migration | `{}` |
| `cfssl_db_migration_environment` | Environment for database migration | `development` |
| `cfssl_flags` | Additional options for startup script | `""` |
| `cfssl_certs` | list of certificates to sign (see below) | `""` |

## `cfssl_certs`

This is a list of dict. An element represents a CSR.

| Key | Description | Mandatory? |
|-----|-------------|------------|
| `name` | relative file name from `cfssl_certs_dir` | yes |
| `SAN` | list of Subject Alternative Name | no |
| `profile` | profile name to use when signing | yes |
| `json` | content of request JSON file in YAML format | yes |
| `owner` | Unix user name of owner of the private key file (default is `cfssl_user`) | no |

## Including `trombik.cfssl`

You may include the role from your tasks or roles. Use `vars` to define
specific role variables by `vars`.

```yaml
- name: Include role trombik.cfssl
  include_role:
    name: trombik.cfssl
  vars:
    cfssl_extra_packages:
      - zsh
```

However, when you want to pass a single variable that includes the role
variables, you need to pass your variable to a special bridge role variable,
`cfssl_vars`.

```yaml
- name: Include role trombik.cfssl
  include_role:
    name: trombik.cfssl
  vars:
    cfssl_vars: "{{ my_variable }}"
```

The following example does NOT work:

```yaml
- name: Include role trombik.cfssl
  include_role:
    name: trombik.cfssl
  vars: "{{ my_variable }}"
```

see [tests/serverspec/intermediate.yml](tests/serverspec/intermediate.yml),
which includes the role multiple times to create intermediate CAs.

## Debian

| Variable | Default |
|----------|---------|
| `__cfssl_user` | `cfssl` |
| `__cfssl_group` | `cfssl` |
| `__cfssl_package` | `golang-cfssl` |
| `__cfssl_ca_root_dir` | `/etc/cfssl` |
| `__cfssl_db_dir` | `/var/lib/cfssl` |
| `__cfssl_db_sqlite_sql_file_dir` | `""` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__cfssl_user` | `cfssl` |
| `__cfssl_group` | `cfssl` |
| `__cfssl_package` | `security/cfssl` |
| `__cfssl_ca_root_dir` | `/usr/local/etc/cfssl` |
| `__cfssl_db_dir` | `/var/db/cfssl` |
| `__cfssl_db_sqlite_sql_file_dir` | `/usr/local/share/cfssl/certdb/sqlite/migrations` |

# Dependencies

None

# Example Playbook

This example manages `cfssl`, and signs a few certificates.

For an example for API server, see [tests/serverspec/api.yml](tests/serverspec/api.yml).

For an example for multiple intermediate CAs under a root CA,
see [tests/serverspec/intermediate.yml](tests/serverspec/intermediate.yml).

```yaml
---
- hosts: localhost
  roles:
    - role: ansible-role-cfssl
  vars:
    # this test case follows the same steps described at
    # https://docs.sensu.io/sensu-go/latest/guides/generate-certificates/
    cfssl_certs:
      - name: agent1.example.com.json
        # Subject Alternative Name, or SAN in short
        SAN: []
        profile: agent
        owner: nobody
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
