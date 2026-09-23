module Twitch
  class AdsResource < Resource
    # Required scope: channel:read:ads
    # broadcaster_id must match the user in the OAuth token
    def schedule(broadcaster_id:)
      response = get_request("channels/ads", params: { broadcaster_id: broadcaster_id })
      AdSchedule.new(response.body.dig("data")[0])
    end

    # Pushes back the next scheduled ad by 5 minutes
    # Required scope: channel:manage:ads
    # broadcaster_id must match the user in the OAuth token
    def snooze(broadcaster_id:)
      response = post_request(query_path("channels/ads/schedule/snooze", broadcaster_id: broadcaster_id), body: {})
      AdSchedule.new(response.body.dig("data")[0])
    end
  end
end
