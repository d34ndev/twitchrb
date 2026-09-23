require "test_helper"

class AdsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_ads_schedule
    stub_helix(:get, "channels/ads", query: { "broadcaster_id" => "123" },
      body: { data: [ { next_ad_at: 1_700_000_000, duration: 60, snooze_count: 1, preroll_free_time: 90 } ] }.to_json)

    schedule = @client.ads.schedule(broadcaster_id: "123")

    assert_instance_of Twitch::AdSchedule, schedule
    assert_equal 60, schedule.duration
    assert_equal 1, schedule.snooze_count
  end

  def test_ads_snooze_sends_broadcaster_id_in_query
    stub_helix(:post, "channels/ads/schedule/snooze", query: { "broadcaster_id" => "123" }, request_body: {},
      body: { data: [ { snooze_count: 0, next_ad_at: 1_700_000_300 } ] }.to_json)

    schedule = @client.ads.snooze(broadcaster_id: "123")

    assert_instance_of Twitch::AdSchedule, schedule
    assert_equal 0, schedule.snooze_count
  end
end
