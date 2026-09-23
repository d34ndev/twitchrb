module Twitch
  class ClipsResource < Resource
    def list(**params)
      raise "broadcaster_id or game_id is required" unless !params[:broadcaster_id].nil? || !params[:game_id].nil?

      response = get_request("clips", params: params)
      collection(response, type: Clip)
    end

    def retrieve(id:)
      Clip.new get_request("clips", params: { id: id }).body.dig("data")[0]
    end

    # Required scope: clips:edit
    def create(broadcaster_id:, **attributes)
      response = post_request(query_path("clips", attributes.merge(broadcaster_id: broadcaster_id)), body: {})

      Clip.new(response.body.dig("data")[0]) if response.success?
    end

    # Required scope: editor:manage:clips or channel:manage:clips
    def create_from_vod(editor_id:, broadcaster_id:, vod_id:, vod_offset:, **attributes)
      params = attributes.merge(
        editor_id: editor_id,
        broadcaster_id: broadcaster_id,
        vod_id: vod_id,
        vod_offset: vod_offset
      )

      response = post_request(query_path("videos/clips", params), body: {})

      Clip.new(response.body.dig("data")[0]) if response.success?
    end

    # Required scope: editor:manage:clips or channel:manage:clips
    def downloads(editor_id:, broadcaster_id:, clip_id: nil, clip_ids: nil)
      ids = clip_ids || Array(clip_id)
      response = get_request("clips/downloads", params: { editor_id: editor_id, broadcaster_id: broadcaster_id, clip_id: ids })

      collection(response, type: ClipDownload)
    end
  end
end
