module DecidimMetabase
  class HttpRequests
    def initialize(api_session)
      @api_session = api_session
      @conn = api_session.conn
    end

    def get(url, params = nil)
      begin
        request = @conn.get(url,  params, @api_session.session_request_header)
        raise DecidimMetabase::Api::TokenInvalid if request.status == 301

        request
      rescue DecidimMetabase::Api::TokenInvalid => e
        puts "[#{e.class}] #{e.message}"
        @api_session.refresh_token!
        self.get(url, params)
      end
    end

    def post(url, params = nil)
      begin
        request = @conn.post(url,  params&.to_json, @api_session.session_request_header)
        raise DecidimMetabase::Api::TokenInvalid if request.status == 301

        request
      rescue DecidimMetabase::Api::TokenInvalid => e
        puts "[#{e.class}] #{e.message}"
        @api_session.refresh_token!
        self.post(url, params)
      end
    end

    def self.token
      @api_session.token
    end
  end
end
