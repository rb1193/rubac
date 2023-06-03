# frozen_string_literal: true

module Rubac
  class User
    attr_reader :type, :id, :relation

    # @param [String] user_string
    def initialize(user_string)
      type_and_userset = user_string.split ":"
      @type = type_and_userset.first
      id_and_relation = type_and_userset.last.split "#"
      @id = id_and_relation.first
      @relation = id_and_relation.last if id_and_relation.length > 1
    end

    def qualified_id
      "#{type}:#{id}"
    end

    def is_userset?
      !@relation.nil?
    end

    def is_wildcard?
      @id == "*"
    end

    def is?(user)
      to_s == user
    end

    def to_s
      result = "#{@type}:#{@id}"
      result += "##{@relation}" if @relation
      result
    end
  end
end
