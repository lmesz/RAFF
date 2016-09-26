require 'spec_helper'
require 'aws-sdk'
require 'logger'

require_relative '../lib/subnet_manager'

describe 'SubnetManager Initialise' do
  context 'when initialized without parameters' do
    it 'use defaults' do
      subnetmanager = SubnetManager.new
      expect(subnetmanager.ec2).to be_a Aws::EC2::Resource
      expect(subnetmanager.logger).to be_a Logger
    end
  end

  context 'when initialized with parameters' do
    it 'it used on them properly' do
      ec2mock = double("ec2")
      loggermock = double("logger")
      subnetmanager = SubnetManager.new(ec2mock, loggermock)
      expect(subnetmanager.ec2).to eq(ec2mock)
      expect(subnetmanager.logger).to eq(loggermock)
    end
  end
end

describe 'SubnetManager create_subnet_if_not_exists' do
  context 'when subnet found' do
    it 'return with its id' do
      expectedid = "42"
      subnet = Aws::EC2::Subnet.new(:id => expectedid, :stub_responses => true)
      ec2mock = double("ec2")
      allow(ec2mock).to receive(:subnets).and_return([subnet])
      expect(ec2mock).to receive(:subnets).with(filters: [{ name: 'tag:Name', values: ['TestSubnet'] }])
      loggermock = double("logger")
      allow(loggermock).to receive(:info)

      subnetmanager = SubnetManager.new(ec2mock, loggermock)
      expect(subnetmanager.create_subnet_if_not_exists("fakevpcid")).to eq(expectedid)
    end
  end
  context 'when subnet not found' do
    it 'creates it with proper parameters and returns with the id' do
      expectedid = "42"
      subnetmock = double("subnet")
      allow(subnetmock).to receive(:wait_until)
      allow(subnetmock).to receive(:create_tags)
      allow(subnetmock).to receive(:id).and_return(expectedid)

      ec2mock = double("ec2")
      allow(ec2mock).to receive(:subnets).and_return([])
      allow(ec2mock).to receive(:create_subnet).and_return(subnetmock)
      expect(ec2mock).to receive(:subnets).with(filters: [{ name: 'tag:Name', values: ['TestSubnet'] }])

      loggermock = double("logger")
      allow(loggermock).to receive(:info)

      subnetmanager = SubnetManager.new(ec2mock, loggermock)
      expect(subnetmanager.create_subnet_if_not_exists("fakevpcid")).to eq(expectedid)
    end
  end
end
