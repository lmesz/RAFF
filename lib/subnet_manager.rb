class SubnetManager

  def initialize(ec2, logger)
    @ec2 = ec2
    @logger = logger
  end

  def create_subnet_if_not_exists(vpc_id)
    subnet_name = 'TestSubnet'

    @logger.info('Check if subnet exists ...')

    subnet = @ec2.subnets(filters: [{name: 'tag:Name', values: [subnet_name]}])
    if subnet.first.instance_of? Aws::EC2::Subnet
      @logger.info('Subnet exists')
      return subnet.first.id
    end

    @logger.info('Subnet does not exists create it')

    subnet = @ec2.create_subnet({
                                    vpc_id: vpc_id,
                                    cidr_block: '10.200.10.0/24',
                                    availability_zone: 'us-east-1c'
                                })

    subnet.create_tags({tags: [{key: 'Name', value: subnet_name}]})
    return subnet.id
  end
end
