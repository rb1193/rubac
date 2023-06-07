# frozen_string_literal: true

require 'minitest/autorun'
require 'test_helper'
require 'json'

class CheckerTest < Minitest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  # Next tests:
  # wildcards e.g. user:*
  # introduce groups
  # principle of least permission (using blocklist?)
  def test_it_checks_if_a_user_can_access_an_object_via_direct_access
    schema = {
      user: {},
      object: {
        can_read: {},
        can_write: {}
      }
    }

    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:foo"),
        "can_read",
        "object:1"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("user:baz"),
        "can_read",
        "object:1"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("user:baz"),
        "can_read",
        "object:3"
      )
    ]

    valid_tuple_keys = tuples.map { |tuple| Rubac::TupleKey.new(tuple.user.to_s, tuple.relation, tuple.object) }

    tuples << Rubac::Tuple.new(
      Rubac::User.new("user:*"),
      "can_write",
      "object:4"
    )

    valid_tuple_keys << Rubac::TupleKey.new("user:foo", "can_write", "object:4")

    invalid_tuple_keys = [
      Rubac::TupleKey.new("user:bar", "can_read", "object:1"),
      Rubac::TupleKey.new("user:foo", "can_read", "object:2"),
      Rubac::TupleKey.new("user:foo", "can_write", "object:1"),
      Rubac::TupleKey.new("user:foo", "can_read", "object:3"),
    ]

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid checker, valid_tuple_keys
    assert_all_tuple_keys_are_invalid(checker, invalid_tuple_keys)
  end

  def test_it_checks_if_a_user_has_a_relation_to_an_object_via_group_membership
    schema = {
      user: {},
      group: {
        member: {},
        admin: {}
      },
      object:
        {
          can_write: {
            userset_rewrite: {
              union: [
                :this,
                Rubac::ComputedUserset.new("member"),
                Rubac::ComputedUserset.new("admin")
              ]
            }
          },
          can_delete: {
            userset_rewrite: {
              union: [
                :this,
                Rubac::ComputedUserset.new("admin")
              ]
            }
          }
        }
    }

    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:alice"),
        "member",
        "group:one"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("user:bob"),
        "member",
        "group:two"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("group:one#member"),
        "can_write",
        "object:1"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("user:tim"),
        "admin",
        "group:one"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("group:one#admin"),
        "can_delete",
        "object:1"
      )
    ]

    valid_tuple_keys = [
      Rubac::TupleKey.new("user:alice", "can_write", "object:1"),
      Rubac::TupleKey.new("user:tim", "can_delete", "object:1")
    ]

    invalid_tuple_keys = [
      Rubac::TupleKey.new("user:bob", "can_write", "object:1"),
      Rubac::TupleKey.new("user:alice", "can_delete", "object:1")
    ]

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid checker, valid_tuple_keys
    assert_all_tuple_keys_are_invalid checker, invalid_tuple_keys
  end

  def test_it_checks_if_a_user_has_a_relation_to_an_object_via_another_object
    schema = {
      user: {},
      folder: {
        editor: {}
      },
      document: {
        parent: {},
        editor: {
          userset_rewrite: {
            union: [
              :this,
              Rubac::TupleToUserset.new("parent", Rubac::ComputedUserset.new("editor"))
            ]
          }
        }
      }
    }

    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:bob"),
        "editor",
        "folder:documents"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("folder:documents"),
        "parent",
        "document:foo"
      )
    ]

    valid_tuple_keys = [
      Rubac::TupleKey.new("user:bob", "editor", "document:foo")
    ]

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid(checker, valid_tuple_keys)
  end

  def test_it_checks_if_a_user_has_a_relation_to_an_object_via_more_than_one_other_object()
    schema = {
      user: {},
      folder: {
        parent: {},
        editor: {}
      },
      document: {
        parent: {},
        editor: {
          userset_rewrite: {
            union: [
              :this,
              Rubac::TupleToUserset.new("parent", Rubac::ComputedUserset.new("editor"))
            ]
          }
        }
      }
    }

    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:bob"),
        "editor",
        "folder:documents"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("folder:documents"),
        "parent",
        "folder:drafts"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("folder:drafts"),
        "parent",
        "document:foo"
      )
    ]

    valid_tuple_keys = [
      Rubac::TupleKey.new("user:bob", "editor", "document:foo")
    ]
    invalid_tuple_keys = [
      Rubac::TupleKey.new("user:bob", "owner", "document:foo")
    ]

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid(checker, valid_tuple_keys)
    assert_all_tuple_keys_are_invalid(checker, invalid_tuple_keys)
  end

  def test_it_checks_if_a_user_has_a_relation_to_an_object_via_child_group_membership()
    schema = {
      user: {},
      org: {
        member: {}
      },
      folder: {
        parent: {},
        can_read: {}
      },
      document: {
        parent: {},
        can_read: {
          userset_rewrite: {
            union: [
              :this,
              Rubac::TupleToUserset.new("parent", Rubac::ComputedUserset.new("can_read"))
            ]
          }
        },
        can_write: {
          userset_rewrite: {
            union: [
              :this,
              Rubac::TupleToUserset.new("parent", Rubac::ComputedUserset.new("can_write"))
            ]
          }
        }
      }
    }

    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:alice"),
        "member",
        "org:two"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("org:one#member"),
        "can_read",
        "folder:documents"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("org:two#member"),
        "member",
        "org:one"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("folder:documents"),
        "parent",
        "folder:drafts"
      ),
      Rubac::Tuple.new(
        Rubac::User.new("folder:drafts"),
        "parent",
        "document:foo"
      )
    ]

    valid_tuple_keys = [
      Rubac::TupleKey.new("user:alice", "can_read", "document:foo")
    ]

    invalid_tuple_keys = [
      Rubac::TupleKey.new("user:bob", "can_read", "document:foo"),
      Rubac::TupleKey.new("user:alice", "can_write", "document:foo")
    ]

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid(checker, valid_tuple_keys)
    assert_all_tuple_keys_are_invalid(checker, invalid_tuple_keys)
  end

  def test_it_applies_the_provided_schema_when_checking_direct_access
    tuples = [
      Rubac::Tuple.new(
        Rubac::User.new("user:foo"),
        "editor",
        "object:1"
      )
    ]

    valid_tuple_keys = [
      Rubac::TupleKey.new("user:foo", "can_read", "object:1")
    ]

    schema = {
      object: {
        editor: {},
        can_read: {
          userset_rewrite: {
            union: [
              :this,
              Rubac::ComputedUserset.new("editor")
            ]
          }
        }
      }
    }

    checker = Rubac::Checker.new(tuples, schema)

    assert_all_tuple_keys_are_valid checker, valid_tuple_keys
  end

  private

  def assert_all_tuple_keys_are_invalid(checker, invalid_tuple_keys)
    invalid_tuple_keys.each { |key| assert(!checker.check?(key), "Failed on #{key}") }
  end

  def assert_all_tuple_keys_are_valid(checker, valid_tuple_keys)
    valid_tuple_keys.each { |key| assert(checker.check?(key), "Failed on #{key}") }
  end
end
