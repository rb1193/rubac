# frozen_string_literal: true

require_relative 'userset_rewrite'

class UsersetDifference < UsersetRewrite
  def rewrite(reader, tuple_key)
    minuend_userset = @usersets.first
    computed_minuend_userset = compute_userset minuend_userset, reader, tuple_key

    subtrahend_userset = @usersets.last
    computed_subtrahend_userset = compute_userset subtrahend_userset, reader, tuple_key

    computed_minuend_userset.filter do |minuend_tuple|
      computed_subtrahend_userset.none? do |subtrahend_tuple|
        if minuend_tuple.user.is_wildcard?
          subtrahend_tuple.user == tuple_key.user
        else
          minuend_tuple.user == subtrahend_tuple.user
        end
      end
    end
  end
end
