require "test_helper"

class CustomRewardsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_custom_rewards_create_sends_broadcaster_id_in_query
    stub_helix(:post, "channel_points/custom_rewards",
      query: { "broadcaster_id" => "123" },
      request_body: { title: "Hydrate", cost: 500, prompt: "Drink water" },
      body: { data: [ { id: "reward-1", title: "Hydrate", cost: 500 } ] }.to_json)

    reward = @client.custom_rewards.create(broadcaster_id: "123", title: "Hydrate", cost: 500, prompt: "Drink water")

    assert_instance_of Twitch::CustomReward, reward
    assert_equal "reward-1", reward.id
  end

  def test_custom_rewards_update_sends_ids_in_query
    stub_helix(:patch, "channel_points/custom_rewards",
      query: { "broadcaster_id" => "123", "id" => "reward-1" },
      request_body: { is_enabled: false },
      body: { data: [ { id: "reward-1", is_enabled: false } ] }.to_json)

    reward = @client.custom_rewards.update(broadcaster_id: "123", reward_id: "reward-1", is_enabled: false)

    assert_instance_of Twitch::CustomReward, reward
    assert_equal false, reward.is_enabled
  end

  def test_custom_reward_redemptions_update_sends_status_in_body_only
    stub_helix(:patch, "channel_points/custom_rewards/redemptions",
      query: { "broadcaster_id" => "123", "reward_id" => "reward-1", "id" => "redemption-1" },
      request_body: { status: "FULFILLED" },
      body: { data: [ { id: "redemption-1", status: "FULFILLED" } ] }.to_json)

    redemption = @client.custom_reward_redemptions.update(broadcaster_id: "123", reward_id: "reward-1", redemption_id: "redemption-1", status: "fulfilled")

    assert_instance_of Twitch::CustomRewardRedemption, redemption
    assert_equal "FULFILLED", redemption.status
  end
end
