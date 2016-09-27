require 'aws-sdk'
require 'aws_base'

class SecurityGroupManager < AwsBase
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
                                    description: 'Security group for TestInstance',
                                    vpc_id: vpc_id)

    sg.authorize_egress(ip_permissions: [
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
                        ])

    sg.authorize_ingress(ip_permissions: [
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
                         ])
    sg.id
  end
end
