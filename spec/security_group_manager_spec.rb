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
