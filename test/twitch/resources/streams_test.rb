require "test_helper"

class StreamsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_streams_list
    stub_helix(:get, "streams", query: { "first" => "10" }, fixture: "get_streams")

    streams = @client.streams.list(first: 10)

    assert_equal Twitch::Collection, streams.class
    assert streams.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_list_by_user_id
    stub_request(:get, "#{HELIX_URL}/streams?user_id=141981764")
      .to_return(status: 200, body: helix_fixture("get_streams"),
        headers: { "Content-Type" => "application/json" })

    streams = @client.streams.list(user_id: [ "141981764" ])

    assert_equal Twitch::Collection, streams.class
    assert streams.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_list_by_user_login
    stub_request(:get, "#{HELIX_URL}/streams?user_login=twitchdev")
      .to_return(status: 200, body: helix_fixture("get_streams"),
        headers: { "Content-Type" => "application/json" })

    streams = @client.streams.list(user_login: [ "twitchdev" ])

    assert_equal Twitch::Collection, streams.class
    assert streams.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_list_by_game_id
    stub_request(:get, "#{HELIX_URL}/streams?game_id=33214&first=5")
      .to_return(status: 200, body: helix_fixture("get_streams"),
        headers: { "Content-Type" => "application/json" })

    streams = @client.streams.list(game_id: [ "33214" ], first: 5)

    assert_equal Twitch::Collection, streams.class
    assert streams.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_list_with_language
    stub_request(:get, "#{HELIX_URL}/streams?language=en&first=3")
      .to_return(status: 200, body: helix_fixture("get_streams"),
        headers: { "Content-Type" => "application/json" })

    streams = @client.streams.list(language: [ "en" ], first: 3)

    assert_equal Twitch::Collection, streams.class
    assert streams.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_list_with_pagination
    stub_helix(:get, "streams", query: { "first" => "5" }, fixture: "get_streams")
    stub_helix(:get, "streams",
      query: { "first" => "5", "after" => "eyJiIjpudWxsLCJhIjp7Ik9mZnNldCI6MX19" },
      fixture: "get_streams")

    first_page = @client.streams.list(first: 5)
    assert first_page.cursor, "expected pagination cursor in fixture"

    page2 = @client.streams.list(first: 5, after: first_page.cursor)

    assert_equal Twitch::Collection, page2.class
    assert page2.data.all? { |stream| stream.is_a?(Twitch::Stream) }
  end

  def test_streams_followed_requires_scope
    stub_request(:get, "#{HELIX_URL}/streams/followed")
      .with(query: { "user_id" => "141981764", "first" => "5" })
      .to_return(
        status: 401,
        body: { error: "Unauthorized", status: 401, message: "Missing scope: user:read:follows" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.streams.followed(user_id: "141981764", first: 5)
    end
  end
end
