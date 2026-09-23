require "test_helper"

class ChatSettingsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_chat_settings_retrieve
    stub_helix(:get, "chat/settings", query: { "broadcaster_id" => "123" },
      body: { data: [ { broadcaster_id: "123", slow_mode: true, slow_mode_wait_time: 30 } ] }.to_json)

    settings = @client.chat_settings.retrieve(broadcaster_id: "123")

    assert_instance_of Twitch::ChatSettings, settings
    assert_equal 30, settings.slow_mode_wait_time
  end

  def test_chat_settings_retrieve_with_moderator
    stub_helix(:get, "chat/settings", query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      body: { data: [ { broadcaster_id: "123", non_moderator_chat_delay: true } ] }.to_json)

    assert_equal true, @client.chat_settings.retrieve(broadcaster_id: "123", moderator_id: "321").non_moderator_chat_delay
  end

  def test_chat_settings_update_sends_ids_in_query
    stub_helix(:patch, "chat/settings",
      query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      request_body: { slow_mode: true, slow_mode_wait_time: 10 },
      body: { data: [ { broadcaster_id: "123", slow_mode: true, slow_mode_wait_time: 10 } ] }.to_json)

    settings = @client.chat_settings.update(broadcaster_id: "123", moderator_id: "321", slow_mode: true, slow_mode_wait_time: 10)

    assert_instance_of Twitch::ChatSettings, settings
    assert_equal 10, settings.slow_mode_wait_time
  end
end
