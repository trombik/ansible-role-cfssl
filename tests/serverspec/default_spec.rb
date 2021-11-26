require "spec_helper"
require "serverspec"

package = case os[:family]
          when "ubuntu"
            "golang-cfssl"
          else
            "cfssl"
          end
ca_root_dir = case os[:family]
              when "freebsd"
                "/usr/local/etc/cfssl"
              else
                "/etc/cfssl"
              end
user    = case os[:family]
          when "openbsd"
            "_cfssl"
          else
            "cfssl"
          end
group   = case os[:family]
          when "openbsd"
            "_cfssl"
          else
            "cfssl"
          end
default_group = case os[:family]
                when /bsd/
                  "wheel"
                else
                  "root"
                end
extra_packages = []
public_mode = case os[:family]
              when /bsd/
                644
              else
                664
              end
service = "cfssl"

ca_config = "#{ca_root_dir}/ca-config.json"
csr_config = "#{ca_root_dir}/ca-csr.json"
ca_key_private = "#{ca_root_dir}/ca-key.pem"
ca_key_public = "#{ca_root_dir}/ca.pem"
ca_csr = "#{ca_root_dir}/ca.csr"
certs_dir = "#{ca_root_dir}/certs"

backends = %w[backend-1 backend-2 backend-3]
agents = %w[agent1]
domain = "example.com"

# rubocop:disable Style/GlobalVars
if $API
  # rubocop:enable Style/GlobalVars
  proxy_service = "haproxy"
  default_user = "root"
  certdb_dir = case os[:family]
               when "freebsd"
                 "/var/db/cfssl"
               else
                 "/var/lib/cfssl"
               end
  certdb_file = "#{certdb_dir}/certdb.db"
  db_config_file = "#{ca_root_dir}/db.json"
  migration_dir = "#{ca_root_dir}/goose/sqlite"
  log_file = "/var/log/messages"
end

describe user(user) do
  it { should exist }
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe package(package) do
  it { should be_installed }
end

case os[:family]
when "freebsd"
  describe file "/etc/rc.conf.d/cfssl" do
    # rubocop:disable Style/GlobalVars
    if $API
      # rubocop:enable Style/GlobalVars
      it { should exist }
    else
      it { should_not exist }
    end
  end
end

describe file ca_root_dir do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(csr_config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by user }
  it { should be_grouped_into default_group }
  its(:content_as_json) { should include("CN" => "Sensu Test CA") }
end

describe file(ca_csr) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/BEGIN CERTIFICATE REQUEST/) }
end

describe file(ca_config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by "root" }
  it { should be_grouped_into default_group }
  its(:content_as_json) { should include("signing" => include("default" => include("expiry" => "17520h"))) }
end

describe file ca_key_public do
  it { should exist }
  it { should be_file }
  it { should be_mode public_mode }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/-----BEGIN CERTIFICATE-----/) }
end

describe file ca_key_private do
  it { should exist }
  it { should be_file }
  it { should be_mode 640 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/-----BEGIN (?:RSA )?PRIVATE KEY-----/) }
end

backends.each do |backend|
  %w[-key.pem .csr .json .pem].each do |ext|
    describe file "#{certs_dir}/#{backend}.#{domain}#{ext}" do
      it { should exist }
      it { should be_file }
      case ext
      when "-key.pem"
        it { should be_mode 600 }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      when ".json"
        it { should be_mode 644 }
        it { should be_owned_by "root" }
        it { should be_grouped_into default_group }
      when ".csr"
        it { should be_mode 644 }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      when ".pem"
        it { should be_mode public_mode }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      end
    end
  end
end

agents.each do |agent|
  %w[-key.pem .csr .json .pem].each do |ext|
    describe file "#{certs_dir}/#{agent}.#{domain}#{ext}" do
      it { should exist }
      it { should be_file }
      case ext
      when "-key.pem"
        it { should be_mode 600 }
        it { should be_owned_by "nobody" }
        it { should be_grouped_into group }
      when ".json"
        it { should be_mode 644 }
        it { should be_owned_by "root" }
        it { should be_grouped_into default_group }
      when ".csr"
        it { should be_mode 644 }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      when ".pem"
        it { should be_mode public_mode }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      end
    end
  end
