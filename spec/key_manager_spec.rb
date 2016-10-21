require 'spec_helper'
require 'aws-sdk'
require 'logger'

require_relative '../lib/key_manager'

describe 'KeyManager ImportKey' do
  before :each do
    @ec2_mock = double('Ec2')
    logger_mock = double('Logger')
    allow(logger_mock).to receive(:info)
    File.open('/tmp/TestKeyPub.key', 'w') {}
    config='config.test'
    @keymanager = KeyManager.new(@ec2_mock, logger_mock, config)
  end

  context 'when key exists' do
    it 'import happenes properly' do
      allow(@ec2_mock).to receive(:import_key_pair)
      expect(@ec2_mock).to receive(:import_key_pair)
      @keymanager.import_key_if_not_exists
      expect(@keymanager.config['key']['key_path']).to eq('/tmp/')
    end
  end
end
