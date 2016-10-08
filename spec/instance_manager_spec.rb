require 'spec_helper'
require 'aws-sdk'

require_relative '../lib/instance_manager'

describe 'InstanceManager status' do
  context 'when called with an unexist instance name' do
    it 'InstanceManagerException thrown' do
      instance_manager = InstanceManager.new
      expect { instance_manager.status('instanceDoesNotExists') }.to raise_exception(InstanceManagerException, 'Instance does not exists!')
    end
  end

  context 'when called and the instance exists and drupal is available' do
    it 'does not return false' do
      inst = Aws::EC2::Instance.new(id: '42', stub_responses: true)
      allow(inst).to receive(:public_dns_name).and_return('just.a.dns.name')

      ec2mock = double('ec2')
      allow(ec2mock).to receive(:instances).and_return([inst])

      loggermock = double('logger')
      allow(loggermock).to receive(:info)
      expect(loggermock).to receive(:info).with('Drupal is available at'\
                                                ' http://just.a.dns.name')

      respmock = double('resp')
      allow(respmock).to receive(:body).and_return('drupal')

      nethttpmock = double('net_http')
      allow(nethttpmock).to receive(:get_response).and_return(respmock)

      instance_manager = InstanceManager.new(ec2mock, loggermock, nethttpmock)
      instance_manager.status('existentInstance')
    end
  end
end

describe 'InstanceManager create_instance' do
  before (:each) do
    @loggermock = double('logger')
    allow(@loggermock).to receive(:info)
    @ec2mock = double('ec2')
  end

  context 'when called and instance does not exists' do
    it 'create a new instance and returns the id' do
      instmock = double('inst')
      allow(instmock).to receive(:wait_until_running)
      allow(instmock).to receive(:id)

      instancesmock = double('instances')
      allow(instancesmock).to receive(:first).and_return(instmock)
      allow(instancesmock).to receive(:batch_create_tags)

      allow(@ec2mock).to receive(:instances).and_return([])
      allow(@ec2mock).to receive(:create_instances).and_return(instancesmock)
      allow(@ec2mock).to receive(:instance)
      # rubocop: disable Metrics/LineLength
      expect(@ec2mock).to receive(:create_instances).with(image_id: 'ami-2d39803a',
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

      instance_manager = InstanceManager.new(@ec2mock, @loggermock)
      allow(instance_manager).to receive(:user_data).and_return('dummyUserData')
      instance_manager.create_instance_if_not_exists('notExistentInstance',
                                                     'dummySecurityGroupId',
                                                     'dummySubnetId')
    end
  end
end
