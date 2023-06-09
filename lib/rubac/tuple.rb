# frozen_string_literal: true

module Rubac
  class Tuple
    attr_reader :user, :relation, :object

    def initialize(user, relation, object)
      @user = user
      @relation = relation
      @object = object
    end

    def ==(other)
      other.class == self.class && other.object == object && other.relation == relation && other.user == user
    end
  end
end
