require "test_helper"

class SuspiciousUsersResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_suspicious_users_create_returns_object
    stub_request(:post, "#{HELIX_URL}/moderation/suspicious_users")
      .with(
        query: { "broadcaster_id" => "123", "moderator_id" => "321" },
        body: hash_including("user_id" => "9876", "status" => "RESTRICTED")
      )
      .to_return(
        status: 200,
        body: {
          data: [
            {
              user_id: "9876",
              broadcaster_id: "123",
              moderator_id: "321",
              updated_at: "2025-12-01T23:08:18+00:00",
              status: "RESTRICTED",
              types: [ "MANUALLY_ADDED" ]
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    user = @client.suspicious_users.create(
      broadcaster_id: "123",
      moderator_id: "321",
      user_id: "9876",
      status: "RESTRICTED"
    )

    assert_instance_of Twitch::SuspiciousUser, user
    assert_equal "9876", user.user_id
    assert_equal "RESTRICTED", user.status
    assert_equal "MANUALLY_ADDED", user.types.first
  end

  def test_suspicious_users_delete_returns_object
    stub_request(:delete, "#{HELIX_URL}/moderation/suspicious_users")
      .with(query: { "broadcaster_id" => "123", "moderator_id" => "321", "user_id" => "9876" })
      .to_return(
        status: 200,
        body: {
          data: [
            {
              user_id: "9876",
              broadcaster_id: "123",
              moderator_id: "321",
              updated_at: "2025-12-01T23:08:18+00:00",
              status: "NO_TREATMENT",
              types: [ "MANUALLY_ADDED" ]
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    user = @client.suspicious_users.delete(
      broadcaster_id: "123",
      moderator_id: "321",
      user_id: "9876"
    )

    assert_instance_of Twitch::SuspiciousUser, user
    assert_equal "9876", user.user_id
    assert_equal "NO_TREATMENT", user.status
  end

  def test_suspicious_users_delete_with_no_content_response
    stub_request(:delete, "#{HELIX_URL}/moderation/suspicious_users")
      .with(query: { "broadcaster_id" => "123", "moderator_id" => "321", "user_id" => "9876" })
      .to_return(status: 204, body: "")

    result = @client.suspicious_users.delete(
      broadcaster_id: "123",
      moderator_id: "321",
      user_id: "9876"
    )

    assert_equal true, result
  end
end
