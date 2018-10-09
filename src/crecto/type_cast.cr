module Crecto
  module TypeCast
    def cast_to_string(value : String); value; end
    def cast_to_string(value); value.to_s; end

    def cast_to_int16(value : Int16); value; end
    def cast_to_int16(value : Int); value.to_i16?; end
    def cast_to_int16(value : String); value.to_i16?; end

    def cast_to_int(value : Int); value; end
    def cast_to_int(value : String); value.to_i?; end

    def cast_to_float(value : Float); value; end
    def cast_to_float(value : String); value.to_f?; end

    def cast_to_bool(value); !!value; end

    def cast_to_time(value : Time); value; end
    def cast_to_time(value : String); Time.parse!(value, "%F %T %z"); end
  end
end
