begin
  APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env.to_s]
rescue Errno::ENOENT
  puts "config file not found. loading from ENV"
  APP_CONFIG = Hash.new
  APP_CONFIG['fusion_table_id'] = ENV['fusion_table_id'].to_s
  APP_CONFIG['google_account'] = ENV['google_account'].to_s
  APP_CONFIG['google_password'] = ENV['google_password'].to_s
  APP_CONFIG['google_api_key'] = ENV['google_api_key'].to_s
  
  APP_CONFIG['flickr_key'] = ENV['flickr_key'].to_s
  APP_CONFIG['flickr_secret'] = ENV['flickr_secret'].to_s

  APP_CONFIG['signupNotificationEmail'] = ENV['signupNotificationEmail'].to_s

  APP_CONFIG['admin1Email'] = ENV['admin1Email'].to_s
  APP_CONFIG['admin1Pass'] = ENV['admin1Pass'].to_s
  APP_CONFIG['admin2Email'] = ENV['admin2Email'].to_s
  APP_CONFIG['admin2Pass'] = ENV['admin2Pass'].to_s

end

APP_CONFIG['domain'] = 'http://weconnectchicago.org/'

#initialize Fusion Tables API
FT = GData::Client::FusionTables.new      
begin
  FT.clientlogin(APP_CONFIG['google_account'], APP_CONFIG['google_password'])
  FT.set_api_key(APP_CONFIG['google_api_key'])
rescue StandardError => e
  puts "[fusion tables] error initializing Fusion Tables API. Fusion Tables are unavailable. \n[fusion tables] Error message: #{e.message}."
end

#initialize Flickr
FlickRaw.api_key=APP_CONFIG['flickr_key']
FlickRaw.shared_secret=APP_CONFIG['flickr_secret']