require_relative "spec_helper"

ca_dir = case os[:family]
         when "freebsd"
           "/usr/local/etc/cfssl"
         else
           "/etc/cfssl"
         end
ca_root_dir = "#{ca_dir}/root"

intermediate_ca_names = ["Test development CA", "Test production CA"]
intermediate_ca = %w[development production]

intermediate_ca_names.each do |n|
  ca_name = n.gsub(/[ ]/, "_")
  file_name = "#{ca_root_dir}/certs/#{ca_name}"
  describe file "#{file_name}-key.pem" do
    it { should exist }
    it { should be_file }
    it { should be_mode 640 }
    its(:content) { should match(/BEGIN RSA PRIVATE KEY/) }
  end

  describe file "#{file_name}.csr" do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    its(:content) { should match(/BEGIN CERTIFICATE REQUEST/) }
  end

  describe file "#{file_name}.pem" do
    it { should exist }
    it { should be_file }
    case os[:family]
    when "ubuntu"
      it { should be_mode 664 }
    else
      it { should be_mode 644 }
    end
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end
end

intermediate_ca.each do |ca|
  describe file "#{ca_root_dir}/certs/#{ca}.json" do
    its(:content_as_json) { should include("CN" => "Test #{ca} CA") }
  end
end

intermediate_ca.each do |ca|
  filename = "#{ca_dir}/#{ca}/certs/agent1.example.com.pem"
  describe command "openssl x509 -text -in #{filename}" do
    its(:stderr) { should eq "" }
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/Issuer: CN = Test #{ca} CA/) }
  end

  # verify bundled certificate
  describe command "cat '#{ca_root_dir}/certs/Test_#{ca}_CA.pem' '#{filename}' | openssl verify -CAfile '#{ca_root_dir}/ca.pem'" do
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/: OK$/) }
  end
end
