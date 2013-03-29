# Overview

Sane defaults for a production box running Ubuntu. See `recipes/default.rb` for details.

# Configuration

Create a wrapper cookbook with the following in `recipes/default.rb`, changing the attributes as necessary.

  # Your chef configuration
  node.override['chef_client']['server_url'] = 'https://api.opscode.com/organizations/my_organization'
  node.override['chef_client']['validation_client_name'] = 'my-validator'
  node.override['chef_client']['bin'] = '/usr/local/bin/chef-client'

  # Add the usernames for any server logins you'd like to create here
  node.normal['users'] = %w(user1 user2)

  # Your New Relic License Key
  # New Relic's server monitoring is free, so you don't have any excuse not to get one
  node.normal['newrelic']['license_key'] = ''

  # Set up local email sending
  # I'm using Sendgrid, but this should be applicable elsewhere too
  node.normal['postfix']['relayhost'] = 'smtp.sendgrid.net:587'
  node.normal['postfix']['smtp_sasl_auth_enable'] = 'yes'
  node.normal['postfix']['smtp_sasl_password_maps'] = 'static:my_login@example.com:my_password'
  node.normal['postfix']['smtp_sasl_security_options'] = 'noanonymous'
  node.normal['postfix']['smtp_use_tls'] = 'yes'

  # Any Apt packages you want installed on every machine
  node.normal['base']['packages'] = %w(mailutils ntp)

  include_recipe 'base'
