namespace :location do
  desc "Batch-geocode all locations"
  task :geocode => :environment do
    puts "Geocoding"
    @locations = FT.execute("SELECT * FROM #{APP_CONFIG['fusion_table_id']};")
    table = GData::Client::FusionTables::Table.new(FT, :table_id => APP_CONFIG['fusion_table_id'], :name => "My table")

    @locations.each do |location|
      lat, long = Geocoder.coordinates(location[:full_address])
      puts "#{location[:full_address]}: #{lat}, #{long}"
      sleep 1
      row_id = FT.execute("SELECT ROWID FROM #{APP_CONFIG['fusion_table_id']} WHERE slug = '#{location[:slug]}';").first[:rowid]
      sql = "UPDATE #{APP_CONFIG['fusion_table_id']} SET latitude='#{lat}',longitude='#{long}' WHERE ROWID='#{row_id}';"
      #puts sql
      geo_save = FT.execute(sql)
      #puts Geocoder.coordinates(location[:full_address]).inspect
    end

    puts "done"
  end
end