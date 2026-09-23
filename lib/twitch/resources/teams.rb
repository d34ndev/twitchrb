module Twitch
  class TeamsResource < Resource
    def retrieve(id: nil, name: nil)
      raise "Either id or name is required" if id.nil? && name.nil?

      response = get_request("teams", params: { id: id, name: name }.compact)
      data = response.body.dig("data")

      return nil if data.nil? || data.empty?

      Team.new(data[0])
    end

    # Gets the teams that a broadcaster is a member of
    def channel(broadcaster_id:)
      response = get_request("teams/channel", params: { broadcaster_id: broadcaster_id })
      collection(response, type: Team)
    end
  end
end
