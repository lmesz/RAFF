#!/usr/bin/env ruby

require 'thor'

require './lib/aws_drupal_cluster_handler'

INSTANCE_NAME = "WTestInstance"

def background
  require 'sinatra'

  get '/' do
    'Holari-hollari-hollari-ho!!!'
  end
end

class Raff < Thor
  desc "deploy", "Deploy a drupal cluster"

  def deploy
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.deploy(INSTANCE_NAME)
  end

  desc "suspend", "Suspend current drupal cluster"

  def suspend
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.suspend(INSTANCE_NAME)
  end

  desc "status", "Get current status of the drupal cluster"

  def status
    aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
    aws_drupal_cluster_handler.status(INSTANCE_NAME)
  end

  desc "start", "Start as a service, after the start the scripts listen on lolcahost:6666 port and exposes the following endpoint. /deploy, /suspend, /status"

  def start
  end
end

Raff.start(ARGV)
