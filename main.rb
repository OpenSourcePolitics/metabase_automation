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
require "benchmark"

Faraday.default_adapter = :net_http
main = DecidimMetabase::Main.new(true)

## Interesting things below...
begin
  main.tap do |obj|
    obj.configs = DecidimMetabase::Config.new
    obj.define_connexion!
    obj.define_api_session!
    obj.define_http_request!
    obj.define_api_database!
    obj.set_databases!
    obj.set_api_cards!
    obj.set_collections!
  end

  puts "Cards prepared to be saved in Metabase '#{main.filesystem_collection.cards.map(&:name).join(", ")}'"
    .colorize(:yellow)

  if main.create_new_cards?
    puts "Creating new cards #{main.filesystem_collection.cards.map(&:name) - main.metabase_collection.cards.map(&:name)}"
      .colorize(:light_green)
  end

  main.store_and_update_cards!

  puts "Program successfully terminated (Exit code: 0)".colorize(:light_green)
  exit 0
rescue StandardError => e
  puts "[#{e.class}] #{e.message} (Exit code: 2)".colorize(:light_red)
  puts e.backtrace.join("\n").colorize(:light_red) if ARGV.include?("-v")
  puts "You can enable verbose mode using '-v' to have the backtrace".colorize(:light_yellow) unless ARGV.include?("-v")
  puts "Operation terminated".colorize(:light_red)

  exit 2
end
