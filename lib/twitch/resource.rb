module Twitch
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(url, params: {}, headers: {})
      validate_request_path!(url)
      execute_request { client.connection.get(url, params, headers) }
    end

    def post_request(url, body:, headers: {})
      validate_request_path!(url)
      execute_request { client.connection.post(url, body, headers) }
    end

    def patch_request(url, body:, headers: {})
      validate_request_path!(url)
      execute_request { client.connection.patch(url, body, headers) }
    end

    def put_request(url, body:, headers: {})
      validate_request_path!(url)
      execute_request { client.connection.put(url, body, headers) }
    end

    def delete_request(url, params: {}, headers: {})
      validate_request_path!(url)
      execute_request { client.connection.delete(url, params, headers) }
    end

    # Builds a Collection that can fetch its following pages by repeating the
    # original GET request with the cursor as the after param
    def collection(response, type:)
      Collection.from_response(response, type: type, next_page: next_page_fetcher(response, type))
    end

    def next_page_fetcher(response, type)
      return unless response.respond_to?(:env) && response.env.method == :get

      url = response.env.url
      path = url.path.delete_prefix("#{URI(Client::BASE_URL).path}/")
      params = Faraday::FlatParamsEncoder.decode(url.query) || {}
      params.delete("before")

      ->(cursor) { collection(get_request(path, params: params.merge("after" => cursor)), type: type) }
    end

    # Builds a path with a query string, for write endpoints that take some parameters
    # in the query string rather than the body. nil values are dropped.
    def query_path(path, params)
      "#{path}?#{URI.encode_www_form(params.compact)}"
    end

    def execute_request
      access_token = client.access_token
      response = yield

      # Retry once with a refreshed token if the access token has expired
      if response.status == 401 && client.refresh_after_unauthorized(response, access_token)
        response = yield
      end

      # Retry once after a 429, waiting until the rate limit window resets
      if response.status == 429 && client.auto_retry_rate_limit
        update_rate_limit(response)
        client.rate_limiter.wait_if_rate_limited
        response = yield
      end

      handle_response(response)
    end

    def handle_response(response)
      # Extract and update rate limit info from response headers
      update_rate_limit(response)

      return true if response.status == 204
      return response unless error?(response)

      raise_error(response)
    end

    def error?(response)
      response.status >= 400 ||
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
