# frozen_string_literal: true
require_relative 'userset_rewrite'

module Rubac
  class UsersetUnion < UsersetRewrite
    def rewrite(reader, tuple_key)
      @usersets.inject([]) { |matches, userset| matches.concat compute_userset(userset, reader, tuple_key) }
    end
  end
end
