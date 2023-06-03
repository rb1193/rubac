# frozen_string_literal: true

module Rubac
  class TupleKey
    attr_accessor :user, :relation, :object

    def initialize (user, relation, object)
      @user = user
      @relation = relation
      @object = object
    end

    def to_s
      "{ user: #{@user}, relation: #{@relation}, object: #{@object} }"
    end
  end
end
