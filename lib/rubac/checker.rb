# frozen_string_literal: true

module Rubac
  class Checker
    def initialize(tuples, schema)
      @tuples = tuples
      @schema = schema
    end

    def check? (tuple_key)
      object_relations = @schema[tuple_key.object_type.to_sym]

      matches = []
      relation = object_relations[tuple_key.relation.to_sym]

      return false unless relation

      if relation.include?(:userset_rewrite)
        if relation[:userset_rewrite].include? :union
          relation[:userset_rewrite][:union].each do |child|
            if child == :this
              matches.concat read tuple_key.object, tuple_key.relation
            elsif child.include? :computed_userset
              object_matches = read tuple_key.object, child[:relation]
              object_matches.each { |tuple| matches.concat read(tuple.object, tuple.relation) }
            else
              matches.concat read tuple_key.object, child[:relation]
            end
          end
        elsif relation[:userset_rewrite].include? :intersection
          return false
        end
      else
        matches.concat read tuple_key.object, tuple_key.relation
      end

      # Select tuples that match the user
      matches.any? { |tuple| (tuple.user.is_wildcard? || tuple.user.is?(tuple_key.user)) }
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
