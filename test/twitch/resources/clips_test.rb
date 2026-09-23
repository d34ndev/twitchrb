require "test_helper"

class ClipsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_clips_list_by_broadcaster_id
    stub_helix(:get, "clips",
      query: { "broadcaster_id" => "141981764", "first" => "5" },
      fixture: "get_clips")

    clips = @client.clips.list(broadcaster_id: "141981764", first: 5)

    assert_equal Twitch::Collection, clips.class
    assert clips.data.count <= 5
    assert clips.data.all? { |clip| clip.is_a?(Twitch::Clip) }
  end

  def test_clips_list_by_game_id
    stub_helix(:get, "clips",
      query: { "game_id" => "33214", "first" => "3" },
      fixture: "get_clips")

    clips = @client.clips.list(game_id: "33214", first: 3)

    assert_equal Twitch::Collection, clips.class
    assert clips.data.all? { |clip| clip.is_a?(Twitch::Clip) }
  end

  def test_clips_list_with_date_range
    stub_helix(:get, "clips",
      query: {
        "broadcaster_id" => "141981764",
        "started_at" => "2023-01-01T00:00:00Z",
        "ended_at" => "2023-12-31T23:59:59Z",
        "first" => "5"
      },
      fixture: "get_clips")

    clips = @client.clips.list(
      broadcaster_id: "141981764",
      started_at: "2023-01-01T00:00:00Z",
      ended_at: "2023-12-31T23:59:59Z",
      first: 5
    )

    assert_equal Twitch::Collection, clips.class
    assert clips.data.all? { |clip| clip.is_a?(Twitch::Clip) }
  end

  def test_clips_list_missing_params_raises_error
    assert_raises(ArgumentError) { @client.clips.list(first: 5) }
  end

  def test_clips_list_by_ids
    stub_request(:get, "#{HELIX_URL}/clips?id=clip-1&id=clip-2")
      .to_return(status: 200, body: { data: [ { id: "clip-1" }, { id: "clip-2" } ] }.to_json, headers: { "Content-Type" => "application/json" })

    clips = @client.clips.list(id: [ "clip-1", "clip-2" ])

    assert_equal %w[clip-1 clip-2], clips.map(&:id)
  end

  def test_clips_retrieve
    stub_helix(:get, "clips",
      query: { "id" => "AwkwardHelplessSalamanderSwiftRage" },
      fixture: "get_clip")

    clip = @client.clips.retrieve(id: "AwkwardHelplessSalamanderSwiftRage")

    assert_equal Twitch::Clip, clip.class
    assert_equal "AwkwardHelplessSalamanderSwiftRage", clip.id
  end

  def test_clips_create_requires_scope
    stub_request(:post, "#{HELIX_URL}/clips")
      .with(query: { "broadcaster_id" => "141981764", "has_delay" => "false" })
      .to_return(
        status: 401,
        body: { error: "Unauthorized", status: 401, message: "Missing scope: clips:edit" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.clips.create(broadcaster_id: "141981764", has_delay: false)
    end
  end
end
