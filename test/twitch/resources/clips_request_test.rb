require "test_helper"

class ClipsRequestTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_clips_create_uses_query_params
    stub_request(:post, "#{HELIX_URL}/clips")
      .with(query: { "broadcaster_id" => "123", "title" => "Best moment", "duration" => "12.5" })
      .to_return(
        status: 202,
        body: { data: [ { id: "clip-1", edit_url: "https://clips.twitch.tv/clip-1/edit" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    clip = @client.clips.create(broadcaster_id: "123", title: "Best moment", duration: 12.5)

    assert_instance_of Twitch::Clip, clip
    assert_equal "clip-1", clip.id
  end

  def test_clips_create_from_vod_uses_query_params
    stub_request(:post, "#{HELIX_URL}/videos/clips")
      .with(query: {
        "editor_id" => "321",
        "broadcaster_id" => "123",
        "vod_id" => "vod-1",
        "vod_offset" => "45",
        "duration" => "15.0",
        "title" => "VOD highlight"
      })
      .to_return(
        status: 202,
        body: { data: [ { id: "clip-2", edit_url: "https://clips.twitch.tv/clip-2/edit" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    clip = @client.clips.create_from_vod(
      editor_id: "321",
      broadcaster_id: "123",
      vod_id: "vod-1",
      vod_offset: 45,
      duration: 15.0,
      title: "VOD highlight"
    )

    assert_instance_of Twitch::Clip, clip
    assert_equal "clip-2", clip.id
  end

  def test_clips_downloads_returns_collection
    stub_request(:get,
      "#{HELIX_URL}/clips/downloads?editor_id=321&broadcaster_id=123&clip_id=clip-1&clip_id=clip-2")
      .to_return(
        status: 200,
        body: {
          data: [
            { clip_id: "clip-1", landscape_download_url: "https://cdn.example/clip-1.mp4", portrait_download_url: nil },
            { clip_id: "clip-2", landscape_download_url: "https://cdn.example/clip-2.mp4", portrait_download_url: "https://cdn.example/clip-2-portrait.mp4" }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    downloads = @client.clips.downloads(
      editor_id: "321",
      broadcaster_id: "123",
      clip_ids: [ "clip-1", "clip-2" ]
    )

    assert_instance_of Twitch::Collection, downloads
    assert downloads.data.all? { |download| download.is_a?(Twitch::ClipDownload) }
    assert_equal "https://cdn.example/clip-1.mp4", downloads.first.landscape_download_url
    assert_equal "https://cdn.example/clip-2-portrait.mp4", downloads.last.portrait_download_url
  end
end
