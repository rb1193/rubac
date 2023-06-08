# frozen_string_literal: true

module Rubac
  class Checker
    def initialize(tuples, schema)
      @tuples = tuples
      @schema = schema
    end

    # To do: implement intersection and exclusion operations
    def check? (tuple_key)
      object_relations = @schema[tuple_key.object_type.to_sym]

      matches = []
      relation = object_relations[tuple_key.relation.to_sym]

      return false unless relation

      if relation.userset_rewrite?
        case relation.userset_rewrite.operation
        when :union
          relation.userset_rewrite.usersets.each do |child|
            if child == :this
              matches.concat read tuple_key.object, tuple_key.relation
            elsif child.instance_of? ComputedUserset
              matches.concat read tuple_key.object, child.relation
            elsif child.instance_of? TupleToUserset
              object_matches = read tuple_key.object, child.relation
              object_matches.each { |tuple| matches.concat read(tuple.object, child.computed_userset.relation) }
            end
          end
        when :intersection
          return false
        else
          return false
        end
      else
        matches.concat read tuple_key.object, tuple_key.relation
      end

      # Select tuples that match the user
      matches.any? { |tuple| (tuple.user.is_wildcard? && tuple.user.type == tuple_key.user_type) || tuple.user.is?(tuple_key.user) }
    end

    def read(object, relation, collected_tuples = [])
      # Find tuples that match the object and relation provided
      new_matches = @tuples.filter do |tuple|
        tuple.object == object && (relation.nil? || tuple.relation == relation)
      end

      # For each new match, check for further matches
      new_matches.each do |tuple|
        read(
          tuple.user.qualified_id,
          tuple.user.relation,
          collected_tuples
        )
      end

      collected_tuples.concat new_matches
    end
  end
end
