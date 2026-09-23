require "test_helper"

class EventsubWebhookTest < Minitest::Test
  SECRET = "this is my secret".freeze
  MESSAGE_ID = "e76c6bd4-55c9-4987-8304-da1588d8988b".freeze

  NOTIFICATION_BODY = {
    subscription: {
      id: "f1c2a387-161a-49f9-a165-0f21d7a4e1c4",
      type: "channel.follow",
      version: "2",
      status: "enabled",
      condition: { broadcaster_user_id: "1337", moderator_user_id: "1337" }
    },
    event: { user_id: "1234", user_login: "cool_user", broadcaster_user_id: "1337" }
  }.to_json.freeze

  def sign(body, message_id: MESSAGE_ID, timestamp: Time.now.utc.iso8601(9), secret: SECRET)
    "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, message_id + timestamp + body)}"
  end

  def headers_for(body, type: "notification", timestamp: Time.now.utc.iso8601(9), signature: nil)
    {
      "Twitch-Eventsub-Message-Id" => MESSAGE_ID,
      "Twitch-Eventsub-Message-Timestamp" => timestamp,
      "Twitch-Eventsub-Message-Signature" => signature || sign(body, timestamp: timestamp),
      "Twitch-Eventsub-Message-Type" => type,
      "Twitch-Eventsub-Message-Retry" => "0",
      "Twitch-Eventsub-Subscription-Type" => "channel.follow",
      "Twitch-Eventsub-Subscription-Version" => "2"
    }
  end

  def webhook(body: NOTIFICATION_BODY, headers: headers_for(body), secret: SECRET, **options)
    Twitch::EventsubWebhook.new(secret: secret, headers: headers, body: body, **options)
  end

  def test_signature_matches_independently_computed_hmac
    body = '{"subscription":{"type":"channel.follow"}}'
    headers = {
      "Twitch-Eventsub-Message-Id" => MESSAGE_ID,
      "Twitch-Eventsub-Message-Timestamp" => "2019-11-16T10:11:12.634234626Z",
      "Twitch-Eventsub-Message-Signature" => "sha256=d1ed7a5fdd06bb71935c84ef81194bfe213f70b88aed4ada6b9875c4b55a3bbb"
    }

    assert webhook(body: body, headers: headers).signature_valid?
  end

  def test_valid_notification
    assert webhook.valid?
  end

  def test_verify_class_method
    assert Twitch::EventsubWebhook.verify(secret: SECRET, headers: headers_for(NOTIFICATION_BODY), body: NOTIFICATION_BODY)
    refute Twitch::EventsubWebhook.verify(secret: "wrong secret", headers: headers_for(NOTIFICATION_BODY), body: NOTIFICATION_BODY)
  end

  def test_invalid_with_wrong_secret
    refute webhook(secret: "a different secret").valid?
  end

  def test_invalid_when_body_is_tampered_with
    headers = headers_for(NOTIFICATION_BODY)

    refute webhook(body: NOTIFICATION_BODY.sub("cool_user", "evil_user"), headers: headers).valid?
  end

  def test_invalid_with_malformed_signature
    refute webhook(headers: headers_for(NOTIFICATION_BODY, signature: "sha256=abc")).valid?
    refute webhook(headers: headers_for(NOTIFICATION_BODY, signature: "not a signature")).valid?
  end

  def test_invalid_with_missing_headers
    headers = headers_for(NOTIFICATION_BODY)

    refute webhook(headers: headers.except("Twitch-Eventsub-Message-Signature")).valid?
    refute webhook(headers: headers.except("Twitch-Eventsub-Message-Id")).valid?
    refute webhook(headers: headers.except("Twitch-Eventsub-Message-Timestamp")).valid?
    refute webhook(headers: {}).valid?
  end

  def test_invalid_without_secret
    refute webhook(secret: nil).valid?
    refute webhook(secret: "").valid?
  end

  def test_expired_message_is_invalid_even_with_valid_signature
    old = (Time.now.utc - 11 * 60).iso8601(9)
    message = webhook(headers: headers_for(NOTIFICATION_BODY, timestamp: old))

    assert message.signature_valid?
    assert message.expired?
    refute message.valid?
  end

  def test_message_from_the_future_is_invalid
    future = (Time.now.utc + 11 * 60).iso8601(9)

    refute webhook(headers: headers_for(NOTIFICATION_BODY, timestamp: future)).valid?
  end

  def test_custom_max_age
    two_minutes_ago = (Time.now.utc - 120).iso8601(9)
    headers = headers_for(NOTIFICATION_BODY, timestamp: two_minutes_ago)

    assert webhook(headers: headers).valid?
    refute webhook(headers: headers, max_age: 60).valid?
  end

  def test_unparseable_timestamp_is_invalid
    message = webhook(headers: headers_for(NOTIFICATION_BODY, timestamp: "yesterday"))

    assert message.signature_valid?
    assert_nil message.timestamp
    refute message.valid?
  end

  def test_rejects_parsed_body
    assert_raises(ArgumentError) do
      Twitch::EventsubWebhook.new(secret: SECRET, headers: {}, body: JSON.parse(NOTIFICATION_BODY))
    end
  end

  def test_reads_lowercase_headers
    headers = headers_for(NOTIFICATION_BODY).transform_keys(&:downcase)

    assert webhook(headers: headers).valid?
  end

  def test_reads_rack_env_headers
    env = headers_for(NOTIFICATION_BODY).transform_keys { |key| "HTTP_#{key.upcase.tr("-", "_")}" }

    message = webhook(headers: env)

    assert message.valid?
    assert_equal "channel.follow", message.subscription_type
  end

  def test_notification_accessors
    message = webhook

    assert message.notification?
    refute message.verification?
    refute message.revocation?
    refute message.retry?
    assert_equal MESSAGE_ID, message.message_id
    assert_equal "channel.follow", message.subscription_type
    assert_equal "2", message.subscription_version
    assert_instance_of Time, message.timestamp
    assert_instance_of Twitch::EventsubSubscription, message.subscription
    assert_equal "1337", message.subscription.condition.broadcaster_user_id
    assert_equal "cool_user", message.event.user_login
    assert_nil message.challenge
  end

  def test_retry_header
    headers = headers_for(NOTIFICATION_BODY).merge("Twitch-Eventsub-Message-Retry" => "1")

    assert webhook(headers: headers).retry?
  end

  def test_verification_challenge
    body = { challenge: "pogchamp-kappa-360noscope-vohiyo", subscription: { type: "channel.follow", status: "webhook_callback_verification_pending" } }.to_json
    message = webhook(body: body, headers: headers_for(body, type: "webhook_callback_verification"))

    assert message.valid?
    assert message.verification?
    assert_equal "pogchamp-kappa-360noscope-vohiyo", message.challenge
    assert_nil message.event
  end

  def test_revocation
    body = { subscription: { type: "channel.follow", status: "authorization_revoked" } }.to_json
    message = webhook(body: body, headers: headers_for(body, type: "revocation"))

    assert message.valid?
    assert message.revocation?
    assert_equal "authorization_revoked", message.subscription.status
  end
end
