require 'aws-sdk'
require 'logger'

require_relative '../lib/key_manager'

describe 'Initialise' do
  context 'when key preferencies not given and environment variables are not set' do
    it 'exception throwing' do
      ec2_mock = class_double('Ec2')
      logger_mock = class_double('Logger')
      expect{KeyManager.new(ec2_mock, logger_mock)}.to raise_exception(KeyManagerException,
          'The "key_path" and "key_name" environment variable need to be set if not given during initialization')
    end
  end
  context 'when initialized without parameters' do
    it 'all the parameters are default' do
      ENV['key_path'] = '/tmp'
      ENV['key_name'] = 'TestKey'
      keymanager = KeyManager.new
      expect(keymanager.ec2).to be_a Aws::EC2::Resource
      expect(keymanager.logger).to be_a Logger
      expect(keymanager.key_path).to eq('/tmp')
      expect(keymanager.key_name).to eq('TestKey')
      ENV['key_path'] = nil
      ENV['key_name'] = nil
    end
  end
  context 'when initialized with custom parameters' do
    it 'uses them' do
      ec2_mock = class_double('Ec2')
      logger_mock = class_double('Logger')
      keymanager = KeyManager.new(ec2_mock, logger_mock, '/tmp', 'CustomKey')
      expect(keymanager.ec2).to eq(ec2_mock)
      expect(keymanager.logger).to eq(logger_mock)
      expect(keymanager.key_path).to eq('/tmp')
      expect(keymanager.key_name).to eq('CustomKey')
    end
  end
end

describe 'ImportKey' do
  before :each do
    @ec2_mock = class_double('Ec2')
    @logger_mock = class_double('Logger')
    @key_path = File.dirname(__FILE__)
    @key_name = 'Custom_key'
    @keymanager = KeyManager.new(@ec2_mock, @logger_mock, @key_path, @key_name)
  end
  context 'when key not exists' do
    it 'throws KeyManagerException' do
      expect{@keymanager.import_key}.to raise_exception(KeyManagerException)
    end
  end
  context 'when key exists' do
    it 'import happenes properly' do
      file_with_path = File.join(@key_path, @key_name)
      File.open(file_with_path, 'w') {}
      allow(@ec2_mock).to receive(:import_key_pair)
      expect(@ec2_mock).to receive(:import_key_pair)
      @keymanager.import_key
      File.unlink(file_with_path)
    end
  end
end
