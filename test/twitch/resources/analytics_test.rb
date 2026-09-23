require "test_helper"

class AnalyticsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_analytics_extensions
    stub_helix(:get, "analytics/extensions", query: { "extension_id" => "ext-1", "type" => "overview_v2" },
      body: { data: [ { extension_id: "ext-1", URL: "https://example.com/report.csv", type: "overview_v2" } ], pagination: {} }.to_json)

    reports = @client.analytics.extensions(extension_id: "ext-1", type: "overview_v2")

    assert_instance_of Twitch::AnalyticsReport, reports.first
    assert_equal "https://example.com/report.csv", reports.first.URL
  end

  def test_analytics_games
    stub_helix(:get, "analytics/games", query: { "game_id" => "493057" },
      body: { data: [ { game_id: "493057", URL: "https://example.com/game.csv" } ], pagination: { cursor: "abc" } }.to_json)

    reports = @client.analytics.games(game_id: "493057")

    assert_equal "493057", reports.first.game_id
    assert_equal "abc", reports.cursor
  end
end
