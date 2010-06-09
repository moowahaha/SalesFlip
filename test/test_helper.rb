# encoding: utf-8
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require File.expand_path(File.dirname(__FILE__) + "/blueprints")

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def self.should_have_constant(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_constant '#{arg}'" do
        assert klass.new.respond_to?(arg.to_s.singularize)
        assert klass.respond_to?(arg.to_s)
        assert klass.new.respond_to?("#{arg.to_s.singularize}_is?")
      end
    end
  end

  def self.should_act_as_paranoid
    klass = self.name.gsub(/Test$/, '').constantize
    should 'act as paranoid' do
      assert klass.new.respond_to?('deleted_at')
      assert klass.respond_to?('not_deleted')
      assert klass.respond_to?('deleted')
      assert klass.not_deleted.blank?
      assert klass.deleted.blank?
      obj = klass.make
      assert klass.not_deleted.include?(obj)
      obj.destroy
      assert obj.deleted_at
      assert klass.deleted.include?(obj)
      assert klass.not_deleted.blank?
    end
  end

  def self.should_be_trackable
    klass = self.name.gsub(/Test$/, '').constantize
    should 'be trackable' do
      assert klass.new.respond_to?('tracker_ids')
      assert klass.new.respond_to?('trackers')
      assert klass.new.respond_to?('tracker_ids=')
      assert klass.new.respond_to?('tracked_by?')
      assert klass.new.respond_to?('remove_tracker_ids=')
      assert klass.respond_to?('tracked_by')
    end
  end

  def self.should_have_key(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_key '#{arg}'" do
        assert klass.fields.map(&:first).include?(arg.to_s)
      end
    end
  end

  def self.should_require_key(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "require key '#{arg}'" do
        obj = klass.new
        obj.send("#{arg.to_sym}=", nil)
        obj.valid?
        assert !obj.errors[arg.to_sym].blank?
      end
    end
  end

  def self.should_have_many(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_many '#{arg}'" do
        has = false
        klass.associations.each do |name, assoc|
          if assoc.association.to_s.match(/ReferencesMany|EmbedsMany/) and name == arg.to_s
            has = true
          end
        end
        assert has
      end
    end
  end

  def self.should_have_one(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_one '#{arg}'" do
        has = false
        klass.associations.each do |name, assoc|
          if assoc.association.to_s.match(/HasOneRelated/) and name == arg.to_s
            has = true
          end
        end
        assert has
      end
    end
  end

  def self.should_belong_to(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "belong_to '#{arg}'" do
        has = false
        klass.associations.each do |name, assoc|
          if assoc.association.to_s.match(/ReferencedIn|EmbeddedIn/) and name == arg.to_s
            has = true
          end
        end
        assert has
      end
    end
  end

  def self.should_have_uploader(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_uploader '#{arg}'" do
        assert klass.new.send(arg).is_a?(CarrierWave::Uploader::Base)
      end
    end
  end

  setup do
    Sham.reset
    Dir[Rails.root.to_s + '/app/models/**/*.rb'].each do |model_path|
      model_name = File.basename(model_path).gsub(/\.rb$/, '')
      if model_name == 'alias'
        klass = Alias
      else
        klass = model_name.classify.constantize
      end
      klass.delete_all if klass.respond_to?('delete_all')
    end
    Configuration.make
  end

  def assert_add_job_email_sent(posting)
    assert_sent_email do |email|
      email.subject == "Neue Stellenanzeige von #{posting.job.company_name}" and
      email.body    =~ /#{posting.job.position}/ and
      email.to.include? posting.board.api_email
    end
  end
 
  def assert_delete_job_email_sent(posting)
    assert_sent_email do |email|
      email.subject == "Löschen der Stellenanzeige #{posting.job.position} von #{posting.job.company_name}" and
      email.body =~ /#{posting.job.position}/ and email.to.include? posting.board.api_email
    end
  end
end
