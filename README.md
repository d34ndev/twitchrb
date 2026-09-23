# TwitchRB

[![CI](https://github.com/deanpcmad/twitchrb/actions/workflows/ci.yml/badge.svg)](https://github.com/deanpcmad/twitchrb/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/twitchrb.svg)](https://badge.fury.io/rb/twitchrb)
[![Downloads](https://img.shields.io/gem/dt/twitchrb.svg)](https://rubygems.org/gems/twitchrb)

TwitchRB is the easiest and most complete Ruby library for the [Twitch Helix API](https://dev.twitch.tv/docs/api).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "twitchrb"
```

## Usage

### Set Client Details

Firstly you'll need to set a Client ID and an Access Token.

An access token is required because the Helix API requires authentication.

```ruby
@client = Twitch::Client.new(client_id: "abc123", access_token: "xyz123")
```

Requests time out after 30 seconds (10 seconds to open the connection) by default, raising
`Faraday::TimeoutError` or `Faraday::ConnectionFailed`. Both can be changed on `Twitch::Client` and `Twitch::OAuth`:

```ruby
@client = Twitch::Client.new(client_id: "abc123", access_token: "xyz123", timeout: 10, open_timeout: 5)
```

#### Refreshing User Access Tokens

User access tokens expire after a few hours. Pass the `refresh_token` and your `client_secret` and the client
will refresh an expired token automatically, then retry the request. Twitch may issue a new refresh token each
time, so use `on_token_refresh` to store the new tokens:

```ruby
@client = Twitch::Client.new(
  client_id: "abc123",
  client_secret: "your-client-secret", # omit for public clients
  access_token: user.twitch_access_token,
  refresh_token: user.twitch_refresh_token,
  on_token_refresh: ->(token) {
    user.update!(twitch_access_token: token.access_token, twitch_refresh_token: token.refresh_token)
  }
)

# Or refresh manually
@client.refresh_access_token!
```

The client refreshes once per expired token, even across threads. If the refresh token itself is invalid (e.g.
the user disconnected your app), the error from Twitch is raised, e.g. `Twitch::Errors::BadRequestError`.

#### User vs. App Access Tokens

Most endpoints accept a **user access token** — issued for a specific Twitch user via the
[authorization code](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#authorization-code-grant-flow)
or [device code](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#device-code-grant-flow) flows,
and required for anything that acts on behalf of a user (sending chat, managing channels, etc.).

Some endpoints require an **app access token** instead — issued to your application, not a user. These
are the EventSub APIs (subscriptions over webhooks, conduits, and shards), plus a few others noted in
each section below. App tokens are obtained with the `client_credentials` grant and need only your
Client ID and Client Secret:

```ruby
oauth = Twitch::OAuth.new(client_id: "abc123", client_secret: "your-client-secret")
token = oauth.create(grant_type: "client_credentials")

@app_client = Twitch::Client.new(client_id: "abc123", access_token: token.access_token)
```

App tokens expire (typically after ~60 days). Use `oauth.validate(token: ...)` to check the remaining
lifetime, and `oauth.create(grant_type: "client_credentials")` to mint a fresh one when needed.

### Resources

The gem maps as closely as we can to the Twitch API so you can easily convert API examples to gem code.

Responses are created as objects like `Twitch::Channel`. Having types like `Twitch::User` is handy for understanding what
type of object you're working with. They're built using OpenStruct so you can easily access data in a Ruby-ish way.

### Pagination

Some of the endpoints return pages of results. The result object will have a `data` key to access the results, as well as metadata like `cursor`
for retrieving the next and previous pages. This can be used by using `before` and `after` parameters, on API endpoints that support it.

An example of using collections, including pagination:

```ruby
results = @client.clips.list(broadcaster_id: 123)
#=> Twitch::Collection

results.total
#=> 30

results.data
#=> [#<Twitch::Clip>, #<Twitch::Clip>]

results.each do |result|
  puts result.id
end

results.first
#=> #<Twitch::Clip>

results.last
#=> #<Twitch::Clip>

results.cursor
#=> "abc123"

# Retrieve the next page manually
@client.clips.list(broadcaster_id: 123, after: results.cursor)
#=> Twitch::Collection
```

#### Automatic Pagination

Collections from paginated endpoints can fetch their following pages for you. Each extra page is a separate
API request (and counts towards your rate limit), so use `first:` to request up to 100 items per page.

```ruby
followers = @client.channels.followers(broadcaster_id: 123, first: 100)

# Fetch the next page, or nil on the last page
followers.next_page? #=> true
followers.next_page  #=> Twitch::Collection

# Iterate over every item across all pages. Pages are fetched lazily, only as needed.
followers.auto_paginate.each { |follower| puts follower.user_name }

# Stop after 250 items, without fetching any more pages than needed
followers.auto_paginate.first(250)

# Get every item as an array
followers.auto_paginate.to_a

# Iterate page by page
followers.each_page do |page|
  puts "#{page.data.size} followers on this page"
end
```

### Rate Limiting

The Twitch API has rate limits to ensure fair usage. TwitchRB automatically tracks rate limit information from API responses and can warn you when approaching limits.

#### Automatic Rate Limit Tracking

By default, the client tracks rate limit headers from all API responses:

```ruby
@client = Twitch::Client.new(client_id: "abc123", access_token: "xyz123")

# Make an API call
user = @client.users.retrieve(id: 12345)

# Check current rate limit status
@client.rate_limiter.remaining   #=> 119
@client.rate_limiter.limit       #=> 120
@client.rate_limiter.reset_at    #=> 1701619234 (Unix timestamp)
@client.rate_limiter.status      #=> "119/120 requests remaining"
```

#### Configuring Rate Limit Warnings

You can configure the client to warn when approaching the rate limit:

```ruby
# With logging enabled (e.g., Rails logger)
@client = Twitch::Client.new(
  client_id: "abc123",
  access_token: "xyz123",
  logger: Rails.logger,
  rate_limit_threshold: 10  # Warn when remaining <= 10
)

# When approaching the limit, a warning will be logged:
# "Twitch API rate limit approaching: 5/120 requests remaining. Resets in 45 seconds."
```

#### Handling Rate Limit Errors

When you hit the rate limit (429 response), the library raises a `Twitch::Errors::RateLimitError` with detailed information:

```ruby
begin
  @client.users.retrieve(id: 12345)
rescue Twitch::Errors::RateLimitError => e
  puts e.message
  #=> "Error 429: Your request exceeded the API rate limit. (Resets at 14:23:45, 0/120 requests)"

  puts e.reset_at     #=> 1701619234 (Unix timestamp)
  puts e.remaining    #=> 0
  puts e.limit        #=> 120
end
```

#### Rate Limiter Methods

The `rate_limiter` object has several useful methods:

```ruby
# Check if approaching limit
@client.rate_limiter.approaching_limit?(threshold: 10)  #=> true/false

# Get seconds until reset
@client.rate_limiter.reset_in  #=> 45

# Check if rate limited
@client.rate_limiter.rate_limited?  #=> false

# Wait until rate limit resets (useful for batch operations)
@client.rate_limiter.wait_if_rate_limited

# Reset tracking (useful when creating new client instances)
@client.rate_limiter.reset
```

### OAuth

This library includes the ability to create, refresh, validate and revoke OAuth tokens.

Failed token requests raise the same errors as API requests (e.g. `Twitch::Errors::BadRequestError`),
with Twitch's message available as `error.twitch_error_message`.

```ruby
# Firstly, set the client details
# client_secret can be omitted for public clients using the device code flow
@oauth = Twitch::OAuth.new(client_id: "", client_secret: "")

# Create an app access token (client credentials grant flow)
@oauth.create(grant_type: "client_credentials")

# Exchange the code from the authorization code grant flow for a user access token
# https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#authorization-code-grant-flow
token = @oauth.exchange_code(code: params[:code], redirect_uri: "http://localhost:3000/callback")
token.access_token
token.refresh_token

# Refresh a Token
@oauth.refresh(refresh_token: "")

# Validate an Access Token
# Returns false if the token is invalid
@oauth.validate(token: "")

# Revoke a Token
# Returns false if the token couldn't be revoked
@oauth.revoke(token: "")
```

#### Device Code Grant Flow

For apps with limited input, such as CLIs, set-top boxes or games.
See [the Twitch docs](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#device-code-grant-flow).

```ruby
# scopes can be an array or a space-delimited string
scopes = ["user:read:email", "chat:read"]
device = @oauth.device(scopes: scopes)

puts "Go to #{device.verification_uri} and enter #{device.user_code}"

# Poll until the user has authorized the app
token = begin
  sleep device.interval
  @oauth.device_token(device_code: device.device_code, scopes: scopes)
rescue Twitch::Errors::BadRequestError => e
  retry if e.twitch_error_message == "authorization_pending"
  raise
end
```

### Users

```ruby
# Retrieves a user by their ID
@client.users.retrieve(id: 141981764)

# Retrieves multiple users by their IDs
# Requires an array of IDs
@client.users.retrieve(ids: [141981764, 72938118])

# Retrieves a user by their username
@client.users.retrieve(username: "twitchdev")

# Retrieves multiple users by their usernames
# Requires an array of IDs
@client.users.retrieve(usernames: ["twitchdev", "deanpcmad"])

# Update the currently authenticated user's description
# Required scope: user:edit
@client.users.update(description: "New Description")

# Returns Blocked users for a broadcaster
# Required scope: user:read:blocked_users
@client.users.blocks(broadcaster_id: 141981764)

# Blocks a user
# Required scope: user:manage:blocked_users
@client.users.block_user(target_user_id: 141981764)

# Unblocks a user
# Required scope: user:manage:blocked_users
@client.users.unblock_user(target_user_id: 141981764)

# Get a User's Chat Color
@client.users.get_color(user_id: 123)

# Or get multiple users' chat colors
# Returns a collection
@client.users.get_color(user_ids: "123,321")

# Update a User's Chat Color
# Requires user:manage:chat_color
# user_id must be the currently authenticated user
# Current allowed colours: blue, blue_violet, cadet_blue, chocolate, coral, dodger_blue, firebrick, golden_rod, green, hot_pink, orange_red, red, sea_green, spring_green, yellow_green
# For Turbo and Prime users, a hex colour code is allowed.
@client.users.update_color(user_id: 123, color: "blue")

# Get Emotes a User has
# Required scope: user:read:emotes
@client.users.emotes(user_id: 123)
@client.users.emotes(user_id: 123, broadcaster_id: 321)
@client.users.emotes(user_id: 123, after: "abc123")

# Gets the authorization scopes that the specified user(s) have granted the application. Takes a single User ID or multiple as an array.
# Requires an App Access Token
# Returns a collection of Twitch::UserAuthorization's
# #<Twitch::UserAuthorization user_id="72938118", user_name="deanpcmad", user_login="deanpcmad", scopes=["user:read:email"], has_authorized=true>
@client.users.authorization(id: 123)
@client.users.authorization(ids: [123, 321])

# Gets all extensions the authenticated user has installed, active or not
# Required scope: user:read:broadcast or user:edit:broadcast (needed to include inactive extensions)
@client.users.extensions

# Gets the active extensions for a user, or the authenticated user if user_id is omitted
@client.users.active_extensions(user_id: 123)

# Updates the authenticated user's active extensions
# Required scope: user:edit:broadcast
@client.users.update_extensions(data: {
  panel: { "1" => { active: true, id: "abc123", version: "1.0.0" } }
})
```

### Channels

```ruby
# Retrieve a channel by their ID
@client.channels.retrieve(id: 141981764)

# Retrieve a list of broadcasters a specified user follows
# user_id must match the currently authenticated user
# Required scope: user:read:follows
@client.channels.followed user_id: 123123

# Retrieve a list of users that follow a specified broadcaster
# broadcaster_id must match the currently authenticated user or
# a moderator of the specified broadcaster
# Required scope: moderator:read:followers
@client.channels.followers broadcaster_id: 123123

# Retrieve the number of Followers a broadcaster has
@client.channels.follows_count(broadcaster_id: 141981764)

# Retrieve the number of Subscribers and Subscriber Points a broadcaster has
# Required scope: channel:read:subscriptions
@client.channels.subscribers_count(broadcaster_id: 141981764)

# Update the currently authenticated channel details
# Required scope: channel:manage:broadcast
# Parameters which are allowed: game_id, title, broadcaster_language, delay
attributes = {title: "My new title"}
@client.channels.update(broadcaster_id: 141981764, attributes)

# Retrieves editors for a channel
@client.channels.editors(broadcaster_id: 141981764)

# Retrieve the Stream Key for a channel
# broadcaster_id must match the currently authenticated user
# Required scope: channel:read:stream_key
@client.channels.stream_key(broadcaster_id: 123123)
=> #<Twitch::StreamKey stream_key="live_abc123">

# Run a commercial
# broadcaster_id must match the currently authenticated user
# Required scope: channel:edit:commercial
@client.channels.commercial(broadcaster_id: 123123, length: 30)
```

### Videos

```ruby
# Retrieves a list of videos
# Available parameters: user_id or game_id
@client.videos.list(user_id: 12345)
@client.videos.list(game_id: 12345)

# Retrieves a video by its ID
@client.videos.retrieve(id: 12345)
```

### Clips

```ruby
# Retrieves a list of clips
# Available parameters: broadcaster_id or game_id
@client.clips.list(broadcaster_id: 12345)
@client.clips.list(game_id: 12345)

# Retrieves a clip by its ID.
# Clip IDs are alphanumeric. e.g. AwkwardHelplessSalamanderSwiftRage
@client.clips.retrieve(id: "AwkwardHelplessSalamanderSwiftRage")

# Create a clip of a given Channel
# Required scope: clips:edit
# title is optional
# duration is optional and can be from 5 to 60 seconds; defaults to 30 if not set
@client.clips.create(broadcaster_id: 1234, title: "Best moment", duration: 12.5)

# Create a clip from a VOD
# Required scope: editor:manage:clips or channel:manage:clips
# title is optional
# duration is optional and can be from 5 to 60 seconds; defaults to 30 if not set
@client.clips.create_from_vod(
  editor_id: 1234,
  broadcaster_id: 1234,
  vod_id: 5678,
  vod_offset: 45,
  duration: 15.0,
  title: "VOD highlight"
)

# Get download URLs for one or more clips
# Required scope: editor:manage:clips or channel:manage:clips
@client.clips.downloads(editor_id: 1234, broadcaster_id: 1234, clip_ids: ["clip-1", "clip-2"])
```

### Emotes

```ruby
# Retrieve all global emotes
@client.emotes.global

# Retrieve emotes for a channel
@client.emotes.channel(broadcaster_id: 141981764)

# Retrieve emotes for an emote set
@client.emotes.sets(emote_set_id: 301590448)
```

### Badges

```ruby
# Retrieve all global badges
@client.badges.global

# Retrieve badges for a channel
@client.badges.channel(broadcaster_id: 141981764)
```

### Games

```ruby
# Retrieves a game by ID
@client.games.retrieve(id: 514974)

# Retrieves multiple games by IDs
# Requires an array of IDs
@client.games.retrieve(ids: [66402, 514974])

# Retrieves a game by name
@client.games.retrieve(name: "Battlefield 4")

# Retrieves multiple games by names
# Requires an array of IDs
@client.games.retrieve(names: ["Battlefield 4", "Battlefield 2042"])
```

### EventSub Subscriptions

These require an application OAuth access token.

```ruby
# Retrieves a list of EventSub Subscriptions
# Available parameters: status, type, user_id, after, conduit_id, subscription_id
@client.eventsub_subscriptions.list
@client.eventsub_subscriptions.list(status: "enabled")
@client.eventsub_subscriptions.list(type: "channel.follow")
@client.eventsub_subscriptions.list(conduit_id: "conduit-id")

# Create an EventSub Subscription
@client.eventsub_subscriptions.create(
  type: "channel.follow",
  version: 1,
  condition: {broadcaster_user_id: 123},
  transport: {method: "webhook", callback: "webhook_url", secret: "secret"}
)

# If Twitch returns a 409 conflict for an already-existing subscription,
# the raised error exposes the existing subscription ID
begin
  @client.eventsub_subscriptions.create(
    type: "channel.follow",
    version: 1,
    condition: {broadcaster_user_id: 123},
    transport: {method: "webhook", callback: "webhook_url", secret: "secret"}
  )
rescue Twitch::Errors::EventsubSubscriptionConflictError => e
  e.existing_subscription_id
end

# The generic EventSub API also supports beta subscription types such as
# channel.custom_power_up_redemption.add with version "beta"
@client.eventsub_subscriptions.create(
  type: "channel.custom_power_up_redemption.add",
  version: "beta",
  condition: {broadcaster_user_id: 123},
  transport: {method: "webhook", callback: "webhook_url", secret: "secret"}
)

# Delete an EventSub Subscription
# IDs are UUIDs
@client.eventsub_subscriptions.delete(id: "abc12-abc12-abc12")
```

### EventSub Webhooks

When Twitch sends EventSub notifications to your webhook callback, you must verify each request came from Twitch
before trusting it. `Twitch::EventsubWebhook` checks the HMAC signature using the `secret` you passed when creating
the subscription, and rejects messages older than 10 minutes to guard against replay attacks.

Pass the **raw** request body, as the signature covers the exact bytes Twitch sent. `headers` can be a Hash,
a Rack env, or Rails' `request.headers`.

```ruby
# Rails example
class TwitchWebhooksController < ApplicationController
  skip_forgery_protection

  def create
    webhook = Twitch::EventsubWebhook.new(
      secret: ENV["TWITCH_EVENTSUB_SECRET"],
      headers: request.headers,
      body: request.raw_post
    )

    return head :forbidden unless webhook.valid?

    if webhook.verification?
      # Twitch confirms you own the callback when you create a subscription
      render plain: webhook.challenge
    elsif webhook.notification?
      # Twitch may send a message more than once, so skip message IDs you've already processed
      # webhook.subscription_type  #=> "channel.follow"
      # webhook.event              #=> #<Twitch::Object user_id="1234", user_login="cool_user", ...>
      head :no_content
    elsif webhook.revocation?
      # webhook.subscription.status  #=> "authorization_revoked"
      head :no_content
    end
  end
end

# Or just check the signature and timestamp
Twitch::EventsubWebhook.verify(secret: "...", headers: request.headers, body: request.raw_post)

# Allow a different maximum message age, in seconds (default 600)
Twitch::EventsubWebhook.new(secret: "...", headers: request.headers, body: request.raw_post, max_age: 300)
```

Other readers: `message_id`, `message_type`, `timestamp`, `retry?`, `subscription_version`, `payload` (the parsed body),
`signature_valid?`, and `expired?`.

### Custom Power-ups

```ruby
# Get all custom Power-ups for a broadcaster
# Required scope: bits:read
# broadcaster_id must match the currently authenticated user
@client.custom_power_ups.list(broadcaster_id: 123)

# Filter custom Power-ups by ID
@client.custom_power_ups.list(broadcaster_id: 123, ids: ["power-up-1", "power-up-2"])
```

### EventSub Conduits

Conduits provide a way to receive events over multiple transports. These require an application OAuth access token.

```ruby
# List all conduits for your application
@client.eventsub_conduits.list

# Create a conduit with a specified number of shards
# shard_count must be between 1 and 100
@client.eventsub_conduits.create(shard_count: 10)

# Update a conduit's shard count
@client.eventsub_conduits.update(id: "abc123-def456", shard_count: 20)

# Delete a conduit
@client.eventsub_conduits.delete(id: "abc123-def456")

# List shards for a conduit
# Optional parameters: status, after
@client.eventsub_conduits.shards(id: "abc123-def456")
@client.eventsub_conduits.shards(id: "abc123-def456", status: "enabled")

# Update shards for a conduit
# shards is an array of shard objects with id and transport properties
shards = [
  {
    id: "0",
    transport: {
      method: "webhook",
      callback: "https://example.com/webhooks/callback",
      secret: "your-secret"
    }
  }
]
result = @client.eventsub_conduits.update_shards(id: "abc123-def456", shards: shards)

# Twitch accepts up to 100 shards per request, so larger lists are sent in batches automatically.
# Twitch applies the valid shards even if others fail, so check errors for any that didn't update:
result.errors.each do |error|
  puts "Shard #{error.id} failed: #{error.message} (#{error.code})"
end
```

### Banned Users

```ruby
# Retrieves all banned and timed-out users for a channel
# Available parameters: user_id
@client.banned_users.list(broadcaster_id: 123)
```

```ruby
# Ban/Timeout a user from a broadcaster's channel
# Required scope: moderator:manage:banned_users
# A reason is required
# To time a user out, a duration is required. If no duration is set, the user will be banned.
@client.banned_users.create broadcaster_id: 123, moderator_id: 321, user_id: 112233, reason: "testing", duration: 60
```

```ruby
# Unban/untimeout a user from a broadcaster's channel
# Required scope: moderator:manage:banned_users
@client.banned_users.delete broadcaster_id: 123, moderator_id: 321, user_id: 112233
```

### Send Chat Announcement

```ruby
# Sends an announcement to the broadcaster's chat room
# Requires moderator:manage:announcements
# moderator_id can be either the currently authenticated moderator or the broadcaster
# color can be either blue, green, orange, purple, primary. If left blank, primary is default
@client.announcements.create broadcaster_id: 123, moderator_id: 123, message: "test message", color: "purple"

# When using an App Access Token during a shared chat session, set for_source_only: false
# to send the announcement to all channels in the session instead of only the source channel
@client.announcements.create broadcaster_id: 123, moderator_id: 123, message: "shared announcement", for_source_only: false
```

### Create a Shoutout

```ruby
# Creates a Shoutout for a broadcaster
# Requires moderator:manage:shoutouts
# From: the ID of the Broadcaster creating the Shoutout
# To: the ID of the Broadcaster the Shoutout will be for
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.shoutouts.create from: 123, to: 321, moderator_id: 123
```

### Moderators

```ruby
# List all channels a user has moderator privileges on
# Required scope: user:read:moderated_channels
# user_id must be the currently authenticated user
@client.moderators.channels user_id: 123
```

```ruby
# List all moderators for a broadcaster
# Required scope: moderation:read
# broadcaster_id must be the currently authenticated user
@client.moderators.list broadcaster_id: 123
```

```ruby
# Add a Moderator
# Required scope: channel:manage:moderators
# broadcaster_id must be the currently authenticated user
@client.moderators.create broadcaster_id: 123, user_id: 321
```

```ruby
# Remove a Moderator
# Required scope: channel:manage:moderators
# broadcaster_id must be the currently authenticated user
@client.moderators.delete broadcaster_id: 123, user_id: 321
```

### VIPs

```ruby
# List all VIPs for a broadcaster
# Required scope: channel:read:vips or channel:manage:vips
# broadcaster_id must be the currently authenticated user
@client.vips.list broadcaster_id: 123
```

```ruby
# Add a VIP
# Required scope: channel:manage:vips
# broadcaster_id must be the currently authenticated user
@client.vips.create broadcaster_id: 123, user_id: 321
```

```ruby
# Remove a VIP
# Required scope: channel:manage:vips
# broadcaster_id must be the currently authenticated user
@client.vips.delete broadcaster_id: 123, user_id: 321
```

### Raids

```ruby
# Starts a raid
# Requires channel:manage:raids
# from_broadcaster_id must be the authenticated user
@client.raids.create from_broadcaster_id: 123, to_broadcaster_id: 321
```

```ruby
# Requires channel:manage:raids
# broadcaster_id must be the authenticated user
@client.raids.delete broadcaster_id: 123
```

### Chat Messages

```ruby
# Send a chat message to a broadcaster's chat room
# Requires an app or user access token that includes user:write:chat then either user:bot or channel:bot
# sender_id must be the currently authenticated user
# reply_to is optional and is the UUID of the message to reply to
@client.chat_messages.create broadcaster_id: 123, sender_id: 321, message: "A test message", reply_to: "aabbcc"

# When using an App Access Token during a shared chat session, control whether the message
# is only sent to the source channel or shared to all channels in the session
@client.chat_messages.create broadcaster_id: 123, sender_id: 321, message: "Shared chat message", for_source_only: false

# Optionally pin the message immediately after sending it
# Requires moderator:manage:chat_messages and the sender must be the broadcaster or a moderator
@client.chat_messages.create broadcaster_id: 123, sender_id: 321, message: "Read the rules", pin: true

# Removes a single chat message from the broadcaster's chat room
# Requires moderator:manage:chat_messages
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.chat_messages.delete broadcaster_id: 123, moderator_id: 123, message_id: "abc123-abc123"
```

### Pinned Chat Messages

```ruby
# Get the currently pinned chat message
# Requires moderator:read:chat_messages or moderator:manage:chat_messages
@client.pinned_chat_messages.retrieve broadcaster_id: 123, moderator_id: 321

# Pin a message
# Requires moderator:manage:chat_messages
@client.pinned_chat_messages.create broadcaster_id: 123, moderator_id: 321, message_id: "abc123-abc123", duration_seconds: 300

# Update a pinned message's duration
# Requires moderator:manage:chat_messages
@client.pinned_chat_messages.update broadcaster_id: 123, moderator_id: 321, message_id: "abc123-abc123", duration_seconds: 120

# Unpin a message
# Requires moderator:manage:chat_messages
@client.pinned_chat_messages.delete broadcaster_id: 123, moderator_id: 321, message_id: "abc123-abc123"
```

### Whispers

```ruby
# Send a Whisper
# Required scope: user:manage:whispers
# from_user_id must be the currently authenticated user's ID and have a verified phone number
@client.whispers.create from_user_id: 123, to_user_id: 321, message: "this is a test"
```

### AutoMod

```ruby
# Check if a message meets the channel's AutoMod requirements
# Required scope: moderation:read
# id is a developer-generated identifier for mapping messages to results.
@client.automod.check_status_multiple broadcaster_id: 123, id: "abc123", text: "Is this message allowed?"

#> #<Twitch::AutomodStatus msg_id="abc123", is_permitted=true>
```

```ruby
# Check if multiple messages meet the channel's AutoMod requirements
# messages must be an array of hashes and must include msg_id and msg_text
# Returns a collection
messages = [{msg_id: "abc1", msg_text: "is this allowed?"}, {msg_id: "abc2", msg_text: "What about this?"}]
@client.automod.check_status_multiple broadcaster_id: 123, messages: messages
```

```ruby
# Get AutoMod settings
# Required scope: moderator:read:automod_settings
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.automod.settings broadcaster_id: 123, moderator_id: 321
```

```ruby
# Update AutoMod settings
# Required scope: moderator:manage:automod_settings
# moderator_id can be either the currently authenticated moderator or the broadcaster
# As this is a PUT method, it overwrites all options so all fields you want set should be supplied
@client.automod.update_settings broadcaster_id: 123, moderator_id: 321, swearing: 1
```

### Creator Goals

```ruby
# List all active creator goals
# Required scope: channel:read:goals
# broadcaster_id must match the currently authenticated user
@client.goals.list broadcaster_id: 123
```

### Blocked Terms

```ruby
# List all blocked terms
# Required scope: moderator:read:blocked_terms
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.blocked_terms.list broadcaster_id: 123, moderator_id: 321
```

```ruby
# Create a blocked term
# Required scope: moderator:manage:blocked_terms
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.blocked_terms.create broadcaster_id: 123, moderator_id: 321, text: "term to block"
```

```ruby
# Delete a blocked term
# Required scope: moderator:manage:blocked_terms
# moderator_id can be either the currently authenticated moderator or the broadcaster
@client.blocked_terms.delete broadcaster_id: 123, moderator_id: 321, id: "abc12-12abc"
```

### Charity Campaigns

```ruby
# Gets information about the charity campaign that a broadcaster is running
# Required scope: channel:read:charity
# broadcaster_id must match the currently authenticated user
@client.charity_campaigns.list broadcaster_id: 123

# Gets the donations made to the broadcaster's active charity campaign
# Required scope: channel:read:charity
# broadcaster_id must match the currently authenticated user
@client.charity_campaigns.donations(broadcaster_id: 123)
```

### Chatters

```ruby
# Gets the list of users that are connected to the specified broadcaster’s chat session
# Required scope: moderator:read:chatters
# broadcaster_id must match the currently authenticated user
@client.chatters.list broadcaster_id: 123, moderator_id: 123
```

### Shared Chat Sessions

```ruby
# Get the active shared chat session for a broadcaster
@client.shared_chat_sessions.retrieve broadcaster_id: 123
```

### Channel Points Custom Rewards

```ruby
# Gets a list of custom rewards for a specific channel
# Required scope: channel:read:redemptions
# broadcaster_id must match the currently authenticated user
@client.custom_rewards.list broadcaster_id: 123

# Create a custom reward
# Required scope: channel:manage:redemptions
# broadcaster_id must match the currently authenticated user
@client.custom_rewards.create broadcaster_id: 123, title: "New Reward", cost: 1000

# Update a custom reward
# Required scope: channel:manage:redemptions
# broadcaster_id must match the currently authenticated user
@client.custom_rewards.update broadcaster_id: 123, reward_id: 321, title: "Updated Reward"

# Delete a custom reward
# Required scope: channel:manage:redemptions
# broadcaster_id must match the currently authenticated user
@client.custom_rewards.delete broadcaster_id: 123, reward_id: 321
```

### Channel Points Custom Reward Redemptions

```ruby
# Gets a list of custom reward redemptions for a specific channel
# Required scope: channel:read:redemptions
# broadcaster_id must match the currently authenticated user
@client.custom_reward_redemptions.list broadcaster_id: 123, reward_id: 321, status: "UNFULFILLED"

# Update a custom reward redemption status
# Required scope: channel:manage:redemptions
# broadcaster_id must match the currently authenticated user
# Status can be FULFILLED or CANCELED
@client.custom_reward_redemptions.update broadcaster_id: 123, reward_id: 321, redemption_id: 123, status: "FULFILLED"
```

### Unban Requests

```ruby
# Retrieves a list of Unban Requests for a broadcaster
# Required scope: moderator:read:unban_requests or moderator:manage:unban_requests
# moderator_id must match the currently authenticated user
@client.unban_requests.list broadcaster_id: 123, moderator_id: 123, status: "pending"

# Resolve an Unban Request
# Required scope: moderator:manage:unban_requests
# moderator_id must match the currently authenticated user
@client.unban_requests.resolve broadcaster_id: 123, moderator_id: 123, id: "abc123", status: "approved"
```

### Warnings

```ruby
# Sends a warning to a user
# Required scope: moderator:manage:warnings
# moderator_id must match the currently authenticated user
@client.warnings.create broadcaster_id: 123, moderator_id: 123, user_id: 321, reason: "dont do that"
```

### Suspicious Users

```ruby
# Add suspicious status to a chat user
# Required scope: moderator:manage:suspicious_users
# moderator_id must match the currently authenticated moderator
@client.suspicious_users.create broadcaster_id: 123, moderator_id: 321, user_id: 456, status: "RESTRICTED"

# Remove suspicious status from a chat user
# Required scope: moderator:manage:suspicious_users
# moderator_id must match the currently authenticated moderator
@client.suspicious_users.delete broadcaster_id: 123, moderator_id: 321, user_id: 456
```

### Streams

```ruby
# List live streams
# Available parameters: user_id, user_login, game_id, type, language, first, before, after
@client.streams.list
@client.streams.list(game_id: "509658")
@client.streams.list(user_login: "twitchdev")

# Get followed streams for a user
# Required scope: user:read:follows
# user_id must match the currently authenticated user
@client.streams.followed(user_id: 123)
```

### Polls

```ruby
# List polls for a broadcaster
# broadcaster_id must match the currently authenticated user
@client.polls.list(broadcaster_id: 123)

# Create a poll
# broadcaster_id must match the currently authenticated user
# duration is in seconds (15-1800)
choices = [
  { title: "Choice 1" },
  { title: "Choice 2" }
]
@client.polls.create(broadcaster_id: 123, title: "What should I play?", choices: choices, duration: 300)

# End a poll
# broadcaster_id must match the currently authenticated user
# status can be "TERMINATED" or "ARCHIVED"
@client.polls.end(broadcaster_id: 123, id: "poll-id", status: "terminated")
```

### Predictions

```ruby
# List predictions for a broadcaster
# broadcaster_id must match the currently authenticated user
@client.predictions.list(broadcaster_id: 123)

# Create a prediction
# broadcaster_id must match the currently authenticated user
# duration is in seconds (30-1800)
outcomes = [
  { title: "Outcome 1" },
  { title: "Outcome 2" }
]
@client.predictions.create(broadcaster_id: 123, title: "Will I win?", outcomes: outcomes, duration: 600)

# End a prediction
# broadcaster_id must match the currently authenticated user
# status can be "RESOLVED", "CANCELED", or "LOCKED"
# winning_outcome_id is required when status is "RESOLVED"
@client.predictions.end(broadcaster_id: 123, id: "prediction-id", status: "resolved", winning_outcome_id: "outcome-id")
```

### Subscriptions

```ruby
# Get all subscriptions for a broadcaster
# Required scope: channel:read:subscriptions
# broadcaster_id must match the currently authenticated user
@client.subscriptions.list(broadcaster_id: 123)

# Check if a user is subscribed to a broadcaster
# Required scope: user:read:subscriptions
# user_id must match the currently authenticated user
# Returns a collection with the subscription, or raises Twitch::Errors::EntityNotFoundError if not subscribed
@client.subscriptions.is_subscribed(broadcaster_id: 123, user_id: 456)

# Or get true/false
@client.subscriptions.subscribed?(broadcaster_id: 123, user_id: 456)

# Get subscription counts and points for a broadcaster
# Required scope: channel:read:subscriptions
# broadcaster_id must match the currently authenticated user
@client.subscriptions.counts(broadcaster_id: 123)
```

### Search

```ruby
# Search for categories/games
@client.search.categories(query: "Just Chatting")

# Search for channels
@client.search.channels(query: "twitchdev")
```

### Stream Schedule

```ruby
# Get stream schedule for a broadcaster
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.list(broadcaster_id: 123)

# Get iCalendar format of stream schedule
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.icalendar(broadcaster_id: 123)

# Update stream schedule settings
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.update(broadcaster_id: 123, is_vacation_enabled: true)

# Create a schedule segment
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.create_segment(
  broadcaster_id: 123,
  start_time: "2023-08-01T16:00:00Z",
  timezone: "America/New_York",
  duration: "240",
  is_recurring: false,
  category_id: "509658",
  title: "Special Stream"
)

# Update a schedule segment
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.update_segment(broadcaster_id: 123, id: "segment-id", title: "Updated Title")

# Delete a schedule segment
# broadcaster_id must match the currently authenticated user
@client.stream_schedule.delete_segment(broadcaster_id: 123, id: "segment-id")
```

### Stream Markers

```ruby
# Create a stream marker
# Required scope: channel:manage:broadcast
# user_id must match the currently authenticated user
@client.stream_markers.create(user_id: 123, description: "Important moment")

# Get stream markers for a user or video
# Required scope: user:read:broadcast
# user_id must match the currently authenticated user
@client.stream_markers.list(user_id: 123)
@client.stream_markers.list(video_id: "video-id")
```

### Hype Train Status

```ruby
# Get hype train status for a broadcaster
# Required scope: channel:read:hype_train
# broadcaster_id must match the currently authenticated user
@client.hype_train_status.retrieve(broadcaster_id: 123)
```


### Ads

```ruby
# Gets the broadcaster's ad schedule and snooze details
# Required scope: channel:read:ads
# broadcaster_id must match the currently authenticated user
@client.ads.schedule(broadcaster_id: 123)

# Pushes back the next scheduled ad by 5 minutes
# Required scope: channel:manage:ads
# broadcaster_id must match the currently authenticated user
@client.ads.snooze(broadcaster_id: 123)
```

### Analytics

```ruby
# Gets URLs for downloadable CSV reports about the authenticated user's extensions
# Required scope: analytics:read:extensions
# Available parameters: extension_id, type, started_at, ended_at, first, after
@client.analytics.extensions(extension_id: "abc123")

# Gets URLs for downloadable CSV reports about the authenticated user's games
# Required scope: analytics:read:games
# Available parameters: game_id, type, started_at, ended_at, first, after
@client.analytics.games(game_id: 123)
```

### Bits

```ruby
# Gets the Bits leaderboard for the authenticated broadcaster
# Required scope: bits:read
# Available parameters: count, period, started_at, user_id
@client.bits.leaderboard(count: 10, period: "week")

# Gets the global Cheermotes, plus a broadcaster's custom Cheermotes if broadcaster_id is given
@client.bits.cheermotes
@client.bits.cheermotes(broadcaster_id: 123)
```

### Chat Settings

```ruby
# Gets a broadcaster's chat settings
# Pass moderator_id (matching the authenticated user) to include non_moderator_chat_delay settings
@client.chat_settings.retrieve(broadcaster_id: 123)
@client.chat_settings.retrieve(broadcaster_id: 123, moderator_id: 321)

# Updates a broadcaster's chat settings
# Required scope: moderator:manage:chat_settings
# moderator_id must match the currently authenticated user
# Available attributes: emote_mode, follower_mode, follower_mode_duration, non_moderator_chat_delay,
# non_moderator_chat_delay_duration, slow_mode, slow_mode_wait_time, subscriber_mode, unique_chat_mode
@client.chat_settings.update(broadcaster_id: 123, moderator_id: 321, slow_mode: true, slow_mode_wait_time: 10)
```

### Shield Mode

```ruby
# Gets a broadcaster's Shield Mode status
# Required scope: moderator:read:shield_mode or moderator:manage:shield_mode
# moderator_id must match the currently authenticated user
@client.shield_mode.retrieve(broadcaster_id: 123, moderator_id: 321)

# Turns Shield Mode on or off
# Required scope: moderator:manage:shield_mode
# moderator_id must match the currently authenticated user
@client.shield_mode.update(broadcaster_id: 123, moderator_id: 321, is_active: true)
```

### Content Classification Labels

```ruby
# Gets the content classification labels that can be applied to a channel with channels.update
@client.content_classification_labels.list
@client.content_classification_labels.list(locale: "en-US")
```

### Teams

```ruby
# Gets a team by ID or name
@client.teams.retrieve(id: 123)
@client.teams.retrieve(name: "staff")

# Gets the teams a broadcaster is a member of
@client.teams.channel(broadcaster_id: 123)
```

### Drops Entitlements

```ruby
# Gets Drops entitlements
# The Client ID must be owned by a member of the organization that owns the game
# Available parameters: id, user_id, game_id, fulfillment_status, first, after
@client.drops_entitlements.list(user_id: 123)

# Updates the fulfillment status of Drops entitlements (CLAIMED or FULFILLED)
@client.drops_entitlements.update(entitlement_ids: ["abc", "def"], fulfillment_status: "FULFILLED")
```

### Extensions

Most Extensions endpoints require a signed JWT created by your Extension Backend Service rather than an
OAuth token. Pass the JWT as the client's `access_token`. See
[Signing the JWT](https://dev.twitch.tv/docs/extensions/building/#signing-the-jwt).

```ruby
@ext_client = Twitch::Client.new(client_id: "extension-client-id", access_token: signed_jwt)

# Gets an extension (requires a JWT), or a released extension (app or user token)
@ext_client.extensions.retrieve(extension_id: "abc123")
@client.extensions.released(extension_id: "abc123", extension_version: "1.0.0")

# Gets live channels that have the extension installed or activated
@client.extensions.live_channels(extension_id: "abc123")

# Gets and sets configuration segments (requires a JWT)
# segment: broadcaster, developer or global. Pass an array to get more than one.
@ext_client.extensions.configuration(extension_id: "abc123", segment: "broadcaster", broadcaster_id: 123)
@ext_client.extensions.set_configuration(extension_id: "abc123", segment: "broadcaster", broadcaster_id: 123, content: "{}", version: "1")
@ext_client.extensions.set_required_configuration(broadcaster_id: 123, extension_id: "abc123", extension_version: "1.0.0", required_configuration: "RCS")

# Sends a PubSub message or chat message (requires a JWT)
@ext_client.extensions.send_pubsub_message(broadcaster_id: 123, target: ["broadcast"], message: "hello")
@ext_client.extensions.send_chat_message(broadcaster_id: 123, text: "hello", extension_id: "abc123", extension_version: "1.0.0")

# Gets or creates the extension's JWT secrets (requires a JWT)
@ext_client.extensions.secrets(extension_id: "abc123")
@ext_client.extensions.create_secret(extension_id: "abc123", delay: 300)

# Gets and updates Bits products
# Requires an app access token whose Client ID matches the extension's
@app_client.extensions.bits_products(should_include_all: true)
@app_client.extensions.update_bits_product(sku: "sku-1", cost: { amount: 100, type: "bits" }, display_name: "Thing")

# Gets Bits transactions for the extension
# Requires an app access token
@app_client.extensions.transactions(extension_id: "abc123")
```

### Guest Star (Beta)

```ruby
# Gets and updates a channel's Guest Star settings
@client.guest_star.settings(broadcaster_id: 123, moderator_id: 321)
@client.guest_star.update_settings(broadcaster_id: 123, slot_count: 4)

# Gets, creates and ends a Guest Star session
@client.guest_star.session(broadcaster_id: 123, moderator_id: 321)
@client.guest_star.create_session(broadcaster_id: 123)
@client.guest_star.end_session(broadcaster_id: 123, session_id: "abc")

# Gets, sends and deletes invites
@client.guest_star.invites(broadcaster_id: 123, moderator_id: 321, session_id: "abc")
@client.guest_star.send_invite(broadcaster_id: 123, moderator_id: 321, session_id: "abc", guest_id: 456)
@client.guest_star.delete_invite(broadcaster_id: 123, moderator_id: 321, session_id: "abc", guest_id: 456)

# Assigns, moves and removes guests in slots
@client.guest_star.assign_slot(broadcaster_id: 123, moderator_id: 321, session_id: "abc", guest_id: 456, slot_id: "1")
@client.guest_star.update_slot(broadcaster_id: 123, moderator_id: 321, session_id: "abc", source_slot_id: "1", destination_slot_id: "2")
@client.guest_star.delete_slot(broadcaster_id: 123, moderator_id: 321, session_id: "abc", guest_id: 456, slot_id: "1")

# Updates a slot's audio, video, live and volume settings
@client.guest_star.update_slot_settings(broadcaster_id: 123, moderator_id: 321, session_id: "abc", slot_id: "1", volume: 50)
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/deanpcmad/twitchrb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
