require "test_helper"

class CollectionTest < Minitest::Test
  FakeResponse = Struct.new(:body)

  def test_from_response_uses_the_api_total_when_present
    response = FakeResponse.new({
      "data" => [ { "id" => "1" } ],
      "total" => 250,
      "pagination" => { "cursor" => "abc123" }
    })

    collection = Twitch::Collection.from_response(response, type: Twitch::Object)

    assert_equal 250, collection.total
    assert_equal "abc123", collection.cursor
  end

  def test_from_response_falls_back_to_page_size_without_a_total
    response = FakeResponse.new({ "data" => [ { "id" => "1" }, { "id" => "2" } ] })

    collection = Twitch::Collection.from_response(response, type: Twitch::Object)

    assert_equal 2, collection.total
    assert_nil collection.cursor
  end

  def test_from_response_handles_a_missing_data_key
    response = FakeResponse.new({})

    collection = Twitch::Collection.from_response(response, type: Twitch::Object)

    assert_equal [], collection.data
    assert_equal 0, collection.total
  end

  def test_from_response_reads_errors
    response = FakeResponse.new({ "data" => [], "errors" => [ { "id" => "1", "message" => "failed" } ] })

    collection = Twitch::Collection.from_response(response, type: Twitch::Object)

    assert_equal "failed", collection.errors.first.message
  end

  def test_errors_default_to_empty
    assert_equal [], Twitch::Collection.from_response(FakeResponse.new({ "data" => [] }), type: Twitch::Object).errors
    assert_equal [], Twitch::Collection.new(data: [], total: 0, cursor: nil).errors
  end

end
