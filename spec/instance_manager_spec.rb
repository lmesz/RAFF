require 'spec_helper'
require 'aws-sdk'

require_relative '../lib/instance_manager'

describe 'InstanceManager status' do
  context 'when status called with an unexist instance name' do
    it 'return false' do
      instance_manager = InstanceManager.new
      expect(instance_manager.status('notExistInstance')).to be false
    end
  end
end
