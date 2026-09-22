module Twitch
  class Client
    BASE_URL = "https://api.twitch.tv/helix"
    DEFAULT_TIMEOUT = 30
    DEFAULT_OPEN_TIMEOUT = 10

    attr_reader :client_id, :access_token, :adapter, :rate_limiter
    attr_reader :rate_limit_threshold, :auto_retry_rate_limit, :logger
    attr_reader :timeout, :open_timeout

    def initialize(
      client_id:,
      access_token:,
      adapter: Faraday.default_adapter,
      rate_limit_threshold: 10,
      auto_retry_rate_limit: true,
      logger: nil,
      timeout: DEFAULT_TIMEOUT,
      open_timeout: DEFAULT_OPEN_TIMEOUT
    )
      @client_id = client_id
      @access_token = access_token
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

    def banned_events
      BannedEventsResource.new(self)
    end

    def banned_users
      BannedUsersResource.new(self)
    end

    def moderators
      ModeratorsResource.new(self)
    end

    def moderator_events
      ModeratorEventsResource.new(self)
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

    def tags
      TagsResource.new(self)
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

    def connection
      @connection ||= Faraday.new(BASE_URL) do |conn|
        conn.request :authorization, :Bearer, access_token

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
  end
end
