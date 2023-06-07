# frozen_string_literal: true

require_relative "rubac/version"

module Rubac
  require "rubac/checker"
  require "rubac/schema/computed_userset"
  require "rubac/schema/tuple_to_userset"
  require "rubac/tuple"
  require "rubac/tuple_key"
  require "rubac/user"
  class Error < StandardError; end

end
