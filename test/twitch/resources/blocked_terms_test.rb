require "test_helper"

class BlockedTermsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_blocked_terms_create_returns_blocked_term
    stub_request(:post, "#{HELIX_URL}/moderation/blocked_terms")
      .with(query: { "broadcaster_id" => "123", "moderator_id" => "321" }, body: { "text" => "crac" })
      .to_return(
        status: 200,
        body: {
          data: [
            {
              broadcaster_id: "123",
              moderator_id: "321",
              id: "520e4d4e-0cda-49c7-821e-e5ef4f88c2f2",
              text: "crac",
              created_at: "2021-09-29T19:45:37Z",
              updated_at: "2021-09-29T19:45:37Z",
              expires_at: nil
            }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    term = @client.blocked_terms.create(broadcaster_id: "123", moderator_id: "321", text: "crac")

    assert_instance_of Twitch::BlockedTerm, term
    assert_equal "crac", term.text
  end
end
