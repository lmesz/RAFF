#!/usr/bin/env ruby

require 'optparse'
require './lib/aws-handler'

INSTANCE_NAME = "OTestInstance"

def deploy()
    handler = AwsHandler.new
    handler.create_key_if_not_exists()
    vpc_id = handler.create_vpc_if_not_exists()
    subnet_id = handler.create_subnet_if_not_exists(vpc_id)
    sg_id = handler.create_security_group_if_not_exists(vpc_id)
    handler.create_instance(INSTANCE_NAME, sg_id, subnet_id)
end

def pause()
    puts "Paused!"
end

def restart()
    puts "Restarted!"
end

def status()
    handler = AwsHandler.new
    handler.status(INSTANCE_NAME)
end

ARGV << "-h" if ARGV.empty?

options = {}
optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

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
