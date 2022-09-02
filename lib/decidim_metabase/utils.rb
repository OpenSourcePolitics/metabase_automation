# frozen_string_literal: true

module DecidimMetabase
  # Utils - Contains not required logic like outputs
  module Utils
    def self.welcome
      render_ascii_art
    end

    def self.render_ascii_art
      File.readlines("ascii.txt")[0..-2].each do |line|
        puts line
      end
      puts "                     Module Metabase (v#{DecidimMetabase::VERSION})".colorize(:cyan)
      puts "                     By Open Source Politics.".colorize(:cyan)
      puts "\n"
    end
  end
end
