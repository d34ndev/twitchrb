module Twitch
  class EmotesResource < Resource
    def channel(broadcaster_id:)
      response = get_request("chat/emotes", params: { broadcaster_id: broadcaster_id })
      collection(response, type: Emote)
    end

    def global
      response = get_request("chat/emotes/global")
      collection(response, type: Emote)
    end

    def sets(emote_set_id:)
      response = get_request("chat/emotes/set", params: { emote_set_id: emote_set_id })
      collection(response, type: Emote)
    end
  end
end
