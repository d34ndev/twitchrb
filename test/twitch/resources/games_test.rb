require "test_helper"

class GamesResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_games_retrieve_by_id
    stub_helix(:get, "games", query: { "id" => "33214" }, fixture: "get_games")

    game = @client.games.retrieve(id: "33214")

    assert_equal Twitch::Game, game.class
    assert_equal "Fortnite", game.name
  end

  def test_games_retrieve_by_ids
    stub_request(:get, "#{HELIX_URL}/games?id=33214&id=509658")
      .to_return(status: 200, body: helix_fixture("get_games_many"),
        headers: { "Content-Type" => "application/json" })

    games = @client.games.retrieve(ids: [ "33214", "509658" ])

    assert_equal Twitch::Collection, games.class
    assert_equal 2, games.data.count
    assert games.data.all? { |game| game.is_a?(Twitch::Game) }
  end

  def test_games_retrieve_by_name
    stub_helix(:get, "games", query: { "name" => "Fortnite" }, fixture: "get_games")

    game = @client.games.retrieve(name: "Fortnite")

    assert_equal Twitch::Game, game.class
    assert_equal "33214", game.id
  end

  def test_games_retrieve_by_names
    stub_request(:get, "#{HELIX_URL}/games?name=Fortnite&name=Just%20Chatting")
      .to_return(status: 200, body: helix_fixture("get_games_many"),
        headers: { "Content-Type" => "application/json" })

    games = @client.games.retrieve(names: [ "Fortnite", "Just Chatting" ])

    assert_equal Twitch::Collection, games.class
    assert_equal 2, games.data.count
    assert games.data.all? { |game| game.is_a?(Twitch::Game) }
  end

  def test_games_retrieve_by_names_with_single_match
    stub_request(:get, "#{HELIX_URL}/games?name=Fortnite")
      .to_return(status: 200, body: helix_fixture("get_games"),
        headers: { "Content-Type" => "application/json" })

    games = @client.games.retrieve(names: [ "Fortnite" ])

    assert_equal Twitch::Collection, games.class
    assert_equal 1, games.data.count
  end

  def test_games_retrieve_by_id_with_no_match
    stub_helix(:get, "games", query: { "id" => "0" }, body: { data: [] }.to_json)

    assert_nil @client.games.retrieve(id: "0")
  end

  def test_games_retrieve_missing_params_raises_error
    assert_raises(ArgumentError) { @client.games.retrieve }
  end

  def test_games_top
    stub_helix(:get, "games/top", query: { "first" => "10" }, fixture: "get_top_games")

    games = @client.games.top(first: 10)

    assert_equal Twitch::Collection, games.class
    assert games.data.count <= 10
    assert games.data.all? { |game| game.is_a?(Twitch::Game) }
  end

  def test_games_top_with_pagination
    stub_helix(:get, "games/top", query: { "first" => "5" }, fixture: "get_top_games")
    stub_helix(:get, "games/top",
      query: { "first" => "5", "after" => "eyJiIjpudWxsLCJhIjp7IkN1cnNvciI6IjUifX0" },
      fixture: "get_top_games_page2")

    first_page = @client.games.top(first: 5)
    assert first_page.cursor, "expected pagination cursor in fixture"

    page2 = @client.games.top(first: 5, after: first_page.cursor)

    assert_equal Twitch::Collection, page2.class
    assert_equal 2, page2.data.count
    assert page2.data.all? { |game| game.is_a?(Twitch::Game) }
  end
end
