module DecidimMetabase
  module Api
    class TokenNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Token not found in response")
        super(response, msg)
      end
    end

    class TokenInvalid < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Token is not authorized")
        super(response, msg)
      end
    end

    class Session
      attr_reader :token
      attr_accessor :conn

      def initialize(conn, params_h, token_db_path="token.private")
        @conn = conn
        @params_h = params_h
        @token_db_path = token_db_path
        @token = get_token!
      end

      def refresh_token!
        puts "Refreshing token"
        File.write(@token_db_path, "")

        get_token!
      end

      def get_token!
        token = already_existing_token
        return token unless token.nil? || token == ""

        response = @conn.post(DecidimMetabase::Api::Routes::API_SESSION) do |req|
          req.body = @params_h.to_json
        end

        body = JSON.parse(response.body)

        raise DecidimMetabase::Api::ResponseError.new(body) if body.nil? || body.is_a?(String)
        token = body.fetch("id", nil)
        raise DecidimMetabase::Api::TokenNotFound.new(body) if token.nil?

        File.open(@token_db_path, "w+") { |file| file.write(token) }

        @token = token
        token
      end

      def session_request_header
        { "X-Metabase-Session" => @token }
      end

      private

      def already_existing_token
        return unless File.exists? @token_db_path

        File.open(@token_db_path)&.read.chomp
      end
    end
  end
end
