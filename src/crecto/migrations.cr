module Crecto
  module Migrations
    macro extended
      @@query : String = ""
      @@adds = Array(String).new
    end

    def change(&block)
      puts yield
    end

    def create_table(table_name, &block)
      @@query += "CREATE TABLE #{table_name}(\n"
      yield
      @@query += @@adds.join(",\n")
      @@query += "\n);"
    end

    def create_if_not_exists(table_name, &block)
      @@query += "CREATE TABLE #{table_name} IF NOT EXISTS(\n"
      yield
      @@query += "\n);"
    end

    def add(field_name, field_type, **opts)
      add = "#{field_name} #{field_type_from_sym(field_type)}"

      add += add_opts(opts)

      @@adds.push add
    end

    def add_opts(opts)
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
