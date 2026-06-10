module Twitch
  class RaidsResource < Resource
    # from_broadcaster_id must match the user in the OAuth token
    def create(from_broadcaster_id:, to_broadcaster_id:)
      attrs = { from_broadcaster_id: from_broadcaster_id, to_broadcaster_id: to_broadcaster_id }

      response = post_request("raids", body: attrs)

      Raid.new(response.body.dig("data")[0]) if response.success?
    end

    # broadcaster_id must match the user in the OAuth token
    def delete(broadcaster_id:)
      delete_request("raids", params: { broadcaster_id: broadcaster_id })
    end
  end
end
