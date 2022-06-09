# frozen_string_literal: true

# Script that check every data in all decidim_cards cards to make sure every card is correct to use
require "yaml"
require "yaml/store"
require "colorize"

def check(folder)
  Dir.chdir(folder) do
    print "Checking #{folder}... \n".colorize(:cyan)
    @yaml = YAML::Store.new "info.yml"
    @folder = folder
    # Search for info.yml
    if File.exist?("info.yml")
      info = YAML.load_file("info.yml")
      # If name of file corresponds to check_for_resource_in(info)
      unless check_for_resource_in(info) == folder.split("/")[2].strip
        # Ask if user wants to autocorrect the resource name and write it to info.yml
        puts "Error: Resource name does not match the name of the folder".colorize(:red)
        ask_to_modify(info, folder)
      end
      dependencies = check_for_query_in(info)

      verify_if_dependencies_corresponds_with(dependencies, info) unless dependencies.empty?
    else
      puts ("Error: Info.yml does not exist for #{folder}").colorize(:red)
      next
    end
  end
end

def check_for_resource_in(info)
  resource = info["resource"]
  if resource.nil?
    puts "Error: Resource name not found in info.yml".colorize(:red)
    create_resource_in(info)
  end
  info["resource"]
end

def check_for_query_in(info)
  # Search for query in the yaml structure
  dependencies = []
  query_sql = info["query"]["sql"]
  regexp = /{{#(.*?)}}/
  query_sql.split(" ").each do |word|
    word.match(regexp) do |match|
      dependencies << match[1]
    end
  end
  dependencies
end

def verify_if_dependencies_corresponds_with(dependencies, info)
  asked_dependencies = info.dig("query", "info", "meta", "depends_on")
  if asked_dependencies.nil?
    # Check if meta exists and create it if not
    meta = info.dig("query", "info", "meta")
    create_meta_in(info) if meta.nil?
    puts "Error: No dependencies in info.yml".colorize(:red)
    create_depends_on_in(info)
    info = YAML.load_file("info.yml")
    asked_dependencies = info.dig("query", "info", "meta", "depends_on")
  end
  dependencies.each do |dependency|
    ask_to_add_dependency(info, dependency, asked_dependencies) unless asked_dependencies.include?(dependency)
  end
end

def ask_to_modify(info, folder)
  puts "Do you want to autocorrect the resource name of #{folder}
    that is actually #{info["resource"]}?".colorize(:yellow)
  puts "y/n".colorize(:white).center(100)
  answer = gets.chomp
  return unless answer == "y"

  @yaml.transaction do
    @yaml["resource"] = folder.split("/")[2].strip
  end
  puts "Resource name has been autocorrected to #{folder.split("/")[2].strip}".colorize(:cyan)
end

def ask_to_add_dependency(info, dependency, _asked_dependencies)
  puts "Do you want to add missing dependency #{dependency} to
            dependencies of #{info["resource"]}?".colorize(:yellow)
  puts "y/n".colorize(:white).center(100)
  answer = gets.chomp
  return unless answer == "y"

  @yaml.transaction do
    @yaml["query"]["info"]["meta"]["depends_on"] << dependency
  end
end

def create_resource_in(_info)
  @yaml.transaction do
    @yaml["resource"] = ""
  end
end

def create_meta_in(_info)
  @yaml.transaction do
    @yaml["query"]["info"]["meta"] = {}
  end
end

def create_depends_on_in(_info)
  @yaml.transaction do
    @yaml["query"]["info"]["meta"]["depends_on"] = []
  end
end

folders = Dir.glob("cards/decidim_cards/*")
puts folders
unless folders.empty?
folders.each do |folder|
  next unless File.directory?(folder)
  check(folder)
end
puts "Verification finished ! Everything is safe !".colorize(:green)
else 
    puts "Error: No cards found".colorize(:red)
end
