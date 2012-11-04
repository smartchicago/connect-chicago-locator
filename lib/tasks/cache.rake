namespace :cache do
  desc "Populate cache for all detail pages"
  task :populate => :environment do
    puts "Populating cache"
    @locations = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']};") || not_found

    @locations.each do |location|
      sh "curl -o /dev/null 'http://locations.weconnectchicago.org/location/#{location[:slug]}'"
      sleep(10)
    end

    puts "done"
  end
end