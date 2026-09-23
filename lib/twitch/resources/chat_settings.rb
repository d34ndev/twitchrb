module Twitch
  class ChatSettingsResource < Resource
    # moderator_id is only needed to include non_moderator_chat_delay settings,
    # and must match the user in the OAuth token
    def retrieve(broadcaster_id:, moderator_id: nil)
      response = get_request("chat/settings", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id }.compact)
      ChatSettings.new(response.body.dig("data")[0])
    end

    # Required scope: moderator:manage:chat_settings
    # moderator_id must match the user in the OAuth token
    # Available attributes: emote_mode, follower_mode, follower_mode_duration, non_moderator_chat_delay,
    # non_moderator_chat_delay_duration, slow_mode, slow_mode_wait_time, subscriber_mode, unique_chat_mode
    def update(broadcaster_id:, moderator_id:, **attributes)
      path = query_path("chat/settings", broadcaster_id: broadcaster_id, moderator_id: moderator_id)
      response = patch_request(path, body: attributes)
      ChatSettings.new(response.body.dig("data")[0])
    end
  end
end
