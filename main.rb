#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/decidim_metabase"
require "securerandom"
require "faraday"
require "faraday/net_http"
require "dotenv/load"
require "yaml"
require "colorize"
require "byebug"

main = DecidimMetabase::Main.new(true)

## Interesting things below...
begin
  TOKEN_DB_PATH = "token.private"
  # Load file 'config.yml'
  main.configs = YAML.load_file("config.yml")
  # Define new Faraday connexion
  Faraday.default_adapter = :net_http
  main.connexion!
  main.api_session!
  main.http_request!
  main.api_database!

  # Interpret local queries from decidim cards
  main.query_interpreter = DecidimMetabase::QueryInterpreter

  decidim_db = DecidimMetabase::Object::Database.new(api_database.find_by(configs["database"]["decidim"]["name"]))
  puts "Database '#{decidim_db.name}' found (ID/#{decidim_db.id})".colorize(:light_green)

  metabase_collection_response = DecidimMetabase::Api::Collection.new(http_request)
                                                                 .find_or_create!(configs["collection_name"])
  metabase_collection = DecidimMetabase::Object::Collection.new(metabase_collection_response)
  filesystem_collection = DecidimMetabase::Object::Collection.new(metabase_collection_response)

  api_cards = DecidimMetabase::Api::Card.new(http_request)
  metabase_collection.cards_from!(api_cards.cards)
  filesystem_collection.local_cards!(Dir.glob("./cards/decidim_cards/*"), metabase_collection, configs["language"])
  metabase_collection.define_resource(filesystem_collection)

  puts "Cards prepared to be saved in Metabase '#{filesystem_collection.cards.map(&:name).join(", ")}'"
         .colorize(:yellow)

  if (filesystem_collection.cards.map(&:name) - metabase_collection.cards.map(&:name)).count.positive?
    puts "Creating new cards #{filesystem_collection.cards.map(&:name) - metabase_collection.cards.map(&:name)}"
           .colorize(:light_green)
  end

  CARDS = filesystem_collection.cards + metabase_collection.cards

  filesystem_collection.cards.each_with_index do |card, _|
    card.query = query_interpreter.interpreter!(configs, card, CARDS)

    online_card = metabase_collection.find_card(card.name)
    card.update_id!(online_card.id) if online_card&.id
    card.need_update = online_card&.query != card.query

    card.build_payload!(metabase_collection, decidim_db.id, CARDS)
    if card.exist && card.need_update
      puts "Updating card '#{card.name}' (ID/#{card.id})".colorize(:light_yellow)
      updated = api_cards.update(card)
      puts "Card successfully updated (ID/#{updated["id"]})".colorize(:light_green)
      card.update_id!(updated["id"]) if card.id != updated["id"]
    elsif !card.exist
      puts "Creating card '#{card.name}'".colorize(:light_green)
      created = api_cards.create(card)
      puts "Card successfully created (ID/#{created["id"]})".colorize(:light_green)
      card.update_id!(created["id"]) if card.id != created["id"]
    else
      puts "Card '#{card.name}' already up-to-date".colorize(:green)
    end
  end

  puts "Program successfully terminated (Exit code: 0)".colorize(:light_green)
  exit 0
rescue StandardError => e
  puts "[#{e.class}] #{e.message} (Exit code: 2)".colorize(:light_red)
  puts e.backtrace.join("\n").colorize(:light_red) if ARGV.include?("-v")
  puts "You can enable verbose mode using '-v' to have the backtrace".colorize(:light_yellow) unless ARGV.include?("-v")
  puts "Operation terminated".colorize(:light_red)

  exit 2
end
