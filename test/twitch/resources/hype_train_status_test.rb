require "test_helper"

class HypeTrainStatusResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_hype_train_status_retrieve_returns_object
    stub_request(:get, "#{HELIX_URL}/hypetrain/status")
      .with(query: { "broadcaster_id" => "123" })
      .to_return(
        status: 200,
        body: {
          data: [
            {
              current: { id: "train-1", broadcaster_user_id: "123", level: 2 },
              shared_all_time_high: { level: 5, total: 9001 }
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    status = @client.hype_train_status.retrieve(broadcaster_id: "123")

    assert_instance_of Twitch::HypeTrainStatus, status
    assert_equal "train-1", status.current.id
    assert_equal 5, status.shared_all_time_high.level
  end

  def test_hype_train_status_retrieve_returns_nil_when_none_exist
    stub_request(:get, "#{HELIX_URL}/hypetrain/status")
      .with(query: { "broadcaster_id" => "123" })
      .to_return(status: 200, body: { data: [] }.to_json,
        headers: { "Content-Type" => "application/json" })

    assert_nil @client.hype_train_status.retrieve(broadcaster_id: "123")
  end
end
