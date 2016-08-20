class KeyManager
  KEY_NAME = 'TestKey'.freeze

  def initialize(ec2, logger)
    @ec2 = ec2
    @logger = logger
  end

  def create_key
    client = Aws::EC2::Client.new(region: REGION)
    key_pair = client.create_key_pair({key_name: KEY_NAME})
    filename = File.join(Dir.home, "#{KEY_NAME}.pem")
    File.open(filename, 'w') { |file| file.write(key_pair.key_material) }
  end

  def is_key_downloaded
    return File.file?(File.join(Dir.home, "#{KEY_NAME}.pem"))
  end

  def create_key_if_not_exists
    @logger.info('Check if key exists ...')
    if @ec2.key_pairs(filters: [{name: 'key-name', values: [KEY_NAME]}]).first
      @logger.info('Key exists check if it is downloaded ...')
      create_key unless is_key_downloaded
      return
    end
    create_key
  end
end
