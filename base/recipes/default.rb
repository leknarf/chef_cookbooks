node.normal['authorization']['sudo']['groups'] = %w(wheel)
node.normal['authorization']['sudo']['passwordless'] = true
node.normal['authorization']['sudo']['users'] = %w(vagrant) if Chef::Config[:solo]

node.normal['base']['packages'] = %w(mailutils ntp)
node.normal['base']['timezone'] = 'America/New_York'

include_recipe 'apt'
include_recipe 'build-essential'
include_recipe 'chef-client::delete_validation'
include_recipe 'chef-client::config'
include_recipe 'chef-client::service'
include_recipe 'fqdn' unless Chef::Config[:solo]
include_recipe 'git'
include_recipe 'newrelic'
include_recipe 'openssl'
include_recipe 'postfix'
include_recipe 'sudo'
include_recipe 'ubuntu'
include_recipe 'user::data_bag'

node['base']['packages'].each do |pkg|
  package pkg do
    action :install
  end
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
