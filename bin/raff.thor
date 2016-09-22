#!/usr/bin/env ruby

require 'thor'

require './lib/aws_drupal_cluster_handler'
require './lib/aws_rest'

class Raff < Thor

  @logger = Logger.new(STDOUT)
  @aws_drupal_cluster_handler = AwsDrupalClusterHandler.new(@logger)

  desc 'deploy <instance_name>', 'Deploy a drupal cluster'

  def deploy(instance_name)
    @logger.info("Deploy #{instance_name}!")
    if not @aws_drupal_cluster_handler.deploy(instance_name)
      @logger.error("Error during deploy instance: #{instance_name}!")
    end
  end

  desc 'stop <instance_name>', 'Suspend current drupal cluster'

  def stop(instance_name)
    @logger.info("Stop #{instance_name}!")
    @aws_drupal_cluster_handler = AwsDrupalClusterHandler.new(@logger)
    if not @aws_drupal_cluster_handler.stop(instance_name)
      @logger.error("Error during stopping instance: #{instance_name}!")
    end
  end

  desc 'status <instance_name>', 'Get current status of the drupal cluster'

  def status(instance_name)
    @logger.info("Check the status of #{instance_name}!")
    if not @aws_drupal_cluster_handler.status(instance_name)
      @logger.error('Something is not okay with the given instance. Doesn\'t exists or exists, but page doesn\'t contains the drupal page')
    end
  end

  desc 'terminate <instance_name>', 'Terminate the drupal instance'

  def terminate(instance_name)
    @logger.info("Terminate instance: #{instance_name}!")
    if not @aws_drupal_cluster_handler.terminate(instance_name)
      @logger.error('Something is not okay with the given instance or does not instance.')
    end
  end


  desc 'start', 'Start as a service, after the start the scripts listen on localhost:6666 port and exposes the following endpoint. /deploy, /stop, /status'

  def start
    AwsRest.run!
  end
end

Raff.start(ARGV)
