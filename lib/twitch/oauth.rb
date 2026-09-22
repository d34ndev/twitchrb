module Twitch
  class OAuth
    BASE_URL = "https://id.twitch.tv/oauth2"

    attr_reader :client_id, :client_secret, :timeout, :open_timeout

    def initialize(client_id:, client_secret:, timeout: Client::DEFAULT_TIMEOUT, open_timeout: Client::DEFAULT_OPEN_TIMEOUT)
      @client_id = client_id
      @client_secret = client_secret
      @timeout = timeout
      @open_timeout = open_timeout
    end

    def create(grant_type:, scope: nil)
      send_request(url: "token", body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: grant_type,
        scope: scope
      })
    end

    def refresh(refresh_token:)
      send_request(url: "token", body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "refresh_token",
        refresh_token: refresh_token
      })
    end

    def device(scopes:)
      send_request(url: "device", body: { client_id: client_id, scope: scopes })
    end

    def validate(token:)
      response = connection.get("validate", nil, { "Authorization" => "OAuth #{token}" })

      return false if response.status != 200

      JSON.parse(response.body, object_class: OpenStruct)
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
      response = connection.post(url, body)

      return false if response.status != 200

      JSON.parse(response.body, object_class: OpenStruct)
    end
  end
end
