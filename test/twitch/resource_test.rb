require "test_helper"

class ResourceTest < Minitest::Test
  class TestResource < Twitch::Resource
    def get(url)
      send(:get_request, url)
    end
  end

  def setup
    super
    @client = Twitch::Client.new(client_id: "123", access_token: "abc123")
    @resource = TestResource.new(@client)
  end

  def test_rejects_protocol_relative_request_paths
    error = assert_raises(Twitch::UnsafeRequestPathError) do
      @resource.get("//evil.example/steal")
    end

    assert_equal "request path must be relative to the Twitch API base URL", error.message
  end

  def test_rejects_absolute_request_paths
    assert_raises(Twitch::UnsafeRequestPathError) do
      @resource.get("https://evil.example/steal")
    end
  end

  def test_handles_non_json_response_bodies
    stub_request(:get, "#{HELIX_URL}/schedule/icalendar")
      .to_return(status: 200, body: "BEGIN:VCALENDAR", headers: { "Content-Type" => "text/calendar" })

    response = @resource.get("schedule/icalendar")

    assert_equal "BEGIN:VCALENDAR", response.body
  end

  def test_raises_for_error_status_with_non_json_body
    stub_request(:get, "#{HELIX_URL}/users")
      .to_return(status: 500, body: "<html>Internal Server Error</html>", headers: { "Content-Type" => "text/html" })

    assert_raises(Twitch::Errors::InternalError) do
      @resource.get("users")
    end
  end
end
