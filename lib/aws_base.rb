require 'aws-sdk'
require 'parseconfig'

class AwsBase
  attr_reader :ec2
  attr_reader :logger
  attr_reader :config

  def initialize(ec2 = Aws::EC2::Resource.new(:region => 'us-east-1',
                                              :stub_responses => true),
                 logger = Logger.new(STDOUT),
                 config = 'config')
    @ec2 = ec2
    @logger = logger
    @config = ParseConfig.new(File.join(File.dirname(__FILE__),
                                        '..',
                                        'conf',
                                        config))
  end
end
