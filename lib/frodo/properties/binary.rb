module Frodo
  module Properties
    # Defines the Binary Frodo type.
    class Binary < Frodo::Property
      # Returns the property value, properly typecast
      # @return [Integer,nil]
      def value
        if (@value.nil? || @value.empty?) && allows_nil?
          nil
        else
          @value.to_i
        end
      end

      # Sets the property value
      # @params new_value [0,1,Boolean]
      def value=(new_value)
        validate(new_value)
        @value = parse_value(new_value)
      end

      # The Frodo type name
      def type
        'Edm.Binary'
      end

      # Value to be used in URLs.
      # @return [String]
      def url_value
        "binary'#{value}'"
      end

      private

      def parse_value(value)
        if value == 0 || value == '0' || value == false
          '0'
        else
          '1'
        end
      end

      def validate(value)
        unless [0,1,'0','1',true,false].include?(value)
          validation_error 'Value is outside accepted range: 0 or 1'
        end
      end
    end
  end
end
