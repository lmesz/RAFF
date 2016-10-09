require 'aws-sdk'
require 'parseconfig'
require './lib/aws_base'

# This class is responsible for handling AWS security groups
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
    begin
      sec_group_name = 'TestSecurityGroup'
      @logger.info('Security group does not exists, create...')
      create_sec_group(sec_group_name, vpc_id)
    rescue
      raise SecurityGroupManagerException, 'Failed to create security group!'
    end
  end

  def create_sec_group(sec_group_name, vpc_id)
    sg = @ec2.create_security_group(group_name: sec_group_name,
                                    description: 'Simple description.',
                                    vpc_id: vpc_id)
    ip_params = create_ip_params
    sg.authorize_egress(ip_permissions: ip_params)
    sg.authorize_ingress(ip_permissions: ip_params)
    sg.id
  end

  # rubocop:disable Metrics/MethodLength
  def create_ip_params
    ip_params = []
    @config['security group']['port'].split(',').each do |port|
      ip_params << {
        ip_protocol: @config['security group']['proto'],
        from_port: port.to_i,
        to_port: port.to_i,
        ip_ranges: [{
          cidr_ip: @config['security group']['cidr']
        }]
      }
    end
    ip_params
  end
end

class SecurityGroupManagerException < RuntimeError
end
