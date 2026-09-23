module Twitch
  class UnbanRequestsResource < Resource
    def list(broadcaster_id:, moderator_id:, status:, **params)
      attrs = { broadcaster_id: broadcaster_id, moderator_id: moderator_id, status: status }
      response = get_request("moderation/unban_requests", params: attrs.merge(params))
      Collection.from_response(response, type: UnbanRequest)
    end

    def resolve(broadcaster_id:, moderator_id:, id:, status:, **params)
      attrs = { broadcaster_id: broadcaster_id, moderator_id: moderator_id, unban_request_id: id, status: status }
      response = patch_request(query_path("moderation/unban_requests", attrs.merge(params)), body: {})
      UnbanRequest.new(response.body.dig("data")[0])
    end
  end
end
