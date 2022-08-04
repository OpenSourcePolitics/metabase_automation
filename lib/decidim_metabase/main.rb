# frozen_string_literal: true

module DecidimMetabase
  class Main
    attr_accessor :configs, :query_interpreter, :database

    def initialize(welcome)
      DecidimMetabase::Utils.welcome if welcome
    end

    # Define new Faraday connexion
    def conn
      @conn ||= Faraday.new(
        url: "https://#{ENV.fetch("METABASE_HOST")}/",
        headers: { "Content-Type" => "application/json" }
      )
    end
    alias connexion! conn

    def api_session
      @api_session ||= DecidimMetabase::Api::Session.new(conn, {
        username: ENV.fetch("METABASE_USERNAME"),
        password: ENV.fetch("METABASE_PASSWORD")
        }
      )
    end
    alias api_session! api_session

    # HTTP Request builder
    def http_request
      @http_request ||= DecidimMetabase::HttpRequests.new(api_session)
    end
    alias http_request! http_request

    # Metabase database API
    def api_database
      @api_database ||= DecidimMetabase::Api::Database.new(http_request)
    end
    alias api_database! api_database
  end
end
