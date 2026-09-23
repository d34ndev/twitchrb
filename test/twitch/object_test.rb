require "test_helper"

class ObjectTest < Minitest::Test
  def test_creating_object_from_hash
    assert_equal "bar", Twitch::Object.new(foo: "bar").foo
  end

  def test_nested_hash
    assert_equal "foobar", Twitch::Object.new(foo: { bar: { baz: "foobar" } }).foo.bar.baz
  end

  def test_nested_number
    assert_equal 1, Twitch::Object.new(foo: { bar: 1 }).foo.bar
  end

  def test_array
    object = Twitch::Object.new(foo: [ { bar: :baz } ])
    assert_equal OpenStruct, object.foo.first.class
    assert_equal :baz, object.foo.first.bar
  end

  def test_empty_hash
    object = Twitch::Object.new({})
    refute_nil object
  end

  def test_nil_values
    object = Twitch::Object.new(foo: nil, bar: "baz")
    assert_nil object.foo
    assert_equal "baz", object.bar
  end

  def test_boolean_values
    object = Twitch::Object.new(is_live: true, is_mature: false)
    assert_equal true, object.is_live
    assert_equal false, object.is_mature
  end

  def test_mixed_array_types
    object = Twitch::Object.new(data: [ "string", 123, { nested: "value" }, true ])
    assert_equal "string", object.data[0]
    assert_equal 123, object.data[1]
    assert_equal "value", object.data[2].nested
    assert_equal true, object.data[3]
  end

  def test_deeply_nested_structure
    complex_data = {
      user: {
        id: "123",
        profile: {
          settings: {
            notifications: {
              email: true,
              push: false
            }
          }
        }
      }
    }
    object = Twitch::Object.new(complex_data)
    assert_equal "123", object.user.id
    assert_equal true, object.user.profile.settings.notifications.email
    assert_equal false, object.user.profile.settings.notifications.push
  end

  def test_string_keys_and_symbol_keys
    object = Twitch::Object.new("string_key" => "value1", symbol_key: "value2")
    assert_equal "value1", object.string_key
    assert_equal "value2", object.symbol_key
  end

  def test_to_h_converts_nested_objects_to_hashes
    object = Twitch::Object.new("id" => "1", "settings" => { "slow_mode" => true }, "items" => [ { "a" => 1 }, 2 ])

    assert_equal({ id: "1", settings: { slow_mode: true }, items: [ { a: 1 }, 2 ] }, object.to_h)
  end

  def test_to_h_with_block
    object = Twitch::Object.new("id" => "1", "name" => "test")

    assert_equal({ "id" => "1", "name" => "test" }, object.to_h { |key, value| [ key.to_s, value ] })
  end

  def test_to_json_serializes_nested_objects
    object = Twitch::Object.new("id" => "1", "settings" => { "slow_mode" => true }, "items" => [ { "a" => 1 } ])

    assert_equal({ "id" => "1", "settings" => { "slow_mode" => true }, "items" => [ { "a" => 1 } ] }, JSON.parse(object.to_json))
  end

  def test_to_json_works_inside_other_structures
    users = [ Twitch::User.new("id" => "1", "images" => { "profile" => "url" }) ]

    assert_equal [ { "id" => "1", "images" => { "profile" => "url" } } ], JSON.parse(users.to_json)
  end

  def test_as_json_returns_nested_hash
    object = Twitch::Object.new("settings" => { "slow_mode" => true })

    assert_equal({ settings: { slow_mode: true } }, object.as_json)
  end
end
