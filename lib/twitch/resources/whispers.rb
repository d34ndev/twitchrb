module Twitch
  class WhispersResource < Resource
    def create(from_user_id:, to_user_id:, message:)
      post_request(query_path("whispers", from_user_id: from_user_id, to_user_id: to_user_id), body: { message: message })
    end
  end
end
