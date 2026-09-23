require "openssl"
require "time"

module Twitch
  # Verifies and parses an EventSub webhook request from Twitch.
  # See https://dev.twitch.tv/docs/eventsub/handling-webhook-events/
  #
  #   webhook = Twitch::EventsubWebhook.new(secret: ENV["TWITCH_EVENTSUB_SECRET"], headers: request.headers, body: request.raw_post)
  #   return head :forbidden unless webhook.valid?
  #
  # body must be the raw request body, as the signature covers the exact bytes Twitch sent.
  class EventsubWebhook
    MESSAGE_ID_HEADER = "Twitch-Eventsub-Message-Id".freeze
    MESSAGE_TIMESTAMP_HEADER = "Twitch-Eventsub-Message-Timestamp".freeze
    MESSAGE_SIGNATURE_HEADER = "Twitch-Eventsub-Message-Signature".freeze
    MESSAGE_TYPE_HEADER = "Twitch-Eventsub-Message-Type".freeze
    MESSAGE_RETRY_HEADER = "Twitch-Eventsub-Message-Retry".freeze
    SUBSCRIPTION_TYPE_HEADER = "Twitch-Eventsub-Subscription-Type".freeze
    SUBSCRIPTION_VERSION_HEADER = "Twitch-Eventsub-Subscription-Version".freeze

    # Twitch recommends rejecting messages older than 10 minutes to guard against replay attacks
    DEFAULT_MAX_AGE = 600

    attr_reader :body

    # Returns true if the request's signature is valid and it isn't older than max_age seconds
    def self.verify(secret:, headers:, body:, max_age: DEFAULT_MAX_AGE)
      new(secret: secret, headers: headers, body: body, max_age: max_age).valid?
    end

    # headers can be a Hash (any header name casing), a Rack env, or Rails' request.headers
    def initialize(secret:, headers:, body:, max_age: DEFAULT_MAX_AGE)
      raise ArgumentError, "body must be the raw request body string, not parsed JSON" unless body.is_a?(String)

      @secret = secret
      @headers = headers
      @body = body
      @max_age = max_age
    end

    def valid?
      signature_valid? && !expired?
    end

    def signature_valid?
      return false if @secret.nil? || @secret.empty?
      return false if message_id.nil? || timestamp_header.nil? || signature.nil?

      expected = "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", @secret, message_id + timestamp_header + body)}"
      OpenSSL.secure_compare(expected, signature)
    end

    # True if the message is older than max_age seconds, or has no readable timestamp.
    # Also rejects timestamps far in the future.
    def expired?
      return true if timestamp.nil?

      (Time.now - timestamp).abs > @max_age
    end

    # Use this to ignore messages you've already processed, as Twitch may send a message more than once
    def message_id
      header(MESSAGE_ID_HEADER)
    end

    # notification, webhook_callback_verification or revocation
    def message_type
      header(MESSAGE_TYPE_HEADER)
    end

    def notification?
      message_type == "notification"
    end

    def verification?
      message_type == "webhook_callback_verification"
    end

    def revocation?
      message_type == "revocation"
    end

    def retry?
      header(MESSAGE_RETRY_HEADER).to_i > 0
    end

    def timestamp
      Time.iso8601(timestamp_header) if timestamp_header
    rescue ArgumentError
      nil
    end

    # e.g. channel.follow
    def subscription_type
      header(SUBSCRIPTION_TYPE_HEADER)
    end

    def subscription_version
      header(SUBSCRIPTION_VERSION_HEADER)
    end

    def payload
      @payload ||= JSON.parse(body)
    end

    def subscription
      EventsubSubscription.new(payload["subscription"]) if payload["subscription"]
    end

    # The event data for notification messages
    def event
      Object.new(payload["event"]) if payload["event"]
    end

    # For webhook_callback_verification messages. Respond with this as a text/plain 200 response.
    def challenge
      payload["challenge"]
    end

    private

    def signature
      header(MESSAGE_SIGNATURE_HEADER)
    end

    def timestamp_header
      header(MESSAGE_TIMESTAMP_HEADER)
    end

    def header(name)
      rack_key = "HTTP_#{name.upcase.tr("-", "_")}"

      value = @headers[name] || @headers[rack_key]
      return value if value

      @headers.each { |key, val| return val if key.to_s.casecmp?(name) }
      nil
    end
  end
end
