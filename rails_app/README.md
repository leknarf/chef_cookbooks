# Overview

Deploys a full rails application stack, including the following components:

  - nginx
  - unicorn
  - sidekiq
  - clockwork
  - monit

This is similar to the OpsCode [Application Ruby](https://github.com/opscode-cookbooks/application_ruby) cookbook, but includes more components in the stack.

# Additional features

  - Includes Monit, Init, and Upstart scripts
  - Graceful, zero-downtime restarts (via Unicorn)
  - Configures SSH to allow source checkouts from Github
  - Installs ruby 2.0 (via ruby_build, can be configured to use 1.9.3 instead)
  - Sends a notification to a given email address after a successful deployment

# Notes

This cookbook currently assumes you are running your entire stack on one machine and only want one instance of each component. If you want to run multiple web servers behind a load balancer, you'll need to separate the web server setup from the background workers and task scheduler.

For simplicity, this cookbook stops the background workers and task scheduler before running a database migration. That works well for many small projects, but may not be suitable for your needs.

# Configuration

Create a wrapper cookbook with the following in `recipes/default.rb`, changing the attributes as necessary.

  node.normal['rails_app']['database'] = {
        'adapter' => 'postgresql',
        'database' => 'example_database',
        'host' => 'db.example.com',
        'port' => '5432',
        'username' => 'db_user',
        'password' => 'super_secret_password',
        'pool' => '50',
      }

  node.override['rails_app']['git_repo'] = 'git@github.com:example_org/example.git'
  node.override['rails_app']['git_branch'] = 'master'

  node.override['rails_app']['workers'] = { :default => 1 }
  node.override['rails_app']['deploy_dir'] = '/opt/example'
  node.override['rails_app']['unicorn_config'] = '/etc/unicorn/example.rb'
  node.override['rails_app']['user'] = 'example'
  node.override['rails_app']['group'] = 'example'
  node.override['rails_app']['notify_email'] = 'admin@example.com'
  node.override['rails_app']['server_name'] = 'example.com'

  node.override['github']['id_rsa'] = <<-EOS
  -----BEGIN RSA PRIVATE KEY-----
  A private key for a deploy user
  -----END RSA PRIVATE KEY-----
  EOS

  include_recipe 'rails_app'
