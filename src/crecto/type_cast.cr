module Crecto
  module TypeCast
    extend self

    def cast_to_string(value)
      case value
      when String
        value
      else
        value.to_s
      end
    end

    def cast_to_int16(value)
      case value
      when Int16
        value
      when Number
        value.to_i16?
      when String
        value.to_i16?
      else
        nil
      end
    end

    def cast_to_int(value)
      case value
      when Int
        value
      when Number
        value.to_i
      when String
        value.to_i?
      when JSON::Any
        cast_to_int(value.raw)
      else
        nil
      end
    end

    def cast_to_float(value)
      case value
      when Float
        value
      when Number
        value.to_f
      when String
        value.to_f?
      when JSON::Any
        cast_to_float(value.raw)
      else
        nil
      end
    end

    def cast_to_bool(value)
      case value
      when Bool
        value
      when String
        return false if value == "false"
        !!value
      when JSON::Any
        cast_to_bool(value.raw)
      else
        !!value
      end
    end

    def cast_to_time(value)
      case value
      when Time
        value
      when String
        begin
          Time.parse!(value, "%F %T %z")
        rescue
          nil
        end
      when JSON::Any
        begin
          Time::Format::ISO_8601_DATE_TIME.parse(value.as_s)
        rescue
          nil
        end
      else
        nil
      end
    end
  end
end
