#
# Cookbook Name:: database
# Recipe:: default
#
# Copyright 2009, Jim Van Fleet
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Two cases to prepare for:

# DB Node registers with Chef
# I log in, validate the node, instruct it "apply the database role to yourself"
# DB Node complies, setting a root password
# DB Node asks "any nodes have applications out there I need to configure myself for?"
# Server says "nope" seeing no nodes
# Run ends

# DB Node runs chef-client
# DB node asks "any nodes have applications out there I need to configure myself for?"
# Server, seeing node with <name-of-rails-app>, says "yes, this one"
# DB node generates appropriate user, database, and grants, flushing privileges.
# Run ends

include_recipe "mysql::server"

# Broadcast this as a database location.  If there are multiples, let client cookbooks
# sort it out.

node[:database] ||= Mash.new
node[:database][:location] = `hostname -f`.downcase.strip
 
Gem.clear_paths
require 'mysql'

Chef::Log.info "Configure which master to use, and where in the logs, start slave"

execute "mysql-slave-config" do
  command "/usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < /etc/mysql/configure-slave.sql"
  action :nothing
end

template "/etc/mysql/configure-slave.sql" do
  source "configure-slave.sql.erb"
  owner "root"
  group "root"
  mode "0600"
   variables(
        :master_host     => master_host,
        :slave_username => slave_username,
        :slave_password => slave_password,
        :log_file_name => log_file_name,
        :log_position => log_position
      )
  notifies :run, resources(:execute => "mysql-slave-config"), :immediately
end