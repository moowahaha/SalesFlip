include MongoMapper

begin
  db_config = YAML::load(File.read(File.join(Rails.root, "/config/mongodb.yml")))
rescue
  raise IOError, 'config/mongodb.yml could not be loaded'
end

if db_config[Rails.env] && db_config[Rails.env]['adapter'] == 'mongodb'
  mongo = db_config[Rails.env]
  MongoMapper.connection = Mongo::Connection.new(mongo['host'] || 'localhost',
                                                 mongo['port'] || 27017,
                                                 :logger => Rails.logger)
  MongoMapper.database = mongo['database']

  if mongo['username'] && mongo['password']
    MongoMapper.database.authenticate(mongo['username'], mongo['password'])
  end
end

ActionController::Base.rescue_responses['MongoMapper::DocumentNotFound'] = :not_found

require 'carrierwave'
require 'carrierwave/orm/mongomapper'

CarrierWave.configure do |config|
  mongo = db_config[Rails.env]
  config.grid_fs_database = mongo['database']
  config.grid_fs_host = mongo['host'] || 'localhost'
  config.grid_fs_access_url = "gridfs"
  config.grid_fs_username = mongo['username'] if mongo['username']
  config.grid_fs_password =  mongo['password'] if mongo['password']
end

MongoMapper::Document.append_inclusions(UsefulScopes)

module Xml
  def self.included( base )
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    def from_xml( xml )
      self.new Hash.from_xml(xml).values.first
    end
  end

  module InstanceMethods
    def to_xml( options = {} )
      require 'builder'
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.tag! self.class.to_s.downcase do
        self.keys.each do |key|
          key = key.first.gsub(/^_/, '')
          xml.tag! key.dasherize, self.send(key) unless key == 'sphinx_id'
        end
      end
    end
  end
end

MongoMapper::Document.append_inclusions(Xml)

MongoMapper.database.eval(
  <<-JAVASCRIPT
  db.system.js.save( { _id : 'contains', value : function( array, value ) {
    a = false;
    for(i = 0; i < array.length; i++) {
      if(array[i] == value) {
        a = true;
      }
    }
    return a;
  } } );
  JAVASCRIPT
)
