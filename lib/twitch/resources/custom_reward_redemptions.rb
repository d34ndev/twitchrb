module Twitch
  class CustomRewardRedemptionsResource < Resource
    # Required scope: channel:read:redemptions
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, reward_id:, status:, **params)
      attributes = { broadcaster_id: broadcaster_id, reward_id: reward_id, status: status.upcase }
      response = get_request("channel_points/custom_rewards/redemptions", params: attributes.merge(params))
      collection(response, type: CustomRewardRedemption)
    end

    # Required scope: channel:manage:redemptions
    # Broadcaster ID must match the user in the OAuth token
    def update(broadcaster_id:, reward_id:, redemption_id:, status:)
      path = query_path("channel_points/custom_rewards/redemptions", broadcaster_id: broadcaster_id, reward_id: reward_id, id: redemption_id)
      response = patch_request(path, body: { status: status.upcase })

      CustomRewardRedemption.new(response.body.dig("data")[0]) if response.success?
    end
  end
end
