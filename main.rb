#!/usr/bin/env ruby

require_relative "lib/decidim_metabase"
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

  http_request = DecidimMetabase::HttpRequests.new(conn, api_session)

  # Récupérer les bases de données
  api_database = DecidimMetabase::Api::Database.new(http_request)
  target_database = api_database.find_by(configs["database"]["decidim"]["name"])

  api_collection = DecidimMetabase::Api::Collection.new(http_request)
  collection = api_collection.find_or_create!(configs["collection_name"])

  components = Dir.glob("./cards/decidim_cards/*").select { |path| File.directory?(path) }

  components.each do |path|
    next unless File.directory? path
    next unless File.exists? "#{path}/info.yml"
    next unless File.exists? "#{path}/locales/en.yml"

    info = YAML.load_file("#{path}/info.yml")
    locales = YAML.load_file("#{path}/locales/en.yml")

    request = http_request.post("/api/card", {
      visualization_settings: {
        "table.cell_column"=> "id",
      },
      collection_id: collection["id"],
      name: locales["name"],
      dataset_query: {
        "type" => "native",
        "native" => {
          "query" => info["query"]["sql"].chomp
        },
        "database" => target_database["id"] },
      display: "table", # Or scalar
    })
    # {"errors"=>{"display"=>"la valeur doit être une chaîne de caractères non vide."}}
    body = JSON.parse(request.body)

    puts body
  end

  puts components
rescue StandardError => e
  puts "[#{e.class}] - #{e.message} (Exit code: 2)"
  exit 2
end


