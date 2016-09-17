require './lib/aws_drupal_cluster_handler'
require 'test/unit'

class TestRaff < Test::Unit::TestCase
  def test_raff()
    logger = Logger.new(STDOUT)
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new(logger)
    assert_instance_of AwsDrupalClusterHandler, aws_drupal_cluster_handler
  end
end
