require 'aws-sdk'
require 'net/ssh'
require 'net/scp'
require 'net/http'

class AwsHandler
  REGION = 'us-east-1'.freeze
  KEY_NAME = 'TestKey'.freeze


  def initialize()
    @ec2 = Aws::EC2::Resource.new(region: REGION)
  end

  def create_key_if_not_exists()

    puts 'Check if key exists ...'
    @ec2.key_pairs().each do |key|
      if key.name == KEY_NAME
        puts "#{KEY_NAME} exists"
        raise "#{KEY_NAME} file doesn't exists local !" unless is_key_downloaded
        return
      end
    end

    puts 'Create key ...'
    create_key()
  end

  def is_key_downloaded()
    return File.file?(File.join(Dir.home, "#{KEY_NAME}.pem"))
  end

  def create_key()
    client = Aws::EC2::Client.new(region: REGION)
    key_pair = client.create_key_pair({key_name: KEY_NAME})
    filename = File.join(Dir.home, "#{KEY_NAME}.pem")
    File.open(filename, 'w') { |file| file.write(key_pair.key_material) }
  end

  def create_vpc_if_not_exists()

    vpc_name = 'TestVPC'

    puts 'Create vpc ...'
    vpc = @ec2.vpcs(filters: [{name: 'tag:Name', values: [vpc_name]}])
    if vpc.first.instance_of? Aws::EC2::Vpc
      return vpc.first.id
    end

    puts 'VPC does not exists create it'

    vpc = @ec2.create_vpc({cidr_block: '10.200.0.0/16'})

    # So we get a public DNS
    vpc.modify_attribute({
                             enable_dns_support: {value: true}
                         })

    vpc.modify_attribute({
                             enable_dns_hostnames: {value: true}
                         })

    # Name our VPC
    vpc.create_tags({tags: [{key: 'Name', value: vpc_name}]})
    igw_id = attach_vpc_to_internet_gateway('vpc-0e670569') #vpc.vpc_id)

    create_route_table_to_internet_gateway(vpc.vpc_id, igw_id)

    return vpc.vpc_id
  end

  def attach_vpc_to_internet_gateway(vpc_id)
    internet_gateway_name = 'TestIGW'

    puts 'Check if Internet Gateway already exists ...'

    igw = @ec2.internet_gateways(filters: [{name: 'tag:Name', values: [internet_gateway_name]}])
    if igw.first.instance_of? Aws::EC2::InternetGateway
      puts 'Internet gateway exists ...'
      return igw.first.id
    end

    puts 'Internet Gateway does not exists, create it ...'

    igw = @ec2.create_internet_gateway

    igw.create_tags({tags: [{key: 'Name', value: internet_gateway_name}]})
    igw.attach_to_vpc(vpc_id: vpc_id)
    return igw.id
  end

  def create_route_table_to_internet_gateway(vpc_id, igw_id)
    puts 'Add the internet gateway to the route tables ...'

    route_table = @ec2.route_tables(filters: [{name: 'vpc-id', values: [vpc_id]}])

    if route_table.first.instance_of? Aws::EC2::RouteTable
      puts 'Route found for the vpc ...'
      route_table.first.create_route({
                                         destination_cidr_block: '0.0.0.0/0',
                                         gateway_id: igw_id
                                     })
      return
    end
    puts "Route table not found!"
  end


  def create_subnet_if_not_exists(vpc_id)
    subnet_name = 'TestSubnet'

    puts 'Check if subnet exists ...'

    subnet = @ec2.subnets(filters: [{name: 'tag:Name', values: [subnet_name]}])
    if subnet.first.instance_of? Aws::EC2::Subnet
      puts 'Subnet exists'
      return subnet.first.id
    end

    puts 'Subnet does not exists create it'

    subnet = @ec2.create_subnet({
                                    vpc_id: vpc_id,
                                    cidr_block: '10.200.10.0/24',
                                    availability_zone: 'us-east-1c'
                                })

    subnet.create_tags({tags: [{key: 'Name', value: subnet_name}]})
    puts subnet.id
    return subnet.id
  end

  def create_security_group_if_not_exists(vpc_id)

    security_group_name = 'TestSecurityGroup'

    puts 'Check if security group exists ...'

    sec_group = @ec2.security_groups(filters: [{name: 'group-name', values: [security_group_name]}])

    if sec_group.first.instance_of? Aws::EC2::SecurityGroup
      puts 'Security group exists'
      return sec_group.first.id
    end

    puts 'Security group does not exists, create...'

    sg = @ec2.create_security_group({
                                        group_name: security_group_name,
                                        description: 'Security group for TestInstance',
                                        vpc_id: vpc_id
                                    })

    sg.authorize_egress({
                            ip_permissions: [
                                {
                                    ip_protocol: 'tcp',
                                    from_port: 22,
                                    to_port: 22,
                                    ip_ranges: [{
                                                    cidr_ip: '0.0.0.0/0'
                                                }]
                                },
                                {
                                    ip_protocol: 'tcp',
                                    from_port: 80,
                                    to_port: 80,
                                    ip_ranges: [{
                                                    cidr_ip: '0.0.0.0/0'
                                                }]
                                }
                            ]
                        })

    sg.authorize_ingress({
                             ip_permissions: [
                                 {
                                     ip_protocol: 'tcp',
                                     from_port: 22,
                                     to_port: 22,
                                     ip_ranges: [{
                                                     cidr_ip: '0.0.0.0/0'
                                                 }]
                                 },
                                 {
                                     ip_protocol: 'tcp',
                                     from_port: 80,
                                     to_port: 80,
                                     ip_ranges: [{
                                                     cidr_ip: '0.0.0.0/0'
                                                 }]
                                 }
                             ]
                         })

    puts sg.id
    return sg.id
  end

  def create_instance(instance_name, sg_id, subnet_id)
    puts 'Check if instance exists'

    instance = @ec2.instances(filters: [{name: 'tag:Name', values: [instance_name]}])
    if instance.first.instance_of? Aws::EC2::Instance
      puts "Instance already exists. Public DNS adress is #{instance.first.public_dns_name}"
      return
    end

    puts 'Instance does not exists, Create instance ...'

    user_data = File.read(File.join(File.dirname(__FILE__), '..', 'conf', 'user.data'))

    instance = @ec2.create_instances({
                                         image_id: 'ami-2d39803a',
                                         min_count: 1,
                                         max_count: 1,
                                         user_data: Base64.encode64(user_data),
                                         key_name: KEY_NAME,
                                         instance_type: 't2.micro',
                                         network_interfaces: [{
                                                                  device_index: 0,
                                                                  subnet_id: subnet_id,
                                                                  groups: [sg_id],
                                                                  associate_public_ip_address: true
                                                              }]
                                     })

    # Wait for the instance to be created, running, and passed status checks
    @ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance[0].id]})

    # Name the instance 'TestInstance' and give it the Group tag 'TestGroup'
    instance.batch_create_tags({tags: [{key: 'Name', value: instance_name}, {key: 'Group', value: 'TestGroup'}]})

    inst = @ec2.instance(instance[0].id)

    puts "The created instance public DNS address is: #{inst.public_dns_name}"
  end

  def status(instance_name)
    instance = @ec2.instances(filters: [{name: 'tag:Name', values: [instance_name]}])
    if instance.first.instance_of? Aws::EC2::Instance
      puts "Instance already exists. Public DNS adress is #{instance.first.public_dns_name}"
      begin
        uri = URI("http://#{instance.first.public_dns_name}/")
        res = Net::HTTP.get_response(uri)

        if res.body.include? "drupal"
          puts "Drupal is available at http://#{instance.first.public_dns_name}"
        else
          puts 'Drupal is not available, the host is listen on port 80, but does not serve drupal site!'
        end
      rescue Timeout::Error, SocketError
        puts 'Drupal is not available, because nothing listen at port 80!'
      end
    end
  end

end
