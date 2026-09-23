require "test_helper"

class EventsubConduitsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_user_token")
    @app_client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_app_token")
  end

  def test_eventsub_conduits_list_with_user_token_fails
    stub_request(:get, "#{HELIX_URL}/eventsub/conduits")
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.eventsub_conduits.list
    end
  end

  def test_eventsub_conduits_list_with_app_token
    stub_request(:get, "#{HELIX_URL}/eventsub/conduits")
      .to_return(status: 200, body: helix_fixture("get_conduits"), headers: json_headers)

    conduits = @app_client.eventsub_conduits.list

    assert_equal Twitch::Collection, conduits.class
    assert conduits.data.all? { |conduit| conduit.is_a?(Twitch::EventsubConduit) }
  end

  def test_eventsub_conduits_create_with_user_token_fails
    stub_request(:post, "#{HELIX_URL}/eventsub/conduits")
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)

    assert_raises(Twitch::Errors::AuthenticationMissingError) do
      @client.eventsub_conduits.create(shard_count: 1)
    end
  end

  def test_eventsub_conduits_create_with_app_token
    conduit_id = "26b1c993-bfcf-44d9-b876-379dacafe75a"

    stub_request(:post, "#{HELIX_URL}/eventsub/conduits")
      .with(body: hash_including("shard_count" => 1))
      .to_return(
        status: 200,
        body: { data: [ { id: conduit_id, shard_count: 1 } ] }.to_json,
        headers: json_headers
      )

    stub_request(:delete, "#{HELIX_URL}/eventsub/conduits")
      .with(query: { "id" => conduit_id })
      .to_return(status: 204, body: "")

    conduit = @app_client.eventsub_conduits.create(shard_count: 1)

    assert_equal Twitch::EventsubConduit, conduit.class
    assert_equal conduit_id, conduit.id
    assert_equal 1, conduit.shard_count

    @app_client.eventsub_conduits.delete(id: conduit.id)
  end

  def test_eventsub_conduits_create_and_manage_lifecycle_with_app_token
    conduit_id = "26b1c993-bfcf-44d9-b876-379dacafe75a"

    stub_request(:post, "#{HELIX_URL}/eventsub/conduits")
      .with(body: hash_including("shard_count" => 2))
      .to_return(
        status: 200,
        body: { data: [ { id: conduit_id, shard_count: 2 } ] }.to_json,
        headers: json_headers
      )

    stub_request(:get, "#{HELIX_URL}/eventsub/conduits/shards")
      .with(query: { "conduit_id" => conduit_id })
      .to_return(status: 200, body: helix_fixture("get_conduit_shards"), headers: json_headers)

    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits")
      .with(body: hash_including("id" => conduit_id, "shard_count" => 3))
      .to_return(
        status: 200,
        body: { data: [ { id: conduit_id, shard_count: 3 } ] }.to_json,
        headers: json_headers
      )

    stub_request(:delete, "#{HELIX_URL}/eventsub/conduits")
      .with(query: { "id" => conduit_id })
      .to_return(status: 204, body: "")

    conduit = @app_client.eventsub_conduits.create(shard_count: 2)
    assert_equal 2, conduit.shard_count

    shards = @app_client.eventsub_conduits.shards(id: conduit.id)
    assert_equal Twitch::Collection, shards.class
    assert shards.data.all? { |shard| shard.is_a?(Twitch::EventsubConduitShard) }

    updated = @app_client.eventsub_conduits.update(id: conduit.id, shard_count: 3)
    assert_equal 3, updated.shard_count

    @app_client.eventsub_conduits.delete(id: conduit.id)
  end

  def test_eventsub_conduits_operations_with_user_token_fail
    stub_request(:post, "#{HELIX_URL}/eventsub/conduits")
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)
    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits")
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)
    stub_request(:get, %r{#{HELIX_URL}/eventsub/conduits/shards})
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)
    stub_request(:delete, %r{#{HELIX_URL}/eventsub/conduits\?})
      .to_return(status: 401, body: unauthorized_body, headers: json_headers)

    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.eventsub_conduits.create(shard_count: 3) }
    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.eventsub_conduits.update(id: "fake-id", shard_count: 2) }
    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.eventsub_conduits.shards(id: "fake-id") }
    assert_raises(Twitch::Errors::AuthenticationMissingError) { @client.eventsub_conduits.delete(id: "fake-id") }
  end

  def test_update_shards_sends_a_single_request_for_up_to_100_shards
    shards = (0...100).map { |i| shard(i) }
    stub = stub_request(:patch, "#{HELIX_URL}/eventsub/conduits/shards")
      .with(body: { conduit_id: "conduit-1", shards: shards }.to_json)
      .to_return(status: 202, body: shard_response(0...100), headers: json_headers)

    result = @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: shards)

    assert_requested stub, times: 1
    assert_equal 100, result.data.size
    assert_instance_of Twitch::EventsubConduitShard, result.first
    assert_empty result.errors
  end

  def test_update_shards_batches_more_than_100_shards
    batch_sizes = []
    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits/shards").to_return do |request|
      body = JSON.parse(request.body)
      assert_equal "conduit-1", body["conduit_id"]
      batch_sizes << body["shards"].size
      { status: 202, body: shard_response(body["shards"].map { |s| s["id"] }), headers: json_headers }
    end

    result = @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: (0...250).map { |i| shard(i) })

    assert_equal [ 100, 100, 50 ], batch_sizes
    assert_equal 250, result.data.size
    assert_equal 250, result.total
    assert_equal (0...250).map(&:to_s), result.map(&:id)
  end

  def test_update_shards_exposes_failed_shards
    errors = [ { id: "5", message: "The shard id is outside of the conduit's range.", code: "invalid_parameter" } ]
    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits/shards")
      .to_return(status: 202, body: shard_response([ 0 ], errors: errors), headers: json_headers)

    result = @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: [ shard(0), shard(5) ])

    assert_equal [ "0" ], result.map(&:id)
    assert_equal 1, result.errors.size
    assert_equal "5", result.errors.first.id
    assert_equal "invalid_parameter", result.errors.first.code
  end

  def test_update_shards_merges_errors_across_batches
    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits/shards").to_return do |request|
      ids = JSON.parse(request.body)["shards"].map { |s| s["id"] }
      failed = ids.last
      {
        status: 202,
        body: shard_response(ids - [ failed ], errors: [ { id: failed, message: "failed", code: "invalid_parameter" } ]),
        headers: json_headers
      }
    end

    result = @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: (0...150).map { |i| shard(i) })

    assert_equal 148, result.data.size
    assert_equal [ "99", "149" ], result.errors.map(&:id)
  end

  def test_update_shards_with_no_shards_sends_nothing
    result = @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: [])

    assert_empty result.data
    assert_not_requested :patch, "#{HELIX_URL}/eventsub/conduits/shards"
  end

  def test_update_shards_raises_when_a_batch_fails
    calls = 0
    stub_request(:patch, "#{HELIX_URL}/eventsub/conduits/shards").to_return do |request|
      calls += 1
      if calls == 1
        { status: 202, body: shard_response(JSON.parse(request.body)["shards"].map { |s| s["id"] }), headers: json_headers }
      else
        { status: 400, body: { error: "Bad Request", status: 400, message: "Invalid conduit" }.to_json, headers: json_headers }
      end
    end

    assert_raises(Twitch::Errors::BadRequestError) do
      @app_client.eventsub_conduits.update_shards(id: "conduit-1", shards: (0...150).map { |i| shard(i) })
    end
    assert_equal 2, calls
  end

  private

  def shard(id)
    { id: id.to_s, transport: { method: "webhook", callback: "https://example.com/webhook", secret: "a-secret-value" } }
  end

  def shard_response(ids, errors: [])
    { data: ids.map { |id| { id: id.to_s, status: "webhook_callback_verification_pending", transport: { method: "webhook" } } }, errors: errors }.to_json
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end

  def unauthorized_body
    { error: "Unauthorized", status: 401, message: "OAuth token is missing" }.to_json
  end

end
