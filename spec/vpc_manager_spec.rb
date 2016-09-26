require 'spec_helper'
require_relative '../lib/vpc_manager'

describe 'VpcManager Initialise' do
  context 'without parameters' do
    it 'all the parameters are default' do
      vpcmanager = VpcManager.new

      expect(vpcmanager.ec2).to be_a Aws::EC2::Resource
      expect(vpcmanager.logger).to be_a Logger
    end
  end

  context 'with parameters' do
    it 'all the parameters used properly' do
      ec2mock = double('ec2')
      loggermock = double('logger')
      vpcmanager = VpcManager.new(ec2mock, loggermock)

      expect(vpcmanager.ec2).to eq(ec2mock)
      expect(vpcmanager.logger).to eq(loggermock)
    end
  end
end

describe 'VpcManager create_vpc_if_not_exists' do
  context 'when called and not found' do
    it 'creates one and return its id' do
      vpcmock = double('vpc')
      allow(vpcmock).to receive(:wait_until_exists)
      allow(vpcmock).to receive(:modify_attribute)
      allow(vpcmock).to receive(:create_tags)
      allow(vpcmock).to receive(:vpc_id).and_return(42)

      loggermock = double('logger')
      allow(loggermock).to receive(:info)

      ec2mock = double('ec2')
      allow(ec2mock).to receive(:vpcs).and_return(['asd'])
      allow(ec2mock).to receive(:create_vpc).and_return(vpcmock)

      vpcmanager = VpcManager.new(ec2mock, loggermock)
      allow(vpcmanager).to receive(:attach_vpc_to_internet_gateway)
      allow(vpcmanager).to receive(:create_route_table_to_internet_gateway)

      expect(ec2mock).to receive(:vpcs)
      expect(vpcmanager.create_vpc_if_not_exists).to eq(42)
    end
  end

  context 'when called and found' do
    it 'returns the id' do
      expectedvpcid = "42"
      loggermock = double('logger')
      allow(loggermock).to receive(:info)

      aws_vpc = Aws::EC2::Vpc.new(:id => "42", :region => 'us-east-1', :stub_responses => true)

      allow(aws_vpc).to receive(:id).and_return(expectedvpcid)

      ec2mock = double('ec2')
      allow(ec2mock).to receive(:vpcs).and_return([aws_vpc])

      vpcmanager = VpcManager.new(ec2mock, loggermock)
      expect(vpcmanager.create_vpc_if_not_exists).to eq(expectedvpcid)
    end
  end
end
