# frozen_string_literal: true

module Rubac
  class ComputedUserset
    attr_reader :relation

    def initialize(relation)
      @relation = relation
    end
  end
end
