require "test_helper"

class OAuthTest < WebmockTest
  TOKEN_URL    = "https://id.twitch.tv/oauth2/token".freeze
  DEVICE_URL   = "https://id.twitch.tv/oauth2/device".freeze
  VALIDATE_URL = "https://id.twitch.tv/oauth2/validate".freeze
  REVOKE_URL   = "https://id.twitch.tv/oauth2/revoke".freeze

  def setup
    @oauth = Twitch::OAuth.new(client_id: "test_client_id", client_secret: "test_client_secret")
  end

  def test_oauth_initialization
    oauth = Twitch::OAuth.new(client_id: "test_id", client_secret: "test_secret")

    assert_equal "test_id", oauth.client_id
    assert_equal "test_secret", oauth.client_secret
  end

  def test_oauth_create_client_credentials_token
    stub_request(:post, TOKEN_URL).to_return(
      status: 200,
      body: { access_token: "abcd1234", expires_in: 5011271, token_type: "bearer" }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    token = @oauth.create(grant_type: "client_credentials")

    assert_equal "bearer", token.token_type
    assert_equal "abcd1234", token.access_token
  end

  def test_oauth_create_client_credentials_with_scopes
    stub_request(:post, TOKEN_URL)
      .with(body: hash_including("scope" => "channel:read:subscriptions"))
      .to_return(
        status: 200,
        body: {
          access_token: "abcd1234",
          expires_in: 5011271,
          scope: [ "channel:read:subscriptions" ],
          token_type: "bearer"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    token = @oauth.create(grant_type: "client_credentials", scope: "channel:read:subscriptions")

    assert_equal "bearer", token.token_type
    assert_equal "abcd1234", token.access_token
    assert_equal [ "channel:read:subscriptions" ], token.scope
  end

  def test_oauth_validate_token
    stub_request(:get, VALIDATE_URL)
      .with(headers: { "Authorization" => "OAuth valid_token" })
      .to_return(
        status: 200,
        body: {
          client_id: "test_client_id",
          login: "twitchdev",
          scopes: [ "channel:read:subscriptions" ],
          user_id: "141981764",
          expires_in: 5520838
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    validation = @oauth.validate(token: "valid_token")

    assert_equal "test_client_id", validation.client_id
    assert_equal 5520838, validation.expires_in
  end

  def test_oauth_validate_invalid_token
    stub_request(:get, VALIDATE_URL)
      .with(headers: { "Authorization" => "OAuth invalid_token_123" })
      .to_return(status: 401, body: { status: 401, message: "invalid access token" }.to_json,
        headers: { "Content-Type" => "application/json" })

    assert_equal false, @oauth.validate(token: "invalid_token_123")
  end

  def test_oauth_revoke_token
    stub_request(:post, REVOKE_URL)
      .with(body: hash_including("token" => "valid_token"))
      .to_return(status: 200, body: "")

    assert_equal true, @oauth.revoke(token: "valid_token")
  end

  def test_oauth_device_flow_initiation
    stub_request(:post, DEVICE_URL)
      .with(body: hash_including("scope" => "user:read:email"))
      .to_return(
        status: 200,
        body: {
          device_code: "abcd1234",
          user_code: "ABCDEFGH",
          verification_uri: "https://www.twitch.tv/activate?device-code=ABCDEFGH",
          expires_in: 1800,
          interval: 5
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    device_response = @oauth.device(scopes: "user:read:email")

    assert_equal "abcd1234", device_response.device_code
    assert_equal "ABCDEFGH", device_response.user_code
    assert_equal "https://www.twitch.tv/activate?device-code=ABCDEFGH", device_response.verification_uri
    assert_equal 1800, device_response.expires_in
    assert_equal 5, device_response.interval
  end

  def test_oauth_refresh_token_with_invalid_token
    stub_request(:post, TOKEN_URL)
      .with(body: hash_including("grant_type" => "refresh_token", "refresh_token" => "invalid_refresh_token"))
      .to_return(status: 400, body: { status: 400, message: "Invalid refresh token" }.to_json,
        headers: { "Content-Type" => "application/json" })

    assert_equal false, @oauth.refresh(refresh_token: "invalid_refresh_token")
  end

  def test_oauth_create_with_invalid_grant_type
    stub_request(:post, TOKEN_URL)
      .with(body: hash_including("grant_type" => "invalid_grant_type"))
      .to_return(status: 400, body: { status: 400, message: "Invalid grant type" }.to_json,
        headers: { "Content-Type" => "application/json" })

    assert_equal false, @oauth.create(grant_type: "invalid_grant_type")
  end

  def test_oauth_create_with_invalid_credentials
    stub_request(:post, TOKEN_URL)
      .with(body: hash_including("client_id" => "invalid_client_id"))
      .to_return(status: 403, body: { status: 403, message: "invalid client" }.to_json,
        headers: { "Content-Type" => "application/json" })

    bad_oauth = Twitch::OAuth.new(client_id: "invalid_client_id", client_secret: "invalid_client_secret")

    assert_equal false, bad_oauth.create(grant_type: "client_credentials")
  end

  def test_oauth_revoke_invalid_token
    stub_request(:post, REVOKE_URL)
      .with(body: hash_including("token" => "invalid_token"))
      .to_return(status: 400, body: { status: 400, message: "Invalid token" }.to_json,
        headers: { "Content-Type" => "application/json" })

    assert_equal false, @oauth.revoke(token: "invalid_token")
  end

  def test_oauth_default_timeouts
    connection = @oauth.send(:connection)
    assert_equal Twitch::Client::DEFAULT_TIMEOUT, connection.options.timeout
    assert_equal Twitch::Client::DEFAULT_OPEN_TIMEOUT, connection.options.open_timeout
  end

  def test_oauth_custom_timeouts
    oauth = Twitch::OAuth.new(client_id: "id", client_secret: "secret", timeout: 5, open_timeout: 2)
    connection = oauth.send(:connection)
    assert_equal 5, connection.options.timeout
    assert_equal 2, connection.options.open_timeout
  end

  def test_oauth_request_timeout_raises
    stub_request(:post, TOKEN_URL).to_timeout
    assert_raises(Faraday::ConnectionFailed, Faraday::TimeoutError) { @oauth.create(grant_type: "client_credentials") }
  end
end
