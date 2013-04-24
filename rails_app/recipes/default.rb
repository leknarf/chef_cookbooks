
include_recipe 'monit'
include_recipe 'ruby_build'
node.default['rails_app']['ruby_version'] = '2.0.0-p0'

file "/etc/gemrc" do
  content <<-EOS
    install: --no-rdoc --no-ri
    update:  --no-rdoc --no-ri
  EOS
  owner "root"
  mode 0644
end

ruby_build_ruby node['rails_app']['ruby_version'] do
  prefix_path "/usr/local/ruby/ruby-#{node['rails_app']['ruby_version']}"
  action :install
end

gem_package 'bundler' do
  gem_binary "/usr/local/ruby/ruby-#{node['rails_app']['ruby_version']}/bin/gem"
end

['ruby', 'gem', 'bundle'].each do |bin|
  link "/usr/local/bin/#{bin}" do
    to "/usr/local/ruby/ruby-#{node['rails_app']['ruby_version']}/bin/#{bin}"
  end
end

node.default['rails_app']['install_redis'] = true
node.default['rails_app']['services'] = %w(unicorn sidekiq clock)

if node['rails_app']['install_redis']
  include_recipe 'redis::server_package'
end

node.default['rails_app']['database'] = {
      'adapter' => 'postgresql',
      'database' => 'example_database',
      'host' => 'example_host',
      'port' => '5432',
      'username' => 'example',
      'password' => 'example',
      'pool' => '50',
    }
node.default['rails_app']['create_db'] = false
node.default['rails_app']['db_exists_command'] = "true"
node.default['rails_app']['create_db_command'] = "bundle exec rake db:create && bundle exec rake db:schema:load"

node.default['rails_app']['user'] = 'example'
node.default['rails_app']['group'] = 'example'
node.default['rails_app']['uid'] = 2000
node.default['rails_app']['gid'] = 2000
node.default['rails_app']['deploy_dir'] = '/opt/example'
node.default['rails_app']['unicorn_config'] = '/etc/unicorn/example.rb'
node.default['rails_app']['keep_releases'] = 3
node.default['rails_app']['bundler_without_groups'] = %w(development test cucumber staging darwin)
node.default['rails_app']['git_repo'] = 'git@github.com:example_repo.git'
node.default['rails_app']['git_branch'] = 'master'
node.default['rails_app']['rails_env'] = 'production'
node.default['rails_app']['unicorn_workers'] = 3
node.default['rails_app']['nginx_workers'] = 3
node.default['rails_app']['server_name'] = 'example.com'
if node['rails_app']['services'].include? 'sidekiq'
  node.default['rails_app']['sidekiq_workers'] = 25
  node.default['rails_app']['sidekiq_worker_priority'] = { :default => 1 }
end


node.default['rails_app']['packages'] = %w(openssl libpq-dev libreadline6 libreadline6-dev libxml2-dev libxslt-dev libyaml-dev zlib1g zlib1g-dev imagemagick libmagickcore-dev)

node.default['github']['id_rsa'] = <<-EOS
-----BEGIN RSA PRIVATE KEY-----
Create a deploy user account in github,
give it read access to your repo,
and put its private key here.
-----END RSA PRIVATE KEY-----
EOS

node.default['rails_app']['packages'] = %w(openssl libpq-dev libreadline6 libreadline6-dev libxml2-dev libxslt-dev libyaml-dev zlib1g zlib1g-dev imagemagick libmagickcore-dev)
node['rails_app']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

ssh_known_hosts_entry 'github.com'

group node['rails_app']['group'] do
  gid node['rails_app']['gid']
end

user node['rails_app']['user'] do
  uid node['rails_app']['uid']
  gid node['rails_app']['gid']
  home "/home/#{node['rails_app']['user']}"
  shell '/bin/bash'
end

directory "/home/#{node['rails_app']['user']}/.ssh" do
  owner node['rails_app']['user']
  group node['rails_app']['group']
  mode "0700"
  action :create
  recursive true
end

file "/home/#{node['rails_app']['user']}/.ssh/id_rsa" do
  content node['github']['id_rsa']
  owner node['rails_app']['user']
  mode 0600
end

[
  node['rails_app']['deploy_dir'] + '/shared',
 '/var/run/',
 '/var/log/nginx',
 '/var/log/unicorn',
].each do |dir|
  directory dir do
    owner node['rails_app']['user']
    group node['rails_app']['group']
    mode '0755'
    action :create
    recursive true
  end
end

file "/etc/gemrc" do
  content <<-EOS
    install: --no-rdoc --no-ri
    update:  --no-rdoc --no-ri
  EOS
  owner "root"
  mode 0644
end

directory "/etc/unicorn" do
  action :create
  owner node['rails_app']['user']
  mode '0755'
end

template node['rails_app']['unicorn_config'] do
  source 'unicorn.rb.erb'
  variables(:working_directory => "#{node['rails_app']['deploy_dir']}/current")
  mode '0755'
  owner node['rails_app']['user']
