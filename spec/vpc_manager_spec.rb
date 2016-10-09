require 'spec_helper'
require_relative '../lib/vpc_manager'

describe 'VpcManager Initialise' do
  context 'without parameters' do
    it 'all the parameters are default' do
      vpc_manager = VpcManager.new
      expect(vpc_manager.ec2).to be_a Aws::EC2::Resource
      expect(vpc_manager.logger).to be_a Logger
    end
  end

  context 'with parameters' do
    it 'all the parameters used properly' do
      ec2_mock = double('ec2')
      logger_mock = double('logger')
      vpc_manager = VpcManager.new(ec2_mock, logger_mock)

      expect(vpc_manager.ec2).to eq(ec2_mock)
      expect(vpc_manager.logger).to eq(logger_mock)
    end
  end
end

describe 'VpcManager create_vpc_if_not_exists' do
  context 'when called and not found' do
    it 'creates one and return its id' do
      vpc_mock = double('vpc')
      allow(vpc_mock).to receive(:wait_until_exists)
      allow(vpc_mock).to receive(:modify_attribute)
      allow(vpc_mock).to receive(:create_tags)
      allow(vpc_mock).to receive(:vpc_id).and_return(42)

      logger_mock = double('logger')
      allow(logger_mock).to receive(:info)

      ec2_mock = double('ec2')
      allow(ec2_mock).to receive(:create_vpc).and_return(vpc_mock)

      vpc_manager = VpcManager.new(ec2_mock, logger_mock)
      allow(vpc_manager).to receive(:attach_vpc_to_internet_gateway)
      allow(vpc_manager).to receive(:create_route_table_to_internet_gateway)

      expect(vpc_manager.create_vpc_if_not_exists).to eq(42)
    end
  end

  context 'when error happens' do
    it 'throws VpcManagerException' do
      logger_mock = double('logger')
      allow(logger_mock).to receive(:info)

      ec2_mock = double('ec2')
      allow(ec2_mock).to receive(:create_vpc).and_raise("just_raise")

      vpc_manager = VpcManager.new(ec2_mock, logger_mock)
      expect { vpc_manager.create_vpc_if_not_exists }.to raise_error(VpcManagerException)
    end
  end
end
