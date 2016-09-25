class InstanceManager
  def initialize(ec2, logger, keyname)
    @ec2 = ec2
    @logger = logger
    @key_name = keyname
  end

  def status(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name', values: [instance_name] }])
    if instance.first.instance_of? Aws::EC2::Instance
      @logger.info("Instance already exists. Public DNS adress is #{instance.first.public_dns_name}")
      begin
        uri = URI("http://#{instance.first.public_dns_name}/")
        res = Net::HTTP.get_response(uri)

        if res.body.include? 'drupal'
          @logger.info("Drupal is available at http://#{instance.first.public_dns_name}")
        else
          @logger.info('Drupal is not available, the host is listen on port 80, but does not serve drupal site!')
          return false
        end
        return true
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED
        @logger.error('Drupal is not available, because nothing listen at port 80!')
        return false
      end
    end
    false
  end

  def create_instance(instance_name, sg_id, subnet_id)
    @logger.info('Check if instance exists')

    instance = @ec2.instances(filters: [{ name: 'tag:Name', values: [instance_name] }])
    if instance.first.instance_of? Aws::EC2::Instance
      state_of_instance = instance.first.state.name
      if state_of_instance.eql? 'running'
        @logger.info("Instance already exists. Public DNS adress is #{instance.first.public_dns_name}")
        return true
      end
      @logger.info('Instance already exists, but not running')
      return false
    end

    @logger.info('Instance does not exists, Create instance ...')

    user_data = File.read(File.join(File.dirname(__FILE__), '..', 'conf', 'user.data'))

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

    instance[0].wait_until_running

    instance.batch_create_tags(tags: [{ key: 'Name', value: instance_name }, { key: 'Group', value: 'TestGroup' }])

    inst = @ec2.instance(instance[0].id)

    return false unless inst.instance_of? Aws::EC2::Instance
    @logger.info("The created instance public DNS address is: #{inst.public_dns_name}")

    wait_for_drupal_to_be_installed(instance_name)
  end

  def wait_for_drupal_to_be_installed(instance_name)
    timeout = 600
    step = 5

    until status(instance_name)
      return false if timeout.zero?
      @logger.info("Drupal is not installed, wait #{step} more sec")
      sleep(step)
      timeout -= step
    end

    true
  end

  def stop_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name', values: [instance_name] }])
    if instance.first.instance_of? Aws::EC2::Instance
      @logger.info("Instance already exists. #{instance.first.id}")
      begin
        instance.first.stop
      rescue Aws::EC2::Errors::IncorrectInstanceState
        @logger.error('Instance can not stopped because of it\'s state.')
        return false
      end
      instance.first.wait_until_stopped
      @logger.info('Instance stopped.')
      return true
    end

    @logger.info('Instance does not exists.')
    false
  end

  def terminate_instance(instance_name)
    instance = @ec2.instances(filters: [{ name: 'tag:Name', values: [instance_name] }])
    if instance.first.instance_of? Aws::EC2::Instance
      @logger.info("Instance already exists. #{instance.first.id}")
      instance.first.terminate
      instance.first.wait_until_terminated
      @logger.info('Instance terminated.')
      return true
    end

    @logger.info('Instance does not exists.')
    false
  end
end
