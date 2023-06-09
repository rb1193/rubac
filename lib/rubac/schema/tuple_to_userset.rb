# frozen_string_literal: true

class TupleToUserset
  attr_reader :relation, :computed_userset

  def initialize(relation, computed_userset)
    @relation = relation
    @computed_userset = computed_userset
  end
end
