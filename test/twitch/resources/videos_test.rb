require "test_helper"

class VideosResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_videos_list_by_user_id
    stub_helix(:get, "videos",
      query: { "user_id" => "141981764", "first" => "5" },
      fixture: "get_videos")

    videos = @client.videos.list(user_id: "141981764", first: 5)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_by_game_id
    stub_helix(:get, "videos",
      query: { "game_id" => "33214", "first" => "3" },
      fixture: "get_videos")

    videos = @client.videos.list(game_id: "33214", first: 3)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_with_period
    stub_helix(:get, "videos",
      query: { "user_id" => "141981764", "period" => "week", "first" => "5" },
      fixture: "get_videos")

    videos = @client.videos.list(user_id: "141981764", period: "week", first: 5)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_with_sort
    stub_helix(:get, "videos",
      query: { "user_id" => "141981764", "sort" => "time", "first" => "5" },
      fixture: "get_videos")

    videos = @client.videos.list(user_id: "141981764", sort: "time", first: 5)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_with_type
    stub_helix(:get, "videos",
      query: { "user_id" => "141981764", "type" => "archive", "first" => "5" },
      fixture: "get_videos")

    videos = @client.videos.list(user_id: "141981764", type: "archive", first: 5)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_with_language
    stub_helix(:get, "videos",
      query: { "user_id" => "141981764", "language" => "en", "first" => "5" },
      fixture: "get_videos")

    videos = @client.videos.list(user_id: "141981764", language: "en", first: 5)

    assert_equal Twitch::Collection, videos.class
    assert videos.data.all? { |video| video.is_a?(Twitch::Video) }
  end

  def test_videos_list_missing_params_raises_error
    assert_raises(ArgumentError) { @client.videos.list(first: 5) }
  end

  def test_videos_list_by_ids
    stub_request(:get, "#{HELIX_URL}/videos?id=1&id=2")
      .to_return(status: 200, body: { data: [ { id: "1" }, { id: "2" } ] }.to_json, headers: { "Content-Type" => "application/json" })

    videos = @client.videos.list(id: [ "1", "2" ])

    assert_equal %w[1 2], videos.map(&:id)
  end

  def test_videos_retrieve
    stub_helix(:get, "videos", query: { "id" => "335921245" }, fixture: "get_videos")

    video = @client.videos.retrieve(id: "335921245")

    assert_equal Twitch::Video, video.class
    assert_equal "335921245", video.id
  end

  def test_videos_delete_requires_scope
    stub_request(:delete, "#{HELIX_URL}/videos")
      .with(query: { "id" => "1234567890" })
      .to_return(
        status: 401,
        body: { error: "Unauthorized", status: 401, message: "Missing scope: channel:manage:videos" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.videos.delete(video_id: "1234567890")
    end
  end
end
