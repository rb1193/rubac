# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'
require 'json'

class CheckerTest < Minitest::Test
  def setup
    schema = {
      user: {},
      org: {
        member: Rubac::Relation.new
      },
      folder: {
        parent: Rubac::Relation.new,
        can_read: Rubac::Relation.new
      },
      document: {
        parent: Rubac::Relation.new,
        can_read: Rubac::Relation.new(
          Rubac::UsersetRewrite.new(
            :union,
            [
              :this,
              Rubac::TupleToUserset.new("parent", Rubac::ComputedUserset.new("can_read"))
            ]
          )
        ),
        editor: Rubac::Relation.new,
        can_write: Rubac::Relation.new(
          Rubac::UsersetRewrite.new(
            :union,
            [
              :this,
              Rubac::ComputedUserset.new("editor")
            ]
          )
        )
      }
    }

    tuples = [
      Rubac::Tuple.new(Rubac::User.new("user:alice"), "member", "org:a"),
      Rubac::Tuple.new(Rubac::User.new("user:bob"), "member", "org:b"),
      Rubac::Tuple.new(Rubac::User.new("user:*"), "can_read", "document:public"),
      Rubac::Tuple.new(Rubac::User.new("org:a#member"), "can_read", "folder:documents"),
      Rubac::Tuple.new(Rubac::User.new("folder:documents"), "parent", "document:report"),
      Rubac::Tuple.new(Rubac::User.new("folder:documents"), "parent", "folder:drafts"),
      Rubac::Tuple.new(Rubac::User.new("folder:drafts"), "parent", "document:draft_report"),
      Rubac::Tuple.new(Rubac::User.new("user:bob"), "editor", "document:plan")
    ]

    @checker = Rubac::Checker.new(tuples, schema)
  end

  def teardown
    # Do nothing
  end

  def test_direct_access
    assert @checker.check? Rubac::TupleKey.new("user:alice", "member", "org:a")
    assert !@checker.check?(Rubac::TupleKey.new("user:james", "member", "org:a"))
  end

  def test_wildcard_access
    assert @checker.check? Rubac::TupleKey.new("user:alice", "can_read", "document:public")
    assert !@checker.check?(Rubac::TupleKey.new("bot:crawler", "can_read", "document:public"))
  end

  def test_access_via_group_membership
    assert @checker.check? Rubac::TupleKey.new("user:alice", "can_read", "folder:documents")
    assert !@checker.check?(Rubac::TupleKey.new("user:bob", "can_read", "folder:documents"))
  end

  def test_access_via_intermediate_relations
    assert @checker.check? Rubac::TupleKey.new("user:alice", "can_read", "document:report")
    assert !@checker.check?(Rubac::TupleKey.new("user:alice", "can_write", "document:report"))
  end

  def test_access_via_multiple_intermediate_relations
    assert @checker.check? Rubac::TupleKey.new("user:alice", "can_read", "document:draft_report")
    assert !@checker.check?(Rubac::TupleKey.new("user:alice", "can_write", "document:draft_report"))
  end

  def test_access_via_indirect_relation
    assert @checker.check? Rubac::TupleKey.new("user:bob", "can_write", "document:plan")
  end
end
