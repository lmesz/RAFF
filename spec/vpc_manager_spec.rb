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
