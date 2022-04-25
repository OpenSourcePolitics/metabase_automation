#!/usr/bin/env ruby

require_relative "lib/decidim_metabase"
require 'securerandom'
require "byebug"
require 'faraday'
require 'faraday/net_http'
require 'dotenv/load'
require 'yaml'

def render_ascii_art
  File.readlines("ascii.txt")[0..-2].each do |line|
    puts line
  end
  puts "                     Module Metabase (v#{DecidimMetabase::VERSION})"
  puts "                     By Open Source Politics."
  puts "\n"
end

render_ascii_art

## Interesting things below...

begin

  TOKEN_DB_PATH = "token.private"

  # Charger le fichier config.yml
  configs = YAML.load_file("config.yml")

  # Définir la connexion Faraday
  Faraday.default_adapter = :net_http
  conn = Faraday.new(
    url: "https://#{ENV.fetch("METABASE_HOST")}/",
    headers: { 'Content-Type' => 'application/json' }
  )

  # Définition de l'Api Session
  api_session = DecidimMetabase::Api::Session.new(conn, {
    username: ENV.fetch("METABASE_USERNAME"),
    password: ENV.fetch("METABASE_PASSWORD"),
  })

  # Builder de requetes
  http_request = DecidimMetabase::HttpRequests.new(conn, api_session)

  # Récupérer les bases de données
  api_database = DecidimMetabase::Api::Database.new(http_request)
  decidim_db = api_database.find_by(configs["database"]["decidim"]["name"])

  api_collection = DecidimMetabase::Api::Collection.new(http_request)
  collection = api_collection.find_or_create!(configs["collection_name"])
  # Collection should be nil

  components = Dir.glob("./cards/decidim_cards/*").select { |path| File.directory?(path) }.sort

  cards = []

  components.each do |path|
    next unless File.directory? path
    next unless File.exists? "#{path}/info.yml"
    next unless File.exists? "#{path}/locales/en.yml"

    info = YAML.load_file("#{path}/info.yml")
    locales = YAML.load_file("#{path}/locales/en.yml")

    query = info["query"]["sql"].chomp
    if query.match?(/\$HOST/)
      query = query.gsub!("$HOST", "'#{configs["host"]}'")
    end

    if query.include?("{{#ORGANIZATION}}")
      organization = cards.select { |card| card if card["name"] == "Organization" }.first
      query = query.gsub!("{{#ORGANIZATION}}", "{{##{organization["id"].to_s}}}")
    end

    if query.include?("{{#components}}")
      components_card = cards.select { |card| card if card["name"] == "Components" }.first
      # TODO: Ensure components cards, may be nil
      query = query.gsub!("{{#components}}", "{{##{components_card["id"].to_s}}}")
    end

    payload = {
      collection_id: collection["id"],
      name: locales["name"],
      display: "table",
      dataset: true,
      dataset_query: {
        "type" => "native",
        "native" => {
          "query" => query,
          "filter" => {}
        },
        "database" => decidim_db["id"]
      },
      visualization_settings: {
        "table.cell_column"=> "id",
      }
    }

    if !organization.nil?
      uuid = SecureRandom.uuid.to_s
      payload[:dataset_query]["native"]["template-tags"] =
        { "##{organization["id"].to_s}" => {
          "id" => uuid,
          "name"=>"##{organization["id"].to_s}",
          "display-name"=>"##{organization["id"].to_s}",
          "type"=>"card",
          "card-id"=>organization["id"]
        }
      }
    end
    if !components_card.nil?
      uuid = SecureRandom.uuid.to_s
      payload[:dataset_query]["native"]["template-tags"] =
        { "##{components_card["id"].to_s}" => {
          "id" => uuid,
          "name"=>"##{components_card["id"].to_s}",
          "display-name"=>"##{components_card["id"].to_s}",
          "type"=>"card",
          "card-id"=>components_card["id"]
        }
      }
    end

    request = http_request.post("/api/card", payload)

    body = JSON.parse(request.body)

    cards << body
  end
rescue StandardError => e
  puts "[#{e.class}] - #{e.message} (Exit code: 2)"
  exit 2
end


