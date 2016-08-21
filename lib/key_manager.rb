class KeyManager

  def initialize(ec2, logger, key_name)
    @ec2 = ec2
    @logger = logger
    @key_name = key_name
  end

  def import_key
    pub_key = File.read(File.join(File.dirname(__FILE__), '..', 'conf', 'TestKeyPub.key'))
    @ec2.import_key_pair({key_name: @key_name, public_key_material: pub_key })
  end

  def import_key_if_not_exists
    @logger.info('Check if key exists ...')
    if @ec2.key_pairs(filters: [{name: 'key-name', values: [@key_name]}]).first
      @logger.info('Key exists')
      return
    end
    import_key
  end
end
