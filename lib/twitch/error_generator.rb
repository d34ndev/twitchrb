module Twitch
  class ErrorGenerator < Error
    attr_reader :response_body
    attr_reader :http_status_code
    attr_reader :twitch_error_code
    attr_reader :twitch_error_message

    def initialize(response_body, http_status_code)
      @response_body = response_body
      @http_status_code = http_status_code
      set_twitch_error_values
      super(build_message)
    end

    private

    def set_twitch_error_values
      parsed_body = parse_response_body
      @twitch_error_code = parsed_body.dig("error")
      @twitch_error_message = parsed_body.dig("message")
    end

    def parse_response_body
      case @response_body
      when Hash
        @response_body
      when String
        JSON.parse(@response_body)
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end

    def error_message
      parsed_body = parse_response_body
      @twitch_error_message || parsed_body.dig("error")
    rescue NoMethodError
      "An unknown error occurred."
    end

    def build_message
      message = "Error #{@http_status_code}: #{error_message}"
      if twitch_error_message && twitch_error_message != error_message
        message += " '#{twitch_error_message}'"
      end
      message
    end
  end

  module Errors
    class BadRequestError < ErrorGenerator
      private

      def error_message
        "Your request was malformed."
      end
    end

    class AuthenticationMissingError < ErrorGenerator
      private

      def error_message
        "You did not supply valid authentication credentials."
      end
    end

    class ForbiddenError < ErrorGenerator
      private

      def error_message
        "You are not allowed to perform that action."
      end
    end

    class EntityNotFoundError < ErrorGenerator
      private

      def error_message
        "No results were found for your request."
      end
    end

    class ConflictError < ErrorGenerator
      private

      def error_message
        "Your request was a conflict."
      end
    end

    class EventsubSubscriptionConflictError < ConflictError
      attr_reader :existing_subscription_id

      def initialize(response_body, http_status_code, existing_subscription_id: nil)
        @existing_subscription_id = existing_subscription_id
        super(response_body, http_status_code)
      end
    end

    class TooManyRequestsError < ErrorGenerator
      private

      def error_message
        "Your request exceeded the API rate limit."
      end
    end

    class RateLimitError < TooManyRequestsError
      attr_reader :reset_at, :remaining, :limit

      def initialize(response_body, http_status_code, reset_at: nil, remaining: nil, limit: nil)
        @reset_at = reset_at
        @remaining = remaining
        @limit = limit
        super(response_body, http_status_code)
      end

      private

      def build_message
        base_message = super
        rate_info = build_rate_info
        "#{base_message}#{rate_info}"
      end

      def build_rate_info
        return "" if reset_at.nil?

        reset_time = Time.at(reset_at).strftime("%H:%M:%S")
        info = " (Resets at #{reset_time}"
        info += ", #{remaining}/#{limit} requests" if remaining && limit
        info + ")"
      end
    end

    class InternalError < ErrorGenerator
      private

      def error_message
        "We were unable to perform the request due to server-side problems."
      end
    end

    class ServiceUnavailableError < ErrorGenerator
      private

      def error_message
        "You have been rate limited for sending more than 20 requests per second."
      end
    end

    class NotImplementedError < ErrorGenerator
      private

      def error_message
        "This resource has not been implemented."
      end
    end
  end

  class ErrorFactory
    HTTP_ERROR_MAP = {
      400 => Errors::BadRequestError,
      401 => Errors::AuthenticationMissingError,
      403 => Errors::ForbiddenError,
      404 => Errors::EntityNotFoundError,
      409 => Errors::ConflictError,
      429 => Errors::TooManyRequestsError,
      500 => Errors::InternalError,
      503 => Errors::ServiceUnavailableError,
      501 => Errors::NotImplementedError
    }.freeze

    def self.create(response_body, http_status_code)
      status = http_status_code
      error_class = HTTP_ERROR_MAP[status] || ErrorGenerator
      error_class.new(response_body, http_status_code) if error_class
    end
  end
end
