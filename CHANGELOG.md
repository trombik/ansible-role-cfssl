## Release 1.4.0

* 070ec77 doc: document intermediate CAs example
* ad9829e bugfix: fix wrong permission on key in tests
* 795796f bugfix: add tests for ca.csr
* a33951e bugfix: add cfssl_ca_csr_config_file
* 7917931 doc: update README
* ac93207 bugfix: fix permission on .csr
* 1e35f10 bugfix: test fails on FreeBSD only
* a5ce2c1 bugfix: drop mode from Ensure private key
* 729dd63 bugfix: QA
* 91b2d24 ci: test if signer is correct in test
* e9c9ba0 bugfix: refactor variables in example
* 4f774a7 bugfix: remove hard-coded path to keys
* a398485 ci: add include_role example
* b063f80 bugfix: replace hard-coded path in example
* 7382d16 bugfix: workaround a bug in ansible
* 436e4b1 bugfix: do not use /etc/ssl
* 16c387f bugfix: replace spaces with `_` in file names
* 51a5be2 bugfix: notify service when rc.conf.d file changed
* 811e68e ci: add test CA's cert to system ca store
* 6f4b03a bugfix: test the hanlder only once
* 42cd8c7 bugfix: add HTTP basic auth to haproxy

## Release 1.3.1

* 98ce6d0 bugfix: update api example to support key rotation

## Release 1.3.0

* 921fd66 feature: officially support API server

## Release 1.2.0

* d99d535 imp: suport APIs, requires updated FreeBSD package
* 5f6d9c7 ci: add GitHub workflows
* 4146f8c bugfix: remove trombik.freebsd_pkg_repo, fix tests
* 4590ebe bugfix: udpate box versions and gems

## Release 1.1.3

* 296f665 bugfix: another missing mode

## Release 1.1.2

* cf12d20 bugfix: always set mode in template

## Release 1.1.1

* 7f4ad9f bugfix: update gems

## Release 1.1.0

* ae14d63 bugfix: fix wrong indent at `profiles`
* 1f07bb2 feature: allow Unix user to private key

## Release 1.0.0

* Initial release
