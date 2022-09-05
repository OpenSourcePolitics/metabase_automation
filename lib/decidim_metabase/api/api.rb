# frozen_string_literal: true

module DecidimMetabase
  module Api
    # Default response error
    class ResponseError < StandardError
      def initialize(response = nil, msg = "Error occured in Metabase response")
        @response = response
        super(msg)
      end
    end

    # Allows to communicate with the Metabase API
    class Api
      def initialize(http_request)
        unless http_request.is_a?(DecidimMetabase::HttpRequests)
          raise ::ArgumentError, "Please use DecidimMetabase::HttpRequests as HTTP requester."
        end

        @http_request = http_request
      end
    end
  end
end
