ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

require File.expand_path(File.dirname(__FILE__) + "/blueprints")

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  #self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  #self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

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
      assert_equal [], klass.not_deleted
      assert_equal [], klass.deleted
      obj = klass.make
      assert_equal [obj], klass.not_deleted
      obj.destroy
      assert obj.deleted_at
      assert_equal [obj], klass.deleted
      assert_equal [], klass.not_deleted
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
        assert klass.keys.map(&:first).include?(arg.to_s)
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
        assert obj.errors.on(arg.to_sym)
      end
    end
  end

  def self.should_have_many(*args)
    klass = self.name.gsub(/Test$/, '').constantize
    args.each do |arg|
      should "have_many '#{arg}'" do
        has = false
        klass.associations.each do |name, assoc|
          has = true if assoc.type == :many and name == arg.to_s
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
          has = true if assoc.type == :has_one and name == arg.to_s
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
          has = true if assoc.type == :belongs_to and name == arg.to_s
        end
        assert has
      end
    end
  end

  setup do
    Sham.reset
    Dir[Rails.root + 'app/models/**/*.rb'].each do |model_path|
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
end
