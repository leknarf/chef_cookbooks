node.normal['authorization']['sudo']['groups'] = %w(wheel sudo)
node.normal['authorization']['sudo']['passwordless'] = true
node.normal['authorization']['sudo']['users'] = %w(vagrant) if Chef::Config[:solo]

node.normal['base']['packages'] = %w(mailutils ntp unattended-upgrades fail2ban)
node.normal['base']['timezone'] = 'America/New_York'

node.normal['chef_client']['daemon_options'] = %w(--fork)

unless Chef::Config[:solo]
  include_recipe 'chef-client::delete_validation'
  include_recipe 'chef-client::config'
  include_recipe 'chef-client::service'
  include_recipe 'fqdn'
end

include_recipe 'apt'
include_recipe 'build-essential'
include_recipe 'fail2ban'
include_recipe 'git'
include_recipe 'newrelic'
include_recipe 'openssl'
include_recipe 'postfix'
include_recipe 'sudo'
include_recipe 'ubuntu'
include_recipe 'user'

node['base']['users'].each do |user|
  user_account user['name'] do
    ssh_keys [user['public_key']]
    home "/home/#{user['name']}"
    gid 27 # sudo
  end
end

node['base']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

execute "apt-get-update-on-boot" do
  command "apt-get -y update && apt-get -y dist-upgrade && touch /var/lib/chef/apt_get_lock"
  not_if { File.exists?('/var/lib/chef/apt_get_lock') }
end

package 'whoopsie' do
  action :purge
end

# Set timezone
bash 'Set timezone' do
  user 'root'
  code <<-EOH
    echo "#{node['base']['timezone']}" > /etc/timezone
    dpkg-reconfigure --frontend noninteractive tzdata
  EOH
  not_if { File.new('/etc/timezone').gets.strip == node['base']['timezone'] }
end
