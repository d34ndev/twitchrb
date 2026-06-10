module Twitch
  class BadgesResource < Resource
    def channel(broadcaster_id:)
      response = get_request("chat/badges", params: { broadcaster_id: broadcaster_id })
      Collection.from_response(response, type: Badge)
    end

    def global
      response = get_request("chat/badges/global")
      Collection.from_response(response, type: Badge)
    end
  end
end
