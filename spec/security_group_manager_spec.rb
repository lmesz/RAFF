require 'spec_helper'
require 'parseconfig'
require 'aws-sdk'

require_relative '../lib/security_group_manager'

describe 'SecurityGroupManager Initialise' do
  context 'when default config not given' do
    it 'uses the one under conf/config' do
      secgroupman = SecurityGroupManager.new

      expect(secgroupman.config).to be_a(ParseConfig)
      expect(secgroupman.config['network-settings']['proto']).to eq('tcp')
      expect(secgroupman.config['network-settings']['port']).to eq('22')
      expect(secgroupman.config['network-settings']['cidr']).to eq('0.0.0.0/0')

    end
  end
end

describe 'SecurityGroupManager create_security_group_if_not_exists' do
  context 'when called and the security group exists' do
    it 'returns the id' do
      ec2mock = double('ec2')
      allow(ec2mock).to receive(:security_groups).and_return([Aws::EC2::SecurityGroup.new(id: 42, stub_responses: true)])

      loggermock = double('logger')
      allow(loggermock).to receive(:info)

      secgroupman = SecurityGroupManager.new(ec2mock, loggermock)
      expect(secgroupman.create_security_group_if_not_exists('TestId')).to eq(42)
    end
  end

  context 'when called and the security group does not exists' do
    it 'creates it and return with the id' do
      sgmock = double('security mock')
      allow(sgmock).to receive(:authorize_egress)
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
