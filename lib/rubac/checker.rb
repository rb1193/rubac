# frozen_string_literal: true

module Rubac
  class Checker
    def initialize(tuples)
      @tuples = tuples
    end

    # @param [Rubac::TupleKey] tuple_key
    # @return [bool]
    def check?(tuple_key)
      # Get initial set of tuples that match on the object and the relation
      matches = direct_object_matches tuple_key

      # Get additional tuples that match the object via relationships
      matches.concat related_object_matches(tuple_key.object)

      # Rewrite any tuples that specify usersets so that a tuple is created for each user in the set
      rewrite_usersets(matches)

      # Select tuples that match the user
      matches.any? { |tuple| (tuple.user.is_wildcard? || tuple.user.is?(tuple_key.user)) && (tuple.relation == tuple_key.relation) }
    end

    private

    def direct_object_matches(tuple_key)
      @tuples.filter do |tuple|
        key_user = Rubac::User.new(tuple_key.user)
        tuple.object == tuple_key.object && tuple.relation == tuple_key.relation && (
          !key_user.is_userset? || key_user.relation == tuple.relation
        )
      end
    end

    def related_object_matches(object, collected_tuples = [])
      # Find tuples that match the latest key object
      new_matches = @tuples.filter do |tuple|
        tuple.object == object
      end

      # For each new match, investigate the tuples to see whether there are potential further matches
      new_matches.each do |tuple|
        related_object_matches(
          tuple.user.qualified_id,
          collected_tuples
        )
      end

      collected_tuples.concat new_matches
    end

    def rewrite_usersets(tuples)
      tuples.map! do |subject_tuple|
        next subject_tuple unless subject_tuple.user.is_userset?

        rewritten_tuples = []
        @tuples.each do |object_tuple|
          if subject_tuple.user.qualified_id == object_tuple.object && subject_tuple.user.relation == object_tuple.relation
            rewritten_tuples << Rubac::Tuple.new(object_tuple.user, subject_tuple.relation, subject_tuple.object)
          end
        end
        rewritten_tuples.empty? ? subject_tuple : rewritten_tuples
      end
      tuples.flatten!

      rewrite_usersets(tuples) if tuples.any? { |tuple| tuple.user.is_userset? }
    end
  end
end
