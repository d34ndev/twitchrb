module Twitch
  # Guest Star is in beta, so Twitch may change these endpoints
  class GuestStarResource < Resource
    # Required scope: channel:read:guest_star, channel:manage:guest_star, moderator:read:guest_star or moderator:manage:guest_star
    # moderator_id must match the user in the OAuth token
    def settings(broadcaster_id:, moderator_id:)
      response = get_request("guest_star/channel_settings", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id })
      GuestStarSettings.new(response.body.dig("data")[0])
    end

    # Required scope: channel:manage:guest_star
    # broadcaster_id must match the user in the OAuth token
    # Available attributes: is_moderator_send_live_enabled, slot_count, is_browser_source_audio_enabled,
    # group_layout, regenerate_browser_sources
    def update_settings(broadcaster_id:, **attributes)
      put_request(query_path("guest_star/channel_settings", broadcaster_id: broadcaster_id), body: attributes)
    end

    # Required scope: channel:read:guest_star, channel:manage:guest_star, moderator:read:guest_star or moderator:manage:guest_star
    def session(broadcaster_id:, moderator_id:)
      response = get_request("guest_star/session", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id })
      data = response.body.dig("data")

      return nil if data.nil? || data.empty?

      GuestStarSession.new(data[0])
    end

    # Required scope: channel:manage:guest_star
    # broadcaster_id must match the user in the OAuth token
    def create_session(broadcaster_id:)
      response = post_request(query_path("guest_star/session", broadcaster_id: broadcaster_id), body: {})
      GuestStarSession.new(response.body.dig("data")[0])
    end

    # Required scope: channel:manage:guest_star
    # broadcaster_id must match the user in the OAuth token
    def end_session(broadcaster_id:, session_id:)
      response = delete_request("guest_star/session", params: { broadcaster_id: broadcaster_id, session_id: session_id })
      GuestStarSession.new(response.body.dig("data")[0])
    end

    # Required scope: channel:read:guest_star, channel:manage:guest_star, moderator:read:guest_star or moderator:manage:guest_star
    def invites(broadcaster_id:, moderator_id:, session_id:)
      response = get_request("guest_star/invites", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id, session_id: session_id })
      Collection.from_response(response, type: GuestStarInvite)
    end

    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    # moderator_id must match the user in the OAuth token
    def send_invite(broadcaster_id:, moderator_id:, session_id:, guest_id:)
      params = { broadcaster_id: broadcaster_id, moderator_id: moderator_id, session_id: session_id, guest_id: guest_id }
      post_request(query_path("guest_star/invites", params), body: {})
    end

    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    # moderator_id must match the user in the OAuth token
    def delete_invite(broadcaster_id:, moderator_id:, session_id:, guest_id:)
      delete_request("guest_star/invites", params: { broadcaster_id: broadcaster_id, moderator_id: moderator_id, session_id: session_id, guest_id: guest_id })
    end

    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    # moderator_id must match the user in the OAuth token
    def assign_slot(broadcaster_id:, moderator_id:, session_id:, guest_id:, slot_id:)
      params = { broadcaster_id: broadcaster_id, moderator_id: moderator_id, session_id: session_id, guest_id: guest_id, slot_id: slot_id }
      post_request(query_path("guest_star/slot", params), body: {})
    end

    # Moves a guest to another slot, or swaps two guests when destination_slot_id is occupied
    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    def update_slot(broadcaster_id:, moderator_id:, session_id:, source_slot_id:, destination_slot_id: nil)
      params = {
        broadcaster_id: broadcaster_id,
        moderator_id: moderator_id,
        session_id: session_id,
        source_slot_id: source_slot_id,
        destination_slot_id: destination_slot_id
      }
      patch_request(query_path("guest_star/slot", params), body: {})
    end

    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    def delete_slot(broadcaster_id:, moderator_id:, session_id:, guest_id:, slot_id:, should_reinvite_guest: nil)
      params = {
        broadcaster_id: broadcaster_id,
        moderator_id: moderator_id,
        session_id: session_id,
        guest_id: guest_id,
        slot_id: slot_id,
        should_reinvite_guest: should_reinvite_guest
      }.compact
      delete_request("guest_star/slot", params: params)
    end

    # Required scope: channel:manage:guest_star or moderator:manage:guest_star
    # Available attributes: is_audio_enabled, is_video_enabled, is_live, volume
    def update_slot_settings(broadcaster_id:, moderator_id:, session_id:, slot_id:, **attributes)
      params = attributes.merge(broadcaster_id: broadcaster_id, moderator_id: moderator_id, session_id: session_id, slot_id: slot_id)
      patch_request(query_path("guest_star/slot_settings", params), body: {})
    end
  end
end
