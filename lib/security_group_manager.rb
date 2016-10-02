require 'aws-sdk'
require 'parseconfig'
require 'aws_base'

class SecurityGroupManager < AwsBase
  attr_reader :config

  def initialize(ec2 = Aws::EC2::Resource.new(region: 'us-east-1',
                                              stub_responses: true),
                 logger = Logger.new(STDOUT),
                 config = 'config')
    super(ec2, logger)
    @config = ParseConfig.new(File.join(File.dirname(__FILE__),
                                        '..',
                                        'conf',
                                        config))
  end

  def create_security_group_if_not_exists(vpc_id)
    security_group_name = 'TestSecurityGroup'

    @logger.info('Check if security group exists ...')

    sec_group = @ec2.security_groups(filters: [{ name: 'group-name', values: [security_group_name] }])

    if sec_group.first.instance_of? Aws::EC2::SecurityGroup
      @logger.info('Security group exists')
      return sec_group.first.id
    end

    @logger.info('Security group does not exists, create...')

    sg = @ec2.create_security_group(group_name: security_group_name,
                                    description: 'Simple description.',
                                    vpc_id: vpc_id)

    ports = @config['security group']['port'].split(',')

    ip_params = [
                  {
                    ip_protocol: @config['security group']['proto'],
                    from_port: ports[0].to_i,
                    to_port: ports[0].to_i,
                    ip_ranges: [{
                      cidr_ip: @config['security group']['cidr'],
                    }]
                  },
                  {
                    ip_protocol: @config['security group']['proto'],
                    from_port: ports[1].to_i,
                    to_port: ports[1].to_i,
                    ip_ranges: [{
                      cidr_ip: @config['security group']['cidr'],
                    }]
                  }
                ]

    sg.authorize_egress(ip_permissions: ip_params )
    sg.authorize_ingress(ip_permissions: ip_params)

    sg.id
  end
end
