# frozen_string_literal: true
require_relative 'computed_userset'
require_relative 'tuple_to_userset'

module Rubac
  class UsersetRewrite
    attr_reader :usersets

    def initialize(usersets)
      @usersets = usersets
    end

    def rewrite(reader, tuple_key)
      raise StandardError "Failed to implement rewrite method on userset"
    end

    private

    def compute_userset(userset, reader, tuple_key)
      if userset == :this
        reader.read(tuple_key.object, tuple_key.relation)
      elsif userset.instance_of? ComputedUserset
        reader.read(tuple_key.object, userset.relation)
      elsif userset.instance_of? TupleToUserset
        intermediate_matches = reader.read tuple_key.object, userset.relation
        intermediate_matches.map! { |tuple| reader.read(tuple.object, userset.computed_userset.relation) }.flatten
      end
    end
  end
end
