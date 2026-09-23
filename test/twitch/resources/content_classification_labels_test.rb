require "test_helper"

class ContentClassificationLabelsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_content_classification_labels_list
    stub_helix(:get, "content_classification_labels", query: { "locale" => "en-US" },
      body: { data: [ { id: "Gambling", name: "Gambling", description: "Participating in online or in-person gambling" } ] }.to_json)

    labels = @client.content_classification_labels.list(locale: "en-US")

    assert_instance_of Twitch::ContentClassificationLabel, labels.first
    assert_equal "Gambling", labels.first.id
  end
end
