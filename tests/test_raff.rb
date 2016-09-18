require './lib/aws_drupal_cluster_handler'
require './lib/aws_rest'

require 'test/unit'
require 'rack/test'

class TestRaff < Test::Unit::TestCase
  def test_raff_cli()
    logger = Logger.new(STDOUT)
    adch = AwsDrupalClusterHandler.new(logger)
    assert_instance_of AwsDrupalClusterHandler, adch
  end

  def test_raff_rest()
    browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    browser.get '/status', :instance_name => 'DummyInstanceName'
  end

end
