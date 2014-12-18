require 'chef/provisioning/aws_driver'
with_driver 'aws'

1.upto(3) do |n|
  machine "webserver-#{n}" do
    action :destroy
  end
end

load_balancer 'webserver-elb' do
  action :destroy
end
