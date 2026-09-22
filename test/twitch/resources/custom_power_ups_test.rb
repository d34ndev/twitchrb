require "test_helper"

class CustomPowerUpsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_custom_power_ups_list_returns_collection
    stub_request(:get, "#{HELIX_URL}/bits/custom_power_ups")
      .with(query: { "broadcaster_id" => "123" })
      .to_return(
        status: 200,
        body: {
          data: [
            { id: "power-up-1", broadcaster_id: "123", title: "Confetti Cannon", bits_cost: 100, is_enabled: true }
          ],
          pagination: {}
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    power_ups = @client.custom_power_ups.list(broadcaster_id: "123")

    assert_instance_of Twitch::Collection, power_ups
    assert power_ups.data.all? { |power_up| power_up.is_a?(Twitch::CustomPowerUp) }
    assert_equal "power-up-1", power_ups.first.id
  end

  def test_custom_power_ups_list_supports_id_filter
    stub_request(:get, "#{HELIX_URL}/bits/custom_power_ups?broadcaster_id=123&id=power-up-1&id=power-up-2")
      .to_return(
        status: 200,
        body: {
          data: [
            { id: "power-up-1", broadcaster_id: "123", title: "Confetti Cannon", bits_cost: 100, is_enabled: true },
            { id: "power-up-2", broadcaster_id: "123", title: "Spotlight",       bits_cost: 250, is_enabled: false }
          ],
          pagination: {}
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    power_ups = @client.custom_power_ups.list(broadcaster_id: "123", ids: [ "power-up-1", "power-up-2" ])

    assert_instance_of Twitch::Collection, power_ups
    assert_equal 2, power_ups.data.count
    assert_equal "Spotlight", power_ups.last.title
  end
end
