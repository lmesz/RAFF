require_relative 'instance_manager.rb'
require_relative 'security_group_manager.rb'
require_relative 'subnet_manager.rb'
require_relative 'vpc_manager.rb'
require_relative 'key_manager.rb'
require 'logger'
require 'net/ssh'
require 'net/scp'
require 'net/http'
require 'aws-sdk'

class AwsDrupalClusterHandler < InstanceManager
  REGION = 'us-east-1'.freeze
  KEY_NAME = 'TestKey'.freeze

  def initialize(ec2 = Aws::EC2::Resource.new(region: REGION), logger=Logger.new(STDOUT))
    @ec2 = ec2
    @logger = logger
  end

  def deploy(instance_name)
    key_manager = KeyManager.new(@ec2, @logger, KEY_NAME)
    key_manager.import_key_if_not_exists

    vpc_manager = VpcManager.new(@ec2, @logger)
    vpc_id = vpc_manager.create_vpc_if_not_exists

    subnet_manager = SubnetManager.new(@ec2, @logger)
    subnet_id = subnet_manager.create_subnet_if_not_exists(vpc_id)

    security_group_manager = SecurityGroupManager.new(@ec2, @logger)
    sg_id = security_group_manager.create_security_group_if_not_exists(vpc_id)
    create_instance(instance_name, sg_id, subnet_id)
  end
end
