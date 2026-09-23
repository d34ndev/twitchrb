require "test_helper"

class PaginationTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def page(ids, cursor: nil)
    { data: ids.map { |id| { id: id } }, pagination: cursor ? { cursor: cursor } : {} }.to_json
  end

  def stub_followers_pages
    @page1 = stub_helix(:get, "channels/followers", query: { "broadcaster_id" => "123", "first" => "2" }, body: page(%w[1 2], cursor: "c1"))
    @page2 = stub_helix(:get, "channels/followers", query: { "broadcaster_id" => "123", "first" => "2", "after" => "c1" }, body: page(%w[3 4], cursor: "c2"))
    @page3 = stub_helix(:get, "channels/followers", query: { "broadcaster_id" => "123", "first" => "2", "after" => "c2" }, body: page(%w[5]))
  end

  def test_next_page_repeats_the_request_with_the_cursor
    stub_followers_pages

    first = @client.channels.followers(broadcaster_id: "123", first: 2)
    second = first.next_page

    assert_instance_of Twitch::Collection, second
    assert_instance_of Twitch::User, second.first
    assert_equal %w[3 4], second.map(&:id)
    assert_equal "c2", second.cursor
  end

  def test_last_page_has_no_next_page
    stub_followers_pages

    last = @client.channels.followers(broadcaster_id: "123", first: 2).next_page.next_page

    assert_equal %w[5], last.map(&:id)
    refute last.next_page?
    assert_nil last.next_page
  end

  def test_auto_paginate_returns_every_item_across_pages
    stub_followers_pages

    ids = @client.channels.followers(broadcaster_id: "123", first: 2).auto_paginate.map(&:id).to_a

    assert_equal %w[1 2 3 4 5], ids
    assert_requested @page3, times: 1
  end

  def test_auto_paginate_only_fetches_pages_it_needs
    stub_followers_pages

    ids = @client.channels.followers(broadcaster_id: "123", first: 2).auto_paginate.first(3).map(&:id)

    assert_equal %w[1 2 3], ids
    assert_requested @page2, times: 1
    assert_not_requested @page3
  end

  def test_each_page_yields_every_page
    stub_followers_pages

    pages = []
    @client.channels.followers(broadcaster_id: "123", first: 2).each_page { |p| pages << p.map(&:id) }

    assert_equal [ %w[1 2], %w[3 4], %w[5] ], pages
  end

  def test_each_page_without_a_block_returns_an_enumerator
    stub_followers_pages

    pages = @client.channels.followers(broadcaster_id: "123", first: 2).each_page

    assert_kind_of Enumerator, pages
    assert_equal 3, pages.count
  end

  def test_next_page_keeps_repeated_params_and_drops_before
    stub_request(:get, "#{HELIX_URL}/streams?user_id=1&user_id=2&before=b0")
      .to_return(status: 200, body: page(%w[s1], cursor: "c1"), headers: { "Content-Type" => "application/json" })
    second = stub_request(:get, "#{HELIX_URL}/streams?user_id=1&user_id=2&after=c1")
      .to_return(status: 200, body: page(%w[s2]), headers: { "Content-Type" => "application/json" })

    streams = @client.streams.list(user_id: [ "1", "2" ], before: "b0").auto_paginate.to_a

    assert_equal %w[s1 s2], streams.map(&:id)
    assert_requested second
  end

  def test_stops_when_twitch_returns_a_cursor_with_an_empty_page
    stub_helix(:get, "games/top", query: { "first" => "1" }, body: page(%w[g1], cursor: "c1"))
    stub_helix(:get, "games/top", query: { "first" => "1", "after" => "c1" }, body: page([], cursor: "c2"))
    third = stub_helix(:get, "games/top", query: { "first" => "1", "after" => "c2" }, body: page(%w[g3]))

    games = @client.games.top(first: 1).auto_paginate.to_a

    assert_equal %w[g1], games.map(&:id)
    assert_not_requested third
  end

  def test_stops_when_twitch_repeats_a_cursor
    stub_helix(:get, "games/top", query: { "first" => "1" }, body: page(%w[g1], cursor: "same"))
    repeat = stub_helix(:get, "games/top", query: { "first" => "1", "after" => "same" }, body: page(%w[g2], cursor: "same"))

    games = @client.games.top(first: 1).auto_paginate.to_a

    assert_equal %w[g1 g2], games.map(&:id)
    assert_requested repeat, times: 1
  end

  def test_string_pagination_cursor_is_followed
    stub_helix(:get, "extensions/live", query: { "extension_id" => "ext" }, body: { data: [ { broadcaster_id: "1" } ], pagination: "c1" }.to_json)
    stub_helix(:get, "extensions/live", query: { "extension_id" => "ext", "after" => "c1" }, body: { data: [ { broadcaster_id: "2" } ], pagination: "" }.to_json)

    channels = @client.extensions.live_channels(extension_id: "ext").auto_paginate.to_a

    assert_equal %w[1 2], channels.map(&:broadcaster_id)
  end

  def test_errors_on_later_pages_are_raised
    stub_helix(:get, "games/top", body: page(%w[g1], cursor: "c1"))
    stub_helix(:get, "games/top", query: { "after" => "c1" }, status: 500, body: { error: "Internal Server Error", message: "" }.to_json)

    assert_raises(Twitch::Errors::InternalError) { @client.games.top.auto_paginate.to_a }
  end

  def test_collections_from_post_requests_do_not_paginate
    stub_helix(:post, "moderation/enforcements/status", query: { "broadcaster_id" => "123" },
      body: { data: [ { msg_id: "1", is_permitted: true } ], pagination: { cursor: "c1" } }.to_json)

    statuses = @client.automod.check_status_multiple(broadcaster_id: "123", messages: [ { msg_id: "1", msg_text: "hi" } ])

    refute statuses.next_page?
    assert_equal 1, statuses.auto_paginate.to_a.size
  end

  def test_collections_built_directly_do_not_paginate
    collection = Twitch::Collection.new(data: [ 1 ], total: 1, cursor: "c1")

    refute collection.next_page?
    assert_equal [ 1 ], collection.auto_paginate.to_a
  end
end
