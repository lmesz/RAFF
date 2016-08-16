#!/usr/bin/env ruby

require 'optparse'
require './lib/aws_drupal_cluster_handler'

INSTANCE_NAME = "WTestInstance"

def background
  require 'sinatra'

  get '/' do
    'Holari-hollari-hollari-ho!!!'
  end
end

def deploy
  aws_drupal_cluster_handler = AwsDrupalClusterHandler.new
  aws_drupal_cluster_handler.deploy(INSTANCE_NAME)
end

def pause
  puts "Paused!"
end

def restart
  puts "Restarted!"
end

def status
  handler = AwsDrupalClusterHandler.new
  handler.status(INSTANCE_NAME)
end

ARGV << "-h" if ARGV.empty?

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-b", "--background", "Run in the background and offer restful API. The following endpoints available /deploy, /pause, /restart, /status") do |b|
    background
  end

  opts.on("-d", "--deploy", "Deploy a new drupal cluster") do |l|
    deploy
  end

  opts.on("-p", "--pause", "Pause the drupal cluster") do |p|
    pause
  end

  opts.on("-r", "--restart", "Restart already paused cluster!") do |r|
    restart
  end

  opts.on("-s", "--status", "Check if cluster available!") do |s|
    status
  end
end.parse!
