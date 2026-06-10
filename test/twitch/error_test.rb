class ErrorTest < Minitest::Test
  def test_bad_request_error
    error = Twitch::ErrorFactory.create(
      { "error" => 123, "message" => "Twitch error message" },
      400
    )

    assert_equal "Error 400: Your request was malformed. 'Twitch error message'", error.message
  end

  def test_authentication_missing_error
    error = Twitch::ErrorFactory.create(
      { "error": {} },
      401
    )

    assert_equal "Error 401: You did not supply valid authentication credentials.", error.message
  end

  def test_twitch_error_generator_message
    error = Twitch::ErrorGenerator.new({ "error" => 123, "message" => "Twitch error message" }, 409)

    assert_equal "Twitch error message", error.twitch_error_message
  end

  def test_twitch_error_message
    error = Twitch::Error.new("Connection failed")

    assert_equal "Connection failed", error.message
  end

  def test_api_errors_are_rescuable_as_twitch_error
    error = Twitch::ErrorFactory.create({ "error" => "Bad Request" }, 400)

    assert_kind_of Twitch::Error, error
  end

  def test_eventsub_subscription_conflict_error_exposes_existing_id
    error = Twitch::Errors::EventsubSubscriptionConflictError.new(
      { "error" => "Conflict", "message" => "subscription already exists" },
      409,
      existing_subscription_id: "sub-123"
    )

    assert_equal "sub-123", error.existing_subscription_id
    assert_equal "Error 409: Your request was a conflict. 'subscription already exists'", error.message
  end

  def test_rate_limit_error_with_full_info
    reset_time = Time.now.to_i + 60
    error = Twitch::Errors::RateLimitError.new(
      { "error" => "Too Many Requests", "message" => "Rate limited" },
      429,
      reset_at: reset_time,
      remaining: 0,
      limit: 120
    )

    assert_equal 429, error.http_status_code
    assert_equal reset_time, error.reset_at
    assert_equal 0, error.remaining
    assert_equal 120, error.limit
    assert error.message.include?("Resets at")
    assert error.message.include?("0/120 requests")
  end

  def test_rate_limit_error_with_partial_info
    reset_time = Time.now.to_i + 60
    error = Twitch::Errors::RateLimitError.new(
      { "error" => "Too Many Requests" },
      429,
      reset_at: reset_time
    )

    assert_equal 429, error.http_status_code
    assert_equal reset_time, error.reset_at
    assert error.message.include?("Resets at")
  end

  def test_rate_limit_error_without_reset_info
    error = Twitch::Errors::RateLimitError.new(
      { "error" => "Too Many Requests" },
      429
    )

    assert_equal 429, error.http_status_code
    assert_nil error.reset_at
  end

  def test_too_many_requests_error_still_works
    error = Twitch::ErrorFactory.create(
      { "error" => "Too Many Requests", "message" => "Rate limited" },
      429
    )

    assert_equal "Error 429: Your request exceeded the API rate limit. 'Rate limited'", error.message
  end
end
