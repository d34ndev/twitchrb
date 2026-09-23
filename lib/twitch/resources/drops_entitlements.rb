module Twitch
  class DropsEntitlementsResource < Resource
    # The Client ID must be owned by a member of the organization that owns the game
    # Available parameters: id, user_id, game_id, fulfillment_status, first, after
    def list(**params)
      response = get_request("entitlements/drops", params: params)
      collection(response, type: DropsEntitlement)
    end

    # fulfillment_status: CLAIMED or FULFILLED
    # Returns a collection of results grouped by status, each with the affected ids
    def update(entitlement_ids:, fulfillment_status:)
      response = patch_request("entitlements/drops", body: { entitlement_ids: Array(entitlement_ids), fulfillment_status: fulfillment_status })
      collection(response, type: DropsEntitlementUpdate)
    end
  end
end
