module Pickle
  module Session
    def create_model(pickle_ref, fields = nil)
      factory, label = *parse_model(pickle_ref)
      factory = "#{label}_#{factory}" unless label.blank?
      raise ArgumentError, "Can't create with an ordinal (e.g. 1st user)" if label.is_a?(Integer)
      fields = fields.is_a?(Hash) ? parse_hash(fields) : parse_fields(fields)
      record = pickle_config.factories[factory].create(fields)
      store_model(factory, label, record)
      record
    end
  end
end
