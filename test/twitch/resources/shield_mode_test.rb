require "test_helper"

class ShieldModeResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_shield_mode_retrieve
    stub_helix(:get, "moderation/shield_mode", query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      body: { data: [ { is_active: false, moderator_id: "321" } ] }.to_json)

    status = @client.shield_mode.retrieve(broadcaster_id: "123", moderator_id: "321")

    assert_instance_of Twitch::ShieldModeStatus, status
    assert_equal false, status.is_active
  end

  def test_shield_mode_update_sends_ids_in_query
    stub_helix(:put, "moderation/shield_mode",
      query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      request_body: { is_active: true },
      body: { data: [ { is_active: true, moderator_id: "321" } ] }.to_json)

    status = @client.shield_mode.update(broadcaster_id: "123", moderator_id: "321", is_active: true)

    assert_equal true, status.is_active
  end
end
