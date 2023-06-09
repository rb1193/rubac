# frozen_string_literal: true

class Relation
  attr_reader :userset_rewrite

  def initialize(userset_rewrite = nil)
    @userset_rewrite = userset_rewrite
  end

  def userset_rewrite?
    !@userset_rewrite.nil?
  end

  def matching_tuples(reader, tuple_key)
    if userset_rewrite.nil?
      reader.read tuple_key.object, tuple_key.relation
    else
      @userset_rewrite.rewrite reader, tuple_key
    end
  end
end
