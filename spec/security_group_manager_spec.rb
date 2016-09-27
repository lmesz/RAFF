require 'spec_helper'
require 'aws-sdk'

require_relative '../lib/security_group_manager'

describe 'SecurityGroupManager Initialise' do
  context 'when initialize without params' do
    it 'uses defaults' do
      secgroupman = SecurityGroupManager.new
    end
  end
end
