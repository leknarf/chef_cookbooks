backup_user = node[:backup][:backup_user]
backup_home = node[:backup][:backup_home]

package "libxslt" do
  package_name "libxslt-dev"
  action :install
end

package "libxml-dev" do
  package_name "libxml2-dev"
  action :install
end

gem_package 'fog' do
  action :install
  version "~> 1.4.0"
end

['backup', 's3sync', 'mail', 'whenever', 'popen4'].each do |gem_name|
  gem_package gem_name do
    action :install
  end
end

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

cron_command = "/usr/local/bin/backup perform --trigger postgres_backup"
cron "hourly backup" do
  user backup_user
  minute "0"
  command(cron_command + '_hourly')
end
cron "daily backup" do
  user backup_user
  hour "0"
  minute "0"
  command(cron_command + '_daily')
end
cron "weekly backup" do
  user backup_user
  hour "0"
  minute "0"
  weekday "0"
  command(cron_command + '_weekly')
end
cron "monthly backup" do
  user backup_user
  hour "0"
  minute "0"
  day "1"
  command(cron_command + '_monthly')
end
