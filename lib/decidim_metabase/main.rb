# frozen_string_literal: true

require_relative "object/database"

module DecidimMetabase
  # Main - Main structure to work with Metabase
  class Main
    attr_accessor :configs, :databases
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
    alias set_connexion! conn

    def metabase_url
      @conn.build_url.to_s
    end

    def token_db_path
      "token.private"
    end

    def api_session
      @api_session ||= DecidimMetabase::Api::Session.new(conn, {
                                                           username: DecidimMetabase.env("METABASE_USERNAME"),
                                                           password: DecidimMetabase.env("METABASE_PASSWORD")
                                                         }, token_db_path)
    end
    alias set_api_session! api_session

    # HTTP Request builder
    def http_request
      @http_request ||= DecidimMetabase::HttpRequests.new(api_session)
    end
    alias set_http_request! http_request

    # Metabase database API
    def api_database
      @api_database ||= DecidimMetabase::Api::Database.new(http_request)
    end
    alias set_api_database! api_database

    # Store databases fetched from Metabase as Array of DecidimMetabase::Object::Database
    # Prints ID of the database found on STDOUT
    def set_databases!
      @databases = configs.databases.map do |db|
        database = DecidimMetabase::Object::Database.new api_database.find_by(db.name)
        puts "Database '#{database.name}' found (ID/#{database.id})".colorize(:light_green)

        database
      end
    end

    def load_all_fs_cards(collection, metabase_collection)
      Dir.glob(DecidimMetabase.cards_path).each do |path|
        next unless File.directory? path
        next if DecidimMetabase.ignore_card?(path)

        collection.local_cards!(Dir.glob("#{path}/*"), metabase_collection, configs["language"])
      end
    end

    def find_db_for(card)
      db_registry.select { |hash| hash["cards"] == card.cards_name }.first["db_name"]
    end
  end
end
