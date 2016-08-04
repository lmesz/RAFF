require 'aws-sdk'

class AwsHandler
    REGION = 'us-east-1'

    def initialize()
        @ec2 = Aws::EC2::Resource.new(region: REGION)
    end
    
    def create_key_if_not_exists()

        key_name = 'TestKey'

        puts "Check if key exists ..."
        @ec2.key_pairs().each do |key|
            if key.name == key_name
                puts "#{key_name} exists"
                if not is_key_downloaded(key_name)
                    puts "Download #{key_name} file"
                    download_key(key_name)
                end
                return
            end
        end

        puts "Create key ..."

        create_key(key_name)
        download_key(key_name)
    end

    def is_key_downloaded(key_name)
        return File.file?(Dir.home + '/' + key_name + '.pem')
    end

    def download_key(key_name)
        filename = File.join(Dir.home, key_name + '.pem')
        File.open(filename, 'w') { |file| file.write(key_pair.key_material) }
    end

    def create_key(key_name)
        client = Aws::EC2::Client.new(region: REGION)
        client.create_key_pair({key_name: key_name})
    end

    def create_vpc_if_not_exists()
        puts "Create vpc ..."
        
        @ec2.vpcs.each() do |vpc|
            vpc.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == "TestVPC")
                    puts "VPC exists"
                    return vpc.id
                end
            end
        end

        puts "VPC does not exists create it"

        vpc = @ec2.create_vpc({ cidr_block: '10.200.0.0/16' })

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

    def create_subnet_if_not_exists(vpc_id)
        puts "Check if subnet exists ..."

        @ec2.subnets.each() do |subnet|
            subnet.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == "TestSubnet")
                    puts "Subnet exists"
                    return subnet.id
                end
            end
        end

        puts "Subnet does not exists create it"

        subnet = @ec2.create_subnet({
          vpc_id: vpc_id,
          cidr_block: '10.200.10.0/24',
          availability_zone: 'us-east-1c'
        })

        subnet.create_tags({ tags: [{ key: 'Name', value: 'TestSubnet' }]})
        puts subnet.id
        return subnet.id
    end

    def create_security_group_if_not_exists(vpc_id)
        puts "Check if security group exists ..."

        @ec2.security_groups.each() do |sec_group|
            if sec_group.group_name == "TestSecurityGroup"
                puts "Security group exists"
                return sec_group.id
            end
        end

        puts "Security group does not exists, let's create..."

        sg = @ec2.create_security_group({
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
        puts "Check if instance exists"

        @ec2.instances.each() do |instance|
            instance.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == "TestInstance")
                    puts "Instance already exists"
                    return
                end
            end
        end

        puts "Instance does not exists, Create instance ..."

        script = 'apt-get update && apt-get install -y ansible'

        encoded_script = Base64.encode64(script)
        
        instance = @ec2.create_instances({
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
        @ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance[0].id]})

        # Name the instance 'TestInstance' and give it the Group tag 'TestGroup'
        instance.create_tags({ tags: [{ key: 'Name', value: 'TestInstance' }, { key: 'Group', value: 'TestGroup' }]})

        puts "Instance created"
    end
end
