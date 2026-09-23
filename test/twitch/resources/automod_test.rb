require "test_helper"

class AutomodResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_automod_check_status_sends_broadcaster_id_in_query
    stub_helix(:post, "moderation/enforcements/status",
      query: { "broadcaster_id" => "123" },
      request_body: { data: [ { msg_id: "msg-1", msg_text: "hello" } ] },
      body: { data: [ { msg_id: "msg-1", is_permitted: true } ] }.to_json)

    status = @client.automod.check_status(broadcaster_id: "123", id: "msg-1", text: "hello")

    assert_instance_of Twitch::AutomodStatus, status
    assert_equal true, status.is_permitted
  end

  def test_automod_check_status_multiple_sends_broadcaster_id_in_query
    messages = [ { msg_id: "msg-1", msg_text: "hello" }, { msg_id: "msg-2", msg_text: "world" } ]
    stub_helix(:post, "moderation/enforcements/status",
      query: { "broadcaster_id" => "123" },
      request_body: { data: messages },
      body: { data: [ { msg_id: "msg-1", is_permitted: true }, { msg_id: "msg-2", is_permitted: false } ] }.to_json)

    statuses = @client.automod.check_status_multiple(broadcaster_id: "123", messages: messages)

    assert_instance_of Twitch::Collection, statuses
    assert_equal [ true, false ], statuses.map(&:is_permitted)
  end

  def test_automod_update_settings_sends_ids_in_query
    stub_helix(:put, "moderation/automod/settings",
      query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      request_body: { overall_level: 3 },
      body: { data: [ { broadcaster_id: "123", overall_level: 3 } ] }.to_json)

    settings = @client.automod.update_settings(broadcaster_id: "123", moderator_id: "321", overall_level: 3)

    assert_instance_of Twitch::AutomodSetting, settings
    assert_equal 3, settings.overall_level
  end
end
