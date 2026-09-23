module Twitch
  class BitsResource < Resource
    # Required scope: bits:read
    # Available parameters: count, period, started_at, user_id
    def leaderboard(**params)
      response = get_request("bits/leaderboard", params: params)
      collection(response, type: BitsLeaderboardEntry)
    end

    # Pass broadcaster_id to include the broadcaster's custom Cheermotes
    def cheermotes(broadcaster_id: nil)
      response = get_request("bits/cheermotes", params: { broadcaster_id: broadcaster_id }.compact)
      collection(response, type: Cheermote)
    end
  end
end
