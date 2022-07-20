# frozen_string_literal: true

module DecidimMetabase
  # HttpRequests contains HTTP queries to work with Metabase
  class HttpRequests
    attr_reader :api_session

    def initialize(api_session)
      @api_session = api_session
      @conn = api_session.conn
    end

    def get(url, params = nil)
      request = @conn.get(url, params, @api_session.session_request_header)
      raise DecidimMetabase::Api::TokenInvalid if request.status == 301

      request
    rescue DecidimMetabase::Api::TokenInvalid => e
      puts "[#{e.class}] #{e.message}"
      @api_session.refresh_token!
      get(url, params)
    end

    def post(url, params = nil)
      request = @conn.post(url, params&.to_json, @api_session.session_request_header)
      raise DecidimMetabase::Api::TokenInvalid if request.status == 301

      request
    rescue DecidimMetabase::Api::TokenInvalid => e
      puts "[#{e.class}] #{e.message}"
      @api_session.refresh_token!
      post(url, params)
    end

    def put(url, params = nil)
      request = @conn.put(url, params&.to_json, @api_session.session_request_header)
      raise DecidimMetabase::Api::TokenInvalid if request.status == 301

      request
    rescue DecidimMetabase::Api::TokenInvalid => e
      puts "[#{e.class}] #{e.message}"
      @api_session.refresh_token!
      post(url, params)
    end

    def self.token
      @api_session.token
    end
  end
end
