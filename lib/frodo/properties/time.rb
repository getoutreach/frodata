module Frodo
  module Properties
    # Defines the Time Frodo type.
    class Time < Frodo::Property
      # Returns the property value, properly typecast
      # @return [Time,nil]
      def value
        if (@value.nil? || @value.empty?) && allows_nil?
          nil
        else
          ::Time.strptime(@value, '%H:%M:%S%:z')
        end
      end

      # Sets the property value
      # @params new_value [Time]
      def value=(new_value)
        validate(new_value)
        @value = parse_value(new_value)
      end

      # The Frodo type name
      def type
        'Edm.Time'
      end

      private

      def validate(value)
        unless value.is_a?(::Time)
          validation_error 'Value is not a time object'
        end
      end

      def parse_value(value)
        value.strftime('%H:%M:%S%:z')
      end
    end
  end
end
