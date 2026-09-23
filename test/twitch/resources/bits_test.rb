require "test_helper"

class BitsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_bits_leaderboard
    stub_helix(:get, "bits/leaderboard", query: { "count" => "2", "period" => "week" },
      body: { data: [ { user_id: "1", rank: 1, score: 500 }, { user_id: "2", rank: 2, score: 100 } ], total: 2 }.to_json)

    leaderboard = @client.bits.leaderboard(count: 2, period: "week")

    assert_instance_of Twitch::BitsLeaderboardEntry, leaderboard.first
    assert_equal [ 1, 2 ], leaderboard.map(&:rank)
    assert_equal 2, leaderboard.total
  end

  def test_bits_cheermotes_without_broadcaster
    stub = stub_request(:get, "#{HELIX_URL}/bits/cheermotes")
      .to_return(status: 200, body: { data: [ { prefix: "Cheer", type: "global_first_party" } ] }.to_json, headers: { "Content-Type" => "application/json" })

    cheermotes = @client.bits.cheermotes

    assert_instance_of Twitch::Cheermote, cheermotes.first
    assert_equal "Cheer", cheermotes.first.prefix
    assert_requested stub
  end

  def test_bits_cheermotes_for_broadcaster
    stub_helix(:get, "bits/cheermotes", query: { "broadcaster_id" => "123" },
      body: { data: [ { prefix: "Custom", type: "channel_custom" } ] }.to_json)

    assert_equal "Custom", @client.bits.cheermotes(broadcaster_id: "123").first.prefix
  end
end
