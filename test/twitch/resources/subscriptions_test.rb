require "test_helper"

class SubscriptionsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
    @query = { "broadcaster_id" => "123", "user_id" => "456" }
  end

  def test_subscribed_returns_true_when_subscribed
    stub_helix(:get, "subscriptions/user", query: @query,
      body: { data: [ { broadcaster_id: "123", tier: "1000", is_gift: false } ] }.to_json)

    assert_equal true, @client.subscriptions.subscribed?(broadcaster_id: "123", user_id: "456")
  end

  def test_subscribed_returns_false_when_not_subscribed
    stub_helix(:get, "subscriptions/user", query: @query, status: 404,
      body: { error: "Not Found", status: 404, message: "456 has no subscription to 123" }.to_json)

    assert_equal false, @client.subscriptions.subscribed?(broadcaster_id: "123", user_id: "456")
  end

  def test_subscribed_raises_other_errors
    stub_helix(:get, "subscriptions/user", query: @query, status: 401,
      body: { error: "Unauthorized", status: 401, message: "Missing scope: user:read:subscriptions" }.to_json)

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.subscriptions.subscribed?(broadcaster_id: "123", user_id: "456")
    end
  end

  def test_is_subscribed_returns_the_subscription
    stub_helix(:get, "subscriptions/user", query: @query,
      body: { data: [ { broadcaster_id: "123", tier: "2000", is_gift: true } ] }.to_json)

    subscription = @client.subscriptions.is_subscribed(broadcaster_id: "123", user_id: "456").first

    assert_instance_of Twitch::Subscription, subscription
    assert_equal "2000", subscription.tier
  end
end
