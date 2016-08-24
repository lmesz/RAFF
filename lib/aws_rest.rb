require 'sinatra/base'
require './lib/aws_drupal_cluster_handler'

class AwsRest < Sinatra::Base

    set :port, 6666

    def initialize(app = nil)
      super()
      @aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    end

    post '/deploy/:instance_name' do
      @aws_drupal_cluster_handler.deploy(params[:instance_name])
    end

    post '/stop/:instance_name' do
      @aws_drupal_cluster_handler.stop(params[:instance_name])
    end

    get '/status/:instance_name' do
      @aws_drupal_cluster_handler.status(params[:instance_name])
    end
end