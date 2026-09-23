module Twitch
  class ShieldModeResource < Resource
    # Required scope: moderator:read:shield_mode or moderator:manage:shield_mode
    # moderator_id must match the user in the OAuth token
    def retrieve(broadcaster_id:, moderator_id:)
      response = get_request("moderation/shield_mode", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id })
      ShieldModeStatus.new(response.body.dig("data")[0])
    end

    # Required scope: moderator:manage:shield_mode
    # moderator_id must match the user in the OAuth token
    def update(broadcaster_id:, moderator_id:, is_active:)
      path = query_path("moderation/shield_mode", broadcaster_id: broadcaster_id, moderator_id: moderator_id)
      response = put_request(path, body: { is_active: is_active })
      ShieldModeStatus.new(response.body.dig("data")[0])
    end
  end
end
