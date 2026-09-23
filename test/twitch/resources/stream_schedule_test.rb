require "test_helper"

class StreamScheduleResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_stream_schedule_update_sends_everything_in_query
    stub_helix(:patch, "schedule/settings",
      query: {
        "broadcaster_id" => "123",
        "is_vacation_enabled" => "true",
        "vacation_start_time" => "2026-10-01T00:00:00Z",
        "vacation_end_time" => "2026-10-08T00:00:00Z",
        "timezone" => "Europe/London"
      },
      request_body: {},
      status: 204, body: "")

    result = @client.stream_schedule.update(
      broadcaster_id: "123",
      is_vacation_enabled: true,
      vacation_start_time: "2026-10-01T00:00:00Z",
      vacation_end_time: "2026-10-08T00:00:00Z",
      timezone: "Europe/London"
    )

    assert_equal true, result
  end

  def test_stream_schedule_create_segment_sends_broadcaster_id_in_query
    stub_helix(:post, "schedule/segment",
      query: { "broadcaster_id" => "123" },
      request_body: { start_time: "2026-10-01T18:00:00Z", timezone: "Europe/London", duration: "120", is_recurring: true, title: "Game night" },
      body: { data: { broadcaster_id: "123", segments: [ { id: "seg-1", title: "Game night" } ] } }.to_json)

    schedule = @client.stream_schedule.create_segment(
      broadcaster_id: "123",
      start_time: "2026-10-01T18:00:00Z",
      timezone: "Europe/London",
      duration: "120",
      is_recurring: true,
      title: "Game night"
    )

    assert_instance_of Twitch::StreamSchedule, schedule
    assert_equal "seg-1", schedule.data.segments.first.id
  end

  def test_stream_schedule_update_segment_sends_ids_in_query
    stub_helix(:patch, "schedule/segment",
      query: { "broadcaster_id" => "123", "id" => "seg-1" },
      request_body: { is_canceled: true },
      body: { data: { broadcaster_id: "123", segments: [ { id: "seg-1", canceled_until: "2026-10-02T00:00:00Z" } ] } }.to_json)

    schedule = @client.stream_schedule.update_segment(broadcaster_id: "123", id: "seg-1", is_canceled: true)

    assert_instance_of Twitch::StreamSchedule, schedule
  end
end
