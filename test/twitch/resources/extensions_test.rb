require "test_helper"

class ExtensionsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_extensions_retrieve
    stub_helix(:get, "extensions", query: { "extension_id" => "ext-1" }, body: { data: [ { id: "ext-1", name: "Test" } ] }.to_json)

    extension = @client.extensions.retrieve(extension_id: "ext-1")

    assert_instance_of Twitch::Extension, extension
    assert_equal "Test", extension.name
  end

  def test_extensions_released_with_version
    stub_helix(:get, "extensions/released", query: { "extension_id" => "ext-1", "extension_version" => "1.0.0" },
      body: { data: [ { id: "ext-1", version: "1.0.0" } ] }.to_json)

    assert_equal "1.0.0", @client.extensions.released(extension_id: "ext-1", extension_version: "1.0.0").version
  end

  def test_extensions_live_channels_handles_string_pagination
    stub_helix(:get, "extensions/live", query: { "extension_id" => "ext-1", "first" => "1" },
      body: { data: [ { broadcaster_id: "123", title: "Live" } ], pagination: "cursor-string" }.to_json)

    channels = @client.extensions.live_channels(extension_id: "ext-1", first: 1)

    assert_instance_of Twitch::ExtensionLiveChannel, channels.first
    assert_equal "cursor-string", channels.cursor
  end

  def test_extensions_configuration_with_multiple_segments
    stub_helix(:get, "extensions/configurations?extension_id=ext-1&segment=global&segment=developer",
      body: { data: [ { segment: "global", content: "{}", version: "1" }, { segment: "developer", content: "{}", version: "1" } ] }.to_json)

    segments = @client.extensions.configuration(extension_id: "ext-1", segment: [ "global", "developer" ])

    assert_instance_of Twitch::ExtensionConfigurationSegment, segments.first
    assert_equal [ "global", "developer" ], segments.map(&:segment)
  end

  def test_extensions_set_configuration
    stub_helix(:put, "extensions/configurations",
      request_body: { extension_id: "ext-1", segment: "broadcaster", broadcaster_id: "123", content: "{\"a\":1}", version: "2" },
      status: 204, body: "")

    result = @client.extensions.set_configuration(extension_id: "ext-1", segment: "broadcaster", broadcaster_id: "123", content: "{\"a\":1}", version: "2")

    assert_equal true, result
  end

  def test_extensions_set_required_configuration_sends_broadcaster_id_in_query
    stub_helix(:put, "extensions/required_configuration",
      query: { "broadcaster_id" => "123" },
      request_body: { extension_id: "ext-1", extension_version: "1.0.0", required_configuration: "RCS" },
      status: 204, body: "")

    assert_equal true, @client.extensions.set_required_configuration(broadcaster_id: "123", extension_id: "ext-1", extension_version: "1.0.0", required_configuration: "RCS")
  end

  def test_extensions_send_pubsub_message
    stub_helix(:post, "extensions/pubsub",
      request_body: { broadcaster_id: "123", target: [ "broadcast" ], message: "hello" },
      status: 204, body: "")

    assert_equal true, @client.extensions.send_pubsub_message(broadcaster_id: "123", target: "broadcast", message: "hello")
  end

  def test_extensions_send_chat_message_sends_broadcaster_id_in_query
    stub_helix(:post, "extensions/chat",
      query: { "broadcaster_id" => "123" },
      request_body: { text: "hello", extension_id: "ext-1", extension_version: "1.0.0" },
      status: 204, body: "")

    assert_equal true, @client.extensions.send_chat_message(broadcaster_id: "123", text: "hello", extension_id: "ext-1", extension_version: "1.0.0")
  end

  def test_extensions_secrets
    stub_helix(:get, "extensions/jwt/secrets", query: { "extension_id" => "ext-1" },
      body: { data: [ { format_version: 1, secrets: [ { content: "secret", active_at: "2026-01-01T00:00:00Z" } ] } ] }.to_json)

    secrets = @client.extensions.secrets(extension_id: "ext-1")

    assert_instance_of Twitch::ExtensionSecret, secrets.first
    assert_equal "secret", secrets.first.secrets.first.content
  end

  def test_extensions_create_secret_sends_params_in_query
    stub_helix(:post, "extensions/jwt/secrets", query: { "extension_id" => "ext-1", "delay" => "600" }, request_body: {},
      body: { data: [ { format_version: 1, secrets: [] } ] }.to_json)

    assert_equal 1, @client.extensions.create_secret(extension_id: "ext-1", delay: 600).first.format_version
  end

  def test_extensions_bits_products
    stub_helix(:get, "bits/extensions", query: { "should_include_all" => "true" },
      body: { data: [ { sku: "sku-1", cost: { amount: 100, type: "bits" } } ] }.to_json)

    products = @client.extensions.bits_products(should_include_all: true)

    assert_instance_of Twitch::ExtensionBitsProduct, products.first
    assert_equal 100, products.first.cost.amount
  end

  def test_extensions_update_bits_product
    stub_helix(:put, "bits/extensions",
      request_body: { sku: "sku-1", cost: { amount: 100, type: "bits" }, display_name: "Thing", in_development: true },
      body: { data: [ { sku: "sku-1", display_name: "Thing", in_development: true } ] }.to_json)

    product = @client.extensions.update_bits_product(sku: "sku-1", cost: { amount: 100, type: "bits" }, display_name: "Thing", in_development: true)

    assert_instance_of Twitch::ExtensionBitsProduct, product
    assert_equal "Thing", product.display_name
  end

  def test_extensions_transactions
    stub_helix(:get, "extensions/transactions", query: { "extension_id" => "ext-1", "first" => "5" },
      body: { data: [ { id: "txn-1", product_type: "BITS_IN_EXTENSION" } ], pagination: { cursor: "c" } }.to_json)

    transactions = @client.extensions.transactions(extension_id: "ext-1", first: 5)

    assert_instance_of Twitch::ExtensionTransaction, transactions.first
    assert_equal "c", transactions.cursor
  end
end
