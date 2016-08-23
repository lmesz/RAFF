#!/usr/bin/env ruby

require 'thor'

require './lib/aws_drupal_cluster_handler'

class Raff < Thor
  desc 'deploy <instance_name>', 'Deploy a drupal cluster'

  def deploy(instance_name)
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.deploy(instance_name)
  end

  desc 'stop <instance_name>', 'Suspend current drupal cluster'

  def stop(instance_name)
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.stop(instance_name)
  end

  desc 'status <instance_name>', 'Get current status of the drupal cluster'

  def status(instance_name)
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.status(instance_name)
  end

  desc 'start', 'Start as a service, after the start the scripts listen on lolcahost:6666 port and exposes the following endpoint. /deploy, /stop, /status'

  def start
    require 'sinatra'

    get '/' do
      'Holari-hollari-hollari-ho!!!'
    end
  end
end

Raff.start(ARGV)
