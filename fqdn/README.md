# Overview

Sets the server's FQDN (fully qualified domain name) from the node name. That is, if you create a node named"app01" and set your domain to "mydomain.com", this cookbook will set the FQDN to "app01.mydomain.com"

This will also create a `/etc/hosts` file with the IP address and FQDN of each node in your chef organization, allowing you to access the servers in your network without relying on DNS.

# Configuration

Create a wrapper cookbook with the following in `recipes/default.rb`, changing the attributes as necessary.

  node.override['fqdn']['domain'] = 'example.com'
  include_recipe 'fqdn'
