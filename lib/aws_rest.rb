require 'sinatra/base'
require 'json'

require './lib/aws_drupal_cluster_handler'

class AwsRest < Sinatra::Base

    set :port, 6666

    def initialize(app = nil)
      super()
      @aws_drupal_cluster_handler = AwsDrupalClusterHandler.new(Logger.new(STDOUT))
    end

    post '/deploy/:instance_name' do
      @aws_drupal_cluster_handler.deploy(params[:instance_name])
    end

    post '/stop/:instance_name' do
      @aws_drupal_cluster_handler.stop(params[:instance_name])
    end

    post '/terminate/:instance_name' do
      @aws_drupal_cluster_handler.terminate(params[:instance_name])
    end

    get '/status/:instance_name' do
      if not @aws_drupal_cluster_handler.status(params[:instance_name])
        content_type :json
        status 404
        {:result => 'error', :message => 'Instance not found'}.to_json
      end
    end
end
