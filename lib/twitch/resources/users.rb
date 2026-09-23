module Twitch
  class UsersResource < Resource
    def retrieve(id: nil, ids: nil, username: nil, usernames: nil)
      raise "Either id, ids, username or usernames is required" unless !id.nil? || !ids.nil? || !username.nil? || !usernames.nil?

      if id
        response = get_request("users", params: { id: id })
      elsif ids
        response = get_request("users", params: { id: ids })
      elsif usernames
        response = get_request("users", params: { login: usernames })
      else
        response = get_request("users", params: { login: username })
      end

      body = response.body.dig("data")
      if id || username
        body.empty? ? nil : User.new(body[0])
      else
        Collection.from_response(response, type: User)
      end
    end

    # Updates the current users description
    # Required scope: user:edit
    def update(description:)
      response = put_request(query_path("users", description: description), body: {})
      User.new response.body.dig("data")[0]
    end

    def get_color(user_id: nil, user_ids: nil)
      if user_ids
        ids = user_ids.is_a?(Array) ? user_ids : user_ids.split(",")
        response = get_request("chat/color", params: { user_id: ids.map { |i| i.to_s.strip } })
        Collection.from_response(response, type: UserColor)
      else
        response = get_request("chat/color", params: { user_id: user_id })
        UserColor.new response.body.dig("data")[0]
      end
    end

    # Update a user's color
    # Required scope: user:manage:chat_color
    # user_id must be the currently authenticated user
    def update_color(user_id:, color:)
      put_request(query_path("chat/color", user_id: user_id, color: color), body: {})
    end

    # Required scope: user:read:blocked_users
    def blocks(broadcaster_id:, **params)
      response = get_request("users/blocks", params: params.merge(broadcaster_id: broadcaster_id))
      Collection.from_response(response, type: BlockedUser)
    end

    # Required scope: user:manage:blocked_users
    def block_user(target_user_id:, **attributes)
      put_request(query_path("users/blocks", attributes.merge(target_user_id: target_user_id)), body: {})
    end

    # Required scope: user:manage:blocked_users
    def unblock_user(target_user_id:)
      delete_request("users/blocks", params: { target_user_id: target_user_id })
    end

    def emotes(user_id:, **params)
      attrs = { user_id: user_id }
      response = get_request("chat/emotes/user", params: attrs.merge(params))
      Collection.from_response(response, type: Emote)
    end

    def authorization(id: nil, ids: nil)
      raise "Either id or ids is required" unless !id.nil? || !ids.nil?

      if id
        response = get_request("authorization/users", params: { user_id: id })
      elsif ids
        response = get_request("authorization/users", params: { user_id: ids })
      end

      Collection.from_response(response, type: UserAuthorization)
    end
  end
end
