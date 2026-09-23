require "test_helper"

class GuestStarResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_guest_star_settings
    stub_helix(:get, "guest_star/channel_settings", query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      body: { data: [ { slot_count: 4, is_moderator_send_live_enabled: true } ] }.to_json)

    settings = @client.guest_star.settings(broadcaster_id: "123", moderator_id: "321")

    assert_instance_of Twitch::GuestStarSettings, settings
    assert_equal 4, settings.slot_count
  end

  def test_guest_star_update_settings_sends_broadcaster_id_in_query
    stub_helix(:put, "guest_star/channel_settings", query: { "broadcaster_id" => "123" }, request_body: { slot_count: 3 },
      status: 204, body: "")

    assert_equal true, @client.guest_star.update_settings(broadcaster_id: "123", slot_count: 3)
  end

  def test_guest_star_session
    stub_helix(:get, "guest_star/session", query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      body: { data: [ { id: "sess-1", guests: [ { slot_id: "0", user_id: "123" } ] } ] }.to_json)

    session = @client.guest_star.session(broadcaster_id: "123", moderator_id: "321")

    assert_instance_of Twitch::GuestStarSession, session
    assert_equal "123", session.guests.first.user_id
  end

  def test_guest_star_session_returns_nil_when_none_active
    stub_helix(:get, "guest_star/session", query: { "broadcaster_id" => "123", "moderator_id" => "321" }, body: { data: [] }.to_json)

    assert_nil @client.guest_star.session(broadcaster_id: "123", moderator_id: "321")
  end

  def test_guest_star_create_session
    stub_helix(:post, "guest_star/session", query: { "broadcaster_id" => "123" }, request_body: {},
      body: { data: [ { id: "sess-1", guests: [] } ] }.to_json)

    assert_equal "sess-1", @client.guest_star.create_session(broadcaster_id: "123").id
  end

  def test_guest_star_end_session
    stub_helix(:delete, "guest_star/session", query: { "broadcaster_id" => "123", "session_id" => "sess-1" },
      body: { data: [ { id: "sess-1", guests: [] } ] }.to_json)

    assert_equal "sess-1", @client.guest_star.end_session(broadcaster_id: "123", session_id: "sess-1").id
  end

  def test_guest_star_invites
    stub_helix(:get, "guest_star/invites", query: { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1" },
      body: { data: [ { user_id: "9876", status: "INVITED" } ] }.to_json)

    invites = @client.guest_star.invites(broadcaster_id: "123", moderator_id: "321", session_id: "sess-1")

    assert_instance_of Twitch::GuestStarInvite, invites.first
    assert_equal "INVITED", invites.first.status
  end

  def test_guest_star_send_and_delete_invite
    query = { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1", "guest_id" => "9876" }
    stub_helix(:post, "guest_star/invites", query: query, request_body: {}, status: 204, body: "")
    stub_helix(:delete, "guest_star/invites", query: query, status: 204, body: "")

    args = { broadcaster_id: "123", moderator_id: "321", session_id: "sess-1", guest_id: "9876" }
    assert_equal true, @client.guest_star.send_invite(**args)
    assert_equal true, @client.guest_star.delete_invite(**args)
  end

  def test_guest_star_assign_slot
    stub_helix(:post, "guest_star/slot",
      query: { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1", "guest_id" => "9876", "slot_id" => "1" },
      request_body: {}, status: 204, body: "")

    assert_equal true, @client.guest_star.assign_slot(broadcaster_id: "123", moderator_id: "321", session_id: "sess-1", guest_id: "9876", slot_id: "1")
  end

  def test_guest_star_update_slot_omits_missing_destination
    stub_helix(:patch, "guest_star/slot",
      query: { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1", "source_slot_id" => "1" },
      request_body: {}, status: 204, body: "")

    assert_equal true, @client.guest_star.update_slot(broadcaster_id: "123", moderator_id: "321", session_id: "sess-1", source_slot_id: "1")
  end

  def test_guest_star_delete_slot
    stub_helix(:delete, "guest_star/slot",
      query: { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1", "guest_id" => "9876", "slot_id" => "1", "should_reinvite_guest" => "true" },
      status: 204, body: "")

    assert_equal true, @client.guest_star.delete_slot(broadcaster_id: "123", moderator_id: "321", session_id: "sess-1", guest_id: "9876", slot_id: "1", should_reinvite_guest: true)
  end

  def test_guest_star_update_slot_settings_sends_everything_in_query
    stub_helix(:patch, "guest_star/slot_settings",
      query: { "broadcaster_id" => "123", "moderator_id" => "321", "session_id" => "sess-1", "slot_id" => "1", "is_audio_enabled" => "false", "volume" => "50" },
      request_body: {}, status: 204, body: "")

    result = @client.guest_star.update_slot_settings(broadcaster_id: "123", moderator_id: "321", session_id: "sess-1", slot_id: "1", is_audio_enabled: false, volume: 50)

    assert_equal true, result
  end
end
