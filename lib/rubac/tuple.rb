# frozen_string_literal: true

module Rubac
  class Tuple
    attr_reader :user, :relation, :object

    def initialize(user, relation, object)
      @user = user
      @relation = relation
      @object = object
    end

    # @param [Rubac::TupleKey] tuple_key
    # @return [TrueClass, FalseClass]
    def is_direct_match?(tuple_key)
      (@user.is?(tuple_key.user) || @user.is_wildcard?) && (@object == tuple_key.object) && (@relation == tuple_key.relation)
    end
  end
end
