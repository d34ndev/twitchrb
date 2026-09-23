require "test_helper"

class WhispersResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_whispers_create_sends_user_ids_in_query_and_message_in_body
    stub_helix(:post, "whispers",
      query: { "from_user_id" => "123", "to_user_id" => "456" },
      request_body: { message: "hello" },
      status: 204, body: "")

    assert_equal true, @client.whispers.create(from_user_id: "123", to_user_id: "456", message: "hello")
  end
end
