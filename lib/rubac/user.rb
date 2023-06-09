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

    def ==(other)
      if other.instance_of? String
        other == to_s
      else
        other.class == self.class && other.type == type && other.id == id && other.relation == relation
      end
    end

    def to_s
      result = "#{@type}:#{@id}"
      result += "##{@relation}" if @relation
      result
    end
  end
end
