# frozen_string_literal: true

module DecidimMetabase
  module Api
    class DatabaseNotFound < DecidimMetabase::Api::ResponseError
      def initialize(response = nil, msg = "Database is not present")
        super(response, msg)
      end
    end

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

        db = databases&.select { |database| name == database["name"] }.compact.first
        raise DatabaseNotFound if db.nil? || db.empty?

        db
      end
    end
  end
end
