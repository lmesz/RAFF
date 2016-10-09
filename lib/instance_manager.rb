require_relative 'aws_base'
require 'net/http'

class InstanceManager < AwsBase
  def initialize(ec2 = Aws::EC2::Resource.new(region: 'us-east-1',
                                              stub_responses: true),
                 logger = Logger.new(STDOUT),
                 net_http = Net::HTTP,
                 key_name = 'TestKey')
    super(ec2, logger)
    @net_http = net_http
    @key_name = key_name
  end

  # rubocop: disable Metrics/MethodLength
  def status(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                          values: [instance_name] }])
    if instance.first.instance_of? Aws::EC2::Instance
      begin
        inst = instance.first
        @logger.info('Instance already exists. Public DNS adress'\
                     " is #{inst.public_dns_name}")
        res = @net_http.get_response(inst.public_dns_name)

        if res.body.include? 'drupal'
          @logger.info("Drupal is available at http://#{inst.public_dns_name}")
          return
        end
        raise InstanceManagerException, 'Drupal is not available, the host is'\
                                        ' listen on port 80, but does not'\
                                        ' serve drupal site!'

      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
        raise InstanceManagerException, 'Drupal is not available, because'\
                                        ' nothing listen at port 80!'
      end
    end
    raise InstanceManagerException, 'Instance does not exists!'
  end

  def create_instance_if_not_exists(instance_name, sg_id, subnet_id)
    inst = create_instance(instance_name, sg_id, subnet_id)
    @logger.info('The created instance public DNS address is:'\
                 " #{inst.public_dns_name}")
    wait_for_drupal_to_be_installed(instance_name)
  rescue
    raise InstanceManagerException, 'Something went wrong during initialization'
  end

  def create_instance(instance_name, sg_id, subnet_id)
    instance = @ec2.create_instances(image_id: 'ami-2d39803a',
                                     min_count: 1,
                                     max_count: 1,
                                     user_data: Base64.encode64(user_data),
                                     key_name: @key_name,
                                     instance_type: 't2.micro',
                                     network_interfaces: [{
                                       device_index: 0,
                                       subnet_id: subnet_id,
                                       groups: [sg_id],
                                       associate_public_ip_address: true
                                     }])
    inst = instance.first
    inst.wait_until_running

    instance.batch_create_tags(tags: [{ key: 'Name',
                                        value: instance_name },
                                      { key: 'Group',
                                        value: 'TestGroup' }])
    @ec2.instance(inst.id)
  end
  # rubocop: enable Metrics/MethodLength

  def user_data
    File.read(File.join(File.dirname(__FILE__),
                        '..',
                        'conf',
                        'user.data'))
  end

  def wait_for_drupal_to_be_installed(instance_name)
    timeout = 600
    step = 5

    until status(instance_name)
      raise InstanceManagerException if timeout.zero?
      @logger.info("Drupal is not installed, wait #{step} more sec")
      sleep(step)
      timeout -= step
    end
  end

  def stop_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                        values: [instance_name] }])
    instance.first.stop
    instance.first.wait_until_stopped
  rescue Aws::EC2::Errors::IncorrectInstanceState, NoMethodError
    raise InstanceManagerException, 'Instance can not stopped because of'\
                                    ' it\'s state or does not exists.'
  end

  def terminate_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                          values: [instance_name] }])
    instance.first.terminate
    instance.first.wait_until_terminated
  rescue
    raise InstanceManagerException, 'Something went wrong during termination!'
  end
end

class InstanceManagerException < RuntimeError
end
