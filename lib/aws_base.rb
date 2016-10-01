require 'aws-sdk'

class AwsBase
  attr_reader :ec2
  attr_reader :logger

  def initialize(ec2 = Aws::EC2::Resource.new(:region => 'us-east-1',
                                              :stub_responses => true),
                 logger = Logger.new(STDOUT))
    @ec2 = ec2
    @logger = logger
  end
end
