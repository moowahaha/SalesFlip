module Salesflip
  module Callback
    @@classes = []
    @@responder = []

    def self.add( klass )
      @@classes << klass
    end

    def self.responder( method )
      @@responder[method] ||= @classes.map(&:instance).select do |instance|
        instance.respond_to?(method)
      end
    end

    def self.hook( method, caller, context = {} )
      responder(method).inject([]) do |response, m|
        response << m.send(method, caller, context)
      end
    end

    class Base
      include Singleton

      def self.inherited( child )
        Salesflip::Callback.add(child)
        super
      end
    end

    module Helper
      def hook( method, caller, context = {} )
        data = Salesflip::Callback.hook(method, caller, context)
        caller.class.to_s.start_with?('ActionView') ? data.join : data
      end
    end
  end
end
