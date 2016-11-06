#!/usr/bin/env ruby

require 'logger'
require 'thor'

require './lib/aws_drupal_cluster_handler'
require './lib/aws_rest'

class Raff < Thor

  def initialize(*args)
    super
    @logger = Logger.new(STDOUT)
    @aws_drupal_cluster_handler = AwsDrupalClusterHandler.new(Aws::EC2::Resource.new(:region => 'us-east-1'),
                                                              @logger)
  end

  desc 'deploy <instance_name>', 'Deploy a drupal cluster'

  def deploy(instance_name)
    @logger.info("Deploy #{instance_name}!")
    @aws_drupal_cluster_handler.deploy(instance_name)
  rescue InstanceManagerException => i
    @logger.error(i.to_s)
  end

  desc 'stop <instance_name>', 'Suspend current drupal cluster'

  def stop(instance_name)
    @logger.info("Stop #{instance_name}!")
    @aws_drupal_cluster_handler.stop_instance(instance_name)
  rescue InstanceManagerException => i
    @logger.error(i.to_s)
  end

  desc 'status <instance_name>', 'Get current status of the drupal cluster'

  def status(instance_name)
    @logger.info("Check the status of #{instance_name}!")
    @aws_drupal_cluster_handler.status(instance_name)
  rescue InstanceManagerException => i
    @logger.error(i.to_s)
  end

  desc 'terminate <instance_name>', 'Terminate the drupal instance'

  def terminate(instance_name)
    @logger.info("Terminate instance: #{instance_name}!")
    @aws_drupal_cluster_handler.terminate_instance(instance_name)
  rescue InstanceManagerException => i
    @logger.error(i.to_s)
  end


  desc 'start', 'Start as a service, after the start the scripts listen on localhost:6666 port and exposes the following endpoint. /deploy, /stop, /status'

  def start
    AwsRest.run!
  end
end

Raff.start(ARGV)
