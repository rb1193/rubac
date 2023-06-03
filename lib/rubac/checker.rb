# frozen_string_literal: true

module Rubac
  class Checker
    # @param [Rubac::Tuple] valid_tuples
    def initialize(valid_tuples)
      @tuples = valid_tuples
    end

    # @param [Rubac::TupleKey] tuple_key
    # @return [bool]
    def check?(tuple_key)
      matching_tuples = @tuples.filter do |tuple|
        key_user = Rubac::User.new(tuple_key.user)
        tuple.object == tuple_key.object && tuple.relation == tuple_key.relation && (
          !key_user.is_userset? || key_user.relation == tuple.relation
        )
      end

      return true if matching_tuples.any? do |tuple|
        tuple.user.is_wildcard? || tuple.user.is?(tuple_key.user)
      end

      # Evaluate remaining relations - time to add a test requiring this to be recursive
      @tuples.any? do |tuple|
        if tuple.user.is_userset? && (tuple.object == tuple_key.object) && (tuple.relation == tuple_key.relation)
          return @tuples.any? do |searched_tuple|
            searched_tuple.user.is?(tuple_key.user) and tuple.user.qualified_id == searched_tuple.object and searched_tuple.relation == tuple.user.relation
          end
        end

        if tuple.user.is?(tuple_key.user) && (tuple.relation == tuple_key.relation)
          return true if @tuples.any? do |searched_tuple|
            next if tuple == searched_tuple

            searched_tuple.user.is?(tuple.object) && searched_tuple.object == tuple_key.object
          end
        end
      end
    end
  end
end
