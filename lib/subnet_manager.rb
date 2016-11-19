require 'aws-sdk'
require './lib/aws_base'

class SubnetManager < AwsBase
  def create_subnet_if_not_exists(vpc_id)
    subnet_name = 'TestSubnet'
    @logger.info('Subnet does not exists create it')
    create_subnet(vpc_id, subnet_name)
  rescue
    raise SubnetManagerException, 'Failed to create subnet!'
  end

  def create_subnet(vpc_id, subnet_name)
    subnet = @ec2.create_subnet(vpc_id: vpc_id,
                                cidr_block: '10.200.10.0/24',
                                availability_zone: 'us-east-1c')

    subnet.wait_until { |created_subnet| created_subnet.state == 'available' }

    subnet.create_tags(tags: [{ key: 'Name', value: subnet_name }])
    subnet.id
  end
end

class SubnetManagerException < StandardError
end
