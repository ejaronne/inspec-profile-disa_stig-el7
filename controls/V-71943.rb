# encoding: utf-8          
#
=begin
-----------------
Benchmark: Red Hat Enterprise Linux 7 Security Technical Implementation Guide
Status: Accepted

This Security Technical Implementation Guide is published as a tool to improve
the security of Department of Defense (DoD) information systems. The
requirements are derived from the National Institute of Standards and
Technology (NIST) 800-53 and related documents. Comments or proposed revisions
to this document should be sent via email to the following address:
disa.stig_spt@mail.mil.

Release Date: 2017-03-08
Version: 1
Publisher: DISA
Source: STIG.DOD.MIL
uri: http://iase.disa.mil
-----------------
=end
UNSUCCESSFUL_ATTEMPTS = attribute('unsuccessful_attempts', default: '3',
description: 'The account is denied access after the specified number of
consecutive failed logon attempts.')
FAIL_INTERVAL = attribute('fail_interval', default: '900',
description: 'The interval of time in which the consecutive failed logon
attempts must occur in order for the account to be locked out.')
LOCKOUT_TIME = attribute('lockout_time', default: '604800',
description: 'The amount of time that an account must be locked out for
after the specified number of unsuccessful logon attempts.')

control "V-71943" do
  title "Accounts subject to three unsuccessful logon attempts within 15 minutes
must be locked for the maximum configurable period."
  desc  "
    By limiting the number of failed logon attempts, the risk of unauthorized system
access via user password guessing, otherwise known as brute-forcing, is reduced.
Limits are imposed by locking the account.

    Satisfies: SRG-OS-000329-GPOS-00128, SRG-OS-000021-GPOS-0000.
  "
  impact 0.5
  tag "severity": "medium"
  tag "gtitle": "SRG-OS-000329-GPOS-00128"
  tag "gid": "V-71943"
  tag "rid": "SV-86567r2_rule"
  tag "stig_id": "RHEL-07-010320"
  tag "cci": "CCI-002238"
  tag "nist": ["AC-7 b", "Rev_4"]
  tag "subsystems": ['pam']
  tag "check": "Verify the operating system automatically locks an account for the
maximum period for which the system can be configured.

Check that the system locks an account for the maximum period after three
unsuccessful logon attempts within a period of 15 minutes with the following command:

# grep pam_faillock.so /etc/pam.d/password-auth-ac
auth        required       pam_faillock.so preauth silent audit deny=3
even_deny_root unlock_time=604800
auth        [default=die]  pam_faillock.so authfail audit deny=3 even_deny_root
unlock_time=604800

If the \"unlock_time\" setting is greater than \"604800\" on both lines with the
\"pam_faillock.so\" module name or is missing from a line, this is a finding."
  tag "fix": "Configure the operating system to lock an account for the maximum
period when three unsuccessful logon attempts in 15 minutes are made.

Modify the first three lines of the auth section of the
\"/etc/pam.d/system-auth-ac\" and \"/etc/pam.d/password-auth-ac\" files to match the
following lines:

auth        required       pam_faillock.so preauth silent audit deny=3
even_deny_root fail_interval=900 unlock_time=604800
auth        sufficient     pam_unix.so try_first_pass
auth        [default=die]  pam_faillock.so authfail audit deny=3 even_deny_root
fail_interval=900 unlock_time=604800

and run the \"authconfig\" command."
  
  only_if { file('/etc/pam.d/password-auth-ac').exist? }
  
  describe command("grep -Po '^auth\s+required\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'deny\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should <= UNSUCCESSFUL_ATTEMPTS }
  end
  
  describe command("grep -Po '^auth\s+required\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'fail_interval\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should <= FAIL_INTERVAL }
  end
  
  describe command("grep -Po '^auth\s+required\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'unlock_time\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should >= LOCKOUT_TIME }
  end
  
  describe command("grep -Po '^auth\s+\[default=die\]\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'deny\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should <= UNSUCCESSFUL_ATTEMPTS }
  end
  
  describe command("grep -Po '^auth\s+\[default=die\]\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'fail_interval\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should <= FAIL_INTERVAL }
  end
  describe command("grep -Po '^auth\s+\[default=die\]\s+pam_faillock.so.*$' /etc/pam.d/system-auth-ac-1 | grep -Po '(?<=pam_faillock.so).*$' | grep -Po 'unlock_time\s*=\s*[0-9]+' | cut -d '=' -f2") do
    its('content') { should >= LOCKOUT_TIME }
  end 
end
