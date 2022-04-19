#!/usr/bin/env ruby

require_relative "lib/decidim_metabase"
require "byebug"

def render_ascii_art
  File.readlines("ascii.txt")[0..-2].each do |line|
    puts line
  end
  puts "                     Module Metabase (v#{DecidimMetabase::VERSION})"
  puts "                     By Open Source Politics."
  puts "\n"
end



render_ascii_art
puts ""



