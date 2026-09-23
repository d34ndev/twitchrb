require "test_helper"

class CharityCampaignsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_charity_campaigns_donations
    stub_helix(:get, "charity/donations", query: { "broadcaster_id" => "123", "first" => "10" },
      body: { data: [ { id: "don-1", user_id: "9876", amount: { value: 500, decimal_places: 2, currency: "USD" } } ], pagination: { cursor: "next" } }.to_json)

    donations = @client.charity_campaigns.donations(broadcaster_id: "123", first: 10)

    assert_instance_of Twitch::CharityDonation, donations.first
    assert_equal 500, donations.first.amount.value
    assert_equal "next", donations.cursor
  end
end
