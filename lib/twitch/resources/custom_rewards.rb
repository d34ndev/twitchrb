module Twitch
  class CustomRewardsResource < Resource
    # Required scope: channel:read:redemptions
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("channel_points/custom_rewards", params: params.merge(broadcaster_id: broadcaster_id))
      collection(response, type: CustomReward)
    end

    def create(broadcaster_id:, title:, cost:, **params)
      attributes = { title: title, cost: cost }
      response = post_request(query_path("channel_points/custom_rewards", broadcaster_id: broadcaster_id), body: attributes.merge(params))

      CustomReward.new(response.body.dig("data")[0]) if response.success?
    end

    def update(broadcaster_id:, reward_id:, **params)
      path = query_path("channel_points/custom_rewards", broadcaster_id: broadcaster_id, id: reward_id)
      response = patch_request(path, body: params)

      CustomReward.new(response.body.dig("data")[0]) if response.success?
    end

    def delete(broadcaster_id:, reward_id:)
      delete_request("channel_points/custom_rewards", params: { broadcaster_id: broadcaster_id, id: reward_id })
    end
  end
end
