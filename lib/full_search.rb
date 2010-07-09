module FullSearch
  def self.included( base )
    base.extend(ClassMethods)
  end

  module ClassMethods
    def search_keys( *keys )
      self.class_eval do
        @keys_to_search = keys.map(&:to_s)
      end
    end

    def search( query_string, options = {} )
      conditions = []
      (options[:keys_to_search] || @keys_to_search).each do |key|
        next if key.match(/_id|created_at|updated_at/)
        conditions << "(this.#{key} != null && this.#{key}.match(/#{query_string}/i))"
      end
      where(conditions.join(' || '))
    end
  end
end
