require_relative 'aws_base'
require 'net/http'

class InstanceManager < AwsBase
  def initialize(ec2 = Aws::EC2::Resource.new(region: 'us-east-1'),
                 logger = Logger.new(STDOUT),
                 net_http = Net::HTTP,
                 config = 'config')
    super(ec2, logger, config)
    @net_http = net_http
  end

  # rubocop: disable Metrics/MethodLength
  def status(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                          values: [instance_name] }])
    inst = instance.first
    if @net_http.get_response(URI.parse("http://#{inst.public_dns_name}")).body.include? 'drupal'
      @logger.info("Drupal is available at http://#{inst.public_dns_name}")
      return true
    end
    raise InstanceManagerException, 'Drupal is not available, the host is'\
                                    ' listening on port 80, but does not'\
                                    ' serve drupal site!'

  rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
    raise InstanceManagerException, 'Drupal is not available, because'\
                                    ' nothing listen on port 80!'
  rescue
    raise InstanceManagerException, 'Instance does not exists!'\
  end

  def create_instance_if_not_exists(instance_name, sg_id, subnet_id)
    inst = create_instance(instance_name, sg_id, subnet_id)
    @logger.info('The created instance public DNS address is:'\
                 " #{inst.public_dns_name}")
    wait_for_drupal_to_be_installed(instance_name)
  rescue
    raise InstanceManagerException, 'Something went wrong during instance creation!'
  end

  def create_instance(instance_name, sg_id, subnet_id)
    instance = @ec2.create_instances(image_id: 'ami-2d39803a',
                                     min_count: 1,
                                     max_count: 1,
                                     user_data: Base64.encode64(user_data),
                                     key_name: @config['instance']['key_name'],
                                     instance_type: @config['instance']['instance_type'],
                                     network_interfaces: [{
                                       device_index: 0,
                                       subnet_id: subnet_id,
                                       groups: [sg_id],
                                       associate_public_ip_address: !@config['instance']['public_ip'].nil?
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
    step = @config['instance']['step'].to_i

    begin
      status(instance_name)
    rescue InstanceManagerException => e
      @logger.info("Wait #{step} more sec, #{timeout} remained")
      sleep(step)
      timeout -= step
      retry unless timeout.zero?
      raise InstanceManagerException
    end
  end

  def stop_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                          values: [instance_name] }])
    instance.first.stop
    instance.first.wait_until_stopped
    @logger.info("#{instance_name} stopped!")
  rescue NoMethodError, Aws::EC2::Errors::IncorrectInstanceState
    raise InstanceManagerException, 'Something went wrong during stopping the instance.'
  end

  def terminate_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name',
                                          values: [instance_name] }])
    instance.first.terminate
    instance.first.wait_until_terminated
    @logger.info("#{instance_name} terminated!")
  rescue NoMethodError, Aws::EC2::Errors::IncorrectInstanceState
    raise InstanceManagerException, 'Something went wrong during termination!'
  end
end

class InstanceManagerException < StandardError
end
