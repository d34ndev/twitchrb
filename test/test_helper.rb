$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "twitch"

require "minitest/autorun"
require "faraday"
require "json"
require "webmock/minitest"

WebMock.disable_net_connect!

HELIX_URL = "https://api.twitch.tv/helix".freeze
FIXTURES_DIR = File.expand_path("fixtures", __dir__).freeze

def helix_fixture(name)
  File.read(File.join(FIXTURES_DIR, "helix", "#{name}.json"))
end

# request_body matches the JSON request body exactly, so stray params in the body fail the stub
def stub_helix(method, path, query: nil, request_body: nil, fixture: nil, status: 200, body: nil)
  body ||= fixture ? helix_fixture(fixture) : "{}"
  stub = stub_request(method, "#{HELIX_URL}/#{path}")
  stub = stub.with(query: query) if query
  # WebMock treats an empty hash as "match anything", so compare empty bodies as a string
  stub = stub.with(body: request_body.empty? ? "{}" : request_body) if request_body
  stub.to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
end

# Base class for HTTP-stubbed tests. Equivalent to Minitest::Test now that VCR is gone;
# kept as a distinct name so the WebMock pattern is obvious at test sites.
class WebmockTest < Minitest::Test
end
