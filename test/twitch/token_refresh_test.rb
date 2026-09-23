require "test_helper"

class TokenRefreshTest < WebmockTest
  TOKEN_URL = "https://id.twitch.tv/oauth2/token".freeze

  def setup
    @refreshed = []
    @client = Twitch::Client.new(
      client_id: "test_client_id",
      client_secret: "test_client_secret",
      access_token: "old_token",
      refresh_token: "old_refresh",
      on_token_refresh: ->(token) { @refreshed << token }
    )
  end

  def stub_expired(token = "old_token", message: "Invalid OAuth token")
    stub_request(:get, "#{HELIX_URL}/users?id=1")
      .with(headers: { "Authorization" => "Bearer #{token}" })
      .to_return(status: 401, body: { error: "Unauthorized", status: 401, message: message }.to_json,
        headers: { "Content-Type" => "application/json" })
  end

  def stub_users(token)
    stub_request(:get, "#{HELIX_URL}/users?id=1")
      .with(headers: { "Authorization" => "Bearer #{token}" })
      .to_return(status: 200, body: { data: [ { id: "1", login: "twitchdev" } ] }.to_json,
        headers: { "Content-Type" => "application/json" })
  end

  def stub_refresh(refresh_token: "old_refresh", new_access: "new_token", new_refresh: "new_refresh", client_secret: "test_client_secret")
    body = { "client_id" => "test_client_id", "grant_type" => "refresh_token", "refresh_token" => refresh_token }
    body["client_secret"] = client_secret if client_secret

    stub_request(:post, TOKEN_URL)
      .with(body: body)
      .to_return(status: 200, body: { access_token: new_access, refresh_token: new_refresh, expires_in: 14_000, scope: [ "user:read:email" ], token_type: "bearer" }.to_json)
  end

  def test_refreshes_expired_token_and_retries
    stub_expired
    refresh = stub_refresh
    retried = stub_users("new_token")

    user = @client.users.retrieve(id: 1)

    assert_equal "twitchdev", user.login
    assert_requested refresh, times: 1
    assert_requested retried, times: 1
    assert_equal "new_token", @client.access_token
    assert_equal "new_refresh", @client.refresh_token
  end

  def test_calls_on_token_refresh_with_the_new_token
    stub_expired
    stub_refresh
    stub_users("new_token")

    @client.users.retrieve(id: 1)

    assert_equal 1, @refreshed.size
    assert_equal "new_token", @refreshed.first.access_token
    assert_equal "new_refresh", @refreshed.first.refresh_token
    assert_equal 14_000, @refreshed.first.expires_in
  end

  def test_uses_the_rotated_refresh_token_next_time
    stub_expired("old_token")
    stub_refresh(refresh_token: "old_refresh", new_access: "token_2", new_refresh: "refresh_2")
    stub_users("token_2")
    @client.users.retrieve(id: 1)

    WebMock.reset!
    stub_expired("token_2")
    second_refresh = stub_refresh(refresh_token: "refresh_2", new_access: "token_3", new_refresh: "refresh_3")
    stub_users("token_3")
    @client.users.retrieve(id: 1)

    assert_requested second_refresh, times: 1
    assert_equal "token_3", @client.access_token
  end

  def test_does_not_refresh_for_missing_scope
    stub_expired(message: "Missing scope: user:read:email")
    refresh = stub_refresh

    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.users.retrieve(id: 1) }
    assert_not_requested refresh
  end

  def test_does_not_refresh_without_a_refresh_token
    client = Twitch::Client.new(client_id: "test_client_id", access_token: "old_token")
    stub_expired
    refresh = stub_refresh

    assert_raises(Twitch::Errors::AuthenticationMissingError) { client.users.retrieve(id: 1) }
    assert_not_requested refresh
  end

  def test_raises_if_still_unauthorized_after_refresh
    stub_expired("old_token")
    refresh = stub_refresh
    stub_expired("new_token")

    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.users.retrieve(id: 1) }
    assert_requested refresh, times: 1
  end

  def test_raises_when_the_refresh_token_is_invalid
    stub_expired
    stub_request(:post, TOKEN_URL).to_return(status: 400, body: { status: 400, message: "Invalid refresh token" }.to_json)

    error = assert_raises(Twitch::Errors::BadRequestError) { @client.users.retrieve(id: 1) }
    assert_equal "Invalid refresh token", error.twitch_error_message
    assert_equal "old_token", @client.access_token
    assert_empty @refreshed
  end

  def test_public_client_refreshes_without_client_secret
    client = Twitch::Client.new(client_id: "test_client_id", access_token: "old_token", refresh_token: "old_refresh")
    stub_expired
    refresh = stub_refresh(client_secret: nil)
    stub_users("new_token")

    assert_equal "1", client.users.retrieve(id: 1).id
    assert_requested refresh, times: 1
  end

  def test_refreshes_write_requests_too
    stub_request(:post, "#{HELIX_URL}/chat/messages")
      .with(headers: { "Authorization" => "Bearer old_token" })
      .to_return(status: 401, body: { status: 401, message: "Invalid OAuth token" }.to_json, headers: { "Content-Type" => "application/json" })
    stub_refresh
    retried = stub_request(:post, "#{HELIX_URL}/chat/messages")
      .with(headers: { "Authorization" => "Bearer new_token" }, body: { broadcaster_id: "1", sender_id: "2", message: "hi" }.to_json)
      .to_return(status: 200, body: { data: [ { message_id: "m1", is_sent: true } ] }.to_json, headers: { "Content-Type" => "application/json" })

    message = @client.chat_messages.create(broadcaster_id: "1", sender_id: "2", message: "hi")

    assert_equal "m1", message.message_id
    assert_requested retried, times: 1
  end

  def test_refresh_access_token_manually
    refresh = stub_refresh

    token = @client.refresh_access_token!

    assert_equal "new_token", token.access_token
    assert_equal "new_token", @client.access_token
    assert_equal 1, @refreshed.size
    assert_requested refresh, times: 1
  end

  def test_refresh_access_token_manually_requires_a_refresh_token
    client = Twitch::Client.new(client_id: "test_client_id", access_token: "old_token")

    assert_raises(Twitch::Error) { client.refresh_access_token! }
  end

  # If several threads hit a 401 with the same expired token, only the first should refresh.
  # The rest see the token has already changed and just retry.
  def test_skips_refresh_when_another_request_already_refreshed
    refresh = stub_refresh
    response = Struct.new(:body).new({ "message" => "Invalid OAuth token" })

    assert @client.refresh_after_unauthorized(response, "old_token")
    assert @client.refresh_after_unauthorized(response, "old_token")

    assert_requested refresh, times: 1
    assert_equal 1, @refreshed.size
  end

  def test_concurrent_401s_refresh_once
    refresh = stub_refresh
    response = Struct.new(:body).new({ "message" => "Invalid OAuth token" })

    threads = 5.times.map { Thread.new { @client.refresh_after_unauthorized(response, "old_token") } }
    threads.each(&:join)

    assert_requested refresh, times: 1
    assert_equal "new_token", @client.access_token
  end
end
