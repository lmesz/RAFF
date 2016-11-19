require 'spec_helper'
require 'parseconfig'
require 'aws-sdk'

require_relative '../lib/security_group_manager'

describe 'SecurityGroupManager Initialise' do
  context 'when default config not given' do
    it 'uses the one under conf/config' do
      secgroupman = SecurityGroupManager.new

      expect(secgroupman.config).to be_a(ParseConfig)
      expect(secgroupman.config['security group']['proto']).to eq('tcp')
      expect(secgroupman.config['security group']['port']).to eq('22,80')
      expect(secgroupman.config['security group']['cidr']).to eq('0.0.0.0/0')
    end
  end
end

describe 'SecurityGroupManager create_security_group_if_not_exists' do
  context 'when called and the security group does not exists' do
    it 'creates it and return with the id' do
      sgmock = double('security mock')
      allow(sgmock).to receive(:authorize_egress).with(ip_permissions: [
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
      allow(sgmock).to receive(:authorize_ingress)
      allow(sgmock).to receive(:id).and_return(42)

      ec2mock = double('ec2')
      allow(ec2mock).to receive(:security_groups).and_return([])
      allow(ec2mock).to receive(:create_security_group).and_return(sgmock)

      loggermock = double('logger')
      allow(loggermock).to receive(:info)

      secgroupman = SecurityGroupManager.new(ec2mock, loggermock)
      expect(secgroupman.create_security_group_if_not_exists('TestId')).to eq(42)
    end
  end
end
