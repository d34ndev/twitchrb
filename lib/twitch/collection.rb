module Twitch
  class Collection
    include Enumerable

    attr_reader :data, :total, :cursor, :errors

    def self.from_response(response, type:, next_page: nil)
      body = response.body
      data = body["data"] || []

      new(
        data: data.map { |attrs| type.new(attrs) },
        total: body["total"] || data.count,
        cursor: cursor_from(body["pagination"]),
        next_page: next_page,
        errors: (body["errors"] || []).map { |attrs| Object.new(attrs) }
      )
    end

    # Most endpoints return pagination as { "cursor": "..." }, but a few
    # (e.g. Get Extension Live Channels) return the cursor as a bare string
    def self.cursor_from(pagination)
      pagination.is_a?(Hash) ? pagination["cursor"] : pagination
    end

    # next_page is a callable that takes a cursor and returns the following Collection.
    # errors lists items that failed, for endpoints that report partial failures (e.g. Update Conduit Shards).
    def initialize(data:, total:, cursor:, next_page: nil, errors: [])
      @data = data
      @total = total
      @cursor = cursor
      @next_page = next_page
      @errors = errors
    end

    def each(&block)
      data.each(&block)
    end

    def first(...)
      data.first(...)
    end

    def last(...)
      data.last(...)
    end

    # Twitch can return a cursor alongside an empty last page, so an empty page has no next page
    def next_page?
      !@next_page.nil? && !cursor.nil? && !cursor.empty? && data.any?
    end

    # Fetches the following page, or returns nil on the last page
    def next_page
      @next_page.call(cursor) if next_page?
    end

    # Yields this page and each following page, fetching them as needed.
    # Returns an Enumerator without a block.
    def each_page
      return enum_for(:each_page) unless block_given?

      page = self
      seen_cursors = []

      while page
        yield page
        break if page.cursor.nil? || seen_cursors.include?(page.cursor)

        seen_cursors << page.cursor
        page = page.next_page
      end
    end

    # Lazily iterates over every item across all pages, fetching pages only as needed.
    #   client.clips.list(broadcaster_id: 123).auto_paginate.first(250)
    #   client.channels.followers(broadcaster_id: 123, first: 100).auto_paginate.to_a
    def auto_paginate
      each_page.lazy.flat_map(&:data)
    end
  end
end
