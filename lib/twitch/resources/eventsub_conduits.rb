module Twitch
  class EventsubConduitsResource < Resource
    def list(**params)
      response = get_request("eventsub/conduits", params: params)
      collection(response, type: EventsubConduit)
    end

    def create(shard_count:)
      response = post_request("eventsub/conduits", body: { shard_count: shard_count })

      EventsubConduit.new(response.body.dig("data")[0]) if response.success?
    end

    def update(id:, shard_count:)
      response = patch_request("eventsub/conduits", body: { id: id, shard_count: shard_count })

      EventsubConduit.new(response.body.dig("data")[0]) if response.success?
    end

    def delete(id:)
      delete_request("eventsub/conduits", params: { id: id })
    end

    def shards(id:, **params)
      response = get_request("eventsub/conduits/shards", params: { conduit_id: id }.merge(params))
      collection(response, type: EventsubConduitShard)
    end

    def update_shards(id:, shards:)
      response = patch_request("eventsub/conduits/shards", body: { conduit_id: id, shards: shards })
      collection(response, type: EventsubConduitShard)
    end
  end
end
