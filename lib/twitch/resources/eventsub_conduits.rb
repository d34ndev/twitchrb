module Twitch
  class EventsubConduitsResource < Resource
    MAX_SHARDS_PER_UPDATE = 100

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

    # Twitch accepts up to 100 shards per request, so larger lists are sent in batches.
    # Returns the updated shards. Shards that failed to update are listed in #errors
    # (each with id, message and code), as Twitch applies the rest of the update anyway.
    def update_shards(id:, shards:)
      results = shards.each_slice(MAX_SHARDS_PER_UPDATE).map do |batch|
        response = patch_request("eventsub/conduits/shards", body: { conduit_id: id, shards: batch })
        collection(response, type: EventsubConduitShard)
      end

      data = results.flat_map(&:data)
      Collection.new(data: data, total: data.size, cursor: nil, errors: results.flat_map(&:errors))
    end
  end
end
