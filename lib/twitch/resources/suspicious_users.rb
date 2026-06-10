module Twitch
  class SuspiciousUsersResource < Resource
    # Required scope: moderator:manage:suspicious_users
    # moderator_id must match the currently authenticated moderator
    def create(broadcaster_id:, moderator_id:, user_id:, status:)
      attrs = { user_id: user_id, status: status }
      response = post_request(
        "moderation/suspicious_users?broadcaster_id=#{broadcaster_id}&moderator_id=#{moderator_id}",
        body: attrs
      )

      SuspiciousUser.new(response.body.dig("data")[0])
    end

    # Required scope: moderator:manage:suspicious_users
    # moderator_id must match the currently authenticated moderator
    def delete(broadcaster_id:, moderator_id:, user_id:)
      response = delete_request(
        "moderation/suspicious_users?broadcaster_id=#{broadcaster_id}&moderator_id=#{moderator_id}&user_id=#{user_id}"
      )

      # delete_request returns true for 204 No Content responses
      return true unless response.respond_to?(:body)

      SuspiciousUser.new(response.body.dig("data")[0])
    end
  end
end
