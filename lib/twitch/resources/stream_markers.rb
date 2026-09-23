module Twitch
  class StreamMarkersResource < Resource
    # Required scope: user:read:broadcast
    def list(**params)
      response = get_request("streams/markers", params: params)

      collection(response, type: StreamMarker)
    end

    # Required scope: channel:manage:broadcast
    def create(user_id:, **params)
      response = post_request("streams/markers", body: params.merge(user_id: user_id))

      StreamMarker.new(response.body.dig("data")[0]) if response.success?
    end
  end
end
