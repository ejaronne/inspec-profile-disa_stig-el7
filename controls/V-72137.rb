# encoding: utf-8
#
control "V-72137" do
  title "All uses of the setsebool command must be audited."
  desc  "
    Without generating audit records that are specific to the security and
mission needs of the organization, it would be difficult to establish,
correlate, and investigate the events relating to an incident or identify those
responsible for one.

    Audit records can be generated from various components within the
information system (e.g., module or policy filter).
  "
  impact 0.5
  tag "gtitle": "SRG-OS-000392-GPOS-00172"
  tag "satisfies": ["SRG-OS-000392-GPOS-00172", "SRG-OS-000463-GPOS-00207",
"SRG-OS-000465-GPOS-00209"]
  tag "gid": "V-72137"
  tag "rid": "SV-86761r3_rule"
  tag "stig_id": "RHEL-07-030570"
  tag "cci": ["CCI-000172", "CCI-002884"]
  tag "documentable": false
  tag "nist": ["AU-12 c", "MA-4 (1) (a)", "Rev_4"]
  tag "subsystems": ['audit', 'auditd', 'audit_rule']
  tag "check": "Verify the operating system generates audit records when
successful/unsuccessful attempts to use the \"setsebool\" command occur.

Check the file system rule in \"/etc/audit/audit.rules\" with the following
command:

# grep -i /usr/sbin/setsebool /etc/audit/audit.rules

-a always,exit -F path=/usr/sbin/setsebool -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-priv_change

If the command does not return any output, this is a finding."
  tag "fix": "Configure the operating system to generate audit records when
successful/unsuccessful attempts to use the \"setsebool\" command occur.

Add or update the following rule in \"/etc/audit/rules.d/audit.rules\":

-a always,exit -F path=/usr/sbin/setsebool -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-priv_change

The audit daemon must be restarted for the changes to take effect."
  tag "fix_id": "F-78489r5_fix"

  @audit_file = '/usr/sbin/setsebool'

  describe auditd.file(@audit_file) do
    its('permissions') { should_not cmp [] }
    its('action') { should_not include 'never' }
  end

  # Resource creates data structure including all usages of file
  @perms = auditd.file(@audit_file).permissions

  @perms.each do |perm|
    describe perm do
      it { should include 'x' }
    end
  end
  only_if { file(@audit_file).exist? }
end