end

backends.each do |backend|
  describe command "openssl x509 -in #{certs_dir}/#{backend}.#{domain}.pem -text" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    # output format of libressl is slightly different from openssl
    its(:stdout) { should match(/Issuer: CN\s*=\s*Sensu Test CA/) }
    its(:stdout) { should match(/RSA Public-Key: \(2048 bit\)/) }
    its(:stdout) { should match(/Signature Algorithm: sha256WithRSAEncryption/) }
    its(:stdout) { should match(/Subject: CN\s*=\s*#{Regexp.escape(backend)}\.#{Regexp.escape(domain)}/) }
    its(:stdout) { should match(/TLS Web Server Authentication/) }
    its(:stdout) { should_not match(/TLS Web Client Authentication/) }
    its(:stdout) { should match(/DNS:localhost, DNS:#{Regexp.escape(backend)}, IP Address:127\.0\.0\.1, IP Address:10\.0\.0\.[123]/) }
  end
end

# rubocop:disable Style/GlobalVars
if $API
  # rubocop:enable Style/GlobalVars
  describe service service do
    it { should be_running }
    it { should be_enabled }
  end
else
  describe service service do
    it do
      pending "does not work due to old serverspec" if os[:family] == "freebsd"
      should_not be_running
    end
    it { should_not be_enabled }
  end
end

# rubocop:disable Style/GlobalVars
if $API
  # rubocop:enable Style/GlobalVars
  describe file ca_root_dir do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end

  describe file migration_dir do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
  end

  describe file "#{migration_dir}/dbconf.yml" do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match(/Managed by ansible/) }
  end

  describe file certdb_dir do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end

  describe file certdb_file do
    it { should exist }
    it { should be_file }
    it { should be_mode 640 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end

  describe file db_config_file do
    it { should exist }
    it { should be_file }
    it { should be_mode 640 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end

  describe service service do
    it { should be_enabled }
    it { should be_running }
  end

  %w[
    /
    /api/v1/cfssl/authsign
    /api/v1/cfssl/bundle
    /api/v1/cfssl/certadd
    /api/v1/cfssl/certinfo
    /api/v1/cfssl/crl
    /api/v1/cfssl/gencrl
    /api/v1/cfssl/health
    /api/v1/cfssl/info
    /api/v1/cfssl/init_ca
    /api/v1/cfssl/newcert
    /api/v1/cfssl/newkey
    /api/v1/cfssl/revoke
    /api/v1/cfssl/scan
    /api/v1/cfssl/scaninfo
  ].each do |endpoint|
    describe file log_file do
      its(:content) { should match(/endpoint '#{endpoint}' is enabled/) }
    end
  end

  describe file log_file do
    its(:content) { should match(/foo is restarted/) }
  end

  describe service proxy_service do
    it { should be_enabled }
    it { should be_running }
  end

  describe port 443 do
    it { should be_listening }
  end

  # XXX wget, instead of curl, is used here because curl, by default, does not
  # load system's root CA certificate store.
  describe package "wget" do
    it { should be_installed }
  end
  describe command "wget --user foo --password password --server-response --output-document - https://localhost" do
    its(:stderr) { should match(/#{Regexp.escape("HTTP/1.1")} 200/) }
    its(:stdout) { should match(/#{Regexp.escape("<title>CFSSL</title>")}/) }
    its(:exit_status) { should eq 0 }
  end

  describe command "wget --server-response --output-document - https://localhost/" do
    its(:stderr) { should match(/#{Regexp.escape("HTTP/1.1")} 401/) }
    # 6   Username/password authentication failure.
    its(:exit_status) { should eq 6 }
  end
end
