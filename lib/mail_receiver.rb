#!/usr/bin/env ruby
require 'rubygems'
require 'mail'
require 'beanstalk-client'
require 'mongoid'
require File.join(File.dirname(__FILE__), '..', 'app', 'models', 'mail_queue')

begin
  db_config = YAML::load(File.read(File.join(File.dirname(__FILE__), '..', 'config', 'mongoid.yml')))
rescue
  raise IOError, 'config/mongoid.yml could not be loaded'
end

mongo = db_config['production']
Mongoid.connection = Mongo::Connection.new(mongo['host'] || 'localhost',
                                               mongo['port'] || 27017)
Mongoid.database = mongo['database']
if mongo['username'] && mongo['password']
  Mongoid.database.authenticate(mongo['username'], mongo['password'])
end

message = $stdin.read
mail = Mail.new(message)

if !mail.to.nil?
  item = MailQueue.create! :mail => mail.to_s, :status => 'New'

  BEANSTALK = Beanstalk::Pool.new(['127.0.0.1:11300'])
  BEANSTALK.yput({
    :type => 'received_email',
    :item => item.id
  })
end
