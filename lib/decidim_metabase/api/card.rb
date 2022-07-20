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

      def create(card)
        request = @http_request.post("/api/card/", card.payload)
        JSON.parse(request.body)
      end

      def update(card)
        request = @http_request.put("/api/card/#{card.id}", card.payload)
        JSON.parse(request.body)
      end
    end
  end
end
