require "test_helper"

class UnbanRequestsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_unban_requests_resolve_sends_everything_in_query
    stub_helix(:patch, "moderation/unban_requests",
      query: {
        "broadcaster_id" => "123",
        "moderator_id" => "321",
        "unban_request_id" => "req-1",
        "status" => "approved",
        "resolution_text" => "Welcome back"
      },
      request_body: {},
      body: { data: [ { id: "req-1", status: "approved", resolution_text: "Welcome back" } ] }.to_json)

    request = @client.unban_requests.resolve(broadcaster_id: "123", moderator_id: "321", id: "req-1", status: "approved", resolution_text: "Welcome back")

    assert_instance_of Twitch::UnbanRequest, request
    assert_equal "approved", request.status
  end
end
