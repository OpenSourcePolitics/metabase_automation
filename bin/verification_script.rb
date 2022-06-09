# frozen_string_literal: true

# Script that check every data in all decidim_cards cards to make sure every card is correct to use
require "yaml"
require "yaml/store"
require "colorize"

def check(folder)
  Dir.chdir(folder) do
    print "Checking '#{folder.split("/").last}'... \n".colorize(:cyan)
    @folder = folder
    # Search for info.yml
    if File.exist?("info.yml")
      @yaml = YAML::Store.new "info.yml"
      info = load_file
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
    create_resource_key!
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
    create_meta_key! if meta.nil?
    puts "Error: No dependencies in info.yml".colorize(:red)
    create_depends_on_key!
    asked_dependencies = load_file
  end
  dependencies.each do |dependency|
    ask_to_add_dependency(info, dependency) unless asked_dependencies.include?(dependency)
    asked_dependencies = load_file.dig("query", "info", "meta", "depends_on")
  end
end

def load_file
  YAML.load_file("info.yml")
end

def ask_to_modify(info, folder)
  return unless prompt_user("Do you want to autocorrect the resource name of #{folder}
  that is actually #{info["resource"]}?") == "y"

  @yaml.transaction do
    @yaml["resource"] = folder.split("/")[2].strip
  end
  puts "Resource name has been autocorrected to #{folder.split("/")[2].strip}".colorize(:cyan)
end

def ask_to_add_dependency(info, dependency)
  return unless prompt_user("Do you want to add missing dependency #{dependency} to
  dependencies of #{info["resource"]}?") == "y"

  @yaml.transaction do
    @yaml["query"]["info"]["meta"]["depends_on"] << dependency
  end
  puts "Dependency #{dependency} has been added to dependencies of #{info["resource"]}".colorize(:cyan)
end

def prompt_user(message)
  if @auto_complete == false
    puts message.colorize(:yellow)
    puts "y/n".colorize(:white).center(100)
    answer = gets.chomp
  else
    answer = "y"
  end
  answer
end

def create_resource_key!
  @yaml.transaction do
    @yaml["resource"] = ""
  end
  puts "Creating resource key in info.yml".colorize(:cyan)
end

def create_meta_key!
  @yaml.transaction do
    @yaml["query"]["info"]["meta"] = {}
  end
  puts "Creating meta key in info.yml".colorize(:cyan)
end

def create_depends_on_key!
  @yaml.transaction do
    @yaml["query"]["info"]["meta"]["depends_on"] = []
  end
  puts "Creating depends_on key in info.yml".colorize(:cyan)
end

folders = Dir.glob("cards/decidim_cards/*")
@auto_complete = false
# If the last argument of the command is -y
@auto_complete = true if ARGV[-1] == "-y"
if folders.empty?
  puts "Error: No cards found".colorize(:red)
  exit 1
else
  folders.each do |folder|
    next unless File.directory?(folder)

    check(folder)
  end
  puts "Verification finished ! Everything is safe !".colorize(:green)
  exit 0
end
