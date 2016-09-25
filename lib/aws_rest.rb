require 'sinatra/base'
require 'json'

require './lib/aws_drupal_cluster_handler'

class AwsRest < Sinatra::Base
  set :port, 6666

  def initialize(_app = nil, adch = AwsDrupalClusterHandler.new(Logger.new(STDOUT)))
    super()
    @aws_drupal_cluster_handler = adch
  end

  post '/deploy/:instance_name' do
    if !@aws_drupal_cluster_handler.deploy(params[:instance_name])
      content_type :json
      status 404
      { result: 'error', message: 'Instance not found' }.to_json
    else
      content_type :json
      { result: 'ok', message: 'Instance successfully deployed!' }.to_json
    end
  end

  post '/stop/:instance_name' do
    if !@aws_drupal_cluster_handler.stop(params[:instance_name])
      content_type :json
      status 404
      { result: 'error', message: 'Instance not found' }.to_json
    else
      content_type :json
      { result: 'ok', message: 'Instance successfully stoped!' }.to_json
    end
  end

  post '/terminate/:instance_name' do
    if !@aws_drupal_cluster_handler.terminate(params[:instance_name])
      content_type :json
      status 404
      { result: 'error', message: 'Instance not found' }.to_json
    else
      content_type :json
      { result: 'ok', message: 'Instance successfully terminated!' }.to_json
    end
  end

  get '/status/:instance_name' do
    if !@aws_drupal_cluster_handler.status(params[:instance_name])
      content_type :json
      status 404
      { result: 'error', message: 'Instance not found' }.to_json
    else
      content_type :json
      { result: 'ok', message: 'Drupal is available on the given instance!' }.to_json
    end
  end
end
