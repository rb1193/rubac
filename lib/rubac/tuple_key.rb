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
      object.split(":").first or raise InvalidTupleKeyError.invalid_object object
    end

    def user_type
      user.split(":").first or raise InvalidTupleKeyError.invalid_user user
    end

    def to_s
      "{ user: #{@user}, relation: #{@relation}, object: #{@object} }"
    end
  end

  class InvalidTupleKeyError < StandardError
    def invalid_object(tuple_key)
      new("Invalid object value: #{tuple_key.object}")
    end

    def invalid_user(tuple_key)
      new("Invalid user value: #{tuple_key.user}")
    end
  end
end
