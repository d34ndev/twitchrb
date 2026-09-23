module Twitch
  class PredictionsResource < Resource
    # Broadcaster ID must match the user in the OAuth token
    def list(broadcaster_id:, **params)
      response = get_request("predictions", params: params.merge(broadcaster_id: broadcaster_id))

      if response.body["data"]
        collection(response, type: Prediction)
      else
        nil
      end
    end

    # Broadcaster ID must match the user in the OAuth token
    def create(broadcaster_id:, title:, outcomes:, duration:, **params)
      attrs = { broadcaster_id: broadcaster_id, title: title, outcomes: outcomes, prediction_window: duration }
      response = post_request("predictions", body: attrs.merge(params))

      Prediction.new(response.body.dig("data")[0]) if response.success?
    end

    # Broadcaster ID must match the user in the OAuth token
    def end(broadcaster_id:, id:, status:, **params)
      attrs = { broadcaster_id: broadcaster_id, id: id, status: status.upcase }
      response = patch_request("predictions", body: attrs.merge(params))

      Prediction.new(response.body.dig("data")[0]) if response.success?
    end
  end
end
