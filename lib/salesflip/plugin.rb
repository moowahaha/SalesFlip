module Salesflip
  class Plugin
    @@list = {}

    def initialize( id, initializer )
      @id, @initializer = id, initializer
    end

    %w(name description author version).each do |name|
      define_method(name) do |*args|
        args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", args.first)
      end
    end
    alias :authors :author

    def dependencies( *plugins )
      plugin_path = @initializer.configuration.plugins_path.first
      plugins.each do |name|
        plugin = Rails::Plugin.new("#{plugin_path}/#{name}")
        plugin.load(@initializer)
      end
    end

    def tab( main_or_admin, options = nil )
      if main_or_admin.is_a?(Hash)
        options = main_or_admin.dup
        main_or_admin = :main
      end
    end

    class << self
      private :new

      def register( id, initializer = nil, &block )
        if initializer && Rails.env == 'development'
          initializer.configuration.cache_classes = true
        end
        plugin = new(id, initializer)
        plugin.instance_eval(&block)
        plugin.name(id.to_s) unless plugin.name
        @@list[name] = plugin
      end
      alias_method :<<, :register

      def list
        @@list.values
      end
    end
  end
end
