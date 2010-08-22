module Mongoid
  module Rails
    module MultiParameterAttributes
      def self.included(base)
        base.before_validation :handle_multiparameter_attributes

        base.class_eval do
          include InstanceMethods
        end
      end
    end

    module InstanceMethods

    protected
      def handle_multiparameter_attributes
        multiparameter_attributes = []
        self.attributes.each_pair do |attr_name, value|
          multiparameter_attributes << [attr_name, value] if attr_name.include?("(")
        end
        assign_multiparameter_attributes(multiparameter_attributes) if multiparameter_attributes.any?
      end

      def assign_multiparameter_attributes(pairs)
        execute_callstack_for_multiparameter_attributes(
          extract_callstack_for_multiparameter_attributes(pairs)
        )
      end

      def execute_callstack_for_multiparameter_attributes(callstack)
        errors = []
        callstack.each do |name, values_with_empty_parameters|
          begin
            klass = self.class.fields[name].type

            # puts "Class is #{klass.to_s}"
            # in order to allow a date to be set without a year, we must keep the empty values.
            # Otherwise, we wouldn't be able to distinguish it from a date with an empty day.
            values = values_with_empty_parameters.reject(&:nil?)

            if values.empty?
              send(name + "=", nil)
            else

              value = if Time == klass
                instantiate_time_object(name, values)
              elsif Date == klass
                begin
                  values = values_with_empty_parameters.collect do |v| v.nil? ? 1 : v end
                  Date.new(*values)
                rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                  instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
                end
              else
                klass.new(*values)
              end

              send(name + "=", value)
            end
          rescue => ex
            errors << AttributeAssignmentError.new("error on assignment #{values.inspect} to #{name}", ex, name)
          end
        end
        unless errors.empty?
          raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
        end
      end

      def extract_callstack_for_multiparameter_attributes(pairs)
        attributes = { }

        for pair in pairs
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = [] unless attributes.include?(attribute_name)

          parameter_value = value.empty? ? nil : type_cast_attribute_value(multiparameter_name, value)
          attributes[attribute_name] << [ find_parameter_position(multiparameter_name), parameter_value ]
        end

        attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
      end

      def type_cast_attribute_value(multiparameter_name, value)
        multiparameter_name =~ /\([0-9]*([if])\)/ ? value.send("to_" + $1) : value
      end

      def find_parameter_position(multiparameter_name)
        multiparameter_name.scan(/\(([0-9]*).*\)/).first.first
      end

      def instantiate_time_object(name, values)
        Time.zone.local(*values)
      end

    end
  end
end
