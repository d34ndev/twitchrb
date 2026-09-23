require "test_helper"

class RaidsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_raids_create_sends_ids_in_query
    stub_helix(:post, "raids",
      query: { "from_broadcaster_id" => "123", "to_broadcaster_id" => "456" },
      request_body: {},
      body: { data: [ { created_at: "2026-09-23T12:00:00Z", is_mature: false } ] }.to_json)

    raid = @client.raids.create(from_broadcaster_id: "123", to_broadcaster_id: "456")

    assert_instance_of Twitch::Raid, raid
    assert_equal false, raid.is_mature
  end
end
