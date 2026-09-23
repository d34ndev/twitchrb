module Twitch
  class Collection
    include Enumerable

    attr_reader :data, :total, :cursor

    def self.from_response(response, type:)
      body = response.body
      data = body["data"] || []

      new(
        data: data.map { |attrs| type.new(attrs) },
        total: body["total"] || data.count,
        cursor: cursor_from(body["pagination"])
      )
    end

    # Most endpoints return pagination as { "cursor": "..." }, but a few
    # (e.g. Get Extension Live Channels) return the cursor as a bare string
    def self.cursor_from(pagination)
      pagination.is_a?(Hash) ? pagination["cursor"] : pagination
    end

    def initialize(data:, total:, cursor:)
      @data = data
      @total = total
      @cursor = cursor
    end

    def each(&block)
      data.each(&block)
    end

    def first
      data.first
    end

    def last
      data.last
    end
  end
end
