module Crecto
  # T can be any class that defines a CHANGESET_FIELDS constant containing
  # an array of NamedTuple(name: Symbol, type: String).
  module Changeset(T)
    # Create and return a new Changeset for the given instance, first passing
    # it to the given block to perform casting and validation.
    def make_changeset(instance : T, &block)
      changeset = Changeset(T).new(instance)
      with changeset yield
      changeset
    end

    # A record containing a single validation error for a changeset field.
    alias Error = NamedTuple(field: Symbol, message: String)

    # A record containing a single constraint for a changeset field.
    alias Constraint = NamedTuple(field: Symbol, type: Symbol, name: String, message: String)

    macro extended
      macro set_changeset_fields(**fields)
        CHANGESET_FIELDS = \{{fields}}
      end
    end


    class Changeset(T)
      # The action performed with this changeset. Usually set automatically
      # by `Repo` functions like `update` or `insert`.
      property action : Symbol?
      # All errors found while validating this changeset. Errors are cleared
      # whenever `cast` is run on this changeset, or they can be cleared
      # manually. Clearing errors will _not_ make the changeset valid.
      property errors = [] of Error
      # All changes from the parameters given to this changeset and approved
      # by casting.
      property changes = {} of Symbol => DbValue | ArrayDbValue
      # List of fields with unique constraints to check.
      property constraints = [] of Constraint
      # List of fields that are required to be present in this changeset.
      property required = [] of Symbol
      # Hash of all validations applied to each field in this changeset. Fields
      # will only be present in this Hash if they have at least one validation
      # applied to them.
      property validations = {} of Symbol => Array(Symbol)

      # Indication of whether this changeset is valid.
      private property? valid = true
      # A hash representation of the initial data for this changeset, used as a
      # static and dynamically-accesible representation of an instance to avoid
      # modifying an external data while working with the changeset.
      private property data : Hash(Symbol, DbValue | ArrayDbValue)

      # Values to be considered as "empty" for this changeset. Mainly used when
      # checking presence for `validate_required`.
      property empty_values = ["", nil]


      # Initialize a changeset with data from the given instance. This method
      # expects the instance type to define a `to_query_hash` method that
      # returns a hash of fields to values for this changeset to keep.
      def initialize(instance : T)
        @data = instance.to_query_hash(true)
      end

      # Initialize a changeset directly with the given hash of data.
      def initialize(@data : Hash(Symbol, DbValue | ArrayDbValue))
      end

      # Initialize a changeset with no initial data. All values casted into
      # the changeset will then be considered changes from the initial data.
      def initialize
        @data = {} of Symbol => DbValue | ArrayDbValue
      end


      # Apply the changes stored in this changeset to the given instance,
      # regardless of whether those changes are valid. Returns the modified
      # instance directly.
      # This method may raise a runtime error if a value from the changes
      # cannot be converted to its expected type on the instance. Generally,
      # this can easily be avoided by only creating changes through `cast`,
      # where those conversions are done safely.
      def apply_changes!(instance : T)
        changes.each do |field, value|
          {% begin %}
            case field
              {% for changeset_field, type in T::CHANGESET_FIELDS %}
                when :{{changeset_field}}
                  {% expected_type = T.instance_vars.find(&.name.==(changeset_field.id)).type %}
                  instance.{{changeset_field.id}} = value.as({{expected_type}})
              {% end %}
            end
          {% end %}
        end
        instance
      end


      # Applies the values from the given attributes hash as changes in this
      # changeset. Only the fields given by `permitted` are allowed as changes
      # from the attribute hash, essentially acting as a whitelist for changes.
      def cast(attrs : Hash(Symbol, V), permitted : Array(Symbol)) : self forall V
        self.valid = true

        permitted.each do |key|
          if attrs.has_key?(key)
            self.changes[key] = attrs[key]
          end
        end
        self
      end

      def cast(attrs : Hash(String, V), permitted : Array(Symbol)) : self forall V
        self.valid = true

        permitted.each do |key|
          if attrs.has_key?(key.to_s)
            self.changes[key] = attrs[key.to_s]
          end
        end
        self
      end

      def cast(attrs : NamedTuple, permitted : Array(Symbol))
        self.valid = true

        permitted.each do |key|
          if attrs.has_key?(key.to_s)
            self.changes[key] = attrs[key.to_s]
          end
        end
        self
      end

      # Validates that the given fields are present in the changeset with a
      # value that is not considered "empty" by the changeset's `empty_values`.
      def validate_required(fields : Array(Symbol))
        @required.concat(fields)

        fields.each do |field|
          value = get_field(field)
          if @empty_values.includes?(value)
            add_error(field, "can't be blank")
          end
        end
        self
      end

      # Add a uniqueness constraint on the given field. Uniqueness constraints
      # are checked via the database using indexes. In complex cases or with
      # multiple indexes, this can be difficult to generate automatically, so
      # the `name` parameter can be given to specify the index to use for
      # validating uniqueness.
      def unique_constraint(field : Symbol, name : String? = nil)
        name ||= "some_index"
        add_constraint(field, :unique, name, message: "must be unique")
      end


      # Add an error to this changeset. Adding an error automatically sets
      # this changeset as invalid.
      def add_error(field : Symbol, message : String)
        @errors.push(Error.new(field: field, message: message))
        @valid = false
        self
      end

      # Add a constraint to this changeset. Constraints are checked via the
      # database and thus are not asserted until after talking to the database.
      def add_constraint(field : Symbol, type : Symbol, name : String, message : String)
        @constraints.push(Constraint.new(
          field: field,
          type: type,
          name: name,
          message: message
        ))
        self
      end


      private def get_field(field : Symbol)
        changes[field]? || data[field]?
      end

      private def get_change(field : Symbol)
        changes[field]?
      end
    end
  end
end
