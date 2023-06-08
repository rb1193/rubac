# frozen_string_literal: true

require_relative "rubac/version"

module Rubac
  require "rubac/tuple_key"
  require "rubac/user"
  require "rubac/tuple"

  require "rubac/schema/computed_userset"
  require "rubac/schema/tuple_to_userset"

  require "rubac/schema/userset_difference"
  require "rubac/schema/userset_intersection"
  require "rubac/schema/userset_rewrite"
  require "rubac/schema/userset_union"

  require "rubac/schema/relation"

  require "rubac/checker"
end
