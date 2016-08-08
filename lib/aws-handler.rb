require 'aws-sdk'
require 'net/ssh'
require 'net/scp'

class AwsHandler
    REGION = 'us-east-1'
    KEY_NAME = 'TestKey'


    def initialize()
        @ec2 = Aws::EC2::Resource.new(region: REGION)
    end
    
    def create_key_if_not_exists()

        puts "Check if key exists ..."
        @ec2.key_pairs().each do |key|
            if key.name == KEY_NAME
                puts "#{KEY_NAME} exists"
                if not is_key_downloaded()
                    raise "#{KEY_NAME} file doesn't exists local !"
                end
                return
            end
        end

        puts "Create key ..."
        create_key()
    end

    def is_key_downloaded()
        return File.file?(Dir.home + '/' + KEY_NAME + '.pem')
    end

    def create_key()
        client = Aws::EC2::Client.new(region: REGION)
        key_pair = client.create_key_pair({key_name: KEY_NAME})
        filename = File.join(Dir.home, KEY_NAME + '.pem')
        File.open(filename, 'w') { |file| file.write(key_pair.key_material) }
    end

    def create_vpc_if_not_exists()

        vpc_name = "TestVPC"

        puts "Create vpc ..."
        
        @ec2.vpcs.each() do |vpc|
            vpc.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == vpc_name)
                    puts "VPC exists" #assume it is attached to an IGW
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
        vpc.create_tags({ tags: [{ key: 'Name', value: vpc_name }]})

        igw_id = attach_vpc_to_internet_gateway(vpc.vpc_id)

        create_route_table_to_internet_gateway(vpc.vpc_id, igw_id)

        return vpc.vpc_id
    end

    def attach_vpc_to_internet_gateway(vpc_id)

        internet_gateway_name = "TestIGW"

        puts "Check if Internet Gateway already exists ..."
        @ec2.internet_gateways.each() do |igw|
            igw.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == internet_gateway_name)
                    puts "Internet Gateway exists..." #assume if it exists vpc already attached
                    return
                end
            end
        end

        puts "Internet Gateway does not exists, create it ..."
        igw = @ec2.create_internet_gateway

        igw.create_tags({ tags: [{ key: 'Name', value: internet_gateway_name }]})
        igw.attach_to_vpc(vpc_id: vpc_id)
        return igw.id
    end

    def create_route_table_to_internet_gateway(vpc_id, igw_id)
        puts "Add the internet gateway to the route tables ..."
        
        @ec2.route_tables.each() do |route_table|
            if route_table.vpc_id == vpc_id
                puts "Route found for the vpc ..."
                route_table.create_route({
                  destination_cidr_block: '0.0.0.0/0',
                  gateway_id: igw_id
                })
                return
            end
        end
        puts "No route table for the given vpc :("
    end


    def create_subnet_if_not_exists(vpc_id)
        subnet_name = "TestSubnet"

        puts "Check if subnet exists ..."

        @ec2.subnets.each() do |subnet|
            subnet.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == subnet_name)
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

        subnet.create_tags({ tags: [{ key: 'Name', value: subnet_name }]})
        puts subnet.id
        return subnet.id
    end

    def create_security_group_if_not_exists(vpc_id)

        security_group_name = "TestSecurityGroup"

        puts "Check if security group exists ..."

        @ec2.security_groups.each() do |sec_group|
            if sec_group.group_name == security_group_name
                puts "Security group exists"
                return sec_group.id
            end
        end

        puts "Security group does not exists, let's create..."

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

    def install_ansible_lamp_stack_and_drupal()
        Net::SSH.start(instance.public_dns_name, 'ubuntu', :keys => [Dir.home + '/' + KEY_NAME + '.pem']) do |ssh|
            output = ssh.exec!("sudo apt-get update && sudo apt-get install -y software-properties-common && sudo apt-add-repository ppa:ansible/ansible -y && sudo apt-get update && sudo apt-get install -y ansible")
            puts output
            output = ssh.exec!("ansible --version")
            puts output
            output = ssh.exec!("sudo add-apt-repository ppa:ondrej/php -y && sudo apt-get update")
            puts output
            output = ssh.exec!("sudo apt-get install -y libapache2-mod-php7.0")
            puts output
            output = ssh.scp.upload!(File.dirname(__FILE__) + "/hosts.yml", "/tmp")
            puts output
            output = ssh.exec!("sudo ansible-galaxy install geerlingguy.drupal")
            puts output
            output = ssh.scp.upload!(File.dirname(__FILE__) + "/site.yml", "/tmp")
            puts output
            output = ssh.exec!("ansible-playbook -i /tmp/hosts.yml /tmp/site.yml")
            puts output
            output = ssh.exec!("sudo find /etc/apache2/sites-enabled -type l -delete && sudo apache2ctl restart")
            puts output
    end

    def create_instance(instance_name, sg_id, subnet_id)

        puts "Check if instance exists"

        @ec2.instances.each() do |instance|
            instance.tags.each() do |tag|
                if (tag.key == "Name" and tag.value == instance_name)
                    puts "Instance already exists. Public DNS adress is #{instance.public_dns_name}"
                    install_ansible_lamp_stack_and_drupal()
                    end
                    return
                end
            end
        end

        puts "Instance does not exists, Create instance ..."

        instance = @ec2.create_instances({
          image_id: 'ami-2d39803a',
          min_count: 1,
          max_count: 1,
          key_name: KEY_NAME,
          instance_type: 't2.micro',
          network_interfaces: [{
            device_index: 0,
            subnet_id: subnet_id,
            groups: [sg_id],
            associate_public_ip_address: true
          }],
        })

        # Wait for the instance to be created, running, and passed status checks
        @ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance[0].id]})

        # Name the instance 'TestInstance' and give it the Group tag 'TestGroup'
        instance.batch_create_tags({ tags: [{ key: 'Name', value: instance_name }, { key: 'Group', value: 'TestGroup' }]})

        install_ansible_lamp_stack_and_drupal()
        puts "Instance created and drupal is available at: http://#{instance.public_dns_name}"
    end
end
