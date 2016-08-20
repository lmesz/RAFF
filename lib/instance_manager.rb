class InstanceManager
  def initialize(ec2, logger)
    @ec2 = ec2
    @logger = logger
  end

  def status(instance_name)
    instance = @ec2.instances(filters: [{name: 'tag:Name', values: [instance_name]}])
    if instance.first.instance_of? Aws::EC2::Instance
      @logger.info("Instance already exists. Public DNS adress is #{instance.first.public_dns_name}")
      begin
        uri = URI("http://#{instance.first.public_dns_name}/")
        res = Net::HTTP.get_response(uri)

        if res.body.include? "drupal"
          @logger.info("Drupal is available at http://#{instance.first.public_dns_name}")
        else
          @logger.info('Drupal is not available, the host is listen on port 80, but does not serve drupal site!')
        end
      rescue Timeout::Error, SocketError
        @logger.error('Drupal is not available, because nothing listen at port 80!')
      end
    end
  end

  def create_instance(instance_name, sg_id, subnet_id)
    @logger.info('Check if instance exists')

    instance = @ec2.instances(filters: [{name: 'tag:Name', values: [instance_name]}])
    if instance.first.instance_of? Aws::EC2::Instance
      @logger.info("Instance already exists. Public DNS adress is #{instance.first.public_dns_name}")
      return
    end

    @logger.info('Instance does not exists, Create instance ...')

    user_data = File.read(File.join(File.dirname(__FILE__), '..', 'conf', 'user.data'))

    instance = @ec2.create_instances({
                                         image_id: 'ami-2d39803a',
                                         min_count: 1,
                                         max_count: 1,
                                         user_data: Base64.encode64(user_data),
                                         key_name: KEY_NAME,
                                         instance_type: 't2.micro',
                                         network_interfaces: [{
                                                                  device_index: 0,
                                                                  subnet_id: subnet_id,
                                                                  groups: [sg_id],
                                                                  associate_public_ip_address: true
                                                              }]
                                     })

    @ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance[0].id]})

    instance.batch_create_tags({tags: [{key: 'Name', value: instance_name}, {key: 'Group', value: 'TestGroup'}]})

    inst = @ec2.instance(instance[0].id)

    @logger.info("The created instance public DNS address is: #{inst.public_dns_name}")
  end
end
