require "test_helper"

class BannedUsersResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_banned_users_create_sends_ids_in_query
    stub_helix(:post, "moderation/bans",
      query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      request_body: { data: { user_id: "9876", reason: "spam", duration: 600 } },
      body: { data: [ { broadcaster_id: "123", user_id: "9876", end_time: "2026-09-23T12:10:00Z" } ] }.to_json)

    ban = @client.banned_users.create(broadcaster_id: "123", moderator_id: "321", user_id: "9876", reason: "spam", duration: 600)

    assert_instance_of Twitch::BannedUser, ban
    assert_equal "9876", ban.user_id
  end

  def test_banned_users_create_omits_duration_for_permanent_bans
    stub_helix(:post, "moderation/bans",
      query: { "broadcaster_id" => "123", "moderator_id" => "321" },
      request_body: { data: { user_id: "9876", reason: "spam" } },
      body: { data: [ { broadcaster_id: "123", user_id: "9876", end_time: nil } ] }.to_json)

    ban = @client.banned_users.create(broadcaster_id: "123", moderator_id: "321", user_id: "9876", reason: "spam")

    assert_nil ban.end_time
  end
end
