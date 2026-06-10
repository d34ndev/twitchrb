module Twitch
  class WarningsResource < Resource
    # Moderator ID must match the user in the OAuth token
    # Required scope: moderator:manage:warnings
    def create(broadcaster_id:, moderator_id:, user_id:, reason:)
      attrs = { user_id: user_id, reason: reason }

      response = post_request("moderation/warnings?#{URI.encode_www_form(broadcaster_id: broadcaster_id, moderator_id: moderator_id)}", body: { data: attrs })
      Collection.from_response(response, type: Warning)
    end
  end
end
