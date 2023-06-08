# frozen_string_literal: true

module Rubac
  class TupleKey
    attr_accessor :user, :relation, :object

    def initialize (user, relation, object)
      @user = user
      @relation = relation
      @object = object
    end

    def object_type
      object.split(":").first or raise InvalidTupleKeyError
    end

    def user_type
      user.split(":").first or raise InvalidTupleKeyError
    end

    def to_s
      "{ user: #{@user}, relation: #{@relation}, object: #{@object} }"
    end
  end

  class InvalidTupleKeyError < Rubac::Error; end
end
