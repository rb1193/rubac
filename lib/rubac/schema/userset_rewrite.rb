# frozen_string_literal: true

module Rubac
  class UsersetRewrite
    attr_reader :operation, :usersets

    def initialize(operation, usersets)
      @operation = operation
      @usersets = usersets
    end
  end
end
