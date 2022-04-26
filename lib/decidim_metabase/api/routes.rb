# frozen_string_literal: true

module DecidimMetabase
  module Api
    module Routes
      module Collection
        def get(conn)
          conn.get(::Routes.API_COLLECTION_INDEX)
        end
      end

      ROUTE_PREFIX = "/api"
      API_SESSION = "#{ROUTE_PREFIX}/session"
      API_COLLECTION_INDEX = "#{ROUTE_PREFIX}/collection"
    end
  end
end
