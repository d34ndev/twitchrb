require "test_helper"

class ModeratorsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_moderators_create_sends_ids_in_query
    stub_helix(:post, "moderation/moderators",
      query: { "broadcaster_id" => "123", "user_id" => "9876" },
      request_body: {},
      status: 204, body: "")

    assert_equal true, @client.moderators.create(broadcaster_id: "123", user_id: "9876")
  end
end
