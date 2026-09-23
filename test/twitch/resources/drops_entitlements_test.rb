require "test_helper"

class DropsEntitlementsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_drops_entitlements_list
    stub_helix(:get, "entitlements/drops", query: { "user_id" => "9876", "fulfillment_status" => "CLAIMED" },
      body: { data: [ { id: "ent-1", benefit_id: "ben-1", fulfillment_status: "CLAIMED" } ], pagination: {} }.to_json)

    entitlements = @client.drops_entitlements.list(user_id: "9876", fulfillment_status: "CLAIMED")

    assert_instance_of Twitch::DropsEntitlement, entitlements.first
    assert_equal "ben-1", entitlements.first.benefit_id
  end

  def test_drops_entitlements_update
    stub_helix(:patch, "entitlements/drops",
      request_body: { entitlement_ids: [ "ent-1", "ent-2" ], fulfillment_status: "FULFILLED" },
      body: { data: [ { status: "SUCCESS", ids: [ "ent-1" ] }, { status: "NOT_FOUND", ids: [ "ent-2" ] } ] }.to_json)

    results = @client.drops_entitlements.update(entitlement_ids: [ "ent-1", "ent-2" ], fulfillment_status: "FULFILLED")

    assert_instance_of Twitch::DropsEntitlementUpdate, results.first
    assert_equal [ "SUCCESS", "NOT_FOUND" ], results.map(&:status)
  end
end
