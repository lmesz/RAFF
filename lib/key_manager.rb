require 'aws-sdk'

class KeyManager

  attr_reader :ec2
  attr_reader :logger
  attr_reader :key_path
  attr_reader :key_name

  def initialize(ec2=Aws::EC2::Resource.new(region: 'us-east-1'), logger=Logger.new(STDOUT), key_path=ENV['key_path'], key_name=ENV['key_name'])
    @ec2 = ec2
    @logger = logger
    if key_path == nil or key_name == nil
      raise KeyManagerException, 'The "key_path" and "key_name" environment variable need to be set if not given during initialization'
    end
    @key_path = key_path
    @key_name = key_name
  end

  def import_key
    begin
      pub_key = File.read(File.join(@key_path, @key_name))
      @ec2.import_key_pair({ key_name: @key_name, public_key_material: pub_key })
    rescue Errno::ENOENT => e
      raise KeyManagerException, e.message
    end
  end

  def import_key_if_not_exists
    @logger.info('Check if key exists ...')
    if @ec2.key_pairs(filters: [{ name: 'key-name', values: [@key_name] }]).first
      @logger.info('Key exists')
      return
    end
    import_key
  end
end

class KeyManagerException < Exception
end
