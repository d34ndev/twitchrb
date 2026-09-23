module Twitch
  class GamesResource < Resource
    def retrieve(id: nil, ids: nil, name: nil, names: nil)
      raise "Either id, ids, name or names is required" unless !id.nil? || !ids.nil? || !name.nil? || !names.nil?

      if id
        response = get_request("games", params: { id: id })
      elsif ids
        response = get_request("games", params: { id: ids })
      elsif names
        response = get_request("games", params: { name: names })
      else
        response = get_request("games", params: { name: name })
      end

      body = response.body.dig("data")
      if id || name
        body.empty? ? nil : Game.new(body[0])
      else
        collection(response, type: Game)
      end
    end

    def top(**params)
      response = get_request("games/top", params: params)
      collection(response, type: Game)
    end
  end
end
