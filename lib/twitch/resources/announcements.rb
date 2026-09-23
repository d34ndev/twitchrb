module Twitch
  class AnnouncementsResource < Resource
    # Moderator ID must match the user in the OAuth token
    # Required scope: moderator:manage:announcements
    def create(broadcaster_id:, moderator_id:, message:, color: nil, for_source_only: nil)
      attrs = { message: message, color: color, for_source_only: for_source_only }

      post_request(query_path("chat/announcements", broadcaster_id: broadcaster_id, moderator_id: moderator_id), body: attrs)
    end
  end
end
