module Twitch
  class ChattersResource < Resource
    # Gets a list of users that are connected to the specified broadcaster's chat session
    # Moderator ID must match the user in the OAuth token
    # Required scope: moderator:read:chatters
    def list(broadcaster_id:, moderator_id:, **params)
      attrs = { broadcaster_id: broadcaster_id, moderator_id: moderator_id }
      response = get_request("chat/chatters", params: attrs.merge(params))

      collection(response, type: Chatter)
    end
  end
end
