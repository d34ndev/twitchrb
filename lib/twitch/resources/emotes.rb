module Twitch
  class EmotesResource < Resource
    def channel(broadcaster_id:)
      response = get_request("chat/emotes", params: { broadcaster_id: broadcaster_id })
      Collection.from_response(response, type: Emote)
    end

    def global
      response = get_request("chat/emotes/global")
      Collection.from_response(response, type: Emote)
    end

    def sets(emote_set_id:)
      response = get_request("chat/emotes/set", params: { emote_set_id: emote_set_id })
      Collection.from_response(response, type: Emote)
    end
  end
end
