# frozen_string_literal: true

module DecidimMetabase
  module Api
    # Defines Metabase Card
    class Card < Api
      def cards
        request = @http_request.get("/api/card")
        body = JSON.parse(request.body)

        @cards = body
      end
    end
  end
end
