module Twitch
  class OAuth
    BASE_URL = "https://id.twitch.tv/oauth2"
    DEVICE_CODE_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code"

    attr_reader :client_id, :client_secret, :timeout, :open_timeout

    # client_secret can be omitted for public clients using the device code flow
    def initialize(client_id:, client_secret: nil, timeout: Client::DEFAULT_TIMEOUT, open_timeout: Client::DEFAULT_OPEN_TIMEOUT)
      @client_id = client_id
      @client_secret = client_secret
      @timeout = timeout
      @open_timeout = open_timeout
    end

    # Extra params (e.g. code and redirect_uri) are sent with the request
    def create(grant_type:, scope: nil, **params)
      send_request(url: "token", body: params.merge(
        client_id: client_id,
        client_secret: client_secret,
        grant_type: grant_type,
        scope: scope_string(scope)
      ))
    end

    # Exchanges the code from the authorization code grant flow for an access token and refresh token
    def exchange_code(code:, redirect_uri:)
      create(grant_type: "authorization_code", code: code, redirect_uri: redirect_uri)
    end

    def refresh(refresh_token:)
      send_request(url: "token", body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "refresh_token",
        refresh_token: refresh_token
      })
    end

    # Starts the device code grant flow. scopes can be an array or a space-delimited string.
    def device(scopes:)
      send_request(url: "device", body: { client_id: client_id, scopes: scope_string(scopes) })
    end

    # Exchanges a device code for an access token and refresh token once the user has authorized.
    # Until then, raises Twitch::Errors::BadRequestError with twitch_error_message "authorization_pending".
    def device_token(device_code:, scopes:)
      send_request(url: "token", body: {
        client_id: client_id,
        client_secret: client_secret,
        device_code: device_code,
        scopes: scope_string(scopes),
        grant_type: DEVICE_CODE_GRANT_TYPE
      })
    end

    def validate(token:)
      response = connection.get("validate", nil, { "Authorization" => "OAuth #{token}" })

      return false if response.status != 200

      Object.new(JSON.parse(response.body))
    end

    def revoke(token:)
      response = connection.post("revoke", {
        client_id: client_id,
        token: token
      })

      response.status == 200
    end

    private

    def connection
      @connection ||= Faraday.new(BASE_URL) do |conn|
        conn.options.timeout = timeout
        conn.options.open_timeout = open_timeout
        conn.request :url_encoded
      end
    end

    def send_request(url:, body:)
      response = connection.post(url, body.compact)

      raise ErrorFactory.create(response.body, response.status) if response.status != 200

      Object.new(JSON.parse(response.body))
    end

    def scope_string(scopes)
      scopes.is_a?(Array) ? scopes.join(" ") : scopes
    end
  end
end
