#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require 'rubygems'
require 'beanstalk-client'
require 'yaml'
#beanstalk_config = YAML::load(File.open("#{Rails.root}/config/beanstalk.yml"))

@logger = Logger.new("#{RAILS_ROOT}/log/queue.#{Rails.env}.log")
@logger.level = Logger::INFO

#BEANSTALK = Beanstalk::Pool.new(beanstalk_config[Rails.env])
BEANSTALK = Beanstalk::Pool.new(['localhost:11300'])

loop do
  job = BEANSTALK.reserve
  job_hash = job.ybody
  case job_hash[:type]
  when 'received_email'
    @logger.info("Got email: #{job_hash.inspect}")
    item = MailQueue.find_by_id(job_hash[:item]) if job_hash[:item]
    if EmailReader.parse_email(Mail.new(item.mail))
      job.delete
      item.destroy
    else
      @logger.warn("Did not process email: #{job_hash.inspect}")
      job.bury
      item.update_attributes :status => 'Failed'
    end
  else
    @logger.warn("Don't know how to process #{job_hash.inspect}")
  end
end
