module Twitch
  # Most of these endpoints require a signed JWT created by your Extension Backend Service,
  # rather than an OAuth token. Pass the JWT as the client's access_token.
  # See https://dev.twitch.tv/docs/extensions/building/#signing-the-jwt
  class ExtensionsResource < Resource
    # Requires a signed JWT
    def retrieve(extension_id:, extension_version: nil)
      response = get_request("extensions", params: { extension_id: extension_id, extension_version: extension_version }.compact)
      data = response.body.dig("data")

      return nil if data.nil? || data.empty?

      Extension.new(data[0])
    end

    def released(extension_id:, extension_version: nil)
      response = get_request("extensions/released", params: { extension_id: extension_id, extension_version: extension_version }.compact)
      data = response.body.dig("data")

      return nil if data.nil? || data.empty?

      Extension.new(data[0])
    end

    # Available parameters: first, after
    def live_channels(extension_id:, **params)
      response = get_request("extensions/live", params: params.merge(extension_id: extension_id))
      collection(response, type: ExtensionLiveChannel)
    end

    # Requires a signed JWT
    # segment: broadcaster, developer or global. Pass an array to get more than one.
    def configuration(extension_id:, segment:, broadcaster_id: nil)
      params = { extension_id: extension_id, segment: segment, broadcaster_id: broadcaster_id }.compact
      response = get_request("extensions/configurations", params: params)
      collection(response, type: ExtensionConfigurationSegment)
    end

    # Requires a signed JWT
    # Available attributes: broadcaster_id, content, version
    def set_configuration(extension_id:, segment:, **attributes)
      put_request("extensions/configurations", body: attributes.merge(extension_id: extension_id, segment: segment))
    end

    # Requires a signed JWT
    def set_required_configuration(broadcaster_id:, extension_id:, extension_version:, required_configuration:)
      attrs = { extension_id: extension_id, extension_version: extension_version, required_configuration: required_configuration }
      put_request(query_path("extensions/required_configuration", broadcaster_id: broadcaster_id), body: attrs)
    end

    # Requires a signed JWT
    # target: an array containing broadcast, global, or whisper-<user-id>
    def send_pubsub_message(broadcaster_id:, target:, message:, is_global_broadcast: nil)
      attrs = { broadcaster_id: broadcaster_id, target: Array(target), message: message, is_global_broadcast: is_global_broadcast }.compact
      post_request("extensions/pubsub", body: attrs)
    end

    # Requires a signed JWT
    def send_chat_message(broadcaster_id:, text:, extension_id:, extension_version:)
      attrs = { text: text, extension_id: extension_id, extension_version: extension_version }
      post_request(query_path("extensions/chat", broadcaster_id: broadcaster_id), body: attrs)
    end

    # Requires a signed JWT
    def secrets(extension_id:)
      response = get_request("extensions/jwt/secrets", params: { extension_id: extension_id })
      collection(response, type: ExtensionSecret)
    end

    # Requires a signed JWT
    # delay: seconds before the new secret becomes active (minimum 300)
    def create_secret(extension_id:, delay: nil)
      response = post_request(query_path("extensions/jwt/secrets", extension_id: extension_id, delay: delay), body: {})
      collection(response, type: ExtensionSecret)
    end

    # Requires an app access token whose Client ID matches the extension's
    def bits_products(should_include_all: nil)
      response = get_request("bits/extensions", params: { should_include_all: should_include_all }.compact)
      collection(response, type: ExtensionBitsProduct)
    end

    # Requires an app access token whose Client ID matches the extension's
    # cost: { amount: 100, type: "bits" }
    # Available attributes: in_development, expiration, is_broadcast
    def update_bits_product(sku:, cost:, display_name:, **attributes)
      attrs = attributes.merge(sku: sku, cost: cost, display_name: display_name)
      response = put_request("bits/extensions", body: attrs)
      ExtensionBitsProduct.new(response.body.dig("data")[0])
    end

    # Requires an app access token
    # Available parameters: id, first, after
    def transactions(extension_id:, **params)
      response = get_request("extensions/transactions", params: params.merge(extension_id: extension_id))
      collection(response, type: ExtensionTransaction)
    end
  end
end
