require 'aws-sdk'
require './lib/aws_base'

class VpcManager < AwsBase
  def create_vpc_if_not_exists
    vpc_tag_name = 'TestVPC'
    @logger.info('Create vpc ...')
    vpc = @ec2.create_vpc(cidr_block: @config['vpc']['cidr'])
    configure_vpc(vpc, vpc_tag_name)
    create_igw_for_vpc(vpc.vpc_id)
    vpc.vpc_id
  rescue RuntimeError
    raise VpcManagerException, 'Failed to create vpc.'
  end

  def configure_vpc(vpc, vpc_tag_name)
    vpc.wait_until_exists
    vpc.modify_attribute(enable_dns_support: { value: !@config['vpc']['dns_support'].nil? })
    vpc.modify_attribute(enable_dns_hostname: { value: !@config['vpc']['dns_hostname'].nil? })
    vpc.create_tags(tags: [{ key: 'Name', value: vpc_tag_name }])
  end

  def create_igw_for_vpc(vpc_id)
    igw_id = attach_vpc_to_internet_gateway(vpc_id)
    create_route_table_to_internet_gateway(vpc_id, igw_id)
  end

  def attach_vpc_to_internet_gateway(vpc_id)
    igw_name = 'TestIGW'
    @logger.info('Internet Gateway does not exists, create it ...')
    create_igw(igw_name, vpc_id)
  end

  private
  def create_igw(igw_name, vpc_id)
    igw = @ec2.create_internet_gateway
    sleep(10)
    igw.create_tags(tags: [{ key: 'Name',
                             value: igw_name }])
    igw.attach_to_vpc(vpc_id: vpc_id)
    igw.id
  end

  def create_route_table_to_internet_gateway(vpc_id, igw_id)
    @logger.info('Add the internet gateway to the route tables ...')
    route_table = @ec2.route_tables(filters: [{ name: 'vpc-id',
                                                values: [vpc_id] }])
    route_table.first.create_route(destination_cidr_block: @configure['vpc']['cidr'],
                                   gateway_id: igw_id)
  end
end

class VpcManagerException < RuntimeError
end