end

# Deploy monit service config files
node['rails_app']['services'].each do |service_name|
  template "/etc/monit/conf.d/#{service_name}.monitrc" do
    source "#{service_name}.monitrc.erb"
    mode '0755'
    owner node['rails_app']['user']
    notifies :restart, "service[monit]", :immediately
  end
end

# Deploy unicorn init.d script
template "/etc/init.d/unicorn" do
  source "unicorn.erb"
  mode '0755'
  owner 'root'
end

# Deploy upstart scripts for all non-unicorn services
node['rails_app']['services'].reject {|sn| sn == 'unicorn'}.each do |service_name|
  if node['rails_app']['services'].include? service_name
    template "/etc/init/#{service_name}.conf" do
      source "#{service_name}.conf.erb"
      mode '0755'
      owner 'root'
    end
  end
end

package 'nginx' do
  action 'install'
end

service 'nginx' do
  supports :start => true, :stop => true, :reload => true, :restart => true
  action :start
  start_command 'service nginx start'
  stop_command 'service nginx stop'
  status_command 'service nginx status'
  reload_command 'service nginx reload'
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0755'
  notifies :enable, "service[nginx]"
  notifies :start, "service[nginx]"
  notifies :reload, "service[nginx]"
end

deploy_revision node['rails_app']['deploy_dir'] do
  action :deploy
  user node['rails_app']['user']
  group node['rails_app']['group']
  repository node['rails_app']['git_repo']
  revision node['rails_app']['git_branch']
  bundler_without_groups = node['rails_app']['bundler_without_groups']
  create_dirs_before_symlink = %w(tmp log)
  symlink_before_migrate.clear
  symlinks.clear

  migrate true
  migration_command "bundle exec rake db:migrate"
  environment({
    "RBENV_VERSION" => "",
    "RAILS_ENV" => node['rails_app']['rails_env'],
  })

  before_migrate do
    template "#{release_path}/config/database.yml" do
      source 'database.yml.erb'
      owner node['rails_app']['user']
      group node['rails_app']['group']
      mode '0755'
    end

    if node['rails_app']['services'].include? 'sidekiq'
      execute "stop_sidekiq" do
        command "monit stop sidekiq"
        user 'root'
        ignore_failure true # The stop command will fail on the first deployment
      end
    end

    if node['rails_app']['services'].include? 'clock'
      execute "stop_clock" do
        command "monit stop clock"
        user 'root'
        ignore_failure true # The stop command will fail on the first deployment
      end
    end

    execute "bundle_install" do
      command "bundle install --path=vendor/bundle --deployment --without #{bundler_without_groups.join(' ')}"
      user node['rails_app']['user']
      cwd release_path
      environment({
        "RBENV_DIR" => release_path,
        "RBENV_VERSION" => "",
        "RAILS_ENV" => node['rails_app']['rails_env'],
      })
    end

    if node['rails_app']['create_db']
      execute "create db" do
        command node['rails_app']['create_db_command']
        user node['rails_app']['user']
        cwd release_path
        not_if node['rails_app']['db_exists_command']
        environment({
          "RBENV_DIR" => release_path,
          "RBENV_VERSION" => "",
          "RAILS_ENV" => node['rails_app']['rails_env'],
        })
      end
    end
  end

  before_symlink do
    execute "precompile_assets" do
      command "bundle exec rake assets:precompile"
      user node['rails_app']['user']
      cwd release_path
      environment({
        "RBENV_DIR" => release_path,
        "RBENV_VERSION" => "",
        "RAILS_ENV" => node['rails_app']['rails_env'],
      })
    end
  end

  restart_command do
    command = '/etc/init.d/unicorn upgrade'
    command += '; monit start sidekiq' if node['rails_app']['services'].include? 'sidekiq'
    command += '; monit start clock' if node['rails_app']['services'].include? 'clock'
    command += '; monit start xvfb' if node['rails_app']['services'].include? 'xvfb'
    bash "restart_app" do
      user 'root'
      code command
    end
  end

  after_restart do
    directory "#{release_path}/log" do
      action :create
      recursive true
      owner node['rails_app']['user']
      group node['rails_app']['group']
      mode '0777'
    end
    {
      'nginx.access.log' => 'nginx',
      'nginx.error.log' => 'nginx',
      'unicorn.log' => 'unicorn',
    }.each do |log_file, log_dir|
      log_file_path = "#{release_path}/log/#{log_file}"
      file log_file_path do
        user node['rails_app']['user']
        group node['rails_app']['group']
        action :create_if_missing
        mode '0444'
      end
      link log_file_path do
        to "/var/log/#{log_dir}/#{log_file}"
      end
    end

    bash "notify_admins" do
      user node['rails_app']['user']
      code <<-EOH
        git log -n 5 | mail -s "#{node['rails_app']['rails_env']} deployment complete" #{node['rails_app']['notify_email']}
      EOH
      cwd release_path
    end
  end

  notifies :restart, "service[nginx]"
end
