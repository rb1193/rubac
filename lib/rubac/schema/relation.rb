# frozen_string_literal: true

module Rubac
  class Relation
    attr_reader :userset_rewrite

    def initialize(userset_rewrite = nil)
      @userset_rewrite = userset_rewrite
    end

    def userset_rewrite?
      !@userset_rewrite.nil?
    end
  end
end
