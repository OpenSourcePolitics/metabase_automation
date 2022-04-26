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
  end
end
