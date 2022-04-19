module DecidimMetabase
  module Api
    class TokenNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Toke not found in response")
        super(response, msg)
      end
    end

    class Session
      attr_reader :token

      def initialize(conn, params_h)
        @token = get_token(conn, params_h)
      end

      def get_token(conn, params_h)
        token = already_existing_token
        return token unless token.nil? || token == ""

        response = conn.post(::Routes.API_SESSION) do |req|
          req.body = params_h.to_json
        end

        body = JSON.parse(response.body)

        raise DecidimMetabase::Api::ResponseError.new(body) if body.nil? || body.is_a?(String)
        token = body.fetch("id", nil)
        raise DecidimMetabase::Api::TokenNotFound.new(body) if token.nil?

        File.open("token.private", "w+") { |file| file.write(token) }

        token
      end

      private

      def already_existing_token
        File.open(TOKEN_DB_PATH).read
      end
    end
  end
end
