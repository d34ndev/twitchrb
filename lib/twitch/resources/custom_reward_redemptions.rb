module Twitch
  class CustomRewardRedemptionsResource < Resource
    # Required scope: channel:read:redemptions
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, reward_id:, status:, **params)
      attributes = { broadcaster_id: broadcaster_id, reward_id: reward_id, status: status.upcase }
      response = get_request("channel_points/custom_rewards/redemptions", params: attributes.merge(params))
      Collection.from_response(response, type: CustomRewardRedemption)
    end

    # Required scope: channel:manage:redemptions
    # Broadcaster ID must match the user in the OAuth token
    def update(broadcaster_id:, reward_id:, redemption_id:, status:)
      attributes = { status: status.upcase }
      query = URI.encode_www_form(broadcaster_id: broadcaster_id, reward_id: reward_id, id: redemption_id, status: status.upcase)
      response = patch_request("channel_points/custom_rewards/redemptions?#{query}", body: attributes)

      CustomRewardRedemption.new(response.body.dig("data")[0]) if response.success?
    end
  end
end
