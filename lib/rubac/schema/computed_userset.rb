# frozen_string_literal: true

class ComputedUserset
  attr_reader :relation

  def initialize(relation)
    @relation = relation
  end
end
