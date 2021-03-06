# encoding: utf-8
#

LDAP_CA_CERT = attribute(
  'ldap_ca_cert',
  default: '/etc/openldap/ldap-cacert.pem',
  description: "Certificate file containing CA certificate for LDAP"
)

control "V-72231" do
  title "The operating system must implement cryptography to protect the
integrity of Lightweight Directory Access Protocol (LDAP) communications."
  desc  "
    Without cryptographic integrity protections, information can be altered by
unauthorized users without detection.

    Cryptographic mechanisms used for protecting the integrity of information
include, for example, signed hash functions using asymmetric cryptography
enabling distribution of the public key to verify the hash information while
maintaining the confidentiality of the key used to generate the hash.
  "
  impact 0.5
  tag "gtitle": "SRG-OS-000250-GPOS-00093"
  tag "gid": "V-72231"
  tag "rid": "SV-86855r2_rule"
  tag "stig_id": "RHEL-07-040200"
  tag "cci": ["CCI-001453"]
  tag "documentable": false
  tag "nist": ["AC-17 (2)", "Rev_4"]
  tag "check": "Verify the operating system implements cryptography to protect
the integrity of remote ldap access sessions.

To determine if LDAP is being used for authentication, use the following
command:

# grep -i useldapauth /etc/sysconfig/authconfig
USELDAPAUTH=yes

If USELDAPAUTH=yes, then LDAP is being used.

Check that the path to the X.509 certificate for peer authentication with the
following command:

# grep -i cacertfile /etc/pam_ldap.conf
tls_cacertfile /etc/openldap/ldap-cacert.pem

Verify the \"tls_cacertfile\" option points to a file that contains the trusted
CA certificate.

If this file does not exist, or the option is commented out or missing, this is
a finding."
  tag "fix": "Configure the operating system to implement cryptography to
protect the integrity of LDAP remote access sessions.

Set the \"tls_cacertfile\" option in \"/etc/pam_ldap.conf\" to point to the
path for the X.509 certificates used for peer authentication."
  tag "fix_id": "F-78585r1_fix"

  authconfig = parse_config_file('/etc/sysconfig/authconfig')

  USESSSD_ldap_enabled = (authconfig.params['USESSSD'].eql? 'yes' and
    !command('grep "^\s*id_provider\s*=\s*ldap" /etc/sssd/sssd.conf').stdout.strip.empty?)

  USESSSDAUTH_ldap_enabled = (authconfig.params['USESSSDAUTH'].eql? 'yes' and
    !command('grep "^\s*[a-z]*_provider\s*=\s*ldap" /etc/sssd/sssd.conf').stdout.strip.empty?)

  USELDAPAUTH_ldap_enabled = (authconfig.params['USELDAPAUTH'].eql? 'yes')

  # @todo - verify best way to check this
  VAS_QAS_ldap_enabled = (package('vasclnt').installed? or service('vasd').installed?)

  if !(USESSSD_ldap_enabled or USESSSDAUTH_ldap_enabled or
       USELDAPAUTH_ldap_enabled or VAS_QAS_ldap_enabled)
    impact 0.0
    describe "LDAP not enabled" do
      skip "LDAP not enabled using any known mechanisms, this control is Not Applicable."
    end
  end

  if USESSSD_ldap_enabled
    ldap_id_use_start_tls = command('grep ldap_id_use_start_tls /etc/sssd/sssd.conf')
    describe ldap_id_use_start_tls do
      its('stdout.strip') { should match %r{^ldap_id_use_start_tls = true$}}
    end

    ldap_id_use_start_tls.stdout.strip.each_line do |line|
      describe line do
        it { should match %r{^ldap_id_use_start_tls = true$}}
      end
    end
  end

  if USESSSDAUTH_ldap_enabled
    describe command('grep -i ldap_tls_cacert /etc/sssd/sssd.conf') do
      its('stdout.strip') { should match %r{^ldap_tls_cacert = #{Regexp.escape(LDAP_CA_CERT)}$}}
    end
    describe file(LDAP_CA_CERT) do
      it { should exist }
      it { should be_file }
    end
  end

  if USELDAPAUTH_ldap_enabled
    describe command('grep -i tls_cacertfile /etc/pam_ldap.conf') do
      its('stdout.strip') { should match %r{^tls_cacertfile #{Regexp.escape(LDAP_CA_CERT)}$}}
    end
    describe file(LDAP_CA_CERT) do
      it { should exist }
      it { should be_file }
    end
  end

  # @todo - not sure how USELDAP is implemented and how it affects the system, so ignore for now

  if VAS_QAS_ldap_enabled
    describe command('grep ldap-gsssasl-security-layers /etc/opt/quest/vas/vas.conf') do
      its('stdout.strip') { should match %r{^ldap-gsssasl-security-layers = 0$}}
      its('stdout.strip.lines.length') { should eq 1 }
    end
  end
end

