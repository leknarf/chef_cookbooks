node.default['fqdn']['domain'] = 'example.com'

name = node['name'].nil? ? node['name'] : 'example'

# Set hostname from node name
fqdn = "#{name}.#{node['fqdn']['domain']}"
changed = false
file '/etc/hostname' do
  content "#{name}\n"
  mode "0644"
end

if node['fqdn'] != fqdn
  execute "hostname #{name}"
  changed = true
end

hosts = search(:node, "*:*", "X_CHEF_id_CHEF_X asc")

template "/etc/hosts" do
  source "hosts.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :hosts => hosts,
    :domain => node['fqdn']['domain']
  )
end

ohai 'reload' if changed
