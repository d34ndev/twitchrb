module Twitch
  class PollsResource < Resource
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("polls", params: params.merge(broadcaster_id: broadcaster_id))
      collection(response, type: Poll)
    end

    # Broadcaster ID must match the user in the OAuth token
    def create(broadcaster_id:, title:, choices:, duration:, **params)
      attrs = { broadcaster_id: broadcaster_id, title: title, choices: choices, duration: duration }
      response = post_request("polls", body: attrs.merge(params))

      Poll.new(response.body.dig("data")[0]) if response.success?
    end

    # Broadcaster ID must match the user in the OAuth token
    def end(broadcaster_id:, id:, status:)
      attrs = { broadcaster_id: broadcaster_id, id: id, status: status.upcase }
      response = patch_request("polls", body: attrs)

      Poll.new(response.body.dig("data")[0]) if response.success?
    end
  end
end
