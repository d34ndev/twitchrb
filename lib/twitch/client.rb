module Twitch
  class Client
    BASE_URL = "https://api.twitch.tv/helix"
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10

    attr_reader :client_id, :access_token, :adapter, :rate_limiter
    attr_reader :rate_limit_threshold, :auto_retry_rate_limit, :logger
    attr_reader :timeout, :open_timeout
    attr_reader :refresh_token, :client_secret, :on_token_refresh

    # Pass refresh_token to refresh expired user access tokens automatically. client_secret is
    # needed unless your app is a public client. on_token_refresh is called with the new token
    # (access_token, refresh_token, expires_in, scope) so you can store it.
    def initialize(
      client_id:,
      access_token:,
      refresh_token: nil,
      client_secret: nil,
      on_token_refresh: nil,
      adapter: Faraday.default_adapter,
      rate_limit_threshold: 10,
      auto_retry_rate_limit: true,
      logger: nil,
      timeout: DEFAULT_TIMEOUT,
      open_timeout: DEFAULT_OPEN_TIMEOUT
    )
      @client_id = client_id
      @access_token = access_token
      @refresh_token = refresh_token
      @client_secret = client_secret
      @on_token_refresh = on_token_refresh
      @token_refresh_mutex = Mutex.new
      @adapter = adapter
      @rate_limit_threshold = rate_limit_threshold
      @auto_retry_rate_limit = auto_retry_rate_limit
      @logger = logger
      @timeout = timeout
      @open_timeout = open_timeout
      @rate_limiter = RateLimiter.new(logger: logger)
    end

    def users
      UsersResource.new(self)
    end

    def channels
      ChannelsResource.new(self)
    end

    def emotes
      EmotesResource.new(self)
    end

    def badges
      BadgesResource.new(self)
    end

    def games
      GamesResource.new(self)
    end

    def videos
      VideosResource.new(self)
    end

    def clips
      ClipsResource.new(self)
    end

    def eventsub_subscriptions
      EventsubSubscriptionsResource.new(self)
    end

    def eventsub_conduits
      EventsubConduitsResource.new(self)
    end

    def banned_users
      BannedUsersResource.new(self)
    end

    def moderators
      ModeratorsResource.new(self)
    end

    def polls
      PollsResource.new(self)
    end

    def predictions
      PredictionsResource.new(self)
    end

    def stream_schedule
      StreamScheduleResource.new(self)
    end

    def search
      SearchResource.new(self)
    end

    def streams
      StreamsResource.new(self)
    end

    def stream_markers
      StreamMarkersResource.new(self)
    end

    def subscriptions
      SubscriptionsResource.new(self)
    end

    def custom_rewards
      CustomRewardsResource.new(self)
    end

    def custom_reward_redemptions
      CustomRewardRedemptionsResource.new(self)
    end

    def custom_power_ups
      CustomPowerUpsResource.new(self)
    end

    def goals
      GoalsResource.new(self)
    end

    def hype_train_events
      HypeTrainEventsResource.new(self)
    end

    def hype_train_status
      HypeTrainStatusResource.new(self)
    end

    def announcements
      AnnouncementsResource.new(self)
    end

    def raids
      RaidsResource.new(self)
    end

    def chat_messages
      ChatMessagesResource.new(self)
    end

    def pinned_chat_messages
      PinnedChatMessagesResource.new(self)
    end

    def vips
      VipsResource.new(self)
    end

    def whispers
      WhispersResource.new(self)
    end

    def automod
      AutomodResource.new(self)
    end

    def blocked_terms
      BlockedTermsResource.new(self)
    end

    def charity_campaigns
      CharityCampaignsResource.new(self)
    end

    def chatters
      ChattersResource.new(self)
    end

    def shoutouts
      ShoutoutsResource.new(self)
    end

    def shared_chat_sessions
      SharedChatSessionsResource.new(self)
    end

    def unban_requests
      UnbanRequestsResource.new(self)
    end

    def warnings
      WarningsResource.new(self)
    end

    def suspicious_users
      SuspiciousUsersResource.new(self)
    end

    def ads
      AdsResource.new(self)
    end

    def analytics
      AnalyticsResource.new(self)
    end

    def bits
      BitsResource.new(self)
    end

    def chat_settings
      ChatSettingsResource.new(self)
    end

    def content_classification_labels
      ContentClassificationLabelsResource.new(self)
    end

    def drops_entitlements
      DropsEntitlementsResource.new(self)
    end

    def extensions
      ExtensionsResource.new(self)
    end

    def guest_star
      GuestStarResource.new(self)
    end

    def shield_mode
      ShieldModeResource.new(self)
    end

    def teams
      TeamsResource.new(self)
    end

    # Refreshes the access token using the refresh token, and returns the new token
    def refresh_access_token!
      raise Error, "A refresh_token is required to refresh the access token" unless refresh_token

      @token_refresh_mutex.synchronize { perform_token_refresh }
    end

    # Called after a 401. Refreshes the token if the response means it has expired, unless
    # another thread already refreshed it. Returns true if the request should be retried.
    def refresh_after_unauthorized(response, failed_access_token)
      return false unless refresh_token && token_expired_response?(response)

      @token_refresh_mutex.synchronize do
        perform_token_refresh if access_token == failed_access_token
      end

      true
    end

    def connection
      @connection ||= Faraday.new(BASE_URL) do |conn|
        # A lambda, so requests pick up a refreshed token
        conn.request :authorization, :Bearer, -> { access_token }

        conn.headers = {
          "User-Agent" => "twitchrb/v#{VERSION} (github.com/deanpcmad/twitchrb)",
          "Client-ID": client_id
        }

        # Helix expects repeated keys for multiple values (id=1&id=2), not id[]=1&id[]=2
        conn.options.params_encoder = Faraday::FlatParamsEncoder
        conn.options.timeout = timeout
        conn.options.open_timeout = open_timeout

        conn.request :json

        conn.response :json, content_type: "application/json"

        conn.adapter adapter
      end
    end

    private

    def oauth
      @oauth ||= OAuth.new(client_id: client_id, client_secret: client_secret, timeout: timeout, open_timeout: open_timeout)
    end

    def perform_token_refresh
      token = oauth.refresh(refresh_token: refresh_token)

      @access_token = token.access_token
      @refresh_token = token.refresh_token if token.refresh_token
      on_token_refresh&.call(token)

      token
    end

    # Helix also returns 401 for a token missing a required scope, which a refresh won't fix
    def token_expired_response?(response)
      message = response.body.is_a?(Hash) ? response.body["message"].to_s : ""
      !message.match?(/missing scope/i)
    end
  end
end
