require 'aws-sdk'
require './lib/aws_base'

# This class handle the keys that will be used in aws ec2 instance for ssh.
class KeyManager < AwsBase
  attr_reader :key_path
  attr_reader :key_name

  def initialize(ec2 = Aws::EC2::Resource.new(region: 'us-east-1',
                                              stub_responses: true),
                 logger = Logger.new(STDOUT),
                 key_path = ENV['key_path'],
                 key_name = ENV['key_name'])
    super(ec2, logger)
    if key_path.nil? || key_name.nil?
      raise KeyManagerException, 'The "key_path" and "key_name" environment'\
                                 ' variable need to be set if not given during'\
                                 ' initialization'
    end
    @key_path = key_path
    @key_name = key_name
  end

  def import_key
    pub_key = File.read(File.join(@key_path, @key_name))
    @ec2.import_key_pair(key_name: @key_name, public_key_material: pub_key)
  rescue Errno::ENOENT => e
    raise KeyManagerException, e.message
  end

  def import_key_if_not_exists
    @logger.info('Check if key exists ...')
    if @ec2.key_pairs(filters: [{ name: 'key-name',
                                  values: [@key_name] }]).first
      @logger.info('Key exists')
      return
    end
    import_key
  end
end

class KeyManagerException < RuntimeError
end
