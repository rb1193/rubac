# frozen_string_literal: true

module Rubac
  class Tuple
    attr_reader :user, :relation, :object

    def initialize(user, relation, object)
      @user = user
      @relation = relation
      @object = object
    end
  end
end
