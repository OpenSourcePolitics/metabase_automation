#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/decidim_metabase"
require "securerandom"
require "faraday"
require "faraday/net_http"
require "dotenv/load"
require "yaml"
require "colorize"

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

  decidim_db = api_database.find_by(configs["database"]["decidim"]["name"])
  puts "Database '#{configs["database"]["decidim"]["name"]}' found (ID/#{decidim_db["id"]})".colorize(:green)

  api_collection = DecidimMetabase::Api::Collection.new(http_request)
  collection = api_collection.find_or_create!(configs["collection_name"])

  decidim_cards = Dir.glob("./cards/decidim_cards/*").map do |path|
    next unless File.directory?(path)

    DecidimMetabase::Api::Card.new(path)
  end.compact

  puts "Cards prepared to be save in Metabase '#{decidim_cards.map(&:name).join(", ")}'".colorize(:yellow)
  CARDS = decidim_cards.reject(&:invalid?)

  need_dependencies = CARDS.map.with_index do |card, index|
    next if card.dependencies.empty?

    {
      name: card.name,
      item: card.dependencies,
      index: index
    }
  end.compact

  puts "Sorting cards to match dependencies : #{need_dependencies.map do |card|
                                                  [card[:name], card[:item]].join(" DEPENDS ON ")
                                                end.join(", ")}...".colorize(:green)

  need_dependencies.each do |deps|
    deps[:item].each do |item|
      item_index = CARDS.index { |card| card.name == item }
      deps_index = CARDS.index { |card| card.name == deps[:name] }

      CARDS[item_index], CARDS[deps_index] = CARDS[deps_index], CARDS[item_index] if item_index > deps_index
    end
  end

  CARDS.each_with_index do |current_card, index|
    puts "Creating card '#{current_card.name}'...".colorize(:green)
    current_card.interpreter!(configs, CARDS)

    request = http_request.post(
      "/api/card",
      current_card.payload(collection, decidim_db["id"], CARDS)
    )

    body = JSON.parse(request.body)
    puts "Card successfully created (ID/#{body["id"]})".colorize(:green)
    CARDS[index].update_id!(body["id"])
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
