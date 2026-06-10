module Twitch
  class OAuth
    attr_reader :client_id, :client_secret

    def initialize(client_id:, client_secret:)
      @client_id = client_id
      @client_secret = client_secret
    end

    def create(grant_type:, scope: nil)
      send_request(url: "https://id.twitch.tv/oauth2/token", body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: grant_type,
        scope: scope
      })
    end

    def refresh(refresh_token:)
      send_request(url: "https://id.twitch.tv/oauth2/token", body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "refresh_token",
        refresh_token: refresh_token
      })
    end

    def device(scopes:)
      send_request(url: "https://id.twitch.tv/oauth2/device", body: { client_id: client_id, scope: scopes })
    end

    def validate(token:)
      response = Faraday.get("https://id.twitch.tv/oauth2/validate", nil, { "Authorization" => "OAuth #{token}" })

      return false if response.status != 200

      JSON.parse(response.body, object_class: OpenStruct)
    end

    def revoke(token:)
      response = Faraday.post("https://id.twitch.tv/oauth2/revoke", {
        client_id: client_id,
        token: token
      })

      response.status == 200
    end

    private

    def send_request(url:, body:)
      response = Faraday.post(url, body)

      return false if response.status != 200

      JSON.parse(response.body, object_class: OpenStruct)
    end
  end
end
