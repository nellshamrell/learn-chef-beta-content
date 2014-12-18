require 'chef/provisioning/aws_driver'
with_driver 'aws'

# declare two security groups - one that provides inbound access on port 22 (SSH) and another that provides inbound access on port 80 (HTTP)
aws_security_group 'webserver-ssh' do
  inbound_rules [{:ports => 22, :protocol => :tcp, :sources => ['0.0.0.0/0'] }]
end

aws_security_group 'webserver-http' do
  inbound_rules [{:ports => 80, :protocol => :tcp, :sources => ['0.0.0.0/0'] }]
end

webservers = []

# declare two machines to act as our web servers
1.upto(3) do |n|
  webserver = "webserver-#{n}"
  machine webserver do
    # specify what's needed to create the machine
    machine_options lazy { ({
      :bootstrap_options => {
        :instance_type => 't1.micro',
        :security_group_ids => [
          data_bag_item('aws_security_groups', 'webserver-ssh')['security_group_id'],
          data_bag_item('aws_security_groups', 'webserver-http')['security_group_id']
        ]
      },
      :ssh_username => 'root',
      :image_id => 'ami-b6bdde86'
      }) }
    recipe 'web'
    tag 'webserver'
    converge true
  end
  webservers << webserver
end

load_balancer 'webserver-lb' do
  load_balancer_options({
    :availability_zones => ['us-west-2a', 'us-west-2b', 'us-west-2c'],
    :listeners => [{
      :port => 80,
      :protocol => :http,
      :instance_port => 80,
      :instance_protocol => :http
    }],
    :security_group_name => 'webserver-http'
  })
  machines webservers
end
