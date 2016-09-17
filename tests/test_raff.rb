require './lib/aws_drupal_cluster_handler'
require 'test/unit'

class TestRaff < Test::Unit::TestCase
  def test_raff()
    logger = Logger.new(STDOUT)
    adch = AwsDrupalClusterHandler.new(logger)
    assert_instance_of AwsDrupalClusterHandler, adch
  end
end
