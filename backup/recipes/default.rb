backup_user = node[:backup][:backup_user]
backup_home = node[:backup][:backup_home]

node.default['backup']['backup_triggers'] = %w(database)

package "libxslt" do
  package_name "libxslt-dev"
  action :install
end

package "libxml-dev" do
  package_name "libxml2-dev"
  action :install
end

['builder', 'formatador', 'multi_json', 'backup', 's3sync', 'mail', 'whenever', 'popen4', 'net-ssh'].each do |gem_name|
  execute "gem install --no-ri --no-rdoc #{gem_name}"
end

execute "gem install --no-ri --no-rdoc excon -v '~> 0.14.0'" # for fog
execute "gem install --no-ri --no-rdoc excon -v '~> 0.17.0'" # for backup
execute "gem install --no-ri --no-rdoc net-scp -v '<= 1.0.4'"
execute "gem install --no-ri --no-rdoc fog -v '~> 1.9.0'"

execute "chown #{backup_user}:#{backup_user} #{backup_home}"

execute "mkdir -p #{backup_home}/Backup/config" do
  user backup_user
  not_if { File.directory?("#{backup_home}/Backup/config") }
end

execute "mkdir -p #{backup_home}/Backup/log" do
  user backup_user
  not_if { File.directory?("#{backup_home}/Backup/log") }
end

template "#{backup_home}/Backup/config.rb" do
  owner backup_user
  source "config.rb.erb"
  variables(:config => node[:backup])
end

node.override['backup']['backup_command'] = '/usr/local/ruby/ruby-2.0.0-p0/lib/ruby/gems/2.0.0/gems/backup-3.3.2/bin/backup'

node['backup']['backup_triggers'].each do |trigger|
  cron_command = "#{node['backup']['backup_command']} perform --trigger #{trigger}_backup"
  cron "hourly #{trigger} backup" do
    user backup_user
    minute "0"
    command(cron_command + '_hourly')
  end
  cron "daily #{trigger} backup" do
    user backup_user
    hour "0"
    minute "0"
    command(cron_command + '_daily')
  end
  cron "weekly #{trigger} backup" do
    user backup_user
    hour "0"
    minute "0"
    weekday "0"
    command(cron_command + '_weekly')
  end
  cron "monthly #{trigger} backup" do
    user backup_user
    hour "0"
    minute "0"
    day "1"
    command(cron_command + '_monthly')
  end
end
