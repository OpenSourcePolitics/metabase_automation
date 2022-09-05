# frozen_string_literal: true

require_relative "object/database"

module DecidimMetabase
  # Main - Main structure to work with Metabase
  # Define connexion, session, http requests, databases, cards actions
  class Main
    attr_accessor :configs, :databases, :metabase_collection, :metabase_cards, :metabase_api_collection,
                  :filesystem_collection, :api_cards
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
    alias define_connexion! conn

    def api_session
      @api_session ||= DecidimMetabase::Api::Session.new(conn, {
                                                           username: DecidimMetabase.env("METABASE_USERNAME"),
                                                           password: DecidimMetabase.env("METABASE_PASSWORD")
                                                         }, token_db_path)
    end
    alias define_api_session! api_session

    # HTTP Request builder
    def http_request
      @http_request ||= DecidimMetabase::HttpRequests.new(api_session)
    end
    alias define_http_request! http_request

    # Metabase database API
    def api_database
      @api_database ||= DecidimMetabase::Api::Database.new(http_request)
    end
    alias define_api_database! api_database

    # Store databases fetched from Metabase as Array of DecidimMetabase::Object::Database
    # Prints ID of the database found on STDOUT
    def set_databases!
      @databases = configs.databases.map do |db|
        database = DecidimMetabase::Object::Database.new(api_database.find_by(db.name), db.type)
        puts "Database '#{database.name}' found (ID/#{database.id})".colorize(:light_green)

        database
      end
    end

    # Fetch the Metabase database for the given card
    def find_db_for(card)
      @databases.select { |db| db.type == card.cards_name }.first
    end


    # Returns the metabase URL
    def metabase_url
      @conn&.build_url.to_s || ""
    end

    # File name where token will be stored on the disk
    def token_db_path
      "token.private"
    end

    # Read folders './cards/*' and for each folder, load the YAML cards.
    # For each folder in './cards/*' it saves the cards in @filesystem_collection.cards
    # @metabase_collection must be defined in order to link the filesystem card with existing cards
    def load_all_fs_cards!
      Dir.glob(DecidimMetabase.cards_path).each do |path|
        next unless File.directory? path
        next if DecidimMetabase.ignore_card?(path)

        @filesystem_collection.local_cards!(Dir.glob("#{path}/*"), @metabase_collection, configs.language)
      end
    end

    # This method creates the required collections and load all local cards
    # It registers the cards present in Metabase in the metabase_collection.cards
    def set_collections!
      prepare_metabase_collection!
      set_metabase_cards!
      set_filesystem_collection!

      @metabase_collection = DecidimMetabase::Object::Collection.new(@metabase_api_collection).tap do |obj|
        obj.cards_from!(@metabase_cards.cards)
      end

      load_all_fs_cards!
      @metabase_collection.define_resource(@filesystem_collection)
    end

    # Define @metabase_api_collection from the collection fetched from Metabase
    def prepare_metabase_collection!
      @metabase_api_collection = DecidimMetabase::Api::Collection.new(@http_request)
                                                                 .find_or_create!(@configs.collection_name)
    end

    # Define @metabase_cards from the cards fetched from Metabase
    def set_metabase_cards!
      @metabase_cards = DecidimMetabase::Api::Card.new(@http_request)
    end

    # Define @filesystem_collection from the collection fetched from Metabase
    def set_filesystem_collection!
      @filesystem_collection = DecidimMetabase::Object::Collection.new(@metabase_api_collection)
    end

    def create_new_cards?
      (@filesystem_collection.cards.map(&:name) - @metabase_collection.cards.map(&:name)).count.positive?
    end

    def set_api_cards!
      @api_cards = DecidimMetabase::Api::Card.new(@http_request)
    end

    def all_cards
      @all_cards ||= @filesystem_collection.cards + @metabase_collection.cards
    end

    def action_for(card, db)
      case card.switch_actions
      when :update
        puts "Updating card '#{card.name}' (#{db.type} - ID/#{card.id}) with URL : #{metabase_url}question/#{card.id}"
          .colorize(:light_yellow)
        updated = @api_cards.update(card)
        puts "Card successfully updated (#{db.type} - ID/#{updated["id"]})".colorize(:light_green)

        card.update_id!(updated["id"]) if card.id != updated["id"]
      when :create
        puts "Creating card '#{card.name}'".colorize(:light_green)
        created = @api_cards.create(card)
        puts "Card successfully created (#{db.type} - ID/#{created["id"]})".colorize(:light_green)

        card.update_id!(created["id"]) if card.id != created["id"]
      when :up_to_date
        puts "Card '#{card.name}' already up-to-date (#{db.type} - ID/#{card.id})".colorize(:green)
      else
        puts "Unexpected action for card '#{card.name}' - Directory #{db.type}"
      end
    end

    def store_and_update_cards!
      @filesystem_collection.cards.each do |card|
        card.query = DecidimMetabase::QueryInterpreter.interpreter!(@configs, card, all_cards)

        online_card = @metabase_collection.find_card(card.name)
        card.update_id!(online_card.id) if online_card&.id
        card.need_update = online_card&.query != card.query
        db = find_db_for(card)
        next if db.nil?

        card.build_payload!(@metabase_collection, db.id, all_cards)
        action_for(card, db)
      end
    end
  end
end
