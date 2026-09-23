module Twitch
  class PinnedChatMessagesResource < Resource
    def retrieve(broadcaster_id:, moderator_id:)
      response = get_request("chat/pins", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id })
      data = response.body.dig("data")

      return nil if data.nil? || data.empty?

      PinnedChatMessage.new(data[0])
    end

    # moderator_id must match the user in the OAuth token
    def create(broadcaster_id:, moderator_id:, message_id:, duration_seconds: nil)
      put_request(pins_path(broadcaster_id:, moderator_id:, message_id:, duration_seconds:), body: {})
    end

    # moderator_id must match the user in the OAuth token
    def update(broadcaster_id:, moderator_id:, message_id:, duration_seconds: nil)
      patch_request(pins_path(broadcaster_id:, moderator_id:, message_id:, duration_seconds:), body: {})
    end

    # moderator_id must match the user in the OAuth token
    def delete(broadcaster_id:, moderator_id:, message_id:)
      delete_request("chat/pins", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id, message_id: message_id })
    end

    private

    def pins_path(broadcaster_id:, moderator_id:, message_id:, duration_seconds:)
      query_path("chat/pins", broadcaster_id: broadcaster_id, moderator_id: moderator_id, message_id: message_id, duration_seconds: duration_seconds)
    end
  end
end
