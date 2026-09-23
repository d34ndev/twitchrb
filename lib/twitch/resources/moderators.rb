module Twitch
  class ModeratorsResource < Resource
    # User ID must match the user in the OAuth token
    def channels(user_id:)
      response = get_request("moderation/channels", params: { user_id: user_id })
      Collection.from_response(response, type: Channel)
    end

    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("moderation/moderators", params: params.merge(broadcaster_id: broadcaster_id))
      Collection.from_response(response, type: Moderator)
    end

    def create(broadcaster_id:, user_id:)
      post_request(query_path("moderation/moderators", broadcaster_id: broadcaster_id, user_id: user_id), body: {})
    end

    def delete(broadcaster_id:, user_id:)
      delete_request("moderation/moderators", params: { broadcaster_id: broadcaster_id, user_id: user_id })
    end
  end
end
