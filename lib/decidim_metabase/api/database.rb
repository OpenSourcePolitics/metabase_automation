# frozen_string_literal: true

module DecidimMetabase
  module Api
    # DatabaseNotFound raises when database was not found in database
    class DatabaseNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Database is not present")
        super(response, msg)
      end
    end

    # Database defines a Metabase Database
    class Database
      def initialize(http_request)
        unless http_request.is_a?(DecidimMetabase::HttpRequests)
          raise ::ArgumentError, "Please use DecidimMetabase::HttpRequests while initializing database."
        end

        @http_request = http_request
      end

      def databases
        request = @http_request.get("/api/database", { "include_cards" => "true" })
        body = JSON.parse(request.body)

        @databases = body["data"]
      end

      def find_by(name = "")
        return if name == "" || name.nil?

        # rubocop:disable Lint/SafeNavigationChain
        db = databases&.select { |database| name == database["name"] }.compact.first
        # rubocop:enable Lint/SafeNavigationChain

        raise DatabaseNotFound if db.nil? || db.empty?

        db
      end
    end
  end
end
