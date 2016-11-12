# RAFF
[![Build Status](https://travis-ci.org/lmesz/RAFF.svg?branch=WIP)](https://travis-ci.org/lmesz/RAFF)
[![](https://images.microbadger.com/badges/image/lmesz/raff.svg)](https://microbadger.com/images/lmesz/raff)

#RubyAwsForFun

###Just a simple project to learn [Ruby](https://www.ruby-lang.org/en/) and use some [Amazon Web Services](https://aws.amazon.com/) stuffs.

The script can deploy a default drupal app on an EC2 instance. At the end of the deploy the instance is available via a browser at the resulted URL.

How to execute the script:

 * ./bin/raff.thor deploy <instance_name>: When the command executed a drupal instance will be available.
 * ./bin/raff.thor status <instance_name>: Returns the status of the given instance.
 * ./bin/raff.thor stop <instance_name>: Stop the running instance. If it is already stopped nothing happens. If the instance is not available InstanceManagerException throwns.
 * ./bin/raff.thor terminate <instance_name>: Terminate the given instance. If it is already terminated nothing happens. If the instance is not available an exception throwns.
 * ./bin/raff.thor start: Start a web service that listen on http://localhost:6666. The following endpoints will be exposed:
   * [POST] /deploy/:instance_name : Same as CLI deploy.
   * [POST] /stop/:instance_name : Same as CLI stop.
   * [POST] /terminate/:instance_name : Same as CLI terminate.
   * [GET] /status/:instance_name : Same as CLI status.
