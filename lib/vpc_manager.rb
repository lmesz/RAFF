require 'aws-sdk'
require './lib/aws_base'

class VpcManager < AwsBase
  def create_vpc_if_not_exists
    vpc_tag_name = 'TestVPC'

    @logger.info('Create vpc ...')
    vpc = @ec2.vpcs(filters: [{ name: 'tag:Name', values: [vpc_tag_name] }])
    return vpc.first.id if vpc.first.instance_of? Aws::EC2::Vpc

    @logger.info('VPC does not exists create it')
    vpc = @ec2.create_vpc(cidr_block: '0.0.0.0/0')

    configure_vpc(vpc, vpc_tag_name)
    create_igw_for_vpc(vpc.vpc_id)

    vpc.vpc_id
  end

  def configure_vpc(vpc, vpc_tag_name)
    vpc.wait_until_exists
    vpc.modify_attribute(enable_dns_support: { value: true })
    vpc.modify_attribute(enable_dns_hostnames: { value: true })
    vpc.create_tags(tags: [{ key: 'Name', value: vpc_tag_name }])
  end

  def create_igw_for_vpc(vpc_id)
    igw_id = attach_vpc_to_internet_gateway(vpc_id)
    create_route_table_to_internet_gateway(vpc_id, igw_id)
  end

  def attach_vpc_to_internet_gateway(vpc_id)
    igw_name = 'TestIGW'

    @logger.info('Check if Internet Gateway already exists ...')

    igw = @ec2.internet_gateways(filters: [{ name: 'tag:Name',
                                             values: [igw_name] }])
    if igw.first.instance_of? Aws::EC2::InternetGateway
      @logger.info('Internet gateway exists ...')
      return igw.first.id
    end

    @logger.info('Internet Gateway does not exists, create it ...')
    create_igw(igw_name, vpc_id)
  end

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

    if route_table.first.instance_of? Aws::EC2::RouteTable
      @logger.info('Route found for the vpc ...')
      route_table.first.create_route(destination_cidr_block: '0.0.0.0/0',
                                     gateway_id: igw_id)
      return
    end

    @logger.info('Route table not found!')
  end
end
