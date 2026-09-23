module Twitch
  class SearchResource < Resource
    def categories(query:, **params)
      response = get_request("search/categories", params: params.merge(query: query))

      collection(response, type: SearchResult)
    end

    def channels(query:, **params)
      response = get_request("search/channels", params: params.merge(query: query))

      collection(response, type: SearchResult)
    end
  end
end
