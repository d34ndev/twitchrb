module Twitch
  class AnalyticsResource < Resource
    # Gets URLs for downloadable CSV reports about the user's extensions
    # Required scope: analytics:read:extensions
    # Available parameters: extension_id, type, started_at, ended_at, first, after
    def extensions(**params)
      response = get_request("analytics/extensions", params: params)
      Collection.from_response(response, type: AnalyticsReport)
    end

    # Gets URLs for downloadable CSV reports about the user's games
    # Required scope: analytics:read:games
    # Available parameters: game_id, type, started_at, ended_at, first, after
    def games(**params)
      response = get_request("analytics/games", params: params)
      Collection.from_response(response, type: AnalyticsReport)
    end
  end
end
