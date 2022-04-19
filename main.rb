#!/usr/bin/env ruby

require_relative "lib/decidim_metabase"
require "byebug"
require 'faraday'
require 'faraday/net_http'
require 'dotenv/load'


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

Faraday.default_adapter = :net_http

conn = Faraday.new(
  url: "https://#{ENV.fetch("METABASE_HOST")}/",
  headers: {'Content-Type' => 'application/json'}
)

response = conn.post('/api/session') do |req|
  req.body = {
    username: ENV.fetch("METABASE_USERNAME"),
    password: ENV.fetch("METABASE_PASSWORD"),
  }.to_json
  req.headers = { "Content-Type" => "application/json" }
end

if response.body != ""
  body = JSON.parse(response.body)
  File.open("token.private", "w+") { |file| file.write(body["id"]) }
end

puts response
