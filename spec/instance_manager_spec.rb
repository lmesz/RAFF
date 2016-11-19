require 'spec_helper'
require 'aws-sdk'

require_relative '../lib/instance_manager'

describe 'InstanceManager status' do
  before :each do
    @ec2_mock = double('ec2')
    @logger_mock = double('logger')
  end

  context 'when called and the instance exists and drupal is available' do
    it 'does not return false' do
      inst = Aws::EC2::Instance.new(id: '42', stub_responses: true)
      allow(inst).to receive(:public_dns_name).and_return('just.a.dns.name')

      allow(@ec2_mock).to receive(:instances).and_return([inst])

      allow(@logger_mock).to receive(:info)
      expect(@logger_mock).to receive(:info).with('Drupal is available at'\
                                                ' http://just.a.dns.name')

      respmock = double('resp')
      allow(respmock).to receive(:body).and_return('drupal')

      nethttpmock = double('net_http')
      allow(nethttpmock).to receive(:get_response).and_return(respmock)

      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock, nethttpmock)
      instance_manager.status('existentInstance')
    end
  end

  context 'when called and instance does not exists' do
    it 'throws InstanceManagerException' do
      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(@ec2_mock).to receive(:instances).and_raise('dummy_error')
      expect do
        instance_manager.status('dummy_instance')
      end.to raise_error(InstanceManagerException)
    end
  end

  context 'when called and instance exists, socket exception thrown' do
    it 'the reason is in the exception' do
      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(@ec2_mock).to receive(:instances).and_raise(Errno::ECONNREFUSED)
      expect do
        instance_manager.status('dummy_instance')
      end.to raise_error(InstanceManagerException, 'Drupal is not available, '\
                       'because nothing listen on port 80!')
    end
  end
end

describe 'InstanceManager create_instance_if_not_exists' do
  before :each do
    @logger_mock = double('logger')
    allow(@logger_mock).to receive(:info)
    @ec2_mock = double('ec2')
  end

  context 'when called and instance does not exists' do
    it 'creates a new instance and returns the id' do
      inst_mock = double('inst')
      allow(inst_mock).to receive(:wait_until_running)
      allow(inst_mock).to receive(:id)
      allow(inst_mock).to receive(:public_dns_name)

      instancesmock = double('instances')
      allow(instancesmock).to receive(:first).and_return(inst_mock)
      allow(instancesmock).to receive(:batch_create_tags)

      allow(@ec2_mock).to receive(:instances).and_return([])
      allow(@ec2_mock).to receive(:create_instances).and_return(instancesmock)
      allow(@ec2_mock).to receive(:instance).and_return(inst_mock)
      # rubocop: disable Metrics/LineLength
      expect(@ec2_mock).to receive(:create_instances).with(image_id: 'ami-2d39803a',
                                                           min_count: 1,
                                                           max_count: 1,
                                                           user_data: Base64.encode64('dummyUserData'),
                                                           key_name: 'TestKey',
                                                           instance_type: 't2.micro',
                                                           network_interfaces: [{
                                                             device_index: 0,
                                                             subnet_id: 'dummySubnetId',
                                                             groups: ['dummySecurityGroupId'],
                                                             associate_public_ip_address: true
                                                           }])
      # rubocop: enable Metrics/LineLength

      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(instance_manager).to receive(:user_data).and_return('dummyUserData')
      allow(instance_manager).to receive(:wait_for_drupal_to_be_installed)
      instance_manager.create_instance_if_not_exists('notExistentInstance',
                                                     'dummySecurityGroupId',
                                                     'dummySubnetId')
    end
  end

  context 'when something goes wrong during creation' do
    it 'throws InstanceManagerException' do
      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(instance_manager).to receive(:create_instance)
        .and_raise('dummy_error')
      expect do
        instance_manager.create_instance_if_not_exists('instance_name',
                                                       'dummy_security_group',
                                                       'dummy_subnet_id')
      end.to raise_error(InstanceManagerException)
    end
  end
end

describe 'InstanceManager stop_instance' do
  before :each do
    @logger_mock = double('logger')
    allow(@logger_mock).to receive(:info)
    @ec2_mock = double('ec2')
  end

  context 'when called, all the necessary function called' do
    it 'stop the instance properly' do
      inst_mock = double('instance')
      allow(inst_mock).to receive(:stop)
      expect(inst_mock).to receive(:stop).once
      allow(inst_mock).to receive(:wait_until_stopped)
      expect(inst_mock).to receive(:wait_until_stopped).once
      allow(@ec2_mock).to receive(:instances).and_return([inst_mock])

      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      instance_manager.stop_instance('just_an_instance_name')
    end
  end

  context 'when called, but the instance does not exists' do
    it 'InstanceManagerException thrown' do
      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(@ec2_mock).to receive(:instances).and_raise(NoMethodError)
      expect do
        instance_manager.stop_instance('error_trigger_instance')
      end.to raise_error(InstanceManagerException)
    end
  end
end

describe 'InstanceManager terminate_instance' do
  before :each do
    @logger_mock = double('logger')
    allow(@logger_mock).to receive(:info)
    @ec2_mock = double('ec2')
  end

  context 'when called' do
    it 'terminates properly' do
      inst_mock = double('instance')
      allow(inst_mock).to receive(:terminate)
      expect(inst_mock).to receive(:terminate).once
      allow(inst_mock).to receive(:wait_until_terminated)
      expect(inst_mock).to receive(:wait_until_terminated).once
      allow(@ec2_mock).to receive(:instances).and_return([inst_mock])

      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      instance_manager.terminate_instance('just_an_instance_name')
    end
  end

  context 'when called, but the instance does not exists' do
    it 'InstanceManagerException thrown' do
      instance_manager = InstanceManager.new(@ec2_mock, @logger_mock)
      allow(@ec2_mock).to receive(:instances).and_raise(NoMethodError)
      expect do
        instance_manager.terminate_instance('error_trigger_instance')
      end.to raise_error(InstanceManagerException)
    end
  end
end

describe 'InstanceManager wait_for_drupal_to_be_installed' do
  before :each do
    @logger_mock = double('logger')
    allow(@logger_mock).to receive(:info)
    @ec2_mock = double('ec2')
  end

  context 'when available' do
    it 'status called only once' do
      net_http_mock = double('net_http')

      instance_manager = InstanceManager.new(@ec2_mock,
                                             @logger_mock,
                                             net_http_mock,
                                             config = 'config.test')

      count = 0
      allow(instance_manager).to receive(:status) do
        count += 1
        raise InstanceManagerException, 'negyvenketto' if count == 1
      end
      expect(instance_manager).to receive(:status).twice

      instance_manager.wait_for_drupal_to_be_installed('just_an_instance')
      expect(instance_manager.config['instance']['public_ip']).to eq('false')
    end
  end
end
