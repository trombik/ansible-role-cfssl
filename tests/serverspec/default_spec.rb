require "spec_helper"
require "serverspec"

package = "cfssl"
ca_root_dir = "/etc/ssl"
user    = "cfssl"
group   = "cfssl"
default_group = "root"
extra_packages = []

case os[:family]
when "ubuntu"
  package = "golang-cfssl"
when "freebsd"
  default_group = "wheel"
  ca_root_dir = "/usr/local/etc/ssl"
end

ca_config = "#{ca_root_dir}/ca-config.json"
csr_config = "#{ca_root_dir}/ca-csr.json"
ca_key_private = "#{ca_root_dir}/ca-key.pem"
ca_key_public = "#{ca_root_dir}/ca.pem"
certs_dir = "#{ca_root_dir}/certs"

backends = %w[backend-1 backend-2 backend-3]
agents = %w[agent1]
domain = "example.com"

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
  it { should be_owned_by "root" }
  it { should be_grouped_into default_group }
  its(:content_as_json) { should include("CN" => "Sensu Test CA") }
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
  it { should be_mode 644 }
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
        it { should be_mode 660 }
        it { should be_owned_by user }
        it { should be_grouped_into group }
      when ".json"
        it { should be_mode 644 }
        it { should be_owned_by "root" }
        it { should be_grouped_into default_group }
      else
        it { should be_mode 644 }
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
        it { should be_mode 660 }
        it { should be_owned_by "nobody" }
        it { should be_grouped_into group }
      when ".json"
        it { should be_mode 644 }
        it { should be_owned_by "root" }
        it { should be_grouped_into default_group }
      else
        it { should be_mode 644 }
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
    its(:stdout) { should match(/Issuer: CN = Sensu Test CA/) }
    its(:stdout) { should match(/RSA Public-Key: \(2048 bit\)/) }
    its(:stdout) { should match(/Signature Algorithm: sha256WithRSAEncryption/) }
    its(:stdout) { should match(/Subject: CN = #{Regexp.escape(backend)}\.#{Regexp.escape(domain)}/) }
    its(:stdout) { should match(/TLS Web Server Authentication/) }
    its(:stdout) { should_not match(/TLS Web Client Authentication/) }
    its(:stdout) { should match(/DNS:localhost, DNS:#{Regexp.escape(backend)}, IP Address:127\.0\.0\.1, IP Address:10\.0\.0\.[123]/) }
  end
end
