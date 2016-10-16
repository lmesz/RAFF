require 'spec_helper'
require 'aws-sdk'
require 'logger'

require_relative '../lib/key_manager'

describe 'KeyManager ImportKey' do
  before :each do
    @ec2_mock = double('Ec2')
    @logger_mock = double('Logger')
    allow(@logger_mock).to receive(:info)
    @keymanager = KeyManager.new(@ec2_mock, @logger_mock)
  end

  context 'when key exists' do
    it 'import happenes properly' do
      allow(@ec2_mock).to receive(:import_key_pair)
      expect(@ec2_mock).to receive(:import_key_pair)
      @keymanager.import_key_if_not_exists
    end
  end
end
