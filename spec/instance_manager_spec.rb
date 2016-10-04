require 'spec_helper'
require 'aws-sdk'

require_relative '../lib/instance_manager'

describe 'InstanceManager status' do
  context 'when status called with an unexist instance name' do
    it 'return false' do
      instance_manager = InstanceManager.new
      expect(instance_manager.status('notExistentInstance')).to be false
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
      expect(loggermock).to receive(:info).with('Drupal is available at http://just.a.dns.name')

      respmock = double('resp')
      allow(respmock).to receive(:body).and_return('drupal')

      nethttpmock = double('net_http')
      allow(nethttpmock).to receive(:get_response).and_return(respmock)

      instance_manager = InstanceManager.new(ec2mock, loggermock, nethttpmock)
      instance_manager.status('existentInstance')
    end
  end
end
