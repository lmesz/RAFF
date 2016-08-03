require 'aws-sdk'

def create_key()
    puts "Create key ..."
    key_name = 'TestKey'

    client = Aws::EC2::Client.new(region: 'us-east-1')
    key_pair = client.create_key_pair({key_name: key_name})

    # Save it in user's home directory as TestKey.pem
    filename = File.join(Dir.home, key_name + '.pem')
    File.open(filename, 'w') { |file| file.write(key_pair.key_material) }
end

def create_vpc()
    puts "Create vpc ..."
    
    ec2 = Aws::EC2::Resource.new(region: 'us-east-1')

    vpc = ec2.create_vpc({ cidr_block: '10.200.0.0/16' })

    # So we get a public DNS
    vpc.modify_attribute({
      enable_dns_support: { value: true }
    })

    vpc.modify_attribute({
      enable_dns_hostnames: { value: true }
    })

    # Name our VPC
    vpc.create_tags({ tags: [{ key: 'Name', value: 'TestVPC' }]})

    puts vpc.vpc_id
    return vpc.vpc_id
end

def create_subnet(vpc_id)
    ec2 = Aws::EC2::Resource.new(region: 'us-east-1')

    subnet = ec2.create_subnet({
      vpc_id: vpc_id,
      cidr_block: '10.200.10.0/24',
      availability_zone: 'us-east-1c'
    })

    subnet.create_tags({ tags: [{ key: 'Name', value: 'TestSubnet' }]})
    puts subnet.id
    return subnet.id
end

def create_security_group(vpc_id)
    puts "Create security group ..."
    ec2 = Aws::EC2::Resource.new(region: 'us-east-1')

    sg = ec2.create_security_group({
        group_name: 'TestSecurityGroup',
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

def create_instance(sg_id, subnet_id)
    puts "Create instance ..."
    script = 'apt-get update && apt-get install -y ansible'

    encoded_script = Base64.encode64(script)
    
    ec2 = Aws::EC2::Resource.new(region: 'us-east-1')

    instance = ec2.create_instances({
      image_id: 'ami-2d39803a',
      min_count: 1,
      max_count: 1,
      key_name: 'TestKey',
      security_group_ids: [sg_id],
      user_data: encoded_script,
      instance_type: 't2.micro',
      subnet_id: subnet_id,
    })

    # Wait for the instance to be created, running, and passed status checks
    ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance[0].id]})

    # Name the instance 'TestInstance' and give it the Group tag 'TestGroup'
    instance.create_tags({ tags: [{ key: 'Name', value: 'TestInstance' }, { key: 'Group', value: 'TestGroup' }]})

    puts "Instance created"
end

if __FILE__ == $0
    puts "Let's dance ..."
    create_key()
    vpc_id = create_vpc()
    subnet_id = create_subnet(vpc_id)
    sg_id = create_security_group(vpc_id)
    create_instance(sg_id, subnet_id)
    puts "Let's dance ..."
end
