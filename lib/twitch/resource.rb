module Twitch
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(url, params: {}, headers: {})
      validate_request_path!(url)
      handle_response client.connection.get(url, params, headers)
    end

    def post_request(url, body:, headers: {})
      validate_request_path!(url)
      handle_response client.connection.post(url, body, headers)
    end

    def patch_request(url, body:, headers: {})
      validate_request_path!(url)
      handle_response client.connection.patch(url, body, headers)
    end

    def put_request(url, body:, headers: {})
      validate_request_path!(url)
      handle_response client.connection.put(url, body, headers)
    end

    def delete_request(url, params: {}, headers: {})
      validate_request_path!(url)
      handle_response client.connection.delete(url, params, headers)
    end

    def handle_response(response)
      # Extract and update rate limit info from response headers
      update_rate_limit(response)

      return true if response.status == 204
      return response unless error?(response)

      raise_error(response)
    end

    def error?(response)
      [ 400, 401, 403, 404, 409, 429, 500, 501, 503 ].include?(response.status) ||
        (response.body.is_a?(Hash) && response.body.key?("error"))
    end

    def raise_error(response)
      # Special handling for rate limit errors
      if response.status == 429
        raise_rate_limit_error(response)
      end

      error = Twitch::ErrorFactory.create(response.body, response.status)
      raise error if error
    end

    private

    def update_rate_limit(response)
      client.rate_limiter.update(response.headers)
      client.rate_limiter.warn_if_approaching(threshold: client.rate_limit_threshold)
    end

    def raise_rate_limit_error(response)
      headers = response.headers
      error = Twitch::Errors::RateLimitError.new(
        response.body,
        response.status,
        reset_at: headers["ratelimit-reset"]&.to_i,
        remaining: headers["ratelimit-remaining"]&.to_i,
        limit: headers["ratelimit-limit"]&.to_i
      )
      raise error
    end

    def validate_request_path!(url)
      return unless url.start_with?("//") || URI(url).absolute?

      raise Twitch::UnsafeRequestPathError, "request path must be relative to the Twitch API base URL"
    rescue URI::InvalidURIError
      nil
    end
  end
end
