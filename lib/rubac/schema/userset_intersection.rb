# frozen_string_literal: true

require_relative 'userset_rewrite'

module Rubac
  class UsersetIntersection < UsersetRewrite
    def rewrite(reader, tuple_key)
      computed_usersets = @usersets.map { |userset| compute_userset userset, reader, tuple_key }

      first_userset = computed_usersets.shift

      return [] if first_userset.nil?

      first_userset.filter do |candidate_tuple|
        computed_usersets.all? do |userset|
          userset.any? { |tuple| tuple.user == candidate_tuple.user }
        end
      end
    end
  end
end
