# frozen_string_literal: true

module DecidimMetabase
  module Api
    # TokenNotFound raises when token is not found from Metabase
    class TokenNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Token not found in response")
        super(response, msg)
      end
    end

    # TokenInvalid raises when Metabase doesn't accept token
    class TokenInvalid < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Token is not authorized")
        super(response, msg)
      end
    end

    # Session defines a Metabase Session and refresh token if needed
    class Session
      attr_reader :token
      attr_accessor :conn, :token_db_path

      def initialize(conn, params_h, token_db_path = "token.private")
        @conn = conn
        @params_h = params_h
        @token_db_path = token_db_path
        @token = fetch_token!
      end

      def refresh_token!
        puts "Refreshing token"
        File.write(@token_db_path, "")
        fetch_token!
      end

      # rubocop:disable Metrics/MethodLength
      def fetch_token!
        token = already_existing_token
        return token unless token.nil? || token == ""

        response = @conn.post(DecidimMetabase::Api::Routes::API_SESSION) do |req|
          req.body = @params_h.to_json
        end

        body = JSON.parse(response.body)

        raise DecidimMetabase::Api::ResponseError, body if body.nil? || body.is_a?(String)

        token = body.fetch("id", nil)
        raise DecidimMetabase::Api::TokenNotFound, body if token.nil?

        unless token_db_path == "./spec/fixtures/token.public"
          File.open(@token_db_path, "w+") { |file| file.write(token) }
        end

        @token = token
      end
      # rubocop:enable Metrics/MethodLength

      def session_request_header
        { "X-Metabase-Session" => @token }
      end

      private

      def already_existing_token
        return unless File.exist? @token_db_path

        content = File.open(@token_db_path).read
        content.chomp
      end
    end
  end
end
