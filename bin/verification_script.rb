# Navigate into each directory in the directory ../cards/decidim_cards
# and run the verification script

def check(folder)
    Dir.chdir(folder) do
        # Search for info.yml
        if File.exist?("info.yml")
            info = File.read("info.yml")
            # If name of file corresponds to check_for_resource_in(info) puts ok else puts error
            if check_for_resource_in(info) == folder.split("/")[3].strip
                puts "ok"
            else
                # Ask if user wants to autocorrect the resource name and write it to info.yml
                puts "error"
                ask_to_modify(info, folder)
            end
        else
            puts ("FATAL ERROR: Info.yml does not exist for #{folder}")
            next
        end
    end
end

def check_for_resource_in(info)
    # Check for resources in the info.yml
    resource = info.scan(/resource:.*/).first.split(":")[1].strip
end

def ask_to_modify(info, folder)
    puts "Do you want to autocorrect the resource name?"
    puts "y/n"
    answer = gets.chomp
    if answer == "y"
        info.gsub!(/resource:.*/, "resource: #{folder.split("/")[3].strip}")
        File.write("info.yml", info)
    end
end

folders = Dir.glob("../cards/decidim_cards/*")
folders.each do |folder|
    next unless File.directory?(folder)
    check(folder)
end

