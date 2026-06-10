module Twitch
  class VipsResource < Resource
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("channels/vips", params: params.merge(broadcaster_id: broadcaster_id))
      Collection.from_response(response, type: Vip)
    end

    def create(broadcaster_id:, user_id:)
      post_request("channels/vips", body: { broadcaster_id: broadcaster_id, user_id: user_id })
    end

    def delete(broadcaster_id:, user_id:)
      delete_request("channels/vips", params: { broadcaster_id: broadcaster_id, user_id: user_id })
    end
  end
end
