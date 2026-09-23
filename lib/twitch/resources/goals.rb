module Twitch
  class GoalsResource < Resource
    # Required scope: channel:read:goals
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:)
      response = get_request("goals", params: { broadcaster_id: broadcaster_id })
      collection(response, type: Goal)
    end
  end
end
