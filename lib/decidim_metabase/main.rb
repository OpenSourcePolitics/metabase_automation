# frozen_string_literal: true

require_relative "object/database"

module DecidimMetabase
  class Main
    attr_accessor :configs, :query_interpreter, :databases
    attr_reader :db_registry

    def initialize(welcome)
      DecidimMetabase::Utils.welcome if welcome
    end

    # Define new Faraday connexion
    def conn
      @conn ||= Faraday.new(
        url: "https://#{DecidimMetabase.env("METABASE_HOST")}/",
        headers: { "Content-Type" => "application/json" }
      )
    end
    alias connexion! conn

    def api_session
      @api_session ||= DecidimMetabase::Api::Session.new(conn, {
                                                           username: DecidimMetabase.env("METABASE_USERNAME"),
                                                           password: DecidimMetabase.env("METABASE_PASSWORD")
                                                         })
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

    def load_databases!
      databases = configs["database"].map do |key, value|
        { "cards" => key, "db_name" => value["name"] }
      end

      @db_registry = databases
      @databases = databases
    end

    def load_all_fs_cards(collection, metabase_collection)
      Dir.glob(DecidimMetabase.cards_path).each do |path|
        next unless File.directory? path
        next if DecidimMetabase.ignore_card?(path)

        collection.local_cards!(Dir.glob("#{path}/*"), metabase_collection, configs["language"])
      end
    end

    def find_db_for(card)
      db_registry.select { |hash| hash["cards"] == card }.first["db_name"]
    end
  end
end
