# frozen_string_literal: true

require 'test_helper'

class CheckerTest < Minitest::Test
  include Rubac
  def setup
    schema = {
      user: {},
      org: {
        member: Relation.new
      },
      folder: {
        editor: Relation.new,
        parent: Relation.new,
        can_read: Relation.new
      },
      document: {
        author: Relation.new,
        parent: Relation.new,
        can_read: Relation.new(
          UsersetUnion.new(
            [
              :this,
              TupleToUserset.new("parent", ComputedUserset.new("can_read"))
            ]
          )
        ),
        can_write: Relation.new(
          UsersetUnion.new(
            [
              :this,
              TupleToUserset.new("parent", ComputedUserset.new("editor")),
            ]
          )
        ),
        can_delete: Relation.new(
          UsersetIntersection.new(
            [
              TupleToUserset.new("parent", ComputedUserset.new("editor")),
              ComputedUserset.new("author")
            ]
          )
        ),
        blocked: Relation.new,
        is_not_blocked: Relation.new(
          UsersetDifference.new(
            [
              ComputedUserset.new("can_read"),
              ComputedUserset.new("blocked")
            ]
          )
        )
      }
    }

    tuples = [
      Tuple.new(User.new("user:alice"), "member", "org:a"),
      Tuple.new(User.new("user:bob"), "member", "org:b"),
      Tuple.new(User.new("user:*"), "can_read", "document:public"),
      Tuple.new(User.new("org:a#member"), "can_read", "folder:documents"),
      Tuple.new(User.new("folder:documents"), "parent", "document:report"),
      Tuple.new(User.new("folder:documents"), "parent", "folder:drafts"),
      Tuple.new(User.new("folder:drafts"), "parent", "document:draft_report"),
      Tuple.new(User.new("folder:plans"), "parent", "document:plan"),
      Tuple.new(User.new("user:bob"), "editor", "folder:plans"),
      Tuple.new(User.new("user:james"), "author", "document:plan"),
      Tuple.new(User.new("user:james"), "editor", "folder:plans"),
      Tuple.new(User.new("user:mary"), "blocked", "document:public"),
    ]

    @checker = Checker.new(schema)

    tuples.each { |tuple| @checker.write tuple}
  end

  def teardown
    # Do nothing
  end

  def test_direct_access
    assert @checker.check? TupleKey.new("user:alice", "member", "org:a")
    assert !@checker.check?(TupleKey.new("user:james", "member", "org:a"))
  end

  def test_wildcard_access
    assert @checker.check? TupleKey.new("user:alice", "can_read", "document:public")
    assert !@checker.check?(TupleKey.new("bot:crawler", "can_read", "document:public"))
  end

  def test_access_via_group_membership
    assert @checker.check? TupleKey.new("user:alice", "can_read", "folder:documents")
    assert !@checker.check?(TupleKey.new("user:bob", "can_read", "folder:documents"))
  end

  def test_access_via_intermediate_relations
    assert @checker.check? TupleKey.new("user:alice", "can_read", "document:report")
    assert !@checker.check?(TupleKey.new("user:alice", "can_write", "document:report"))
  end

  def test_access_via_multiple_intermediate_relations
    assert @checker.check? TupleKey.new("user:alice", "can_read", "document:draft_report")
    assert !@checker.check?(TupleKey.new("user:alice", "can_write", "document:draft_report"))
  end

  def test_access_via_indirect_relation
    assert @checker.check? TupleKey.new("user:bob", "can_write", "document:plan")
  end

  def test_access_requiring_two_relations
    assert @checker.check? TupleKey.new("user:james", "can_delete", "document:plan")
    assert !@checker.check?(TupleKey.new("user:bob", "can_delete", "document:plan"))
  end

  def test_blocklisting
    assert @checker.check? TupleKey.new("user:alice", "is_not_blocked", "document:public")
    assert !@checker.check?(TupleKey.new("user:mary", "is_not_blocked", "document:public"))
  end

  def test_writing_raises_an_error_if_tuple_already_exists
    assert_raises TupleExistsError do
      @checker.write(Tuple.new(User.new("user:alice"), "member", "org:a"))
    end
  end

  def test_deleting_a_tuple
    tuple = Tuple.new(User.new("user:ali"), "member", "org:a")
    tuple_key = TupleKey.new("user:ali", "member", "org:a")
    @checker.write tuple
    assert @checker.check? tuple_key
    @checker.destroy tuple
    assert !@checker.check?(tuple_key)
  end

  def test_deleting_a_tuple_raises_an_error_if_the_tuple_does_not_exist
    tuple = Tuple.new(User.new("user:sam"), "member", "org:a")
    assert_raises MissingTupleError do
      @checker.destroy tuple
    end
  end
end
