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

def render_ascii_art
  File.readlines("ascii.txt")[0..-2].each do |line|
    puts line
  end
  puts "                     Module Metabase (v#{DecidimMetabase::VERSION})".colorize(:cyan)
  puts "                     By Open Source Politics.".colorize(:cyan)
  puts "\n"
end

render_ascii_art

## Interesting things below...

begin
  TOKEN_DB_PATH = "token.private"

  # Load file 'config.yml'
  configs = YAML.load_file("config.yml")

  # Define new Faraday connexion
  Faraday.default_adapter = :net_http
  conn = Faraday.new(
    url: "https://#{ENV.fetch("METABASE_HOST")}/",
    headers: { "Content-Type" => "application/json" }
  )

  # Define API Session
  api_session = DecidimMetabase::Api::Session.new(conn, {
    username: ENV.fetch("METABASE_USERNAME"),
    password: ENV.fetch("METABASE_PASSWORD")
  })

  # HTTP Request builder
  http_request = DecidimMetabase::HttpRequests.new(api_session)

  # Metabase database API
  api_database = DecidimMetabase::Api::Database.new(http_request)

  query_interpreter = DecidimMetabase::QueryInterpreter

  decidim_db = api_database.find_by(configs["database"]["decidim"]["name"])
  puts "Database '#{configs["database"]["decidim"]["name"]}' found (ID/#{decidim_db["id"]})".colorize(:green)

  api_collection = DecidimMetabase::Api::Collection.new(http_request)
  metabase_collection_response = api_collection.find_or_create!(configs["collection_name"])
  metabase_collection = DecidimMetabase::Object::Collection.new(metabase_collection_response)
  filesystem_collection = DecidimMetabase::Object::Collection.new(metabase_collection_response)

  filesystem_collection.cards = Dir.glob("./cards/decidim_cards/*").map do |path|
    next unless File.directory?(path)

    card = DecidimMetabase::Object::FileSystemCard.new(path)
    card.collection_id = metabase_collection.id
    card
  end.compact.sort_by(&:dependencies)

  collection_online_cards = JSON.parse(http_request.get("/api/card/").body)
  metabase_collection.cards = collection_online_cards.map do |online_card|
    next if online_card["collection"].nil? || online_card["collection"].empty?

    card = DecidimMetabase::Object::Card.new(online_card, false)
    next unless card&.collection_id == metabase_collection.id
    puts "Found existing card '#{card.name}'".colorize(:green)

    card
  end.compact

  puts "Cards prepared to be save in Metabase '#{filesystem_collection.cards.map(&:name).join(", ")}'".colorize(:yellow)

  # Sorting fs cards by dependencies
  filesystem_collection.cards.each_with_index do |card, index|
    next if card.dependencies.empty?

    deps_ids = []
    card.dependencies.each do |dep|
      deps_id = filesystem_collection.cards.index { |elem| elem&.name == dep }
      deps_ids << deps_id unless deps_id.nil?
    end
    next if deps_ids.empty?
    next if index > deps_ids.max

    filesystem_collection.cards[index], filesystem_collection.cards[deps_ids.max] = filesystem_collection.cards[deps_ids.max], filesystem_collection.cards[index]
  end

  filesystem_collection.cards.each { |fs_card| fs_card.card_exists?(metabase_collection) }

  CARDS = filesystem_collection.cards + metabase_collection.cards

  filesystem_collection.cards.each_with_index do |card, idx|
    card.query = query_interpreter.interpreter!(configs, card, CARDS)

    online_card = metabase_collection.find_card(card.name)
    card.update_id!(online_card.id) if online_card&.id
    card.need_update = online_card&.query != card.query

    if card.exist && card.need_update
      puts "Updating card '#{card.name}'".colorize(:yellow)
      request = http_request.put(
        "/api/card/#{card.id}",
        card.payload(metabase_collection, decidim_db["id"], CARDS)
      )

      body = JSON.parse(request.body)
      puts "Card successfully updated (ID/#{body["id"]})".colorize(:green)
      card.update_id!(body["id"]) if card.id != body["id"]
    elsif !card.exist
      puts "Creating card '#{card.name}'".colorize(:green)
      request = http_request.post(
        "/api/card",
        card.payload(metabase_collection, decidim_db["id"], CARDS)
      )

      body = JSON.parse(request.body)
      puts "Card successfully created (ID/#{body["id"]})".colorize(:green)
      card.update_id!(body["id"]) if card.id != body["id"]
    else
      puts "Card '#{card.name}' already up-to-date".colorize(:green)
    end
  end

  puts "Program successfully terminated (Exit code: 0)".colorize(:green)
  exit 0
rescue StandardError => e
  puts "[#{e.class}] #{e.message} (Exit code: 2)".colorize(:red)
  puts e.backtrace.join("\n").colorize(:red) if ARGV.include?("-v")
  puts "You can enable verbose mode using '-v' to have the backtrace".colorize(:yellow) unless ARGV.include?("-v")
  puts "Operation terminated".colorize(:red)

  exit 2
end
