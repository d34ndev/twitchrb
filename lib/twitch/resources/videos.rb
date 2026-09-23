module Twitch
  class VideosResource < Resource
    def list(**params)
      raise ArgumentError, "user_id, game_id or id is required" if params.values_at(:user_id, :game_id, :id).all?(&:nil?)

      response = get_request("videos", params: params)
      collection(response, type: Video)
    end

    def retrieve(id:)
      response = get_request("videos", params: { id: id })
      if response.body
        Video.new response.body["data"].first
      end
    end

    # Required scope: channel:manage:videos
    def delete(video_id:)
      delete_request("videos", params: { id: video_id })
    end
  end
end
