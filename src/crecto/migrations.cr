module Crecto
  module Migrations
    macro extended
      @@migration : String = ""
      @@adds = Array(String).new
      @@change : String = ""
    end

    def change(&block)
      @@change = yield
    end

    def get_change
      @@change  
    end

    def create_table(table_name, &block)
      @@migration += "CREATE TABLE #{table_name}(\n"
      yield
      @@migration += @@adds.join(",\n")
      @@migration += "\n);"
    end

    def create_if_not_exists(table_name, &block)
      @@migration += "CREATE TABLE #{table_name} IF NOT EXISTS(\n"
      yield
      @@migration += "\n);"
    end

    def add(field_name, field_type, **opts)
      add = "#{field_name} #{field_type_from_sym(field_type)}"

      add += add_field_opts(opts)

      @@adds.push add
    end

    def add_field_opts(opts)
      x = ""
      unique = opts[:unique]?
      x += " UNIQUE" if unique == true

      null = opts[:null]?
      x += " NOT NULL" if null == false

      default = opts[:default]?
      x += " DEFAULT #{default}" unless default.nil?
      x
    end

    def field_type_from_sym(field_type)
      case field_type
      when :string
        "character varying"
      when :integer
        "integer"
      when :float
        "float"
      end
    end

    def timestamps
      @@adds.push "created_at timestamp without time zone NOT NULL"
      @@adds.push "created_at timestamp without time zone NOT NULL"
    end
  end
end
