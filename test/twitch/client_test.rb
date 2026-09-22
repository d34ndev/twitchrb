require "test_helper"

class ClientTest < Minitest::Test
  def test_client_id
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_equal "123", client.client_id
  end

  def test_access_token
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_equal "abc123", client.access_token
  end

  def test_rate_limiter_initialization
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_instance_of Twitch::RateLimiter, client.rate_limiter
  end

  def test_default_rate_limit_threshold
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_equal 10, client.rate_limit_threshold
  end

  def test_custom_rate_limit_threshold
    client = Twitch::Client.new client_id: "123", access_token: "abc123", rate_limit_threshold: 20
    assert_equal 20, client.rate_limit_threshold
  end

  def test_default_auto_retry_rate_limit
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert client.auto_retry_rate_limit
  end

  def test_disable_auto_retry_rate_limit
    client = Twitch::Client.new client_id: "123", access_token: "abc123", auto_retry_rate_limit: false
    refute client.auto_retry_rate_limit
  end

  def test_logger_configuration
    logger = Logger.new($stdout)
    client = Twitch::Client.new client_id: "123", access_token: "abc123", logger: logger
    assert_equal logger, client.logger
    assert_equal logger, client.rate_limiter.logger
  end

  def test_no_logger_by_default
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_nil client.logger
  end

  def test_hype_train_status_resource_accessor
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_instance_of Twitch::HypeTrainStatusResource, client.hype_train_status
  end

  def test_suspicious_users_resource_accessor
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_instance_of Twitch::SuspiciousUsersResource, client.suspicious_users
  end

  def test_shared_chat_sessions_resource_accessor
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_instance_of Twitch::SharedChatSessionsResource, client.shared_chat_sessions
  end

  def test_custom_power_ups_resource_accessor
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_instance_of Twitch::CustomPowerUpsResource, client.custom_power_ups
  end

  def test_default_timeouts
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_equal Twitch::Client::DEFAULT_TIMEOUT, client.connection.options.timeout
    assert_equal Twitch::Client::DEFAULT_OPEN_TIMEOUT, client.connection.options.open_timeout
  end

  def test_custom_timeouts
    client = Twitch::Client.new client_id: "123", access_token: "abc123", timeout: 5, open_timeout: 2
    assert_equal 5, client.connection.options.timeout
    assert_equal 2, client.connection.options.open_timeout
  end

  def test_array_params_are_encoded_as_repeated_keys
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    url = client.connection.build_url("users", id: [ "1", "2" ]).to_s
    assert_equal "https://api.twitch.tv/helix/users?id=1&id=2", url
  end

  def test_request_timeout_raises
    stub_request(:get, "https://api.twitch.tv/helix/users?id=1").to_timeout
    client = Twitch::Client.new client_id: "123", access_token: "abc123"
    assert_raises(Faraday::ConnectionFailed, Faraday::TimeoutError) { client.users.retrieve(id: "1") }
  end
end
