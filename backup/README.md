# Overview
Takes regular backups of postgres and copies them to S3, using the "Backup" ruby gem and cron.

Sends an email notification after a successful run.

# Configuration

Create a wrapper cookbook with the following in `recipes/default.rb`, changing the attributes as necessary.

  node.override['backup'] = {
    :backup_user => "postgres",
    :backup_home => "/var/lib/postgresql",
    :database => {
      :username => "db_user",
      :password => "db_password",
      :databases => ['database_to_backup'],
    },
    :s3 => {
      :aws_access_key => '',
      :aws_secret_key => '',
      :bucket_name => '',
    },
    :mail: {
      :from_address => "backups@example.com",
      :to_address => "my_address@example.com",
      :domain => "example.com",
      :username => "smtp_username",
      :password => "smtp_password",
      :smtp_server => "smtp.example.com",
      :smtp_port => "587",
    },
  }
  include_recipe 'backup'

You may also want to review `templates/default/config.rb.erb`, which is the configuration file for Backup.
