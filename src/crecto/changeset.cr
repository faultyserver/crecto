module Crecto
  module Changeset(T)
    def make_changeset(instance : T, &block)
      changeset = Changeset(T).new(instance)
      with changeset yield
      changeset
    end

    # A record containing a single validation error for a changeset field.
    alias Error = NamedTuple(field: Symbol, message: String)

    # A record containing a single constraint for a changeset field.
    alias Constraint = NamedTuple(field: Symbol, type: Symbol, name: String, message: String)

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
      # A hash representation of the instance behind this changeset, used as a
      # static and dynamically-accesible representation of the instance.
      private property data : Hash(Symbol, DbValue | ArrayDbValue)
      # A reference to the instance behind this changeset. Generally this is
      # a read-only property.
      private getter instance : T

      # Values to be considered as "empty" for this changeset. Mainly used when
      # checking presence for `validate_required`.
      property empty_values = ["", nil]


      def initialize(@instance : T)
        @data = @instance.to_query_hash(true)
      end


      def cast(attrs : Hash(Symbol, V), permitted : Array(Symbol)) : self forall V
        @valid = true

        permitted.each do |key|
          if given_value = attrs[key]?
            changes[key] = given_value
          end
        end
        self
      end

      def cast(attrs : Hash(String, V), permitted : Array(Symbol)) : self forall V
        @valid = true

        permitted.each do |key|
          if given_value = attrs[key.to_s]?
            changes[key] = given_value
          end
        end
        self
      end

      def cast(attrs : NamedTuple, permitted : Array(Symbol))
        @valid = true

        permitted.each do |key|
          if given_value = attrs[key]?
            changes[key] = given_value
          end
        end
        self
      end


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
        add_constraint(field, :unique, "uniqueness constraint #{name}", message: "must be unique")
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
    end
  end
end
