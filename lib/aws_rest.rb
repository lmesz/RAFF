require 'sinatra/base'
require 'json'

require './lib/aws_drupal_cluster_handler'

class AwsRest < Sinatra::Base
  set :port, 6666

  def initialize(_app = nil, adch = AwsDrupalClusterHandler.new)
    super()
    @aws_drupal_cluster_handler = adch
  end

  post '/deploy/:instance_name' do
    begin
      @aws_drupal_cluster_handler.deploy(params[:instance_name])
      everything_ok_with_message('Instance successfully deployed!')
    rescue InstanceManagerException => e
      raise Sinatra::NotFound
    end
  end

  post '/stop/:instance_name' do
    begin
      @aws_drupal_cluster_handler.stop_instance(params[:instance_name])
      everything_ok_with_message('Instance successfully stopped!')
    rescue InstanceManagerException => e
      raise Sinatra::NotFound
    end
  end

  post '/terminate/:instance_name' do
    begin
      @aws_drupal_cluster_handler.terminate_instance(params[:instance_name])
      everything_ok_with_message('Instance successfully terminated!')
    rescue InstanceManagerException => e
      raise Sinatra::NotFound
    end
  end

  get '/status/:instance_name' do
    begin
      @aws_drupal_cluster_handler.status(params[:instance_name])
      everything_ok_with_message('Drupal is available on the given instance!')
    rescue InstanceManagerException => e
      raise Sinatra::NotFound
    end
  end

  def everything_ok_with_message(message)
    content_type :json
    { result: 'ok', message: message }.to_json
  end

  not_found do
    content_type :json
    status 404
    { result: 'error', message: 'Instance not found' }.to_json
  end
end
