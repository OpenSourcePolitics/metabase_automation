module DecidimMetabase
  module Api
      class ResponseError < StandardError
        def initialize(response = nil, msg = "Error occured in Metabase response")
          @response = response
          super(msg)
        end
      end
  end
end
