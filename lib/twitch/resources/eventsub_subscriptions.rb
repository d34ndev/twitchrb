module Twitch
  class EventsubSubscriptionsResource < Resource
    def list(**params)
      response = get_request("eventsub/subscriptions", params: params)
      Collection.from_response(response, type: EventsubSubscription)
    end

    def create(type:, version:, condition:, transport:, **params)
      attributes = { type: type, version: version, condition: condition, transport: transport }.merge(params)
      response = post_request("eventsub/subscriptions", body: attributes)

      EventsubSubscription.new(response.body.dig("data")[0]) if response.success?
    rescue Twitch::Errors::ConflictError => error
      existing_id = error.response_body.dig("data", 0, "id") if error.response_body.is_a?(Hash)
      raise Twitch::Errors::EventsubSubscriptionConflictError.new(
        error.response_body,
        error.http_status_code,
        existing_subscription_id: existing_id
      )
    end

    def delete(id:)
      delete_request("eventsub/subscriptions", params: { id: id })
    end
  end
end
