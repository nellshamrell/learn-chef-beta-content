require 'chef/provisioning'
with_driver 'aws'

with_machine_options :bootstrap_options => {
  :instance_type => 't1.micro'
  },
  :ssh_username => 'root',
  :image_id => 'ami-b6bdde86'

webservers = []

1.upto(3) do |n|
  webserver = "webserver-#{n}"
  machine webserver do
    recipe 'web'
    tag 'webserver'
    converge true
  end
  webservers << webserver
end

load_balancer 'webserver-lb' do
  load_balancer_options :availability_zones => ['us-west-2a', 'us-west-2b', 'us-west-2c'],
  :listeners => [{
    :port => 80,
    :protocol => :http,
    :instance_port => 80,
    :instance_protocol => :http
    }],
    machines webservers
  end
