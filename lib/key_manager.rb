require 'aws-sdk'
require './lib/aws_base'

# This class handle the keys that will be used in aws ec2 instance for ssh.
class KeyManager < AwsBase
  def import_key_if_not_exists
    @logger.info('Import key ...')
    pub_key = File.read(File.join(@config['key']['key_path'], @config['key']['key_name']))
    @ec2.import_key_pair(key_name: @config['key']['key_name'], public_key_material: pub_key)
  rescue Aws::EC2::Errors::InvalidKeyPairDuplicate
    @logger.info('Key already exists')
    return
  rescue Errno::ENOENT => e
    raise KeyManagerException, e.message
  end
end

class KeyManagerException < RuntimeError
end
