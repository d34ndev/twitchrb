require "test_helper"

class UsersResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_users_retrieve_by_id
    stub_helix(:get, "users", query: { "id" => "141981764" }, fixture: "get_users")

    user = @client.users.retrieve(id: 141981764)

    assert_equal Twitch::User, user.class
    assert_equal "twitchdev", user.login
  end

  def test_users_retrieve_by_username
    stub_helix(:get, "users", query: { "login" => "twitchdev" }, fixture: "get_users")

    user = @client.users.retrieve(username: "twitchdev")

    assert_equal Twitch::User, user.class
    assert_equal "partner", user.broadcaster_type
  end

  def test_users_retrieve_by_ids
    stub_request(:get, "#{HELIX_URL}/users?id%5B%5D=141981764&id%5B%5D=72938118")
      .to_return(status: 200, body: helix_fixture("get_users_many"),
        headers: { "Content-Type" => "application/json" })

    users = @client.users.retrieve(ids: [ "141981764", "72938118" ])

    assert_equal Twitch::Collection, users.class
    assert_equal 2, users.data.count
  end

  def test_users_retrieve_by_usernames
    stub_request(:get, "#{HELIX_URL}/users?login%5B%5D=twitchdev&login%5B%5D=deanpcmad")
      .to_return(status: 200, body: helix_fixture("get_users_many"),
        headers: { "Content-Type" => "application/json" })

    users = @client.users.retrieve(usernames: [ "twitchdev", "deanpcmad" ])

    assert_equal Twitch::Collection, users.class
    assert_equal 2, users.data.count
  end

  def test_users_retrieve_by_usernames_with_single_match
    stub_request(:get, "#{HELIX_URL}/users?login%5B%5D=twitchdev")
      .to_return(status: 200, body: helix_fixture("get_users"),
        headers: { "Content-Type" => "application/json" })

    users = @client.users.retrieve(usernames: [ "twitchdev" ])

    assert_equal Twitch::Collection, users.class
    assert_equal 1, users.data.count
  end

  def test_users_retrieve_by_id_with_no_match
    stub_helix(:get, "users", query: { "id" => "0" }, body: { data: [] }.to_json)

    assert_nil @client.users.retrieve(id: 0)
  end

  def test_users_retrieve_raises_without_args
    assert_raises(RuntimeError) { @client.users.retrieve }
  end
end
