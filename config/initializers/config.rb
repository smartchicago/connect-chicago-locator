begin
  APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env.to_s]
rescue Errno::ENOENT
  puts "config file not found. loading from ENV"
  APP_CONFIG = []
  APP_CONFIG['fusion_table_id'] = ENV['google_account']
  APP_CONFIG['google_account'] = ENV['google_account']
  APP_CONFIG['google_password'] = ENV['google_password'] 
  
  APP_CONFIG['flickr_key'] = ENV['flickr_key']
  APP_CONFIG['flickr_secret'] = ENV['flickr_secret'] 
end

puts "google_account: #{google_account}"
puts "google_password: #{google_password}"

#initialize Fusion Tables API
FT = GData::Client::FusionTables.new      
FT.clientlogin(APP_CONFIG['google_account'], APP_CONFIG['google_password'])

#initialize Flickr
FlickRaw.api_key=APP_CONFIG['flickr_key']
FlickRaw.shared_secret=APP_CONFIG['flickr_secret']