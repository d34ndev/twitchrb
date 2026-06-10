module Twitch
  class CharityCampaignsResource < Resource
    # Required scope: channel:read:charity
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:)
      response = get_request("charity/campaigns", params: { broadcaster_id: broadcaster_id })
      if response.body.dig("data")[0]
        CharityCampaign.new(response.body.dig("data")[0])
      else
        nil
      end
    end
  end
end
