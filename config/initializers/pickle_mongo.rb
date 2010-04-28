module Pickle
  class Adapter
    def self.model_classes
      @@model_classes ||=
      Dir[Rails.root + 'app/models/**/*.rb'].map do |model_path|
        model_name = File.basename(model_path).gsub(/\.rb$/, '')
        if model_name == 'alias'
          klass = Alias
        else
          klass = model_name.classify.constantize
        end
      end.reject { |klass| !klass.respond_to?('collection') }
    end
  end

  module Session
    def find_model(a_model_name, fields = nil)
      factory, name = *parse_model(a_model_name)
      raise ArgumentError, "Can't find a model with an ordinal (e.g. 1st user)" if name.is_a?(Integer)
      model_class = pickle_config.factories[factory].klass
      fields = fields.is_a?(Hash) ? parse_hash(fields) : parse_fields(fields)
      if record = model_class.first(:conditions => convert_models_to_attributes(model_class, fields))
        store_model(factory, name, record)
      end
    end

    def find_models( factory, fields = nil )
      models_by_index(factory).clear
      model_class = pickle_config.factories[factory].klass
      records = model_class.all(:conditions => convert_models_to_attributes(model_class, parse_fields(fields)))
      records.each { |record| store_model(factory, nil, record) }
    end

    def create_model(pickle_ref, fields = nil)
      factory, label = *parse_model(pickle_ref)
      raise ArgumentError, "Can't create with an ordinal (e.g. 1st user)" if label.is_a?(Integer)
      fields = fields.is_a?(Hash) ? parse_hash(fields) : parse_fields(fields)
      if pickle_config.factories.keys.include?("#{label}_#{factory}")
        record = pickle_config.factories["#{label}_#{factory}"].create(fields)
      else
        record = pickle_config.factories[factory].create(fields)
      end
      store_model(factory, label, record)
    end
  end
end
