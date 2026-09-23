require "test_helper"

class TeamsResourceTest < WebmockTest
  def setup
    @client = Twitch::Client.new(client_id: "test_client_id", access_token: "test_token")
  end

  def test_teams_retrieve_by_name
    stub_helix(:get, "teams", query: { "name" => "staff" },
      body: { data: [ { id: "team-1", team_name: "staff", users: [ { user_id: "1" } ] } ] }.to_json)

    team = @client.teams.retrieve(name: "staff")

    assert_instance_of Twitch::Team, team
    assert_equal "1", team.users.first.user_id
  end

  def test_teams_retrieve_by_id
    stub_helix(:get, "teams", query: { "id" => "team-1" }, body: { data: [ { id: "team-1" } ] }.to_json)

    assert_equal "team-1", @client.teams.retrieve(id: "team-1").id
  end

  def test_teams_retrieve_returns_nil_when_not_found
    stub_helix(:get, "teams", query: { "name" => "nope" }, body: { data: [] }.to_json)

    assert_nil @client.teams.retrieve(name: "nope")
  end

  def test_teams_retrieve_raises_without_args
    assert_raises(RuntimeError) { @client.teams.retrieve }
  end

  def test_teams_channel
    stub_helix(:get, "teams/channel", query: { "broadcaster_id" => "123" },
      body: { data: [ { id: "team-1", team_name: "staff", broadcaster_id: "123" } ] }.to_json)

    teams = @client.teams.channel(broadcaster_id: "123")

    assert_instance_of Twitch::Team, teams.first
    assert_equal "staff", teams.first.team_name
  end
end
