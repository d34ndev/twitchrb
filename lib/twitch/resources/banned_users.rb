module Twitch
  class BannedUsersResource < Resource
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("moderation/banned", params: params.merge(broadcaster_id: broadcaster_id))
      Collection.from_response(response, type: BannedUser)
    end

    # Required scope: moderator:manage:banned_users
    # moderator_id must match the currently authenticated user. Can be either the broadcaster ID or moderator ID
    def create(broadcaster_id:, moderator_id:, user_id:, reason:, duration: nil)
      path = query_path("moderation/bans", broadcaster_id: broadcaster_id, moderator_id: moderator_id)
      response = post_request(path, body: { data: { user_id: user_id, reason: reason, duration: duration }.compact })
      BannedUser.new response.body.dig("data")[0]
    end

    # Required scope: moderator:manage:banned_users
    # moderator_id must match the currently authenticated user. Can be either the broadcaster ID or moderator ID
    def delete(broadcaster_id:, moderator_id:, user_id:)
      delete_request("moderation/bans", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id, user_id: user_id })
    end
  end
end
